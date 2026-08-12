import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/editor_performance_telemetry.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test('inactive telemetry does not retain samples or counters', () {
    for (var index = 0; index < 100000; index += 1) {
      expect(
        EditorPerformanceTelemetry.startSpan(
          EditorPerformanceSpanName.pointerPreDispatch,
        ),
        isNull,
      );
      EditorPerformanceTelemetry.incrementCounter(
        EditorPerformanceCounterName.filesystemRead,
      );
    }

    final recorder = EditorPerformanceRecorder();
    final recording = EditorPerformanceTelemetry.startRecording(recorder);
    addTearDown(recording.close);
    final snapshot = recorder.snapshot();

    expect(
      snapshot.spanSamples(EditorPerformanceSpanName.pointerPreDispatch),
      isEmpty,
    );
    expect(snapshot.counter(EditorPerformanceCounterName.filesystemRead), 0);
  });

  test('exposes the complete PERF-000C span catalog', () {
    expect(EditorPerformanceSpanName.all, <String>[
      'pointer.pre_dispatch',
      'pointer.to_state_publish',
      'mutation.local',
      'state.publish',
      'canvas.prepare',
      'canvas.future_builder_body',
      'canvas.paint_recording',
      'mask.readback',
      'mask.pointer_move',
      'mask.commit',
      'mask.build',
      'mask.paint',
      'map.validation.full',
      'snapshot',
      'plan',
      'apply',
      'save.queue',
      'save.encode',
    ]);
  });

  test('records canonical span distributions and counter deltas', () {
    var nowMicroseconds = 100;
    final recorder = EditorPerformanceRecorder(clock: () => nowMicroseconds);
    final recording = EditorPerformanceTelemetry.startRecording(recorder);

    final mutation = EditorPerformanceTelemetry.startSpan(
      EditorPerformanceSpanName.mutationLocal,
    );
    nowMicroseconds = 240;
    mutation!.finish();
    EditorPerformanceTelemetry.incrementCounter(
      EditorPerformanceCounterName.filesystemRead,
    );
    final before = recorder.snapshot();

    final publication = EditorPerformanceTelemetry.startSpan(
      EditorPerformanceSpanName.statePublish,
    );
    nowMicroseconds = 300;
    publication!.finish();
    EditorPerformanceTelemetry.incrementCounter(
      EditorPerformanceCounterName.jsonEncode,
      by: 2,
    );

    final receipt = recorder.snapshot().toJson();
    final spans = receipt['spans']! as Map<String, Object?>;
    final mutationMetrics =
        spans[EditorPerformanceSpanName.mutationLocal]! as Map<String, Object?>;
    expect(mutationMetrics['count'], 1);
    expect(mutationMetrics['totalUs'], 140);
    expect(mutationMetrics['p50Us'], 140);
    expect(mutationMetrics['p95Us'], 140);
    expect(mutationMetrics['p99Us'], 140);
    expect(mutationMetrics['maxUs'], 140);
    expect(
      spans[EditorPerformanceSpanName.canvasPaintRecording],
      <String, Object?>{
        'count': 0,
        'totalUs': 0,
        'p50Us': 0,
        'p95Us': 0,
        'p99Us': 0,
        'maxUs': 0,
      },
    );

    final delta = recorder.deltaSince(before);
    expect(delta.spanSamples(EditorPerformanceSpanName.mutationLocal), isEmpty);
    expect(delta.spanSamples(EditorPerformanceSpanName.statePublish), <int>[
      60,
    ]);
    expect(delta.counter(EditorPerformanceCounterName.filesystemRead), 0);
    expect(delta.counter(EditorPerformanceCounterName.jsonEncode), 2);

    recording.close();
    expect(
      EditorPerformanceTelemetry.startSpan(
        EditorPerformanceSpanName.pointerPreDispatch,
      ),
      isNull,
    );
  });

  test('bounds recorded samples and reports dropped measurements', () {
    var nowMicroseconds = 0;
    final recorder = EditorPerformanceRecorder(
      clock: () => nowMicroseconds,
      maxSamplesPerSpan: 2,
    );
    final recording = EditorPerformanceTelemetry.startRecording(recorder);
    addTearDown(recording.close);

    for (var index = 0; index < 3; index++) {
      final span = EditorPerformanceTelemetry.startSpan(
        EditorPerformanceSpanName.canvasPaintRecording,
      )!;
      nowMicroseconds += 10;
      span.finish();
    }

    final receipt = recorder.snapshot().toJson();
    expect(
      recorder.snapshot().spanSamples(
        EditorPerformanceSpanName.canvasPaintRecording,
      ),
      <int>[10, 10],
    );
    expect(receipt['droppedSampleCount'], 1);
  });

  test('rejects out-of-order recording closure without leaking a recorder', () {
    final firstRecorder = EditorPerformanceRecorder();
    final secondRecorder = EditorPerformanceRecorder();
    final first = EditorPerformanceTelemetry.startRecording(firstRecorder);
    final second = EditorPerformanceTelemetry.startRecording(secondRecorder);

    expect(first.close, throwsStateError);
    EditorPerformanceTelemetry.incrementCounter(
      EditorPerformanceCounterName.jsonEncode,
    );
    expect(
      secondRecorder.snapshot().counter(
        EditorPerformanceCounterName.jsonEncode,
      ),
      1,
    );

    second.close();
    first.close();
    expect(
      EditorPerformanceTelemetry.startSpan(
        EditorPerformanceSpanName.pointerPreDispatch,
      ),
      isNull,
    );
  });

  test(
    'production adapters increment filesystem JSON and base64 counters',
    () async {
      final root = await Directory.systemTemp.createTemp('perf-telemetry-');
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/fixture.json').writeAsString('{}');
      final recorder = EditorPerformanceRecorder();
      final recording = EditorPerformanceTelemetry.startRecording(recorder);
      addTearDown(recording.close);

      final encoded = EditorPerformanceTelemetry.encodeJson(<String, int>{
        'value': 1,
      });
      EditorPerformanceTelemetry.decodeJson(encoded);
      final mask = EditorPerformanceTelemetry.encodePackedCollisionMask(
        widthPx: 2,
        heightPx: 2,
        solidPixels: const <bool>[true, false, false, true],
      );
      EditorPerformanceTelemetry.decodePackedCollisionMask(
        widthPx: 2,
        heightPx: 2,
        dataBase64: mask,
      );
      const reader = EditorProjectFileReader();
      final canonicalRoot = await reader.canonicalizeDirectory(root.path);
      await reader.readBytes(
        projectRoot: canonicalRoot,
        relativePath: 'fixture.json',
      );

      final snapshot = recorder.snapshot();
      expect(snapshot.counter(EditorPerformanceCounterName.filesystemRead), 1);
      expect(
        snapshot.counter(EditorPerformanceCounterName.filesystemMetadata),
        1,
      );
      expect(snapshot.counter(EditorPerformanceCounterName.jsonEncode), 1);
      expect(snapshot.counter(EditorPerformanceCounterName.jsonDecode), 1);
      expect(snapshot.counter(EditorPerformanceCounterName.base64Encode), 1);
      expect(snapshot.counter(EditorPerformanceCounterName.base64Decode), 1);
    },
  );
}

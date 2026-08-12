import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/debug/marionette_personalization_qa_seed.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_narrative_document_recovery_store.dart';
import 'package:map_editor/src/infrastructure/riverpod_retry_policy.dart';
import 'package:path/path.dart' as p;

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _target =
    'integration_test/personalization_performance_journey_test.dart';
const _payloadBytes = 10 * 1024 * 1024;
const _sliderTicks = 100;
const _soakGestures = 10;
const _soakTicksPerGesture = 20;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'profiles slider preview recovery canonical save and soak on macOS',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = await _PersonalizationPerformanceFixture.create();
      addTearDown(fixture.dispose);
      final durableBefore = await fixture.projectFile.readAsBytes();
      final container = ProviderContainer(retry: disableAutomaticProviderRetry);
      addTearDown(() async {
        await container
            .read(editorAuthoringSessionLifecycleProvider)
            .closeAll();
        container.dispose();
      });
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: fixture.projectRoot.path,
        project: ProjectManifest.fromJson(
          jsonDecode(utf8.decode(durableBefore)) as Map<String, dynamic>,
        ),
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MapEditorApp(),
        ),
      );
      expect(await notifier.initializePersonalizationStudioSession(), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey<String>('personalization-studio-workspace')),
        findsOneWidget,
      );

      final diagnostics = container.read(
        personalizationRecoveryStoreDiagnosticsProvider,
      );
      final ioBefore = diagnostics.snapshot();
      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('personalization-studio-scene-dialogue'),
        ),
      );
      final slider = find.descendant(
        of: find.byKey(const ValueKey<String>('dialogue-geometry-width')),
        matching: find.byType(CupertinoSlider),
      );
      expect(slider, findsOneWidget);

      final timings = <FrameTiming>[];
      void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);
      var callbackRegistered = true;
      SchedulerBinding.instance.addTimingsCallback(captureTimings);
      addTearDown(() {
        if (!callbackRegistered) return;
        SchedulerBinding.instance.removeTimingsCallback(captureTimings);
        callbackRegistered = false;
      });

      final rssBefore = ProcessInfo.currentRss;
      final firstGesture = Stopwatch()..start();
      await _runSliderGesture(
        tester,
        slider,
        start: 82,
        end: 70,
        ticks: _sliderTicks,
      );
      await _waitForDurableWrites(
        tester,
        diagnostics,
        ioBefore.durableWrites + 1,
      );
      firstGesture.stop();
      final firstGestureIo = diagnostics.snapshot().deltaFrom(ioBefore);
      expect(firstGestureIo.writeRequests, 1);
      expect(firstGestureIo.durableWrites, 1);
      expect(firstGestureIo.verificationReads, 1);
      expect(await _recoveryUndoDepth(fixture.projectRoot), 1);
      expect(notifier.personalizationStudioSessionState?.canUndo, isTrue);
      expect(await fixture.projectFile.readAsBytes(), durableBefore);

      final rssBeforeSoak = ProcessInfo.currentRss;
      final soak = Stopwatch()..start();
      var current = 70.0;
      for (var gesture = 0; gesture < _soakGestures; gesture += 1) {
        final target = gesture.isEven ? 71.0 : 70.0;
        await _runSliderGesture(
          tester,
          slider,
          start: current,
          end: target,
          ticks: _soakTicksPerGesture,
        );
        current = target;
        await _waitForDurableWrites(
          tester,
          diagnostics,
          ioBefore.durableWrites + gesture + 2,
        );
      }
      soak.stop();
      final rssAfterSoak = ProcessInfo.currentRss;
      final ioAfterSoak = diagnostics.snapshot().deltaFrom(ioBefore);
      expect(ioAfterSoak.writeRequests, 1 + _soakGestures);
      expect(ioAfterSoak.durableWrites, 1 + _soakGestures);
      expect(ioAfterSoak.verificationReads, 1 + _soakGestures);
      expect(await _recoveryUndoDepth(fixture.projectRoot), 1 + _soakGestures);

      final save = Stopwatch()..start();
      expect(await notifier.savePersonalizationStudio(), isTrue);
      save.stop();
      await tester.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final ioAfterSave = diagnostics.snapshot().deltaFrom(ioBefore);
      expect(ioAfterSave.clearRequests, 1);
      expect(ioAfterSave.durableClears, 1);
      expect(notifier.personalizationStudioSessionState?.isDirty, isFalse);
      expect(await _transactionDirectoryCount(fixture.projectRoot), 0);
      expect(await fixture.projectFile.readAsBytes(), isNot(durableBefore));

      SchedulerBinding.instance.removeTimingsCallback(captureTimings);
      callbackRegistered = false;
      final frameMetrics = _frameMetrics(timings);
      expect(frameMetrics['frameCount'], greaterThanOrEqualTo(_sliderTicks));
      expect(tester.takeException(), isNull);

      binding.reportData = <String, dynamic>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'personalization_studio_journey',
        'target': _target,
        'requestedOutputPath': _requestedOutputPath,
        'executionMode': const bool.fromEnvironment('dart.vm.profile')
            ? 'flutter-profile'
            : 'flutter-debug',
        'fixture': <String, Object?>{
          'kind': 'marionette-personalization-qa-padded',
          'projectBytes': await fixture.projectFile.length(),
          'requestedPayloadBytes': _payloadBytes,
          'beforeFingerprint': sha256.convert(durableBefore).toString(),
          'afterFingerprint': sha256
              .convert(await fixture.projectFile.readAsBytes())
              .toString(),
        },
        'iterations': <String, Object?>{
          'sliderTicks': 100,
          'soakGestures': 10,
          'soakTicksPerGesture': _soakTicksPerGesture,
          'canonicalSaves': 1,
        },
        'durationsUs': <String, Object?>{
          'firstGesture': firstGesture.elapsedMicroseconds,
          'soak': soak.elapsedMicroseconds,
          'canonicalSave': save.elapsedMicroseconds,
        },
        'io': ioAfterSave.toJson(),
        'memory': <String, Object?>{
          'rssBeforeBytes': rssBefore,
          'rssBeforeSoakBytes': rssBeforeSoak,
          'rssAfterSoakBytes': rssAfterSoak,
          'rssAfterSaveBytes': ProcessInfo.currentRss,
          'rssGrowthBytes': rssAfterSoak - rssBeforeSoak,
        },
        'frameMetrics': frameMetrics,
        'transactionArtifactsAfterSave': await _transactionDirectoryCount(
          fixture.projectRoot,
        ),
        'thresholdPolicy': <String, Object?>{
          'observationOnly': true,
          'minimumHistoricalObservations': 10,
          'requiredConsecutiveRegressions': 2,
          'enforcedWorkCounts': <String, Object?>{
            'firstGestureDurableWrites': 1,
            'firstGestureUndoEntries': 1,
            'transactionArtifactsAfterSave': 0,
          },
        },
      };
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Future<void> _runSliderGesture(
  WidgetTester tester,
  Finder slider, {
  required double start,
  required double end,
  required int ticks,
}) async {
  tester.widget<CupertinoSlider>(slider).onChangeStart?.call(start);
  for (var tick = 0; tick < ticks; tick += 1) {
    final value = start + ((end - start) * (tick + 1) / ticks);
    tester.widget<CupertinoSlider>(slider).onChanged?.call(value);
    await tester.pump(const Duration(milliseconds: 16));
  }
  tester.widget<CupertinoSlider>(slider).onChangeEnd?.call(end);
  await tester.pump();
}

Future<void> _waitForDurableWrites(
  WidgetTester tester,
  NarrativeRecoveryStoreDiagnostics diagnostics,
  int expected,
) async {
  for (
    var attempt = 0;
    attempt < 300 && diagnostics.durableWrites < expected;
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 10));
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(diagnostics.durableWrites, greaterThanOrEqualTo(expected));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder.hitTestable());
  await tester.pump(const Duration(milliseconds: 50));
}

Future<int> _recoveryUndoDepth(Directory projectRoot) async {
  final file = File(
    p.join(
      projectRoot.path,
      '.pokemap',
      'recovery',
      'personalization-studio.json',
    ),
  );
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return (json['undoEntries']! as List<Object?>).length;
}

Future<int> _transactionDirectoryCount(Directory projectRoot) async {
  final directory = Directory(
    p.join(projectRoot.path, '.pokemap', 'authoring', 'transactions'),
  );
  if (!await directory.exists()) return 0;
  return directory.list().where((entity) => entity is Directory).length;
}

Map<String, Object?> _frameMetrics(List<FrameTiming> timings) {
  final spans = timings
      .map((timing) => timing.totalSpan.inMicroseconds)
      .toList(growable: false);
  final sorted = List<int>.of(spans)..sort();
  return <String, Object?>{
    'frameCount': spans.length,
    'frameSpanSamplesMicroseconds': spans,
    'frameSpanP50Us': _percentile(sorted, 0.50),
    'frameSpanP95Us': _percentile(sorted, 0.95),
    'frameSpanP99Us': _percentile(sorted, 0.99),
    'maxUs': sorted.isEmpty ? 0 : sorted.last,
    'framesOver16Point67Milliseconds': spans
        .where((value) => value > 16670)
        .length,
    'framesOver33Point3Milliseconds': spans
        .where((value) => value > 33300)
        .length,
  };
}

int _percentile(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

final class _PersonalizationPerformanceFixture {
  const _PersonalizationPerformanceFixture({
    required this.sandbox,
    required this.projectRoot,
  });

  final Directory sandbox;
  final Directory projectRoot;

  File get projectFile => File(p.join(projectRoot.path, 'project.json'));

  static Future<_PersonalizationPerformanceFixture> create() async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap-personalization-performance-',
    );
    final projectRoot = await MarionettePersonalizationQaSeed.create(
      sandboxRoot: sandbox,
      runId: 'profile',
      loadAsset: (path) async {
        final data = await rootBundle.load(path);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      },
    );
    final projectFile = File(p.join(projectRoot.path, 'project.json'));
    final json =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    final properties = Map<String, Object?>.from(
      json['globalProperties'] as Map? ?? const <String, Object?>{},
    );
    properties['performancePayload'] = 'x' * _payloadBytes;
    json['globalProperties'] = properties;
    await projectFile.writeAsString(jsonEncode(json), flush: true);
    return _PersonalizationPerformanceFixture(
      sandbox: sandbox,
      projectRoot: projectRoot,
    );
  }

  Future<void> dispose() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  }
}

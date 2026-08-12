import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/editor_performance_telemetry.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  test('map save and load retain separately traced full validation', () async {
    final directory = await Directory.systemTemp.createTemp(
      'map-full-validation-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final recorder = EditorPerformanceRecorder();
    final recording = EditorPerformanceTelemetry.startRecording(recorder);
    addTearDown(recording.close);
    final repository = FileMapRepository();
    final path = '${directory.path}/map.json';
    const map = MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[false],
        ),
      ],
    );

    await repository.saveMap(map, path);
    expect(await repository.loadMap(path), map);

    final snapshot = recorder.snapshot();
    expect(
      snapshot.spanSamples(EditorPerformanceSpanName.mapFullValidation),
      hasLength(2),
    );
    expect(
      snapshot.spanSamples(EditorPerformanceSpanName.mapIncrementalValidation),
      isEmpty,
    );
  });
}

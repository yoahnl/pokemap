import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

void main() {
  late Directory root;
  const project = ProjectManifest(name: 'Map corpus', maps: [], tilesets: []);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('runtime-map-corpus-');
  });
  tearDown(() => root.delete(recursive: true));

  Future<String> writeMap(String id, {String? name}) async {
    final file = File('${root.path}/$id.json');
    await file.writeAsString(
      jsonEncode(
        MapData(
          id: id,
          name: name ?? id,
          size: const GridSize(width: 2, height: 2),
        ).toJson(),
      ),
    );
    return file.path;
  }

  test('accepts an empty corpus', () async {
    expect(await loadMapDataFiles([], projectDialogueContext: project), isEmpty);
  });

  test(
    'loads ordered maps and observes later disk edits without a cache',
    () async {
      final first = await writeMap('first');
      final second = await writeMap('second');
      final loaded = await loadMapDataFiles([
        second,
        first,
      ], projectDialogueContext: project);
      expect(loaded.map((map) => map.id), ['second', 'first']);
      await writeMap('second', name: 'Changed');
      final fresh = await loadMapDataFiles([
        second,
      ], projectDialogueContext: project);
      expect(fresh.single.name, 'Changed');
      expect(loaded.first.name, 'second');
    },
  );

  test('rejects a missing map instead of returning a partial corpus', () async {
    final first = await writeMap('first');
    await expectLater(
      loadMapDataFiles([
        first,
        '${root.path}/missing.json',
      ], projectDialogueContext: project),
      throwsA(
        isA<MapLoadException>().having(
          (error) => error.message,
          'message',
          contains('missing.json'),
        ),
      ),
    );
  });

  test('validates the dimensions of every map against the project', () async {
    final first = await writeMap('first');
    final invalid = File('${root.path}/spatial.json');
    await invalid.writeAsString(
      jsonEncode(
        MapData(
          id: 'spatial',
          name: 'Spatial',
          version: ProjectVersion.v9,
          size: const GridSize(width: 2, height: 2),
          spatialScene: MapSpatialScene(width: 2, depth: 2),
        ).toJson(),
      ),
    );
    await expectLater(
      loadMapDataFiles([first, invalid.path], projectDialogueContext: project),
      throwsA(
        isA<MapLoadException>().having(
          (error) => error.message,
          'message',
          contains('dimension'),
        ),
      ),
    );
  });

  test('rejects unsupported visual composition semantics', () async {
    final file = File('${root.path}/future.json');
    await file.writeAsString(
      jsonEncode(
        MapData(
          id: 'future',
          name: 'Future',
          size: const GridSize(width: 2, height: 2),
          visualStack: MapVisualStackConfig(semanticsVersion: 99),
        ).toJson(),
      ),
    );
    await expectLater(
      loadMapDataFiles([file.path], projectDialogueContext: project),
      throwsA(isA<MapLoadException>()),
    );
  });
}

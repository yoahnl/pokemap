import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/bundled_runtime_project.dart';

void main() {
  test('packaged project inventory supports New Game and save/reload',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_selbrume_release_package_',
    );
    addTearDown(() => root.delete(recursive: true));
    final projectRoot = Directory(
      p.join(
        root.path,
        'PokeMap Selbrume.app',
        'Contents',
        'Resources',
        'selbrume',
      ),
    );
    await _writeMinimalBundledProject(projectRoot);

    final verification = await verifyBundledRuntimeProject(
      p.join(projectRoot.path, 'project.json'),
    );

    expect(verification.projectName, 'Selbrume package test');
    expect(verification.startMapId, 'start');
    expect(verification.mapCount, 1);
    expect(verification.newGameSaveReloadPassed, isTrue);
    expect(
      verification.requiredRelativePaths,
      containsAll(<String>[
        'project.json',
        'maps/start.json',
        'dialogues/intro.yarn',
        'data/pokemon/catalogs/items.json',
        'data/pokemon/catalogs/moves.json',
        'data/pokemon/species/0001-test.json',
        'assets/tilesets/test.png',
      ]),
    );
  });

  test('package verification fails closed when a required family is missing',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_selbrume_release_package_missing_',
    );
    addTearDown(() => root.delete(recursive: true));
    await _writeMinimalBundledProject(root);
    await Directory(p.join(root.path, 'dialogues')).delete(recursive: true);

    await expectLater(
      verifyBundledRuntimeProject(p.join(root.path, 'project.json')),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('dialogues'),
        ),
      ),
    );
  });
}

Future<void> _writeMinimalBundledProject(Directory root) async {
  await root.create(recursive: true);
  const map = MapData(
    id: 'start',
    name: 'Start',
    size: GridSize(width: 2, height: 1),
    layers: <MapLayer>[
      CollisionLayer(
        id: 'collision',
        name: 'Collision',
        collisions: <bool>[false, false],
      ),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
    ],
  );
  const project = ProjectManifest(
    name: 'Selbrume package test',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'start',
        name: 'Start',
        relativePath: 'maps/start.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    newGame: ProjectNewGameConfig(
      enabled: true,
      startMapId: 'start',
      startSpawnId: 'spawn',
      playerName: 'Testeur',
      startingMoney: 500,
    ),
  );
  await _writeJson(File(p.join(root.path, 'project.json')), project.toJson());
  await _writeJson(File(p.join(root.path, 'maps', 'start.json')), map.toJson());
  await _writeText(
    File(p.join(root.path, 'dialogues', 'intro.yarn')),
    'title: Start\n---\nBienvenue.\n===\n',
  );
  await _writeJson(
    File(p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json')),
    <String, Object?>{'schemaVersion': 1, 'items': <Object?>[]},
  );
  await _writeJson(
    File(p.join(root.path, 'data', 'pokemon', 'catalogs', 'moves.json')),
    <String, Object?>{'schemaVersion': 1, 'moves': <Object?>[]},
  );
  await _writeJson(
    File(
      p.join(
        root.path,
        'data',
        'pokemon',
        'species',
        '0001-test.json',
      ),
    ),
    <String, Object?>{'id': 'test'},
  );
  await _writeText(
    File(p.join(root.path, 'assets', 'tilesets', 'test.png')),
    'png-placeholder',
  );
}

Future<void> _writeJson(File file, Object? value) {
  return _writeText(
    file,
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}

Future<void> _writeText(File file, String value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(value);
}

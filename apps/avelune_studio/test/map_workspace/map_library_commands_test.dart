import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  late MapLibraryCommands commands;
  setUp(() async {
    fixture = await MapCatalogFixture.create();
    commands = MapLibraryCommands(fixture.controller);
  });
  tearDown(() => fixture.dispose());

  test(
    'a new map gets a readable id, the asked size and folder, then opens',
    () async {
      final folder = await commands.createFolder('Johto');
      expect(folder.ok, isTrue, reason: folder.detail);
      final groupId = folder.groupId!;
      final created = await commands.createMap(
        name: 'Route 31',
        width: 12,
        height: 9,
        groupId: groupId,
      );
      expect(created.ok, isTrue, reason: created.detail);
      expect(created.mapId, 'route-31');
      final entry = fixture.controller.project!.maps.singleWhere(
        (map) => map.id == 'route-31',
      );
      expect(entry.name, 'Route 31');
      expect(entry.groupId, groupId);
      expect(fixture.controller.active!.base.mapId, 'route-31');
      expect(
        fixture.controller.active!.current.size,
        const GridSize(width: 12, height: 9),
      );
      final again = await commands.createMap(
        name: 'Route 31',
        width: 4,
        height: 4,
      );
      expect(again.mapId, 'route-31-2');
    },
  );

  test(
    'creation refuses an empty name or a size outside the map limits',
    () async {
      final before = await _files(fixture.root);
      expect(
        (await commands.createMap(name: '  ', width: 5, height: 5)).problem,
        MapLibraryProblem.nameRequired,
      );
      expect(
        (await commands.createMap(name: 'Grotte', width: 0, height: 5)).problem,
        MapLibraryProblem.sizeInvalid,
      );
      expect(
        (await commands.createMap(
          name: 'Grotte',
          width: 5,
          height: 100000,
        )).problem,
        MapLibraryProblem.sizeInvalid,
      );
      expect(await _files(fixture.root), before);
      expect(fixture.catalog.mutations, 0);
    },
  );

  test('duplicate, rename and move keep the map identity stable', () async {
    final folder = await commands.createFolder('Bourg Geon');
    final duplicated = await commands.duplicateMap(
      'jardin',
      name: 'Jardin des essais (copie)',
    );
    expect(duplicated.ok, isTrue, reason: duplicated.detail);
    final copyId = duplicated.mapId!;
    expect(fixture.controller.active!.base.mapId, copyId);
    final renamed = await commands.renameMap(copyId, 'Jardin du soir');
    expect(renamed.ok, isTrue, reason: renamed.detail);
    final moved = await commands.moveMap(copyId, folder.groupId);
    expect(moved.ok, isTrue, reason: moved.detail);
    final entry = fixture.controller.project!.maps.singleWhere(
      (map) => map.id == copyId,
    );
    expect(entry.name, 'Jardin du soir');
    expect(entry.groupId, folder.groupId);
    expect(fixture.controller.active!.current.name, 'Jardin du soir');
    final back = await commands.moveMap(copyId, null);
    expect(back.ok, isTrue, reason: back.detail);
    expect(
      fixture.controller.project!.maps
          .singleWhere((map) => map.id == copyId)
          .groupId,
      isNull,
    );
  });

  test('renaming to the same name or a blank name publishes nothing', () async {
    expect(
      (await commands.renameMap('jardin', ' ')).problem,
      MapLibraryProblem.nameRequired,
    );
    final same = await commands.renameMap('jardin', 'Jardin des essais');
    expect(same.ok, isTrue);
    expect(fixture.catalog.mutations, 0);
  });

  test(
    'folders are created, renamed and refused on a sibling name clash',
    () async {
      final johto = await commands.createFolder('Johto');
      final routes = await commands.createFolder(
        'Routes',
        parentId: johto.groupId,
      );
      expect(routes.ok, isTrue, reason: routes.detail);
      expect(
        (await commands.createFolder('johto')).problem,
        MapLibraryProblem.folderNameTaken,
      );
      final renamed = await commands.renameFolder(routes.groupId!, 'Chemins');
      expect(renamed.ok, isTrue, reason: renamed.detail);
      final group = fixture.controller.project!.groups.singleWhere(
        (group) => group.id == routes.groupId,
      );
      expect(group.name, 'Chemins');
      expect(group.parentGroupId, johto.groupId);
      expect(commands.folderDeletionBlocked(johto.groupId!), isTrue);
      final removed = await commands.deleteFolder(routes.groupId!);
      expect(removed.ok, isTrue, reason: removed.detail);
      expect((await commands.deleteFolder('missing')).ok, isFalse);
    },
  );

  test('a used map is refused with the names of its users', () async {
    await fixture.controller.activate(
      fixture.controller.project!.maps.singleWhere(
        (map) => map.id == 'clairiere',
      ),
    );
    final clairiere = fixture.controller.active!;
    clairiere.commit(
      clairiere.current.copyWith(
        warps: [
          const MapWarp(
            id: 'vers-jardin',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'jardin',
            targetPos: GridPos(x: 2, y: 2),
          ),
        ],
      ),
    );
    expect(await fixture.controller.save(clairiere), isTrue);
    final before = await _files(fixture.root);
    final deletion = await commands.analyzeDeletion('jardin');
    expect(deletion.allowed, isFalse);
    expect(
      deletion.usages.map((usage) => (usage.kind, usage.label)),
      contains((MapLibraryUsageKind.map, 'Clairière')),
    );
    expect(
      deletion.usages.map((usage) => usage.label),
      isNot(contains('clairiere')),
    );
    final refused = await commands.confirmDeletion(deletion);
    expect(refused.ok, isFalse);
    expect(await _files(fixture.root), before);
  });

  test(
    'an unused map is deleted after analysis and leaves the project',
    () async {
      final created = await commands.createMap(
        name: 'Brouillon',
        width: 5,
        height: 5,
      );
      final deletion = await commands.analyzeDeletion(created.mapId!);
      expect(deletion.allowed, isTrue, reason: '${deletion.failure?.detail}');
      expect(deletion.usages, isEmpty);
      final deleted = await commands.confirmDeletion(deletion);
      expect(deleted.ok, isTrue, reason: deleted.detail);
      expect(
        fixture.controller.project!.maps.map((map) => map.id),
        isNot(contains(created.mapId)),
      );
      expect(
        File(p.join(fixture.root.path, 'maps', '${created.mapId}.json'))
            .existsSync(),
        isFalse,
      );
      expect(fixture.controller.active, isNotNull);
    },
  );

  test('a dirty map cannot be deleted or renamed before its Save', () async {
    final document = fixture.controller.active!;
    document.commit(document.current.copyWith(properties: {'draft': true}));
    final rename = await commands.renameMap(document.base.mapId, 'Autre nom');
    expect(rename.ok, isFalse);
    expect(rename.detail, contains('Enregistrez'));
    final deletion = await commands.analyzeDeletion(document.base.mapId);
    expect(deletion.allowed, isFalse);
    expect(deletion.failure?.detail, contains('Enregistrez'));
    expect(fixture.catalog.mutations, 0);
  });

  test('usages are named from the project and never show raw ids', () {
    final project = ProjectManifest(
      name: 'Usages',
      maps: const [
        ProjectMapEntry(id: 'route-30', name: 'Route 30', relativePath: 'a'),
      ],
      tilesets: const [],
    );
    final usages = mapLibraryUsages({
      'dependents': [
        {
          'kind': 'sourceMap',
          'id': 'w1',
          'scope': 'map',
          'parentId': 'route-30',
          'sourceKind': 'warp',
        },
        {
          'kind': 'sourceMap',
          'id': 'c1',
          'scope': 'map',
          'parentId': 'route-30',
          'sourceKind': 'connection',
        },
        {
          'kind': 'sourceMap',
          'id': 'newGame',
          'scope': 'project',
          'sourceKind': 'newGame',
        },
        {'kind': 'scene', 'id': 'scene-inconnue'},
        {
          'kind': 'sourceMap',
          'id': 'x',
          'scope': 'map',
          'parentId': 'gone',
          'sourceKind': 'warp',
        },
      ],
    }, project);
    expect(usages, [
      const MapLibraryUsage(MapLibraryUsageKind.map, 'Route 30'),
      const MapLibraryUsage(MapLibraryUsageKind.newGame, null),
      const MapLibraryUsage(MapLibraryUsageKind.scene, null),
      const MapLibraryUsage(MapLibraryUsageKind.map, null),
    ]);
  });

  test('map ids follow the canonical id rule', () {
    expect(
      mapLibraryIdFor('Écorcia — Centre Pokémon', const {}),
      'ecorcia-centre-pokemon',
    );
    expect(mapLibraryIdFor('!!!', const {}), 'carte');
    expect(mapLibraryIdFor('Carte', const {'carte', 'carte-2'}), 'carte-3');
    expect(mapLibraryIdFor('a' * 90, const {}).length, lessThanOrEqualTo(64));
  });
}

Future<Map<String, String>> _files(Directory root) async => {
  await for (final entity in root.list(recursive: true))
    if (entity is File && !entity.path.contains('${p.separator}.'))
      p.relative(entity.path, from: root.path): base64Encode(
        await entity.readAsBytes(),
      ),
};

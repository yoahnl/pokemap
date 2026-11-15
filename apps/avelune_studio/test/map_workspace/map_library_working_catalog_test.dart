import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'map_library_counting_reader.dart';

void main() {
  late Directory root;
  late ProjectSession session;
  late CountingProjectReader reader;
  late MapWorkspaceController controller;
  late MapLibraryCommands commands;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('maps_crud_');
    root = Directory(await temporary.resolveSymbolicLinks());
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'maps-crud',
      project: ProjectManifest(
        name: 'Catalogue ciblé',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        groups: const [
          ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.route),
        ],
        maps: const [],
        tilesets: const [],
      ),
    );
    session = ProjectSession(
      sessionId: 'maps-crud',
      name: 'Catalogue ciblé',
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    reader = CountingProjectReader();
    final maps = LocalMapWorkspaceAdapter(reader: reader);
    final catalog = LocalMapCatalogAdapter(maps, fileReader: reader);
    await maps.loadCatalog(session);
    for (var i = 0; i < 4; i++) {
      final before = await maps.resourceBaseline(session);
      final receipt = await catalog.mutate(session, 'map.create', {
        'mapId': 'foreign-$i',
        'name': 'Voisine $i',
        'width': 6,
        'height': 5,
      }, expectedManifest: before.manifest);
      await catalog.reconcile(session, receipt);
    }
    controller = MapWorkspaceController(session, maps, catalogPort: catalog);
    await controller.initialize();
    commands = MapLibraryCommands(controller);
  });

  tearDown(() async {
    controller.dispose();
    await root.delete(recursive: true);
  });

  test('the scoped catalog creates, renames, organizes and duplicates maps without reading the others', () async {
    expect(controller.hasCompleteProject, isFalse);
    reader.paths.clear();

    final created = await commands.createMap(
      name: 'Route 31',
      width: 8,
      height: 6,
      groupId: 'johto',
    );
    expect(created.ok, isTrue, reason: created.detail);
    expect(controller.active?.base.mapId, 'route-31');
    expect(controller.active!.current.spatialScene, isNotNull);

    final renamed = await commands.renameMap('route-31', 'Route trente et un');
    expect(renamed.ok, isTrue, reason: renamed.detail);
    expect(controller.active!.current.name, 'Route trente et un');

    final folder = await commands.createFolder('Routes', parentId: 'johto');
    expect(folder.ok, isTrue, reason: folder.detail);
    final moved = await commands.moveMap('route-31', folder.groupId);
    expect(moved.ok, isTrue, reason: moved.detail);
    final folderRenamed = await commands.renameFolder(
      folder.groupId!,
      'Chemins',
    );
    expect(folderRenamed.ok, isTrue, reason: folderRenamed.detail);

    final copy = await commands.duplicateMap('route-31', name: 'Route 31 bis');
    expect(copy.ok, isTrue, reason: copy.detail);
    expect(controller.active?.base.mapId, copy.mapId);

    expect(reader.paths.where((path) => path.contains('foreign-')), isEmpty);

    final reopenedMaps = LocalMapWorkspaceAdapter();
    final reopened = await reopenedMaps.loadCatalog(session);
    final entries = {
      for (final entry in reopened.metadata.maps) entry.id: entry,
    };
    expect(entries['route-31']!.name, 'Route trente et un');
    expect(entries['route-31']!.groupId, folder.groupId);
    expect(entries[copy.mapId]!.name, 'Route 31 bis');
    expect(entries[copy.mapId]!.groupId, folder.groupId);
    expect(
      reopened.metadata.groups
          .singleWhere((group) => group.id == folder.groupId)
          .name,
      'Chemins',
    );
    expect(entries.keys, containsAll(['foreign-0', 'foreign-3']));
  });

  test('the scoped catalog undoes create, rename and move to the exact catalog, then redoes the creation', () async {
    final folder = await commands.createFolder('Routes', parentId: 'johto');
    final start = await _catalogFiles(root);
    final startMetadata = await _reopenedLibrary(session);
    reader.paths.clear();

    expect(
      (await commands.createMap(name: 'Route 31', width: 8, height: 6)).ok,
      isTrue,
    );
    final afterCreate = await _catalogFiles(root);
    expect(
      (await commands.renameMap('route-31', 'Route trente et un')).ok,
      isTrue,
    );
    expect((await commands.moveMap('route-31', folder.groupId)).ok, isTrue);

    for (var i = 0; i < 3; i++) {
      await controller.stepHistory(redo: false);
      expect(controller.error, isNull);
      expect(controller.active?.error, isNull);
    }
    expect(
      controller.project!.maps.map((map) => map.id),
      isNot(contains('route-31')),
    );
    expect(await _catalogFiles(root), start);
    expect(await _reopenedLibrary(session), startMetadata);

    await controller.stepHistory(redo: true);
    expect(controller.active?.error, isNull);
    expect(controller.active?.base.mapId, 'route-31');
    expect(await _catalogFiles(root), afterCreate);
    expect(reader.paths.where((path) => path.contains('foreign-')), isEmpty);
  });

  test(
    'returning to an opened map keeps the library current for the next action',
    () async {
      final first = controller.active!;
      final folder = await commands.createFolder('Routes', parentId: 'johto');
      await commands.createMap(name: 'Route 31', width: 8, height: 6);
      await controller.activate(
        controller.project!.maps.singleWhere((m) => m.id == first.base.mapId),
      );
      expect(
        controller.project!.groups.map((g) => g.id),
        contains(folder.groupId),
      );
      final renamed = await commands.renameMap('route-31', 'Autre');
      expect(renamed.ok, isTrue, reason: renamed.detail);
      expect(
        controller.project!.groups.map((g) => g.id),
        contains(folder.groupId),
      );
    },
  );

  test(
    'deletion stays closed on the scoped catalog and writes nothing',
    () async {
      expect(commands.canDelete, isFalse);
      final head = await File('${root.path}/catalog/HEAD.json').readAsString();
      final deletion = await commands.analyzeDeletion('foreign-1');
      expect(deletion.allowed, isFalse);
      expect((await commands.confirmDeletion(deletion)).ok, isFalse);
      expect(await File('${root.path}/catalog/HEAD.json').readAsString(), head);
      expect(File('${root.path}/maps/foreign-1.json').existsSync(), isTrue);
    },
  );
}

Future<Map<String, String>> _catalogFiles(Directory root) async => {
  for (final path in ['project.json', 'catalog/HEAD.json'])
    path: base64Encode(await File('${root.path}/$path').readAsBytes()),
  await for (final entity in Directory('${root.path}/maps').list())
    if (entity is File)
      entity.uri.pathSegments.last: base64Encode(await entity.readAsBytes()),
};

Future<String> _reopenedLibrary(ProjectSession session) async {
  final reopened = await LocalMapWorkspaceAdapter().loadCatalog(session);
  return jsonEncode({
    'maps': reopened.metadata.maps,
    'groups': reopened.metadata.groups,
  });
}

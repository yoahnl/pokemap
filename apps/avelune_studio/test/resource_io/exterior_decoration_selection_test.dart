import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/exterior_decoration_fixture.dart';

void main() {
  test('reopened and neutral preview selections admit resources owned only by persisted exterior visuals', () async {
    final root = await Directory.systemTemp.createTemp('exterior-selection-');
    addTearDown(() => root.delete(recursive: true));
    final project = exteriorDecorationFixtureProject();
    final working = await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'exterior-selection',
      project: project.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'oak',
              mapId: 'route',
            ),
            ResourceLibraryEntry(
              resourceKind: 'smartTilePreset',
              resourceId: 'grass',
              mapId: 'route',
            ),
          ],
        ),
        models3d: [
          ...project.models3d,
          ProjectModel3dEntry.fromJson({
            ...project.models3d.first.toJson(),
            'id': 'unrelated',
            'name': 'Unrelated',
            'relativePath': 'assets/models3d/unrelated.glb',
          }),
        ],
      ),
    );
    final map = MapData(
      id: 'route',
      name: 'Route',
      size: const GridSize(width: 16, height: 16),
      version: ProjectVersion.v9,
      spatialScene: MapSpatialScene(width: 16, depth: 16),
    );
    final mapFile = File('${root.path}/maps/route.json');
    await mapFile.parent.create(recursive: true);
    final original = utf8.encode(jsonEncode(map.toJson()));
    await mapFile.writeAsBytes(original);
    final service = LocalMapExteriorDecorationAuthoring(
      policy: await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader(),
      ),
    );
    var revision = (await service.inspect(
      projectRoot: root.path,
      mapId: 'route',
    )).revision;
    revision = (await service.configure(
      projectRoot: root.path,
      mapId: 'route',
      expectedRevision: revision,
      operationId: 'configure',
      decoration: MapExteriorDecoration(
        mapId: 'route',
        playableWidth: 16,
        playableDepth: 16,
        west: 16,
      ),
    )).afterRevision;
    revision = (await service.setSector(
      projectRoot: root.path,
      mapId: 'route',
      expectedRevision: revision,
      operationId: 'sector',
      sector: ExteriorDecorationSector(
        id: 'west',
        originX: -16,
        originZ: 0,
        scene: MapSpatialScene(width: 16, depth: 16, generateCliffs: false),
      ),
    )).afterRevision;
    final catalogRevision = await service.inspectNativeCatalogRevision(
      projectRoot: root.path,
      mapId: 'route',
    );
    for (final edit in [
      {
        'kind': 'environment.generate',
        'sectorId': 'west',
        'presetId': 'forest',
        'areaId': 'trees',
        'seed': 42,
        'cells': [
          {'x': -8, 'z': 8},
        ],
      },
      {
        'kind': 'terrain.paint',
        'sectorId': 'west',
        'presetId': 'grass',
        'cells': [
          {'x': -8, 'z': 8},
        ],
      },
      {
        'kind': 'border.draw',
        'blueprintId': 'fence',
        'borderId': 'west-fence',
        'seed': '42',
        'points': [
          {'x': -10, 'z': 2},
          {'x': -10, 'z': 8},
        ],
      },
    ]) {
      revision = (await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: revision,
        expectedCatalogRevision: catalogRevision,
        operationId: 'edit_${edit['kind']}',
        edit: edit,
      )).afterRevision;
    }
    final unused = (await working.catalog.snapshot.indexEntry(
      CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'unrelated'),
    ))!;
    await File('${root.path}/catalog/objects/${unused.reference.sha256}.json')
        .writeAsString('unrelated model must never be read');
    const entry = ProjectMapEntry(
      id: 'route',
      name: 'Route',
      relativePath: 'maps/route.json',
    );
    for (final sessionId in ['first-open', 'reopened']) {
      final session = ProjectSession(
        sessionId: sessionId,
        name: 'Route',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final adapter = LocalMapWorkspaceAdapter();
      await adapter.loadCatalog(session);
      final selected = await adapter.loadMapSelection(session, entry);
      expect(selected.document.map, map);
      expect(selected.definitions.models3d.map((model) => model.id).toSet(), {
        'oak',
        'unit',
      });
      expect(
        selected.definitions.smartTileCatalog.atlases.map((atlas) => atlas.id),
        ['grass'],
      );
      expect(selected.definitions.tilesets.map((tileset) => tileset.id), [
        'grass',
      ]);
      expect(
        selected.definitions.environmentPresets.map((preset) => preset.id),
        ['forest'],
      );
      expect(
        selected.definitions.borderCatalog.records.map((record) => record.id),
        ['fence'],
      );
      expect(
        selected.definitions.resourceLibraryCatalog.availableForMap(
          'model3d',
          'oak',
          'route',
        ),
        isTrue,
      );
      expect(
        selected.definitions.resourceLibraryCatalog.availableForMap(
          'model3d',
          'oak',
          'other-map',
        ),
        isFalse,
      );
      expect(
        selected.definitions.resourceLibraryCatalog.availableForMap(
          'smartTilePreset',
          'grass',
          'route',
        ),
        isTrue,
      );
      final before = await adapter.resourceBaseline(session);
      final preview = await adapter.loadMapPreviewSelection(session, entry);
      final after = await adapter.resourceBaseline(session);
      expect(preview.definitions.models3d.map((model) => model.id).toSet(), {
        'oak',
        'unit',
      });
      expect(
        preview.definitions.smartTileCatalog.atlases.map((atlas) => atlas.id),
        ['grass'],
      );
      expect(after.manifest, same(before.manifest));
      expect(after.revision, before.revision);
      expect(
        (await adapter.loadExteriorDecoration(
          session,
          'route',
        )).decoration!.sectors.single.scene.instances,
        isNotEmpty,
      );
    }
    expect(await mapFile.readAsBytes(), original);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture;
import '../domains/maps/environment_spatial_actions_test.dart'
    show spatialEnvironmentFixture;

void main() {
  for (final unrelated in [0, 90]) {
    test(
        'native spatial map actions stay local with $unrelated unrelated maps and models',
        () async {
      final fixture = await _Fixture.open(unrelated);
      addTearDown(fixture.close);
      final operations = <(String, Map<String, Object?>)>[
        ('environment.attach_to_spatial_terrain', {'layerId': 'env'}),
        (
          'environment.area_create',
          {
            'layerId': 'env',
            'areaId': 'forest',
            'name': 'Forest',
            'presetId': 'forest',
            'seed': 1
          }
        ),
        (
          'environment.generated_placement_adopt_batch',
          {
            'layerId': 'env',
            'areaId': 'forest',
            'placementIds': ['old-tree']
          }
        ),
      ];
      for (var i = 0; i < operations.length; i++) {
        final (action, parameters) = operations[i];
        fixture.reader.paths.clear();
        final snapshot = await fixture.api.readWorkshopSnapshot(
            fixture.opened.projectHandle,
            actionId: action,
            parameters: {'mapId': 'map', ...parameters});
        expect(snapshot.maps.map((m) => m.id), ['map']);
        expect(snapshot.manifest.models3d.map((m) => m.id), ['tree']);
        expect(snapshot.manifest.maps.map((m) => m.id), ['map']);
        await fixture.apply(action, {'mapId': 'map', ...parameters}, 'step-$i',
            revision: snapshot.revision);
        expect(
            fixture.reader.paths
                .where((p) => p.startsWith('maps/') && p != 'maps/map.json'),
            isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
            isEmpty);
        expect(fixture.reader.paths.length, lessThan(240));
      }
      for (var repeat = 0; repeat < 2; repeat++) {
        final moved = fixture.instance.copyWith(
            position: Model3dVector3(x: 2.25 + repeat, y: 3, z: 2.125));
        await fixture.apply(
            'map3d.instance.upsert_batch',
            {
              'mapId': 'map',
              'instances': [moved.toJson()]
            },
            'move-$repeat');
      }
      final result = MapData.fromJson(
          jsonDecode(await fixture.mapFile.readAsString())
              as Map<String, dynamic>);
      final area =
          (result.layers.single as EnvironmentLayer).content.areas.single;
      expect(area.manualPlacementIds, ['old-tree']);
      expect(result.spatialScene!.instances.single.position.x, 3.25);
      expect(result.properties, {'keep': 'preserved'});
      expect(
          await File('${fixture.root.path}/.pokemap/authoring/history.jsonl')
              .readAsString(),
          'unrelated legacy history\n');
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          fixture.descriptor);
      await fixture.reopen();
      final reopened = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'map3d.instance.upsert_batch',
          parameters: {
            'mapId': 'map',
            'instances': [result.spatialScene!.instances.single.toJson()]
          });
      expect(reopened.maps.single, result);
    });
  }

  test('targeted spatial publication rejects a concurrent map write', () async {
    final fixture = await _Fixture.open(90);
    addTearDown(fixture.close);
    final parameters = <String, Object?>{'mapId': 'map', 'layerId': 'env'};
    final before = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'environment.attach_to_spatial_terrain',
        parameters: parameters);
    final plan = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'stale',
            actionId: 'environment.attach_to_spatial_terrain',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: before.revision,
            idempotencyKey: 'stale',
            parameters: parameters));
    final external =
        before.maps.single.copyWith(properties: {'external': 'preserve'});
    final bytes = utf8.encode(jsonEncode(external.toJson()));
    await fixture.mapFile.writeAsBytes(bytes);
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId, operationId: 'stale'),
        throwsA(isA<Exception>()));
    expect(await fixture.mapFile.readAsBytes(), bytes);
  });

  test('JSONL adoption undo and reopen preserve exact existing instances',
      () async {
    final fixture = await _Fixture.open(90);
    addTearDown(fixture.close);
    await fixture.apply('environment.attach_to_spatial_terrain',
        {'mapId': 'map', 'layerId': 'env'}, 'attach');
    await fixture.apply(
        'environment.area_create',
        {
          'mapId': 'map',
          'layerId': 'env',
          'areaId': 'forest',
          'name': 'Forest',
          'presetId': 'forest',
          'seed': 1
        },
        'area');
    final before = await fixture.mapFile.readAsBytes();
    final parameters = <String, Object?>{
      'mapId': 'map',
      'layerId': 'env',
      'areaId': 'forest',
      'placementIds': ['old-tree']
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'environment.generated_placement_adopt_batch',
        parameters: parameters);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.root.path], fileReader: fixture.reader);
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy,
                fileReader: fixture.reader,
                handles: fixture.handles,
                catalogMetadataFields: {}),
            snapshotLoader: ProjectSnapshotLoader(handles: fixture.handles)),
        mutations: fixture.api);
    Future<AuthoringResult> command(
            String command, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
            {'id': 'jsonl-$command', 'command': command, 'args': args}))));
    final planned = await command('plan', {
      'projectHandle': fixture.opened.projectHandle.value,
      'request': AuthoringRequest(
              requestId: 'jsonl-adopt',
              actionId: 'environment.generated_placement_adopt_batch',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'jsonl-adopt',
              parameters: parameters)
          .toJson()
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: planned.toJson().toString());
    final applied = await command('apply', {
      'projectHandle': fixture.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'jsonl-adopt'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    final receipt = applied.data['receipt'] as Map;
    final after = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(after.spatialScene!.instances, [fixture.instance]);
    final undone = await command('undo', {
      'projectHandle': fixture.opened.projectHandle.value,
      'entryId': receipt['receiptId'],
      'idempotencyKey': 'jsonl-undo'
    });
    expect(undone.status, AuthoringResultStatus.success,
        reason: undone.toJson().toString());
    expect(await fixture.mapFile.readAsBytes(), before);
    await fixture.reopen();
    final reopened = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'environment.generated_placement_adopt_batch',
        parameters: parameters);
    expect(
        (reopened.maps.single.layers.single as EnvironmentLayer)
            .content
            .areas
            .single
            .manualPlacementIds,
        isEmpty);
    expect(reopened.maps.single.spatialScene!.instances, [fixture.instance]);
  });

  test(
      'terrain changes stay map-local and preserve explicit instance transforms',
      () async {
    final fixture = await _Fixture.open(90);
    addTearDown(fixture.close);
    await fixture.apply(
        'map3d.terrain.configure_appearance',
        {'mapId': 'map', 'cliffFrame': null, 'generateCliffs': false},
        'appearance');
    await fixture.apply(
        'map3d.terrain.surface.upsert_batch',
        {
          'mapId': 'map',
          'reanchorInstances': false,
          'surfaces': [
            {
              'id': 'raised',
              'x': 0,
              'z': 0,
              'height': 2,
              'footprints': [
                [
                  {'x': 0, 'z': 0},
                  {'x': 6, 'z': 0},
                  {'x': 6, 'z': 4},
                  {'x': 0, 'z': 4}
                ]
              ]
            }
          ]
        },
        'surface');
    final after = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(after.spatialScene!.generateCliffs, isFalse);
    expect(after.spatialScene!.terrainSurfaces.surfaces.single.height, 2);
    expect(after.spatialScene!.instances, [fixture.instance]);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
  });

  test('native Border create and materialization use only their model closure',
      () async {
    final source = spatialBorderAuthoringFixture(published: true);
    final fixture = await _Fixture.open(90, content: (
      project: source.project,
      map: source.map.copyWith(layers: const [])
    ));
    addTearDown(fixture.close);
    await fixture.apply(
        'map.apply_operations',
        {
          'mapId': 'map',
          'operations': [
            {
              'kind': 'layer.add',
              'layerKind': 'border',
              'layerId': 'border',
              'name': 'Native Border'
            }
          ]
        },
        'border-layer');
    await fixture.apply(
        'border_layer.feature_create',
        {
          'mapId': 'map',
          'layerId': 'border',
          'featureId': 'fence',
          'blueprintId': 'fence',
          'name': 'Fence',
          'seed': '17',
          'geometry': {
            'kind': 'stroke',
            'strokes': [
              {
                'id': 'line',
                'closed': false,
                'points': [
                  {'x': 1, 'y': 1},
                  {'x': 2, 'y': 1},
                  {'x': 3, 'y': 1}
                ]
              }
            ]
          }
        },
        'border-feature');
    await fixture.apply(
        'border_layer.materialize_batch_apply',
        {
          'mapId': 'map',
          'features': [
            {'layerId': 'border', 'featureId': 'fence'}
          ],
          'tileWidthPx': 32,
          'tileHeightPx': 32,
          'resolverVersion': borderResolverVersion
        },
        'border-materialize');
    final after = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(after.spatialScene!.instances, isNotEmpty);
    final ids = (after.layers.single as BorderLayer)
        .content
        .features
        .single
        .generatedPlacementIds;
    expect(ids.toSet(), after.spatialScene!.instances.map((i) => i.id).toSet());
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
  });

  test('native local selection retains legacy new-game fact dictionary keys',
      () async {
    final base = spatialEnvironmentFixture();
    final fixture = await _Fixture.open(90, content: (
      project: base.project.copyWith(
          newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'map',
              initialFacts: {'fact-ready': true}),
          facts: [NarrativeFactDefinition(id: 'fact-ready', label: 'Ready')]),
      map: base.map
    ));
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    final selected = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'map3d.instance.upsert',
        parameters: {'mapId': 'map', 'instance': fixture.instance.toJson()});
    expect(selected.manifest.facts.map((fact) => fact.id), ['fact-ready']);
    expect(selected.manifest.newGame.initialFacts, {'fact-ready': true});
    expect(() => ProjectValidator.validate(selected.manifest), returnsNormally);
    expect(
        fixture.reader.paths.where(
            (path) => path.startsWith('maps/') && path != 'maps/map.json'),
        isEmpty);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
  });

  test(
      'native 2D map edits retain targeted persistence and concurrent-write checks',
      () async {
    final base = spatialEnvironmentFixture();
    final fixture = await _Fixture.open(90, content: (
      project: base.project.copyWith(
          version: ProjectVersion.v8,
          settings: base.project.settings
              .copyWith(dimension: ProjectDimension.twoD, spatialCamera: null),
          smartTileCatalog: _groundCatalog(),
          tilesets: const [
            ProjectTilesetEntry(
                id: 'ground-image',
                name: 'Ground',
                relativePath: 'assets/ground.png')
          ]),
      map: const MapData(
          version: ProjectVersion.v8,
          id: 'map',
          name: 'Map',
          size: GridSize(width: 6, height: 4))
    ));
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    await fixture.apply(
        'map.apply_operations',
        {
          'mapId': 'map',
          'operations': [
            {
              'kind': 'layer.add',
              'layerKind': 'environment',
              'layerId': 'env-2d',
              'name': 'Forest'
            },
            {
              'kind': 'layer.add',
              'layerKind': 'border',
              'layerId': 'border-2d',
              'name': 'Walls'
            }
          ]
        },
        'create-2d-native-layers');
    await fixture.apply(
        'smart_tile.layer.create',
        {
          'mapId': 'map',
          'presetId': 'ground',
          'layerId': 'path',
          'name': 'Path'
        },
        'create-2d-path');
    await fixture.apply(
        'smart_tile.cell.paint',
        {
          'mapId': 'map',
          'layerId': 'path',
          'materialId': 'grass',
          'cells': [
            {'x': 1, 'y': 1}
          ]
        },
        'paint-2d-path');
    final painted = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(
        smartTileSemanticCells(
                painted.layers.whereType<SmartTileLayer>().single)
            .where((cell) => cell > 0),
        hasLength(1));
    final parameters = <String, Object?>{'mapId': 'map', 'layerId': 'path'};
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'smart_tile.layer.delete',
        parameters: parameters);
    final plan = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'stale-2d',
            actionId: 'smart_tile.layer.delete',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'stale-2d',
            parameters: parameters));
    final confirmation = await fixture.api
        .confirmMutation(fixture.opened.projectHandle, planId: plan.planId);
    final external = utf8.encode(jsonEncode(
        painted.copyWith(properties: {'external': 'preserve'}).toJson()));
    await fixture.mapFile.writeAsBytes(external);
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId,
            operationId: 'stale-2d',
            confirmationToken: confirmation.confirmationToken),
        throwsA(isA<Exception>()));
    expect(await fixture.mapFile.readAsBytes(), external);
    await fixture.apply('smart_tile.layer.delete', parameters, 'delete-2d-path',
        confirm: true);
    final deleted = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(deleted.layers.whereType<SmartTileLayer>(), isEmpty);
    expect(deleted.layers.whereType<EnvironmentLayer>(), hasLength(1));
    expect(deleted.layers.whereType<BorderLayer>(), hasLength(1));
    expect(deleted.properties, {'external': 'preserve'});
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        fixture.descriptor);
    expect(
        fixture.reader.paths.where(
            (path) => path.startsWith('maps/') && path != 'maps/map.json'),
        isEmpty);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
    await fixture.reopen();
    final reopened = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'smart_tile.layer.create',
        parameters: {
          'mapId': 'map',
          'presetId': 'ground',
          'layerId': 'next',
          'name': 'Next'
        });
    expect(reopened.maps.single, deleted);
  });

  test('native Smart Tile map edits do not load unrelated maps or resources',
      () async {
    final base = spatialEnvironmentFixture();
    final catalog = _groundCatalog();
    final fixture = await _Fixture.open(90, content: (
      project: base.project.copyWith(
          smartTileCatalog: catalog,
          maps: [base.project.maps.single.copyWith(groupId: 'child')],
          groups: const [
            ProjectMapGroup(
                id: 'root-group', name: 'Region', type: MapGroupType.route),
            ProjectMapGroup(
                id: 'parent',
                name: 'Routes',
                type: MapGroupType.route,
                parentGroupId: 'root-group'),
            ProjectMapGroup(
                id: 'child',
                name: 'Route',
                type: MapGroupType.route,
                parentGroupId: 'parent'),
          ],
          dialogueFolders: const [
            ProjectDialogueFolder(id: 'root-folder', name: 'Root'),
            ProjectDialogueFolder(
                id: 'parent-folder',
                name: 'Parent',
                parentFolderId: 'root-folder'),
            ProjectDialogueFolder(
                id: 'child-folder',
                name: 'Child',
                parentFolderId: 'parent-folder'),
          ],
          dialogues: const [
            ProjectDialogueEntry(
                id: 'intro',
                name: 'Intro',
                relativePath: 'dialogues/intro.yarn',
                folderId: 'child-folder')
          ],
          characters: const [
            ProjectCharacterEntry(
                id: 'avatar', name: 'Avatar', tilesetId: 'ground-image')
          ],
          facts: [
            NarrativeFactDefinition(id: 'fact-legacy', label: 'Legacy'),
            NarrativeFactDefinition(
                id: 'fact-count',
                label: 'Count',
                initialValue: NarrativeValue.integer(0)),
            NarrativeFactDefinition(id: 'fact-avatar', label: 'Avatar'),
            NarrativeFactDefinition(id: 'fact-party', label: 'Party'),
          ],
          newGame: ProjectNewGameConfig(
              enabled: true,
              startMapId: 'other-0',
              playerAvatarCharacterIds: ['avatar'],
              initialFacts: {'fact-legacy': true},
              initialFactValues: {'fact-count': NarrativeValue.integer(3)},
              initialFactValuesByAvatarCharacterId: {
                'avatar': {'fact-avatar': NarrativeValue.boolean(true)}
              },
              existingPartyFactId: 'fact-party'),
          tilesets: const [
            ProjectTilesetEntry(
                id: 'ground-image',
                name: 'Ground',
                relativePath: 'assets/ground.png')
          ]),
      map: base.map.copyWith(entities: const [
        MapEntity(
            id: 'guide',
            kind: MapEntityKind.sign,
            pos: GridPos(x: 3, y: 2),
            sign: MapEntitySignData(dialogue: DialogueRef(dialogueId: 'intro')))
      ])
    ));
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    final selected = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'smart_tile.layer.create',
        parameters: {
          'mapId': 'map',
          'presetId': 'ground',
          'layerId': 'path',
          'name': 'Path'
        });
    expect(selected.manifest.groups.map((value) => value.id),
        ['root-group', 'parent', 'child']);
    expect(selected.manifest.dialogueFolders.map((value) => value.id),
        ['root-folder', 'parent-folder', 'child-folder']);
    expect(selected.manifest.dialogues.map((value) => value.id), ['intro']);
    expect(selected.manifest.facts.map((value) => value.id).toSet(),
        {'fact-legacy', 'fact-count', 'fact-avatar', 'fact-party'});
    expect(selected.manifest.maps.map((value) => value.id), ['map', 'other-0']);
    expect(selected.manifest.characters.map((value) => value.id), ['avatar']);
    await fixture.apply(
        'smart_tile.layer.create',
        {
          'mapId': 'map',
          'presetId': 'ground',
          'layerId': 'path',
          'name': 'Path'
        },
        'create-native-path');
    await fixture.apply(
        'smart_tile.cell.paint',
        {
          'mapId': 'map',
          'layerId': 'path',
          'materialId': 'grass',
          'cells': [
            {'x': 1, 'y': 1}
          ]
        },
        'paint-native-path');
    final painted = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(
        smartTileSemanticCells(
                painted.layers.whereType<SmartTileLayer>().single)
            .where((v) => v > 0),
        hasLength(1));
    await fixture.apply(
        'smart_tile.cell.erase',
        {
          'mapId': 'map',
          'layerId': 'path',
          'cells': [
            {'x': 1, 'y': 1}
          ]
        },
        'erase-native-path');
    final erased = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(
        smartTileSemanticCells(erased.layers.whereType<SmartTileLayer>().single)
            .where((v) => v > 0),
        isEmpty);
    expect(
        fixture.reader.paths.where(
            (path) => path.startsWith('maps/') && path != 'maps/map.json'),
        isEmpty);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        fixture.descriptor);
    await fixture.reopen();
    final reopened = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'smart_tile.cell.paint',
        parameters: {
          'mapId': 'map',
          'layerId': 'path',
          'materialId': 'grass',
          'cells': [
            {'x': 1, 'y': 1}
          ]
        });
    expect(reopened.maps.single, erased);
  });
}

final class _Fixture {
  _Fixture(this.root, this.opened, this.handles, this.api, this.reader,
      this.unrelatedObjects, this.descriptor, this.instance);
  final Directory root;
  OpenedProject opened;
  final WorkspaceHandleStore handles;
  LocalMapAuthoringMutationApi api;
  final _CountingReader reader;
  final Set<String> unrelatedObjects;
  final List<int> descriptor;
  final SpatialModelInstance instance;
  File get mapFile => File('${root.path}/maps/map.json');

  static Future<_Fixture> open(int unrelated,
      {({ProjectManifest project, MapData map})? content}) async {
    final root = await Directory.systemTemp.createTemp('scoped-spatial-');
    final base = content ?? spatialEnvironmentFixture();
    final model = base.project.models3d.single;
    final project = base.project.copyWith(maps: [
      base.project.maps.single,
      for (var i = 0; i < unrelated; i++)
        ProjectMapEntry(
            id: 'other-$i',
            name: 'Other $i',
            relativePath: 'maps/other-$i.json')
    ], models3d: [
      model,
      for (var i = 0; i < unrelated; i++)
        ProjectModel3dEntry.fromJson({
          ...model.toJson(),
          'id': 'unused-$i',
          'name': 'Unused $i',
          'relativePath': 'assets/models3d/unused-$i.glb'
        })
    ]);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'spatial-local', project: project);
    final unrelatedObjects = <String>{};
    for (var i = 0; i < unrelated; i++) {
      final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'unused-$i')))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      unrelatedObjects.add(path);
      await File('${root.path}/$path')
          .writeAsString('unrelated model must not be read');
      final foreign = File('${root.path}/maps/other-$i.json');
      await foreign.parent.create(recursive: true);
      await foreign.writeAsString('unrelated map must not be decoded');
    }
    final instance = SpatialModelInstance(
        id: 'old-tree',
        modelId: 'tree',
        position: Model3dVector3(x: 1.25, y: 3, z: 2.125),
        rotationDegrees: 25,
        scale: .8,
        blocksMovement: false,
        castsShadows: false);
    final map = content?.map ??
        base.map.copyWith(
            properties: {'keep': 'preserved'},
            layers: const [MapLayer.environment(id: 'env', name: 'Forest')],
            spatialScene:
                base.map.spatialScene!.copyWith(instances: [instance]));
    final file = File('${root.path}/maps/map.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
    final reader = _CountingReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    await history.parent.create(recursive: true);
    await history.writeAsString('unrelated legacy history\n');
    return _Fixture(root, opened, handles, api, reader, unrelatedObjects,
        await File('${root.path}/project.json').readAsBytes(), instance);
  }

  Future<AuthoringMutationResult> apply(
      String action, Map<String, Object?> parameters, String operation,
      {String? revision, bool confirm = false}) async {
    final selected = revision ??
        (await api.readWorkshopSnapshot(opened.projectHandle,
                actionId: action, parameters: parameters))
            .revision;
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: selected,
            idempotencyKey: operation,
            parameters: parameters));
    final token = confirm
        ? (await api.confirmMutation(opened.projectHandle, planId: plan.planId))
            .confirmationToken
        : null;
    return api.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: operation, confirmationToken: token);
  }

  Future<void> reopen() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final List<String> paths = [];
  final LocalProjectFileReader delegate = const LocalProjectFileReader();
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}

ProjectSmartTileCatalog _groundCatalog() =>
    ProjectSmartTileCatalog.fromJson(jsonDecode(jsonEncode({
      'formatVersion': 8,
      'atlases': [
        {
          'id': 'ground-atlas',
          'name': 'Ground',
          'tilesetId': 'ground-image',
          'cellWidth': 32,
          'cellHeight': 32,
          'columns': 1,
          'rows': 1
        }
      ],
      'materials': [
        {'id': 'grass', 'name': 'Grass', 'connectionGroupId': 'grass'}
      ],
      'presets': [
        {
          'id': 'ground',
          'name': 'Ground',
          'usage': 'path',
          'topology': 'uniform',
          'status': 'published',
          'templateHint': 'simple',
          'coveragePolicy': 'sparse',
          'coverageProfile': {'mode': 'template'},
          'transformPolicy': {},
          'defaultMaterialId': 'grass',
          'allowedMaterialIds': ['grass'],
          'rules': [
            {
              'id': 'ground',
              'centerMatch': {'kind': 'material', 'materialId': 'grass'},
              'candidates': [
                {
                  'id': 'native',
                  'parts': [
                    {
                      'source': {
                        'kind': 'frame',
                        'frame': {
                          'atlasId': 'ground-atlas',
                          'column': 0,
                          'row': 0
                        }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    })) as Map<String, dynamic>);

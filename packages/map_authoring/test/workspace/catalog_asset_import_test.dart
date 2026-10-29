import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_resource_positions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:image/image.dart' as img;
import '../support/glb_fixture.dart';
import '../domains/maps/border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture;

void main() {
  for (final unrelated in [0, 80]) {
    test('unpublished Border draft edits stay local with $unrelated foreign units',
        () async {
      final fixture = await _Fixture.open(unrelated,
          rootPath: '/Users/karim/Library/Caches/AveluneQA/chapter7-native-construction/api/unpublished-border-$unrelated');
      addTearDown(fixture.close);
      final artifact = await fixture.api.artifacts
          .put(triangleGlb(), declaredMediaType: 'model/gltf-binary');
      final imported = await fixture.plan('model3d.import', {
        'modelId': 'tree',
        'name': 'Tree',
        'artifactHandle': artifact.reference.handle,
      }, 'import-source');
      await fixture.api.applyMutation(fixture.opened.projectHandle,
          planId: imported.planId, operationId: 'import-source');
      final border = jsonDecode(jsonEncode(encodeBorderBlueprintRecordJson(
          spatialBorderAuthoringFixture().project.borderCatalog.records.single,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion))) as Map<String, dynamic>;
      final created = await fixture.plan('border.blueprint.draft.upsert',
          {'record': border}, 'create-draft');
      await fixture.api.applyMutation(fixture.opened.projectHandle,
          planId: created.planId, operationId: 'create-draft');
      await fixture.reopen();
      for (var repeat = 0; repeat < 2; repeat++) {
        (border['draft']['definition'] as Map)['name'] = 'Contact $repeat';
        fixture.reader.paths.clear();
        fixture.reader.probes.clear();
        final edited = await fixture.plan('border.blueprint.draft.upsert',
            {'record': border}, 'edit-draft-$repeat');
        await fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: edited.planId, operationId: 'edit-draft-$repeat');
        expect(fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
        expect(fixture.reader.paths.where((path) => path.endsWith('history.jsonl')), isEmpty);
        expect(fixture.reader.paths.length, lessThan(220));
        expect(fixture.reader.probes.length, lessThan(160));
      }
      await fixture.reopen();
      final snapshot = (await fixture.store.openRoot((await fixture.store.readHead())!)).snapshot;
      final saved = decodeBorderBlueprintRecordJson(
          (await snapshot.lookup(CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, border['id'] as String)))!.payload['value'],
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
      expect(saved.draft.definition.name, 'Contact 1');
      expect(saved.latestPublished, isNull);
      final published = await fixture.plan('border.blueprint.publish',
          {'blueprintId': border['id']}, 'publish-draft');
      await fixture.api.applyMutation(fixture.opened.projectHandle,
          planId: published.planId, operationId: 'publish-draft');
      await expectLater(fixture.plan('border.blueprint.draft.upsert',
          {'record': border}, 'published-edit'), throwsA(anything));
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptor);
    });
  }
  for (final unrelated in [0, 80]) {
    test('new model and tileset imports preserve $unrelated unread resources',
        () async {
      final fixture = await _Fixture.open(unrelated);
      addTearDown(fixture.close);
      final descriptor =
          await File('${fixture.root.path}/project.json').readAsBytes();
      final glb = triangleGlb();
      final png = img.encodePng(img.Image(width: 16, height: 16));
      for (var repeat = 0; repeat < 2; repeat++) {
        final modelArtifact = await fixture.api.artifacts
            .put(glb, declaredMediaType: 'model/gltf-binary');
        final tileArtifact = await fixture.api.artifacts
            .put(png, declaredMediaType: 'image/png');
        final operations = [
          (
            'model3d.import',
            <String, Object?>{
              'modelId': 'house-$repeat',
              'name': 'House',
              'artifactHandle': modelArtifact.reference.handle
            }
          ),
          (
            'tileset.import_image',
            <String, Object?>{
              'tilesetId': 'ground-$repeat',
              'name': 'Ground',
              'artifactHandle': tileArtifact.reference.handle,
              'tileWidth': 16,
              'tileHeight': 16
            }
          ),
        ];
        for (final (action, parameters) in operations) {
          fixture.reader.paths.clear();
          fixture.reader.probes.clear();
          final beforeObjects =
              await Directory('${fixture.root.path}/catalog/objects')
                  .list()
                  .length;
          final plan =
              await fixture.plan(action, parameters, '$action-$repeat');
          expect(plan.plan.changeSet.changes.length, lessThanOrEqualTo(4));
          await fixture.api.applyMutation(fixture.opened.projectHandle,
              planId: plan.planId, operationId: '$action-$repeat');
          expect(fixture.reader.paths.length, lessThan(210));
          expect(fixture.reader.probes.length, lessThan(150));
          final afterObjects =
              await Directory('${fixture.root.path}/catalog/objects')
                  .list()
                  .length;
          expect(afterObjects - beforeObjects, lessThan(30));
          expect(fixture.reader.paths.where(fixture.unrelatedPaths.contains),
              isEmpty);
        }
        expect(fixture.reader.paths.where(fixture.unrelatedPaths.contains),
            isEmpty);
        expect(
            await File('${fixture.root.path}/assets/models3d/house-$repeat.glb')
                .readAsBytes(),
            glb);
        expect(
            await File('${fixture.root.path}/assets/studio/ground-$repeat.png')
                .readAsBytes(),
            png);
      }
      await fixture.reopen();
      final stored =
          (await fixture.store.openRoot((await fixture.store.readHead())!))
              .snapshot;
      for (var repeat = 0; repeat < 2; repeat++) {
        for (final (kind, id) in [
          (CatalogDefinitionKind.model3d, 'house-$repeat'),
          (CatalogDefinitionKind.tileset, 'ground-$repeat')
        ]) {
          final unit = (await stored.lookup(CatalogDefinitionKey(kind, id)))!;
          expect(unit.payload['position'], unrelated + repeat);
        }
      }
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          descriptor);
    });
  }
  test(
      'model batch import is atomic, survives undo and refuses duplicate identities',
      () async {
    final fixture = await _Fixture.open(80);
    addTearDown(fixture.close);
    final artifact = await fixture.api.artifacts
        .put(triangleGlb(), declaredMediaType: 'model/gltf-binary');
    final parameters = <String, Object?>{
      'models': [
        for (final id in ['batch-a', 'batch-b'])
          {
            'modelId': id,
            'name': id,
            'artifactHandle': artifact.reference.handle
          },
      ]
    };
    fixture.reader.paths.clear();
    final plan =
        await fixture.plan('model3d.import_batch', parameters, 'batch');
    final result = await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: plan.planId, operationId: 'batch');
    expect(
        await File('${fixture.root.path}/assets/models3d/batch-a.glb').exists(),
        isTrue);
    expect(
        await File('${fixture.root.path}/assets/models3d/batch-b.glb').exists(),
        isTrue);
    await expectLater(
        fixture.plan('model3d.import_batch', parameters, 'duplicate-batch'),
        throwsA(isA<FormatException>()));
    await fixture.reopen();
    await fixture.api.undoMutation(fixture.opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'undo-batch');
    expect(
        await File('${fixture.root.path}/assets/models3d/batch-a.glb').exists(),
        isFalse);
    expect(
        await File('${fixture.root.path}/assets/models3d/batch-b.glb').exists(),
        isFalse);
    expect(
        fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
  });

  test(
      'asset position preparation reads selected definitions but no maps or binary sources',
      () async {
    final fixture = await _Fixture.open(80, legacyPositions: true);
    addTearDown(fixture.close);
    final artifact = await fixture.api.artifacts
        .put(triangleGlb(), declaredMediaType: 'model/gltf-binary');
    final parameters = <String, Object?>{
      'modelId': 'prepared',
      'name': 'Prepared',
      'artifactHandle': artifact.reference.handle
    };
    await expectLater(
        fixture.plan('model3d.import', parameters, 'unprepared'),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('preparation_required'))));
    fixture.reader.paths.clear();
    await fixture.api.prepareWorkshopDocument(fixture.opened.projectHandle,
        scope: 'assetImport');
    expect(
        fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
    final plan = await fixture.plan('model3d.import', parameters, 'prepared');
    await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: plan.planId, operationId: 'prepared');
    final snapshot =
        (await fixture.store.openRoot((await fixture.store.readHead())!))
            .snapshot;
    expect(
        await CatalogResourcePositions.read(
            snapshot, CatalogDefinitionKind.model3d),
        81);
    expect(
        await CatalogResourcePositions.read(
            snapshot, CatalogDefinitionKind.tileset),
        80);
  });

  for (final unrelated in [0, 80]) {
    test(
        'new native terrain and Border definitions select their referenced assets only with $unrelated foreign units',
        () async {
      final fixture = await _Fixture.open(unrelated, categoryFamilies: true);
      addTearDown(fixture.close);
      final glb = await fixture.api.artifacts
          .put(triangleGlb(), declaredMediaType: 'model/gltf-binary');
      final png = await fixture.api.artifacts.put(
          img.encodePng(img.Image(width: 16, height: 16)),
          declaredMediaType: 'image/png');
      final border = jsonDecode(jsonEncode(encodeBorderBlueprintRecordJson(
              spatialBorderAuthoringFixture()
                  .project
                  .borderCatalog
                  .records
                  .single,
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion))
          .replaceAll('tree', 'house')) as Map<String, dynamic>;
      (border['draft']['definition'] as Map)['categoryId'] = 'visual';
      final operations = [
        (
          'model3d.import',
          <String, Object?>{
            'modelId': 'house',
            'name': 'House',
            'artifactHandle': glb.reference.handle
          }
        ),
        (
          'tileset.import_image',
          <String, Object?>{
            'tilesetId': 'ground',
            'name': 'Ground',
            'artifactHandle': png.reference.handle,
            'tileWidth': 16,
            'tileHeight': 16
          }
        ),
        ('tileset.upsert', <String, Object?>{'tileset': {'id': 'actor-atlas', 'name': 'Actor atlas', 'relativePath': 'assets/studio/ground.png', 'source': {'kind':'regular_atlas', 'assetId':'image_ground', 'pixelWidth':16, 'pixelHeight':16, 'tileWidth':16, 'tileHeight':16, 'tileProperties':[]}}}),
        ('campaign.character.upsert', <String, Object?>{'value': {'id':'walker', 'name':'Walker', 'tilesetId':'actor-atlas', 'frameWidth':1, 'frameHeight':1, 'animations':[]}}),
        ('resource.classify_batch', <String, Object?>{'entries': [{'resourceKind':'character','resourceId':'walker','familyId':'characters','role':'standard','mapId':null}, {'resourceKind':'tileset','resourceId':'actor-atlas','familyId':'characters','role':'component','mapId':null}]}),
        (
          'smart_tile.atlas.upsert',
          <String, Object?>{
            'atlas': {
              'id': 'ground-atlas',
              'name': 'Ground',
              'tilesetId': 'ground',
              'cellWidth': 16,
              'cellHeight': 16,
              'columns': 1,
              'rows': 1
            }
          }
        ),
        (
          'smart_tile.animation.upsert',
          <String, Object?>{
            'animation': {
              'id': 'ground-cycle',
              'name': 'Ground cycle',
              'frames': [
                {
                  'frame': {'atlasId': 'ground-atlas', 'column': 0, 'row': 0},
                  'durationMs': 120
                }
              ],
              'sync': 'global',
              'loop': 'repeat'
            }
          }
        ),
        (
          'smart_tile.material.upsert_batch',
          <String, Object?>{
            'materials': [
              {'id': 'grass', 'name': 'Grass', 'connectionGroupId': 'grass'}
            ]
          }
        ),
        (
          'smart_tile.preset.publish',
          <String, Object?>{
            'preset': {
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
                            'kind': 'animation',
                            'animationId': 'ground-cycle'
                          }
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          }
        ),
        (
          'environment.preset.upsert',
          <String, Object?>{
            'preset': encodeEnvironmentPreset(EnvironmentPreset(
                id: 'garden',
                name: 'Garden',
                templateId: 'forest',
                categoryId: 'visual',
                palette: [EnvironmentPaletteItem(modelId: 'house', weight: 1)],
                defaultParams: EnvironmentGenerationParams.standard(),
                sortOrder: 0))
          }
        ),
        ('border.blueprint.draft.upsert', <String, Object?>{'record': border}),
        ('border.blueprint.publish', <String, Object?>{'blueprintId': 'fence'}),
      ];
      for (final (action, parameters) in operations) {
        fixture.reader.paths.clear();
        fixture.reader.probes.clear();
        final beforeObjects =
            await Directory('${fixture.root.path}/catalog/objects')
                .list()
                .length;
        final plan = await fixture.plan(action, parameters, action);
        expect(plan.plan.changeSet.changes.length, lessThanOrEqualTo(4));
        await fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId, operationId: action);
        expect(fixture.reader.paths.length, lessThan(220), reason: action);
        expect(fixture.reader.probes.length, lessThan(160), reason: action);
        final afterObjects =
            await Directory('${fixture.root.path}/catalog/objects')
                .list()
                .length;
        expect(afterObjects - beforeObjects, lessThan(30), reason: action);
        expect(fixture.reader.paths.where(fixture.unrelatedPaths.contains),
            isEmpty);
      }
      expect(
          fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
      await fixture.reopen();
      final root =
          (await fixture.store.openRoot((await fixture.store.readHead())!))
              .snapshot;
      final preset = (await root.lookup(CatalogDefinitionKey(
              CatalogDefinitionKind.smartTilePreset, 'ground')))!
          .payload['value'] as Map;
      expect(preset['status'], 'published');
      final animation = (await root.lookup(CatalogDefinitionKey(
              CatalogDefinitionKind.smartTileAnimation, 'ground-cycle')))!
          .payload['value'] as Map;
      expect((animation['frames'] as List).single['frame']['atlasId'],
          'ground-atlas');
      expect((await root.lookup(CatalogDefinitionKey(CatalogDefinitionKind.resourceLibraryEntry, 'character:walker')))!.payload['value'], containsPair('familyId', 'characters'));
      for(var i=0;i<unrelated;i++) expect(await root.lookup(CatalogDefinitionKey(CatalogDefinitionKind.resourceLibraryEntry, 'tileset:foreign-$i')), isNotNull);
      final savedBorder = decodeBorderBlueprintRecordJson(
          (await root.lookup(CatalogDefinitionKey(
                  CatalogDefinitionKind.borderRecord, 'fence')))!
              .payload['value'],
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
      expect(savedBorder.latestPublished?.revision, 1);
      await expectLater(
          fixture.plan('border.blueprint.publish', {'blueprintId': 'fence'},
              'republish'),
          throwsA(anything));
    });
  }
}

final class _Fixture {
  _Fixture(this.root, this.store, this.opened, this.handles, this.api,
      this.reader, this.unrelatedPaths, this.descriptor);
  final Directory root;
  final CatalogStorageStore store;
  OpenedProject opened;
  final WorkspaceHandleStore handles;
  LocalMapAuthoringMutationApi api;
  final _CountingReader reader;
  final Set<String> unrelatedPaths;
  final List<int> descriptor;

  static Future<_Fixture> open(
    int unrelated, {
    String? rootPath,
    List<ProjectMapEntry> extraMaps = const [],
    AuthoringTransactionFaultInjector? faultInjector,
    bool legacyPositions = false,
    bool categoryFamilies = false,
  }) async {
    final root = Directory(rootPath ??
        '/Users/karim/Library/Caches/AveluneQA/hgss-mauville-maps/api/assets-fixture');
    await root.create(recursive: true);
    final project = ProjectManifest(
      name: 'Map creation',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()),
      maps: [
        ...extraMaps,
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
              id: 'foreign-$i',
              name: 'Foreign $i',
              relativePath: 'maps/foreign-$i.json')
      ],
      elementCategories: [
        if (categoryFamilies) ...[
          const ProjectElementCategory(
              id: 'visual', name: 'Visual', parentCategoryId: 'parent'),
          const ProjectElementCategory(id: 'parent', name: 'Parent'),
        ],
      ],
      smartTileCatalog: ProjectSmartTileCatalog(categories: [
        if (categoryFamilies)
          const ProjectSmartTileCategory(id: 'visual', name: 'Foreign'),
      ]),
      models3d: [
        for (var i = 0; i < unrelated; i++)
          ProjectModel3dEntry(
              id: 'foreign-$i',
              name: 'Foreign $i',
              sourceAssetId: 'foreign-model-$i',
              relativePath: 'assets/models3d/foreign-$i.glb',
              inspection: const GlbModel3dInspector().inspect(triangleGlb()))
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(entries: [for (var i=0;i<unrelated;i++) ResourceLibraryEntry(resourceKind:'tileset',resourceId:'foreign-$i',familyId:'characters')]),
      tilesets: [
        for (var i = 0; i < unrelated; i++)
          ProjectTilesetEntry(
              id: 'foreign-$i',
              name: 'Foreign $i',
              relativePath: 'assets/foreign-$i.png')
      ],
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'map-creation', project: project);
    if (legacyPositions) {
      final patch = await working.catalog.snapshot.patch(removals: [
        CatalogResourcePositions.key(CatalogDefinitionKind.model3d),
        CatalogResourcePositions.key(CatalogDefinitionKind.tileset),
      ]);
      await store.gateway.withExclusiveWriteLock(() async {
        await store.publishObjectsUnderLock(patch.objects);
        await File('${root.path}/catalog/HEAD.json')
            .writeAsBytes(CatalogStorageStore.encodeHead(patch.root));
        final snapshot = await patch.nextSnapshot(readObject: store.readObject);
        await store.publishIndexAdmissionUnderLock(snapshot);
        await store.publishMetadataIndexAdmissionUnderLock(snapshot);
      });
    }
    final unrelatedPaths = <String>{};
    if (categoryFamilies) {
      final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(
              CatalogDefinitionKind.smartTileCategory, 'visual')))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      unrelatedPaths.add(path);
      await File('${root.path}/$path')
          .writeAsString('foreign homonymous category must remain unread');
    }
    for (var i = 0; i < unrelated; i++) {
      final mapPath = 'maps/foreign-$i.json';
      unrelatedPaths.add(mapPath);
      final file = File('${root.path}/$mapPath');
      await file.parent.create(recursive: true);
      await file.writeAsString('foreign map must remain unread');
      for (final key in [
        CatalogMetadataDocuments.definitionKey('maps', i + extraMaps.length),
        if (!legacyPositions) ...[
          CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'foreign-$i'),
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'foreign-$i')
        ]
      ]) {
        final entry = (await working.catalog.snapshot.indexEntry(key))!;
        final path = 'catalog/objects/${entry.reference.sha256}.json';
        unrelatedPaths.add(path);
        await File('${root.path}/$path')
            .writeAsString('foreign definition must remain unread');
      }
    }
    final descriptor = await File('${root.path}/project.json').readAsBytes();
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
        faultInjector: faultInjector,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    await history.parent.create(recursive: true);
    await history.writeAsString('foreign old history must remain unread\n' *
        (unrelated == 0 ? 100 : 10000));
    return _Fixture(
        root, store, opened, handles, api, reader, unrelatedPaths, descriptor);
  }

  Future<AuthoringMutationPlanResult> plan(
      String action, Map<String, Object?> parameters, String operation) async {
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: action, parameters: parameters);
    return api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: parameters, extensions: const {'workshopScope': true}));
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
  final paths = <String>[];
  final probes = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<ProjectResourceProbe> probeResource(
      {required String projectRoot, required String relativePath}) {
    probes.add(relativePath);
    return delegate.probeResource(
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

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}

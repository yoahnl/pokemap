import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/glb_fixture.dart';
import '../support/resource_index_fixture.dart';

void main() {
  test('explicit maintenance can prune more than one import-sized batch',
      () async {
    final ids = [for (var index = 0; index < 51; index++) 'remove-$index'];
    final f = await _pruneFixture(modelIds: ['keep', ...ids]);
    final plan = await _prunePlan(f, ids, 'maintenance-batch');
    final confirmation = await f.api.confirmMutation(f.opened.projectHandle,
        planId: plan.planId);
    final result = await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId, operationId: 'maintenance-batch',
        confirmationToken: confirmation.confirmationToken);
    final reopened = await ResourceIndexFixture.openExisting(f.root);
    try {
      final catalog = await reopened.catalog();
      expect((await catalog.page(kind: CatalogDefinitionKind.model3d)).items
          .map((entry) => entry.key.id), ['keep']);
      expect(await File('${f.root.path}/assets/models3d/keep.glb').readAsBytes(),
          triangleGlb());
    } finally {
      await reopened.close();
    }
    await f.api.undoMutation(f.opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'undo-maintenance-batch');
    expect(await File('${f.root.path}/assets/models3d/remove-50.glb').readAsBytes(),
        triangleGlb());
  });

  test('maintenance planning reuses its audited definitions after freshness checks',
      () async {
    final f = await _pruneFixture(
        modelIds: ['remove', 'keep', 'middle', 'tail']);
    f.reader.clear();
    await _prunePlan(f, ['remove'], 'unchanged-reads');
    expect(f.reader.decodedUnits['model3d:keep'], lessThanOrEqualTo(2));
  });

  for (final dependency in ['map', 'source']) {
    test('cached maintenance audit rejects a changed $dependency before planning',
        () async {
      final f = await _pruneFixture();
      final parameters = <String, Object?>{'modelIds': ['remove']};
      final snapshot = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
          actionId: 'model3d.prune_unused', parameters: parameters);
      if (dependency == 'map') {
        final file = File('${f.root.path}/maps/field.json');
        final map = MapData.fromJson(jsonDecode(await file.readAsString())
            as Map<String, dynamic>);
        await file.writeAsString(jsonEncode(map.copyWith(name: 'Changed').toJson()));
      } else {
        await File('${f.root.path}/assets/models3d/remove.glb')
            .writeAsBytes([...triangleGlb(), 0]);
      }
      await expectLater(
          f.api.planMutation(f.opened.projectHandle,
              AuthoringRequest(
                  requestId: 'cached-stale-$dependency',
                  actionId: 'model3d.prune_unused',
                  actionVersion: 1,
                  workspaceHandle: f.opened.workspaceHandle.value,
                  parameters: parameters,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: 'cached-stale-$dependency',
                  extensions: const {'workshopScope': true})),
          throwsA(isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.stale')));
      expect(await File('${f.root.path}/assets/models3d/remove.glb').exists(), isTrue);
    });
  }

  test('maintenance pruning refuses inconsistent shared source identities',
      () async {
    final f = await _pruneFixture(sharedSource: true);
    final head = await f.store.readHead();
    await expectLater(
        _prunePlan(f, ['remove'], 'shared-source'), throwsFormatException);
    expect(await f.store.readHead(), head);
    expect(
        await File('${f.root.path}/assets/models3d/remove.glb').readAsBytes(),
        triangleGlb());
  });
  test(
      'maintenance pruning requires a plan-bound confirmation and replays safely',
      () async {
    final f = await _pruneFixture();
    final plan = await _prunePlan(f, ['remove'], 'confirmation');
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId, operationId: 'confirmation'),
        throwsA(isA<AuthoringAuthorizationException>()
            .having((error) => error.code, 'code', 'confirmation.required')));
    expect(await File('${f.root.path}/assets/models3d/remove.glb').exists(),
        isTrue);
    final confirmation = await f.api
        .confirmMutation(f.opened.projectHandle, planId: plan.planId);
    final result = await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId,
        operationId: 'confirmation',
        confirmationToken: confirmation.confirmationToken);
    final replay = await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId,
        operationId: 'confirmation',
        confirmationToken: confirmation.confirmationToken);
    expect(replay.receipt.toJson(), result.receipt.toJson());
  });
  test(
      'maintenance preview matches reopened model order after a batch deletion',
      () async {
    final f = await _pruneFixture(
        modelIds: ['first', 'keep', 'middle', 'last-a', 'last-b']);
    final keptKey = CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'keep');
    final keptBefore =
        (await (await f.catalog()).indexEntry(keptKey))!.reference;
    final plan = await _prunePlan(f, ['first', 'middle'], 'order');
    final confirmation = await f.api
        .confirmMutation(f.opened.projectHandle, planId: plan.planId);
    await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId,
        operationId: 'order',
        confirmationToken: confirmation.confirmationToken);
    final reopened = await WorkingProjectCatalog.open(
        store: f.store,
        descriptor: WorkingProjectCatalogDescriptor.fromJson(f.descriptor));
    try {
      final project = await reopened.exportProject();
      expect((await (await f.catalog()).indexEntry(keptKey))!.reference,
          keptBefore);
      expect(project.models3d.map((model) => model.id),
          plan.projectedProject!.models3d.map((model) => model.id));
      expect(
          project.resourceLibraryCatalog.entries
              .map((entry) => entry.resourceId)
              .toSet(),
          {'keep', 'last-a', 'last-b'});
    } finally {
      await reopened.close();
    }
  });
  test('maintenance pruning checks active exterior sectors', () async {
    final f = await _pruneFixture();
    final service = LocalMapExteriorDecorationAuthoring(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [f.root.path],
            fileReader: const LocalProjectFileReader()));
    await service.configure(
        projectRoot: f.root.path,
        mapId: 'field',
        expectedRevision:
            (await service.inspect(projectRoot: f.root.path, mapId: 'field'))
                .revision,
        decoration: MapExteriorDecoration(
            mapId: 'field', playableWidth: 4, playableDepth: 4, west: 4),
        operationId: 'configure-exterior');
    await service.setSector(
        projectRoot: f.root.path,
        mapId: 'field',
        expectedRevision:
            (await service.inspect(projectRoot: f.root.path, mapId: 'field'))
                .revision,
        sector: ExteriorDecorationSector(
            id: 'west',
            originX: -4,
            originZ: 0,
            scene: MapSpatialScene(width: 4, depth: 4, instances: [
              SpatialModelInstance(
                  id: 'outside',
                  modelId: 'remove',
                  position: Model3dVector3(x: 1, y: 0, z: 1))
            ])),
        operationId: 'place-exterior');
    await expectLater(
        _prunePlan(f, ['remove'], 'exterior-used'),
        throwsA(isA<AuthoringPlanException>().having(
            (error) => error.code, 'code', 'model3d.prune_model_in_use')));
    expect(await File('${f.root.path}/assets/models3d/remove.glb').exists(),
        isTrue);
  });

  test('maintenance pruning refuses a new exterior definition after planning',
      () async {
    final f = await _pruneFixture();
    final plan = await _prunePlan(f, ['remove'], 'new-exterior');
    final confirmation = await f.api
        .confirmMutation(f.opened.projectHandle, planId: plan.planId);
    await File('${f.root.path}/maps/field.decoration.json').writeAsString('{}');
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId,
            operationId: 'new-exterior',
            confirmationToken: confirmation.confirmationToken),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.project_revision_conflict')));
  });

  test('maintenance pruning refuses modified source preimages', () async {
    final f = await _pruneFixture();
    final head = await f.store.readHead();
    final file = File('${f.root.path}/assets/models3d/remove.glb');
    final changed = [...triangleGlb(), 0];
    await file.writeAsBytes(changed);
    await expectLater(
        _prunePlan(f, ['remove'], 'bad-source'),
        throwsA(isA<AuthoringPlanException>().having(
            (error) => error.code, 'code', 'model3d.prune_source_mismatch')));
    expect(await f.store.readHead(), head);
    expect(await file.readAsBytes(), changed);
  });

  test('maintenance pruning preserves unrelated source changes', () async {
    final f = await _pruneFixture();
    final plan = await _prunePlan(f, ['remove'], 'unrelated');
    final confirmation = await f.api
        .confirmMutation(f.opened.projectHandle, planId: plan.planId);
    final file = File('${f.root.path}/assets/models3d/keep.glb');
    final changed = [...triangleGlb(), 0];
    await file.writeAsBytes(changed);
    await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId,
        operationId: 'unrelated',
        confirmationToken: confirmation.confirmationToken);
    expect(await file.readAsBytes(), changed);
  });

  test('maintenance pruning keeps a source referenced by Pokemon media',
      () async {
    final f = await _pruneFixture(pokemon: true);
    final file = File(
        '${f.root.path}/${const ProjectPokemonConfig(ruleset: PokemonRulesetProfile.standardV1).mediaDir}/riolu.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(const PokemonMediaFile(
            speciesId: 'riolu',
            defaultFormId: 'default',
            unrecognizedFields: {'legacySource': 'assets/models3d/remove.glb'})
        .toJson()));
    final plan = await _prunePlan(f, ['remove'], 'pokemon-source');
    expect(plan.plan.preview['retainedSources'], contains('model3d_remove'));
  });

  test('maintenance pruning refuses a newly created media file after planning',
      () async {
    final f = await _pruneFixture(pokemon: true);
    final plan = await _prunePlan(f, ['remove'], 'new-media');
    final confirmation = await f.api
        .confirmMutation(f.opened.projectHandle, planId: plan.planId);
    final file = File(
        '${f.root.path}/${const ProjectPokemonConfig(ruleset: PokemonRulesetProfile.standardV1).mediaDir}/riolu.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(const PokemonMediaFile(
            speciesId: 'riolu',
            defaultFormId: 'default',
            unrecognizedFields: {'legacySource': 'assets/models3d/remove.glb'})
        .toJson()));
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId,
            operationId: 'new-media',
            confirmationToken: confirmation.confirmationToken),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.project_revision_conflict')));
    expect(await File('${f.root.path}/assets/models3d/remove.glb').exists(),
        isTrue);
  });

  test('maintenance pruning keeps a source referenced by project media',
      () async {
    final f = await _pruneFixture();
    final media = ProjectMediaCatalog(entries: [
      ProjectMediaAsset(
          id: 'shared',
          label: 'Shared',
          kind: ProjectMediaKind.audio,
          sourceAssetId: 'model3d_remove')
    ]);
    await File('${f.root.path}/$projectMediaCatalogStorageKey')
        .writeAsBytes(encodeProjectMediaCatalogBytes(media));
    final plan = await _prunePlan(f, ['remove'], 'project-media');
    expect(plan.plan.preview['retainedSources'], contains('model3d_remove'));
  });

  test('maintenance pruning rejects invalid or unknown model identities',
      () async {
    final f = await _pruneFixture();
    final head = await f.store.readHead();
    for (final ids in <List<String>>[
      [],
      ['remove', 'remove'],
      ['unknown'],
      ['../remove'],
      [for (var i = 0; i < 501; i++) 'model-$i']
    ]) {
      await expectLater(_prunePlan(f, ids, 'invalid'), throwsFormatException);
      expect(await f.store.readHead(), head);
    }
  });

  test(
      'maintenance pruning rejects a reference added outside the prepared index',
      () async {
    final f = await _pruneFixture();
    final before = await f.store.readHead();
    final file = File('${f.root.path}/maps/field.json');
    final map = MapData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    await file.writeAsString(jsonEncode(map
        .copyWith(
            spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [
          SpatialModelInstance(
              id: 'added',
              modelId: 'remove',
              position: Model3dVector3(x: 1, y: 0, z: 1))
        ]))
        .toJson()));
    await expectLater(
        _prunePlan(f, ['remove'], 'used'),
        throwsA(isA<AuthoringPlanException>().having(
            (error) => error.code, 'code', 'model3d.prune_model_in_use')));
    expect(await f.store.readHead(), before);
    expect(await File('${f.root.path}/assets/models3d/remove.glb').exists(),
        isTrue);
  });

  test('maintenance pruning refuses a map change between plan and apply',
      () async {
    final f = await _pruneFixture();
    final plan = await _prunePlan(f, ['remove'], 'stale');
    final confirmation = await f.api
        .confirmMutation(f.opened.projectHandle, planId: plan.planId);
    final before = await f.store.readHead();
    final file = File('${f.root.path}/maps/field.json');
    final map = MapData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    await file.writeAsString(
        jsonEncode(map.copyWith(name: 'Changed externally').toJson()));
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId,
            operationId: 'stale',
            confirmationToken: confirmation.confirmationToken),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.project_revision_conflict')));
    expect(await f.store.readHead(), before);
    expect(await File('${f.root.path}/assets/models3d/remove.glb').exists(),
        isTrue);
  });

  for (final reference in [
    'logicalPath',
    'assetId',
    'handle',
    'digest',
    'hexDigest'
  ]) {
    test(
        'maintenance preview explains a source retained by an arbitrary map $reference',
        () async {
      final f = await _pruneFixture();
      final file = File('${f.root.path}/maps/field.json');
      final map = MapData.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
      final artifact = ContentArtifactRef.fromBytes(triangleGlb(),
          mediaType: 'model/gltf-binary');
      final values = {
        'logicalPath': 'assets/models3d/remove.glb',
        'assetId': 'model3d_remove',
        'handle': artifact.handle,
        'digest': artifact.digest,
        'hexDigest': artifact.hexDigest
      };
      await file.writeAsString(
          jsonEncode(map.copyWith(name: values[reference]!).toJson()));
      final plan = await _prunePlan(f, ['remove'], 'retain');
      expect(plan.plan.preview['retainedSources'], contains('model3d_remove'));
      final confirmation = await f.api
          .confirmMutation(f.opened.projectHandle, planId: plan.planId);
      await f.api.applyMutation(f.opened.projectHandle,
          planId: plan.planId,
          operationId: 'retain',
          confirmationToken: confirmation.confirmationToken);
      expect(await File('${f.root.path}/assets/models3d/remove.glb').exists(),
          isTrue);
      expect(
          await (await f.catalog()).lookup(
              CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'remove')),
          isNull);
    });
  }

  test('maintenance pruning deletes a shared blob only once and supports redo',
      () async {
    final f = await _pruneFixture(mapModelId: null);
    final plan = await _prunePlan(f, ['remove', 'keep'], 'both');
    final confirmation = await f.api
        .confirmMutation(f.opened.projectHandle, planId: plan.planId);
    final result = await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId,
        operationId: 'both',
        confirmationToken: confirmation.confirmationToken);
    final artifact = ContentArtifactRef.fromBytes(triangleGlb(),
        mediaType: 'model/gltf-binary');
    expect(
        await File('${f.root.path}/${assetBlobStorageKey(artifact)}').exists(),
        isFalse);
    await f.api.undoMutation(f.opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'undo-both');
    expect(
        await File('${f.root.path}/${assetBlobStorageKey(artifact)}').exists(),
        isTrue);
    await f.api.redoMutation(f.opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'redo-both');
    expect(
        await File('${f.root.path}/${assetBlobStorageKey(artifact)}').exists(),
        isFalse);
  });

  for (final reference in ['model', 'source']) {
    test('maintenance redo refuses $reference references added after undo',
        () async {
      final f = await _pruneFixture();
      final plan = await _prunePlan(f, ['remove'], 'redo-used');
      final confirmation = await f.api
          .confirmMutation(f.opened.projectHandle, planId: plan.planId);
      final result = await f.api.applyMutation(f.opened.projectHandle,
          planId: plan.planId,
          operationId: 'redo-used',
          confirmationToken: confirmation.confirmationToken);
      await f.api.undoMutation(f.opened.projectHandle,
          entryId: result.receipt.receiptId, idempotencyKey: 'undo-redo-used');
      final file = File('${f.root.path}/maps/field.json');
      final map = MapData.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
      final changed = reference == 'source'
          ? map.copyWith(name: 'assets/models3d/remove.glb')
          : map.copyWith(
              spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [
              SpatialModelInstance(
                  id: 'added',
                  modelId: 'remove',
                  position: Model3dVector3(x: 1, y: 0, z: 1))
            ]));
      await file.writeAsString(jsonEncode(changed.toJson()));
      await expectLater(
          f.api.redoMutation(f.opened.projectHandle,
              entryId: result.receipt.receiptId,
              idempotencyKey: 'redo-used-again'),
          throwsA(isA<AuthoringPlanException>().having(
              (error) => error.code,
              'code',
              reference == 'source'
                  ? 'model3d.prune_source_in_use'
                  : 'model3d.prune_model_in_use')));
      expect(await File('${f.root.path}/assets/models3d/remove.glb').exists(),
          isTrue);
    });
  }
  test('maintenance pruning preserves shared content and can be undone',
      () async {
    final parent =
        Directory('/Users/karim/Library/Caches/AveluneQA/catalog-model-delete');
    await parent.create(recursive: true);
    final root = await parent.createTemp('fixture-');
    final bytes = triangleGlb();
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
    final inspection = const GlbModel3dInspector().inspect(bytes);
    final models = [
      for (final id in ['remove', 'keep'])
        ProjectModel3dEntry(
            id: id,
            name: id,
            sourceAssetId: 'model3d_$id',
            relativePath: 'assets/models3d/$id.glb',
            inspection: inspection),
    ];
    final assets = AssetCatalog(records: [
      for (final model in models)
        AssetRecord(
            id: model.sourceAssetId,
            logicalPath: model.relativePath,
            artifact: artifact),
    ]);
    final map = MapData(
        id: 'field',
        name: 'Field',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [
          SpatialModelInstance(
              id: 'placed',
              modelId: 'keep',
              position: Model3dVector3(x: 1, y: 0, z: 1)),
        ]));
    final project = ProjectManifest(
        name: 'Model deletion',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()),
        pokemon: const ProjectPokemonConfig(
            enabled: false, ruleset: PokemonRulesetProfile.standardV1),
        maps: const [
          ProjectMapEntry(
              id: 'field', name: 'Field', relativePath: 'maps/field.json')
        ],
        tilesets: const [],
        models3d: models,
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
          for (final model in models)
            ResourceLibraryEntry(
                resourceKind: 'model3d',
                resourceId: model.id,
                familyId: 'relief'),
        ]));
    final fixture =
        await ResourceIndexFixture.create(root: root, project: project, maps: [
      map
    ], files: {
      assetCatalogStorageKey: utf8.encode(jsonEncode(assets.toJson())),
      assetBlobStorageKey(artifact): bytes,
      for (final model in models) model.relativePath: bytes,
    });
    addTearDown(() async {
      await fixture.close();
      await root.delete(recursive: true);
    });
    await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle,
        scope: 'assetImport');
    await fixture.prepare();
    final mapBytes = await File('${root.path}/maps/field.json').readAsBytes();
    final scope = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'model3d.prune_unused',
        parameters: {
          'modelIds': ['remove']
        });
    final plan = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'delete-model',
            actionId: 'model3d.prune_unused',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            parameters: const {
              'modelIds': ['remove']
            },
            expectedRevision: scope.revision,
            idempotencyKey: 'delete-model',
            extensions: const {'workshopScope': true}));
    final confirmation = await fixture.api
        .confirmMutation(fixture.opened.projectHandle, planId: plan.planId);
    final result = await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: plan.planId,
        operationId: 'delete-model',
        confirmationToken: confirmation.confirmationToken);
    expect(result.receipt.status, AuthoringReceiptStatus.applied);
    final catalog = await fixture.catalog();
    expect(
        await catalog.lookup(
            CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'remove')),
        isNull);
    expect(
        await catalog.lookup(CatalogDefinitionKey(
            CatalogDefinitionKind.resourceLibraryEntry, 'model3d:remove')),
        isNull);
    expect(
        await catalog.lookup(
            CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'keep')),
        isNotNull);
    expect(await File('${root.path}/assets/models3d/remove.glb').exists(),
        isFalse);
    expect(await File('${root.path}/assets/models3d/keep.glb').readAsBytes(),
        bytes);
    expect(
        await File('${root.path}/${assetBlobStorageKey(artifact)}')
            .readAsBytes(),
        bytes);
    expect(await File('${root.path}/maps/field.json').readAsBytes(), mapBytes);
    await fixture.api.undoMutation(fixture.opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'undo-delete-model');
    final restored = await fixture.catalog();
    expect(
        await restored.lookup(
            CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'remove')),
        isNotNull);
    expect(
        await restored.lookup(CatalogDefinitionKey(
            CatalogDefinitionKind.resourceLibraryEntry, 'model3d:remove')),
        isNotNull);
    expect(await File('${root.path}/assets/models3d/remove.glb').readAsBytes(),
        bytes);
    expect(await File('${root.path}/maps/field.json').readAsBytes(), mapBytes);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<ResourceIndexFixture> _pruneFixture(
    {String? mapModelId = 'keep',
    bool pokemon = false,
    bool sharedSource = false,
    List<String> modelIds = const ['remove', 'keep']}) async {
  final parent =
      Directory('/Users/karim/Library/Caches/AveluneQA/catalog-model-delete');
  await parent.create(recursive: true);
  final root = await parent.createTemp('prune-');
  addTearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  final bytes = triangleGlb();
  final artifact =
      ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
  final inspection = const GlbModel3dInspector().inspect(bytes);
  final models = [
    for (final id in modelIds)
      ProjectModel3dEntry(
          id: id,
          name: id,
          sourceAssetId: sharedSource ? 'model3d_shared' : 'model3d_$id',
          relativePath: 'assets/models3d/$id.glb',
          inspection: inspection)
  ];
  final assets = AssetCatalog(
      records: {
    for (final model in models)
      model.sourceAssetId: AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact)
  }.values);
  final map = MapData(
      id: 'field',
      name: 'Field',
      version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [
        if (mapModelId != null)
          SpatialModelInstance(
              id: 'placed',
              modelId: mapModelId,
              position: Model3dVector3(x: 1, y: 0, z: 1))
      ]));
  final project = ProjectManifest(
      name: 'Model pruning',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()),
      pokemon: ProjectPokemonConfig(
          enabled: pokemon, ruleset: PokemonRulesetProfile.standardV1),
      maps: const [
        ProjectMapEntry(
            id: 'field', name: 'Field', relativePath: 'maps/field.json')
      ],
      tilesets: const [],
      models3d: models,
      resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
        for (final model in models)
          ResourceLibraryEntry(
              resourceKind: 'model3d', resourceId: model.id, familyId: 'relief')
      ]));
  final f =
      await ResourceIndexFixture.create(root: root, project: project, maps: [
    map
  ], files: {
    assetCatalogStorageKey: utf8.encode(jsonEncode(assets.toJson())),
    assetBlobStorageKey(artifact): bytes,
    for (final model in models) model.relativePath: bytes,
  });
  addTearDown(() async {
    await f.close();
  });
  await f.prepare();
  return f;
}

Future<AuthoringMutationPlanResult> _prunePlan(
    ResourceIndexFixture f, List<String> ids, String id) async {
  final parameters = <String, Object?>{'modelIds': ids};
  final snapshot = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
      actionId: 'model3d.prune_unused', parameters: parameters);
  return f.api.planMutation(
      f.opened.projectHandle,
      AuthoringRequest(
          requestId: id,
          actionId: 'model3d.prune_unused',
          actionVersion: 1,
          workspaceHandle: f.opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
          extensions: const {'workshopScope': true}));
}

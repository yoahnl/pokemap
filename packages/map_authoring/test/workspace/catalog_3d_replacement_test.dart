import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show LocalMapExteriorDecorationAuthoring;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/environment_spatial_actions_test.dart'
    show environmentModelGlb;
import '../support/create_model_replacement_fixture.dart';
import '../support/resource_index_fixture.dart';

const _repoint = {
  'family': 'models3d',
  'resourceId': 'tree',
  'replacementId': 'alternate',
};

void main() {
  late Directory root;
  late ResourceIndexFixture fixture;

  setUp(() async {
    final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/model-replacement/authoring');
    await base.create(recursive: true);
    root = await base.createTemp('project-');
  });
  tearDown(() async {
    await fixture.close();
    await root.delete(recursive: true);
  });

  for (final (placed, mixed) in [(false, false), (true, false), (true, true)]) {
    test(
        'repoint and undo a partitioned Border with placements=$placed and mixed pieces=$mixed',
        () async {
      fixture = await createModelReplacementFixture(root,
          placed: placed, mixed: mixed);
      final beforeBorder = await _border(fixture);
      final beforeMap = await File('${root.path}/maps/map.json').readAsBytes();
      final beforeAssets = await _assets(root);
      final plan = await _plan(fixture, 'resource.usages.replace', _repoint);
      expect(plan.applicable, isTrue);
      expect(plan.plan.preview, containsPair('noOp', false));
      expect(plan.plan.preview, containsPair('repointedBorderIds', ['fence']));
      expect(plan.plan.preview, containsPair('mapCount', placed ? 1 : 0));
      final redirected = placed ? (mixed ? 2 : 3) : 0;
      expect(plan.plan.preview, containsPair('occurrenceCount', redirected));
      expect(plan.plan.preview,
          containsPair('regeneratedInstanceCount', placed ? 3 : 0));
      expect(plan.receipt.extensions['referenceImpact'],
          containsPair('occurrenceCount', redirected));
      expect(await _border(fixture), beforeBorder);
      expect(await File('${root.path}/maps/map.json').readAsBytes(), beforeMap);
      final confirmation = await fixture.api
          .confirmMutation(fixture.opened.projectHandle, planId: plan.planId);
      final applied = await fixture.api.applyMutation(
          fixture.opened.projectHandle,
          planId: plan.planId,
          operationId: 'replace',
          confirmationToken: confirmation.confirmationToken);
      await fixture.close();
      fixture = await ResourceIndexFixture.openExisting(root);
      expect(_primitiveSources(await _border(fixture)), {'alternate'});
      final after = _map(root);
      expect(after.spatialScene!.instances.map((value) => value.modelId),
          placed ? everyElement('alternate') : isEmpty);
      expect(await _assets(root), beforeAssets);
      await fixture.api.undoMutation(fixture.opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: 'undo-replace');
      await fixture.close();
      fixture = await ResourceIndexFixture.openExisting(root);
      expect(await _border(fixture), beforeBorder);
      expect(await File('${root.path}/maps/map.json').readAsBytes(), beforeMap);
      expect(await _assets(root), beforeAssets);
    });
  }

  test('a late exterior placement invalidates an already confirmed plan',
      () async {
    fixture = await createModelReplacementFixture(root);
    final service = LocalMapExteriorDecorationAuthoring(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader()));
    final initial = await service.inspect(projectRoot: root.path, mapId: 'map');
    final decoration = await service.configure(
        projectRoot: root.path,
        mapId: 'map',
        expectedRevision: initial.revision,
        decoration: MapExteriorDecoration(
            mapId: 'map', playableWidth: 6, playableDepth: 4, west: 16),
        operationId: 'configure');
    final beforeBorder = await _border(fixture);
    final plan = await _plan(fixture, 'resource.usages.replace', _repoint);
    final confirmation = await fixture.api
        .confirmMutation(fixture.opened.projectHandle, planId: plan.planId);
    await service.setSector(
        projectRoot: root.path,
        mapId: 'map',
        expectedRevision: decoration.afterRevision,
        sector: ExteriorDecorationSector(
            id: 'west',
            originX: -16,
            originZ: 0,
            scene: MapSpatialScene(width: 16, depth: 4, instances: [
              SpatialModelInstance(
                  id: 'outside',
                  modelId: 'tree',
                  position: Model3dVector3(x: 2, y: 0, z: 2))
            ])),
        operationId: 'outside');
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId,
            operationId: 'replace',
            confirmationToken: confirmation.confirmationToken),
        throwsA(anything));
    expect(await _border(fixture), beforeBorder);
    await expectLater(
        _plan(fixture, 'resource.usages.replace', _repoint),
        throwsA(isA<FormatException>().having((error) => error.message, 'cause',
            contains('exterior.resource_in_use'))));
  });

  test('changing a GLB refuses an indexed shared logical source', () async {
    fixture = await createModelReplacementFixture(root, shared: true);
    final before = await _assets(root, shared: true);
    final artifact = await fixture.api.artifacts.put(
        modelReplacementCandidateGlb(),
        declaredMediaType: 'model/gltf-binary');
    await expectLater(
        _plan(fixture, 'model3d.source.replace', {
          'modelId': 'tree',
          'artifactHandle': artifact.reference.handle,
        }),
        throwsA(isA<AuthoringPlanException>().having(
            (error) => error.code, 'code', 'catalog.model_source_shared')));
    expect(await _assets(root, shared: true), before);
    final read = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'model3d.source.replace',
        parameters: {'modelId': 'tree'});
    expect(read.resourceBytes('model3d:tree'), environmentModelGlb());
  });
}

Future<AuthoringMutationPlanResult> _plan(ResourceIndexFixture fixture,
    String action, Map<String, Object?> parameters) async {
  final snapshot = await fixture.api.readWorkshopSnapshot(
      fixture.opened.projectHandle,
      actionId: action,
      parameters: parameters);
  final id = 'plan-${DateTime.now().microsecondsSinceEpoch}';
  return fixture.api.planMutation(
      fixture.opened.projectHandle,
      AuthoringRequest(
          requestId: id,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: fixture.opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: id));
}

Future<Map<String, Object?>> _border(ResourceIndexFixture fixture) async =>
    (await (await fixture.catalog()).lookup(
            CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, 'fence')))!
        .payload;

Set<String> _primitiveSources(Map<String, Object?> unit) {
  final record = (unit['value'] as Map);
  return {
    for (final version in [record['draft'], record['latestPublished']])
      for (final value in version['definition']['primitives'] as List)
        value['sourceModelId'] as String,
  };
}

MapData _map(Directory root) => MapData.fromJson(
    jsonDecode(File('${root.path}/maps/map.json').readAsStringSync())
        as Map<String, dynamic>);

Future<List<List<int>>> _assets(Directory root, {bool shared = false}) =>
    Future.wait([
      for (final path in [
        assetCatalogStorageKey,
        'assets/models3d/tree.glb',
        if (!shared) 'assets/models3d/alternate.glb',
      ])
        File('${root.path}/$path').readAsBytes(),
    ]);

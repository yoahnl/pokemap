import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture;
import '../maps/environment_spatial_actions_test.dart' show environmentModelGlb;
import 'resource_information_fixture.dart';

void main() {
  test(
      'a Border replacement counts changed references and regenerated neighbours',
      () async {
    final base = spatialBorderAuthoringFixture(published: true);
    final tree = base.project.models3d.single;
    final project = _withMixedBorder(base.project, [
      tree,
      _copyOf(tree, 'tree-neighbour'),
      _copyOf(tree, 'tree-copy'),
    ]);
    final preview = resolveSpatialBorderFeature(
        manifest: project,
        map: base.map,
        layerId: 'border',
        featureId: 'fence');
    final map = applySpatialBorderFeaturePreview(base.map,
        manifest: project, proposedResult: preview);
    final instances = map.spatialScene!.instances;
    final changedIds = [
      for (final instance in instances)
        if (instance.modelId == 'tree') instance.id,
    ];
    final neighbourIds = [
      for (final instance in instances)
        if (instance.modelId == 'tree-neighbour') instance.id,
    ];
    expect(changedIds, isNotEmpty);
    expect(neighbourIds, isNotEmpty);
    final fixture = await ResourceInformationFixture.create(project);
    addTearDown(fixture.dispose);
    await _registerModels(fixture.root, project.models3d);
    final path = File('${fixture.root.path}/maps/map.json');
    await path.create(recursive: true);
    final original = encodeMapAuthoringDocument(map);
    await path.writeAsBytes(original);
    final parameters = {
      'family': 'models3d',
      'resourceId': 'tree',
      'replacementId': 'tree-copy',
    };
    final snapshot =
        await fixture.snapshots.load(ProjectHandle(fixture.project));
    final request = AuthoringRequest(
      requestId: 'mixed-border',
      actionId: 'resource.usages.replace',
      actionVersion: 1,
      workspaceHandle: fixture.workspace,
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'mixed-border',
      dryRun: true,
    );
    final draft = const ResourceUsageReplacementActions().build(
        AuthoringPlanningContext(
            snapshot: snapshot, request: request, planId: 'fixture', seed: 1));
    final mapChange = draft.changeSet.changes
        .singleWhere((change) => change.resource.kind == 'map');
    final projected = MapData.fromJson(
        jsonDecode(utf8.decode(mapChange.afterBytes!)) as Map<String, dynamic>);
    expect(projected.spatialScene!.instances, [
      for (final instance in instances)
        if (changedIds.contains(instance.id))
          instance.copyWith(modelId: 'tree-copy')
        else
          instance,
    ]);

    final result = await fixture.command('plan', {
      'projectHandle': fixture.project,
      'request': request.toJson(),
    });
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    final plan = result.data['plan'] as Map;
    final plannedPreview = plan['preview'] as Map;
    expect(plannedPreview['occurrenceCount'], changedIds.length);
    expect(plannedPreview['regeneratedInstanceCount'], instances.length);
    final impact = (result.data['receipt'] as Map)['extensions']
        ['referenceImpact'] as Map;
    expect(impact['occurrenceCount'], changedIds.length);
    expect(impact['regeneratedInstanceCount'], instances.length);
    final mapPreview = (plannedPreview['maps'] as List).single as Map;
    expect(mapPreview['instanceIds'], changedIds);
    expect(mapPreview['regeneratedInstanceCount'], instances.length);
    final diff = (plan['changeSet']['diff']['entries'] as List)
        .singleWhere((entry) => entry['path'] == '/spatialScene/instances');
    expect(diff['before'], {for (final id in changedIds) id: 'tree'});
    expect(diff['after'], {for (final id in changedIds) id: 'tree-copy'});
    expect(await path.readAsBytes(), original);
  });
}

ProjectModel3dEntry _copyOf(ProjectModel3dEntry base, String id) =>
    ProjectModel3dEntry.fromJson({
      ...base.toJson(),
      'id': id,
      'sourceAssetId': '$id-source',
      'relativePath': 'assets/models3d/$id.glb',
    });

Future<void> _registerModels(
    Directory root, List<ProjectModel3dEntry> models) async {
  final glb = environmentModelGlb();
  final artifact =
      ContentArtifactRef.fromBytes(glb, mediaType: 'model/gltf-binary');
  final catalog = AssetCatalog(records: [
    for (final model in models)
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact),
  ]);
  final catalogFile = File('${root.path}/$assetCatalogStorageKey');
  await catalogFile.create(recursive: true);
  await catalogFile.writeAsString(jsonEncode(catalog.toJson()));
  for (final path in [
    assetBlobStorageKey(artifact),
    for (final model in models) model.relativePath,
  ]) {
    final file = File('${root.path}/$path');
    await file.create(recursive: true);
    await file.writeAsBytes(glb);
  }
}

ProjectManifest _withMixedBorder(
    ProjectManifest project, List<ProjectModel3dEntry> models) {
  final json =
      jsonDecode(jsonEncode(project.copyWith(models3d: models).toJson()))
          as Map<String, dynamic>;
  final record = (json['borderCatalog']['records'] as List).single;
  for (final version in [record['draft'], record['latestPublished']]) {
    for (final primitive in version['definition']['primitives'] as List) {
      if (primitive['role'] == 'lineStraight') {
        primitive['sourceModelId'] = 'tree-neighbour';
      }
    }
  }
  return ProjectManifest.fromJson(json);
}

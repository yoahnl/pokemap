import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import '../../support/glb_fixture.dart' show animatedGlb;
import 'border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture, context;

void main() {
  test('canonical native publication preserves authored playback and collision',
      () async {
    final fixture = spatialBorderAuthoringFixture();
    final model = fixture.project.models3d.single;
    final project = fixture.project.copyWith(models3d: [
      ProjectModel3dEntry(
          id: model.id,
          name: model.name,
          sourceAssetId: model.sourceAssetId,
          relativePath: model.relativePath,
          scale: model.scale,
          pivot: model.pivot,
          collisionBounds: model.collisionBounds,
          inspection: const GlbModel3dInspector().inspect(animatedGlb()))
    ]);
    final record = encodeBorderBlueprintRecordJson(
        project.borderCatalog.records.single,
        formatVersion: 5);
    for (final primitive in ((record['draft'] as Map)['definition']
        as Map)['primitives'] as List) {
      (primitive as Map).addAll(<String, Object?>{
        'animationIndex': 0,
        'animationLoop': false,
        'animationSpeed': .5,
        'blocksMovement': false
      });
    }
    final draftMutation = await MapMutationDispatcher.canonical().build(context(
        librarySnapshot([fixture.map], project: project),
        'border.blueprint.draft.upsert',
        {'record': record}));
    final drafted = ProjectManifest.fromJson(jsonDecode(
        utf8.decode(draftMutation.changeSet.changes.single.afterBytes!)));
    final publishedMutation = await MapMutationDispatcher.canonical().build(
        context(librarySnapshot([fixture.map], project: drafted),
            'border.blueprint.publish', {'blueprintId': 'fence'}));
    final published = ProjectManifest.fromJson(jsonDecode(
        utf8.decode(publishedMutation.changeSet.changes.single.afterBytes!)));
    final wire = encodeBorderBlueprintRecordJson(
        published.borderCatalog.records.single,
        formatVersion: 5);
    for (final section in ['draft', 'latestPublished']) {
      for (final primitive in ((wire[section] as Map)['definition']
          as Map)['primitives'] as List) {
        expect(primitive['animationIndex'], 0);
        expect(primitive['animationLoop'], isFalse);
        expect(primitive['animationSpeed'], .5);
        expect(primitive['blocksMovement'], isFalse);
      }
    }
    final materialized = await MapMutationDispatcher.canonical().build(context(
        librarySnapshot([fixture.map], project: published),
        'border_layer.materialize_apply',
        {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'}));
    final map = MapData.fromJson(jsonDecode(
        utf8.decode(materialized.changeSet.changes.single.afterBytes!)));
    expect(map.spatialScene!.instances, hasLength(3));
    for (final instance in map.spatialScene!.instances) {
      expect(instance.animationIndex, 0);
      expect(instance.animationLoop, isFalse);
      expect(instance.animationSpeed, .5);
      expect(instance.blocksMovement, isFalse);
    }
  });

  test(
      'canonical publication rejects a missing animation without mutating its snapshot',
      () async {
    final fixture = spatialBorderAuthoringFixture();
    final record = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: 5);
    for (final primitive in ((record['draft'] as Map)['definition']
        as Map)['primitives'] as List) {
      primitive['animationIndex'] = 0;
    }
    final project = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(formatVersion: 5, records: [
      decodeBorderBlueprintRecordJson(record, formatVersion: 5)
    ]));
    final snapshot = librarySnapshot([fixture.map], project: project);
    final before = jsonEncode(snapshot.manifest.toJson());
    await expectLater(
        MapMutationDispatcher.canonical().build(context(
            snapshot, 'border.blueprint.publish', {'blueprintId': 'fence'})),
        throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'border.blueprint.publication_invalid')));
    expect(jsonEncode(snapshot.manifest.toJson()), before);
    expect(snapshot.maps.single, fixture.map);
  });
}

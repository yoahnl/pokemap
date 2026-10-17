import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture, context;

void main() {
  test(
      'canonical cliff publication keeps local footprints and promotes the catalog',
      () async {
    final fixture = spatialBorderAuthoringFixture();
    final record = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: 5);
    final definition = ((record['draft'] as Map)['definition'] as Map);
    definition['replacesGround'] = true;
    for (final primitive in definition['primitives'] as List) {
      primitive['groundFootprints'] = [
        [
          {'x': -.1, 'z': -.1},
          {'x': .1, 'z': -.1},
          {'x': -.1, 'z': .1}
        ]
      ];
    }
    final snapshot = librarySnapshot([fixture.map],
        project: fixture.project
            .copyWith(borderCatalog: const ProjectBorderCatalog.empty()));
    final draft = await MapMutationDispatcher.canonical().build(
        context(snapshot, 'border.blueprint.draft.upsert', {'record': record}));
    final drafted = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
    expect(drafted.borderCatalog.formatVersion, 8);
    final publication = await MapMutationDispatcher.canonical().build(context(
        librarySnapshot([fixture.map], project: drafted),
        'border.blueprint.publish',
        {'blueprintId': 'fence'}));
    final published = ProjectManifest.fromJson(jsonDecode(
        utf8.decode(publication.changeSet.changes.single.afterBytes!)));
    final actual =
        published.borderCatalog.records.single.latestPublished!.definition;
    expect(actual.primitives, hasLength(3));
    for (final primitive in actual.primitives) {
      expect(primitive.groundFootprints.single.points, [
        BorderGroundPoint(x: -.1, z: -.1),
        BorderGroundPoint(x: .1, z: -.1),
        BorderGroundPoint(x: -.1, z: .1)
      ]);
    }
    expect(
        published.borderCatalog.records.single.draft.definition.primitives
            .map((p) => p.groundFootprints),
        actual.primitives.map((p) => p.groundFootprints));
    final map = applySpatialBorderFeaturePreview(fixture.map,
        manifest: published,
        proposedResult: resolveSpatialBorderFeature(
            manifest: published,
            map: fixture.map,
            layerId: 'border',
            featureId: 'fence'));
    final replacements =
        resolveSpatialBorderGroundReplacements(manifest: published, map: map);
    expect(replacements, hasLength(3));
    expect(
        replacements
            .every((value) => value.footprints.single.points.length == 3),
        isTrue);
    expect(map.spatialScene!.navigation, fixture.map.spatialScene!.navigation);
    expect(
        map.spatialScene!.heightLevels, fixture.map.spatialScene!.heightLevels);
    final transformedProject = published.copyWith(models3d: [
      for (final model in published.models3d)
        model.copyWith(scale: .5, pivot: Model3dVector3(x: .05, y: 0, z: -.02)),
    ]);
    final transformedMap = map.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [
      for (final instance in map.spatialScene!.instances)
        instance.copyWith(
            position: Model3dVector3(x: 2, y: 2, z: 2),
            rotationDegrees: 90,
            scale: .5),
    ]));
    final transformed = resolveSpatialBorderGroundReplacements(
        manifest: transformedProject, map: transformedMap);
    final points = transformed.first.footprints.single.points;
    for (final (index, x, z) in [
      (0, 1.98, 2.0375),
      (1, 1.98, 1.9875),
      (2, 2.03, 2.0375)
    ]) {
      expect(points[index].x, closeTo(x, 1e-10));
      expect(points[index].z, closeTo(z, 1e-10));
    }
    final tinyProject = published.copyWith(models3d: [
      for (final model in published.models3d) model.copyWith(scale: 5e-5),
    ]);
    final tiny =
        resolveSpatialBorderGroundReplacements(manifest: tinyProject, map: map);
    expect(tiny, hasLength(3));
    expect(tiny.first.footprints.single.points, hasLength(3));
  });

  test('canonical publication rejects an out of model ground footprint',
      () async {
    final fixture = spatialBorderAuthoringFixture();
    final raw = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: 5);
    final definition = ((raw['draft'] as Map)['definition'] as Map);
    definition['replacesGround'] = true;
    for (final primitive in definition['primitives'] as List) {
      primitive['groundFootprints'] = [
        [
          {'x': -1.0, 'z': -1.0},
          {'x': 1.0, 'z': -1.0},
          {'x': -1.0, 'z': 1.0}
        ]
      ];
    }
    final project = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
            formatVersion: 8,
            records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 8)]));
    await expectLater(
        MapMutationDispatcher.canonical().build(context(
            librarySnapshot([fixture.map], project: project),
            'border.blueprint.publish',
            {'blueprintId': 'fence'})),
        throwsA(isA<MapAuthoringException>().having((e) => e.details.toString(),
            'diagnostics', contains('ground_footprint_outside_model'))));
  });
}

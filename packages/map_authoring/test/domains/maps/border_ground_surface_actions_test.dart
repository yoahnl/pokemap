import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_core/test/support/spatial_border_ground_surface_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;

void main() {
  for (final inclined in [false, true]) {
    test(
        'canonical publication keeps reusable plateaus and their terrain material (inclined: $inclined)',
        () async {
      final own = surfaceFixture();
      final raw = encodeBorderBlueprintRecordJson(
          own.project.borderCatalog.records.single,
          formatVersion: 9)
        ..remove('latestPublished');
      (raw['draft'] as Map)['baseRevision'] = 0;
      if (inclined) {
        for (final primitive
            in (raw['draft'] as Map)['definition']['primitives'] as List) {
          for (final surface in primitive['groundSurfaces'] as List) {
            surface['gradientX'] = .5;
            surface['gradientZ'] = -.25;
          }
        }
      }
      final project = own.project
          .copyWith(borderCatalog: const ProjectBorderCatalog.empty());
      final planned = await MapMutationDispatcher.canonical().build(context(
          librarySnapshot([own.map], project: project),
          'border.blueprint.draft.upsert',
          {'record': raw}));
      final drafted = ProjectManifest.fromJson(jsonDecode(
          utf8.decode(planned.changeSet.changes.single.afterBytes!)));
      expect(drafted.borderCatalog.formatVersion, inclined ? 10 : 9);
      final published = await MapMutationDispatcher.canonical().build(context(
          librarySnapshot([own.map], project: drafted),
          'border.blueprint.publish',
          {'blueprintId': 'fence'}));
      final actual = ProjectManifest.fromJson(jsonDecode(
          utf8.decode(published.changeSet.changes.single.afterBytes!)));
      final record = actual.borderCatalog.records.single;
      expect(
          record.latestPublished!.definition.primitives
              .map((p) => p.groundSurfaces),
          record.draft.definition.primitives.map((p) => p.groundSurfaces));
      expect(
          record.latestPublished!.definition.primitives
              .every((p) => p.groundSurfaces.length == 2),
          true);
      expect(actual.smartTileCatalog, project.smartTileCatalog);
      expect(actual.models3d, project.models3d);
    });
  }

  test('a terrain used only by a Border cannot be deleted', () async {
    final own = surfaceFixture();
    await expectLater(
        () => MapMutationDispatcher.canonical().build(context(
            librarySnapshot([own.map], project: own.project),
            'smart_tile.preset.delete',
            {'presetId': 'grass-terrain'})),
        throwsA(isA<MapAuthoringException>().having(
            (e) => e.code, 'code', 'smart_tile.preset.references_blocking')));
  });

  test('terrain republication cannot invalidate a published plateau', () async {
    final own = surfaceFixture();
    final source = own.project.smartTileCatalog.presets.single;
    final invalid = source.copyWith(rules: [
      for (final rule in source.rules)
        rule.copyWith(candidates: [
          for (final candidate in rule.candidates)
            candidate.copyWith(parts: [
              for (final part in candidate.parts)
                part.copyWith(spatialHeightOffset: 1)
            ])
        ])
    ]);
    await expectLater(
        () => MapMutationDispatcher.canonical().build(context(
            librarySnapshot([own.map], project: own.project),
            'smart_tile.preset.publish',
            {'preset': invalid.toJson()})),
        throwsA(isA<MapAuthoringException>()));
  });

  test('canonical publication rejects a missing plateau terrain', () async {
    final own = surfaceFixture();
    final project = own.project
        .copyWith(smartTileCatalog: const ProjectSmartTileCatalog.empty());
    await expectLater(
        () => MapMutationDispatcher.canonical().build(context(
            librarySnapshot([own.map], project: project),
            'border.blueprint.publish',
            {'blueprintId': 'fence'})),
        throwsA(isA<MapAuthoringException>().having((e) => e.details.toString(),
            'diagnostics', contains('ground_surface_preset_invalid'))));
  });
}

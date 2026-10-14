import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_resolution_test.dart' show spatialBorderFixture;

void main() {
  test(
    'a measured ground contact survives draft and publication serialization',
    () {
      final fixture = contactFixture(offset: -.0625);
      final raw = fixture.project.toJson();
      final project = ProjectManifest.fromJson(raw);
      final record = encodeBorderBlueprintRecordJson(
        project.borderCatalog.records.single,
        formatVersion: 5,
      );
      for (final key in ['draft', 'latestPublished']) {
        expect((record[key] as Map)['definition']['groundBaseOffset'], -.0625);
      }
      expect(project, fixture.project);
    },
  );

  test('lowering native ground contact preserves the wall and navigation', () {
    final base = contactFixture();
    final shifted = contactFixture(offset: -.0625);
    final original = resolve(base.project, base.map);
    final proposed = resolve(shifted.project, shifted.map);
    expect(proposed.result.canApply, isTrue);
    expect(proposed.modelInstances, original.modelInstances);
    final applied = applySpatialBorderFeaturePreview(
      shifted.map,
      manifest: shifted.project,
      proposedResult: proposed,
    );
    final contacts = resolveSpatialBorderGroundReplacements(
      manifest: shifted.project,
      map: applied,
    );
    expect(contacts, hasLength(proposed.modelInstances.length));
    for (var index = 0; index < contacts.length; index++) {
      final instance = proposed.modelInstances[index];
      expect(contacts[index].lowerHeight, instance.position.y - .0625);
      expect(contacts[index].upperHeight, instance.position.y + 1);
    }
    expect(
      applied.spatialScene!.heightLevels,
      shifted.map.spatialScene!.heightLevels,
    );
    expect(
      applied.spatialScene!.navigation,
      shifted.map.spatialScene!.navigation,
    );
  });

  test('ground contact follows the scale of the authored profile', () {
    final fixture = contactFixture(offset: -.0625, scale: 2);
    final proposed = resolve(fixture.project, fixture.map);
    expect(proposed.result.canApply, isTrue);
    final applied = applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: fixture.project,
      proposedResult: proposed,
    );
    final contacts = resolveSpatialBorderGroundReplacements(
      manifest: fixture.project,
      map: applied,
    );
    for (var index = 0; index < contacts.length; index++) {
      expect(
        contacts[index].lowerHeight,
        proposed.modelInstances[index].position.y - .125,
      );
      expect(
        contacts[index].upperHeight,
        proposed.modelInstances[index].position.y + 2,
      );
    }
  });

  test('publication fingerprints include measured ground contact', () {
    String fingerprint(ProjectManifest project) =>
        computeBorderPublicationCandidateFingerprint(
          blueprintId: 'fence',
          resolverVersion: borderResolverVersion,
          definition:
              project.borderCatalog.records.single.latestPublished!.definition,
        );
    expect(
      fingerprint(contactFixture().project),
      isNot(fingerprint(contactFixture(offset: -.0625).project)),
    );
  });

  test('ground contact rejects invalid values and inactive replacement', () {
    for (final value in [
      null,
      '0.1',
      true,
      double.nan,
      double.infinity,
      .0625,
    ]) {
      expect(() => contactFixture(offset: value), throwsFormatException);
    }
    expect(
      () => contactFixture(offset: -.0625, replacesGround: false),
      throwsFormatException,
    );
  });
}

({ProjectManifest project, MapData map}) contactFixture({
  Object? offset = 0.0,
  bool replacesGround = true,
  double scale = 1,
}) {
  final fixture = spatialBorderFixture();
  final raw = fixture.project.toJson();
  final record = (raw['borderCatalog']['records'] as List).single as Map;
  for (final key in ['draft', 'latestPublished']) {
    final definition = (record[key] as Map)['definition'] as Map;
    definition['replacesGround'] = replacesGround;
    definition['groundBaseOffset'] = offset;
  }
  (raw['models3d'] as List).single['scale'] = scale;
  return (project: ProjectManifest.fromJson(raw), map: fixture.map);
}

SpatialBorderResolutionResult resolve(ProjectManifest project, MapData map) =>
    resolveSpatialBorderFeature(
      manifest: project,
      map: map,
      layerId: 'border',
      featureId: 'fence',
    );

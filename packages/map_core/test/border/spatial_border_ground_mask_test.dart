import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_resolution_test.dart' show spatialBorderFixture;

void main() {
  test('a cell ground mask survives draft and publication serialization', () {
    final fixture = spatialBorderFixture();
    final raw = fixture.project.toJson();
    final record = (raw['borderCatalog']['records'] as List).single as Map;
    for (final key in ['draft', 'latestPublished']) {
      (record[key] as Map)['definition']['masksGroundCells'] = true;
    }
    expect(() => ProjectManifest.fromJson(raw), returnsNormally);
    final project = ProjectManifest.fromJson(raw);
    final saved = encodeBorderBlueprintRecordJson(
      project.borderCatalog.records.single,
      formatVersion: 5,
    );
    for (final key in ['draft', 'latestPublished']) {
      expect((saved[key] as Map)['definition']['masksGroundCells'], isTrue);
    }
    expect(ProjectManifest.fromJson(project.toJson()), project);
  });

  test('a cell ground mask changes the publication fingerprint', () {
    final fixture = spatialBorderFixture();
    final raw = fixture.project.toJson();
    final record = (raw['borderCatalog']['records'] as List).single as Map;
    for (final key in ['draft', 'latestPublished']) {
      (record[key] as Map)['definition']['masksGroundCells'] = true;
    }
    String fingerprint(ProjectManifest project) =>
        computeBorderPublicationCandidateFingerprint(
          blueprintId: 'fence',
          resolverVersion: borderResolverVersion,
          definition:
              project.borderCatalog.records.single.latestPublished!.definition,
        );
    expect(() => ProjectManifest.fromJson(raw), returnsNormally);
    expect(
      fingerprint(ProjectManifest.fromJson(raw)),
      isNot(fingerprint(fixture.project)),
    );
  });

  test('cell masking rejects ground lowering and invalid flag values', () {
    for (final flag in [null, 'true', 1]) {
      final raw = spatialBorderFixture().project.toJson();
      final record = (raw['borderCatalog']['records'] as List).single as Map;
      (record['draft'] as Map)['definition']['masksGroundCells'] = flag;
      expect(() => ProjectManifest.fromJson(raw), throwsFormatException);
    }
    final raw = spatialBorderFixture().project.toJson();
    final record = (raw['borderCatalog']['records'] as List).single as Map;
    (record['draft'] as Map)['definition']['masksGroundCells'] = true;
    (record['draft'] as Map)['definition']['replacesGround'] = true;
    expect(() => ProjectManifest.fromJson(raw), throwsFormatException);
  });

  test('mask cells follow the authored anchor through rotation and scale', () {
    final fixture = maskFixture(
      scale: 2,
      anchor: Model3dVector3(x: .125, y: 0, z: -.125),
    );
    expect(
      resolveSpatialBorderGroundMaskCells(
        manifest: fixture.project,
        map: fixture.map,
      ),
      {(1, 1), (2, 1), (3, 1), (3, 2), (3, 3)},
    );
    expect(fixture.map.spatialScene!.heightLevels, List.filled(36, 1));
    final before = fixture.map.toJson();
    resolveSpatialBorderGroundMaskCells(
      manifest: fixture.project,
      map: fixture.map,
    );
    expect(fixture.map.toJson(), before);
  });

  test('a zero-depth wall still masks its logical cell', () {
    final fixture = maskFixture();
    final raw = fixture.project.toJson();
    final bounds = (raw['models3d'] as List).single['inspection']['bounds'];
    bounds['min']['z'] = 0;
    bounds['max']['z'] = 0;
    final project = ProjectManifest.fromJson(raw);
    expect(
      resolveSpatialBorderGroundMaskCells(manifest: project, map: fixture.map),
      {(1, 1), (2, 1), (3, 1), (3, 2), (3, 3)},
    );
  });

  test('a missing instance or stale publication cannot mask ground', () {
    final fixture = maskFixture();
    final raw = fixture.project.toJson();
    (raw['borderCatalog']['records'] as List)
            .single['latestPublished']['revision'] =
        2;
    expect(
      resolveSpatialBorderGroundMaskCells(
        manifest: ProjectManifest.fromJson(raw),
        map: fixture.map,
      ),
      isEmpty,
    );
    final incomplete = fixture.map.copyWith(
      spatialScene: fixture.map.spatialScene!.copyWith(
        instances: fixture.map.spatialScene!.instances.skip(1).toList(),
      ),
    );
    expect(
      resolveSpatialBorderGroundMaskCells(
        manifest: fixture.project,
        map: incomplete,
      ),
      isEmpty,
    );
  });

  test('cell masking rejects edge strokes and filled region geometry', () {
    final fixture = maskFixture();
    final definition = fixture
        .project
        .borderCatalog
        .records
        .single
        .latestPublished!
        .definition;
    final centered =
        (fixture.map.layers.single as BorderLayer)
                .content
                .features
                .single
                .geometry
            as BorderStrokeGeometry;
    for (final geometry in [
      BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.gridEdges,
        strokes: centered.strokes,
      ),
      BorderRegionGeometry(width: 6, height: 6, cells: List.filled(36, true)),
    ]) {
      final diagnostics = validateSpatialBorderFeatureGeometry(
        blueprintId: 'fence',
        featureId: 'fence',
        definition: definition,
        geometry: geometry,
      );
      expect(diagnostics.hasErrors, isTrue);
      expect(
        diagnostics.diagnostics.map((d) => d.code),
        contains('border.spatial.ground_mask_cell_centers_required'),
      );
    }
  });
}

({ProjectManifest project, MapData map}) maskFixture({
  double scale = 1,
  Model3dVector3? anchor,
}) {
  final base = spatialBorderFixture(anchor: anchor);
  final raw = base.project.toJson();
  final record = (raw['borderCatalog']['records'] as List).single as Map;
  for (final key in ['draft', 'latestPublished']) {
    (record[key] as Map)['definition']['masksGroundCells'] = true;
  }
  (raw['models3d'] as List).single['scale'] = scale;
  final project = ProjectManifest.fromJson(raw);
  final feature =
      (base.map.layers.single as BorderLayer).content.features.single;
  final map = updateBorderFeatureGeometry(
    base.map,
    layerId: 'border',
    featureId: 'fence',
    geometry: BorderStrokeGeometry(
      alignment: BorderStrokeAlignment.cellCenters,
      strokes: (feature.geometry as BorderStrokeGeometry).strokes,
    ),
  );
  final resolved = resolveSpatialBorderFeature(
    manifest: project,
    map: map,
    layerId: 'border',
    featureId: 'fence',
  );
  expect(resolved.result.canApply, isTrue);
  return (
    project: project,
    map: applySpatialBorderFeaturePreview(
      map,
      manifest: project,
      proposedResult: resolved,
    ),
  );
}

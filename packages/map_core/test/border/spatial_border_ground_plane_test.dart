import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';
import 'spatial_border_resolution_test.dart' as spatial;

Map<String, Object?> planeRecord({
  double gradientX = .5,
  double gradientZ = -.25,
}) {
  final raw = encodeBorderBlueprintRecordJson(
    surfaceFixture().project.borderCatalog.records.single,
    formatVersion: 9,
  );
  for (final section in ['draft', 'latestPublished']) {
    for (final primitive
        in (raw[section] as Map)['definition']['primitives'] as List) {
      for (final surface in primitive['groundSurfaces'] as List) {
        surface['gradientX'] = gradientX;
        surface['gradientZ'] = gradientZ;
      }
    }
  }
  return jsonDecode(jsonEncode(raw)) as Map<String, Object?>;
}

void main() {
  test('inclined cliff terrain round trips through catalog format ten', () {
    final raw = planeRecord();
    final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 10);
    expect(encodeBorderBlueprintRecordJson(record, formatVersion: 10), raw);
    expect(minimumBorderCatalogFormatVersionForRecord(record), 10);
    final own = surfaceFixture();
    final project = own.project.copyWith(
      borderCatalog: ProjectBorderCatalog(formatVersion: 10, records: [record]),
    );
    ProjectValidator.validate(project);
    expect(ProjectManifest.fromJson(project.toJson()), project);
  });

  test(
    'inclined terrain follows translation rotation scale and model pivot',
    () {
      final own = surfaceFixture();
      final record = decodeBorderBlueprintRecordJson(
        planeRecord(),
        formatVersion: 10,
      );
      final project = own.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 10,
          records: [record],
        ),
      );
      final applied = applySpatialBorderFeaturePreview(
        own.map,
        manifest: project,
        proposedResult: spatial.resolve(project, own.map),
      );
      final movedProject = project.copyWith(
        models3d: [
          project.models3d.single.copyWith(
            scale: .5,
            pivot: Model3dVector3(x: .05, y: .2, z: -.02),
          ),
        ],
      );
      final movedMap = applied.copyWith(
        spatialScene: applied.spatialScene!.copyWith(
          instances: [
            for (final instance in applied.spatialScene!.instances)
              instance.copyWith(
                position: Model3dVector3(x: 2, y: 3, z: 2),
                rotationDegrees: 90,
                scale: .5,
              ),
          ],
        ),
      );
      final surface = resolveSpatialBorderGroundSurfaces(
        manifest: movedProject,
        map: movedMap,
      ).first;
      expect(surface.gradientX, closeTo(-.25, 1e-10));
      expect(surface.gradientZ, closeTo(-.5, 1e-10));
      expect(surface.height, closeTo(4.4575, 1e-10));
      expect(surface.heightAt(1.98, 2.0375), closeTo(2.94375, 1e-10));
      expect(
        movedMap.spatialScene!.navigation,
        applied.spatialScene!.navigation,
      );
      expect(
        movedMap.spatialScene!.heightLevels,
        applied.spatialScene!.heightLevels,
      );
    },
  );

  test(
    'inclination contributes to publication identity and value equality',
    () {
      final first = decodeBorderBlueprintRecordJson(
        planeRecord(),
        formatVersion: 10,
      );
      final second = decodeBorderBlueprintRecordJson(
        planeRecord(gradientX: .75),
        formatVersion: 10,
      );
      String fingerprint(BorderBlueprintRecord record) =>
          computeBorderPublicationCandidateFingerprint(
            blueprintId: record.id,
            definition: record.latestPublished!.definition,
            resolverVersion: 1,
          );
      expect(first, isNot(second));
      expect(fingerprint(first), isNot(fingerprint(second)));
      expect(
        first,
        decodeBorderBlueprintRecordJson(planeRecord(), formatVersion: 10),
      );
    },
  );

  test(
    'a sloped draft keeps its minimum format while the publication is flat',
    () {
      final raw = planeRecord();
      final old = encodeBorderBlueprintRecordJson(
        surfaceFixture().project.borderCatalog.records.single,
        formatVersion: 9,
      );
      raw['latestPublished'] = old['latestPublished'];
      final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 10);
      expect(minimumBorderCatalogFormatVersionForRecord(record), 10);
    },
  );

  test('older formats cannot silently discard inclined surfaces', () {
    final raw = planeRecord();
    final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 10);
    expect(
      () => encodeBorderBlueprintRecordJson(record, formatVersion: 9),
      throwsFormatException,
    );
    expect(
      () => decodeBorderBlueprintRecordJson(raw, formatVersion: 9),
      throwsFormatException,
    );
  });

  for (final (field, value) in [
    ('gradientX', double.nan),
    ('gradientZ', double.infinity),
    ('gradientX', '0.5'),
    ('gradientZ', null),
  ]) {
    test('inclined terrain rejects invalid $field $value', () {
      final raw = planeRecord();
      ((raw['draft'] as Map)['definition']['primitives'] as List)
              .first['groundSurfaces'][0][field] =
          value;
      expect(
        () => decodeBorderBlueprintRecordJson(raw, formatVersion: 10),
        throwsFormatException,
      );
    });
  }

  test('inclined terrain requires both gradient coordinates', () {
    final raw = planeRecord();
    (((raw['draft'] as Map)['definition']['primitives'] as List)
                .first['groundSurfaces'][0]
            as Map)
        .remove('gradientZ');
    expect(
      () => decodeBorderBlueprintRecordJson(raw, formatVersion: 10),
      throwsFormatException,
    );
  });
}

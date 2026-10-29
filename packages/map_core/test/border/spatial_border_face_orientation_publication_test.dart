import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';

const _code = 'border.spatial.face_on_land_side';
const _warning = 'border.spatial.face_mass_on_land_side';

void main() {
  test('faces that hang outside their authored direction publish', () {
    for (final replacesGround in [false, true]) {
      final profile =
          _profile(minZ: -1, maxZ: 0, replacesGround: replacesGround);
      final readiness = _readiness(profile);
      expect(readiness.canPublish, isTrue,
          reason: readiness.diagnosticReport.diagnostics.toString());
      expect(readiness.diagnosticReport.diagnostics, isEmpty);
    }
  });

  test('declared ground on the land side is refused with its primitive', () {
    final profile = _profile(minZ: 0, maxZ: 1, replacesGround: true);
    final readiness = _readiness(profile);
    expect(readiness.canPublish, isFalse);
    final refused = readiness.diagnosticReport.diagnostics
        .where((diagnostic) => diagnostic.code == _code)
        .toList();
    expect(refused.map((d) => d.parameters['primitiveId']).toSet(),
        {'lineCap', 'lineStraight'});
    expect(refused.first.severity, BorderDiagnosticSeverity.error);
    expect(refused.first.phase, BorderDiagnosticPhase.publication);
    expect(refused.first.parameters['authoredOrientation'], 'east');
    expect(refused.first.parameters['landSideOffset'], closeTo(.5, 1e-9));
    expect(refused.first.parameters['evidence'], 'groundFootprints');
    expect(refused.first.suggestedAction,
        'border.action.turn_face_towards_lower_ground');
  });

  test('undeclared mass on the land side only warns', () {
    final readiness = _readiness(_profile(minZ: 0, maxZ: 1));
    expect(readiness.canPublish, isTrue);
    final warnings = readiness.diagnosticReport.diagnostics
        .where((diagnostic) => diagnostic.code == _warning)
        .toList();
    expect(warnings, isNotEmpty);
    expect(warnings.first.severity, BorderDiagnosticSeverity.warning);
    expect(warnings.first.parameters['evidence'], 'modelBounds');
    expect(warnings.first.suggestedAction, 'border.action.confirm_module_side');
  });

  test('modules that are not crown-anchored faces are not qualified', () {
    final standing = _profile(
        minZ: 0, maxZ: 1, minY: 0, maxY: 1, anchorY: 0, replacesGround: true);
    expect(_readiness(standing).diagnosticReport.diagnostics, isEmpty);
    final undirected =
        _profile(minZ: 0, maxZ: 1, directed: false, replacesGround: true);
    expect(_readiness(undirected).diagnosticReport.diagnostics, isEmpty);
  });

  test('existing features keep resolving with a refused profile', () {
    final profile = _profile(minZ: 0, maxZ: 1, replacesGround: true);
    expect(
      validateSpatialBorderBlueprint(
        blueprintId: 'fence',
        definition: profile.project.borderCatalog.records.single
            .latestPublished!.definition,
        manifest: profile.project,
      ).diagnostics.map((d) => d.code),
      isNot(contains(_code)),
    );
    expect(_resolve(profile).result.canApply, isTrue);
  });

  test('the qualification matches where the resolver places each face', () {
    for (final (minZ, maxZ, refused) in [(-1.0, 0.0, false), (0.0, 1.0, true)]) {
      final profile =
          _profile(minZ: minZ, maxZ: maxZ, replacesGround: true);
      final resolved = _resolve(profile);
      final model = profile.project.models3d.single;
      final bounds = model.inspection.bounds;
      for (final instance in resolved.modelInstances) {
        final angle = instance.rotationDegrees * math.pi / 180;
        final cx = (bounds.min.x + bounds.max.x) / 2 - model.pivot.x;
        final cz = (bounds.min.z + bounds.max.z) / 2 - model.pivot.z;
        final centreZ = instance.position.z -
            math.sin(angle) * cx +
            math.cos(angle) * cz;
        expect(centreZ > 1, refused,
            reason: 'east stroke on z=1 keeps the land on z>1');
      }
      expect(_readiness(profile).canPublish, !refused);
    }
  });
}

({ProjectManifest project, MapData map}) _profile({
  required double minZ,
  required double maxZ,
  double minY = -1,
  double maxY = 0,
  double anchorY = 0,
  bool directed = true,
  bool replacesGround = false,
}) {
  final fixture = spatialBorderFixture();
  final raw = encodeBorderBlueprintRecordJson(
    fixture.project.borderCatalog.records.single,
    formatVersion: 5,
  );
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['followContourDirection'] = directed;
    if (replacesGround) definition['replacesGround'] = true;
    final primitives = definition['primitives'] as List;
    for (final primitive in primitives.cast<Map>()) {
      primitive['authoredOrientation'] = 'east';
      primitive['anchorWorld'] = {'x': 0.0, 'y': anchorY, 'z': 0.0};
      if (replacesGround) {
        primitive['groundFootprints'] = [
          [
            {'x': -.5, 'z': minZ},
            {'x': .5, 'z': minZ},
            {'x': .5, 'z': maxZ},
            {'x': -.5, 'z': maxZ},
          ],
        ];
      }
    }
    if (directed) {
      final corner = Map<String, Object?>.from(
        primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map,
      );
      primitives.removeWhere((p) => p['role'] == 'lineCorner');
      primitives.add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
      primitives.add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
    }
  }
  final source = fixture.project.models3d.single;
  final project = fixture.project.copyWith(
    models3d: [
      ProjectModel3dEntry(
        id: source.id,
        name: source.name,
        sourceAssetId: source.sourceAssetId,
        relativePath: source.relativePath,
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -.5, y: minY, z: minZ),
            max: Model3dVector3(x: .5, y: maxY, z: maxZ),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      ),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 13,
      records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 13)],
    ),
  );
  final original =
      (fixture.map.layers.single as BorderLayer).content.features.single;
  final map = upsertBorderFeature(
    fixture.map.copyWith(
      spatialScene: MapSpatialScene(
        width: 6,
        depth: 6,
        heightLevels: [
          for (var z = 0; z < 6; z++)
            for (var x = 0; x < 6; x++) z >= 1 ? 1 : 0,
        ],
      ),
    ),
    layerId: 'border',
    feature: BorderFeature(
      id: original.id,
      name: original.name,
      blueprintId: original.blueprintId,
      seed: original.seed,
      geometry: BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.gridEdges,
        strokes: [
          BorderStroke(
            id: 'edge',
            points: [for (var x = 1; x <= 4; x++) GridPos(x: x, y: 1)],
            closed: false,
          ),
        ],
      ),
      overrides: const [],
      keepOutRegions: const [],
    ),
  );
  return (project: project, map: map);
}

BorderPublicationReadinessResult _readiness(
  ({ProjectManifest project, MapData map}) profile,
) => assessBorderPublicationReadiness(
  blueprintId: 'fence',
  definition:
      profile.project.borderCatalog.records.single.latestPublished!.definition,
  resolverVersion: borderResolverVersion,
  project: profile.project,
  visualSnapshots: const [],
  snapshotIntegrity: const {},
  canonicalGalleryReport: BorderPublicationGalleryReport(
    resolverVersion: borderResolverVersion,
    canonicalGalleryVersion: 1,
    candidateFingerprint: 'sha256:${'0' * 64}',
    samples: const [],
  ),
);

SpatialBorderResolutionResult _resolve(
  ({ProjectManifest project, MapData map}) profile,
) => resolveSpatialBorderFeature(
  manifest: profile.project,
  map: profile.map,
  layerId: 'border',
  featureId: 'fence',
);

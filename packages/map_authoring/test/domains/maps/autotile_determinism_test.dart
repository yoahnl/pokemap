import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SemanticAutotileResolver', () {
    test('same seed produces the same bounded semantic artifact', () {
      final fixture = _fixture();
      const resolver = SemanticAutotileResolver();

      final first = resolver.preview(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 41,
        preferredPresetId: 'grass_visual',
        region: const SemanticAutotileRegion(x: 1, y: 1, width: 2, height: 2),
      );
      final second = resolver.resolve(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 41,
        preferredPresetId: 'grass_visual',
        region: const SemanticAutotileRegion(x: 1, y: 1, width: 2, height: 2),
      );

      expect(second.toJson(), first.toJson());
      expect(second.fingerprint, first.fingerprint);
      expect(first.seed, 41);
      expect(first.requestedRegion.width, 2);
      expect(first.resolutionRegion.width, 4, reason: 'one-cell halo');
      expect(first.entries, isNotEmpty);
      expect(jsonEncode(first.toJson()), isNot(contains('tilesetId')));
      expect(jsonEncode(first.toJson()), isNot(contains('sourceRect')));
    });

    test('weighted terrain variants are deterministically seed-sensitive', () {
      final fixture = _fixture();
      const resolver = SemanticAutotileResolver();
      final first = resolver.resolve(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 0,
        preferredPresetId: 'grass_visual',
      );
      final shifted = resolver.resolve(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 1,
        preferredPresetId: 'grass_visual',
      );

      expect(first.fingerprint, isNot(shifted.fingerprint));
      expect(
        first.entries.map((entry) => entry['variantIndex']).toList(),
        isNot(shifted.entries.map((entry) => entry['variantIndex']).toList()),
      );
    });

    test('rebuild and validation expose repairable missing-preset diagnostics',
        () {
      final fixture = _fixture(manifest: _manifest(terrainPresets: const []));
      const resolver = SemanticAutotileResolver();

      final artifact = resolver.rebuildRegion(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 7,
        region: const SemanticAutotileRegion(x: 0, y: 0, width: 2, height: 2),
      );

      expect(artifact.diagnostics, isNotEmpty);
      expect(artifact.diagnostics.first['code'], 'terrain.preset_missing');
      expect(artifact.diagnostics.first['remediation'], isNotEmpty);
      expect(
        resolver.validate(
          manifest: fixture.snapshot.manifest,
          map: fixture.map,
          layerId: 'terrain',
          seed: 7,
        ),
        isNotEmpty,
      );
    });
  });

  group('AutotileActions', () {
    test('preview/apply wraps the exact semantic change set and freezes seed',
        () {
      final fixture = _fixture(emptyTerrain: true);
      final directContext = _context(
        fixture.snapshot,
        actionId: 'terrain.fill',
        parameters: const {
          'mapId': 'fixture',
          'layerId': 'terrain',
          'presetId': 'grass_visual',
          'x': 0,
          'y': 0,
          'width': 2,
          'height': 2,
        },
        seed: 99,
      );
      final direct = const TerrainActions().build(directContext);
      final wrapped = const AutotileActions().build(
        _context(
          fixture.snapshot,
          actionId: 'autotile.apply',
          parameters: const {
            'mapId': 'fixture',
            'semanticActionId': 'terrain.fill',
            'semanticParameters': {
              'layerId': 'terrain',
              'presetId': 'grass_visual',
              'x': 0,
              'y': 0,
              'width': 2,
              'height': 2,
            },
            'previewRegion': {'x': 0, 'y': 0, 'width': 2, 'height': 2},
          },
          seed: 99,
        ),
      );

      expect(
        wrapped.changeSet.changes.single.afterBytes,
        direct.changeSet.changes.single.afterBytes,
      );
      expect(wrapped.changeSet.diff.toJson(), direct.changeSet.diff.toJson());
      final artifact = wrapped.preview['autotile']! as Map<String, Object?>;
      expect(artifact['seed'], 99);
      expect(artifact['fingerprint'], startsWith('sha256:'));
      expect(jsonEncode(artifact), isNot(contains('tilesetId')));
    });

    test('rejects a v5 Smart Tile target before building a legacy preview', () {
      final fixture = _nativeSmartTileFixture();
      final beforeBytes = fixture.snapshot.resourceBytes('map:fixture');

      expect(
        () => const AutotileActions().build(
          _context(
            fixture.snapshot,
            actionId: 'autotile.apply',
            parameters: const {
              'mapId': 'fixture',
              'semanticActionId': 'path.paint',
              'semanticParameters': {
                'layerId': 'smart',
                'presetId': 'legacy-path',
                'x': 0,
                'y': 0,
              },
            },
            seed: 99,
          ),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'smart_tile_wang_paint_compiler_required',
              )
              .having(
                (error) => error.details['operation'],
                'operation',
                'autotile.apply',
              ),
        ),
      );
      expect(fixture.snapshot.resourceBytes('map:fixture'), beforeBytes);
      expect(
        smartTileSemanticCells(fixture.map.layers.single as SmartTileLayer),
        everyElement(0),
      );
    });
  });
}

({ProjectSnapshot snapshot, MapData map}) _nativeSmartTileFixture() {
  const map = MapData(
    id: 'fixture',
    name: 'Fixture',
    size: GridSize(width: 2, height: 2),
    version: ProjectVersion.v5,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: [
      MapLayer.smartTile(
        id: 'smart',
        name: 'Smart',
        presetId: 'native-path',
        usage: SmartTileUsage.path,
        materialPalette: ['', 'road'],
        field: SmartTileField.cell(semanticCells: [0, 0, 0, 0]),
      ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Native Smart Tile fixture',
    version: ProjectVersion.v5,
    maps: [
      ProjectMapEntry(
        id: 'fixture',
        name: 'Fixture',
        relativePath: 'maps/fixture.json',
      ),
    ],
    tilesets: [],
    smartTileCatalog: ProjectSmartTileCatalog(formatVersion: 2),
  );
  final projectBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_fixture'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: projectBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/fixture.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: manifest,
    maps: const [map],
    resourceFingerprints: {
      'project': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: projectBytes,
        ),
      ]),
      'map:fixture': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/fixture.json',
          bytes: mapBytes,
        ),
      ]),
    },
    resourceBytes: {'project': projectBytes, 'map:fixture': mapBytes},
  );
  return (snapshot: snapshot, map: map);
}

({ProjectSnapshot snapshot, MapData map}) _fixture({
  ProjectManifest? manifest,
  bool emptyTerrain = false,
}) {
  final map = MapData(
    id: 'fixture',
    name: 'Fixture',
    size: const GridSize(width: 4, height: 4),
    version: ProjectVersion.v3,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: [
      MapLayer.terrain(
        id: 'terrain',
        name: 'Terrain',
        terrains: List.filled(
          16,
          emptyTerrain ? TerrainType.none : TerrainType.grass,
        ),
      ),
    ],
  );
  final resolvedManifest = manifest ?? _manifest();
  final projectBytes = _encode(resolvedManifest.toJson());
  final mapBytes = _encode(map.toJson());
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_fixture'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: projectBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/fixture.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: resolvedManifest,
    maps: [map],
    resourceFingerprints: {
      'project': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: projectBytes,
        ),
      ]),
      'map:fixture': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/fixture.json',
          bytes: mapBytes,
        ),
      ]),
    },
    resourceBytes: {'project': projectBytes, 'map:fixture': mapBytes},
  );
  return (snapshot: snapshot, map: map);
}

ProjectManifest _manifest({
  List<ProjectTerrainPreset>? terrainPresets,
}) =>
    ProjectManifest(
      name: 'Autotile Fixture',
      version: ProjectVersion.v3,
      maps: const [
        ProjectMapEntry(
          id: 'fixture',
          name: 'Fixture',
          relativePath: 'maps/fixture.json',
        ),
      ],
      tilesets: const [],
      terrainPresets: terrainPresets ??
          [
            ProjectTerrainPreset(
              id: 'grass_visual',
              name: 'Grass',
              terrainType: TerrainType.grass,
              variants: [
                TerrainPresetVariant(
                  frames: const [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 0, y: 0),
                    ),
                  ],
                  weight: 1,
                ),
                TerrainPresetVariant(
                  frames: const [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 1, y: 0),
                    ),
                  ],
                  weight: 1,
                ),
              ],
            ),
          ],
    );

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
  required int seed,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request_${actionId.replaceAll('.', '_')}',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'ws_fixture',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_${actionId.replaceAll('.', '_')}',
        dryRun: true,
      ),
      planId: 'plan_${actionId.replaceAll('.', '_')}',
      seed: seed,
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

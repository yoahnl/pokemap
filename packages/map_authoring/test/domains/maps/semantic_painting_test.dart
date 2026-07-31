import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('semantic map actions', () {
    test('advertises typed preset-based terrain, path, and surface actions',
        () {
      expect(
        TerrainActions.descriptors.map((descriptor) => descriptor.id),
        [
          'terrain.erase',
          'terrain.erase_pattern',
          'terrain.fill',
          'terrain.paint',
          'terrain.paint_pattern',
          'terrain.replace',
        ],
      );
      expect(
        PathActions.descriptors.map((descriptor) => descriptor.id),
        containsAll([
          'path.paint',
          'path.erase',
          'path.fill',
          'path.assign_preset',
          'path.set_properties',
          'path.set_animation_mode',
        ]),
      );
      expect(
        SurfaceActions.descriptors.map((descriptor) => descriptor.id),
        containsAll([
          'surface.paint',
          'surface.erase',
          'surface.erase_area',
          'surface.clear',
          'surface.replace_placements',
        ]),
      );
      final dispatcherIds = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id);
      expect(dispatcherIds, contains('terrain.paint'));
      expect(dispatcherIds, contains('path.paint'));
      expect(dispatcherIds, contains('surface.paint'));
      expect(dispatcherIds, contains('autotile.apply'));
    });

    test('terrain fill resolves a preset ID into semantic terrain cells', () {
      final snapshot = _snapshot();
      final draft = const TerrainActions().build(
        _context(
          snapshot,
          actionId: 'terrain.fill',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'terrain',
            'presetId': 'grass_visual',
            'x': 1,
            'y': 0,
            'width': 2,
            'height': 2,
          },
        ),
      );

      final updated = _afterMap(draft);
      final cells = (updated.layers[0] as TerrainLayer).terrains;
      expect(cells[1], TerrainType.grass);
      expect(cells[2], TerrainType.grass);
      expect(cells[5], TerrainType.grass);
      expect(cells[6], TerrainType.grass);
      expect(draft.preview['presetId'], 'grass_visual');
      expect(jsonEncode(draft.preview), isNot(contains('tilesetId')));
    });

    test('terrain pattern, replace, and erase remain preset-driven', () {
      final stampedDraft = const TerrainActions().build(
        _context(
          _snapshot(),
          actionId: 'terrain.paint_pattern',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'terrain',
            'x': 0,
            'y': 0,
            'width': 2,
            'height': 2,
            'presetIds': [
              'grass_visual',
              'dirt_visual',
              'dirt_visual',
              'grass_visual',
            ],
          },
        ),
      );
      final stamped = _afterMap(stampedDraft);
      expect(
        (stamped.layers[0] as TerrainLayer).terrains.take(2),
        [TerrainType.grass, TerrainType.dirt],
      );

      final replacedDraft = const TerrainActions().build(
        _context(
          _snapshot(map: stamped),
          actionId: 'terrain.replace',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'terrain',
            'fromPresetId': 'dirt_visual',
            'toPresetId': 'grass_visual',
          },
        ),
      );
      final replaced = _afterMap(replacedDraft);
      expect(
        (replaced.layers[0] as TerrainLayer)
            .terrains
            .where((cell) => cell == TerrainType.dirt),
        isEmpty,
      );

      final erasedDraft = const TerrainActions().build(
        _context(
          _snapshot(map: replaced),
          actionId: 'terrain.erase_pattern',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'terrain',
            'x': 0,
            'y': 0,
            'width': 2,
            'height': 2,
          },
        ),
      );
      expect(
        (_afterMap(erasedDraft).layers[0] as TerrainLayer).terrains[0],
        TerrainType.none,
      );
    });

    test('path paint validates and assigns its preset without raw tiles', () {
      final snapshot = _snapshot();
      final draft = const PathActions().build(
        _context(
          snapshot,
          actionId: 'path.paint',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'path',
            'presetId': 'road_path',
            'x': 2,
            'y': 1,
          },
        ),
      );

      final path = _afterMap(draft).layers[1] as PathLayer;
      expect(path.presetId, 'road_path');
      expect(path.cells[6], isTrue);
      expect(draft.preview['presetId'], 'road_path');
      expect(jsonEncode(draft.preview), isNot(contains('tilesetId')));
    });

    test('path fill, properties, and animation mode preserve semantic preset',
        () {
      final filledDraft = const PathActions().build(
        _context(
          _snapshot(),
          actionId: 'path.fill',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'path',
            'presetId': 'road_path',
            'x': 0,
            'y': 0,
            'width': 2,
            'height': 1,
          },
        ),
      );
      final filled = _afterMap(filledDraft);
      expect((filled.layers[1] as PathLayer).cells.take(2), [true, true]);

      final propertiesDraft = const PathActions().build(
        _context(
          _snapshot(map: filled),
          actionId: 'path.set_properties',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'path',
            'properties': {'movement': 'slow'},
          },
        ),
      );
      final withProperties = _afterMap(propertiesDraft);
      expect(
        (withProperties.layers[1] as PathLayer).properties,
        {'movement': 'slow'},
      );

      final animationDraft = const PathActions().build(
        _context(
          _snapshot(map: withProperties),
          actionId: 'path.set_animation_mode',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'path',
            'animationMode': 'always_active',
          },
        ),
      );
      final path = _afterMap(animationDraft).layers[1] as PathLayer;
      expect(path.animationMode, PathAnimationMode.alwaysActive);
      expect(path.presetId, 'road_path');
    });

    test('surface paint and clear use catalog preset identities', () {
      final snapshot = _snapshot();
      final paintedDraft = const SurfaceActions().build(
        _context(
          snapshot,
          actionId: 'surface.paint',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'surface',
            'presetId': 'water_surface',
            'x': 3,
            'y': 2,
          },
        ),
      );
      final painted = _afterMap(paintedDraft);
      final surface = painted.layers[2] as SurfaceLayer;
      expect(surface.placements.single.surfacePresetId, 'water_surface');

      final paintedSnapshot = _snapshot(map: painted);
      final clearedDraft = const SurfaceActions().build(
        _context(
          paintedSnapshot,
          actionId: 'surface.clear',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'surface',
          },
        ),
      );
      expect(
        (_afterMap(clearedDraft).layers[2] as SurfaceLayer).placements,
        isEmpty,
      );
    });

    test('surface replacement and area erase validate every preset ID', () {
      final replacedDraft = const SurfaceActions().build(
        _context(
          _snapshot(),
          actionId: 'surface.replace_placements',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'surface',
            'placements': [
              {'x': 0, 'y': 0, 'presetId': 'water_surface'},
              {'x': 1, 'y': 0, 'presetId': 'water_surface'},
              {'x': 3, 'y': 2, 'presetId': 'water_surface'},
            ],
          },
        ),
      );
      final replaced = _afterMap(replacedDraft);
      expect((replaced.layers[2] as SurfaceLayer).placements, hasLength(3));

      final erasedDraft = const SurfaceActions().build(
        _context(
          _snapshot(map: replaced),
          actionId: 'surface.erase_area',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'surface',
            'x': 0,
            'y': 0,
            'width': 2,
            'height': 1,
          },
        ),
      );
      final remaining =
          (_afterMap(erasedDraft).layers[2] as SurfaceLayer).placements;
      expect(remaining, hasLength(1));
      expect(remaining.single.x, 3);
    });

    test('missing semantic presets return stable repairable diagnostics', () {
      final snapshot = _snapshot();
      for (final action in [
        (
          build: (AuthoringPlanningContext context) =>
              const TerrainActions().build(context),
          actionId: 'terrain.paint',
          layerId: 'terrain',
          code: 'terrain.preset_missing',
        ),
        (
          build: (AuthoringPlanningContext context) =>
              const PathActions().build(context),
          actionId: 'path.paint',
          layerId: 'path',
          code: 'path.preset_missing',
        ),
        (
          build: (AuthoringPlanningContext context) =>
              const SurfaceActions().build(context),
          actionId: 'surface.paint',
          layerId: 'surface',
          code: 'surface.preset_missing',
        ),
      ]) {
        expect(
          () => action.build(
            _context(
              snapshot,
              actionId: action.actionId,
              parameters: {
                'mapId': 'fixture',
                'layerId': action.layerId,
                'presetId': 'missing_preset',
                'x': 0,
                'y': 0,
              },
            ),
          ),
          throwsA(
            isA<MapAuthoringException>()
                .having((error) => error.code, 'code', action.code)
                .having(
                  (error) => error.remediation,
                  'remediation',
                  isNotEmpty,
                ),
          ),
        );
      }
    });
  });
}

MapData _afterMap(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map<String, dynamic>,
    );

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
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
      seed: 17,
    );

ProjectSnapshot _snapshot({MapData? map}) {
  final resolvedMap = map ?? _map();
  final manifest = _manifest();
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = _encode(resolvedMap.toJson());
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_fixture'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/fixture.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: manifest,
    maps: [resolvedMap],
    resourceFingerprints: {
      'project': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: manifestBytes,
        ),
      ]),
      'map:fixture': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/fixture.json',
          bytes: mapBytes,
        ),
      ]),
    },
    resourceBytes: {'project': manifestBytes, 'map:fixture': mapBytes},
  );
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Semantic Fixture',
      version: ProjectVersion.v3,
      maps: const [
        ProjectMapEntry(
          id: 'fixture',
          name: 'Fixture',
          relativePath: 'maps/fixture.json',
        ),
      ],
      tilesets: const [],
      terrainPresets: [
        ProjectTerrainPreset(
          id: 'grass_visual',
          name: 'Grass',
          terrainType: TerrainType.grass,
          variants: [
            TerrainPresetVariant(
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              ],
              weight: 1,
            ),
            TerrainPresetVariant(
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
              ],
              weight: 2,
            ),
          ],
        ),
        const ProjectTerrainPreset(
          id: 'dirt_visual',
          name: 'Dirt',
          terrainType: TerrainType.dirt,
        ),
      ],
      pathPresets: const [
        ProjectPathPreset(
          id: 'road_path',
          name: 'Road',
          variants: [],
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(
        presets: [
          ProjectSurfacePreset(
            id: 'water_surface',
            name: 'Water',
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'water_idle',
                ),
              ],
            ),
          ),
        ],
      ),
    );

MapData _map() => MapData(
      id: 'fixture',
      name: 'Fixture',
      size: const GridSize(width: 4, height: 3),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.terrain(
          id: 'terrain',
          name: 'Terrain',
          terrains: List.filled(12, TerrainType.none),
        ),
        MapLayer.path(
          id: 'path',
          name: 'Path',
          cells: List.filled(12, false),
        ),
        const MapLayer.surface(id: 'surface', name: 'Surface'),
      ],
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

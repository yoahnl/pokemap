import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('canonical Smart Tile layer lifecycle', () {
    test('registers create/delete beside normalize/merge', () {
      expect(
        SmartTileLayerActions.descriptors.map((item) => item.id),
        <String>[
          'smart_tile.layer.create',
          'smart_tile.layer.delete',
          'smart_tile.layer.merge',
          'smart_tile.layer.normalize',
          'smart_tile.layer.reconstruct',
          'smart_tile.layer.set_candidate_weights',
        ],
      );
    });

    test('creates a layer from a published preset and rejects a second terrain',
        () {
      final fixture = _fixture();
      final create = const SmartTileLayerActions().build(
        _context(
          fixture.snapshot,
          actionId: 'smart_tile.layer.create',
          parameters: const {
            'mapId': 'map',
            'presetId': 'grass',
            'layerId': 'terrain',
            'name': 'Terrain',
          },
        ),
      );
      final projected = _projectedMap(create);
      final layer = projected.layers.single as SmartTileLayer;

      expect(layer.usage, SmartTileUsage.terrain);
      expect(layer.materialPalette, <String>['', 'grass']);
      expect(smartTileSemanticCells(layer), <int>[1, 1, 1, 1]);

      final projectedSnapshot = _fixture(map: projected).snapshot;
      expect(
        () => const SmartTileLayerActions().build(
          _context(
            projectedSnapshot,
            actionId: 'smart_tile.layer.create',
            parameters: const {
              'mapId': 'map',
              'presetId': 'grass',
              'layerId': 'terrain-2',
              'name': 'Terrain 2',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile_terrain_provider_already_exists',
          ),
        ),
      );
    });

    test('deletes only Smart Tile layers through the canonical action', () {
      final source = _projectedMap(
        const SmartTileLayerActions().build(
          _context(
            _fixture().snapshot,
            actionId: 'smart_tile.layer.create',
            parameters: const {
              'mapId': 'map',
              'presetId': 'grass',
              'layerId': 'terrain',
              'name': 'Terrain',
            },
          ),
        ),
      );
      final fixture = _fixture(map: source);

      final draft = const SmartTileLayerActions().build(
        _context(
          fixture.snapshot,
          actionId: 'smart_tile.layer.delete',
          parameters: const {'mapId': 'map', 'layerId': 'terrain'},
        ),
      );

      expect(_projectedMap(draft).layers, isEmpty);
    });
  });
}

({ProjectSnapshot snapshot, ProjectManifest manifest, MapData map}) _fixture({
  MapData map = const MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: GridSize(width: 2, height: 2),
  ),
}) {
  final manifest = ProjectManifest(
    name: 'Layer fixture',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tileset.png',
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tileset',
          columns: 1,
          rows: 1,
        ),
      ],
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
      ],
      presets: <ProjectSmartTilePreset>[_preset()],
    ),
  );
  final projectBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  return (
    manifest: manifest,
    map: map,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('project_layers'),
      revision: computeAuthoringBytesFingerprint(
        utf8.encode('layer-snapshot-${map.toJson()}'),
        logicalName: 'snapshot',
      ),
      manifest: manifest,
      maps: <MapData>[map],
      resourceFingerprints: <String, String>{
        'project': computeAuthoringBytesFingerprint(
          projectBytes,
          logicalName: 'project.json',
        ),
        'map:map': computeAuthoringBytesFingerprint(
          mapBytes,
          logicalName: 'maps/map.json',
        ),
      },
      resourceBytes: <String, List<int>>{
        'project': projectBytes,
        'map:map': mapBytes,
      },
      resourceStorageKeys: const <String, String>{
        'project': 'project.json',
        'map:map': 'maps/map.json',
      },
    ),
  );
}

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace:layers',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idempotency-$actionId',
      ),
      planId: 'plan-layers',
      seed: 11,
    );

MapData _projectedMap(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(
        utf8.decode(
          draft.changeSet.changes
              .singleWhere((change) => change.resource.kind == 'map')
              .afterBytes!,
        ),
      ) as Map<String, dynamic>,
    );

ProjectSmartTilePreset _preset() => const ProjectSmartTilePreset(
      id: 'grass',
      name: 'Grass',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'base',
          centerMatch: SmartTileSlotMatch.material('grass'),
          signature: SmartTileSignature(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'base',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('CinematicMapBackdropPreviewModel', () {
    test(
      'builds available cinematic map backdrop preview model from project map and map data',
      () {
        final model = buildCinematicMapBackdropPreviewModel(
          asset: _asset(),
          stageMap: _stageMap(),
          mapData: _mapData(
            layers: const [
              MapLayer.tile(
                id: 'ground',
                name: 'Ground',
                tilesetId: 'tileset_port',
                tiles: [1, 2, 3],
              ),
            ],
          ),
          availableTilesetIds: const {'tileset_port'},
          viewportSize: const CinematicMapBackdropViewportSize(
            width: 640,
            height: 360,
          ),
        );

        expect(model.status, CinematicMapBackdropPreviewStatus.available);
        expect(model.isAvailable, isTrue);
        expect(model.mapId, 'map_lab');
        expect(model.mapLabel, 'Research Lab');
        expect(model.mapRelativePath, 'maps/research_lab.json');
        expect(model.mapDataId, 'map_lab');
        expect(model.sizeSummary, '12 x 10 tuiles');
        expect(model.layers, hasLength(1));
        expect(model.layers.single.id, 'ground');
        expect(model.viewportRecommendation.mode,
            CinematicMapBackdropViewportMode.fitMap);
        expect(model.viewportRecommendation.zoom, greaterThan(0));
        expect(model.diagnostics, isEmpty);
      },
    );

    test('returns backdrop disabled when backdrop mode is none', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(
          stageContext: CinematicStageContext(),
        ),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(
        model.status,
        CinematicMapBackdropPreviewStatus.backdropDisabled,
      );
      expect(model.layers, isEmpty);
      expect(model.diagnostics.map((diagnostic) => diagnostic.severity), [
        CinematicMapBackdropPreviewDiagnosticSeverity.info,
      ]);
    });

    test('returns missing stage map when project map backdrop has no map id',
        () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(mapId: null),
        stageMap: null,
        mapData: null,
      );

      expect(model.status, CinematicMapBackdropPreviewStatus.missingStageMap);
      expect(model.mapId, isNull);
      expect(model.layers, isEmpty);
      expect(model.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicMapBackdropPreviewDiagnosticCode.mapBackdropRequiresStageMap,
      ]);
    });

    test('returns stage map unknown when map id has no project map entry', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(mapId: 'map_unknown'),
        stageMap: null,
        mapData: null,
      );

      expect(model.status, CinematicMapBackdropPreviewStatus.stageMapUnknown);
      expect(model.mapId, 'map_unknown');
      expect(model.mapLabel, 'map_unknown');
      expect(model.layers, isEmpty);
      expect(model.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicMapBackdropPreviewDiagnosticCode.mapBackdropStageMapUnknown,
      ]);
    });

    test('returns map data unavailable when stage map has no map data', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: null,
      );

      expect(
        model.status,
        CinematicMapBackdropPreviewStatus.mapDataUnavailable,
      );
      expect(model.mapId, 'map_lab');
      expect(model.mapLabel, 'Research Lab');
      expect(model.layers, isEmpty);
      expect(model.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicMapBackdropPreviewDiagnosticCode.mapBackdropMapDataUnavailable,
      ]);
    });

    test('returns map data mismatch when map data id differs from stage map',
        () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: _mapData(id: 'map_other'),
      );

      expect(model.status, CinematicMapBackdropPreviewStatus.mapDataMismatch);
      expect(model.mapId, 'map_lab');
      expect(model.mapDataId, 'map_other');
      expect(model.layers, isEmpty);
      expect(model.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicMapBackdropPreviewDiagnosticCode.mapBackdropMapDataMismatch,
      ]);
    });

    test(
        'returns tileset unavailable when tileset ids are provided and missing',
        () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: _mapData(
          tilesetId: 'tileset_port',
          layers: const [
            MapLayer.tile(
              id: 'ground',
              name: 'Ground',
              tiles: [1],
            ),
          ],
        ),
        availableTilesetIds: const {'tileset_forest'},
      );

      expect(
        model.status,
        CinematicMapBackdropPreviewStatus.tilesetUnavailable,
      );
      expect(model.layers, hasLength(1));
      expect(model.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicMapBackdropPreviewDiagnosticCode.mapBackdropTilesetMissing,
      ]);
    });

    test(
        'does not diagnose tileset missing when available tilesets are not provided',
        () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: _mapData(
          tilesetId: 'tileset_port',
          layers: const [
            MapLayer.tile(
              id: 'ground',
              name: 'Ground',
              tiles: [1],
            ),
          ],
        ),
      );

      expect(model.status, CinematicMapBackdropPreviewStatus.available);
      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains(
          CinematicMapBackdropPreviewDiagnosticCode.mapBackdropTilesetMissing,
        )),
      );
    });

    test('projects visual layers from map data', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: _mapData(
          layers: const [
            MapLayer.tile(id: 'ground', name: 'Ground', tiles: [1, 2]),
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
              terrains: [TerrainType.grass],
            ),
            MapLayer.path(id: 'path', name: 'Path', cells: [true]),
            MapLayer.surface(
              id: 'surface',
              name: 'Surface',
              placements: [
                SurfaceCellPlacement(
                  x: 1,
                  y: 2,
                  surfacePresetId: 'flower',
                ),
              ],
            ),
            MapLayer.object(id: 'objects', name: 'Objects'),
            MapLayer.environment(id: 'environment', name: 'Environment'),
          ],
        ),
      );

      expect(model.status, CinematicMapBackdropPreviewStatus.available);
      expect(model.layers.map((layer) => layer.kind), [
        CinematicMapBackdropLayerKind.tile,
        CinematicMapBackdropLayerKind.terrain,
        CinematicMapBackdropLayerKind.path,
        CinematicMapBackdropLayerKind.surface,
        CinematicMapBackdropLayerKind.object,
        CinematicMapBackdropLayerKind.environment,
      ]);
      expect(model.layers.map((layer) => layer.label), [
        'Ground',
        'Terrain',
        'Path',
        'Surface',
        'Objects',
        'Environment',
      ]);
    });

    test(
        'excludes entities events triggers warps and gameplay zones from visual layers',
        () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: _mapData(
          layers: const [
            MapLayer.tile(id: 'ground', name: 'Ground'),
            MapLayer.collision(id: 'collision', name: 'Collision'),
          ],
          entities: const [
            MapEntity(
              id: 'npc_guard',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2, y: 3),
            ),
          ],
          events: const [
            MapEventDefinition(
              id: 'event_alert',
              title: 'Alert',
              position: EventPosition(layerId: 'ground', x: 1, y: 1),
              pages: [MapEventPage(pageNumber: 0)],
            ),
          ],
          triggers: const [
            MapTrigger(
              id: 'trigger_alert',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 2, height: 2),
              ),
            ),
          ],
          warps: const [
            MapWarp(
              id: 'warp_exit',
              pos: GridPos(x: 3, y: 3),
              targetMapId: 'map_other',
              targetPos: GridPos(x: 1, y: 1),
            ),
          ],
          gameplayZones: const [
            MapGameplayZone(
              id: 'zone_encounter',
              kind: GameplayZoneKind.encounter,
              area: MapRect(
                pos: GridPos(x: 0, y: 0),
                size: GridSize(width: 3, height: 3),
              ),
            ),
          ],
        ),
      );

      expect(model.layers, hasLength(1));
      expect(model.layers.single.id, 'ground');
      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains(
          CinematicMapBackdropPreviewDiagnosticCode.mapBackdropLayerUnsupported,
        )),
      );
    });

    test('builds human map label from project map entry', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(name: 'Harbor Square'),
        mapData: _mapData(),
      );

      expect(model.mapLabel, 'Harbor Square');
    });

    test('falls back to map id when label is missing', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(name: '   '),
        mapData: _mapData(),
      );

      expect(model.mapLabel, 'map_lab');
    });

    test('builds size summary from map dimensions', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: _mapData(size: const GridSize(width: 24, height: 18)),
      );

      expect(model.sizeSummary, '24 x 18 tuiles');
    });

    test('builds viewport recommendation without Flutter or Flame', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: _mapData(size: const GridSize(width: 24, height: 18)),
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 120,
          height: 60,
        ),
      );

      expect(
        model.viewportRecommendation.mode,
        CinematicMapBackdropViewportMode.fitMap,
      );
      expect(model.viewportRecommendation.center.x, 12);
      expect(model.viewportRecommendation.center.y, 9);
      expect(model.viewportRecommendation.zoom, closeTo(3.333, 0.001));
    });

    test('does not require runtime state', () {
      final model = buildCinematicMapBackdropPreviewModel(
        asset: _asset(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(model.status, CinematicMapBackdropPreviewStatus.available);
      expect(model.viewportRecommendation.reason, isNotEmpty);
    });
  });
}

CinematicAsset _asset({
  String? mapId = 'map_lab',
  CinematicStageContext? stageContext,
}) {
  return CinematicAsset(
    id: 'cinematic_intro',
    title: 'Intro',
    mapId: mapId,
    stageContext: stageContext ??
        CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
        ),
    timeline: CinematicTimeline(),
  );
}

ProjectMapEntry _stageMap({
  String id = 'map_lab',
  String name = 'Research Lab',
  String? relativePath,
}) {
  return ProjectMapEntry(
    id: id,
    name: name,
    relativePath: relativePath ??
        (id == 'map_lab' ? 'maps/research_lab.json' : 'maps/$id.json'),
  );
}

MapData _mapData({
  String id = 'map_lab',
  String name = 'Research Lab',
  GridSize size = const GridSize(width: 12, height: 10),
  String tilesetId = '',
  List<MapLayer> layers = const [],
  List<MapEntity> entities = const [],
  List<MapEventDefinition> events = const [],
  List<MapTrigger> triggers = const [],
  List<MapWarp> warps = const [],
  List<MapGameplayZone> gameplayZones = const [],
}) {
  return MapData(
    id: id,
    name: name,
    size: size,
    tilesetId: tilesetId,
    layers: layers,
    entities: entities,
    events: events,
    triggers: triggers,
    warps: warps,
    gameplayZones: gameplayZones,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';

void main() {
  const hitTest = MapCanvasObjectHitTest();
  const overlap = GridPos(x: 2, y: 2);

  group('MapCanvasObjectHitTest', () {
    test('returns all object families in painter topmost-first order', () {
      final hits = hitTest.hitStack(
        map: _mapWithEveryFamily,
        project: _project,
        position: overlap,
      );

      expect(
        hits.map((target) => target.kind),
        <MapCanvasObjectKind>[
          MapCanvasObjectKind.warp,
          MapCanvasObjectKind.trigger,
          MapCanvasObjectKind.mapEvent,
          MapCanvasObjectKind.gameplayZone,
          MapCanvasObjectKind.entity,
          MapCanvasObjectKind.placedElement,
        ],
      );
    });

    test('uses canonical layer order and later list entries', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'top-first',
            layerId: 'top',
            elementId: 'element-2x2',
            pos: overlap,
          ),
          MapPlacedElement(
            id: 'bottom',
            layerId: 'bottom',
            elementId: 'element-2x2',
            pos: overlap,
          ),
          MapPlacedElement(
            id: 'top-last',
            layerId: 'top',
            elementId: 'element-2x2',
            pos: overlap,
          ),
        ],
      );

      final hits = hitTest.hitStack(
        map: map,
        project: _project,
        position: overlap,
      );

      expect(
        hits.map((target) => target.id),
        <String>['top-last', 'top-first', 'bottom'],
      );
    });

    test('excludes objects attached to hidden layers', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'hidden-placement',
            layerId: 'hidden',
            elementId: 'element-2x2',
            pos: overlap,
          ),
        ],
        events: const <MapEventDefinition>[
          MapEventDefinition(
            id: 'hidden-event',
            pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
            position: EventPosition(layerId: 'hidden', x: 2, y: 2),
          ),
          MapEventDefinition(
            id: 'missing-layer-event',
            pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
            position: EventPosition(layerId: 'missing', x: 2, y: 2),
          ),
        ],
      );

      expect(
        hitTest.hitStack(map: map, project: _project, position: overlap),
        isEmpty,
      );
    });

    test('uses the authored element footprint and ignores missing assets', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'large',
            layerId: 'top',
            elementId: 'element-2x2',
            pos: overlap,
          ),
          MapPlacedElement(
            id: 'missing',
            layerId: 'top',
            elementId: 'unknown',
            pos: overlap,
          ),
        ],
      );

      final inside = hitTest.hitStack(
        map: map,
        project: _project,
        position: const GridPos(x: 3, y: 3),
      );
      final outside = hitTest.hitStack(
        map: map,
        project: _project,
        position: const GridPos(x: 4, y: 3),
      );

      expect(inside.map((target) => target.id), <String>['large']);
      expect(inside.single.size, const GridSize(width: 2, height: 2));
      expect(outside, isEmpty);
    });

    test('uses the currently painted animation frame footprint', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'animated',
            layerId: 'top',
            elementId: 'animated-element',
            pos: overlap,
          ),
        ],
      );

      expect(
        hitTest.hitStack(
          map: map,
          project: _project,
          position: const GridPos(x: 3, y: 2),
          editorAnimationTimeMs: 0,
        ),
        isEmpty,
      );
      expect(
        hitTest
            .hitStack(
              map: map,
              project: _project,
              position: const GridPos(x: 3, y: 2),
              editorAnimationTimeMs: 100,
            )
            .single
            .id,
        'animated',
      );
    });

    test('respects background and foreground object passes', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'background-placement',
            layerId: 'top',
            elementId: 'element-2x2',
            pos: overlap,
          ),
        ],
        entities: const <MapEntity>[
          MapEntity(
            id: 'background-entity',
            kind: MapEntityKind.custom,
            pos: overlap,
          ),
          MapEntity(
            id: 'foreground-entity',
            kind: MapEntityKind.custom,
            pos: overlap,
            editorVisual: MapEntityEditorVisual(
              elementId: 'element-2x2',
              renderInForeground: true,
            ),
          ),
        ],
      );

      expect(
        hitTest
            .hitStack(map: map, project: _project, position: overlap)
            .map((target) => target.id),
        <String>[
          'foreground-entity',
          'background-entity',
          'background-placement',
        ],
      );
    });

    test('cycles deterministically and restarts when current is absent', () {
      const first = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.warp,
        id: 'warp',
        anchor: overlap,
        size: GridSize(width: 1, height: 1),
      );
      const second = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.trigger,
        id: 'trigger',
        anchor: overlap,
        size: GridSize(width: 1, height: 1),
      );
      const absent = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.entity,
        id: 'absent',
        anchor: overlap,
        size: GridSize(width: 1, height: 1),
      );
      const hits = <MapCanvasObjectTarget>[first, second];

      expect(hitTest.cycleTarget(hits: hits, current: null), first);
      expect(hitTest.cycleTarget(hits: hits, current: first), second);
      expect(hitTest.cycleTarget(hits: hits, current: second), first);
      expect(hitTest.cycleTarget(hits: hits, current: absent), first);
      expect(hitTest.cycleTarget(hits: const [], current: first), isNull);
    });

    test('empty and out-of-map positions return no target', () {
      expect(
        hitTest.hitStack(
          map: _baseMap,
          project: _project,
          position: overlap,
        ),
        isEmpty,
      );
      expect(
        hitTest.hitStack(
          map: _mapWithEveryFamily,
          project: _project,
          position: const GridPos(x: -1, y: 2),
        ),
        isEmpty,
      );
    });
  });

  group('resolveSelectedCanvasObjectTarget', () {
    test('resolves every selected family with the canonical target shape', () {
      MapCanvasObjectTarget? resolve({
        String? placedElementId,
        String? entityId,
        String? eventId,
        String? warpId,
        String? triggerId,
        String? gameplayZoneId,
      }) {
        return resolveSelectedCanvasObjectTarget(
          map: _mapWithEveryFamily,
          project: _project,
          selectedPlacedElementInstanceId: placedElementId,
          selectedEntityId: entityId,
          selectedMapEventId: eventId,
          selectedWarpId: warpId,
          selectedTriggerId: triggerId,
          selectedGameplayZoneId: gameplayZoneId,
        );
      }

      void expectTarget(
        MapCanvasObjectTarget? target, {
        required MapCanvasObjectKind kind,
        required String id,
        required GridSize size,
        String? layerId,
      }) {
        expect(target, isNotNull);
        expect(target!.kind, kind);
        expect(target.id, id);
        expect(target.layerId, layerId);
        expect(target.anchor, overlap);
        expect(target.size, size);
      }

      expectTarget(
        resolve(placedElementId: 'placed'),
        kind: MapCanvasObjectKind.placedElement,
        id: 'placed',
        layerId: 'top',
        size: const GridSize(width: 2, height: 2),
      );
      expectTarget(
        resolve(entityId: 'entity'),
        kind: MapCanvasObjectKind.entity,
        id: 'entity',
        size: const GridSize(width: 1, height: 1),
      );
      expectTarget(
        resolve(eventId: 'event'),
        kind: MapCanvasObjectKind.mapEvent,
        id: 'event',
        layerId: 'top',
        size: const GridSize(width: 1, height: 1),
      );
      expectTarget(
        resolve(gameplayZoneId: 'zone'),
        kind: MapCanvasObjectKind.gameplayZone,
        id: 'zone',
        size: const GridSize(width: 1, height: 1),
      );
      expectTarget(
        resolve(triggerId: 'trigger'),
        kind: MapCanvasObjectKind.trigger,
        id: 'trigger',
        size: const GridSize(width: 1, height: 1),
      );
      expectTarget(
        resolve(warpId: 'warp'),
        kind: MapCanvasObjectKind.warp,
        id: 'warp',
        size: const GridSize(width: 1, height: 1),
      );
    });

    test('uses canonical family order when stale selection flags overlap', () {
      final target = resolveSelectedCanvasObjectTarget(
        map: _mapWithEveryFamily,
        project: _project,
        selectedPlacedElementInstanceId: 'placed',
        selectedEntityId: 'entity',
        selectedMapEventId: 'event',
        selectedWarpId: 'warp',
        selectedTriggerId: 'trigger',
        selectedGameplayZoneId: 'zone',
      );

      expect(target?.kind, MapCanvasObjectKind.warp);
      expect(target?.id, 'warp');
    });

    test('keeps logical identity when visual frame data is unavailable', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'logical-only',
            layerId: 'top',
            elementId: 'missing-frame-data',
            pos: overlap,
          ),
        ],
      );

      final logical = resolveSelectedCanvasObjectTarget(
        map: map,
        project: _project,
        selectedPlacedElementInstanceId: 'logical-only',
        selectedEntityId: null,
        selectedMapEventId: null,
        selectedWarpId: null,
        selectedTriggerId: null,
        selectedGameplayZoneId: null,
      );
      final visual = hitTest.hitStack(
        map: map,
        project: _project,
        position: overlap,
      );

      expect(logical?.kind, MapCanvasObjectKind.placedElement);
      expect(logical?.id, 'logical-only');
      expect(logical?.layerId, 'top');
      expect(logical?.anchor, overlap);
      expect(logical?.size, const GridSize(width: 1, height: 1));
      expect(visual, isEmpty);
    });

    test('returns null when every selected identity is stale', () {
      expect(
        resolveSelectedCanvasObjectTarget(
          map: _mapWithEveryFamily,
          project: _project,
          selectedPlacedElementInstanceId: 'missing-placed',
          selectedEntityId: 'missing-entity',
          selectedMapEventId: 'missing-event',
          selectedWarpId: 'missing-warp',
          selectedTriggerId: 'missing-trigger',
          selectedGameplayZoneId: 'missing-zone',
        ),
        isNull,
      );
    });
  });
}

const _project = ProjectManifest(
  name: 'Hit test',
  version: ProjectVersion.v3,
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'assets/tiles.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'element-2x2',
      name: 'Element 2x2',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
        ),
      ],
    ),
    ProjectElementEntry(
      id: 'animated-element',
      name: 'Animated element',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
          durationMs: 100,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2),
          durationMs: 100,
        ),
      ],
    ),
  ],
);

const _baseMap = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v3,
  visualStack: MapVisualStackConfig.canonicalV1,
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(id: 'top', name: 'Top', tilesetId: 'tiles'),
    TileLayer(
      id: 'hidden',
      name: 'Hidden',
      tilesetId: 'tiles',
      isVisible: false,
    ),
    TileLayer(id: 'bottom', name: 'Bottom', tilesetId: 'tiles'),
  ],
);

final _mapWithEveryFamily = _baseMap.copyWith(
  placedElements: const <MapPlacedElement>[
    MapPlacedElement(
      id: 'placed',
      layerId: 'top',
      elementId: 'element-2x2',
      pos: GridPos(x: 2, y: 2),
    ),
  ],
  entities: const <MapEntity>[
    MapEntity(
      id: 'entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 2),
    ),
  ],
  events: const <MapEventDefinition>[
    MapEventDefinition(
      id: 'event',
      pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
      position: EventPosition(layerId: 'top', x: 2, y: 2),
    ),
  ],
  gameplayZones: const <MapGameplayZone>[
    MapGameplayZone(
      id: 'zone',
      kind: GameplayZoneKind.special,
      special: SpecialZonePayload(),
      area: MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
  triggers: const <MapTrigger>[
    MapTrigger(
      id: 'trigger',
      type: TriggerType.custom,
      area: MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
  warps: const <MapWarp>[
    MapWarp(
      id: 'warp',
      pos: GridPos(x: 2, y: 2),
      targetMapId: 'map',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);

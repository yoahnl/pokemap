import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/map_context_target.dart';
import 'package:map_editor/src/features/editor/application/map_context_target_resolver.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  const resolver = MapContextTargetResolver();
  const hitTest = MapCanvasObjectHitTest();
  const overlap = GridPos(x: 2, y: 2);

  group('MapContextTargetResolver canvas targets', () {
    test('matches the canonical top-first hit for all six object families', () {
      final familyMaps = <MapData>[
        _baseMap.copyWith(
          placedElements: const <MapPlacedElement>[
            MapPlacedElement(
              id: 'placed',
              layerId: 'top',
              elementId: 'element',
              pos: overlap,
            ),
          ],
        ),
        _baseMap.copyWith(
          entities: const <MapEntity>[
            MapEntity(
              id: 'entity',
              kind: MapEntityKind.custom,
              pos: overlap,
            ),
          ],
        ),
        _baseMap.copyWith(
          events: const <MapEventDefinition>[
            MapEventDefinition(
              id: 'event',
              pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
              position: EventPosition(layerId: 'top', x: 2, y: 2),
            ),
          ],
        ),
        _baseMap.copyWith(
          gameplayZones: const <MapGameplayZone>[
            MapGameplayZone(
              id: 'zone',
              kind: GameplayZoneKind.special,
              special: SpecialZonePayload(),
              area: MapRect(
                pos: overlap,
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
        ),
        _baseMap.copyWith(
          triggers: const <MapTrigger>[
            MapTrigger(
              id: 'trigger',
              type: TriggerType.custom,
              area: MapRect(
                pos: overlap,
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
        ),
        _baseMap.copyWith(
          warps: const <MapWarp>[
            MapWarp(
              id: 'warp',
              pos: overlap,
              targetMapId: 'map',
              targetPos: GridPos(x: 0, y: 0),
            ),
          ],
        ),
      ];

      for (final map in familyMaps) {
        final expected = hitTest
            .hitStack(map: map, project: _project, position: overlap)
            .first;
        final resolved = resolver.resolveCanvasTarget(
          map: map,
          project: _project,
          position: overlap,
          activeLayerId: 'bottom',
        );

        expect(
          resolved,
          isA<MapObjectContextTarget>()
              .having((target) => target.target, 'target', expected),
        );
      }
    });

    test('uses canonical top-first order for an overlapping object stack', () {
      final expected = hitTest
          .hitStack(
            map: _mapWithEveryFamily,
            project: _project,
            position: overlap,
          )
          .first;

      final resolved = resolver.resolveCanvasTarget(
        map: _mapWithEveryFamily,
        project: _project,
        position: overlap,
        activeLayerId: 'bottom',
      );

      expect(expected.kind, MapCanvasObjectKind.warp);
      expect(
        resolved,
        isA<MapObjectContextTarget>()
            .having((target) => target.target, 'target', expected),
      );
    });

    test('returns a cell only when no object target exists', () {
      final resolved = resolver.resolveCanvasTarget(
        map: _paintedLayersMap,
        project: _project,
        position: overlap,
        activeLayerId: 'bottom',
      );

      expect(
        resolved,
        isA<MapCellContextTarget>()
            .having((target) => target.position, 'position', overlap),
      );
    });

    test('resolves the top visible painted layer instead of the active layer',
        () {
      final resolved = resolver.resolveCanvasTarget(
        map: _paintedLayersMap,
        project: _project,
        position: overlap,
        activeLayerId: 'bottom',
      ) as MapCellContextTarget;

      expect(resolved.layerId, 'top');
      expect(resolved.isPainted, isTrue);
    });

    test('empty cell falls back only to an active compatible layer', () {
      final compatible = resolver.resolveCanvasTarget(
        map: _paintedLayersMap,
        project: _project,
        position: const GridPos(x: 0, y: 0),
        activeLayerId: 'bottom',
      ) as MapCellContextTarget;
      final incompatible = resolver.resolveCanvasTarget(
        map: _paintedLayersMap,
        project: _project,
        position: const GridPos(x: 0, y: 0),
        activeLayerId: 'border',
      ) as MapCellContextTarget;

      expect(compatible.layerId, 'bottom');
      expect(compatible.isPainted, isFalse);
      expect(incompatible.layerId, isNull);
      expect(incompatible.isPainted, isFalse);
    });
  });

  group('MapContextTargetResolver selected object', () {
    test('uses logical identity even when placed-element frames are missing',
        () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'logical-only',
            layerId: 'top',
            elementId: 'missing',
            pos: overlap,
          ),
        ],
      );
      final editor = EditorState(
        activeMap: map,
        project: _project,
        selectedPlacedElementInstanceId: 'logical-only',
      );

      final resolved = resolver.resolveSelectedObject(
        map: map,
        project: _project,
        editor: editor,
      );

      expect(
        resolved?.target,
        isA<MapCanvasObjectTarget>()
            .having(
              (target) => target.kind,
              'kind',
              MapCanvasObjectKind.placedElement,
            )
            .having((target) => target.id, 'id', 'logical-only')
            .having(
              (target) => target.size,
              'fallback size',
              const GridSize(width: 1, height: 1),
            ),
      );
      expect(
        hitTest.hitStack(map: map, project: _project, position: overlap),
        isEmpty,
      );
    });

    test('returns null for a stale selection', () {
      final resolved = resolver.resolveSelectedObject(
        map: _baseMap,
        project: _project,
        editor: const EditorState(selectedEntityId: 'missing'),
      );

      expect(resolved, isNull);
    });
  });
}

const _project = ProjectManifest(
  name: 'Context target resolver',
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
      id: 'element',
      name: 'Element',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
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
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(id: 'top', name: 'Top', tilesetId: 'tiles'),
    TileLayer(id: 'bottom', name: 'Bottom', tilesetId: 'tiles'),
  ],
);

final _mapWithEveryFamily = _baseMap.copyWith(
  placedElements: const <MapPlacedElement>[
    MapPlacedElement(
      id: 'placed',
      layerId: 'top',
      elementId: 'element',
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

const _paintedLayersMap = MapData(
  id: 'painted',
  name: 'Painted',
  version: ProjectVersion.v3,
  visualStack: MapVisualStackConfig.canonicalV1,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'hidden',
      name: 'Hidden',
      tilesetId: 'tiles',
      isVisible: false,
      tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0],
    ),
    TileLayer(
      id: 'top',
      name: 'Top',
      tilesetId: 'tiles',
      tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0],
    ),
    TileLayer(
      id: 'bottom',
      name: 'Bottom',
      tilesetId: 'tiles',
      tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
    ),
    BorderLayer(id: 'border', name: 'Border'),
  ],
);

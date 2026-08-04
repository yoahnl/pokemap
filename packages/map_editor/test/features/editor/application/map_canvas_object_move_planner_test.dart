import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_move_planner.dart';

void main() {
  const planner = MapCanvasObjectMovePlanner();

  group('MapCanvasObjectMovePlanner', () {
    test('moves an entity by changing its position only', () {
      const entity = MapEntity(
        id: 'npc',
        name: '  Preserved name  ',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 2, height: 2),
        npc: MapEntityNpcData(
          displayName: '  Preserved display name  ',
          visualElementId: 'npc-visual',
        ),
        editorVisual: MapEntityEditorVisual(
          elementId: 'npc-visual',
          renderInForeground: true,
        ),
        blocksMovement: false,
        properties: <String, String>{' padded ': ' value '},
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 8, height: 8),
        entities: <MapEntity>[entity],
      );

      final plan = planner.plan(
        map: map,
        project: null,
        target: const MapCanvasObjectTarget(
          kind: MapCanvasObjectKind.entity,
          id: 'npc',
          anchor: GridPos(x: 7, y: 7),
          size: GridSize(width: 1, height: 1),
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(plan.canCommit, isTrue);
      expect(plan.rejection, isNull);
      expect(plan.sourceMap, same(map));
      expect(plan.sourceTarget?.anchor, entity.pos);
      expect(plan.sourceTarget?.size, entity.size);
      final moved = plan.candidateMap!.entities.single;
      expect(moved.pos, const GridPos(x: 4, y: 3));
      expect(moved.copyWith(pos: entity.pos), entity);
      expect(map.entities.single, entity);
    });

    test('moves an authored placed element without normalizing its data', () {
      final shadow = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );
      final placed = MapPlacedElement(
        id: 'placed',
        layerId: 'decor',
        elementId: 'element-2x2',
        pos: const GridPos(x: 1, y: 1),
        applyCollision: false,
        opacity: 0.4,
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          speed: 1.5,
          randomStart: true,
        ),
        shadowOverride: shadow,
        behaviors: const <MapPlacedElementBehavior>[
          MapPlacedElementBehavior(
            id: '  behavior id  ',
            cooldownMs: 42,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: '  preserved message  ',
            ),
          ),
        ],
        properties: const <String, String>{
          'pokemapPlacementOrigin': 'authored',
          ' padded ': ' value ',
        },
      );
      final map = _emptyMap.copyWith(
        placedElements: <MapPlacedElement>[placed],
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          placed.id,
          size: const GridSize(width: 2, height: 2),
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(plan.canCommit, isTrue);
      expect(plan.sourceTarget?.size, const GridSize(width: 2, height: 2));
      final moved = plan.candidateMap!.placedElements.single;
      expect(moved.pos, const GridPos(x: 4, y: 3));
      expect(moved.copyWith(pos: placed.pos), placed);
      expect(moved.shadowOverride, same(shadow));
    });

    test('uses the canonical primary footprint over transient frame bounds',
        () {
      const animatedProject = ProjectManifest(
        name: 'Animated move footprint',
        version: ProjectVersion.v6,
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
            id: 'animated',
            name: 'Animated',
            tilesetId: 'tiles',
            categoryId: 'decor',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 1, y: 0, width: 2, height: 2),
              ),
            ],
          ),
        ],
      );
      final map = _emptyMap.copyWith(
        size: const GridSize(width: 4, height: 4),
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'animated-placement',
            layerId: 'decor',
            elementId: 'animated',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      const visibleFrameTarget = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.placedElement,
        id: 'animated-placement',
        layerId: 'decor',
        anchor: GridPos(x: 0, y: 0),
        size: GridSize(width: 2, height: 2),
      );

      final rejected = planner.plan(
        map: map,
        project: animatedProject,
        target: visibleFrameTarget,
        destinationAnchor: const GridPos(x: 4, y: 4),
      );
      final ready = planner.plan(
        map: map,
        project: animatedProject,
        target: visibleFrameTarget,
        destinationAnchor: const GridPos(x: 3, y: 3),
      );

      expect(
        rejected.rejection,
        MapCanvasObjectMoveRejection.destinationOutOfBounds,
      );
      expect(ready.canCommit, isTrue);
      expect(
        ready.previewTarget?.size,
        const GridSize(width: 1, height: 1),
      );
    });

    test('moves authored rotations with canonical destination dimensions', () {
      final map = _emptyMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'rotated',
            layerId: 'decor',
            elementId: 'element-3x2',
            pos: GridPos(x: 1, y: 1),
            quarterTurns: 1,
          ),
        ],
      );
      const staleUnrotatedTarget = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.placedElement,
        id: 'rotated',
        layerId: 'decor',
        anchor: GridPos(x: 1, y: 1),
        size: GridSize(width: 3, height: 2),
      );

      final widthEdgeAccepted = planner.plan(
        map: map,
        project: _nonSquareProject,
        target: staleUnrotatedTarget,
        destinationAnchor: const GridPos(x: 6, y: 5),
      );
      final heightEdgeRejected = planner.plan(
        map: map,
        project: _nonSquareProject,
        target: staleUnrotatedTarget,
        destinationAnchor: const GridPos(x: 5, y: 6),
      );

      expect(widthEdgeAccepted.canCommit, isTrue);
      expect(
        widthEdgeAccepted.sourceTarget?.size,
        const GridSize(width: 2, height: 3),
      );
      expect(
        widthEdgeAccepted.previewTarget?.size,
        const GridSize(width: 2, height: 3),
      );
      expect(
        heightEdgeRejected.rejection,
        MapCanvasObjectMoveRejection.destinationOutOfBounds,
      );
      expect(
        heightEdgeRejected.previewTarget?.size,
        const GridSize(width: 2, height: 3),
      );
    });

    test('moves an event while preserving its layer, pages, and metadata', () {
      const event = MapEventDefinition(
        id: 'event',
        title: '  Preserved title  ',
        pages: <MapEventPage>[
          MapEventPage(pageNumber: 0, message: '  Preserved page  '),
        ],
        position: EventPosition(layerId: 'decor', x: 1, y: 2),
        type: MapEventType.effect,
        metadata: <String, String>{' padded ': ' value '},
      );
      final map = _emptyMap.copyWith(
        events: const <MapEventDefinition>[event],
      );

      final plan = planner.plan(
        map: map,
        project: null,
        target: _target(MapCanvasObjectKind.mapEvent, event.id),
        destinationAnchor: const GridPos(x: 5, y: 4),
      );

      expect(plan.canCommit, isTrue);
      final moved = plan.candidateMap!.events.single;
      expect(
        moved.position,
        const EventPosition(layerId: 'decor', x: 5, y: 4),
      );
      expect(moved.copyWith(position: event.position), event);
    });

    test('moves a warp without changing its destination contract', () {
      const warp = MapWarp(
        id: 'warp',
        pos: GridPos(x: 1, y: 2),
        targetMapId: 'target',
        targetPos: GridPos(x: 7, y: 8),
        triggerMode: MapWarpTriggerMode.onBump,
        allowedApproachFacings: <EntityFacing>[
          EntityFacing.north,
          EntityFacing.west,
        ],
        triggerPadding: WarpTriggerPadding(
          top: 1,
          right: 2,
          bottom: 3,
          left: 4,
        ),
      );
      final map = _emptyMap.copyWith(warps: const <MapWarp>[warp]);

      final plan = planner.plan(
        map: map,
        project: null,
        target: _target(MapCanvasObjectKind.warp, warp.id),
        destinationAnchor: const GridPos(x: 5, y: 4),
      );

      expect(plan.canCommit, isTrue);
      final moved = plan.candidateMap!.warps.single;
      expect(moved.pos, const GridPos(x: 5, y: 4));
      expect(moved.copyWith(pos: warp.pos), warp);
    });

    test('moves a trigger while preserving its area size and properties', () {
      const trigger = MapTrigger(
        id: 'trigger',
        name: '  Preserved name  ',
        type: TriggerType.custom,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 3, height: 2),
        ),
        properties: <String, String>{' padded ': ' value '},
      );
      final map = _emptyMap.copyWith(
        triggers: const <MapTrigger>[trigger],
      );

      final plan = planner.plan(
        map: map,
        project: null,
        target: _target(MapCanvasObjectKind.trigger, trigger.id),
        destinationAnchor: const GridPos(x: 4, y: 5),
      );

      expect(plan.canCommit, isTrue);
      final moved = plan.candidateMap!.triggers.single;
      expect(moved.area.pos, const GridPos(x: 4, y: 5));
      expect(moved.copyWith(area: trigger.area), trigger);
    });

    test('moves a gameplay zone without clearing any typed payload', () {
      const zone = MapGameplayZone(
        id: 'zone',
        name: '  Preserved name  ',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 3, height: 2),
        ),
        priority: 9,
        encounter: EncounterZonePayload(encounterTableId: 'table'),
        movement: MovementZonePayload(),
        movementEffect: MovementEffectZonePayload(movementCost: 3),
        hazard: HazardZonePayload(damagePerStep: 4),
        special: SpecialZonePayload(
          scriptKey: 'script',
          properties: <String, String>{' padded ': ' value '},
        ),
      );
      final map = _emptyMap.copyWith(
        gameplayZones: const <MapGameplayZone>[zone],
      );

      final plan = planner.plan(
        map: map,
        project: null,
        target: _target(MapCanvasObjectKind.gameplayZone, zone.id),
        destinationAnchor: const GridPos(x: 4, y: 5),
      );

      expect(plan.canCommit, isTrue);
      final moved = plan.candidateMap!.gameplayZones.single;
      expect(moved.area.pos, const GridPos(x: 4, y: 5));
      expect(moved.copyWith(area: zone.area), zone);
    });

    test('returns a no-op without creating a candidate map', () {
      final plan = planner.plan(
        map: _mapWithEntity,
        project: null,
        target: _target(MapCanvasObjectKind.entity, 'entity'),
        destinationAnchor: const GridPos(x: 1, y: 1),
      );

      expect(plan.isNoOp, isTrue);
      expect(plan.canCommit, isFalse);
      expect(plan.candidateMap, isNull);
      expect(plan.rejection, isNull);
    });

    test('rejects missing targets without changing the source map', () {
      final plan = planner.plan(
        map: _emptyMap,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          'missing',
          size: const GridSize(width: 2, height: 2),
        ),
        destinationAnchor: const GridPos(x: 2, y: 2),
      );

      expect(plan.canCommit, isFalse);
      expect(
        plan.rejection,
        MapCanvasObjectMoveRejection.targetNotFound,
      );
      expect(plan.candidateMap, isNull);
      expect(plan.sourceMap, same(_emptyMap));
    });

    test('rejects destinations using each resolved multi-cell footprint', () {
      final cases = <({
        MapData map,
        MapCanvasObjectTarget target,
        ProjectManifest? project,
      })>[
        (
          map: _emptyMap.copyWith(
            placedElements: const <MapPlacedElement>[
              MapPlacedElement(
                id: 'placed',
                layerId: 'decor',
                elementId: 'element-2x2',
                pos: GridPos(x: 1, y: 1),
              ),
            ],
          ),
          target: _target(
            MapCanvasObjectKind.placedElement,
            'placed',
            size: const GridSize(width: 2, height: 2),
          ),
          project: _project,
        ),
        (
          map: _emptyMap.copyWith(
            entities: const <MapEntity>[
              MapEntity(
                id: 'entity',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 2, height: 2),
              ),
            ],
          ),
          target: _target(MapCanvasObjectKind.entity, 'entity'),
          project: null,
        ),
        (
          map: _emptyMap.copyWith(
            triggers: const <MapTrigger>[
              MapTrigger(
                id: 'trigger',
                type: TriggerType.custom,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 2, height: 2),
                ),
              ),
            ],
          ),
          target: _target(MapCanvasObjectKind.trigger, 'trigger'),
          project: null,
        ),
        (
          map: _emptyMap.copyWith(
            gameplayZones: const <MapGameplayZone>[
              MapGameplayZone(
                id: 'zone',
                kind: GameplayZoneKind.special,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 2, height: 2),
                ),
              ),
            ],
          ),
          target: _target(MapCanvasObjectKind.gameplayZone, 'zone'),
          project: null,
        ),
      ];

      for (final entry in cases) {
        final plan = planner.plan(
          map: entry.map,
          project: entry.project,
          target: entry.target,
          destinationAnchor: const GridPos(x: 7, y: 7),
        );

        expect(
          plan.rejection,
          MapCanvasObjectMoveRejection.destinationOutOfBounds,
          reason: entry.target.kind.name,
        );
        expect(plan.previewTarget?.size, const GridSize(width: 2, height: 2));
        expect(plan.candidateMap, isNull);
      }
    });

    test('protects an Environment-owned placement before reading its marker',
        () {
      const placed = MapPlacedElement(
        id: 'generated',
        layerId: 'decor',
        elementId: 'element-2x2',
        pos: GridPos(x: 1, y: 1),
        properties: <String, String>{
          'pokemapPlacementOrigin': 'tile_index',
        },
      );
      final map = _emptyMap.copyWith(
        layers: <MapLayer>[
          EnvironmentLayer(
            id: 'environment',
            name: 'Environment',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: <EnvironmentArea>[
                EnvironmentArea(
                  id: 'area',
                  name: 'Area',
                  presetId: 'forest',
                  mask: EnvironmentAreaMask(
                    width: 8,
                    height: 8,
                    cells: List<bool>.filled(64, true),
                  ),
                  seed: 1,
                  generatedPlacementIds: <String>['generated'],
                ),
              ],
            ),
          ),
          ..._emptyMap.layers,
        ],
        placedElements: const <MapPlacedElement>[placed],
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          placed.id,
          size: const GridSize(width: 2, height: 2),
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(
        plan.rejection,
        MapCanvasObjectMoveRejection.environmentGeneratedPlacement,
      );
      expect(plan.candidateMap, isNull);
    });

    test('moves a tile-index placement and its tile pattern atomically', () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
      );
      final original = map.placedElements.single;

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          original.id,
          size: const GridSize(width: 2, height: 2),
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(plan.canCommit, isTrue);
      final candidate = plan.candidateMap!;
      final moved = candidate.placedElements.single;
      expect(moved.pos, const GridPos(x: 4, y: 3));
      expect(moved.copyWith(pos: original.pos), original);
      expect(_tileAt(candidate, 1, 1), 0);
      expect(_tileAt(candidate, 2, 1), 0);
      expect(_tileAt(candidate, 1, 2), 0);
      expect(_tileAt(candidate, 2, 2), 0);
      expect(_tileAt(candidate, 4, 3), 1);
      expect(_tileAt(candidate, 5, 3), 2);
      expect(_tileAt(candidate, 4, 4), 3);
      expect(_tileAt(candidate, 5, 4), 4);
      expect(_tileAt(map, 1, 1), 1);

      final resynced = const PlacedElementInstanceIndexer().syncLayer(
        map: candidate,
        project: _project,
        layerId: 'decor',
      );
      expect(
        resynced.placedElements.singleWhere((entry) => entry.id == original.id),
        moved,
      );
    });

    test('moves an overlapping tile-index pattern without erasing its result',
        () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          map.placedElements.single.id,
        ),
        destinationAnchor: const GridPos(x: 2, y: 1),
      );

      expect(plan.canCommit, isTrue);
      final candidate = plan.candidateMap!;
      expect(_tileAt(candidate, 1, 1), 0);
      expect(_tileAt(candidate, 1, 2), 0);
      expect(_tileAt(candidate, 2, 1), 1);
      expect(_tileAt(candidate, 3, 1), 2);
      expect(_tileAt(candidate, 2, 2), 3);
      expect(_tileAt(candidate, 3, 2), 4);
    });

    test('rejects a tile-index move that would overwrite destination tiles',
        () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
        extraTiles: <GridPos, int>{
          const GridPos(x: 4, y: 3): 9,
        },
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          map.placedElements.single.id,
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(
        plan.rejection,
        MapCanvasObjectMoveRejection.tileIndexedDestinationOccupied,
      );
      expect(plan.candidateMap, isNull);
      expect(_tileAt(map, 1, 1), 1);
      expect(_tileAt(map, 4, 3), 9);
    });

    test('rejects stale tile-index metadata whose source pattern is absent',
        () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
        includeSourcePattern: false,
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          map.placedElements.single.id,
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(
        plan.rejection,
        MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
      expect(plan.candidateMap, isNull);
    });

    test('preflights a movable target without choosing a destination', () {
      final capability = planner.canStartMove(
        map: _mapWithEntity,
        project: null,
        target: _target(MapCanvasObjectKind.entity, 'entity'),
      );

      expect(capability.allowed, isTrue);
      expect(capability.rejection, isNull);
      expect(capability.reason, isNull);
    });

    test('preflight rejects Environment ownership with the canonical reason',
        () {
      const placed = MapPlacedElement(
        id: 'generated',
        layerId: 'decor',
        elementId: 'element-2x2',
        pos: GridPos(x: 1, y: 1),
      );
      final map = _emptyMap.copyWith(
        layers: <MapLayer>[
          EnvironmentLayer(
            id: 'environment',
            name: 'Environment',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: <EnvironmentArea>[
                EnvironmentArea(
                  id: 'area',
                  name: 'Area',
                  presetId: 'forest',
                  mask: EnvironmentAreaMask(
                    width: 8,
                    height: 8,
                    cells: List<bool>.filled(64, true),
                  ),
                  seed: 1,
                  generatedPlacementIds: <String>['generated'],
                ),
              ],
            ),
          ),
          ..._emptyMap.layers,
        ],
        placedElements: const <MapPlacedElement>[placed],
      );

      final capability = planner.canStartMove(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          placed.id,
          size: const GridSize(width: 2, height: 2),
        ),
      );

      expect(capability.allowed, isFalse);
      expect(
        capability.rejection,
        MapCanvasObjectMoveRejection.environmentGeneratedPlacement,
      );
      expect(
        capability.reason,
        'Cet élément est généré par une zone Environment. '
        'Modifiez ou régénérez cette zone pour le déplacer.',
      );
    });

    test('preflight rejects a placement whose logical bounds are unavailable',
        () {
      final map = _emptyMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'missing-frame',
            layerId: 'decor',
            elementId: 'missing',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      final capability = planner.canStartMove(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          'missing-frame',
        ),
      );

      expect(capability.allowed, isFalse);
      expect(
        capability.rejection,
        MapCanvasObjectMoveRejection.boundsUnavailable,
      );
      expect(
        capability.reason,
        'Déplacement impossible : l’empreinte de l’élément est inconnue.',
      );
    });

    test('preflight rejects an invalid tile-index source projection', () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
        includeSourcePattern: false,
      );

      final capability = planner.canStartMove(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          map.placedElements.single.id,
        ),
      );

      expect(capability.allowed, isFalse);
      expect(
        capability.rejection,
        MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
      expect(
        capability.reason,
        'Déplacement impossible : la projection de tuiles source '
        'n’est plus cohérente.',
      );
    });
  });
}

MapCanvasObjectTarget _target(
  MapCanvasObjectKind kind,
  String id, {
  GridSize size = const GridSize(width: 1, height: 1),
}) {
  return MapCanvasObjectTarget(
    kind: kind,
    id: id,
    anchor: const GridPos(x: 99, y: 99),
    size: size,
  );
}

const _project = ProjectManifest(
  name: 'Move planner',
  version: ProjectVersion.v6,
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
  ],
);

const _nonSquareProject = ProjectManifest(
  name: 'Non-square move planner',
  version: ProjectVersion.v6,
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
      id: 'element-3x2',
      name: 'Element 3x2',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 2),
        ),
      ],
    ),
  ],
);

const _emptyMap = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'decor',
      name: 'Decor',
      cells: <int>[],
    ),
  ],
);

final _mapWithEntity = _emptyMap.copyWith(
  entities: const <MapEntity>[
    MapEntity(
      id: 'entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
    ),
  ],
);

MapData _tileIndexedMap({
  required GridPos source,
  bool includeSourcePattern = true,
  Map<GridPos, int> extraTiles = const <GridPos, int>{},
}) {
  const size = GridSize(width: 8, height: 8);
  final tiles = List<int>.filled(size.width * size.height, 0);
  if (includeSourcePattern) {
    tiles[source.y * size.width + source.x] = 1;
    tiles[source.y * size.width + source.x + 1] = 2;
    tiles[(source.y + 1) * size.width + source.x] = 3;
    tiles[(source.y + 1) * size.width + source.x + 1] = 4;
  }
  for (final entry in extraTiles.entries) {
    tiles[entry.key.y * size.width + entry.key.x] = entry.value;
  }
  return MapData(
    id: 'tile-index-map',
    name: 'Tile index map',
    version: ProjectVersion.v6,
    size: size,
    layers: <MapLayer>[
      TileLayer(
        id: 'decor',
        name: 'Decor',
        palette: List<TileLayerPaletteEntry>.generate(
          9,
          (index) => TileLayerPaletteEntry(
            tilesetId: 'tiles',
            localTileId: index,
          ),
          growable: false,
        ),
        cells: tiles,
      ),
    ],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'stable-derived-id',
        layerId: 'decor',
        elementId: 'element-2x2',
        pos: source,
        applyCollision: false,
        opacity: 0.6,
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
        ),
        behaviors: const <MapPlacedElementBehavior>[
          MapPlacedElementBehavior(
            id: 'behavior',
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Keep me',
            ),
          ),
        ],
        properties: const <String, String>{
          'pokemapPlacementOrigin': 'tile_index',
          'custom': 'keep',
        },
      ),
    ],
  );
}

int _tileAt(MapData map, int x, int y) {
  final layer = map.layers.whereType<TileLayer>().single;
  return layer.cells[y * map.size.width + x];
}

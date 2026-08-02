import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('planMapResize', () {
    test('keeps expansion and empty shrink directly applicable', () {
      final map = MapData(
        id: 'quiet-map',
        name: 'Quiet map',
        size: const GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            tiles: List<int>.filled(9, 0),
          ),
        ],
      );

      final expansion = planMapResize(map, width: 5, height: 4);
      final emptyShrink = planMapResize(map, width: 2, height: 2);

      expect(expansion.isExpansion, isTrue);
      expect(expansion.hasShrink, isFalse);
      expect(expansion.canApply, isTrue);
      expect(expansion.impacts, isEmpty);
      expect(emptyShrink.isExpansion, isFalse);
      expect(emptyShrink.hasShrink, isTrue);
      expect(emptyShrink.canApply, isTrue);
      expect(emptyShrink.impacts, isEmpty);
    });

    test('lists every affected authored collection before destructive shrink',
        () {
      final map = _compositeMap();

      final plan = planMapResize(
        map,
        width: 2,
        height: 2,
        project: _project(),
      );

      expect(plan.canApply, isFalse);
      expect(plan.hasDestructiveImpacts, isTrue);
      expect(
        plan.impacts.map((impact) => impact.kind).toSet(),
        containsAll(<MapResizeImpactKind>{
          MapResizeImpactKind.tileLayer,
          MapResizeImpactKind.collisionLayer,
          MapResizeImpactKind.terrainLayer,
          MapResizeImpactKind.pathLayer,
          MapResizeImpactKind.surfaceLayer,
          MapResizeImpactKind.environmentArea,
          MapResizeImpactKind.placedElement,
          MapResizeImpactKind.generatedPlacementReference,
          MapResizeImpactKind.entity,
          MapResizeImpactKind.entityWaypoint,
          MapResizeImpactKind.warp,
          MapResizeImpactKind.warpTriggerArea,
          MapResizeImpactKind.localWarpTarget,
          MapResizeImpactKind.trigger,
          MapResizeImpactKind.gameplayZone,
          MapResizeImpactKind.event,
          MapResizeImpactKind.connection,
        }),
      );

      final tileImpact = plan.impacts.singleWhere(
        (impact) => impact.kind == MapResizeImpactKind.tileLayer,
      );
      expect(tileImpact.subjectId, 'ground');
      expect(tileImpact.affectedCount, 1);
      expect(tileImpact.positions, const <GridPos>[GridPos(x: 3, y: 3)]);

      final wideElementImpact = plan.impacts.singleWhere(
        (impact) =>
            impact.kind == MapResizeImpactKind.placedElement &&
            impact.subjectId == 'wide-house',
      );
      expect(
        wideElementImpact.reason,
        MapResizeImpactReason.footprintOutside,
      );
      expect(wideElementImpact.positions, contains(const GridPos(x: 2, y: 2)));

      final generatedReference = plan.impacts.singleWhere(
        (impact) =>
            impact.kind == MapResizeImpactKind.generatedPlacementReference,
      );
      expect(generatedReference.subjectId, 'forest');
      expect(generatedReference.relatedIds, const <String>['outside-tree']);

      final connectionImpact = plan.impacts.singleWhere(
        (impact) => impact.kind == MapResizeImpactKind.connection,
      );
      expect(
        connectionImpact.reason,
        MapResizeImpactReason.connectionTopologyChanged,
      );
    });

    test('turns Border clipping diagnostics into blocking impacts', () {
      final map = MapData(
        id: 'border-map',
        name: 'Border map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 3, height: 2),
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border',
            name: 'Border',
            content: BorderLayerContent(
              features: <BorderFeature>[
                BorderFeature(
                  id: 'coast',
                  name: 'Coast',
                  blueprintId: 'coast-blueprint',
                  seed: BorderSignedInt64.zero,
                  geometry: BorderRegionGeometry(
                    width: 3,
                    height: 2,
                    cells: const <bool>[
                      false,
                      false,
                      true,
                      false,
                      false,
                      false,
                    ],
                  ),
                  overrides: const <BorderSlotOverride>[],
                  keepOutRegions: const <BorderKeepOutRegion>[],
                ),
              ],
            ),
          ),
        ],
      );

      final plan = planMapResize(
        map,
        width: 2,
        height: 2,
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(plan.canApply, isFalse);
      expect(
        plan.borderDiagnostics.diagnostics.map((value) => value.code),
        contains('region_cell_clipped'),
      );
      final impact = plan.impacts.singleWhere(
        (value) => value.kind == MapResizeImpactKind.borderLayer,
      );
      expect(impact.subjectId, 'coast');
      expect(impact.diagnosticCode, 'region_cell_clipped');
      expect(impact.affectedCount, 1);
    });

    test('keeps exact counts while bounding coordinate samples', () {
      final map = MapData(
        id: 'large-row',
        name: 'Large row',
        size: const GridSize(width: 20, height: 1),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            tiles: List<int>.filled(20, 1),
          ),
        ],
      );

      final plan = planMapResize(map, width: 1, height: 1);
      final impact = plan.impacts.single;

      expect(impact.affectedCount, 19);
      expect(impact.positions, hasLength(8));
      expect(impact.positions.first, const GridPos(x: 1, y: 0));
      expect(impact.positions.last, const GridPos(x: 8, y: 0));
    });

    test('reports clipped values from active Smart Tile edge lattices', () {
      const map = MapData(
        id: 'wang-map',
        name: 'Wang map',
        version: ProjectVersion.v5,
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.smartTile(
            id: 'wang-path',
            name: 'Wang path',
            presetId: 'path',
            usage: SmartTileUsage.path,
            materialPalette: <String>['', 'dirt'],
            field: SmartTileField.edge(
              semanticCells: <int>[0, 0, 0, 0],
              horizontalEdges: <int>[0, 0, 0, 0, 0, 1],
              verticalEdges: <int>[0, 0, 0, 0, 0, 0],
            ),
          ),
        ],
      );

      final plan = planMapResize(map, width: 1, height: 1);

      expect(plan.canApply, isFalse);
      expect(plan.hasDestructiveImpacts, isTrue);
      final impact = plan.impacts.single;
      expect(impact.kind, MapResizeImpactKind.smartTileLayer);
      expect(impact.subjectId, 'wang-path');
      expect(impact.affectedCount, 1);
      expect(impact.positions, const <GridPos>[GridPos(x: 1, y: 2)]);
    });

    test('fails closed when a Border layer has no project tile size', () {
      final map = MapData(
        id: 'border-map',
        name: 'Border map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 2, height: 2),
        layers: const <MapLayer>[
          MapLayer.border(id: 'border', name: 'Border'),
        ],
      );

      final plan = planMapResize(map, width: 3, height: 3);

      expect(plan.canApply, isFalse);
      expect(
        plan.impacts.single.reason,
        MapResizeImpactReason.missingContext,
      );
    });

    test('uses swapped q1 and q3 footprints for resize clipping impacts', () {
      final plan = planMapResize(
        _rotatedPlacedElementsMap(),
        width: 4,
        height: 4,
        project: _rotatedPlacedElementsProject(),
      );

      final impactsById = <String, MapResizeImpact>{
        for (final impact in plan.impacts.where(
            (impact) => impact.kind == MapResizeImpactKind.placedElement))
          impact.subjectId: impact,
      };
      expect(impactsById.keys, containsAll(<String>['q0', 'q1', 'q3']));
      expect(impactsById['q0']!.affectedCount, 4);
      expect(
        impactsById['q0']!.positions,
        const <GridPos>[
          GridPos(x: 4, y: 1),
          GridPos(x: 5, y: 1),
          GridPos(x: 4, y: 2),
          GridPos(x: 5, y: 2),
        ],
      );
      for (final id in <String>['q1', 'q3']) {
        expect(impactsById[id]!.affectedCount, 3);
        expect(
          impactsById[id]!.positions,
          const <GridPos>[
            GridPos(x: 4, y: 1),
            GridPos(x: 4, y: 2),
            GridPos(x: 4, y: 3),
          ],
        );
      }
    });

    test('rejects non-positive target dimensions', () {
      expect(
        () => planMapResize(_emptyMap(), width: 0, height: 2),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapData _emptyMap() => const MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 1, height: 1),
    );

MapData _compositeMap() => MapData(
      id: 'composite',
      name: 'Composite',
      version: ProjectVersion.v2,
      size: const GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'ground',
          name: 'Ground',
          tiles: _cells<int>(0, const <GridPos>[GridPos(x: 3, y: 3)], 7),
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions:
              _cells<bool>(false, const <GridPos>[GridPos(x: 2, y: 0)], true),
        ),
        MapLayer.terrain(
          id: 'terrain',
          name: 'Terrain',
          terrains: _cells<TerrainType>(
            TerrainType.none,
            const <GridPos>[GridPos(x: 0, y: 3)],
            TerrainType.grass,
          ),
        ),
        MapLayer.path(
          id: 'path',
          name: 'Path',
          cells:
              _cells<bool>(false, const <GridPos>[GridPos(x: 3, y: 2)], true),
        ),
        const MapLayer.surface(
          id: 'surface',
          name: 'Surface',
          placements: <SurfaceCellPlacement>[
            SurfaceCellPlacement(
              x: 3,
              y: 0,
              surfacePresetId: 'grass',
            ),
          ],
        ),
        MapLayer.environment(
          id: 'environment',
          name: 'Environment',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'ground',
            areas: <EnvironmentArea>[
              EnvironmentArea(
                id: 'forest',
                name: 'Forest',
                presetId: 'forest-preset',
                mask: EnvironmentAreaMask(
                  width: 4,
                  height: 4,
                  cells: _cells<bool>(
                    false,
                    const <GridPos>[GridPos(x: 2, y: 1)],
                    true,
                  ),
                ),
                seed: 7,
                generatedPlacementIds: const <String>['outside-tree'],
              ),
            ],
          ),
        ),
      ],
      placedElements: const <MapPlacedElement>[
        MapPlacedElement(
          id: 'outside-tree',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 3, y: 3),
        ),
        MapPlacedElement(
          id: 'wide-house',
          layerId: 'ground',
          elementId: 'house',
          pos: GridPos(x: 1, y: 1),
        ),
      ],
      entities: const <MapEntity>[
        MapEntity(
          id: 'large-npc',
          name: 'Large NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 2),
          npc: MapEntityNpcData(
            movement: MapEntityNpcMovementConfig(
              waypoints: <GridPos>[GridPos(x: 3, y: 1)],
            ),
          ),
        ),
      ],
      connections: const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'north-map',
        ),
      ],
      warps: const <MapWarp>[
        MapWarp(
          id: 'outside-warp',
          pos: GridPos(x: 3, y: 0),
          targetMapId: 'other-map',
          targetPos: GridPos(x: 0, y: 0),
        ),
        MapWarp(
          id: 'self-warp',
          pos: GridPos(x: 0, y: 0),
          targetMapId: 'composite',
          targetPos: GridPos(x: 3, y: 3),
          triggerPadding: WarpTriggerPadding(right: 3),
        ),
      ],
      triggers: const <MapTrigger>[
        MapTrigger(
          id: 'trigger',
          name: 'Trigger',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 1, y: 1),
            size: GridSize(width: 2, height: 2),
          ),
        ),
      ],
      gameplayZones: const <MapGameplayZone>[
        MapGameplayZone(
          id: 'zone',
          name: 'Zone',
          kind: GameplayZoneKind.special,
          area: MapRect(
            pos: GridPos(x: 1, y: 1),
            size: GridSize(width: 2, height: 2),
          ),
          special: SpecialZonePayload(scriptKey: 'zone-script'),
        ),
      ],
      events: const <MapEventDefinition>[
        MapEventDefinition(
          id: 'event',
          title: 'Event',
          pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
          position: EventPosition(layerId: 'ground', x: 3, y: 1),
        ),
      ],
    );

ProjectManifest _project() => const ProjectManifest(
      name: 'Resize project',
      version: ProjectVersion.v2,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'nature',
          categoryId: 'nature',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0),
            ),
          ],
        ),
        ProjectElementEntry(
          id: 'house',
          name: 'House',
          tilesetId: 'buildings',
          categoryId: 'buildings',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
            ),
          ],
        ),
      ],
    );

MapData _rotatedPlacedElementsMap() => MapData(
      id: 'rotation-resize',
      name: 'Rotation resize',
      size: const GridSize(width: 6, height: 5),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'ground',
          name: 'Ground',
          tilesetId: 'buildings',
          tiles: List<int>.filled(30, 0),
        ),
      ],
      placedElements: const <MapPlacedElement>[
        MapPlacedElement(
          id: 'q0',
          layerId: 'ground',
          elementId: 'wide-house',
          pos: GridPos(x: 3, y: 1),
        ),
        MapPlacedElement(
          id: 'q1',
          layerId: 'ground',
          elementId: 'wide-house',
          pos: GridPos(x: 3, y: 1),
          quarterTurns: 1,
        ),
        MapPlacedElement(
          id: 'q3',
          layerId: 'ground',
          elementId: 'wide-house',
          pos: GridPos(x: 3, y: 1),
          quarterTurns: 3,
        ),
      ],
    );

ProjectManifest _rotatedPlacedElementsProject() => const ProjectManifest(
      name: 'Rotation resize project',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'wide-house',
          name: 'Wide house',
          tilesetId: 'buildings',
          categoryId: 'buildings',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 2),
            ),
          ],
        ),
      ],
    );

List<T> _cells<T>(T empty, List<GridPos> positions, T value) {
  final cells = List<T>.filled(16, empty);
  for (final position in positions) {
    cells[position.y * 4 + position.x] = value;
  }
  return cells;
}

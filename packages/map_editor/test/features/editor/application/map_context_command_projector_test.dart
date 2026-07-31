import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/map_context_command.dart';
import 'package:map_editor/src/features/editor/application/map_context_command_projector.dart';
import 'package:map_editor/src/features/editor/application/map_context_target.dart';
import 'package:map_editor/src/features/editor/application/world_map_target_editor_intent.dart';

void main() {
  const projector = MapContextCommandProjector();

  group('MapContextCommandProjector objects', () {
    test('projects family-specific editor labels for all six families', () {
      const expectedLabels = <MapCanvasObjectKind, String>{
        MapCanvasObjectKind.placedElement: 'Propriétés',
        MapCanvasObjectKind.entity: 'Ouvrir l’entité',
        MapCanvasObjectKind.mapEvent: 'Ouvrir dans Event Builder',
        MapCanvasObjectKind.warp: 'Modifier la destination',
        MapCanvasObjectKind.trigger: 'Modifier le déclencheur',
        MapCanvasObjectKind.gameplayZone: 'Modifier la zone',
      };

      for (final entry in expectedLabels.entries) {
        final projection = projector.project(
          target: MapObjectContextTarget(_target(entry.key)),
          map: _objectMap,
          project: _project,
          eventBuilderReadModel: null,
        );
        final open = projection.entries.singleWhere(
          (command) => command.command == MapContextCommand.openTargetEditor,
        );

        expect(open.label, entry.value, reason: entry.key.name);
        expect(open.enabled, isTrue, reason: entry.key.name);
        expect(
          projection.entries.any(
            (command) => command.command == MapContextCommand.move,
          ),
          isTrue,
          reason: entry.key.name,
        );
        expect(
          projection.entries.last.destructive,
          isTrue,
          reason: entry.key.name,
        );
      }
    });

    test('projects four real rotations only for an authored placed element',
        () {
      final projection = projector.project(
        target: MapObjectContextTarget(
          _target(MapCanvasObjectKind.placedElement),
        ),
        map: _objectMap,
        project: _project,
        eventBuilderReadModel: null,
      );
      final rotations = projection.entries.where(
        (entry) => <MapContextCommand>{
          MapContextCommand.rotateClockwise,
          MapContextCommand.rotateCounterClockwise,
          MapContextCommand.rotateHalfTurn,
          MapContextCommand.resetRotation,
        }.contains(entry.command),
      );

      expect(rotations, hasLength(4));
      expect(
        rotations
            .singleWhere(
              (entry) => entry.command == MapContextCommand.rotateClockwise,
            )
            .shortcutLabel,
        'R',
      );
      expect(
        rotations
            .singleWhere(
              (entry) =>
                  entry.command == MapContextCommand.rotateCounterClockwise,
            )
            .shortcutLabel,
        'Shift+R',
      );
      expect(
        rotations
            .where(
              (entry) =>
                  entry.command == MapContextCommand.rotateHalfTurn ||
                  entry.command == MapContextCommand.resetRotation,
            )
            .every((entry) => entry.shortcutLabel == null),
        isTrue,
      );
      expect(
        rotations
            .where((entry) => entry.command != MapContextCommand.resetRotation)
            .every((entry) => entry.enabled),
        isTrue,
        reason: rotations
            .map(
              (entry) => '${entry.command.name}:${entry.enabled}:'
                  '${entry.disabledReason}',
            )
            .join(', '),
      );
      expect(
        rotations.singleWhere(
          (entry) => entry.command == MapContextCommand.resetRotation,
        ),
        isA<MapContextCommandEntry>()
            .having((entry) => entry.enabled, 'enabled', isFalse)
            .having(
              (entry) => entry.disabledReason,
              'disabledReason',
              isNotEmpty,
            ),
      );

      for (final kind in MapCanvasObjectKind.values) {
        if (kind == MapCanvasObjectKind.placedElement) continue;
        expect(
          projector
              .project(
                target: MapObjectContextTarget(_target(kind)),
                map: _objectMap,
                project: _project,
                eventBuilderReadModel: null,
              )
              .entries
              .where((entry) => entry.command.name.startsWith('rotate')),
          isEmpty,
        );
      }
    });

    test('omits rotation and disables move for Environment ownership', () {
      final map = _objectMap.copyWith(
        layers: <MapLayer>[
          EnvironmentLayer(
            id: 'environment',
            name: 'Environment',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'top',
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
                  generatedPlacementIds: const <String>['placed'],
                ),
              ],
            ),
          ),
          ..._objectMap.layers,
        ],
      );

      final projection = projector.project(
        target: MapObjectContextTarget(
          _target(MapCanvasObjectKind.placedElement),
        ),
        map: map,
        project: _project,
        eventBuilderReadModel: null,
      );

      expect(
        projection.entries.where(
          (entry) => <MapContextCommand>{
            MapContextCommand.rotateClockwise,
            MapContextCommand.rotateCounterClockwise,
            MapContextCommand.rotateHalfTurn,
            MapContextCommand.resetRotation,
          }.contains(entry.command),
        ),
        isEmpty,
      );
      expect(
        projection.entries.singleWhere(
          (entry) => entry.command == MapContextCommand.move,
        ),
        isA<MapContextCommandEntry>()
            .having((entry) => entry.enabled, 'enabled', isFalse)
            .having(
              (entry) => entry.disabledReason,
              'disabledReason',
              contains('Environment'),
            ),
      );
    });

    test('uses exact dependency block reason for destructive targets', () {
      final project = _project.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: <NarrativeEventRecord>[
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: 'evt_019abcde-0000-7000-8000-000000000301',
                name: 'Linked',
                source: NarrativeEventSourceRef.entityInteract(
                  'map',
                  'entity',
                ),
                conditions: const <NarrativeEventCondition>[],
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const <LegacySourceClaim>[],
        ),
      );

      final projection = projector.project(
        target: MapObjectContextTarget(
          _target(MapCanvasObjectKind.entity),
        ),
        map: _objectMap,
        project: project,
        eventBuilderReadModel: null,
      );
      final deletion = projection.entries.singleWhere(
        (entry) => entry.command == MapContextCommand.delete,
      );

      expect(deletion.enabled, isFalse);
      expect(
        deletion.disabledReason,
        'Action bloquée (suppression de l’entité entity) : source utilisée '
        'par evt_019abcde-0000-7000-8000-000000000301.',
      );
    });

    test('preserves the one target-editor resolution in the projection', () {
      final projection = projector.project(
        target: MapObjectContextTarget(
          _target(MapCanvasObjectKind.mapEvent),
        ),
        map: _objectMap,
        project: _project,
        eventBuilderReadModel: null,
      );

      expect(
        projection.targetEditorResolution,
        isA<WorldMapTargetEditorReady>().having(
          (ready) => ready.intent,
          'intent',
          isA<OpenLegacyMapEventEditorIntent>(),
        ),
      );
    });
  });

  group('MapContextCommandProjector cells and layers', () {
    test('painted cell erases its resolved layer and copies coordinates', () {
      final projection = projector.project(
        target: const MapCellContextTarget(
          position: GridPos(x: 2, y: 3),
          layerId: 'top',
          isPainted: true,
        ),
        map: _objectMap,
        project: _project,
        eventBuilderReadModel: null,
        activeLayerId: 'bottom',
      );

      expect(
        projection.entries.map((entry) => entry.command),
        <MapContextCommand>[
          MapContextCommand.eraseCell,
          MapContextCommand.activateLayer,
          MapContextCommand.copyCoordinates,
        ],
      );
      expect(
        projection.entries
            .singleWhere(
              (entry) => entry.command == MapContextCommand.activateLayer,
            )
            .enabled,
        isTrue,
      );
    });

    test('empty cell never invents an erase action', () {
      final projection = projector.project(
        target: const MapCellContextTarget(
          position: GridPos(x: 2, y: 3),
          layerId: null,
          isPainted: false,
        ),
        map: _objectMap,
        project: _project,
        eventBuilderReadModel: null,
        activeLayerId: 'bottom',
      );

      expect(
        projection.entries.map((entry) => entry.command),
        <MapContextCommand>[
          MapContextCommand.activateLayer,
          MapContextCommand.copyCoordinates,
        ],
      );
      expect(projection.entries.first.enabled, isFalse);
      expect(projection.entries.first.disabledReason, isNotEmpty);
    });

    test('layer capabilities follow top-first group boundaries and impact', () {
      final top = projector.project(
        target: const MapLayerContextTarget('top'),
        map: _objectMap,
        project: _project,
        eventBuilderReadModel: null,
        activeLayerId: 'bottom',
      );
      final bottom = projector.project(
        target: const MapLayerContextTarget('bottom'),
        map: _objectMap,
        project: _project,
        eventBuilderReadModel: null,
        activeLayerId: 'bottom',
      );

      expect(
        top.entries.map((entry) => entry.command),
        <MapContextCommand>[
          MapContextCommand.activateLayer,
          MapContextCommand.renameLayer,
          MapContextCommand.moveLayerUp,
          MapContextCommand.moveLayerDown,
          MapContextCommand.deleteLayer,
        ],
      );
      expect(_entry(top, MapContextCommand.moveLayerUp).enabled, isFalse);
      expect(_entry(top, MapContextCommand.moveLayerDown).enabled, isTrue);
      expect(_entry(bottom, MapContextCommand.activateLayer).enabled, isFalse);
      expect(_entry(bottom, MapContextCommand.moveLayerUp).enabled, isTrue);
      expect(_entry(bottom, MapContextCommand.moveLayerDown).enabled, isFalse);
      expect(_entry(top, MapContextCommand.deleteLayer).destructive, isTrue);
    });

    test('only the supported command enum is ever projected', () {
      final commands = <MapContextCommand>{
        for (final target in <MapContextTarget>[
          MapObjectContextTarget(
            _target(MapCanvasObjectKind.placedElement),
          ),
          const MapCellContextTarget(
            position: GridPos(x: 0, y: 0),
            layerId: 'top',
            isPainted: true,
          ),
          const MapLayerContextTarget('top'),
        ])
          ...projector
              .project(
                target: target,
                map: _objectMap,
                project: _project,
                eventBuilderReadModel: null,
                activeLayerId: 'bottom',
              )
              .entries
              .map((entry) => entry.command),
      };

      expect(commands.difference(MapContextCommand.values.toSet()), isEmpty);
      expect(
        MapContextCommand.values.map((entry) => entry.name),
        isNot(
          contains(
            anyOf(
              'duplicate',
              'lock',
              'sample',
              'replace',
              'paste',
              'center',
            ),
          ),
        ),
      );
    });
  });
}

MapContextCommandEntry _entry(
  MapContextCommandProjection projection,
  MapContextCommand command,
) {
  return projection.entries.singleWhere((entry) => entry.command == command);
}

MapCanvasObjectTarget _target(MapCanvasObjectKind kind) {
  return switch (kind) {
    MapCanvasObjectKind.placedElement => const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.placedElement,
        id: 'placed',
        layerId: 'top',
        anchor: GridPos(x: 1, y: 1),
        size: GridSize(width: 2, height: 1),
      ),
    MapCanvasObjectKind.entity => const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.entity,
        id: 'entity',
        anchor: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
    MapCanvasObjectKind.mapEvent => const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.mapEvent,
        id: 'event',
        layerId: 'top',
        anchor: GridPos(x: 3, y: 3),
        size: GridSize(width: 1, height: 1),
      ),
    MapCanvasObjectKind.gameplayZone => const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.gameplayZone,
        id: 'zone',
        anchor: GridPos(x: 4, y: 4),
        size: GridSize(width: 1, height: 1),
      ),
    MapCanvasObjectKind.trigger => const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.trigger,
        id: 'trigger',
        anchor: GridPos(x: 5, y: 5),
        size: GridSize(width: 1, height: 1),
      ),
    MapCanvasObjectKind.warp => const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.warp,
        id: 'warp',
        anchor: GridPos(x: 6, y: 6),
        size: GridSize(width: 1, height: 1),
      ),
  };
}

const _project = ProjectManifest(
  name: 'Context projector',
  version: ProjectVersion.v3,
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'map',
      name: 'Map',
      relativePath: 'maps/map.json',
    ),
  ],
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
          source: TilesetSourceRect(x: 0, y: 0, width: 2),
        ),
      ],
    ),
  ],
);

final _objectMap = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v3,
  visualStack: MapVisualStackConfig.canonicalV1,
  size: const GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'top',
      name: 'Top',
      tilesetId: 'tiles',
      tiles: List<int>.filled(64, 0, growable: false),
    ),
    TileLayer(
      id: 'bottom',
      name: 'Bottom',
      tilesetId: 'tiles',
      tiles: List<int>.filled(64, 0, growable: false),
    ),
  ],
  placedElements: <MapPlacedElement>[
    const MapPlacedElement(
      id: 'placed',
      layerId: 'top',
      elementId: 'element',
      pos: GridPos(x: 1, y: 1),
    ),
  ],
  entities: <MapEntity>[
    const MapEntity(
      id: 'entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 2),
    ),
  ],
  events: <MapEventDefinition>[
    const MapEventDefinition(
      id: 'event',
      pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
      position: EventPosition(layerId: 'top', x: 3, y: 3),
    ),
  ],
  gameplayZones: <MapGameplayZone>[
    const MapGameplayZone(
      id: 'zone',
      kind: GameplayZoneKind.special,
      special: SpecialZonePayload(),
      area: MapRect(
        pos: GridPos(x: 4, y: 4),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
  triggers: <MapTrigger>[
    const MapTrigger(
      id: 'trigger',
      type: TriggerType.custom,
      area: MapRect(
        pos: GridPos(x: 5, y: 5),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
  warps: <MapWarp>[
    const MapWarp(
      id: 'warp',
      pos: GridPos(x: 6, y: 6),
      targetMapId: 'map',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);

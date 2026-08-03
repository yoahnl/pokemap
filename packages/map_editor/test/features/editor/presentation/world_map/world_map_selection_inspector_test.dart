import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/map_placed_element_rotation_preview_controller.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_selection_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_subtool_disabled_guidance.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/entity_properties_panel.dart';
import 'package:map_editor/src/ui/panels/event_properties_panel.dart';
import 'package:map_editor/src/ui/panels/gameplay_zone_properties_panel.dart';
import 'package:map_editor/src/ui/panels/placed_element_properties_panel.dart';
import 'package:map_editor/src/ui/panels/trigger_properties_panel.dart';
import 'package:map_editor/src/ui/panels/warp_properties_panel.dart';

void main() {
  testWidgets('routes all selected object kinds by exact kind and id',
      (tester) async {
    const cases = <({
      MapCanvasObjectKind kind,
      String id,
      Type bodyType,
    })>[
      (
        kind: MapCanvasObjectKind.placedElement,
        id: 'placed',
        bodyType: PlacedElementPropertiesPanel,
      ),
      (
        kind: MapCanvasObjectKind.entity,
        id: 'entity',
        bodyType: EntityPropertiesPanel,
      ),
      (
        kind: MapCanvasObjectKind.mapEvent,
        id: 'event',
        bodyType: EventPropertiesPanel,
      ),
      (
        kind: MapCanvasObjectKind.gameplayZone,
        id: 'zone',
        bodyType: GameplayZonePropertiesPanel,
      ),
      (
        kind: MapCanvasObjectKind.trigger,
        id: 'trigger',
        bodyType: TriggerPropertiesPanel,
      ),
      (
        kind: MapCanvasObjectKind.warp,
        id: 'warp',
        bodyType: WarpPropertiesPanel,
      ),
    ];
    const bodyTypes = <Type>[
      PlacedElementPropertiesPanel,
      EntityPropertiesPanel,
      EventPropertiesPanel,
      GameplayZonePropertiesPanel,
      TriggerPropertiesPanel,
      WarpPropertiesPanel,
    ];

    for (final testCase in cases) {
      final harness = _SelectionHarness(_stateFor(testCase.kind));
      addTearDown(harness.dispose);
      final before = harness.notifier.state;
      await harness.pump(
        tester,
        WorldMapSelectionInspector(
          target: _target(testCase.kind, testCase.id),
        ),
      );

      expect(find.byType(testCase.bodyType), findsOneWidget);
      expect(
        bodyTypes
            .map((type) => find.byType(type).evaluate().length)
            .reduce((a, b) => a + b),
        1,
      );
      expect(
        find.byKey(
          ValueKey<String>(
            'world-map-selection-${testCase.kind.name}-${testCase.id}',
          ),
        ),
        findsOneWidget,
      );
      expect(harness.notifier.state, same(before));

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('same-kind identity changes replace the keyed editor subtree',
      (tester) async {
    final harness = _SelectionHarness(
      EditorState(
        project: _project,
        activeMap: _mapWithSecondEntity,
        activeLayerId: 'ground',
        selectedEntityId: 'entity',
      ),
    );
    addTearDown(harness.dispose);

    await harness.pump(
      tester,
      WorldMapSelectionInspector(
        target: _target(MapCanvasObjectKind.entity, 'entity'),
      ),
    );
    expect(
      find.byKey(
        const ValueKey<String>('world-map-selection-entity-entity'),
      ),
      findsOneWidget,
    );

    harness.notifier.state = harness.notifier.state.copyWith(
      selectedEntityId: 'entity-2',
    );
    await harness.pump(
      tester,
      WorldMapSelectionInspector(
        target: _target(MapCanvasObjectKind.entity, 'entity-2'),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('world-map-selection-entity-entity'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('world-map-selection-entity-entity-2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('stale target shows callback-free guidance instead of a form',
      (tester) async {
    final harness = _SelectionHarness(
      const EditorState(
        project: _project,
        activeMap: _map,
        activeLayerId: 'ground',
      ),
    );
    addTearDown(harness.dispose);
    final before = harness.notifier.state;

    await harness.pump(
      tester,
      WorldMapSelectionInspector(
        target: _target(MapCanvasObjectKind.entity, 'missing'),
      ),
    );

    expect(find.byType(WorldMapSubtoolDisabledGuidance), findsOneWidget);
    expect(find.byType(EntityPropertiesPanel), findsNothing);
    expect(harness.notifier.state, same(before));
  });

  testWidgets(
    'ignores viewport and status rebuilds but reacts when target becomes stale',
    (tester) async {
      var rebuilds = 0;
      final harness = _SelectionHarness(
        _stateFor(MapCanvasObjectKind.entity),
      );
      addTearDown(harness.dispose);
      await harness.pump(
        tester,
        _CountingWorldMapSelectionInspector(
          target: _target(MapCanvasObjectKind.entity, 'entity'),
          onBuild: () => rebuilds += 1,
        ),
      );
      expect(find.byType(EntityPropertiesPanel), findsOneWidget);

      rebuilds = 0;
      harness.notifier.state = harness.notifier.state.copyWith(
        zoom: 2,
        panOffset: const Offset(12, 8),
        statusMessage: 'viewport-only',
      );
      await tester.pump();

      expect(rebuilds, 0);
      expect(find.byType(EntityPropertiesPanel), findsOneWidget);

      harness.notifier.state = harness.notifier.state.copyWith(
        selectedEntityId: null,
      );
      await tester.pump();

      expect(rebuilds, greaterThan(0));
      expect(find.byType(WorldMapSubtoolDisabledGuidance), findsOneWidget);
    },
  );

  testWidgets('authored placement exposes preview, Apply, and Cancel actions',
      (tester) async {
    final rotationMap = _map.copyWith(
      entities: const <MapEntity>[],
      events: const <MapEventDefinition>[],
      gameplayZones: const <MapGameplayZone>[],
      triggers: const <MapTrigger>[],
      warps: const <MapWarp>[],
    );
    final harness = _SelectionHarness(
      EditorState(
        project: _project,
        activeMap: rotationMap,
        activeLayerId: 'ground',
        selectedPlacedElementInstanceId: 'placed',
      ),
    );
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      WorldMapSelectionInspector(
        target: _target(MapCanvasObjectKind.placedElement, 'placed'),
      ),
    );

    for (final action in <String>[
      'cw',
      'ccw',
      '180',
      'reset',
      'apply',
      'cancel',
    ]) {
      expect(_rotationAction(action), findsOneWidget);
    }

    await tester.tap(_rotationAction('cw'));
    await tester.pump();
    expect(
      harness.container
          .read(mapPlacedElementRotationPreviewProvider)
          ?.targetQuarterTurns,
      1,
    );
    expect(harness.notifier.state.mapUndoStack, isEmpty);

    await tester.tap(_rotationAction('cancel'));
    await tester.pump();
    expect(
      harness.container.read(mapPlacedElementRotationPreviewProvider),
      isNull,
    );
    expect(harness.notifier.state.mapUndoStack, isEmpty);

    await tester.tap(_rotationAction('ccw'));
    await tester.pump();
    expect(
      harness.container
          .read(mapPlacedElementRotationPreviewProvider)
          ?.targetQuarterTurns,
      3,
    );
    await tester.tap(_rotationAction('180'));
    await tester.pump();
    expect(
      harness.container
          .read(mapPlacedElementRotationPreviewProvider)
          ?.targetQuarterTurns,
      2,
    );
    await tester.tap(_rotationAction('reset'));
    await tester.pump();
    expect(
      harness.container
          .read(mapPlacedElementRotationPreviewProvider)
          ?.targetQuarterTurns,
      0,
    );

    await tester.tap(_rotationAction('cw'));
    await tester.pump();
    await tester.tap(_rotationAction('apply'));
    await tester.pump();
    expect(
      harness.notifier.state.activeMap!.placedElements.single.quarterTurns,
      1,
    );
    expect(harness.notifier.state.mapUndoStack, hasLength(1));
  });

  testWidgets('rejected preview shows the precise planner reason', (
    tester,
  ) async {
    final project = _project.copyWith(
      elements: const <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'lamp',
          name: 'Lamp',
          tilesetId: 'world',
          categoryId: 'decor',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
            ),
          ],
        ),
      ],
    );
    final map = _map.copyWith(
      size: const GridSize(width: 2, height: 1),
      layers: const <MapLayer>[
        TileLayer(
          id: 'ground',
          name: 'Ground',
          tilesetId: 'world',
          tiles: <int>[0, 0],
        ),
      ],
      placedElements: const <MapPlacedElement>[
        MapPlacedElement(
          id: 'placed',
          layerId: 'ground',
          elementId: 'lamp',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
      entities: const <MapEntity>[],
      events: const <MapEventDefinition>[],
      gameplayZones: const <MapGameplayZone>[],
      triggers: const <MapTrigger>[],
      warps: const <MapWarp>[],
    );
    final harness = _SelectionHarness(
      EditorState(
        project: project,
        activeMap: map,
        activeLayerId: 'ground',
        selectedPlacedElementInstanceId: 'placed',
      ),
    );
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      WorldMapSelectionInspector(
        target: _target(MapCanvasObjectKind.placedElement, 'placed'),
      ),
    );

    await tester.tap(_rotationAction('cw'));
    await tester.pump();

    expect(find.byType(PokeMapDiagnosticCallout), findsOneWidget);
    expect(
      find.text('La rotation sortirait de la carte.'),
      findsOneWidget,
    );
    expect(
      tester.widget<PokeMapButton>(_rotationAction('apply')).onPressed,
      isNull,
    );
  });

  for (final origin in <String>[
    pokemapPlacementOriginEnvironment,
    pokemapPlacementOriginTileIndex,
  ]) {
    testWidgets('hides rotation actions for $origin ownership', (tester) async {
      final ownedMap = _map.copyWith(
        placedElements: <MapPlacedElement>[
          _map.placedElements.single.copyWith(
            properties: <String, String>{
              pokemapPlacementOriginProperty: origin,
            },
          ),
        ],
      );
      final harness = _SelectionHarness(
        EditorState(
          project: _project,
          activeMap: ownedMap,
          activeLayerId: 'ground',
          selectedPlacedElementInstanceId: 'placed',
        ),
      );
      addTearDown(harness.dispose);
      await harness.pump(
        tester,
        WorldMapSelectionInspector(
          target: _target(MapCanvasObjectKind.placedElement, 'placed'),
        ),
      );

      expect(_rotationAction('cw'), findsNothing);
      expect(find.byType(PlacedElementPropertiesPanel), findsOneWidget);
    });
  }
}

Finder _rotationAction(String action) => find.byKey(
      ValueKey<String>('placed-element-rotation-$action'),
    );

class _CountingWorldMapSelectionInspector extends WorldMapSelectionInspector {
  const _CountingWorldMapSelectionInspector({
    required super.target,
    required this.onBuild,
  });

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onBuild();
    return super.build(context, ref);
  }
}

MapCanvasObjectTarget _target(MapCanvasObjectKind kind, String id) {
  return MapCanvasObjectTarget(
    kind: kind,
    id: id,
    layerId: kind == MapCanvasObjectKind.placedElement ? 'ground' : null,
    anchor: const GridPos(x: 1, y: 1),
    size: const GridSize(width: 1, height: 1),
  );
}

EditorState _stateFor(MapCanvasObjectKind kind) {
  return EditorState(
    project: _project,
    activeMap: _map,
    activeLayerId: 'ground',
    selectedPlacedElementInstanceId:
        kind == MapCanvasObjectKind.placedElement ? 'placed' : null,
    selectedEntityId: kind == MapCanvasObjectKind.entity ? 'entity' : null,
    selectedMapEventId: kind == MapCanvasObjectKind.mapEvent ? 'event' : null,
    selectedGameplayZoneId:
        kind == MapCanvasObjectKind.gameplayZone ? 'zone' : null,
    selectedTriggerId: kind == MapCanvasObjectKind.trigger ? 'trigger' : null,
    selectedWarpId: kind == MapCanvasObjectKind.warp ? 'warp' : null,
  );
}

class _SelectionHarness {
  _SelectionHarness(EditorState state) {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = state;
  }

  final ProviderContainer container = ProviderContainer();
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        key: ValueKey<Object>(container),
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 520,
              height: 900,
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

const _project = ProjectManifest(
  name: 'Selection inspector',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'lamp',
      name: 'Lamp',
      tilesetId: 'world',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
  ],
  placedElements: <MapPlacedElement>[
    MapPlacedElement(
      id: 'placed',
      layerId: 'ground',
      elementId: 'lamp',
      pos: GridPos(x: 1, y: 1),
    ),
  ],
  entities: <MapEntity>[
    MapEntity(
      id: 'entity',
      name: 'Entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
    ),
  ],
  events: <MapEventDefinition>[
    MapEventDefinition(
      id: 'event',
      title: 'Event',
      pages: <MapEventPage>[],
      position: EventPosition(layerId: 'ground', x: 1, y: 1),
    ),
  ],
  gameplayZones: <MapGameplayZone>[
    MapGameplayZone(
      id: 'zone',
      name: 'Zone',
      kind: GameplayZoneKind.special,
      area: MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
  triggers: <MapTrigger>[
    MapTrigger(
      id: 'trigger',
      name: 'Trigger',
      type: TriggerType.interaction,
      area: MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
  warps: <MapWarp>[
    MapWarp(
      id: 'warp',
      pos: GridPos(x: 1, y: 1),
      targetMapId: 'map',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);

final _mapWithSecondEntity = _map.copyWith(
  entities: <MapEntity>[
    ..._map.entities,
    const MapEntity(
      id: 'entity-2',
      name: 'Entity 2',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 1),
    ),
  ],
);

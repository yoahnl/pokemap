import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_event_legacy_authoring_guard.dart';
import 'package:map_editor/src/features/editor/application/world_map_subtool_body_projector.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_place_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/entity_properties_panel.dart';
import 'package:map_editor/src/ui/panels/event_properties_panel.dart';
import 'package:map_editor/src/ui/panels/gameplay_zone_properties_panel.dart';
import 'package:map_editor/src/ui/panels/trigger_properties_panel.dart';
import 'package:map_editor/src/ui/panels/warp_properties_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';

void main() {
  testWidgets(
    'keeps all placement families visible and activates them in one click',
    (tester) async {
      final harness = _PlaceHarness(
        activeLayerId: 'tile',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.place,
          lastPlacementSubtool: WorldMapPlacementSubtool.object,
        ),
      );
      addTearDown(harness.dispose);

      await harness.pump(tester);

      expect(find.text('Que voulez-vous placer ?'), findsOneWidget);
      for (final subtool in WorldMapPlacementSubtool.values) {
        expect(
          find.byKey(
            ValueKey<String>('world-map-placement-family-${subtool.name}'),
          ),
          findsOneWidget,
          reason: subtool.name,
        );
      }

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-placement-family-entity'),
        ),
      );
      await tester.pump();

      expect(
        harness.sessionState.lastPlacementSubtool,
        WorldMapPlacementSubtool.entity,
      );
      expect(harness.sessionState.activeFamily, WorldMapToolFamily.place);
      expect(
        harness.notifier.state.activeTool,
        EditorToolType.entityPlacement,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'world-map-placement-guidance-entityPlacement',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('entity family exposes every real entity kind without a menu',
      (tester) async {
    final harness = _PlaceHarness(
      activeLayerId: 'tile',
      initialSession: const WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.place,
        lastPlacementSubtool: WorldMapPlacementSubtool.entity,
      ),
    );
    addTearDown(harness.dispose);

    await harness.pump(tester);

    for (final kind in MapEntityKind.values) {
      expect(
        find.byKey(
          ValueKey<String>('world-map-entity-kind-${kind.name}'),
        ),
        findsOneWidget,
        reason: kind.name,
      );
    }

    await tester.tap(
      find.byKey(
        const ValueKey<String>('world-map-entity-kind-item'),
      ),
    );
    await tester.pump();

    expect(harness.notifier.state.selectedEntityKind, MapEntityKind.item);
  });

  testWidgets('hub disables a canonically unavailable placement family',
      (tester) async {
    final harness = _PlaceHarness(
      activeLayerId: 'tile',
      project: _v2OnlyProject,
      initialSession: const WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.place,
        lastPlacementSubtool: WorldMapPlacementSubtool.entity,
      ),
    );
    addTearDown(harness.dispose);
    final beforeEditor = harness.notifier.state;
    final beforeSession = harness.sessionState;
    final canonicalReason = narrativeEventLegacyAuthoringBlockReason(
      beforeEditor.project,
      kind: NarrativeEventLegacyAuthoringKind.mapEvent,
    );

    await harness.pump(tester);

    final eventTile = find.byKey(
      const ValueKey<String>('world-map-placement-family-event'),
    );
    final tile = tester.widget<PokeMapActionTile>(eventTile);
    expect(canonicalReason, isNotNull);
    expect(tile.onPressed, isNull);
    expect(tile.disabledReason, canonicalReason);

    await tester.tap(eventTile);
    await tester.pump();

    expect(harness.notifier.state, same(beforeEditor));
    expect(harness.sessionState, same(beforeSession));
  });

  testWidgets('hub remains overflow-free at doubled text scaling',
      (tester) async {
    final harness = _PlaceHarness(
      activeLayerId: 'tile',
      initialSession: const WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.place,
        lastPlacementSubtool: WorldMapPlacementSubtool.entity,
      ),
    );
    addTearDown(harness.dispose);

    await harness.pump(
      tester,
      textScaler: const TextScaler.linear(2),
    );

    expect(
      find.byKey(
        const ValueKey<String>('world-map-placement-family-gameplayZone'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'projects all six Place subtools to palette or typed placement guidance',
    (tester) async {
      const objectBrush = EditorBrush.projectElement(elementId: 'lamp');
      const cases = <({
        WorldMapPlacementSubtool subtool,
        WorldMapSubtoolBodyKind bodyKind,
        EditorToolType resultingTool,
        EditorBrush resultingBrush,
      })>[
        (
          subtool: WorldMapPlacementSubtool.object,
          bodyKind: WorldMapSubtoolBodyKind.elementsPalette,
          resultingTool: EditorToolType.tilePaint,
          resultingBrush: objectBrush,
        ),
        (
          subtool: WorldMapPlacementSubtool.entity,
          bodyKind: WorldMapSubtoolBodyKind.entityPlacement,
          resultingTool: EditorToolType.entityPlacement,
          resultingBrush: EditorBrush.none(),
        ),
        (
          subtool: WorldMapPlacementSubtool.event,
          bodyKind: WorldMapSubtoolBodyKind.eventPlacement,
          resultingTool: EditorToolType.eventPlacement,
          resultingBrush: EditorBrush.none(),
        ),
        (
          subtool: WorldMapPlacementSubtool.trigger,
          bodyKind: WorldMapSubtoolBodyKind.triggerPlacement,
          resultingTool: EditorToolType.triggerPlacement,
          resultingBrush: EditorBrush.none(),
        ),
        (
          subtool: WorldMapPlacementSubtool.warp,
          bodyKind: WorldMapSubtoolBodyKind.warpPlacement,
          resultingTool: EditorToolType.warpPlacement,
          resultingBrush: EditorBrush.none(),
        ),
        (
          subtool: WorldMapPlacementSubtool.gameplayZone,
          bodyKind: WorldMapSubtoolBodyKind.gameplayZonePlacement,
          resultingTool: EditorToolType.gameplayZonePlacement,
          resultingBrush: EditorBrush.none(),
        ),
      ];

      for (final testCase in cases) {
        final harness = _PlaceHarness(activeLayerId: 'tile');
        addTearDown(harness.dispose);
        final result = harness.session.activateTool(
          harness.notifier,
          ActivateWorldMapPlacement(testCase.subtool),
        );
        expect(result.accepted, isTrue, reason: testCase.subtool.name);
        expect(result.resultingTool, testCase.resultingTool);

        await harness.pump(tester);

        expect(
          find.byKey(
            ValueKey<String>(
              'world-map-place-body-${testCase.bodyKind.name}',
            ),
          ),
          findsOneWidget,
        );
        expect(harness.notifier.state.activeTool, testCase.resultingTool);
        expect(harness.notifier.state.activeBrush, testCase.resultingBrush);

        if (testCase.subtool == WorldMapPlacementSubtool.object) {
          expect(find.byType(MapLayerAssetPalette), findsOneWidget);
          expect(find.byType(MapPaletteAssetBrowserLauncher), findsOneWidget);
        } else {
          expect(
            find.byKey(
              ValueKey<String>(
                'world-map-placement-guidance-${testCase.bodyKind.name}',
              ),
            ),
            findsOneWidget,
          );
          expect(_mountedPropertyPanelCount(), 0);
          if (testCase.subtool == WorldMapPlacementSubtool.entity) {
            expect(
              find.byKey(
                const ValueKey<String>('world-map-entity-kind-npc'),
              ),
              findsOneWidget,
            );
            expect(find.byType(EntityPlacementKindPicker), findsNothing);
          } else {
            expect(find.byType(EntityPlacementKindPicker), findsNothing);
          }
        }

        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('mounts a full properties panel only for a resolved matching id',
      (tester) async {
    const cases = <({
      WorldMapPlacementSubtool subtool,
      Type panelType,
      String selectedId,
    })>[
      (
        subtool: WorldMapPlacementSubtool.entity,
        panelType: EntityPropertiesPanel,
        selectedId: 'entity',
      ),
      (
        subtool: WorldMapPlacementSubtool.event,
        panelType: EventPropertiesPanel,
        selectedId: 'event',
      ),
      (
        subtool: WorldMapPlacementSubtool.trigger,
        panelType: TriggerPropertiesPanel,
        selectedId: 'trigger',
      ),
      (
        subtool: WorldMapPlacementSubtool.warp,
        panelType: WarpPropertiesPanel,
        selectedId: 'warp',
      ),
      (
        subtool: WorldMapPlacementSubtool.gameplayZone,
        panelType: GameplayZonePropertiesPanel,
        selectedId: 'zone',
      ),
    ];

    for (final testCase in cases) {
      final harness = _PlaceHarness(activeLayerId: 'tile');
      addTearDown(harness.dispose);
      expect(
        harness.session
            .activateTool(
              harness.notifier,
              ActivateWorldMapPlacement(testCase.subtool),
            )
            .accepted,
        isTrue,
      );
      harness.select(testCase.subtool, testCase.selectedId);

      await harness.pump(tester);

      expect(find.byType(testCase.panelType), findsOneWidget);
      expect(_mountedPropertyPanelCount(), 1);
      expect(
        find.byKey(
          ValueKey<String>(
            'world-map-place-selection-${testCase.subtool.name}-${testCase.selectedId}',
          ),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('stale selection keeps typed guidance and never mounts a form',
      (tester) async {
    final harness = _PlaceHarness(activeLayerId: 'tile');
    addTearDown(harness.dispose);
    expect(
      harness.session
          .activateTool(
            harness.notifier,
            const ActivateWorldMapPlacement(
              WorldMapPlacementSubtool.entity,
            ),
          )
          .accepted,
      isTrue,
    );
    harness.notifier.state = harness.notifier.state.copyWith(
      selectedEntityId: 'missing',
    );

    await harness.pump(tester);

    expect(find.byType(EntityPropertiesPanel), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('world-map-entity-kind-npc'),
      ),
      findsOneWidget,
    );
    expect(find.byType(EntityPlacementKindPicker), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>(
          'world-map-placement-guidance-entityPlacement',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'disabled Place Object guidance is focusable and keyboard read-only',
    (tester) async {
      final harness = _PlaceHarness(
        activeLayerId: 'terrain',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.place,
          lastPlacementSubtool: WorldMapPlacementSubtool.object,
        ),
      );
      addTearDown(harness.dispose);
      final before = harness.notifier.state;

      await harness.pump(tester);

      const reason =
          'Sélectionnez un calque de tuiles modifiable pour placer cet objet.';
      final guidance = find.byKey(
        const ValueKey<String>('world-map-inspector-disabled-guidance'),
      );
      expect(find.text(reason), findsOneWidget);
      expect(tester.widget<Focus>(guidance).canRequestFocus, isTrue);
      expect(
        tester.getSemantics(guidance).flagsCollection.isFocused,
        isNot(Tristate.none),
      );
      expect(
        find.descendant(
          of: guidance,
          matching: find.byType(PokeMapButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: guidance,
          matching: find.byType(PokeMapIconButton),
        ),
        findsNothing,
      );

      Focus.of(tester.element(find.text(reason))).requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(harness.notifier.state, same(before));
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
    },
  );

  testWidgets(
    'v2Only Event is canonical disabled guidance and never fake placement help',
    (tester) async {
      final harness = _PlaceHarness(
        activeLayerId: 'tile',
        project: _v2OnlyProject,
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.place,
          lastPlacementSubtool: WorldMapPlacementSubtool.event,
        ),
      );
      addTearDown(harness.dispose);
      final beforeEditor = harness.notifier.state;
      final beforeSession = harness.sessionState;
      final canonicalReason = narrativeEventLegacyAuthoringBlockReason(
        beforeEditor.project,
        kind: NarrativeEventLegacyAuthoringKind.mapEvent,
      );

      await harness.pump(tester);

      final disabled = find.byKey(
        const ValueKey<String>('world-map-inspector-disabled-guidance'),
      );
      expect(canonicalReason, isNotNull);
      final reason = canonicalReason!;
      expect(disabled, findsOneWidget);
      expect(find.text(reason), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>(
            'world-map-placement-guidance-eventPlacement',
          ),
        ),
        findsNothing,
      );
      expect(find.textContaining('cliquez dans la carte'), findsNothing);
      expect(_mountedPropertyPanelCount(), 0);

      Focus.of(tester.element(find.text(reason))).requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(harness.notifier.state, same(beforeEditor));
      expect(harness.sessionState, same(beforeSession));
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
    },
  );

  testWidgets(
    'ignores viewport and status rebuilds but reacts to active selection',
    (tester) async {
      var rebuilds = 0;
      final harness = _PlaceHarness(
        activeLayerId: 'tile',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.place,
          lastPlacementSubtool: WorldMapPlacementSubtool.entity,
        ),
      );
      addTearDown(harness.dispose);
      await harness.pump(
        tester,
        child: _CountingWorldMapPlaceInspector(
          onBuild: () => rebuilds += 1,
        ),
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'world-map-placement-guidance-entityPlacement',
          ),
        ),
        findsOneWidget,
      );

      rebuilds = 0;
      harness.notifier.state = harness.notifier.state.copyWith(
        zoom: 2,
        panOffset: const Offset(12, 8),
        statusMessage: 'viewport-only',
      );
      await tester.pump();

      expect(rebuilds, 0);
      expect(
        find.byKey(
          const ValueKey<String>(
            'world-map-placement-guidance-entityPlacement',
          ),
        ),
        findsOneWidget,
      );

      harness.notifier.state = harness.notifier.state.copyWith(
        selectedEntityId: 'entity',
      );
      await tester.pump();

      expect(rebuilds, greaterThan(0));
      expect(find.byType(EntityPropertiesPanel), findsOneWidget);
    },
  );
}

int _mountedPropertyPanelCount() {
  return <Type>[
    EntityPropertiesPanel,
    EventPropertiesPanel,
    TriggerPropertiesPanel,
    WarpPropertiesPanel,
    GameplayZonePropertiesPanel,
  ].map((type) => find.byType(type).evaluate().length).reduce((a, b) => a + b);
}

class _PlaceHarness {
  _PlaceHarness({
    required String activeLayerId,
    WorldMapWorkspaceSession initialSession = const WorldMapWorkspaceSession(),
    ProjectManifest? project,
  }) : container = ProviderContainer(
          overrides: <Override>[
            worldMapWorkspaceSessionProvider.overrideWith(
              () => _TestSessionController(initialSession),
            ),
          ],
        ) {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = EditorState(
      projectRootPath: '/virtual/project',
      project: project ?? _project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: activeLayerId,
      activeBrush: const EditorBrush.projectElement(elementId: 'lamp'),
      savedMapSnapshot: _map,
    );
  }

  final ProviderContainer container;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  WorldMapWorkspaceSessionController get session =>
      container.read(worldMapWorkspaceSessionProvider.notifier);

  WorldMapWorkspaceSession get sessionState =>
      container.read(worldMapWorkspaceSessionProvider);

  void select(WorldMapPlacementSubtool subtool, String id) {
    notifier.state = switch (subtool) {
      WorldMapPlacementSubtool.entity =>
        notifier.state.copyWith(selectedEntityId: id),
      WorldMapPlacementSubtool.event =>
        notifier.state.copyWith(selectedMapEventId: id),
      WorldMapPlacementSubtool.trigger =>
        notifier.state.copyWith(selectedTriggerId: id),
      WorldMapPlacementSubtool.warp =>
        notifier.state.copyWith(selectedWarpId: id),
      WorldMapPlacementSubtool.gameplayZone =>
        notifier.state.copyWith(selectedGameplayZoneId: id),
      WorldMapPlacementSubtool.object => notifier.state,
    };
  }

  Future<void> pump(
    WidgetTester tester, {
    Widget child = const WorldMapPlaceInspector(),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        key: ValueKey<Object>(container),
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 440,
              height: 720,
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

class _CountingWorldMapPlaceInspector extends WorldMapPlaceInspector {
  const _CountingWorldMapPlaceInspector({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onBuild();
    return super.build(context, ref);
  }
}

class _TestSessionController extends WorldMapWorkspaceSessionController {
  _TestSessionController(this.initialSession);

  final WorldMapWorkspaceSession initialSession;

  @override
  WorldMapWorkspaceSession build() => initialSession;
}

const _project = ProjectManifest(
  name: 'Place inspector',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
    ),
  ],
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

final _v2OnlyProject = ProjectManifest(
  name: 'Place inspector V2 only',
  maps: const <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const <ProjectTilesetEntry>[],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: const [],
    legacyClaims: const [],
  ),
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Tile',
      cells: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      field: SmartTileField.cell(),
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
      position: EventPosition(layerId: 'tile', x: 1, y: 1),
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
);

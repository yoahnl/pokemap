import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/map_context_command.dart';
import 'package:map_editor/src/features/editor/application/map_context_target.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/application/world_map_target_editor_intent.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/adaptive_map_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/map_context_menu_controller.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/map_placed_element_rotation_preview_controller.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_context_action_dialogs.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layer_mutation_dialogs.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layers_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../../../shell_chrome_test_harness.dart';

const _appkitUiElementColorsChannel = MethodChannel('appkit_ui_element_colors');

void main() {
  group('WorldMapWorkspace', () {
    testWidgets(
        'composes Explorer, tool slot, adaptive inspector, and real MapCanvas',
        (tester) async {
      final toolFocusNode = FocusNode(debugLabel: 'workspace tool slot');
      addTearDown(toolFocusNode.dispose);

      await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
        toolFocusNode: toolFocusNode,
      );

      final workspace =
          find.byKey(const ValueKey<String>('world-map-workspace'));
      expect(workspace, findsOneWidget);
      expect(
        find.descendant(
          of: workspace,
          matching: find.byType(ProjectExplorerPanel),
        ),
        findsOneWidget,
      );
      expect(
        _opacity(tester, 'project-explorer-expanded-state'),
        1,
      );
      expect(
        _opacity(tester, 'project-explorer-reduced-state'),
        0,
      );
      expect(find.byType(MapCanvas), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('world-map-tool-slot'),
          ),
          matching: find.byKey(
            const ValueKey<String>('workspace-test-tool-focus'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('world-map-inspector-slot'),
          ),
          matching: find.byType(AdaptiveMapInspector),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byType(AdaptiveMapInspector),
          matching: find.byType(PokeMapPanel),
        ),
        findsNothing,
        reason: 'AdaptiveMapInspector must own the only inspector panel.',
      );
      expect(
        tester
            .widget<Focus>(
              find.byKey(
                const ValueKey<String>('workspace-test-tool-focus'),
              ),
            )
            .focusNode,
        same(toolFocusNode),
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-close'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-canvas-focus')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('world-map-canvas-region'),
              ),
            )
            .width,
        greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-dock'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-overlay'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('passes the transient rotation preview into MapCanvas',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
        seedRotationPreview: true,
      );

      final preview = container.read(mapPlacedElementRotationPreviewProvider);
      final canvas = tester.widget<MapCanvas>(find.byType(MapCanvas));
      expect(preview, isNotNull);
      expect(canvas.placedElementRotationPreview, same(preview));
      expect(
        container.read(editorNotifierProvider).mapUndoStack,
        isEmpty,
      );
    });

    testWidgets('selects an object before publishing its projected menu',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );
      final editor = container.read(editorNotifierProvider);
      final map = editor.activeMap!.copyWith(
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      container.read(editorNotifierProvider.notifier).state =
          editor.copyWith(activeMap: map, savedMapSnapshot: map);
      await tester.pump();

      final sequence = <String>[];
      final selectionSubscription = container.listen<String?>(
        editorNotifierProvider.select((state) => state.selectedEntityId),
        (_, next) {
          if (next == 'npc') sequence.add('selection');
        },
      );
      final menuSubscription = container.listen<MapContextMenuState>(
        mapContextMenuControllerProvider,
        (_, next) {
          if (next is MapContextMenuOpen) sequence.add('menu');
        },
      );
      addTearDown(selectionSubscription.close);
      addTearDown(menuSubscription.close);

      final canvas = tester.widget<MapCanvas>(find.byType(MapCanvas));
      const cell = GridPos(x: 1, y: 1);
      canvas.onCellSelected!(cell);
      canvas.onContextMenuRequested!(
        const MapCanvasContextMenuRequest(
          globalPosition: Offset(600, 400),
          gridPosition: cell,
          invocation: MapContextMenuInvocation.pointer,
        ),
      );
      await tester.pump();

      expect(sequence, <String>['selection', 'menu']);
      expect(
        container.read(editorNotifierProvider).selectedEntityId,
        'npc',
      );
      expect(
        container.read(mapContextMenuControllerProvider),
        isA<MapContextMenuOpen>().having(
          (open) => open.target,
          'target',
          isA<MapObjectContextTarget>().having(
            (target) => target.target,
            'object',
            isA<MapCanvasObjectTarget>().having(
              (target) => target.id,
              'id',
              'npc',
            ),
          ),
        ),
      );
      expect(find.text('Ouvrir l’entité'), findsOneWidget);
    });

    testWidgets(
        'keyboard keeps the selected object in an overlap while pointer and stale selection stay top-first',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );
      final editor = container.read(editorNotifierProvider);
      const overlap = GridPos(x: 1, y: 1);
      final map = editor.activeMap!.copyWith(
        entities: const <MapEntity>[
          MapEntity(
            id: 'selected-under-warp',
            kind: MapEntityKind.npc,
            pos: overlap,
          ),
        ],
        warps: const <MapWarp>[
          MapWarp(
            id: 'top-warp',
            pos: overlap,
            targetMapId: 'workspace_map',
            targetPos: GridPos(x: 2, y: 2),
          ),
        ],
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = editor.copyWith(
        activeMap: map,
        savedMapSnapshot: map,
        selectedEntityId: 'selected-under-warp',
      );
      await tester.pump();

      final canvas = tester.widget<MapCanvas>(find.byType(MapCanvas));
      void open(MapContextMenuInvocation invocation) {
        canvas.onContextMenuRequested!(
          MapCanvasContextMenuRequest(
            globalPosition: const Offset(600, 400),
            gridPosition: overlap,
            invocation: invocation,
          ),
        );
      }

      String openTargetId() {
        final open = container.read(mapContextMenuControllerProvider)
            as MapContextMenuOpen;
        return (open.target as MapObjectContextTarget).target.id;
      }

      open(MapContextMenuInvocation.keyboard);
      await tester.pump();
      expect(openTargetId(), 'selected-under-warp');

      container.read(mapContextMenuControllerProvider.notifier).close();
      notifier.state = notifier.state.copyWith(
        selectedEntityId: 'selected-under-warp',
        selectedWarpId: null,
      );
      open(MapContextMenuInvocation.pointer);
      await tester.pump();
      expect(openTargetId(), 'top-warp');

      container.read(mapContextMenuControllerProvider.notifier).close();
      notifier.state = notifier.state.copyWith(
        selectedEntityId: 'stale-entity',
        selectedWarpId: null,
      );
      open(MapContextMenuInvocation.keyboard);
      await tester.pump();
      expect(openTargetId(), 'top-warp');
      expect(tester.takeException(), isNull);
    });

    testWidgets('stores a selected cell before opening its menu',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );
      final sequence = <String>[];
      final cellSubscription = container.listen<WorldMapWorkspaceSession>(
        worldMapWorkspaceSessionProvider,
        (_, next) {
          if (next.selectedCell == const GridPos(x: 5, y: 5)) {
            sequence.add('selection');
          }
        },
      );
      final menuSubscription = container.listen<MapContextMenuState>(
        mapContextMenuControllerProvider,
        (_, next) {
          if (next is MapContextMenuOpen) sequence.add('menu');
        },
      );
      addTearDown(cellSubscription.close);
      addTearDown(menuSubscription.close);

      final canvas = tester.widget<MapCanvas>(find.byType(MapCanvas));
      const cell = GridPos(x: 5, y: 5);
      canvas.onCellSelected!(cell);
      canvas.onContextMenuRequested!(
        const MapCanvasContextMenuRequest(
          globalPosition: Offset(600, 400),
          gridPosition: cell,
          invocation: MapContextMenuInvocation.pointer,
        ),
      );
      await tester.pump();

      expect(sequence, <String>['selection', 'menu']);
      expect(
        container.read(worldMapWorkspaceSessionProvider).selectedCell,
        cell,
      );
      expect(
        container.read(mapContextMenuControllerProvider),
        isA<MapContextMenuOpen>().having(
          (open) => open.target,
          'target',
          const MapCellContextTarget(
            position: cell,
            layerId: 'ground',
            isPainted: false,
          ),
        ),
      );
      expect(find.text('Copier les coordonnées'), findsOneWidget);
    });

    testWidgets('routes a layer-row target into the same menu host',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );
      container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .activateLayers(container.read(editorNotifierProvider.notifier));
      await tester.pump();
      final rowFocus = FocusNode(debugLabel: 'workspace layer row test');
      addTearDown(rowFocus.dispose);

      final inspector = tester.widget<WorldMapLayersInspector>(
        find.byType(WorldMapLayersInspector),
      );
      inspector.onContextMenuRequested!(
        WorldMapLayerContextMenuRequest(
          target: const MapLayerContextTarget('ground'),
          globalPosition: const Offset(600, 400),
          invocation: MapContextMenuInvocation.keyboard,
          invokerFocusNode: rowFocus,
        ),
      );
      await tester.pump();

      expect(
        container.read(mapContextMenuControllerProvider),
        isA<MapContextMenuOpen>().having(
          (open) => open.target,
          'target',
          const MapLayerContextTarget('ground'),
        ),
      );
      expect(find.text('Renommer le calque'), findsOneWidget);
      expect(
          find.byType(PokeMapContextMenu<MapContextCommand>), findsOneWidget);
    });

    testWidgets('context erase commits one exact 1x1 transaction',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );
      final editor = container.read(editorNotifierProvider);
      final sourceMap = editor.activeMap!;
      final sourceLayer = sourceMap.layers.single as TileLayer;
      final map = sourceMap.copyWith(
        layers: <MapLayer>[
          sourceLayer.copyWith(
            tiles: List<int>.filled(64, 7, growable: false),
          ),
        ],
      );
      container.read(editorNotifierProvider.notifier).state = editor.copyWith(
        activeMap: map,
        savedMapSnapshot: map,
        mapUndoStack: const [],
        mapRedoStack: const [],
        mapStrokeStart: null,
      );
      await tester.pump();

      _openCanvasMenu(tester, const GridPos(x: 2, y: 3));
      await tester.pump();
      await tester.tap(find.text('Effacer cette case'));
      await tester.pump();

      final result = container.read(editorNotifierProvider);
      final resultLayer = result.activeMap!.layers.single as TileLayer;
      expect(resultLayer.tiles[26], 0);
      expect(
        resultLayer.tiles.where((tile) => tile == 7),
        hasLength(63),
      );
      expect(result.mapStrokeStart, isNull);
      expect(result.mapUndoStack, hasLength(1));
    });

    testWidgets('copy coordinates only writes the clipboard', (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );
      MethodCall? clipboardCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        clipboardCall = call;
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      _openCanvasMenu(tester, const GridPos(x: 5, y: 6));
      await tester.pump();
      final before = container.read(editorNotifierProvider);
      await tester.tap(find.text('Copier les coordonnées'));
      await tester.pump();

      final after = container.read(editorNotifierProvider);
      expect(clipboardCall?.method, 'Clipboard.setData');
      expect(clipboardCall?.arguments, <String, String>{'text': '5, 6'});
      expect(after.activeMap, same(before.activeMap));
      expect(after.mapUndoStack, before.mapUndoStack);
      expect(after.mapRedoStack, before.mapRedoStack);
    });

    testWidgets('move delegates through selection tool activation',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );
      final editorNotifier = container.read(editorNotifierProvider.notifier);
      final editor = container.read(editorNotifierProvider);
      final map = editor.activeMap!.copyWith(
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      editorNotifier.state =
          editor.copyWith(activeMap: map, savedMapSnapshot: map);
      final eraseActivation = container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .activateTool(editorNotifier, const ActivateWorldMapErase());
      expect(eraseActivation.accepted, isTrue);
      await tester.pump();

      _openCanvasMenu(tester, const GridPos(x: 1, y: 1));
      await tester.pump();
      final before = container.read(editorNotifierProvider);
      await tester.tap(find.text('Déplacer'));
      await tester.pump();

      final after = container.read(editorNotifierProvider);
      expect(after.selectedEntityId, 'npc');
      expect(after.activeTool, EditorToolType.selection);
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.selection,
      );
      expect(after.activeMap, same(before.activeMap));
      expect(after.mapUndoStack, before.mapUndoStack);
    });

    testWidgets('object deletion always crosses confirmation and commits once',
        (tester) async {
      var confirmed = false;
      var confirmationCalls = 0;
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
        onDeleteConfirmationRequested: ({
          required context,
          required target,
          required title,
          required message,
        }) async {
          confirmationCalls += 1;
          expect(target.target.id, 'npc');
          expect(title, 'Supprimer l’entité');
          return confirmed;
        },
      );
      final editor = container.read(editorNotifierProvider);
      final sourceLayer = editor.activeMap!.layers.single as TileLayer;
      final map = editor.activeMap!.copyWith(
        layers: <MapLayer>[
          sourceLayer.copyWith(
            tiles: List<int>.filled(64, 0, growable: false),
          ),
        ],
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      container.read(editorNotifierProvider.notifier).state =
          editor.copyWith(activeMap: map, savedMapSnapshot: map);
      await tester.pump();

      _openCanvasMenu(tester, const GridPos(x: 1, y: 1));
      await tester.pump();
      final beforeCancel = container.read(editorNotifierProvider);
      await tester.tap(find.text('Supprimer l’entité'));
      await tester.pump();

      expect(confirmationCalls, 1);
      expect(container.read(editorNotifierProvider).activeMap, same(map));
      expect(
        container.read(editorNotifierProvider).selectedEntityId,
        beforeCancel.selectedEntityId,
      );
      expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);

      confirmed = true;
      _openCanvasMenu(tester, const GridPos(x: 1, y: 1));
      await tester.pump();
      await tester.tap(find.text('Supprimer l’entité'));
      await tester.pump();

      final deleted = container.read(editorNotifierProvider);
      expect(confirmationCalls, 2);
      expect(
        deleted.activeMap!.entities,
        isEmpty,
        reason: deleted.errorMessage ?? deleted.statusMessage,
      );
      expect(deleted.mapUndoStack, hasLength(1));
    });

    testWidgets('rotation delegates to the one notifier transaction',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );
      final state = _rotationEditorState();
      container.read(editorNotifierProvider.notifier).state = state;
      container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .setInspectorVisible(false);
      await tester.pump();

      _openCanvasMenu(tester, const GridPos(x: 1, y: 1));
      await tester.pump();
      await tester.tap(find.text('Rotation 90° horaire'));
      await tester.pump();

      final rotated = container.read(editorNotifierProvider);
      expect(rotated.activeMap!.placedElements.single.quarterTurns, 1);
      expect(rotated.mapUndoStack, hasLength(1));
      expect(rotated.mapStrokeStart, isNull);
    });

    testWidgets('open target delegates the frozen typed intent without history',
        (tester) async {
      final intents = <WorldMapTargetEditorIntent>[];
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
        onTargetEditorRequested: (intent) async => intents.add(intent),
      );
      final editor = container.read(editorNotifierProvider);
      final map = editor.activeMap!.copyWith(
        warps: const <MapWarp>[
          MapWarp(
            id: 'door',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'workspace_map',
            targetPos: GridPos(x: 2, y: 2),
          ),
        ],
      );
      container.read(editorNotifierProvider.notifier).state =
          editor.copyWith(activeMap: map, savedMapSnapshot: map);
      await tester.pump();

      _openCanvasMenu(tester, const GridPos(x: 1, y: 1));
      await tester.pump();
      await tester.tap(find.text('Modifier la destination'));
      await tester.pump();

      expect(intents, hasLength(1));
      expect(
        intents.single,
        isA<FocusWorldMapObjectInspectorIntent>().having(
          (intent) => intent.target.id,
          'target id',
          'door',
        ),
      );
      expect(container.read(editorNotifierProvider).activeMap, same(map));
      expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);
    });

    testWidgets(
        'loads a dual-read model only for the exact MapEvent menu request',
        (tester) async {
      var readModelLoads = 0;
      final intents = <WorldMapTargetEditorIntent>[];
      late NarrativeEventBuilderProjectReadModel readModel;
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
        onTargetEditorRequested: (intent) async => intents.add(intent),
        overrides: <Override>[
          narrativeEventBuilderV2ReadModelLoaderProvider.overrideWithValue(
            (_) async {
              readModelLoads += 1;
              return readModel;
            },
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'Context workspace',
        version: ProjectVersion.v6,
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'workspace_map',
            name: 'Workspace Map',
            relativePath: 'maps/workspace_map.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: const <NarrativeEventRecord>[],
          legacyClaims: const <LegacySourceClaim>[],
        ),
      );
      const map = MapData(
        id: 'workspace_map',
        name: 'Workspace Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 8, height: 8),
        layers: <MapLayer>[
          ObjectLayer(id: 'events', name: 'Events'),
        ],
        events: <MapEventDefinition>[
          MapEventDefinition(
            id: 'map_event',
            pages: <MapEventPage>[
              MapEventPage(pageNumber: 0),
            ],
            position: EventPosition(layerId: 'events', x: 1, y: 1),
          ),
        ],
      );
      readModel = buildNarrativeEventBuilderProjectReadModel(
        project: project,
        maps: const <MapData>[map],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/context_workspace',
        project: project,
        activeMap: map,
        activeLayerId: 'events',
        savedMapSnapshot: map,
      );
      await tester.pump();
      expect(readModelLoads, 0);

      _openCanvasMenu(tester, const GridPos(x: 1, y: 1));
      await tester.pumpAndSettle();

      expect(readModelLoads, 1);
      final compatibility = readModel.events.singleWhere(
        (summary) => summary.compatibilityOrigins.any(
          (origin) =>
              origin.provenance ==
              LegacySourceRef.mapEvent('workspace_map', 'map_event'),
        ),
      );
      expect(
        container.read(mapContextMenuControllerProvider),
        isA<MapContextMenuOpen>().having(
          (open) => open.targetEditorResolution,
          'target editor resolution',
          isA<WorldMapTargetEditorReady>().having(
            (ready) => ready.intent,
            'intent',
            isA<OpenNarrativeCompatibilityEventIntent>().having(
              (intent) => intent.stableKey,
              'stable key',
              compatibility.stableKey,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir dans Event Builder'));
      await tester.pump();
      expect(intents, hasLength(1));
      expect(
        intents.single,
        isA<OpenNarrativeCompatibilityEventIntent>().having(
          (intent) => intent.stableKey,
          'stable key',
          compatibility.stableKey,
        ),
      );
      expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);
    });

    testWidgets(
        'uses the Explorer rail and inspector overlay without shrinking compact canvas',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(800, 600),
      );

      expect(
        _opacity(tester, 'project-explorer-expanded-state'),
        0,
      );
      expect(
        _opacity(tester, 'project-explorer-reduced-state'),
        1,
      );
      expect(
        find.byKey(
          const ValueKey<String>('project-explorer-reopen-toggle'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-overlay'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-dock'),
        ),
        findsNothing,
      );

      final canvasWidth = tester
          .getSize(
            find.byKey(
              const ValueKey<String>('world-map-canvas-region'),
            ),
          )
          .width;
      expect(
        canvasWidth,
        greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorVisible,
        isTrue,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('project-explorer-reopen-toggle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        isA<WorldMapWorkspaceSession>()
            .having((session) => session.explorerExpanded, 'explorer', isTrue)
            .having(
              (session) => session.inspectorVisible,
              'compact inspector',
              isFalse,
            ),
      );
      expect(
        _opacity(tester, 'project-explorer-expanded-state'),
        1,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'closes and reopens the inspector and persists clamped dock resizing in session state',
        (tester) async {
      final toolFocusNode = FocusNode(debugLabel: 'workspace tool slot');
      addTearDown(toolFocusNode.dispose);
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1440, 900),
        toolFocusNode: toolFocusNode,
      );

      final region =
          find.byKey(const ValueKey<String>('right-inspector-region'));
      final handle = find.byKey(
        const ValueKey<String>('right-inspector-resize-handle'),
      );
      expect(tester.getSize(region).width, 360);

      await tester.drag(
        handle,
        const Offset(-52, 0),
        touchSlopX: 0,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(tester.getSize(region).width, 412);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorWidth,
        412,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('workspace-test-inspector-toggle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(region, findsNothing);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorVisible,
        isFalse,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('workspace-test-inspector-toggle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(region).width, 412);
      expect(
        tester
            .widget<Focus>(
              find.byKey(
                const ValueKey<String>('workspace-test-tool-focus'),
              ),
            )
            .focusNode,
        same(toolFocusNode),
      );
      expect(find.byType(AdaptiveMapInspector), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reopens the Explorer beside a docked inspector when both fit',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(1280, 800),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('project-explorer-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        isA<WorldMapWorkspaceSession>()
            .having((session) => session.explorerExpanded, 'explorer', isFalse)
            .having((session) => session.inspectorVisible, 'inspector', isTrue),
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('project-explorer-reopen-toggle'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(worldMapWorkspaceSessionProvider),
        isA<WorldMapWorkspaceSession>()
            .having((session) => session.explorerExpanded, 'explorer', isTrue)
            .having((session) => session.inspectorVisible, 'inspector', isTrue),
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-dock'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('world-map-canvas-region'),
              ),
            )
            .width,
        greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'compact inspector overlay absorbs padding pointers and keeps controls interactive',
        (tester) async {
      final container = await _pumpWorkspace(
        tester,
        surfaceSize: const Size(800, 600),
      );
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;
      mapFocus.unfocus();
      await tester.pump();
      expect(mapFocus.hasFocus, isFalse);

      final inspectorRect = tester.getRect(
        find.byKey(const ValueKey<String>('right-inspector-region')),
      );
      await tester.tapAt(
        Offset(inspectorRect.left + 4, inspectorRect.center.dy),
      );
      await tester.pump();

      expect(
        mapFocus.hasFocus,
        isFalse,
        reason: 'overlay padding must not pass the pointer to MapCanvas',
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-inspector-close'),
        ),
      );
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorVisible,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey<String>('right-inspector-region')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

void _openCanvasMenu(WidgetTester tester, GridPos cell) {
  final canvas = tester.widget<MapCanvas>(find.byType(MapCanvas));
  canvas.onCellSelected!(cell);
  canvas.onContextMenuRequested!(
    MapCanvasContextMenuRequest(
      globalPosition: const Offset(600, 400),
      gridPosition: cell,
      invocation: MapContextMenuInvocation.pointer,
    ),
  );
}

EditorState _rotationEditorState() {
  const project = ProjectManifest(
    name: 'Rotation workspace',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'rotation_map',
        name: 'Rotation Map',
        relativePath: 'maps/rotation.json',
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
        id: 'tree',
        name: 'Tree',
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
  final map = MapData(
    id: 'rotation_map',
    name: 'Rotation Map',
    version: ProjectVersion.v6,
    visualStack: MapVisualStackConfig.canonicalV1,
    size: const GridSize(width: 8, height: 8),
    layers: <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'tiles',
        tiles: List<int>.filled(64, 0, growable: false),
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'tree_1',
        layerId: 'ground',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
  return EditorState(
    project: project,
    activeMap: map,
    activeLayerId: 'ground',
    savedMapSnapshot: map,
  );
}

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester, {
  required Size surfaceSize,
  FocusNode? toolFocusNode,
  bool seedRotationPreview = false,
  WorldMapTargetEditorRequested? onTargetEditorRequested,
  WorldMapContextDeleteConfirmationRequested? onDeleteConfirmationRequested,
  WorldMapLayerRenameRequested? onLayerRenameRequested,
  WorldMapLayerDeleteRequested? onLayerDeleteRequested,
  ValueChanged<String>? onCommandRejected,
  List<Override> overrides = const <Override>[],
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_appkitUiElementColorsChannel, (call) async {
    return switch (call.method) {
      'getColorComponents' => <String, double>{'hueComponent': 0.58},
      'getColor' => 0xFF0A84FF,
      _ => null,
    };
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_appkitUiElementColorsChannel, null);
  });

  final container = ProviderContainer(overrides: overrides);
  final editorSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
  });
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  container.read(editorNotifierProvider.notifier).state = _editorState();
  if (seedRotationPreview) {
    final editor = container.read(editorNotifierProvider);
    container.read(mapPlacedElementRotationPreviewProvider.notifier).preview(
          map: editor.activeMap,
          project: editor.project,
          instanceId: 'missing-preview-target',
          targetQuarterTurns: 1,
        );
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, child) => PokeMapMacosCompatibilityBridge(
          child: child ?? const SizedBox.shrink(),
        ),
        home: Material(
          child: WorldMapWorkspace(
            onTargetEditorRequested: onTargetEditorRequested ?? (_) async {},
            onDeleteConfirmationRequested: onDeleteConfirmationRequested ??
                showWorldMapContextDeleteConfirmation,
            onLayerRenameRequested:
                onLayerRenameRequested ?? showWorldMapLayerRenameDialog,
            onLayerDeleteRequested:
                onLayerDeleteRequested ?? showWorldMapLayerDeleteDialog,
            onCommandRejected: onCommandRejected,
            toolSlot: _TestToolSlot(focusNode: toolFocusNode),
            stageHeaderSlot: const SizedBox(
              key: ValueKey<String>('workspace-test-stage-header'),
              height: 36,
            ),
            explorerBuilder: (context, onCollapse) {
              return ProjectExplorerPanel(onCollapse: onCollapse);
            },
            explorerRailBuilder: (context, onReopen) {
              return PokeMapButton(
                key: const ValueKey<String>(
                  'project-explorer-reopen-toggle',
                ),
                onPressed: onReopen,
                size: PokeMapButtonSize.compact,
                child: const Text('Rouvrir'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

double _opacity(WidgetTester tester, String key) {
  return tester
      .widget<AnimatedOpacity>(find.byKey(ValueKey<String>(key)))
      .opacity;
}

EditorState _editorState() {
  final map = buildShellChromeMap(
    id: 'workspace_map',
    name: 'Workspace Map',
    width: 8,
    height: 8,
    layers: const <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        tiles: <int>[],
      ),
    ],
  );
  return EditorState(
    projectRootPath: '/tmp/world_map_workspace_test',
    project: buildShellChromeProject(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'workspace_map',
          name: 'Workspace Map',
          relativePath: 'maps/workspace_map.json',
        ),
      ],
    ),
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: map,
    activeLayerId: 'ground',
    savedMapSnapshot: map,
  );
}

class _TestToolSlot extends ConsumerWidget {
  const _TestToolSlot({this.focusNode});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectorVisible = ref.watch(
      worldMapWorkspaceSessionProvider.select(
        (session) => session.inspectorVisible,
      ),
    );
    return Focus(
      key: const ValueKey<String>('workspace-test-tool-focus'),
      focusNode: focusNode,
      child: PokeMapButton(
        key: const ValueKey<String>('workspace-test-inspector-toggle'),
        onPressed: () {
          ref
              .read(worldMapWorkspaceSessionProvider.notifier)
              .setInspectorVisible(!inspectorVisible);
        },
        child: Text(inspectorVisible ? 'Fermer' : 'Rouvrir'),
      ),
    );
  }
}

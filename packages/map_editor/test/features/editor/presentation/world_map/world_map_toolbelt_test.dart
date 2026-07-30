import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/terrain_selection_mode.dart';
import 'package:map_editor/src/application/services/narrative_event_legacy_authoring_guard.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspection_intent.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_toolbelt.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('WorldMapToolbelt', () {
    testWidgets('keeps the five tool families visible in the approved order',
        (tester) async {
      _useViewport(tester, const Size(1280, 800));
      final container = _containerWith(_tileState());

      await _pumpToolbelt(tester, container);

      const orderedKeys = <ValueKey<String>>[
        ValueKey<String>('world-map-tool-selection'),
        ValueKey<String>('world-map-tool-paint'),
        ValueKey<String>('world-map-tool-erase'),
        ValueKey<String>('world-map-tool-place'),
        ValueKey<String>('world-map-tool-layers'),
      ];
      final leftEdges = <double>[
        for (final key in orderedKeys) tester.getTopLeft(find.byKey(key)).dx,
      ];

      expect(find.text('Projet'), findsOneWidget);
      expect(find.text('Outils'), findsOneWidget);
      expect(leftEdges, orderedEquals(leftEdges.toList()..sort()));
      for (final key in orderedKeys) {
        expect(find.byKey(key), findsOneWidget);
      }
    });

    testWidgets('keeps Save Undo Redo and Plus one click above the workspace',
        (tester) async {
      _useViewport(tester, const Size(1280, 800));
      final container = _containerWith(
        _tileState().copyWith(canUndoMap: true, canRedoMap: true),
      );
      var saves = 0;
      var undos = 0;
      var redos = 0;

      await _pumpToolbelt(
        tester,
        container,
        onSave: () => saves += 1,
        onUndo: () => undos += 1,
        onRedo: () => redos += 1,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-command-save')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-command-undo')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-command-redo')),
      );
      await tester.pump();

      expect((saves, undos, redos), (1, 1, 1));
      expect(
        find.byKey(const ValueKey<String>('world-map-command-plus')),
        findsOneWidget,
      );
      expect(
        tester.widget<PokeMapIconButton>(
          find.byKey(const ValueKey<String>('world-map-command-undo')),
        ),
        isA<PokeMapIconButton>(),
      );
      expect(
        tester.widget<PokeMapIconButton>(
          find.byKey(const ValueKey<String>('world-map-command-redo')),
        ),
        isA<PokeMapIconButton>(),
      );
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Rétablir'), findsOneWidget);
    });

    testWidgets('global and family tooltips expose exact accessible labels',
        (tester) async {
      final container = _containerWith(
        _tileState().copyWith(canUndoMap: true, canRedoMap: true),
      );
      await _pumpToolbelt(
        tester,
        container,
        onSave: () {},
        onUndo: () {},
        onRedo: () {},
      );

      void expectTooltip(String key, String message) {
        final target = find.byKey(ValueKey<String>(key));
        final widget = tester.widget<Widget>(target);
        if (widget is PokeMapIconButton) {
          expect(widget.tooltip, message, reason: key);
          return;
        }
        final tooltip = find.ancestor(
          of: target,
          matching: find.byType(Tooltip),
        );
        expect(tooltip, findsOneWidget, reason: key);
        expect(tester.widget<Tooltip>(tooltip).message, message, reason: key);
      }

      expectTooltip(
        'world-map-command-save',
        'Enregistrer (Cmd/Ctrl+S)',
      );
      expectTooltip(
        'world-map-command-undo',
        'Annuler (Cmd/Ctrl+Z)',
      );
      expectTooltip(
        'world-map-command-redo',
        'Rétablir (Shift+Cmd/Ctrl+Z ou Cmd/Ctrl+Y)',
      );
      expectTooltip(
        'world-map-command-plus',
        'Plus d’actions',
      );
      expectTooltip(
        'world-map-tool-selection',
        'Sélectionner et manipuler',
      );
      expectTooltip(
        'world-map-tool-erase',
        'Effacer sur le calque actif',
      );
      expectTooltip(
        'world-map-tool-layers',
        'Ouvrir la gestion des calques',
      );
    });

    testWidgets('Plus exposes the exact project and map action inventory',
        (tester) async {
      final container = _containerWith(_tileState());
      final invoked = <String>[];
      final callbacks = <String, VoidCallback>{
        'Projet · Nouveau projet': () => invoked.add('Projet · Nouveau projet'),
        'Projet · Ouvrir un projet': () =>
            invoked.add('Projet · Ouvrir un projet'),
        'Projet · Réglages du projet': () =>
            invoked.add('Projet · Réglages du projet'),
        'Projet · Exporter le jeu': () =>
            invoked.add('Projet · Exporter le jeu'),
        'Carte · Nouvelle map': () => invoked.add('Carte · Nouvelle map'),
        'Carte · Redimensionner': () => invoked.add('Carte · Redimensionner'),
      };

      await _pumpToolbelt(
        tester,
        container,
        onNewProject: callbacks['Projet · Nouveau projet'],
        onOpenProject: callbacks['Projet · Ouvrir un projet'],
        onProjectSettings: callbacks['Projet · Réglages du projet'],
        onExportGame: callbacks['Projet · Exporter le jeu'],
        onNewMap: callbacks['Carte · Nouvelle map'],
        onResizeMap: callbacks['Carte · Redimensionner'],
      );

      Future<void> openPlus() async {
        await tester.tap(
          find.byKey(const ValueKey<String>('world-map-command-plus')),
        );
        await tester.pump();
      }

      await openPlus();
      final menuFinder = find.byWidgetPredicate(
        (widget) => widget is PokeMapContextMenu,
      );
      final menu = tester.widget<PokeMapContextMenu<dynamic>>(menuFinder);
      expect(
        menu.items.map((item) => item.label),
        const <String>[
          'Projet · Nouveau projet',
          'Projet · Ouvrir un projet',
          'Projet · Réglages du projet',
          'Projet · Exporter le jeu',
          'Carte · Nouvelle map',
          'Carte · Redimensionner',
        ],
      );
      expect(menu.dividerAfter, const <int>{3});

      for (final label in callbacks.keys) {
        if (menuFinder.evaluate().isEmpty) {
          await openPlus();
        }
        await tester.tap(find.text(label));
        await tester.pump();
      }

      expect(invoked, callbacks.keys);
    });

    testWidgets('Selection Erase and Layers activate in one click',
        (tester) async {
      final container = _containerWith(
        _tileState().copyWith(activeTool: EditorToolType.entityPlacement),
      );
      await _pumpToolbelt(tester, container);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-selection')),
      );
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.selection,
      );
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.selection,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-erase')),
      );
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.erase,
      );
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.eraser,
      );

      container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .setInspectorVisible(false);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-layers')),
      );
      await tester.pump();
      final session = container.read(worldMapWorkspaceSessionProvider);
      expect(session.activeFamily, WorldMapToolFamily.layers);
      expect(session.inspectorVisible, isTrue);
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.selection,
      );
    });

    testWidgets('selected family semantics and keyboard focus stay available',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final container = _containerWith(_tileState());
      final selectionFocus = FocusNode(debugLabel: 'selection family');
      addTearDown(selectionFocus.dispose);

      await _pumpToolbelt(
        tester,
        container,
        selectionFocusNode: selectionFocus,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.selected == true,
        ),
        findsOneWidget,
      );

      selectionFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selectionFocus.hasFocus, isTrue);
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.selection,
      );
      semantics.dispose();
    });

    testWidgets('Paint main click replays the remembered layer subtool',
        (tester) async {
      final container = _containerWith(_paintState('path'));
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.path),
            )
            .accepted,
        isTrue,
      );
      expect(
        session
            .activateTool(editor, const ActivateWorldMapSelection())
            .accepted,
        isTrue,
      );
      await _pumpToolbelt(tester, container);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-paint')),
      );
      await tester.pump();

      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
        WorldMapPaintSubtool.path,
      );
      expect(
        container.read(editorNotifierProvider).terrainSelectionMode,
        TerrainSelectionMode.path,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Peindre · Chemins' &&
              widget.properties.selected == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Place main click replays the remembered placement subtool',
        (tester) async {
      final container = _containerWith(_tileState());
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPlacement(
                WorldMapPlacementSubtool.event,
              ),
            )
            .accepted,
        isTrue,
      );
      expect(
        session
            .activateTool(editor, const ActivateWorldMapSelection())
            .accepted,
        isTrue,
      );
      await _pumpToolbelt(tester, container);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-place')),
      );
      await tester.pump();

      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.place,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).lastPlacementSubtool,
        WorldMapPlacementSubtool.event,
      );
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.eventPlacement,
      );
    });

    for (final testCase in <({
      WorldMapPaintSubtool subtool,
      String label,
      String layerId,
      EditorToolType? expectedTool,
      TerrainSelectionMode? expectedTerrainMode,
    })>[
      (
        subtool: WorldMapPaintSubtool.tile,
        label: 'Éléments',
        layerId: 'tile',
        expectedTool: EditorToolType.tilePaint,
        expectedTerrainMode: null,
      ),
      (
        subtool: WorldMapPaintSubtool.terrain,
        label: 'Terrain',
        layerId: 'terrain',
        expectedTool: EditorToolType.terrainPaint,
        expectedTerrainMode: TerrainSelectionMode.terrain,
      ),
      (
        subtool: WorldMapPaintSubtool.path,
        label: 'Chemins',
        layerId: 'path',
        expectedTool: EditorToolType.terrainPaint,
        expectedTerrainMode: TerrainSelectionMode.path,
      ),
      (
        subtool: WorldMapPaintSubtool.surface,
        label: 'Surfaces',
        layerId: 'surface',
        expectedTool: EditorToolType.surfacePaint,
        expectedTerrainMode: null,
      ),
      (
        subtool: WorldMapPaintSubtool.border,
        label: 'Bordures',
        layerId: 'terrain',
        expectedTool: null,
        expectedTerrainMode: null,
      ),
      (
        subtool: WorldMapPaintSubtool.collision,
        label: 'Collision',
        layerId: 'collision',
        expectedTool: EditorToolType.collisionPaint,
        expectedTerrainMode: null,
      ),
    ]) {
      testWidgets('Paint menu maps ${testCase.subtool.name} canonically',
          (tester) async {
        final container = _containerWith(_paintState(testCase.layerId));
        String? rejectionReason;
        await _pumpToolbelt(
          tester,
          container,
          onActivationRejected: (reason) => rejectionReason = reason,
        );

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de peinture'),
        );
        await tester.pump();
        await tester.tap(find.text(testCase.label));
        await tester.pump();

        if (testCase.expectedTool case final expectedTool?) {
          expect(rejectionReason, isNull);
          expect(
            container.read(editorNotifierProvider).activeTool,
            expectedTool,
          );
          expect(
            container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
            testCase.subtool,
          );
          if (testCase.expectedTerrainMode case final expectedTerrainMode?) {
            expect(
              container.read(editorNotifierProvider).terrainSelectionMode,
              expectedTerrainMode,
            );
          }
        } else {
          expect(rejectionReason, isNull);
          expect(
            container.read(editorNotifierProvider).activeTool,
            EditorToolType.selection,
          );
          expect(
            container.read(worldMapWorkspaceSessionProvider).activeFamily,
            WorldMapToolFamily.selection,
          );
          expect(
            container.read(worldMapPaintInspectionIntentProvider)?.kind,
            WorldMapPaintInspectionIntentKind.missingLayer,
          );
        }
      });
    }

    testWidgets(
      'Paint routes from a TileLayer to the sole compatible layer atomically',
      (tester) async {
        final container = _containerWith(_paintState('tile'));
        final beforeMap = container.read(editorNotifierProvider).activeMap;
        String? rejectionReason;
        await _pumpToolbelt(
          tester,
          container,
          onActivationRejected: (reason) => rejectionReason = reason,
        );

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de peinture'),
        );
        await tester.pump();
        await tester.tap(find.text('Terrain'));
        await tester.pump();

        final editor = container.read(editorNotifierProvider);
        expect(rejectionReason, isNull);
        expect(editor.activeLayerId, 'terrain');
        expect(editor.activeTool, EditorToolType.terrainPaint);
        expect(editor.activeMap, same(beforeMap));
        expect(editor.mapUndoStack, isEmpty);
        expect(editor.mapRedoStack, isEmpty);
        expect(editor.isDirty, isFalse);
        expect(
          container.read(worldMapWorkspaceSessionProvider).activeFamily,
          WorldMapToolFamily.paint,
        );
        expect(
          container.read(worldMapPaintInspectionIntentProvider),
          isNull,
        );
      },
    );

    testWidgets(
      'Paint opens a mutation-free layer choice when several layers match',
      (tester) async {
        final initial = _paintState('tile').copyWith(
          activeMap: _paintMap.copyWith(
            layers: <MapLayer>[
              ..._paintMap.layers,
              const TerrainLayer(
                id: 'terrain-secondary',
                name: 'Terrain secondaire',
              ),
            ],
          ),
        );
        final container = _containerWith(initial);
        final beforeSession = container.read(worldMapWorkspaceSessionProvider);
        String? rejectionReason;
        await _pumpToolbelt(
          tester,
          container,
          onActivationRejected: (reason) => rejectionReason = reason,
        );

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de peinture'),
        );
        await tester.pump();
        await tester.tap(find.text('Terrain'));
        await tester.pump();

        final intent = container.read(worldMapPaintInspectionIntentProvider);
        expect(rejectionReason, isNull);
        expect(container.read(editorNotifierProvider), same(initial));
        expect(
          container.read(worldMapWorkspaceSessionProvider),
          same(beforeSession),
        );
        expect(intent?.kind, WorldMapPaintInspectionIntentKind.layerChoice);
        expect(
          intent?.compatibleLayerIds,
          const <String>['terrain', 'terrain-secondary'],
        );
      },
    );

    testWidgets(
      'Paint opens French missing-layer guidance without technical rejection',
      (tester) async {
        final initial = _tileState();
        final container = _containerWith(initial);
        final beforeSession = container.read(worldMapWorkspaceSessionProvider);
        String? rejectionReason;
        await _pumpToolbelt(
          tester,
          container,
          onActivationRejected: (reason) => rejectionReason = reason,
        );

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de peinture'),
        );
        await tester.pump();
        await tester.tap(find.text('Collision'));
        await tester.pump();

        final intent = container.read(worldMapPaintInspectionIntentProvider);
        expect(rejectionReason, isNull);
        expect(container.read(editorNotifierProvider), same(initial));
        expect(
          container.read(worldMapWorkspaceSessionProvider),
          same(beforeSession),
        );
        expect(intent?.kind, WorldMapPaintInspectionIntentKind.missingLayer);
        expect(intent?.subtool, WorldMapPaintSubtool.collision);
        expect(
          container.read(editorNotifierProvider).mapUndoStack,
          isEmpty,
        );
        expect(container.read(editorNotifierProvider).isDirty, isFalse);
      },
    );

    testWidgets('Place menu exposes only French placement labels',
        (tester) async {
      final container = _containerWith(_tileState());
      await _pumpToolbelt(tester, container);

      await tester.tap(
        find.bySemanticsLabel('Choisir un outil de placement'),
      );
      await tester.pump();

      for (final label in const <String>[
        'Objet',
        'Entité',
        'Événement',
        'Déclencheur',
        'Téléporteur',
        'Zone de gameplay',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      for (final label in const <String>[
        'Entity',
        'Event',
        'Trigger',
        'Warp',
        'Gameplay zone',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    for (final entry
        in <WorldMapPlacementSubtool, ({String label, EditorToolType tool})>{
      WorldMapPlacementSubtool.object: (
        label: 'Objet',
        tool: EditorToolType.tilePaint,
      ),
      WorldMapPlacementSubtool.entity: (
        label: 'Entité',
        tool: EditorToolType.entityPlacement,
      ),
      WorldMapPlacementSubtool.event: (
        label: 'Événement',
        tool: EditorToolType.eventPlacement,
      ),
      WorldMapPlacementSubtool.trigger: (
        label: 'Déclencheur',
        tool: EditorToolType.triggerPlacement,
      ),
      WorldMapPlacementSubtool.warp: (
        label: 'Téléporteur',
        tool: EditorToolType.warpPlacement,
      ),
      WorldMapPlacementSubtool.gameplayZone: (
        label: 'Zone de gameplay',
        tool: EditorToolType.gameplayZonePlacement,
      ),
    }.entries) {
      testWidgets('Place menu maps ${entry.key.name} canonically',
          (tester) async {
        final container = _containerWith(_tileState());
        await _pumpToolbelt(tester, container);

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de placement'),
        );
        await tester.pump();
        await tester.tap(find.text(entry.value.label));
        await tester.pump();

        expect(
          container.read(editorNotifierProvider).activeTool,
          entry.value.tool,
        );
        expect(
          container.read(worldMapWorkspaceSessionProvider).lastPlacementSubtool,
          entry.key,
        );
      });
    }

    testWidgets(
      'v2Only Event click rejects canonically without arming fake guidance',
      (tester) async {
        final container = _containerWith(_v2OnlyTileState());
        final beforeEditor = container.read(editorNotifierProvider);
        final beforeSession = container.read(worldMapWorkspaceSessionProvider);
        final canonicalReason = narrativeEventLegacyAuthoringBlockReason(
          beforeEditor.project,
          kind: NarrativeEventLegacyAuthoringKind.mapEvent,
        );
        String? rejectionReason;
        await _pumpToolbelt(
          tester,
          container,
          onActivationRejected: (reason) => rejectionReason = reason,
        );

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de placement'),
        );
        await tester.pump();
        await tester.tap(find.text('Événement'));
        await tester.pump();

        expect(canonicalReason, isNotNull);
        expect(rejectionReason, canonicalReason);
        expect(container.read(editorNotifierProvider), same(beforeEditor));
        expect(
          container.read(worldMapWorkspaceSessionProvider),
          same(beforeSession),
        );
        expect(
          container.read(worldMapWorkspaceSessionProvider).activeFamily,
          isNot(WorldMapToolFamily.place),
        );
        expect(
          container.read(editorNotifierProvider).activeTool,
          isNot(EditorToolType.eventPlacement),
        );
      },
    );

    testWidgets('split choice routes to the sole compatible TileLayer',
        (tester) async {
      final container = _containerWith(_paintState('terrain'));
      String? rejectionReason;
      await _pumpToolbelt(
        tester,
        container,
        onActivationRejected: (reason) => rejectionReason = reason,
      );

      await tester.tap(
        find.bySemanticsLabel('Choisir un outil de peinture'),
      );
      await tester.pump();
      await tester.tap(find.text('Éléments'));
      await tester.pump();

      expect(rejectionReason, isNull);
      expect(container.read(editorNotifierProvider).activeLayerId, 'tile');
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.tilePaint,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);
      expect(container.read(editorNotifierProvider).isDirty, isFalse);
    });

    testWidgets(
      'Surface setup opens UI intent without technical rejection',
      (tester) async {
        final container = _containerWith(
          _paintState('surface').copyWith(
            selectedSurfacePresetId: 'stale-surface',
          ),
        );
        final beforeEditor = container.read(editorNotifierProvider);
        final beforeSession = container.read(worldMapWorkspaceSessionProvider);
        String? rejectionReason;
        await _pumpToolbelt(
          tester,
          container,
          onActivationRejected: (reason) => rejectionReason = reason,
        );

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de peinture'),
        );
        await tester.pump();
        await tester.tap(find.text('Surfaces'));
        await tester.pump();

        expect(rejectionReason, isNull);
        expect(container.read(editorNotifierProvider), same(beforeEditor));
        expect(
          container.read(worldMapWorkspaceSessionProvider),
          same(beforeSession),
        );
        expect(
          container.read(worldMapPaintInspectionIntentProvider),
          const WorldMapPaintInspectionIntent(
            scope: (
              projectRootPath: null,
              activeMapPath: null,
              activeMapId: 'map-a',
            ),
            layerId: 'surface',
            subtool: WorldMapPaintSubtool.surface,
          ),
        );
        expect(beforeEditor.mapUndoStack, isEmpty);
        expect(beforeEditor.mapRedoStack, isEmpty);
      },
    );

    testWidgets(
      'empty Border setup opens UI intent without technical rejection',
      (tester) async {
        final container = _containerWith(_emptyBorderState());
        final beforeEditor = container.read(editorNotifierProvider);
        final beforeSession = container.read(worldMapWorkspaceSessionProvider);
        String? rejectionReason;
        await _pumpToolbelt(
          tester,
          container,
          onActivationRejected: (reason) => rejectionReason = reason,
        );

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de peinture'),
        );
        await tester.pump();
        await tester.tap(find.text('Bordures'));
        await tester.pump();

        expect(rejectionReason, isNull);
        expect(container.read(editorNotifierProvider), same(beforeEditor));
        expect(
          container.read(worldMapWorkspaceSessionProvider),
          same(beforeSession),
        );
        expect(
          container.read(worldMapPaintInspectionIntentProvider),
          const WorldMapPaintInspectionIntent(
            scope: (
              projectRootPath: null,
              activeMapPath: null,
              activeMapId: 'border-map',
            ),
            layerId: 'border',
            subtool: WorldMapPaintSubtool.border,
          ),
        );
      },
    );

    testWidgets(
      'wrong-layer Surface choice routes to the sole SurfaceLayer',
      (tester) async {
        final container = _containerWith(_paintState('terrain'));
        await _pumpToolbelt(tester, container);

        await tester.tap(
          find.bySemanticsLabel('Choisir un outil de peinture'),
        );
        await tester.pump();
        await tester.tap(find.text('Surfaces'));
        await tester.pump();

        expect(container.read(editorNotifierProvider).activeLayerId, 'surface');
        expect(
          container.read(editorNotifierProvider).activeTool,
          EditorToolType.surfacePaint,
        );
        expect(
          container.read(worldMapWorkspaceSessionProvider).activeFamily,
          WorldMapToolFamily.paint,
        );
        expect(
          container.read(worldMapPaintInspectionIntentProvider),
          isNull,
        );
      },
    );

    testWidgets('accepted activation clears an existing setup intent',
        (tester) async {
      final container = _containerWith(_paintState('surface'));
      container.read(worldMapPaintInspectionIntentProvider.notifier).showSetup(
            mapId: 'map-a',
            layerId: 'surface',
            subtool: WorldMapPaintSubtool.surface,
          );
      await _pumpToolbelt(tester, container);

      await tester.tap(
        find.bySemanticsLabel('Choisir un outil de peinture'),
      );
      await tester.pump();
      await tester.tap(find.text('Surfaces'));
      await tester.pump();

      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.surfacePaint,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        container.read(worldMapPaintInspectionIntentProvider),
        isNull,
      );
    });

    testWidgets('Plus escapes the toolbar bounds and restores launcher focus',
        (tester) async {
      final container = _containerWith(_tileState());
      var opened = 0;
      await _pumpToolbelt(
        tester,
        container,
        onNewProject: () => opened += 1,
      );
      final plusFinder =
          find.byKey(const ValueKey<String>('world-map-command-plus'));
      final plus = tester.widget<PokeMapButton>(plusFinder);

      await tester.tap(plusFinder);
      await tester.pump();

      final menuFinder = find.byWidgetPredicate(
        (widget) => widget is PokeMapContextMenu,
      );
      final toolbarBottom =
          tester.getRect(find.byType(PokeMapToolbarSurface)).bottom;
      final menuBottom = tester.getRect(menuFinder).bottom;
      expect(menuBottom, greaterThan(toolbarBottom));

      await tester.tap(find.text('Projet · Nouveau projet'));
      await tester.pump();

      expect(opened, 1);
      expect(menuFinder, findsNothing);
      expect(plus.focusNode?.hasFocus, isTrue);
    });

    testWidgets('valid Border paint menu activation reaches borderPaint',
        (tester) async {
      final container = _containerWith(_validBorderState());
      container
          .read(activeBorderFeatureControllerProvider.notifier)
          .selectFeature(
            map: _validBorderMap,
            layerId: 'border',
            featureId: 'coast',
          );
      String? rejectionReason;
      await _pumpToolbelt(
        tester,
        container,
        onActivationRejected: (reason) => rejectionReason = reason,
      );

      await tester.tap(
        find.bySemanticsLabel('Choisir un outil de peinture'),
      );
      await tester.pump();
      await tester.tap(find.text('Bordures'));
      await tester.pump();

      expect(rejectionReason, isNull);
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.borderPaint,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
        WorldMapPaintSubtool.border,
      );
    });

    testWidgets('Plus reconciles enabled to disabled callbacks while open',
        (tester) async {
      final container = _containerWith(_tileState());
      var settingsCalls = 0;
      String? rejectionReason;
      await _pumpToolbelt(
        tester,
        container,
        onProjectSettings: () => settingsCalls += 1,
        onActivationRejected: (reason) => rejectionReason = reason,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-command-plus')),
      );
      await tester.pump();
      final menuFinder = find.byWidgetPredicate(
        (widget) => widget is PokeMapContextMenu,
      );
      final dynamic staleMenu = tester.widget<Widget>(menuFinder);
      final staleSettingsAction = staleMenu.items[2].value;
      expect(staleMenu.items[2].enabled, isTrue);

      await _pumpToolbelt(
        tester,
        container,
        onProjectSettings: null,
        onActivationRejected: (reason) => rejectionReason = reason,
      );
      await tester.pump();

      final reconciled = tester.widget<PokeMapContextMenu<dynamic>>(menuFinder);
      expect(reconciled.items[2].enabled, isFalse);
      expect(reconciled.items[2].disabledReason, 'Ouvrez un projet.');

      staleMenu.onSelected(staleSettingsAction);
      await tester.pump();

      expect(settingsCalls, 0);
      expect(rejectionReason, 'Ouvrez un projet.');
    });

    testWidgets('Plus reconciles disabled to enabled callbacks while open',
        (tester) async {
      final container = _containerWith(_tileState());
      var settingsCalls = 0;
      await _pumpToolbelt(tester, container);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-command-plus')),
      );
      await tester.pump();
      final menuFinder = find.byWidgetPredicate(
        (widget) => widget is PokeMapContextMenu,
      );
      expect(
        tester.widget<PokeMapContextMenu<dynamic>>(menuFinder).items[2].enabled,
        isFalse,
      );

      await _pumpToolbelt(
        tester,
        container,
        onProjectSettings: () => settingsCalls += 1,
      );
      await tester.pump();

      expect(
        tester.widget<PokeMapContextMenu<dynamic>>(menuFinder).items[2].enabled,
        isTrue,
      );
      await tester.tap(find.text('Projet · Réglages du projet'));
      await tester.pump();
      expect(settingsCalls, 1);
    });

    testWidgets(
        'Paint main does not replay same-id layer memory after map change',
        (tester) async {
      final container = _containerWith(_sameIdPathState());
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.path),
            )
            .accepted,
        isTrue,
      );
      String? rejectionReason;
      await _pumpToolbelt(
        tester,
        container,
        onActivationRejected: (reason) => rejectionReason = reason,
      );

      editor.state = _sameIdTileState();
      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-paint')),
      );
      await tester.pump();

      expect(rejectionReason, isNull);
      expect(editor.state.activeTool, EditorToolType.tilePaint);
      expect(
        container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
        WorldMapPaintSubtool.tile,
      );
    });

    testWidgets(
        'Paint main reconciles a rejected stale replay with its resolved subtool',
        (tester) async {
      final project = _validBorderProject.copyWith(
        surfaceCatalog: _paintProject.surfaceCatalog,
      );
      final map = _validBorderMap.copyWith(
        id: 'map-a',
        layers: <MapLayer>[
          const SurfaceLayer(id: 'surface', name: 'Surface'),
          ..._validBorderMap.layers,
        ],
      );
      final container = _containerWith(
        EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'border',
          selectedSurfacePresetId: 'water',
        ),
      );
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.border),
            )
            .accepted,
        isTrue,
      );
      editor.state = editor.state.copyWith(
        activeLayerId: 'surface',
        activeTool: EditorToolType.selection,
      );
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.surface),
            )
            .accepted,
        isTrue,
      );
      String? rejectionReason;
      await _pumpToolbelt(
        tester,
        container,
        onActivationRejected: (reason) => rejectionReason = reason,
      );

      editor.state = editor.state.copyWith(
        activeMap: map.copyWith(
          layers: const <MapLayer>[
            SurfaceLayer(id: 'surface', name: 'Surface'),
            BorderLayer(id: 'border', name: 'Border'),
          ],
        ),
        activeLayerId: 'border',
        activeTool: EditorToolType.selection,
      );
      final beforeEditor = editor.state;
      final beforeSession = container.read(worldMapWorkspaceSessionProvider);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-paint')),
      );
      await tester.pump();

      expect(rejectionReason, isNull);
      expect(editor.state, same(beforeEditor));
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        same(beforeSession),
      );
      expect(
        container.read(worldMapPaintInspectionIntentProvider),
        const WorldMapPaintInspectionIntent(
          scope: (
            projectRootPath: null,
            activeMapPath: null,
            activeMapId: 'map-a',
          ),
          layerId: 'border',
          subtool: WorldMapPaintSubtool.border,
        ),
      );
    });

    testWidgets(
        'legacy editor tool mutations update visible family and subtool',
        (tester) async {
      final container = _containerWith(_paintState('path'));
      String? rejectionReason;
      await _pumpToolbelt(
        tester,
        container,
        onActivationRejected: (reason) => rejectionReason = reason,
      );

      final editor = container.read(editorNotifierProvider.notifier);
      editor.state = editor.state.copyWith(
        activeTool: EditorToolType.eraser,
      );
      await tester.pump();

      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey<String>('world-map-tool-erase'),
              ),
            )
            .isSelected,
        isTrue,
      );

      editor.state = editor.state.copyWith(
        activeTool: EditorToolType.terrainPaint,
        terrainSelectionMode: TerrainSelectionMode.path,
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Peindre · Chemins' &&
              widget.properties.selected == true,
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-paint')),
      );
      await tester.pump();

      expect(rejectionReason, isNull);
      expect(editor.state.activeTool, EditorToolType.terrainPaint);
      expect(
        editor.state.terrainSelectionMode,
        TerrainSelectionMode.path,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
        WorldMapPaintSubtool.path,
      );
    });

    testWidgets('visual resolver preserves Layers engine ambiguity',
        (tester) async {
      final container = _containerWith(_tileState());
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(session.activateLayers(editor).accepted, isTrue);

      await _pumpToolbelt(tester, container);

      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey<String>('world-map-tool-layers'),
              ),
            )
            .isSelected,
        isTrue,
      );
      expect(editor.state.activeTool, EditorToolType.selection);
    });

    testWidgets('visual resolver preserves Place object engine ambiguity',
        (tester) async {
      final container = _containerWith(_tileState());
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPlacement(
                WorldMapPlacementSubtool.object,
              ),
            )
            .accepted,
        isTrue,
      );

      await _pumpToolbelt(tester, container);

      expect(editor.state.activeTool, EditorToolType.tilePaint);
      expect(editor.state.activeBrush, isA<NoEditorBrush>());
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Placer · Objet' &&
              widget.properties.selected == true,
        ),
        findsOneWidget,
      );
    });

    for (final testCase in <({String label, EditorBrush brush})>[
      (
        label: 'tile',
        brush: const EditorBrush.tile(tileId: 1, tilesetId: 'world'),
      ),
      (
        label: 'palette-entry',
        brush: const EditorBrush.paletteEntry(
          entryId: 'tree',
          tilesetId: 'world',
        ),
      ),
    ]) {
      testWidgets(
          'legacy ${testCase.label} brush makes tilePaint visibly Paint/tile '
          'without mutating the Place/object session', (tester) async {
        final container = _containerWith(_tileState());
        final editor = container.read(editorNotifierProvider.notifier);
        final session =
            container.read(worldMapWorkspaceSessionProvider.notifier);
        expect(
          session
              .activateTool(
                editor,
                const ActivateWorldMapPlacement(
                  WorldMapPlacementSubtool.object,
                ),
              )
              .accepted,
          isTrue,
        );
        editor.state = editor.state.copyWith(
          activeTool: EditorToolType.tilePaint,
          activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
        );
        await _pumpToolbelt(tester, container);
        final sessionBefore = container.read(worldMapWorkspaceSessionProvider);
        final sessionEmissions = <WorldMapWorkspaceSession>[];
        final subscription = container.listen<WorldMapWorkspaceSession>(
          worldMapWorkspaceSessionProvider,
          (_, next) => sessionEmissions.add(next),
        );

        editor.state = editor.state.copyWith(
          activeTool: EditorToolType.tilePaint,
          activeBrush: testCase.brush,
        );
        await tester.pump();

        subscription.close();
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Peindre · Éléments' &&
                widget.properties.selected == true,
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Placer · Objet' &&
                widget.properties.selected == true,
          ),
          findsNothing,
        );
        expect(
          container.read(worldMapWorkspaceSessionProvider),
          sessionBefore,
        );
        expect(sessionEmissions, isEmpty);
      });
    }

    testWidgets(
        'project-element brush keeps tilePaint visibly Paint/elements '
        'when the session is Paint', (tester) async {
      final container = _containerWith(_tileState());
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
            )
            .accepted,
        isTrue,
      );
      await _pumpToolbelt(tester, container);
      final sessionBefore = container.read(worldMapWorkspaceSessionProvider);
      final sessionEmissions = <WorldMapWorkspaceSession>[];
      final subscription = container.listen<WorldMapWorkspaceSession>(
        worldMapWorkspaceSessionProvider,
        (_, next) => sessionEmissions.add(next),
      );

      editor.state = editor.state.copyWith(
        activeTool: EditorToolType.tilePaint,
        activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
      );
      await tester.pump();

      subscription.close();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Peindre · Éléments' &&
              widget.properties.selected == true,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Placer · Objet' &&
              widget.properties.selected == true,
        ),
        findsNothing,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        sessionBefore,
      );
      expect(sessionEmissions, isEmpty);
    });

    testWidgets('keeps every command visible at 800 and 1280 pixels',
        (tester) async {
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      final container = _containerWith(
        _tileState().copyWith(canUndoMap: true, canRedoMap: true),
      );
      const keys = <ValueKey<String>>[
        ValueKey<String>('world-map-command-save'),
        ValueKey<String>('world-map-command-undo'),
        ValueKey<String>('world-map-command-redo'),
        ValueKey<String>('world-map-command-plus'),
        ValueKey<String>('world-map-tool-selection'),
        ValueKey<String>('world-map-tool-paint'),
        ValueKey<String>('world-map-tool-erase'),
        ValueKey<String>('world-map-tool-place'),
        ValueKey<String>('world-map-tool-layers'),
      ];

      for (final width in <double>[800, 1280]) {
        tester.view.physicalSize = Size(width, 600);
        await _pumpToolbelt(
          tester,
          container,
          onSave: () {},
          onUndo: () {},
          onRedo: () {},
        );

        for (final key in keys) {
          expect(find.byKey(key), findsOneWidget, reason: '$width / $key');
        }
        expect(tester.takeException(), isNull, reason: '$width px');
      }
    });
  });
}

void _useViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

ProviderContainer _containerWith(EditorState state) {
  final container = ProviderContainer();
  final keepAlive = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    keepAlive.close();
    container.dispose();
  });
  container.read(editorNotifierProvider.notifier).state = state;
  return container;
}

Future<void> _pumpToolbelt(
  WidgetTester tester,
  ProviderContainer container, {
  VoidCallback? onSave,
  VoidCallback? onUndo,
  VoidCallback? onRedo,
  VoidCallback? onNewProject,
  VoidCallback? onOpenProject,
  VoidCallback? onProjectSettings,
  VoidCallback? onExportGame,
  VoidCallback? onNewMap,
  VoidCallback? onResizeMap,
  ValueChanged<String>? onActivationRejected,
  FocusNode? selectionFocusNode,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Column(
            children: [
              WorldMapToolbelt(
                onSave: onSave,
                onUndo: onUndo,
                onRedo: onRedo,
                onNewProject: onNewProject,
                onOpenProject: onOpenProject,
                onProjectSettings: onProjectSettings,
                onExportGame: onExportGame,
                onNewMap: onNewMap,
                onResizeMap: onResizeMap,
                onActivationRejected: onActivationRejected,
                selectionFocusNode: selectionFocusNode,
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    ),
  );
}

EditorState _tileState() {
  return const EditorState(
    project: ProjectManifest(
      name: 'World map toolbelt',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    ),
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: MapData(
      id: 'map-a',
      name: 'Map A',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        TileLayer(
          id: 'tile',
          name: 'Tile',
          tilesetId: 'world',
          tiles: <int>[],
        ),
      ],
    ),
    activeLayerId: 'tile',
  );
}

EditorState _v2OnlyTileState() {
  return _tileState().copyWith(
    project: ProjectManifest(
      name: 'World map toolbelt V2 only',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: const [],
        legacyClaims: const [],
      ),
    ),
  );
}

EditorState _paintState(String activeLayerId) {
  return EditorState(
    project: _paintProject,
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: _paintMap,
    activeLayerId: activeLayerId,
    selectedSurfacePresetId: 'water',
  );
}

final _paintProject = ProjectManifest(
  name: 'World map paint tools',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog(
    presets: <ProjectSurfacePreset>[
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: <SurfaceVariantAnimationRef>[
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-isolated',
            ),
          ],
        ),
      ),
    ],
  ),
);

const _paintMap = MapData(
  id: 'map-a',
  name: 'Map A',
  version: ProjectVersion.v2,
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Tile',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    TerrainLayer(id: 'terrain', name: 'Terrain'),
    PathLayer(id: 'path', name: 'Path'),
    SurfaceLayer(id: 'surface', name: 'Surface'),
    CollisionLayer(id: 'collision', name: 'Collision'),
  ],
);

EditorState _sameIdPathState() {
  return const EditorState(
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: MapData(
      id: 'map-a',
      name: 'Map A',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        PathLayer(id: 'shared-layer', name: 'Shared path'),
      ],
    ),
    activeLayerId: 'shared-layer',
  );
}

EditorState _sameIdTileState() {
  return const EditorState(
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: MapData(
      id: 'map-b',
      name: 'Map B',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        TileLayer(
          id: 'shared-layer',
          name: 'Shared tile',
          tilesetId: 'world',
          tiles: <int>[],
        ),
      ],
    ),
    activeLayerId: 'shared-layer',
  );
}

EditorState _validBorderState() {
  return EditorState(
    project: _validBorderProject,
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: _validBorderMap,
    activeLayerId: 'border',
  );
}

EditorState _emptyBorderState() {
  return EditorState(
    project: _validBorderProject,
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: _validBorderMap.copyWith(
      layers: const <MapLayer>[
        BorderLayer(id: 'border', name: 'Border'),
      ],
    ),
    activeLayerId: 'border',
  );
}

final _validBorderProject = ProjectManifest(
  name: 'Valid border tool',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  borderCatalog: ProjectBorderCatalog(
    records: <BorderBlueprintRecord>[
      BorderBlueprintRecord(
        id: 'coast-blueprint',
        draft: BorderBlueprintDraft(
          baseRevision: 1,
          definition: BorderBlueprintDraftDefinition(
            name: 'Coast',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: const <BorderPrimitiveDraft>[],
            defaults: _validBorderParams,
            sortOrder: 0,
          ),
        ),
        latestPublished: BorderBlueprintRevision(
          revision: 1,
          definition: BorderBlueprintPublishedDefinition(
            name: 'Coast',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: const <BorderPublishedPrimitive>[],
            defaults: _validBorderParams,
            sortOrder: 0,
          ),
        ),
      ),
    ],
  ),
);

final _validBorderParams = BorderGenerationParams(
  irregularityPermille: 0,
  detailDensityPermille: 0,
  variationPermille: 0,
  maxOverlapPx: 0,
  gapTolerancePx: 0,
  depthRows: 1,
);

final _validBorderMap = MapData(
  id: 'border-map',
  name: 'Border Map',
  version: ProjectVersion.v2,
  size: const GridSize(width: 4, height: 4),
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
              width: 4,
              height: 4,
              cells: const <bool>[
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
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

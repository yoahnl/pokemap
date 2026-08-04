import 'dart:ui' show PointerDeviceKind, SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_target_editor_intent.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_toolbelt.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'tab order is global commands then tools canvas inspector and Explorer',
    (tester) async {
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
      );
      addTearDown(() => harness.dispose(tester));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      final order = <String>[];
      for (var index = 0; index < 60; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus;
        if (focus == null) continue;
        final target = _focusTarget(focus);
        if (target != null && (order.isEmpty || order.last != target)) {
          order.add(target);
        }
        if (target == 'region:explorer') break;
      }

      expect(
        order,
        const <String>[
          'global:world-map-command-save',
          'global:world-map-command-undo',
          'global:world-map-command-redo',
          'global:world-map-command-plus',
          'tool:world-map-tool-selection',
          'tool:world-map-tool-paint',
          'tool:world-map-tool-erase',
          'tool:world-map-tool-place',
          'tool:world-map-tool-layers',
          'region:canvas',
          'region:inspector',
          'region:explorer',
        ],
      );
    },
  );

  testWidgets(
    'Enter and Space activate a workspace button asset card and menu item',
    (tester) async {
      var saves = 0;
      var newProjects = 0;
      var cardActivations = 0;
      final cardFocus = FocusNode(debugLabel: 'workspace asset card');
      addTearDown(cardFocus.dispose);
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        onSave: () => saves += 1,
        onNewProject: () => newProjects += 1,
        stageHeaderSlot: PokeMapAssetCard(
          focusNode: cardFocus,
          thumbnail: const Icon(Icons.park_outlined),
          label: 'Asset accessible',
          onPressed: () => cardActivations += 1,
        ),
      );
      addTearDown(() => harness.dispose(tester));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(saves, 1);

      for (var index = 0; index < 3; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.pump();
      expect(_contextMenu(), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(newProjects, 1);

      cardFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(cardActivations, 1);
    },
  );

  testWidgets(
    'Escape closes a split menu and restores its menu-segment invoker',
    (tester) async {
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
      );
      addTearDown(() => harness.dispose(tester));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      for (var index = 0; index < 6; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      final invoker = FocusManager.instance.primaryFocus;
      expect(invoker?.debugLabel, 'split button menu');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump();
      expect(_contextMenu(), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(_contextMenu(), findsNothing);
      expect(invoker?.hasFocus, isTrue);
    },
  );

  testWidgets(
    'Escape exits project-element placement while a workspace control has focus',
    (tester) async {
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        state: _state.copyWith(
          activeTool: EditorToolType.tilePaint,
          activeBrush: const EditorBrush.projectElement(elementId: 'fridge'),
        ),
      );
      addTearDown(() => harness.dispose(tester));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        _focusTarget(FocusManager.instance.primaryFocus!),
        'global:world-map-command-save',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      final cancelled = harness.container.read(editorNotifierProvider);
      expect(cancelled.activeTool, EditorToolType.tilePaint);
      expect(cancelled.activeBrush, const EditorBrush.none());
      expect(cancelled.activeLayerId, 'ground');
      expect(cancelled.activeMap, _map);
      expect(cancelled.isDirty, isFalse);
    },
  );

  testWidgets(
    'compact inspector closed from its button restores the Layers invoker',
    (tester) async {
      final selectionFocus = FocusNode(debugLabel: 'fallback selection');
      final inspectorFocus = FocusNode(debugLabel: 'inspector overlay');
      addTearDown(selectionFocus.dispose);
      addTearDown(inspectorFocus.dispose);
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(800, 600),
        selectionFocusNode: selectionFocus,
        inspectorFocusNode: inspectorFocus,
      );
      addTearDown(() => harness.dispose(tester));

      harness.container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .setInspectorVisible(false);
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      for (var index = 0; index < 12; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus;
        if (focus != null &&
            _focusTarget(focus) == 'tool:world-map-tool-layers') {
          break;
        }
      }
      final layersInvoker = FocusManager.instance.primaryFocus;
      expect(_focusTarget(layersInvoker!), 'tool:world-map-tool-layers');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        harness.container
            .read(worldMapWorkspaceSessionProvider)
            .inspectorVisible,
        isTrue,
      );
      inspectorFocus.requestFocus();
      await tester.pump();
      expect(inspectorFocus.hasFocus, isTrue);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-inspector-close'),
        ),
      );
      await tester.pump();

      expect(
        harness.container
            .read(worldMapWorkspaceSessionProvider)
            .inspectorVisible,
        isFalse,
      );
      expect(layersInvoker.hasFocus, isTrue);
      expect(selectionFocus.hasFocus, isFalse);
    },
  );

  testWidgets(
    'compact inspector opened by a context action restores the canvas invoker',
    (tester) async {
      final selectionFocus = FocusNode(debugLabel: 'fallback selection');
      final inspectorFocus = FocusNode(debugLabel: 'inspector overlay');
      addTearDown(selectionFocus.dispose);
      addTearDown(inspectorFocus.dispose);
      late _WorkspaceHarness harness;
      harness = await _pumpWorkspace(
        tester,
        size: const Size(800, 600),
        state: _blockedRotationState,
        selectionFocusNode: selectionFocus,
        inspectorFocusNode: inspectorFocus,
        onTargetEditorRequested: (_) async {
          harness.container
              .read(worldMapWorkspaceSessionProvider.notifier)
              .setInspectorVisible(true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            inspectorFocus.requestFocus();
          });
        },
      );
      addTearDown(() => harness.dispose(tester));
      harness.container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .setInspectorVisible(false);
      await tester.pump();
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;
      mapFocus.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      await tester.tap(find.text('Propriétés'));
      await tester.pump();
      await tester.pump();
      expect(inspectorFocus.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(
        harness.container
            .read(worldMapWorkspaceSessionProvider)
            .inspectorVisible,
        isFalse,
      );
      expect(mapFocus.hasFocus, isTrue);
      expect(selectionFocus.hasFocus, isFalse);
    },
  );

  testWidgets(
    'Menu and Shift F10 open contextual actions and Escape restores canvas',
    (tester) async {
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
      );
      addTearDown(() => harness.dispose(tester));
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;

      mapFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(_contextMenu(), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(_contextMenu(), findsNothing);
      expect(mapFocus.hasFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(_contextMenu(), findsOneWidget);
    },
  );

  testWidgets(
    'canvas arrows announce a cell cursor and Enter or Space applies the tool',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        state: _collisionKeyboardState,
      );
      addTearDown(() => harness.dispose(tester));
      harness.container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .selectCell(
            mapId: _map.id,
            cell: const GridPos(x: 1, y: 1),
          );
      await tester.pump();
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;
      mapFocus.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(
        harness.container.read(worldMapWorkspaceSessionProvider).selectedCell,
        const GridPos(x: 2, y: 2),
      );
      expect(
        find.semantics.byLabel(
          RegExp(r'Curseur cellule x 2, y 2'),
        ),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      var collision = harness.notifier.state.activeMap!.layers
          .whereType<CollisionLayer>()
          .single;
      expect(collision.collisions[2 + (2 * 8)], isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      collision = harness.notifier.state.activeMap!.layers
          .whereType<CollisionLayer>()
          .single;
      expect(collision.collisions[3 + (2 * 8)], isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'pointer selection resynchronizes the next keyboard arrow origin',
    (tester) async {
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
      );
      addTearDown(() => harness.dispose(tester));
      harness.container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .selectCell(
            mapId: _map.id,
            cell: const GridPos(x: 1, y: 1),
          );
      await tester.pump();
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;
      mapFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        harness.container.read(worldMapWorkspaceSessionProvider).selectedCell,
        const GridPos(x: 2, y: 1),
      );

      final canvas = find.byKey(
        const ValueKey<String>('map-canvas-gesture-detector'),
      );
      final settings = _state.project!.settings;
      final tileWidth = settings.tileWidth * settings.displayScale;
      final tileHeight = settings.tileHeight * settings.displayScale;
      await tester.tapAt(
        tester.getTopLeft(canvas) + Offset(4.5 * tileWidth, 3.5 * tileHeight),
      );
      await tester.pump();
      expect(
        harness.container.read(worldMapWorkspaceSessionProvider).selectedCell,
        const GridPos(x: 4, y: 3),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        harness.container.read(worldMapWorkspaceSessionProvider).selectedCell,
        const GridPos(x: 5, y: 3),
      );
    },
  );

  testWidgets(
    'Shift arrows move the selected placed element by exactly one cell',
    (tester) async {
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        state: _keyboardMoveState,
      );
      addTearDown(() => harness.dispose(tester));
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;
      mapFocus.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(
        harness.notifier.state.activeMap!.placedElements.single.pos,
        const GridPos(x: 2, y: 1),
        reason: harness.notifier.state.errorMessage,
      );
      expect(harness.notifier.state.mapUndoStack, hasLength(1));

      harness.notifier.undoMap();
      await tester.pump();
      expect(
        harness.notifier.state.activeMap!.placedElements.single.pos,
        const GridPos(x: 1, y: 1),
      );
      expect(harness.notifier.state.mapRedoStack, hasLength(1));

      harness.notifier.redoMap();
      await tester.pump();
      expect(
        harness.notifier.state.activeMap!.placedElements.single.pos,
        const GridPos(x: 2, y: 1),
      );
      expect(harness.notifier.state.mapUndoStack, hasLength(1));
    },
  );

  testWidgets(
    'Shift arrow outside the map rejects without creating history',
    (tester) async {
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        state: _keyboardMoveEdgeState,
      );
      addTearDown(() => harness.dispose(tester));
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;
      mapFocus.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(
        harness.notifier.state.activeMap!.placedElements.single.pos,
        const GridPos(x: 7, y: 1),
      );
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
      expect(
        harness.notifier.state.errorMessage,
        contains('destination dépasse la carte'),
      );
    },
  );

  testWidgets(
    'light preview presets are semantic buttons activatable with the keyboard',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
      );
      addTearDown(() => harness.dispose(tester));
      final evening = find.byKey(
        const ValueKey<String>('shadow-light-preview-evening-button'),
      );

      expect(evening, findsOneWidget);
      expect(
        find.descendant(
          of: evening,
          matching: find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.button == true,
          ),
        ),
        findsWidgets,
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      for (var index = 0; index < 80; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus;
        if (focus != null &&
            _hasAncestorKey(
              focus,
              'shadow-light-preview-evening-button',
            )) {
          break;
        }
      }
      expect(
        _hasAncestorKey(
          FocusManager.instance.primaryFocus!,
          'shadow-light-preview-evening-button',
        ),
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      final selectedSemantics = find.descendant(
        of: evening,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.selected == true,
        ),
      );
      expect(selectedSemantics, findsWidgets);
      semantics.dispose();
    },
  );

  testWidgets(
    'tool and layer status use one stable live region with French labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
      );
      addTearDown(() => harness.dispose(tester));

      Finder statusRegion() => find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.liveRegion == true &&
                (widget.properties.label?.contains('Outil actif') ?? false),
          );

      expect(statusRegion(), findsOneWidget);
      expect(
        tester.widget<Semantics>(statusRegion()).properties.label,
        contains('Calque actif : Sol'),
      );

      harness.notifier.setActiveLayer('collision');
      await tester.pump();

      expect(statusRegion(), findsOneWidget);
      expect(
        tester.widget<Semantics>(statusRegion()).properties.label,
        contains('Calque actif : Collision'),
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'a rejected editing command is projected in French for UI and live region',
    (tester) async {
      const internalReason =
          'Select an active map before choosing an editing tool.';
      const userReason =
          'Sélectionnez une carte active avant de choisir un outil.';
      String? presentedReason;
      final semantics = tester.ensureSemantics();
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        onActivationRejected: (reason) => presentedReason = reason,
      );
      addTearDown(() => harness.dispose(tester));
      harness.notifier.state = const EditorState(
        project: ProjectManifest(
          name: 'Accessible sans carte',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-erase')),
      );
      await tester.pump();

      expect(presentedReason, userReason);
      expect(presentedReason, isNot(contains(internalReason)));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.liveRegion == true &&
              (widget.properties.label?.contains(userReason) ?? false) &&
              !(widget.properties.label?.contains(internalReason) ?? false),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'error live region consumes once and identical rejections announce twice',
    (tester) async {
      final presented = <String>[];
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        state: _incompatibleEraseState,
        onActivationRejected: presented.add,
      );
      addTearDown(() => harness.dispose(tester));
      final errorRegion = find.byKey(
        const ValueKey<String>(
          'world-map-accessibility-error-announcement',
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-erase')),
      );
      await tester.pump();
      expect(errorRegion, findsOneWidget);
      expect(
        tester.widget<Semantics>(errorRegion).properties.label,
        'Le calque actif ne peut pas être effacé.',
      );
      await tester.pump();
      expect(errorRegion, findsNothing);

      harness.notifier.setActiveLayer('ground');
      await tester.pump();
      expect(errorRegion, findsNothing);
      harness.notifier.setActiveLayer('objects');
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-tool-erase')),
      );
      await tester.pump();
      expect(errorRegion, findsOneWidget);
      expect(
        tester.widget<Semantics>(errorRegion).properties.label,
        'Le calque actif ne peut pas être effacé.',
      );
      await tester.pump();
      expect(errorRegion, findsNothing);
      expect(
        presented,
        const <String>[
          'Le calque actif ne peut pas être effacé.',
          'Le calque actif ne peut pas être effacé.',
        ],
      );
    },
  );

  testWidgets(
    'shortcut semantics and decorative exclusions stay unambiguous',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(800, 600),
        stageHeaderSlot: PokeMapAssetCard(
          thumbnail: const Icon(
            Icons.image_outlined,
            semanticLabel: 'Aperçu décoratif du test',
          ),
          label: 'Asset sans doublon',
          onPressed: () {},
        ),
      );
      addTearDown(() => harness.dispose(tester));

      expect(
        find.semantics.byLabel(RegExp(r'Enregistrer.*Cmd/Ctrl\+S')),
        findsOneWidget,
      );
      expect(
        find.semantics.byLabel('Asset sans doublon'),
        findsOneWidget,
      );
      expect(
        find.semantics.byLabel('Aperçu décoratif du test'),
        findsNothing,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'invalid rotation is disabled with an accessible reason and shortcut',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        state: _blockedRotationState,
      );
      addTearDown(() => harness.dispose(tester));
      final mapFocus = tester
          .widget<Focus>(
            find.byKey(const ValueKey<String>('map-canvas-focus')),
          )
          .focusNode!;

      mapFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();

      final blockedRotation = find.semantics.byLabel(
        RegExp(r'Rotation 90° horaire.*rotation dépasserait'),
      );
      expect(blockedRotation, findsOneWidget);
      final data = blockedRotation.evaluate().single.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.hint, contains('Raccourci : R'));
      semantics.dispose();
    },
  );

  testWidgets(
    'animation frames and pointer moves preserve the semantic status node',
    (tester) async {
      var toolbeltBuilds = 0;
      final semantics = tester.ensureSemantics();
      final harness = await _pumpWorkspace(
        tester,
        size: const Size(1280, 800),
        state: _animatedState,
        onToolbeltBuild: () => toolbeltBuilds += 1,
      );
      addTearDown(() => harness.dispose(tester));
      toolbeltBuilds = 0;
      final statusFinder = find.byKey(
        const ValueKey<String>('world-map-accessibility-status'),
      );
      final originalElement = tester.element(statusFinder);
      final originalNodeId = tester.getSemantics(statusFinder).id;
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(
          find.byKey(const ValueKey<String>('world-map-canvas-region')),
        ),
      );
      await mouse.moveBy(const Offset(12, 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pump(const Duration(milliseconds: 110));

      expect(toolbeltBuilds, 0);
      expect(tester.element(statusFinder), same(originalElement));
      expect(tester.getSemantics(statusFinder).id, originalNodeId);
      semantics.dispose();
    },
  );
}

Finder _contextMenu() => find.byWidgetPredicate(
      (widget) => widget is PokeMapContextMenu,
    );

String? _focusTarget(FocusNode node) {
  final context = node.context;
  if (context is! Element) return null;
  const globalKeys = <String>{
    'world-map-command-save',
    'world-map-command-undo',
    'world-map-command-redo',
    'world-map-command-plus',
  };
  const toolKeys = <String>{
    'world-map-tool-selection',
    'world-map-tool-paint',
    'world-map-tool-erase',
    'world-map-tool-place',
    'world-map-tool-layers',
  };
  String? target;
  void inspect(Element element) {
    final key = element.widget.key;
    if (key is ValueKey<String>) {
      if (globalKeys.contains(key.value)) {
        target = 'global:${key.value}';
      } else if (toolKeys.contains(key.value)) {
        target = 'tool:${key.value}';
      } else if (key.value == 'world-map-canvas-region') {
        target = 'region:canvas';
      } else if (key.value == 'right-inspector-region') {
        target = 'region:inspector';
      } else if (key.value == 'project-explorer-region') {
        target = 'region:explorer';
      }
    }
  }

  inspect(context);
  context.visitAncestorElements((element) {
    inspect(element);
    return target == null;
  });
  return target;
}

bool _hasAncestorKey(FocusNode node, String value) {
  final context = node.context;
  if (context is! Element) return false;
  var found = false;
  void inspect(Element element) {
    if (element.widget.key == ValueKey<String>(value)) found = true;
  }

  inspect(context);
  context.visitAncestorElements((element) {
    inspect(element);
    return !found;
  });
  return found;
}

class _WorkspaceHarness {
  const _WorkspaceHarness({
    required this.container,
    required this.subscription,
  });

  final ProviderContainer container;
  final ProviderSubscription<EditorState> subscription;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    subscription.close();
    container.dispose();
  }
}

Future<_WorkspaceHarness> _pumpWorkspace(
  WidgetTester tester, {
  required Size size,
  FocusNode? selectionFocusNode,
  FocusNode? inspectorFocusNode,
  EditorState? state,
  Widget? stageHeaderSlot,
  VoidCallback? onSave,
  VoidCallback? onNewProject,
  VoidCallback? onToolbeltBuild,
  ValueChanged<String>? onActivationRejected,
  WorldMapTargetEditorRequested? onTargetEditorRequested,
}) async {
  final container = ProviderContainer();
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  container.read(editorNotifierProvider.notifier).state = state ?? _state;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        home: Material(
          child: WorldMapWorkspace(
            inspectorFocusNode: inspectorFocusNode,
            compactInspectorReturnFocusNode: selectionFocusNode,
            onTargetEditorRequested: onTargetEditorRequested ?? (_) async {},
            toolSlot: WorldMapToolbelt(
              selectionFocusNode: selectionFocusNode,
              debugOnBuild: onToolbeltBuild,
              onSave: onSave ?? () {},
              onUndo: () {},
              onRedo: () {},
              onNewProject: onNewProject ?? () {},
              onOpenProject: () {},
              onProjectSettings: () {},
              onExportGame: () {},
              onNewMap: () {},
              onResizeMap: () {},
              onActivationRejected: onActivationRejected,
            ),
            stageHeaderSlot: stageHeaderSlot ?? const SizedBox(height: 36),
            explorerBuilder: (context, onCollapse) => PokeMapButton(
              key: const ValueKey<String>(
                'accessibility-explorer-collapse',
              ),
              onPressed: onCollapse,
              size: PokeMapButtonSize.compact,
              child: const Text('Réduire l’explorateur'),
            ),
            explorerRailBuilder: (context, onReopen) => PokeMapIconButton(
              key: const ValueKey<String>(
                'accessibility-explorer-reopen',
              ),
              onPressed: onReopen,
              tooltip: 'Rouvrir l’explorateur',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _WorkspaceHarness(container: container, subscription: subscription);
}

final _map = MapData(
  id: 'accessible-map',
  name: 'Carte accessible',
  size: const GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      cells: List<int>.filled(64, 0, growable: false),
    ),
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: List<bool>.filled(64, false, growable: false),
    ),
  ],
);

final _state = EditorState(
  project: const ProjectManifest(
    name: 'Accessible',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'accessible-map',
        name: 'Carte accessible',
        relativePath: 'maps/accessible.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
  ),
  activeMap: _map,
  activeLayerId: 'ground',
  savedMapSnapshot: _map,
  canUndoMap: true,
  canRedoMap: true,
);

final _collisionKeyboardState = _state.copyWith(
  activeLayerId: 'collision',
  activeTool: EditorToolType.collisionPaint,
);

const _keyboardMoveMap = MapData(
  id: 'keyboard-move',
  name: 'Déplacement clavier',
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'objects',
      name: 'Objets',
      cells: <int>[
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ],
    ),
  ],
  placedElements: <MapPlacedElement>[
    MapPlacedElement(
      id: 'tree-instance',
      layerId: 'objects',
      elementId: 'tree',
      pos: GridPos(x: 1, y: 1),
    ),
  ],
);

const _keyboardMoveState = EditorState(
  project: ProjectManifest(
    name: 'Déplacement clavier',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'keyboard-move',
        name: 'Déplacement clavier',
        relativePath: 'maps/keyboard-move.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'objects',
        name: 'Objets',
        relativePath: 'assets/objects.png',
      ),
    ],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'tree',
        name: 'Arbre',
        tilesetId: 'objects',
        categoryId: 'decor',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0),
          ),
        ],
      ),
    ],
  ),
  activeMap: _keyboardMoveMap,
  activeLayerId: 'objects',
  selectedPlacedElementInstanceId: 'tree-instance',
  savedMapSnapshot: _keyboardMoveMap,
);

final _keyboardMoveEdgeMap = _keyboardMoveMap.copyWith(
  placedElements: const <MapPlacedElement>[
    MapPlacedElement(
      id: 'tree-instance',
      layerId: 'objects',
      elementId: 'tree',
      pos: GridPos(x: 7, y: 1),
    ),
  ],
);

final _keyboardMoveEdgeState = _keyboardMoveState.copyWith(
  activeMap: _keyboardMoveEdgeMap,
  savedMapSnapshot: _keyboardMoveEdgeMap,
);

const _incompatibleEraseMap = MapData(
  id: 'incompatible-erase',
  name: 'Effacement incompatible',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      cells: <int>[0, 0, 0, 0],
    ),
    ObjectLayer(id: 'objects', name: 'Objets'),
  ],
);

const _incompatibleEraseState = EditorState(
  project: ProjectManifest(
    name: 'Effacement incompatible',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'incompatible-erase',
        name: 'Effacement incompatible',
        relativePath: 'maps/incompatible-erase.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
  ),
  activeMap: _incompatibleEraseMap,
  activeLayerId: 'objects',
  savedMapSnapshot: _incompatibleEraseMap,
);

const _blockedRotationMap = MapData(
  id: 'blocked-rotation',
  name: 'Rotation bloquée',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      cells: <int>[0, 0],
    ),
  ],
  placedElements: <MapPlacedElement>[
    MapPlacedElement(
      id: 'wide-instance',
      layerId: 'ground',
      elementId: 'wide',
      pos: GridPos(x: 0, y: 0),
    ),
  ],
);

const _blockedRotationState = EditorState(
  project: ProjectManifest(
    name: 'Rotation bloquée',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'blocked-rotation',
        name: 'Rotation bloquée',
        relativePath: 'maps/blocked.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'objects',
        name: 'Objets',
        relativePath: 'assets/objects.png',
      ),
    ],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'wide',
        name: 'Objet large',
        tilesetId: 'objects',
        categoryId: 'decor',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
          ),
        ],
      ),
    ],
  ),
  activeMap: _blockedRotationMap,
  activeLayerId: 'ground',
  selectedPlacedElementInstanceId: 'wide-instance',
  savedMapSnapshot: _blockedRotationMap,
);

const _animatedMap = MapData(
  id: 'animated-accessibility',
  name: 'Animation accessible',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      cells: <int>[0, 0, 0, 0],
    ),
    ObjectLayer(id: 'objects', name: 'Objets'),
  ],
  entities: <MapEntity>[
    MapEntity(
      id: 'animated-entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 0, y: 0),
      editorVisual: MapEntityEditorVisual(elementId: 'animated'),
    ),
  ],
);

const _animatedState = EditorState(
  project: ProjectManifest(
    name: 'Animation accessible',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'animated',
        name: 'Animation',
        tilesetId: 'missing',
        categoryId: 'test',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0),
            durationMs: 110,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: 0),
            durationMs: 110,
          ),
        ],
      ),
    ],
  ),
  activeMap: _animatedMap,
  activeLayerId: 'ground',
);

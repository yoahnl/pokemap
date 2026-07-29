import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Topbar Command Groups Tests', () {
    testWidgets('inventories every World Map action for its Gate 5 destination',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/topbar_world_map_action_inventory',
          project: buildShellChromeProject(
            tilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'ts_1',
                name: 'Tileset 1',
                relativePath: 'tilesets/ts_1.json',
              ),
            ],
          ),
          activeMap: buildShellChromeMap(),
          workspaceMode: EditorWorkspaceMode.map,
        ),
        surfaceSize: const Size(2200, 220),
      );

      final commandIds = [
        for (final actions in _worldMapCommandInventory.values) ...actions.keys,
      ];
      final allIds = <String>{
        ...commandIds,
        ..._worldExplorerWorkspaceNavigationInventory.keys,
      };
      expect(
        allIds,
        hasLength(
          commandIds.length + _worldExplorerWorkspaceNavigationInventory.length,
        ),
      );
      for (final destination in _WorldMapActionDestination.values) {
        final actionIds = switch (destination) {
          _WorldMapActionDestination.worldExplorer =>
            _worldExplorerWorkspaceNavigationInventory.keys,
          _ => _worldMapCommandInventory[destination]?.keys ?? const <String>[],
        };
        expect(
          actionIds,
          isNotEmpty,
          reason: '${destination.name} must own an explicit action',
        );
      }

      final assignedTooltips = <String>{
        for (final actions in _worldMapCommandInventory.values)
          ...actions.values.whereType<String>(),
        ..._worldExplorerWorkspaceNavigationInventory.values,
      };
      final renderedTooltips = tester
          .widgetList<ToolbarCapsuleButton>(
            find.byType(ToolbarCapsuleButton),
          )
          .map((button) => button.tooltip)
          .toSet();
      expect(
        renderedTooltips.difference(assignedTooltips),
        isEmpty,
        reason:
            'Every currently rendered World Map action must be assigned before '
            'the legacy topbar is replaced.',
      );

      expect(
        _worldExplorerWorkspaceNavigationInventory.values,
        everyElement(renderedTooltips.contains),
      );
    });

    testWidgets('routes map zoom to the canvas and keeps tileset zoom controls',
        (tester) async {
      final container = await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/topbar_command_groups_test',
          project: buildShellChromeProject(
            name: 'Selbrume Demo',
            tilesets: [
              const ProjectTilesetEntry(
                id: 'ts_1',
                name: 'Tileset 1',
                relativePath: 'tilesets/ts_1.json',
              ),
            ],
          ),
          activeMap: buildShellChromeMap(),
          workspaceMode: EditorWorkspaceMode.map,
        ),
        surfaceSize: const Size(1800, 220),
      );

      // Verify Brand elements
      expect(find.text('PokeMap'), findsOneWidget);
      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Selbrume Demo  •  World Editor'), findsOneWidget);

      // World-map navigation now lives directly on the canvas.
      expect(find.text('Fichier'), findsOneWidget);
      expect(find.text('Carte'), findsOneWidget);
      expect(find.text('Affichage'), findsNothing);
      expect(find.text('Outils'), findsOneWidget);
      expect(find.text('Calques'), findsOneWidget);
      expect(find.text('Aperçu'), findsOneWidget);

      // Verify they are rendered inside ToolbarCapsuleGroup widgets
      final capsuleGroups = find.byType(ToolbarCapsuleGroup);
      expect(capsuleGroups, findsAtLeastNWidgets(1));

      // Verify buttons are clickable (e.g. Switch to tileset workspace)
      final tilesetButton = find.byWidgetPredicate(
        (widget) =>
            widget is MacosTooltip &&
            widget.message == 'Switch to tileset workspace',
      );
      expect(tilesetButton, findsOneWidget);
      await tester.tap(tilesetButton);
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.tileset,
      );
      expect(find.text('Affichage'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'Zoom Out',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'Zoom In',
        ),
        findsOneWidget,
      );
    });
  });
}

enum _WorldMapActionDestination {
  toolbelt,
  adaptiveInspector,
  worldExplorer,
  plusMenu,
  globalFileHistory,
}

// This is the migration ledger for the topbar that exists before Gate 5.
// Context-only controls without a stable tooltip keep a semantic id so later
// tasks can move them without inventing a replacement widget in Task 1.
const _worldMapCommandInventory =
    <_WorldMapActionDestination, Map<String, String?>>{
  _WorldMapActionDestination.globalFileHistory: <String, String?>{
    'project.new': 'New Project',
    'project.open': 'Open Project',
    'map.save': 'Save Map',
    'history.undo': 'Undo',
    'history.redo': 'Redo',
  },
  _WorldMapActionDestination.plusMenu: <String, String?>{
    'project.settings': 'Project Settings',
    'game.export': 'Export Game',
    'map.new': 'New Map',
  },
  _WorldMapActionDestination.adaptiveInspector: <String, String?>{
    'map.resize': 'Resize Map',
    'tool.terrainType': null,
    'tool.entityKind': null,
    'tool.collisionBrushSize': null,
    'tool.eraserFootprint': null,
    'inspector.layers.toggle': 'Masquer/Afficher le panneau des calques',
  },
  _WorldMapActionDestination.toolbelt: <String, String?>{
    'tool.selection': 'Selection Tool',
    'tool.tilePaint': 'Tile Paint Tool',
    'tool.terrainPaint': 'Terrain Paint Tool',
    'tool.pathPaint': 'Path Paint Tool',
    'tool.surfacePaint': 'Surface Paint Tool',
    'tool.borderPaint': 'Border Paint Tool',
    'tool.borderErase': 'Border Erase Tool',
    'tool.collisionPaint': 'Collision Paint Tool',
    'tool.eraser': 'Eraser Tool',
    'tool.entity': 'Entity Tool',
    'tool.event': 'Event Tool',
    'tool.trigger': 'Trigger Tool',
    'tool.warp': 'Warp Tool',
    'tool.gameplayZone': 'Gameplay Zone Tool',
  },
};

// Workspace switches are navigation, not editing commands. Gate 5 moves all of
// them to World Explorer while preserving their current semantic tooltips.
const _worldExplorerWorkspaceNavigationInventory = <String, String>{
  'workspace.map': 'Switch to map workspace',
  'workspace.tileset': 'Switch to tileset workspace',
  'workspace.trainer': 'Switch to Trainer Studio',
  'workspace.pokemonCatalogs': 'Switch to Catalogues Pokémon',
  'workspace.narrativeOverview': 'Ouvrir Narrative Studio / Aperçu',
  'workspace.globalStory': 'Switch to global story workspace',
  'workspace.step': 'Switch to Step Studio',
  'workspace.scenes': 'Ouvrir le workspace Scènes',
  'workspace.events': 'Ouvrir le workspace Événements',
  'workspace.cutscene': 'Switch to Cutscene Studio',
  'workspace.dialogue': 'Switch to dialogue studio',
  'workspace.path': 'Switch to Path Studio',
  'workspace.environment': 'Switch to Environment Studio',
};

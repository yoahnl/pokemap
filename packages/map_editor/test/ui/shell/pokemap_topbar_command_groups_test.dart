import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Topbar Command Groups Tests', () {
    test('uses the approved Gate 5 command destinations', () {
      expect(
        _destinationForCommand('project.new'),
        _WorldMapActionDestination.plusMenu,
      );
      expect(
        _destinationForCommand('project.open'),
        _WorldMapActionDestination.plusMenu,
      );
      expect(
        _destinationForCommand('map.resize'),
        _WorldMapActionDestination.plusMenu,
      );
      expect(
        _destinationForCommand('inspector.layers.toggle'),
        _WorldMapActionDestination.toolbelt,
      );
    });

    testWidgets('inventories every World Map action for its Gate 5 destination',
        (tester) async {
      final map = buildShellChromeMap(
        layers: const <MapLayer>[
          MapLayer.tile(id: 'tile-layer', name: 'Tile layer'),
          MapLayer.smartTile(
            id: 'terrain-layer',
            name: 'Terrain layer',
            presetId: 'terrain',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(),
          ),
          MapLayer.smartTile(
            id: 'path-layer',
            name: 'Path layer',
            presetId: 'path',
            usage: SmartTileUsage.path,
            field: SmartTileField.cell(),
          ),
          MapLayer.smartTile(
            id: 'surface-layer',
            name: 'Surface layer',
            presetId: 'surface',
            usage: SmartTileUsage.forestSurface,
            field: SmartTileField.cell(),
          ),
          MapLayer.border(id: 'border-layer', name: 'Border layer'),
          MapLayer.collision(id: 'collision-layer', name: 'Collision layer'),
        ],
      );
      final baseState = EditorState(
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
        activeMap: map,
        workspaceMode: EditorWorkspaceMode.map,
      );
      final container = await pumpTopToolbarHarness(
        tester,
        initialState: baseState,
        surfaceSize: const Size(2200, 220),
      );

      final renderedControls = <Widget>[];

      void captureRenderedControls() {
        renderedControls.addAll(
          tester.widgetList<ToolbarCapsuleButton>(
            find.byType(ToolbarCapsuleButton),
          ),
        );
        renderedControls.addAll(
          tester.widgetList<ToolbarCapsulePulldown>(
            find.byType(ToolbarCapsulePulldown),
          ),
        );
        final eraserFootprint = find.byKey(
          const ValueKey<String>('eraser-footprint-toolbar-button'),
        );
        if (eraserFootprint.evaluate().isNotEmpty) {
          expect(eraserFootprint, findsOneWidget);
          renderedControls.add(tester.widget<PokeMapButton>(eraserFootprint));
        }
      }

      Future<void> renderAndCapture(EditorState state) async {
        container.read(editorNotifierProvider.notifier).state = state;
        await tester.pumpAndSettle();
        captureRenderedControls();
      }

      captureRenderedControls();

      // Layer probes cover every conditional tool button in the legacy topbar.
      await renderAndCapture(
        baseState.copyWith(
          activeLayerId: 'tile-layer',
          activeTool: EditorToolType.selection,
        ),
      );
      await renderAndCapture(
        baseState.copyWith(
          activeLayerId: 'path-layer',
          activeTool: EditorToolType.terrainPaint,
        ),
      );
      await renderAndCapture(
        baseState.copyWith(
          activeLayerId: 'surface-layer',
          activeTool: EditorToolType.terrainPaint,
        ),
      );
      await renderAndCapture(
        baseState.copyWith(
          activeLayerId: 'border-layer',
          activeTool: EditorToolType.selection,
        ),
      );

      // These four states prove the contextual legacy controls requested by the
      // Gate 5 review, rather than representing them with unverified constants.
      await renderAndCapture(
        baseState.copyWith(
          activeLayerId: 'terrain-layer',
          activeTool: EditorToolType.terrainPaint,
        ),
      );
      await renderAndCapture(
        baseState.copyWith(
          activeLayerId: null,
          activeTool: EditorToolType.entityPlacement,
        ),
      );
      await renderAndCapture(
        baseState.copyWith(
          activeLayerId: 'collision-layer',
          activeTool: EditorToolType.collisionPaint,
        ),
      );
      await renderAndCapture(
        baseState.copyWith(
          activeLayerId: 'tile-layer',
          activeTool: EditorToolType.eraser,
        ),
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

      final assignedControls = <String, _WorldMapControlSignature>{
        for (final actions in _worldMapCommandInventory.values) ...actions,
        ..._worldExplorerWorkspaceNavigationInventory,
      };
      final renderedActionIds = <String>{};
      for (final control in renderedControls) {
        final matchingActionIds = assignedControls.entries
            .where((entry) => entry.value.matches(control))
            .map((entry) => entry.key)
            .toList(growable: false);
        expect(
          matchingActionIds,
          hasLength(1),
          reason: '${_describeControl(control)} must be assigned exactly once.',
        );
        renderedActionIds.add(matchingActionIds.single);
      }
      expect(
        renderedActionIds,
        assignedControls.keys.toSet(),
        reason:
            'Every inventory entry must match a control rendered in at least '
            'one characterized World Map state.',
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

enum _WorldMapControlKind {
  capsuleTooltip,
  capsuleTooltipPrefix,
  pulldownLabel,
  pokeMapButtonKey,
}

final class _WorldMapControlSignature {
  const _WorldMapControlSignature.capsuleTooltip(this.value)
      : kind = _WorldMapControlKind.capsuleTooltip;

  const _WorldMapControlSignature.capsuleTooltipPrefix(this.value)
      : kind = _WorldMapControlKind.capsuleTooltipPrefix;

  const _WorldMapControlSignature.pulldownLabel(this.value)
      : kind = _WorldMapControlKind.pulldownLabel;

  const _WorldMapControlSignature.pokeMapButtonKey(this.value)
      : kind = _WorldMapControlKind.pokeMapButtonKey;

  final _WorldMapControlKind kind;
  final String value;

  bool matches(Widget widget) {
    return switch (kind) {
      _WorldMapControlKind.capsuleTooltip =>
        widget is ToolbarCapsuleButton && widget.tooltip == value,
      _WorldMapControlKind.capsuleTooltipPrefix =>
        widget is ToolbarCapsuleButton && widget.tooltip.startsWith(value),
      _WorldMapControlKind.pulldownLabel =>
        widget is ToolbarCapsulePulldown && widget.label == value,
      _WorldMapControlKind.pokeMapButtonKey =>
        widget is PokeMapButton && widget.key == ValueKey<String>(value),
    };
  }
}

// This is the migration ledger for the topbar that exists before Gate 5.
// Every entry carries a signature exercised against a real legacy widget above;
// Task 1 still does not create any destination widget.
const _worldMapCommandInventory =
    <_WorldMapActionDestination, Map<String, _WorldMapControlSignature>>{
  _WorldMapActionDestination.globalFileHistory:
      <String, _WorldMapControlSignature>{
    'map.save': _WorldMapControlSignature.capsuleTooltip('Save Map'),
    'history.undo': _WorldMapControlSignature.capsuleTooltip('Undo'),
    'history.redo': _WorldMapControlSignature.capsuleTooltip('Redo'),
  },
  _WorldMapActionDestination.plusMenu: <String, _WorldMapControlSignature>{
    'project.new': _WorldMapControlSignature.capsuleTooltip('New Project'),
    'project.open': _WorldMapControlSignature.capsuleTooltip('Open Project'),
    'project.settings':
        _WorldMapControlSignature.capsuleTooltip('Project Settings'),
    'game.export': _WorldMapControlSignature.capsuleTooltip('Export Game'),
    'map.new': _WorldMapControlSignature.capsuleTooltip('New Map'),
    'map.tiled.import':
        _WorldMapControlSignature.capsuleTooltip('Import Tiled Map (.tmx)'),
    'map.resize': _WorldMapControlSignature.capsuleTooltip('Resize Map'),
  },
  _WorldMapActionDestination.adaptiveInspector:
      <String, _WorldMapControlSignature>{
    'tool.entityKind': _WorldMapControlSignature.pulldownLabel('NPC'),
    'tool.collisionBrushSize': _WorldMapControlSignature.capsuleTooltip(
      'Collision Brush Size: Brush Footprint',
    ),
    'tool.eraserFootprint': _WorldMapControlSignature.pokeMapButtonKey(
      'eraser-footprint-toolbar-button',
    ),
  },
  _WorldMapActionDestination.toolbelt: <String, _WorldMapControlSignature>{
    'tool.selection':
        _WorldMapControlSignature.capsuleTooltip('Selection Tool'),
    'tool.tilePaint':
        _WorldMapControlSignature.capsuleTooltip('Tile Paint Tool'),
    'tool.smartTile.terrain': _WorldMapControlSignature.capsuleTooltip(
      'Terrain Smart Tile Paint Tool',
    ),
    'tool.smartTile.path': _WorldMapControlSignature.capsuleTooltip(
      'Path Smart Tile Paint Tool',
    ),
    'tool.smartTile.forestSurface': _WorldMapControlSignature.capsuleTooltip(
      'Forest Surface Smart Tile Paint Tool',
    ),
    'tool.borderPaint':
        _WorldMapControlSignature.capsuleTooltipPrefix('Border Paint Tool'),
    'tool.borderErase':
        _WorldMapControlSignature.capsuleTooltipPrefix('Border Erase Tool'),
    'tool.collisionPaint':
        _WorldMapControlSignature.capsuleTooltip('Collision Paint Tool'),
    'tool.eraser': _WorldMapControlSignature.capsuleTooltip('Eraser Tool'),
    'tool.entity': _WorldMapControlSignature.capsuleTooltip('Entity Tool'),
    'tool.event': _WorldMapControlSignature.capsuleTooltip('Event Tool'),
    'tool.trigger': _WorldMapControlSignature.capsuleTooltip('Trigger Tool'),
    'tool.warp': _WorldMapControlSignature.capsuleTooltip('Warp Tool'),
    'tool.gameplayZone':
        _WorldMapControlSignature.capsuleTooltip('Gameplay Zone Tool'),
    'inspector.layers.toggle': _WorldMapControlSignature.capsuleTooltip(
      'Masquer/Afficher le panneau des calques',
    ),
  },
};

// Workspace switches are navigation, not editing commands. Gate 5 moves all of
// them to World Explorer while preserving their current semantic tooltips.
const _worldExplorerWorkspaceNavigationInventory =
    <String, _WorldMapControlSignature>{
      'workspace.map': _WorldMapControlSignature.capsuleTooltip(
        'Switch to map workspace',
      ),
      'workspace.tileset': _WorldMapControlSignature.capsuleTooltip(
        'Switch to tileset workspace',
      ),
      'workspace.trainer': _WorldMapControlSignature.capsuleTooltip(
        'Switch to Encounter Studio',
      ),
      'workspace.pokemonCatalogs': _WorldMapControlSignature.capsuleTooltip(
        'Switch to Catalogues Pokémon',
      ),
      'workspace.narrativeOverview': _WorldMapControlSignature.capsuleTooltip(
        'Ouvrir Narrative Studio / Aperçu',
      ),
      'workspace.globalStory': _WorldMapControlSignature.capsuleTooltip(
        'Switch to global story workspace',
      ),
      'workspace.step': _WorldMapControlSignature.capsuleTooltip(
        'Switch to Step Studio',
      ),
      'workspace.scenes': _WorldMapControlSignature.capsuleTooltip(
        'Ouvrir le workspace Scènes',
      ),
      'workspace.events': _WorldMapControlSignature.capsuleTooltip(
        'Ouvrir le workspace Événements',
      ),
      'workspace.cinematics': _WorldMapControlSignature.capsuleTooltip(
        'Ouvrir la Cinematics Library',
      ),
      'workspace.dialogue': _WorldMapControlSignature.capsuleTooltip(
        'Switch to dialogue studio',
      ),
      'workspace.smartTiles': _WorldMapControlSignature.capsuleTooltip(
        'Switch to Smart Tiles Studio',
      ),
      'workspace.environment': _WorldMapControlSignature.capsuleTooltip(
        'Switch to Environment Studio',
      ),
    };

_WorldMapActionDestination? _destinationForCommand(String actionId) {
  for (final entry in _worldMapCommandInventory.entries) {
    if (entry.value.containsKey(actionId)) {
      return entry.key;
    }
  }
  return null;
}

String _describeControl(Widget widget) {
  return switch (widget) {
    ToolbarCapsuleButton(:final tooltip) => 'capsule "$tooltip"',
    ToolbarCapsulePulldown(:final label) => 'pulldown "$label"',
    PokeMapButton(:final key) => 'PokeMapButton key "$key"',
    _ => widget.runtimeType.toString(),
  };
}

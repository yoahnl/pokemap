import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/terrain_selection_mode.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import 'cupertino_editor_widgets.dart';
import 'top_toolbar/dialogs/top_toolbar_dialogs.dart';
import 'top_toolbar/widgets/toolbar_brand.dart';
import 'top_toolbar/widgets/toolbar_capsules.dart';

/// Exposé pour [MacosScaffold.toolBar], qui attend un [ToolBar] typé (pas un [ConsumerWidget]).
ToolBar buildMapEditorToolbar(BuildContext context, WidgetRef ref) =>
    TopToolbar.buildToolBar(context, ref);

/// Barre d’outils native [macos_ui] pour [MacosScaffold].
class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      TopToolbar.buildToolBar(context, ref);

  static List<MacosPulldownMenuEntry> _terrainPulldownItems(
    EditorNotifier notifier,
  ) {
    return TerrainType.values
        .where((t) => t.isBackgroundPaintable)
        .map(
          (terrain) => MacosPulldownMenuItem(
            label: _terrainTypeLabel(terrain),
            title: Text(_terrainTypeLabel(terrain)),
            onTap: () => notifier.selectTerrainType(terrain),
          ),
        )
        .toList();
  }

  static List<MacosPulldownMenuEntry> _entityKindPulldownItems(
    EditorNotifier notifier,
  ) {
    return MapEntityKind.values
        .map(
          (kind) => MacosPulldownMenuItem(
            label: _entityKindLabel(kind),
            title: Text(_entityKindLabel(kind)),
            onTap: () => notifier.selectEntityKind(kind),
          ),
        )
        .toList(growable: false);
  }

  static ToolBar buildToolBar(BuildContext context, WidgetRef ref) {
    final toolbar = ref.watch(editorToolbarSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final settings = toolbar.settings;
    final subtle = EditorChrome.subtleLabel(context);

    final map = toolbar.activeMap;
    final isMapWorkspace = toolbar.workspaceMode == EditorWorkspaceMode.map;
    final hasTilesets = (toolbar.project?.tilesets.isNotEmpty ?? false);
    final firstTilesetId =
        hasTilesets ? toolbar.project!.tilesets.first.id : null;
    final hasMapCanvas = map != null;
    final showWorldTools = isMapWorkspace && hasMapCanvas;
    final activeLayer = toolbar.activeLayer;

    final canEraseOnActiveLayer = activeLayer is TileLayer ||
        activeLayer is CollisionLayer ||
        activeLayer is TerrainLayer ||
        activeLayer is PathLayer ||
        activeLayer is SurfaceLayer;

    final showTerrainTypePulldown = activeLayer is TerrainLayer &&
        toolbar.activeTool == EditorToolType.terrainPaint &&
        toolbar.terrainSelectionMode == TerrainSelectionMode.terrain;
    final showEntityKindPulldown =
        toolbar.activeTool == EditorToolType.entityPlacement;
    final showContextStrip =
        showWorldTools && (showTerrainTypePulldown || showEntityKindPulldown);

    final showCollisionBrushSize = activeLayer is CollisionLayer &&
        (toolbar.activeTool == EditorToolType.collisionPaint ||
            toolbar.activeTool == EditorToolType.eraser);

    final actions = <ToolbarItem>[
      _groupItem(
        context,
        overflowLabel: 'Project',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_badge_plus,
            tooltip: 'New Project',
            onPressed: () => showTopToolbarNewProjectDialog(
              context,
              notifier,
            ),
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_open,
            tooltip: 'Open Project',
            onPressed: () async {
              final selectedDirectory =
                  await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                final manifestPath = p.join(selectedDirectory, 'project.json');
                await notifier.loadProject(manifestPath);
              }
            },
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.placemark,
            tooltip: 'New Map',
            onPressed:
                toolbar.project != null && toolbar.projectRootPath != null
                    ? () => showTopToolbarNewMapDialog(
                          context,
                          notifier,
                          defaultWidth: settings.defaultMapWidth,
                          defaultHeight: settings.defaultMapHeight,
                        )
                    : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.gear,
            tooltip: 'Project Settings',
            onPressed: toolbar.project != null
                ? () => showTopToolbarProjectSettingsDialog(
                      context,
                      notifier,
                      toolbar.project!,
                    )
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.rectangle_arrow_up_right_arrow_down_left,
            tooltip: 'Resize Map',
            onPressed: isMapWorkspace && toolbar.activeMap != null
                ? () => showTopToolbarResizeMapDialog(
                      context,
                      notifier,
                      currentWidth: toolbar.activeMap!.size.width,
                      currentHeight: toolbar.activeMap!.size.height,
                    )
                : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'History',
        children: [
          if (toolbar.isSaving)
            const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: ProgressCircle(),
              ),
            )
          else
            ToolbarCapsuleButton(
              icon: CupertinoIcons.floppy_disk,
              tooltip: 'Save Map',
              selected: toolbar.isDirty,
              onPressed: toolbar.canSaveMap ? notifier.saveActiveMap : null,
            ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_left,
            tooltip: 'Undo',
            onPressed: toolbar.canUndoMap ? notifier.undoMap : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_right,
            tooltip: 'Redo',
            onPressed: toolbar.canRedoMap ? notifier.redoMap : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'Workspace',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.map,
            tooltip: 'Switch to map workspace',
            selected: isMapWorkspace,
            onPressed: notifier.selectMapWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.square_grid_2x2,
            tooltip: 'Switch to tileset workspace',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.tileset,
            onPressed: hasTilesets
                ? () => notifier.selectTilesetWorkspace(
                      toolbar.selectedTilesetEntry?.id ?? firstTilesetId,
                    )
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.person_3_fill,
            tooltip: 'Switch to Trainer Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.trainer,
            onPressed: toolbar.project != null
                ? notifier.selectTrainerWorkspace
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.book,
            tooltip: 'Switch to Catalogues Pokémon',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.pokedex,
            onPressed: toolbar.project != null
                ? notifier.selectPokedexWorkspace
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.link,
            tooltip: 'Switch to global story workspace',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.globalStory,
            onPressed: notifier.selectGlobalStoryWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.flag,
            tooltip: 'Switch to Step Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.step,
            onPressed: notifier.selectStepWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.play_rectangle,
            tooltip: 'Switch to Cutscene Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.cutscene,
            onPressed: notifier.selectCutsceneWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.text_bubble,
            tooltip: 'Switch to dialogue studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.dialogue,
            onPressed: notifier.selectDialogueWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_branch,
            tooltip: 'Switch to Path Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.pathStudio,
            onPressed: toolbar.project != null
                ? notifier.selectPathStudioWorkspace
                : null,
          ),
        ],
      ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Painting Tools',
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.selection_pin_in_out,
              tooltip: 'Selection Tool',
              selected: toolbar.activeTool == EditorToolType.selection,
              onPressed: () => notifier.selectTool(EditorToolType.selection),
            ),
            if (activeLayer is TileLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.paintbrush,
                tooltip: 'Tile Paint Tool',
                selected: toolbar.activeTool == EditorToolType.tilePaint,
                onPressed: () => notifier.selectTool(EditorToolType.tilePaint),
              ),
            if (activeLayer is TerrainLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.tree,
                tooltip: 'Terrain Paint Tool',
                selected: toolbar.activeTool == EditorToolType.terrainPaint &&
                    toolbar.terrainSelectionMode ==
                        TerrainSelectionMode.terrain,
                onPressed: () =>
                    notifier.selectTool(EditorToolType.terrainPaint),
              ),
            if (activeLayer is PathLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.map,
                tooltip: 'Path Paint Tool',
                selected: toolbar.activeTool == EditorToolType.terrainPaint &&
                    toolbar.terrainSelectionMode == TerrainSelectionMode.path,
                onPressed: notifier.selectPathPaintMode,
              ),
            if (activeLayer is SurfaceLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.drop,
                tooltip: 'Surface Paint Tool',
                selected: toolbar.activeTool == EditorToolType.surfacePaint,
                onPressed: notifier.selectSurfacePaintMode,
              ),
            if (activeLayer is CollisionLayer) ...[
              ToolbarCapsuleButton(
                icon: CupertinoIcons.square_grid_2x2,
                tooltip: 'Collision Paint Tool',
                selected: toolbar.activeTool == EditorToolType.collisionPaint,
                onPressed: () => notifier.selectTool(
                  EditorToolType.collisionPaint,
                ),
              ),
              if (showCollisionBrushSize)
                ToolbarCapsuleButton(
                  icon: toolbar.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? CupertinoIcons.number
                      : CupertinoIcons.square_grid_3x2,
                  tooltip: toolbar.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? 'Collision Brush Size: 1x1'
                      : 'Collision Brush Size: Brush Footprint',
                  selected:
                      toolbar.activeTool == EditorToolType.collisionPaint ||
                          toolbar.activeTool == EditorToolType.eraser,
                  onPressed: notifier.toggleCollisionBrushSizeMode,
                ),
            ],
            if (canEraseOnActiveLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.delete,
                tooltip: 'Eraser Tool',
                selected: toolbar.activeTool == EditorToolType.eraser,
                onPressed: () => notifier.selectTool(EditorToolType.eraser),
              ),
          ],
        ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Gameplay Tools',
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.sparkles,
              tooltip: 'Entity Tool',
              selected: toolbar.activeTool == EditorToolType.entityPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.entityPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.flag,
              tooltip: 'Event Tool',
              selected: toolbar.activeTool == EditorToolType.eventPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.eventPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.square,
              tooltip: 'Trigger Tool',
              selected: toolbar.activeTool == EditorToolType.triggerPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.triggerPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.arrow_branch,
              tooltip: 'Warp Tool',
              selected: toolbar.activeTool == EditorToolType.warpPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.warpPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.leaf_arrow_circlepath,
              tooltip: 'Gameplay Zone Tool',
              selected:
                  toolbar.activeTool == EditorToolType.gameplayZonePlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.gameplayZonePlacement,
              ),
            ),
          ],
        ),
      if (showContextStrip)
        _groupItem(
          context,
          overflowLabel: 'Context',
          children: [
            if (showTerrainTypePulldown)
              ToolbarCapsulePulldown(
                label: _terrainTypeLabel(toolbar.selectedTerrainType),
                items: _terrainPulldownItems(notifier),
              ),
            if (showEntityKindPulldown)
              ToolbarCapsulePulldown(
                label: _entityKindLabel(toolbar.selectedEntityKind),
                items: _entityKindPulldownItems(notifier),
              ),
          ],
        ),
      _groupItem(
        context,
        overflowLabel: 'View',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.minus_circle,
            tooltip: 'Zoom Out',
            onPressed: () => notifier.zoom(-0.1),
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.plus_circle,
            tooltip: 'Zoom In',
            onPressed: () => notifier.zoom(0.1),
          ),
        ],
      ),
      const ToolBarSpacer(spacerUnits: 4),
      if (toolbar.statusMessage != null)
        CustomToolbarItem(
          inToolbarBuilder: (_) => Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                EditorChrome.badgeFill(context),
                EditorChrome.chipFill(context),
                0.45,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              toolbar.statusMessage!,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          inOverflowedBuilder: (_) => const ToolbarOverflowMenuItem(
            label: 'Status',
            onPressed: null,
          ),
        ),
    ];

    return ToolBar(
      title: TopToolbarBrand(
        projectName: toolbar.project?.name,
        workspaceLabel: switch (toolbar.workspaceMode) {
          EditorWorkspaceMode.map => 'World Editor',
          EditorWorkspaceMode.tileset => 'Tileset Studio',
          EditorWorkspaceMode.trainer => 'Trainer Studio',
          EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
          EditorWorkspaceMode.globalStory => 'Global Story',
          EditorWorkspaceMode.step => 'Step Studio',
          EditorWorkspaceMode.cutscene => 'Cutscene Studio',
          EditorWorkspaceMode.dialogue => 'Dialogue Studio',
          EditorWorkspaceMode.pathStudio => 'Path Studio',
        },
      ),
      titleWidth: 236,
      automaticallyImplyLeading: false,
      centerTitle: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dividerColor: MacosColors.transparent,
      decoration: BoxDecoration(
        color: EditorChrome.toolbarBarFill(context),
      ),
      actions: actions,
    );
  }

  static CustomToolbarItem _groupItem(
    BuildContext context, {
    required String overflowLabel,
    required List<Widget> children,
  }) {
    return CustomToolbarItem(
      inToolbarBuilder: (_) => ToolbarCapsuleGroup(children: children),
      inOverflowedBuilder: (_) => ToolbarOverflowMenuItem(
        label: overflowLabel,
        onPressed: null,
      ),
    );
  }

  static String _terrainTypeLabel(TerrainType type) {
    return switch (type) {
      TerrainType.none => 'None',
      TerrainType.grass => 'Grass Base',
      TerrainType.dirt => 'Dirt Base',
      TerrainType.sand => 'Sand Base',
      TerrainType.rock => 'Rock Base',
      TerrainType.stone => 'Stone Base',
      TerrainType.indoor => 'Indoor Base',
    };
  }

  static String _entityKindLabel(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'NPC',
      MapEntityKind.sign => 'Sign',
      MapEntityKind.item => 'Item',
      MapEntityKind.spawn => 'Spawn',
      MapEntityKind.custom => 'Custom',
    };
  }
}

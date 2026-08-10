import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';

import '../../../l10n/l10n.dart';
import '../../app/providers/core/repository_providers.dart';
import '../../features/border_map_editing/application/border_tool_availability.dart';
import '../../features/border_map_editing/presentation/pending_border_save_dialog.dart';
import '../../features/border_map_editing/state/border_map_editing_providers.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/presentation/tiled_map_import_flow.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'top_toolbar/dialogs/top_toolbar_dialogs.dart';
import 'top_toolbar/widgets/toolbar_brand.dart';
import 'top_toolbar/widgets/toolbar_capsules.dart';

const editorUpdateCheckToolbarActionKey =
    ValueKey<String>('editor-update-check-toolbar-action');

/// Barre d’outils native PokeMap.
class TopToolbar extends ConsumerWidget {
  const TopToolbar({
    super.key,
    this.onToggleRightPanel,
    this.rightPanelVisible = false,
    this.onCheckForUpdates,
    this.isUpdateCheckActive = false,
  });

  final VoidCallback? onToggleRightPanel;
  final bool rightPanelVisible;
  final VoidCallback? onCheckForUpdates;
  final bool isUpdateCheckActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TopToolbar.buildToolBar(
        context,
        ref,
        onToggleRightPanel: onToggleRightPanel,
        rightPanelVisible: rightPanelVisible,
        onCheckForUpdates: onCheckForUpdates,
        isUpdateCheckActive: isUpdateCheckActive,
      );

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

  static PokeMapEraserFootprintResult _eraserDialogInitialValue(
    EditorEraserFootprint footprint,
  ) {
    final size = footprint.size;
    return switch (footprint) {
      SingleTileEditorEraserFootprint() =>
        const PokeMapEraserFootprintResult.singleTile(),
      PreviousBrushEditorEraserFootprint() =>
        PokeMapEraserFootprintResult.previousBrush(
          width: size.width,
          height: size.height,
        ),
      CustomEditorEraserFootprint() => PokeMapEraserFootprintResult.custom(
          width: size.width,
          height: size.height,
        ),
    };
  }

  static Future<void> _configureEraserFootprint(
    BuildContext context,
    EditorNotifier notifier,
    EditorEraserFootprint footprint,
  ) async {
    final previousBrushFootprint = switch (footprint) {
      PreviousBrushEditorEraserFootprint(:final size) => size,
      _ => notifier.resolveCurrentPaintFootprintForEraser(),
    };
    final result = await showPokeMapEraserFootprintDialog(
      context,
      initialValue: _eraserDialogInitialValue(footprint),
      previousBrushSize: previousBrushFootprint == null
          ? null
          : (
              width: previousBrushFootprint.width,
              height: previousBrushFootprint.height,
            ),
      maxDimension: kMaxEditorEraserFootprintDimension,
    );
    if (!context.mounted || result == null) return;

    switch (result.mode) {
      case PokeMapEraserFootprintMode.singleTile:
        notifier.useSingleTileEraserFootprint();
        return;
      case PokeMapEraserFootprintMode.previousBrush:
        if (footprint is PreviousBrushEditorEraserFootprint) return;
        notifier.capturePreviousBrushEraserFootprint();
        return;
      case PokeMapEraserFootprintMode.custom:
        notifier.setCustomEraserFootprint(
          width: result.width,
          height: result.height,
        );
        return;
    }
  }

  static Widget buildToolBar(
    BuildContext context,
    WidgetRef ref, {
    VoidCallback? onToggleRightPanel,
    bool rightPanelVisible = false,
    VoidCallback? onCheckForUpdates,
    bool isUpdateCheckActive = false,
  }) {
    final colors = context.pokeMapColors;
    final l10n = context.pokeMapL10n;
    final toolbar = ref.watch(editorToolbarSnapshotProvider);
    final activeBorderFeature =
        ref.watch(activeBorderFeatureControllerProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final settings = toolbar.settings;

    final map = toolbar.activeMap;
    final isMapWorkspace = toolbar.workspaceMode == EditorWorkspaceMode.map;
    final isNarrativeOverview =
        toolbar.workspaceMode == EditorWorkspaceMode.narrativeOverview;
    final hasTilesets = (toolbar.project?.tilesets.isNotEmpty ?? false);
    final firstTilesetId =
        hasTilesets ? toolbar.project!.tilesets.first.id : null;
    final hasMapCanvas = map != null;
    final showWorldTools = isMapWorkspace && hasMapCanvas;
    final activeLayer = toolbar.activeLayer;
    final borderToolAvailability = assessBorderToolAvailability(
      manifest: toolbar.project,
      map: map,
      activeLayerId: activeLayer?.id,
      activeFeatureId: activeBorderFeature.activeFeatureId,
    );
    final showBorderTools = activeLayer is BorderLayer;
    final borderToolDisabledReason = borderToolAvailability.disabledReason;
    String borderToolTooltip(String label) => borderToolAvailability.isEnabled
        ? label
        : '$label — ${borderToolDisabledReason ?? 'Outil indisponible.'}';

    final canEraseOnActiveLayer = activeLayer is TileLayer ||
        activeLayer is CollisionLayer ||
        activeLayer is SmartTileLayer;
    final showEntityKindPulldown =
        toolbar.activeTool == EditorToolType.entityPlacement;

    final showCollisionBrushSize = activeLayer is CollisionLayer &&
        toolbar.activeTool == EditorToolType.collisionPaint;
    final eraserSize = toolbar.eraserFootprint.size;

    final actions = <Widget>[
      _groupItem(
        context,
        title: 'Fichier',
        overflowLabel: 'Fichier',
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
            onPressed: () => showTopToolbarOpenProjectDialog(context, notifier),
          ),
          if (toolbar.isSaving)
            const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            )
          else
            ToolbarCapsuleButton(
              icon: CupertinoIcons.floppy_disk,
              tooltip: switch (toolbar.workspaceMode) {
                EditorWorkspaceMode.map => 'Save Map',
                _ => toolbar.isProjectDirty
                    ? 'Save Project — unsaved project changes'
                    : 'Save Project',
              },
              selected: switch (toolbar.workspaceMode) {
                EditorWorkspaceMode.map => toolbar.isDirty,
                _ => toolbar.isProjectDirty,
              },
              onPressed: switch (toolbar.workspaceMode) {
                EditorWorkspaceMode.map => toolbar.canSaveMap
                    ? () => requestActiveMapSaveWithBorderPreviewGuard(
                          context: context,
                          notifier: notifier,
                        )
                    : null,
                _ =>
                  toolbar.project != null ? notifier.saveProjectManifest : null,
              },
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
            key: const ValueKey<String>('game-export-toolbar-button'),
            icon: CupertinoIcons.archivebox,
            tooltip: 'Export Game',
            onPressed:
                toolbar.project != null && toolbar.projectRootPath != null
                    ? () => showTopToolbarGameExportDialog(
                          context,
                          projectRootPath: toolbar.projectRootPath!,
                          projectName: toolbar.project!.name,
                        )
                    : null,
          ),
        ],
      ),
      if (!isNarrativeOverview)
        _groupItem(
          context,
          title: 'Carte',
          overflowLabel: 'Carte',
          children: [
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
              key: const ValueKey<String>('tiled-map-import-toolbar-button'),
              icon: CupertinoIcons.square_grid_3x2_fill,
              tooltip: 'Import Tiled Map (.tmx)',
              onPressed: toolbar.project != null &&
                      toolbar.projectRootPath != null
                  ? () async {
                      final result = await showTiledMapImportFlow(
                        context,
                        projectRootPath: toolbar.projectRootPath!,
                        mutations: ref.read(authoringMutationAdapterProvider),
                        queries: ref.read(authoringQueryAdapterProvider),
                      );
                      if (result == null) return;
                      notifier.acceptCanonicalProjectManifest(
                        result.manifest,
                        statusMessage:
                            'Carte « ${result.map.name} » importée depuis Tiled.',
                      );
                    }
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
      if (toolbar.workspaceMode == EditorWorkspaceMode.tileset)
        _groupItem(
          context,
          title: 'Affichage',
          overflowLabel: 'Affichage',
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
      if (!isNarrativeOverview)
        _groupItem(
          context,
          title: 'Outils',
          overflowLabel: 'Outils',
          selected: [
                EditorToolType.selection,
                EditorToolType.tilePaint,
                EditorToolType.terrainPaint,
                EditorToolType.collisionPaint,
                EditorToolType.borderPaint,
                EditorToolType.borderErase,
                EditorToolType.eraser,
                EditorToolType.entityPlacement,
                EditorToolType.eventPlacement,
                EditorToolType.triggerPlacement,
                EditorToolType.warpPlacement,
                EditorToolType.gameplayZonePlacement,
              ].contains(toolbar.activeTool) &&
              showWorldTools,
          children: [
            if (showWorldTools) ...[
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
                  onPressed: () =>
                      notifier.selectTool(EditorToolType.tilePaint),
                ),
              if (activeLayer is SmartTileLayer)
                ToolbarCapsuleButton(
                  icon: switch (activeLayer.usage) {
                    SmartTileUsage.terrain => CupertinoIcons.tree,
                    SmartTileUsage.path => CupertinoIcons.map,
                    SmartTileUsage.forestSurface => CupertinoIcons.drop,
                  },
                  tooltip: switch (activeLayer.usage) {
                    SmartTileUsage.terrain => 'Terrain Smart Tile Paint Tool',
                    SmartTileUsage.path => 'Path Smart Tile Paint Tool',
                    SmartTileUsage.forestSurface =>
                      'Forest Surface Smart Tile Paint Tool',
                  },
                  selected: toolbar.activeTool == EditorToolType.terrainPaint,
                  onPressed: () =>
                      notifier.selectTool(EditorToolType.terrainPaint),
                ),
              if (showBorderTools) ...[
                ToolbarCapsuleButton(
                  icon: CupertinoIcons.waveform_path,
                  tooltip: borderToolTooltip('Border Paint Tool'),
                  selected: toolbar.activeTool == EditorToolType.borderPaint,
                  onPressed: borderToolAvailability.isEnabled
                      ? () => notifier.selectTool(EditorToolType.borderPaint)
                      : null,
                ),
                ToolbarCapsuleButton(
                  icon: CupertinoIcons.clear_circled,
                  tooltip: borderToolTooltip('Border Erase Tool'),
                  selected: toolbar.activeTool == EditorToolType.borderErase,
                  onPressed: borderToolAvailability.isEnabled
                      ? () => notifier.selectTool(EditorToolType.borderErase)
                      : null,
                ),
              ],
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
                        toolbar.activeTool == EditorToolType.collisionPaint,
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
              if (toolbar.activeTool == EditorToolType.eraser)
                MacosTooltip(
                  message: 'Régler l’empreinte de la gomme',
                  child: PokeMapButton(
                    key: const ValueKey<String>(
                      'eraser-footprint-toolbar-button',
                    ),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: true,
                    leading: const Icon(CupertinoIcons.delete, size: 14),
                    onPressed: () {
                      _configureEraserFootprint(
                        context,
                        notifier,
                        toolbar.eraserFootprint,
                      );
                    },
                    child: Text(
                      'Gomme ${eraserSize.width}×${eraserSize.height}',
                    ),
                  ),
                ),
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
              if (showEntityKindPulldown)
                ToolbarCapsulePulldown(
                  label: _entityKindLabel(toolbar.selectedEntityKind),
                  items: _entityKindPulldownItems(notifier),
                ),
            ],
          ],
        ),
      if (!isNarrativeOverview)
        _groupItem(
          context,
          title: 'Calques',
          overflowLabel: 'Calques',
          selected: rightPanelVisible,
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.layers,
              tooltip: 'Masquer/Afficher le panneau des calques',
              selected: rightPanelVisible,
              onPressed: onToggleRightPanel,
            ),
          ],
        ),
      if (onCheckForUpdates != null)
        _groupItem(
          context,
          title: l10n.editorUpdateHelp,
          overflowLabel: l10n.editorUpdateHelp,
          children: [
            ToolbarCapsuleButton(
              key: editorUpdateCheckToolbarActionKey,
              icon: CupertinoIcons.arrow_2_circlepath,
              tooltip: isUpdateCheckActive
                  ? l10n.editorUpdateChecking
                  : l10n.editorUpdateCheck,
              onPressed: isUpdateCheckActive ? null : onCheckForUpdates,
            ),
          ],
        ),
      if (isNarrativeOverview)
        _groupItem(
          context,
          title: 'Narrative Studio',
          overflowLabel: 'Narrative Studio',
          selected: true,
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.house,
              tooltip: 'Ouvrir Narrative Studio / Aperçu',
              selected: true,
              onPressed: toolbar.project != null
                  ? notifier.selectNarrativeOverviewWorkspace
                  : null,
            ),
            const ToolbarCapsuleButton(
              icon: CupertinoIcons.plus,
              tooltip:
                  'Nouvelle storyline à venir — création non branchée en V0',
              onPressed: null,
            ),
            const ToolbarCapsuleButton(
              icon: CupertinoIcons.checkmark_shield,
              tooltip:
                  'Validation narrative à venir — aucun validateur global branché en V0',
              onPressed: null,
            ),
            const ToolbarCapsuleButton(
              icon: CupertinoIcons.search,
              tooltip:
                  'Recherche narrative à venir — aucune recherche globale branchée en V0',
              onPressed: null,
            ),
            const ToolbarCapsuleButton(
              icon: CupertinoIcons.bell,
              tooltip:
                  'Notifications indisponibles — aucune source fiable en V0',
              onPressed: null,
            ),
          ],
        )
      else
        _groupItem(
          context,
          title: 'Aperçu',
          overflowLabel: 'Aperçu',
          selected: true,
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
              tooltip: 'Switch to Encounter Studio',
              selected: toolbar.workspaceMode == EditorWorkspaceMode.encounter,
              onPressed: toolbar.project != null
                  ? notifier.selectEncounterWorkspace
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
              icon: CupertinoIcons.house,
              tooltip: 'Ouvrir Narrative Studio / Aperçu',
              selected: toolbar.workspaceMode ==
                  EditorWorkspaceMode.narrativeOverview,
              onPressed: toolbar.project != null
                  ? notifier.selectNarrativeOverviewWorkspace
                  : null,
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.link,
              tooltip: 'Switch to global story workspace',
              selected:
                  toolbar.workspaceMode == EditorWorkspaceMode.globalStory,
              onPressed: notifier.selectGlobalStoryWorkspace,
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.flag,
              tooltip: 'Switch to Step Studio',
              selected: toolbar.workspaceMode == EditorWorkspaceMode.step,
              onPressed: notifier.selectStepWorkspace,
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.square_stack_3d_up,
              tooltip: 'Ouvrir le workspace Scènes',
              selected: toolbar.workspaceMode == EditorWorkspaceMode.scenes,
              onPressed: toolbar.project != null
                  ? notifier.selectScenesWorkspace
                  : null,
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.bolt_horizontal_circle,
              tooltip: 'Ouvrir le workspace Événements',
              selected: toolbar.workspaceMode == EditorWorkspaceMode.events,
              onPressed: toolbar.project != null
                  ? notifier.selectEventsWorkspace
                  : null,
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
              key: const ValueKey<String>('smart-tiles-studio-toolbar-button'),
              icon: CupertinoIcons.square_grid_3x2,
              tooltip: 'Switch to Smart Tiles Studio',
              selected:
                  toolbar.workspaceMode == EditorWorkspaceMode.smartTilesStudio,
              onPressed: toolbar.project != null
                  ? notifier.selectSmartTilesStudioWorkspace
                  : null,
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.tree,
              tooltip: 'Switch to Environment Studio',
              selected: toolbar.workspaceMode ==
                  EditorWorkspaceMode.environmentStudio,
              onPressed: toolbar.project != null
                  ? notifier.selectEnvironmentStudioWorkspace
                  : null,
            ),
          ],
        ),
    ];

    return Container(
      height: 78.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.backgroundShell,
        border: Border(
          bottom: BorderSide(
            color: colors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: TopToolbarBrand(
              projectName: toolbar.project?.name,
              workspaceLabel: switch (toolbar.workspaceMode) {
                EditorWorkspaceMode.map => 'World Editor',
                EditorWorkspaceMode.tileset => 'Tileset Studio',
                EditorWorkspaceMode.encounter => 'Encounter Studio',
                EditorWorkspaceMode.characterStudio => 'Character Studio',
                EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
                EditorWorkspaceMode.narrativeOverview =>
                  'Narrative Studio / Aperçu',
                EditorWorkspaceMode.globalStory => 'Global Story',
                EditorWorkspaceMode.scenes => 'Scenes Workspace',
                EditorWorkspaceMode.events => 'Event Builder',
                EditorWorkspaceMode.step => 'Step Studio',
                EditorWorkspaceMode.cutscene => 'Cutscene Studio',
                EditorWorkspaceMode.dialogue => 'Dialogue Studio',
                EditorWorkspaceMode.facts => 'Facts Manager',
                EditorWorkspaceMode.shops => 'Boutique Builder',
                EditorWorkspaceMode.worldRules => 'World Rules Manager',
                EditorWorkspaceMode.narrativeValidator => 'Narrative Validator',
                EditorWorkspaceMode.smartTilesStudio => 'Smart Tiles Studio',
                EditorWorkspaceMode.environmentStudio => 'Environment Studio',
                EditorWorkspaceMode.personalizationStudio =>
                  'Personalization Studio',
                EditorWorkspaceMode.borderStudio => 'Border Studio',
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: actions,
              ),
            ),
          ),
          if (toolbar.statusMessage != null) ...[
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.brandPrimarySoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colors.brandPrimaryBorder,
                  width: 1,
                ),
              ),
              child: Text(
                toolbar.statusMessage!,
                style: TextStyle(
                  color: colors.brandPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _groupItem(
    BuildContext context, {
    required String overflowLabel,
    required List<Widget> children,
    String? title,
    bool selected = false,
  }) {
    return ToolbarCapsuleGroup(
      title: title,
      selected: selected,
      children: children,
    );
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/models/terrain_selection_mode.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/world_map_observed_tool_family.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import '../../state/editor_selectors.dart';
import '../../tools/editor_tool.dart';
import 'world_map_paint_inspection_intent.dart';
import 'world_map_workspace_session.dart';

class WorldMapToolbelt extends ConsumerWidget {
  const WorldMapToolbelt({
    this.onSave,
    this.onUndo,
    this.onRedo,
    this.onNewProject,
    this.onOpenProject,
    this.onProjectSettings,
    this.onExportGame,
    this.onNewMap,
    this.onResizeMap,
    this.onActivationRejected,
    this.selectionFocusNode,
    super.key,
  });

  final VoidCallback? onSave;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onNewProject;
  final VoidCallback? onOpenProject;
  final VoidCallback? onProjectSettings;
  final VoidCallback? onExportGame;
  final VoidCallback? onNewMap;
  final VoidCallback? onResizeMap;
  final ValueChanged<String>? onActivationRejected;
  final FocusNode? selectionFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolbar = ref.watch(editorWorldMapToolbarSnapshotProvider);
    final brushKind = ref.watch(editorWorldMapBrushKindProvider);
    final session = ref.watch(worldMapWorkspaceSessionProvider);
    final sessionController =
        ref.read(worldMapWorkspaceSessionProvider.notifier);
    final editor = ref.read(editorNotifierProvider.notifier);
    final paintInspectionIntent =
        ref.read(worldMapPaintInspectionIntentProvider.notifier);

    void reportResult(WorldMapToolActivationResult result) {
      final reason = result.rejectionReason;
      if (!result.accepted && reason != null && reason.isNotEmpty) {
        onActivationRejected?.call(reason);
      }
    }

    void reconcilePaintRouting(WorldMapPaintRoutingResult routing) {
      final editorState = ref.read(editorNotifierProvider);
      final mapId = editorState.activeMap?.id;
      switch (routing.outcome) {
        case WorldMapPaintRoutingOutcome.activated:
          paintInspectionIntent.clear();
          sessionController.setInspectorVisible(true);
        case WorldMapPaintRoutingOutcome.setupRequired:
          final layerId = routing.layerId;
          if (mapId != null && layerId != null) {
            paintInspectionIntent.showSetup(
              mapId: mapId,
              layerId: layerId,
              subtool: routing.request.subtool,
            );
            sessionController.setInspectorVisible(true);
          }
        case WorldMapPaintRoutingOutcome.choiceRequired:
          if (mapId != null) {
            paintInspectionIntent.showLayerChoice(
              mapId: mapId,
              subtool: routing.request.subtool,
              compatibleLayerIds: routing.compatibleLayerIds,
            );
            sessionController.setInspectorVisible(true);
          }
        case WorldMapPaintRoutingOutcome.missingLayer:
          if (mapId != null) {
            paintInspectionIntent.showMissingLayer(
              mapId: mapId,
              subtool: routing.request.subtool,
            );
            sessionController.setInspectorVisible(true);
          }
        case WorldMapPaintRoutingOutcome.rejected:
          paintInspectionIntent.clear();
          final activation = routing.activation;
          if (activation != null) {
            reportResult(activation);
          }
      }
    }

    void activate(WorldMapToolActivationRequest request) {
      if (request case ActivateWorldMapPaint(:final subtool)) {
        reconcilePaintRouting(
          sessionController.routePaintSubtool(editor, subtool),
        );
        return;
      }
      final result = sessionController.activateTool(editor, request);
      if (result.accepted) {
        paintInspectionIntent.clear();
      }
      reportResult(result);
    }

    void activateLayers() {
      final result = sessionController.activateLayers(editor);
      if (result.accepted) {
        paintInspectionIntent.clear();
        sessionController.setInspectorVisible(true);
      }
      reportResult(result);
    }

    final rememberedPaint = sessionController.resolveRememberedPaintSubtool(
      mapId: toolbar.activeMap?.id,
      layerId: toolbar.activeLayer?.id,
    );
    final visualState = _resolveVisualToolState(
      session: session,
      activeTool: toolbar.activeTool,
      terrainSelectionMode: toolbar.terrainSelectionMode,
      rememberedPaint: rememberedPaint,
      brushKind: brushKind,
    );
    final paintLabel = _paintSubtoolLabel(visualState.paintSubtool);
    final placementLabel = _placementSubtoolLabel(
      visualState.placementSubtool,
    );

    return PokeMapToolbarSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ToolbeltRow(
            label: 'Projet',
            children: [
              Tooltip(
                message: 'Enregistrer (Cmd/Ctrl+S)',
                child: PokeMapButton(
                  key: const ValueKey<String>('world-map-command-save'),
                  onPressed: toolbar.canSaveMap ? onSave : null,
                  isLoading: toolbar.isSaving,
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(Icons.save_outlined),
                  child: const Text('Enregistrer'),
                ),
              ),
              _LabeledIconCommand(
                commandKey: const ValueKey<String>('world-map-command-undo'),
                onPressed: toolbar.canUndoMap ? onUndo : null,
                icon: const Icon(Icons.undo_rounded),
                label: 'Annuler',
                tooltip: 'Annuler (Cmd/Ctrl+Z)',
              ),
              _LabeledIconCommand(
                commandKey: const ValueKey<String>('world-map-command-redo'),
                onPressed: toolbar.canRedoMap ? onRedo : null,
                icon: const Icon(Icons.redo_rounded),
                label: 'Rétablir',
                tooltip: 'Rétablir (Shift+Cmd/Ctrl+Z ou Cmd/Ctrl+Y)',
              ),
              _WorldMapPlusMenu(
                onNewProject: onNewProject,
                onOpenProject: onOpenProject,
                onProjectSettings: onProjectSettings,
                onExportGame: onExportGame,
                onNewMap: onNewMap,
                onResizeMap: onResizeMap,
                onUnavailable: onActivationRejected,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ToolbeltRow(
            label: 'Outils',
            children: [
              Tooltip(
                message: 'Sélectionner et manipuler',
                child: PokeMapButton(
                  key: const ValueKey<String>('world-map-tool-selection'),
                  onPressed: () => activate(
                    const ActivateWorldMapSelection(),
                  ),
                  focusNode: selectionFocusNode,
                  isSelected:
                      visualState.family == WorldMapToolFamily.selection,
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(Icons.near_me_outlined),
                  child: const Text('Sélection'),
                ),
              ),
              PokeMapSplitButton<WorldMapPaintSubtool>(
                key: const ValueKey<String>('world-map-tool-paint'),
                onPressed: () {
                  final replay = sessionController.activatePaintReplay(
                    editor,
                    observedMapId: toolbar.activeMap?.id,
                    observedLayerId: toolbar.activeLayer?.id,
                    observedSubtool: visualState.paintSubtool,
                  );
                  reconcilePaintRouting(replay.routing);
                },
                items: [
                  for (final subtool in WorldMapPaintSubtool.values)
                    PokeMapMenuItem<WorldMapPaintSubtool>(
                      value: subtool,
                      label: _paintSubtoolLabel(subtool),
                    ),
                ],
                onSelected: (subtool) => activate(
                  ActivateWorldMapPaint(subtool),
                ),
                tooltip: 'Peindre · $paintLabel',
                menuTooltip: 'Choisir un outil de peinture',
                isSelected: visualState.family == WorldMapToolFamily.paint,
                child: const Text('Peindre'),
              ),
              Tooltip(
                message: 'Effacer sur le calque actif',
                child: PokeMapButton(
                  key: const ValueKey<String>('world-map-tool-erase'),
                  onPressed: () => activate(
                    const ActivateWorldMapErase(),
                  ),
                  isSelected: visualState.family == WorldMapToolFamily.erase,
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(Icons.auto_fix_off_outlined),
                  child: const Text('Effacer'),
                ),
              ),
              PokeMapSplitButton<WorldMapPlacementSubtool>(
                key: const ValueKey<String>('world-map-tool-place'),
                onPressed: () => activate(
                  ActivateWorldMapPlacement(
                    visualState.placementSubtool,
                  ),
                ),
                items: [
                  for (final subtool in WorldMapPlacementSubtool.values)
                    PokeMapMenuItem<WorldMapPlacementSubtool>(
                      value: subtool,
                      label: _placementSubtoolLabel(subtool),
                    ),
                ],
                onSelected: (subtool) => activate(
                  ActivateWorldMapPlacement(subtool),
                ),
                tooltip: 'Placer · $placementLabel',
                menuTooltip: 'Choisir un outil de placement',
                isSelected: visualState.family == WorldMapToolFamily.place,
                child: const Text('Placer'),
              ),
              Tooltip(
                message: 'Ouvrir la gestion des calques',
                child: PokeMapButton(
                  key: const ValueKey<String>('world-map-tool-layers'),
                  onPressed: activateLayers,
                  isSelected: visualState.family == WorldMapToolFamily.layers,
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(Icons.layers_outlined),
                  child: const Text('Calques'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef _WorldMapVisualToolState = ({
  WorldMapToolFamily family,
  WorldMapPaintSubtool paintSubtool,
  WorldMapPlacementSubtool placementSubtool,
});

_WorldMapVisualToolState _resolveVisualToolState({
  required WorldMapWorkspaceSession session,
  required EditorToolType activeTool,
  required TerrainSelectionMode terrainSelectionMode,
  required WorldMapPaintSubtool rememberedPaint,
  required EditorWorldMapBrushKind brushKind,
}) {
  final family = resolveWorldMapObservedToolFamily(
    activeTool: activeTool,
    session: session,
    brushKind: brushKind,
  );
  return switch (activeTool) {
    EditorToolType.selection => (
        family: family,
        paintSubtool: rememberedPaint,
        placementSubtool: session.lastPlacementSubtool,
      ),
    EditorToolType.tilePaint => (
        family: family,
        paintSubtool: WorldMapPaintSubtool.tile,
        placementSubtool: family == WorldMapToolFamily.place
            ? WorldMapPlacementSubtool.object
            : session.lastPlacementSubtool,
      ),
    EditorToolType.terrainPaint => (
        family: family,
        paintSubtool: terrainSelectionMode == TerrainSelectionMode.path
            ? WorldMapPaintSubtool.path
            : WorldMapPaintSubtool.terrain,
        placementSubtool: session.lastPlacementSubtool,
      ),
    EditorToolType.surfacePaint => (
        family: family,
        paintSubtool: WorldMapPaintSubtool.surface,
        placementSubtool: session.lastPlacementSubtool,
      ),
    EditorToolType.collisionPaint => (
        family: family,
        paintSubtool: WorldMapPaintSubtool.collision,
        placementSubtool: session.lastPlacementSubtool,
      ),
    EditorToolType.borderPaint => (
        family: family,
        paintSubtool: WorldMapPaintSubtool.border,
        placementSubtool: session.lastPlacementSubtool,
      ),
    EditorToolType.eraser || EditorToolType.borderErase => (
        family: family,
        paintSubtool: rememberedPaint,
        placementSubtool: session.lastPlacementSubtool,
      ),
    EditorToolType.entityPlacement => (
        family: family,
        paintSubtool: rememberedPaint,
        placementSubtool: WorldMapPlacementSubtool.entity,
      ),
    EditorToolType.eventPlacement => (
        family: family,
        paintSubtool: rememberedPaint,
        placementSubtool: WorldMapPlacementSubtool.event,
      ),
    EditorToolType.triggerPlacement => (
        family: family,
        paintSubtool: rememberedPaint,
        placementSubtool: WorldMapPlacementSubtool.trigger,
      ),
    EditorToolType.warpPlacement => (
        family: family,
        paintSubtool: rememberedPaint,
        placementSubtool: WorldMapPlacementSubtool.warp,
      ),
    EditorToolType.gameplayZonePlacement => (
        family: family,
        paintSubtool: rememberedPaint,
        placementSubtool: WorldMapPlacementSubtool.gameplayZone,
      ),
  };
}

class _LabeledIconCommand extends StatelessWidget {
  const _LabeledIconCommand({
    required this.commandKey,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  final Key commandKey;
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapIconButton(
          key: commandKey,
          onPressed: onPressed,
          icon: icon,
          tooltip: tooltip,
          variant: PokeMapIconButtonVariant.soft,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: onPressed == null ? colors.textDisabled : colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ToolbeltRow extends StatelessWidget {
  const _ToolbeltRow({
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (var index = 0; index < children.length; index += 1) ...[
          if (index > 0) const SizedBox(width: 6),
          children[index],
        ],
      ],
    );
  }
}

enum _WorldMapMoreAction {
  newProject,
  openProject,
  projectSettings,
  exportGame,
  newMap,
  resizeMap,
}

class _WorldMapPlusMenu extends StatefulWidget {
  const _WorldMapPlusMenu({
    this.onNewProject,
    this.onOpenProject,
    this.onProjectSettings,
    this.onExportGame,
    this.onNewMap,
    this.onResizeMap,
    this.onUnavailable,
  });

  final VoidCallback? onNewProject;
  final VoidCallback? onOpenProject;
  final VoidCallback? onProjectSettings;
  final VoidCallback? onExportGame;
  final VoidCallback? onNewMap;
  final VoidCallback? onResizeMap;
  final ValueChanged<String>? onUnavailable;

  @override
  State<_WorldMapPlusMenu> createState() => _WorldMapPlusMenuState();
}

class _WorldMapPlusMenuState extends State<_WorldMapPlusMenu> {
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(debugLabel: 'world map plus command');
  OverlayEntry? _menuEntry;

  @override
  void didUpdateWidget(covariant _WorldMapPlusMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_menuEntry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _menuEntry == null) return;
      _menuEntry?.markNeedsBuild();
    });
  }

  @override
  void dispose() {
    final entry = _menuEntry;
    entry?.remove();
    entry?.dispose();
    _menuEntry = null;
    _focusNode.dispose();
    super.dispose();
  }

  List<PokeMapMenuItem<_WorldMapMoreAction>> get _items => [
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.newProject,
          label: 'Projet · Nouveau projet',
          enabled: widget.onNewProject != null,
          disabledReason: widget.onNewProject == null
              ? 'La création de projet est indisponible.'
              : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.openProject,
          label: 'Projet · Ouvrir un projet',
          enabled: widget.onOpenProject != null,
          disabledReason: widget.onOpenProject == null
              ? 'L’ouverture de projet est indisponible.'
              : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.projectSettings,
          label: 'Projet · Réglages du projet',
          enabled: widget.onProjectSettings != null,
          disabledReason:
              widget.onProjectSettings == null ? 'Ouvrez un projet.' : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.exportGame,
          label: 'Projet · Exporter le jeu',
          enabled: widget.onExportGame != null,
          disabledReason: widget.onExportGame == null
              ? 'Ouvrez un projet enregistré.'
              : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.newMap,
          label: 'Carte · Nouvelle map',
          enabled: widget.onNewMap != null,
          disabledReason:
              widget.onNewMap == null ? 'Ouvrez un projet enregistré.' : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.resizeMap,
          label: 'Carte · Redimensionner',
          enabled: widget.onResizeMap != null,
          disabledReason:
              widget.onResizeMap == null ? 'Ouvrez une carte.' : null,
        ),
      ];

  void _openMenu() {
    if (_menuEntry != null) return;
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final overlay = Overlay.of(context);
    final overlayRenderObject = overlay.context.findRenderObject();
    if (overlayRenderObject is! RenderBox) return;
    final globalAnchor = renderObject.localToGlobal(
      Offset(0, renderObject.size.height),
    );
    final anchor = overlayRenderObject.globalToLocal(globalAnchor);
    final entry = OverlayEntry(
      builder: (context) => PokeMapContextMenu<_WorldMapMoreAction>(
        anchor: anchor,
        items: _items,
        dividerAfter: const <int>{3},
        invokerFocusNode: _focusNode,
        semanticLabel: 'Plus d’actions World Map',
        onSelected: _activate,
        onDismiss: _closeMenu,
      ),
    );
    _menuEntry = entry;
    overlay.insert(entry);
    setState(() {});
  }

  void _closeMenu() {
    final entry = _menuEntry;
    if (entry == null) return;
    _menuEntry = null;
    entry.remove();
    entry.dispose();
    if (mounted) setState(() {});
  }

  void _activate(_WorldMapMoreAction action) {
    final callback = switch (action) {
      _WorldMapMoreAction.newProject => widget.onNewProject,
      _WorldMapMoreAction.openProject => widget.onOpenProject,
      _WorldMapMoreAction.projectSettings => widget.onProjectSettings,
      _WorldMapMoreAction.exportGame => widget.onExportGame,
      _WorldMapMoreAction.newMap => widget.onNewMap,
      _WorldMapMoreAction.resizeMap => widget.onResizeMap,
    };
    if (callback == null) {
      final disabledReason =
          _items.singleWhere((item) => item.value == action).disabledReason;
      if (disabledReason != null && disabledReason.isNotEmpty) {
        widget.onUnavailable?.call(disabledReason);
      }
      _menuEntry?.markNeedsBuild();
      return;
    }
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _anchorKey,
      child: Tooltip(
        message: 'Plus d’actions',
        child: PokeMapButton(
          key: const ValueKey<String>('world-map-command-plus'),
          onPressed: _openMenu,
          focusNode: _focusNode,
          size: PokeMapButtonSize.small,
          variant: PokeMapButtonVariant.ghost,
          trailing: const Icon(Icons.arrow_drop_down_rounded),
          child: const Text('Plus'),
        ),
      ),
    );
  }
}

String _paintSubtoolLabel(WorldMapPaintSubtool subtool) {
  return switch (subtool) {
    WorldMapPaintSubtool.tile => 'Éléments',
    WorldMapPaintSubtool.terrain => 'Terrain',
    WorldMapPaintSubtool.path => 'Chemins',
    WorldMapPaintSubtool.surface => 'Surfaces',
    WorldMapPaintSubtool.border => 'Bordures',
    WorldMapPaintSubtool.collision => 'Collision',
  };
}

String _placementSubtoolLabel(WorldMapPlacementSubtool subtool) {
  return switch (subtool) {
    WorldMapPlacementSubtool.object => 'Objet',
    WorldMapPlacementSubtool.entity => 'Entity',
    WorldMapPlacementSubtool.event => 'Event',
    WorldMapPlacementSubtool.trigger => 'Trigger',
    WorldMapPlacementSubtool.warp => 'Warp',
    WorldMapPlacementSubtool.gameplayZone => 'Gameplay zone',
  };
}

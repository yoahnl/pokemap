import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import '../../state/editor_selectors.dart';
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
    final session = ref.watch(worldMapWorkspaceSessionProvider);
    final sessionController =
        ref.read(worldMapWorkspaceSessionProvider.notifier);
    final editor = ref.read(editorNotifierProvider.notifier);

    void reportResult(WorldMapToolActivationResult result) {
      final reason = result.rejectionReason;
      if (!result.accepted && reason != null && reason.isNotEmpty) {
        onActivationRejected?.call(reason);
      }
    }

    void activate(WorldMapToolActivationRequest request) {
      reportResult(sessionController.activateTool(editor, request));
    }

    void activateLayers() {
      final result = sessionController.activateLayers(editor);
      if (result.accepted) {
        sessionController.setInspectorVisible(true);
      }
      reportResult(result);
    }

    final activeLayerId = toolbar.activeLayer?.id;
    final rememberedPaint = activeLayerId == null
        ? session.lastPaintSubtool
        : session.lastPaintSubtoolByLayerId[activeLayerId] ??
            session.lastPaintSubtool;
    final paintLabel = _paintSubtoolLabel(rememberedPaint);
    final placementLabel = _placementSubtoolLabel(
      session.lastPlacementSubtool,
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
              Tooltip(
                message: 'Annuler (Cmd/Ctrl+Z)',
                child: PokeMapButton(
                  key: const ValueKey<String>('world-map-command-undo'),
                  onPressed: toolbar.canUndoMap ? onUndo : null,
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.ghost,
                  leading: const Icon(Icons.undo_rounded),
                  child: const Text('Annuler'),
                ),
              ),
              Tooltip(
                message: 'Rétablir (Shift+Cmd/Ctrl+Z ou Cmd/Ctrl+Y)',
                child: PokeMapButton(
                  key: const ValueKey<String>('world-map-command-redo'),
                  onPressed: toolbar.canRedoMap ? onRedo : null,
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.ghost,
                  leading: const Icon(Icons.redo_rounded),
                  child: const Text('Rétablir'),
                ),
              ),
              _WorldMapPlusMenu(
                onNewProject: onNewProject,
                onOpenProject: onOpenProject,
                onProjectSettings: onProjectSettings,
                onExportGame: onExportGame,
                onNewMap: onNewMap,
                onResizeMap: onResizeMap,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ToolbeltRow(
            label: 'Outils',
            children: [
              PokeMapButton(
                key: const ValueKey<String>('world-map-tool-selection'),
                onPressed: () => activate(
                  const ActivateWorldMapSelection(),
                ),
                focusNode: selectionFocusNode,
                isSelected:
                    session.activeFamily == WorldMapToolFamily.selection,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(Icons.near_me_outlined),
                child: const Text('Sélection'),
              ),
              PokeMapSplitButton<WorldMapPaintSubtool>(
                key: const ValueKey<String>('world-map-tool-paint'),
                onPressed: () => activate(
                  ActivateWorldMapPaint(rememberedPaint),
                ),
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
                isSelected: session.activeFamily == WorldMapToolFamily.paint,
                child: const Text('Peindre'),
              ),
              PokeMapButton(
                key: const ValueKey<String>('world-map-tool-erase'),
                onPressed: () => activate(
                  const ActivateWorldMapErase(),
                ),
                isSelected: session.activeFamily == WorldMapToolFamily.erase,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(Icons.auto_fix_off_outlined),
                child: const Text('Effacer'),
              ),
              PokeMapSplitButton<WorldMapPlacementSubtool>(
                key: const ValueKey<String>('world-map-tool-place'),
                onPressed: () => activate(
                  ActivateWorldMapPlacement(
                    session.lastPlacementSubtool,
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
                isSelected: session.activeFamily == WorldMapToolFamily.place,
                child: const Text('Placer'),
              ),
              PokeMapButton(
                key: const ValueKey<String>('world-map-tool-layers'),
                onPressed: activateLayers,
                isSelected: session.activeFamily == WorldMapToolFamily.layers,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(Icons.layers_outlined),
                child: const Text('Calques'),
              ),
            ],
          ),
        ],
      ),
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
  });

  final VoidCallback? onNewProject;
  final VoidCallback? onOpenProject;
  final VoidCallback? onProjectSettings;
  final VoidCallback? onExportGame;
  final VoidCallback? onNewMap;
  final VoidCallback? onResizeMap;

  @override
  State<_WorldMapPlusMenu> createState() => _WorldMapPlusMenuState();
}

class _WorldMapPlusMenuState extends State<_WorldMapPlusMenu> {
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(debugLabel: 'world map plus command');
  OverlayEntry? _menuEntry;

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
          label: 'New Project',
          enabled: widget.onNewProject != null,
          disabledReason: widget.onNewProject == null
              ? 'La création de projet est indisponible.'
              : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.openProject,
          label: 'Open Project',
          enabled: widget.onOpenProject != null,
          disabledReason: widget.onOpenProject == null
              ? 'L’ouverture de projet est indisponible.'
              : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.projectSettings,
          label: 'Project Settings',
          enabled: widget.onProjectSettings != null,
          disabledReason:
              widget.onProjectSettings == null ? 'Ouvrez un projet.' : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.exportGame,
          label: 'Export Game',
          enabled: widget.onExportGame != null,
          disabledReason: widget.onExportGame == null
              ? 'Ouvrez un projet enregistré.'
              : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.newMap,
          label: 'New Map',
          enabled: widget.onNewMap != null,
          disabledReason:
              widget.onNewMap == null ? 'Ouvrez un projet enregistré.' : null,
        ),
        PokeMapMenuItem<_WorldMapMoreAction>(
          value: _WorldMapMoreAction.resizeMap,
          label: 'Resize Map',
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
    switch (action) {
      case _WorldMapMoreAction.newProject:
        widget.onNewProject?.call();
      case _WorldMapMoreAction.openProject:
        widget.onOpenProject?.call();
      case _WorldMapMoreAction.projectSettings:
        widget.onProjectSettings?.call();
      case _WorldMapMoreAction.exportGame:
        widget.onExportGame?.call();
      case _WorldMapMoreAction.newMap:
        widget.onNewMap?.call();
      case _WorldMapMoreAction.resizeMap:
        widget.onResizeMap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _anchorKey,
      child: PokeMapButton(
        key: const ValueKey<String>('world-map-command-plus'),
        onPressed: _openMenu,
        focusNode: _focusNode,
        size: PokeMapButtonSize.small,
        variant: PokeMapButtonVariant.ghost,
        trailing: const Icon(Icons.arrow_drop_down_rounded),
        child: const Text('Plus'),
      ),
    );
  }
}

String _paintSubtoolLabel(WorldMapPaintSubtool subtool) {
  return switch (subtool) {
    WorldMapPaintSubtool.tile => 'Tuiles',
    WorldMapPaintSubtool.terrain => 'Terrain',
    WorldMapPaintSubtool.path => 'Paths',
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

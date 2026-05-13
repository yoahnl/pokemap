import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, Draggable, DragTarget, Material;
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import 'layers_panel_presentation.dart';

enum _LayerCreationKind {
  tile,
  collision,
  terrain,
  path,
  surface,
  object,
  environment,
}

class LayersPanel extends ConsumerWidget {
  const LayersPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  static String _kindLabel(_LayerCreationKind k) {
    return switch (k) {
      _LayerCreationKind.tile => 'Tile Layer',
      _LayerCreationKind.collision => 'Collision Layer',
      _LayerCreationKind.terrain => 'Terrain Layer',
      _LayerCreationKind.path => 'Path Layer',
      _LayerCreationKind.surface => 'Surface Layer',
      _LayerCreationKind.object => 'Object Layer',
      _LayerCreationKind.environment => 'Environment Layer',
    };
  }

  static MapLayerKind? _mapLayerKindFor(_LayerCreationKind k) {
    return switch (k) {
      _LayerCreationKind.tile => MapLayerKind.tile,
      _LayerCreationKind.collision => MapLayerKind.collision,
      _LayerCreationKind.terrain => MapLayerKind.terrain,
      _LayerCreationKind.path => MapLayerKind.path,
      // SurfaceLayer is deliberately kept as an editor creation option instead
      // of expanding MapLayerKind here; map_core already models the layer, but
      // the editor routes surface creation through addSurfaceLayer().
      _LayerCreationKind.surface => null,
      _LayerCreationKind.object => MapLayerKind.object,
      _LayerCreationKind.environment => MapLayerKind.environment,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final subtle = EditorChrome.subtleLabel(context);
    final content = map == null
        ? Center(
            child: Text(
              'No map loaded',
              style: TextStyle(color: subtle),
            ),
          )
        : _LayerList(
            map: map,
            activeLayerId: state.activeLayerId,
            notifier: notifier,
          );

    const layerAccent = EditorChrome.inspectorJoyBlue;

    if (embedded) {
      return Column(
        children: [
          _LayerActionsRow(
            map: map,
            notifier: notifier,
            accent: layerAccent,
            onAddLayer: () => _showAddLayerDialog(context, notifier),
            onDeleteAllLayers: () =>
                _showDeleteAllLayersDialog(context, notifier),
            compact: true,
          ),
          const SizedBox(height: 10),
          Expanded(child: content),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.islandFill(context),
      ),
      child: Column(
        children: [
          _LayerActionsRow(
            map: map,
            notifier: notifier,
            accent: layerAccent,
            onAddLayer: () => _showAddLayerDialog(context, notifier),
            onDeleteAllLayers: () =>
                _showDeleteAllLayersDialog(context, notifier),
          ),
          const EditorHorizontalDivider(),
          Expanded(child: content),
        ],
      ),
    );
  }

  Future<void> _showAddLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final nameController = TextEditingController();
    var selectedType = _LayerCreationKind.tile;
    var shouldSave = false;

    await showMacosEditorModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Layer',
              style: editorMacosSheetTitleStyle(ctx),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final picked =
                      await showCupertinoListPicker<_LayerCreationKind>(
                    context: ctx,
                    title: 'Layer type',
                    items: _LayerCreationKind.values,
                    labelOf: _kindLabel,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedType = picked;
                      if (picked == _LayerCreationKind.surface &&
                          nameController.text.trim().isEmpty) {
                        nameController.text = 'Surfaces';
                      }
                      if (picked == _LayerCreationKind.environment &&
                          nameController.text.trim().isEmpty) {
                        nameController.text = 'Environment';
                      }
                    });
                  }
                },
                child: Text('Type: ${_kindLabel(selectedType)}'),
              ),
            ),
            const SizedBox(height: 8),
            MacosTextField(
              controller: nameController,
              autofocus: true,
              placeholder: 'Name',
            ),
            if (selectedType == _LayerCreationKind.environment) ...[
              const SizedBox(height: 10),
              Text(
                'Zone auteur pour environnements organiques : forêts, bosquets, '
                'prairies, côtes rocheuses.',
                key: const Key('layers-panel-add-environment-description'),
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    shouldSave = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!shouldSave) return;
    if (selectedType == _LayerCreationKind.surface) {
      notifier.addSurfaceLayer(name: nameController.text.trim());
      return;
    }
    notifier.addMapLayer(
      kind: _mapLayerKindFor(selectedType)!,
      name: nameController.text.trim(),
    );
  }

  Future<void> _showDeleteAllLayersDialog(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Remove All Layers',
      message:
          'All current layers will be removed. The map can stay with zero layers.',
      primaryLabel: 'Remove All',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) return;
    notifier.deleteAllMapLayers();
  }
}

class _LayerActionsRow extends StatelessWidget {
  const _LayerActionsRow({
    required this.map,
    required this.notifier,
    required this.accent,
    required this.onAddLayer,
    required this.onDeleteAllLayers,
    this.compact = false,
  });

  final MapData? map;
  final EditorNotifier notifier;
  final Color accent;
  final VoidCallback onAddLayer;
  final VoidCallback onDeleteAllLayers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = Color.lerp(muted, accent, 0.42)!;
    return Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(8, 8, 8, 6)
          : const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              compact ? 'Layer Actions' : 'LAYERS',
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                letterSpacing: compact ? 0.4 : 1.0,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
          ),
          _LayersAccentIconButton(
            accent: accent,
            onPressed: map == null ? null : onAddLayer,
            icon: CupertinoIcons.add,
            tooltip: 'Add Layer',
            iconSize: 17,
          ),
          const SizedBox(width: 6),
          _LayersAccentIconButton(
            accent: accent,
            onPressed: map == null ? null : onDeleteAllLayers,
            icon: CupertinoIcons.trash_slash,
            tooltip: 'Remove All Layers',
            iconSize: 17,
          ),
        ],
      ),
    );
  }
}

class _LayerList extends StatelessWidget {
  const _LayerList({
    required this.map,
    required this.activeLayerId,
    required this.notifier,
  });

  final MapData map;
  final String? activeLayerId;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    const layerAccent = EditorChrome.inspectorJoyBlue;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    if (map.layers.isEmpty) {
      return Center(
        child: Text(
          'No layers in this map',
          style: TextStyle(color: subtle),
        ),
      );
    }

    final rows = buildLayerPanelPresentationRows(
      map,
      activeLayerId: activeLayerId,
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      itemCount: rows.length + 1,
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return DragTarget<String>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              notifier.moveMapLayerBeforeIndex(
                details.data,
                map.layers.length,
              );
            },
            builder: (context, candidateData, _) {
              final hovering = candidateData.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: SizedBox(
                  height: 14,
                  width: double.infinity,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      height: hovering ? 5 : 3,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: hovering
                            ? layerAccent.withValues(alpha: 0.85)
                            : subtle.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        final row = rows[index];
        final layer = row.layer;
        final isActive = row.isActive;
        final canMoveUp = row.layerIndex > 0;
        final canMoveDown = row.layerIndex < map.layers.length - 1;
        final canDeleteLayer = !row.isDeleteProtectedByEnvironmentAttachment;

        final inactiveFill = Color.lerp(
          EditorChrome.islandFillElevated(context),
          layerAccent,
          0.16,
        )!;
        final inactiveBorder = Color.lerp(
          EditorChrome.editorIslandRim(context),
          layerAccent,
          0.45,
        )!;
        final metaColor =
            Color.lerp(secondary, layerAccent, isActive ? 0.28 : 0.22)!;

        return DragTarget<String>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            notifier.moveMapLayerBeforeIndex(details.data, row.layerIndex);
          },
          builder: (context, candidateData, _) {
            final dropHovering = candidateData.isNotEmpty;
            return Padding(
              key: ValueKey(layer.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                decoration: dropHovering
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: layerAccent.withValues(alpha: 0.9),
                          width: 2,
                        ),
                      )
                    : null,
                padding:
                    dropHovering ? const EdgeInsets.all(2) : EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Draggable<String>(
                      data: layer.id,
                      axis: Axis.vertical,
                      affinity: Axis.vertical,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _dragFeedback(
                          context,
                          layer,
                          layerAccent,
                          label,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 6, 0),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: MacosIcon(
                              CupertinoIcons.line_horizontal_3,
                              size: 16,
                              color: metaColor,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 6, 0),
                        child: MacosTooltip(
                          message: 'Glisser pour réordonner',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Center(
                                child: MacosIcon(
                                  CupertinoIcons.line_horizontal_3,
                                  size: 16,
                                  color: metaColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isActive
                              ? Color.lerp(
                                  EditorChrome.islandFillElevated(context),
                                  layerAccent,
                                  0.36,
                                )!
                              : inactiveFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? layerAccent.withValues(alpha: 0.82)
                                : inactiveBorder,
                            width: 1,
                          ),
                          boxShadow:
                              EditorChrome.inspectorTileHardShadows(context),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                          child: Column(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                onPressed: () =>
                                    notifier.setActiveLayer(layer.id),
                                child: ClipRect(
                                  child: Row(
                                    children: [
                                      MacosIcon(
                                        _iconForLayer(layer),
                                        size: 16,
                                        color: isActive
                                            ? layerAccent
                                            : Color.lerp(
                                                secondary,
                                                layerAccent,
                                                0.55,
                                              )!,
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              layer.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isActive
                                                    ? layerAccent
                                                    : Color.lerp(
                                                        label,
                                                        layerAccent,
                                                        0.12,
                                                      )!,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_labelForLayer(layer)} • ${layer.id}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: metaColor,
                                              ),
                                            ),
                                            if (row.environmentAttachmentLabel !=
                                                null) ...[
                                              const SizedBox(height: 4),
                                              _LayerStatusText(
                                                row.environmentAttachmentLabel!,
                                                color: metaColor,
                                              ),
                                            ],
                                            if (row.technicalEnvironmentSelectionLabel !=
                                                null) ...[
                                              const SizedBox(height: 3),
                                              _LayerStatusText(
                                                row.technicalEnvironmentSelectionLabel!,
                                                color: metaColor,
                                              ),
                                            ],
                                            if (row.environmentWarningLabel !=
                                                null) ...[
                                              const SizedBox(height: 3),
                                              _LayerStatusText(
                                                row.environmentWarningLabel!,
                                                color: CupertinoColors
                                                    .systemOrange
                                                    .resolveFrom(context),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: () =>
                                            notifier.setMapLayerVisibility(
                                          layer.id,
                                          !layer.isVisible,
                                        ),
                                        icon: layer.isVisible
                                            ? CupertinoIcons.eye
                                            : CupertinoIcons.eye_slash,
                                        tooltip: layer.isVisible
                                            ? 'Hide layer'
                                            : 'Show layer',
                                        iconSize: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: canMoveUp
                                            ? () => notifier
                                                .moveMapLayerUp(layer.id)
                                            : null,
                                        icon: CupertinoIcons.arrow_up,
                                        tooltip: 'Move up',
                                        iconSize: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: canMoveDown
                                            ? () => notifier
                                                .moveMapLayerDown(layer.id)
                                            : null,
                                        icon: CupertinoIcons.arrow_down,
                                        tooltip: 'Move down',
                                        iconSize: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: () => _showRenameLayerDialog(
                                          context,
                                          notifier,
                                          layer,
                                        ),
                                        icon: CupertinoIcons.pencil,
                                        tooltip: 'Rename layer',
                                        iconSize: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      _LayersAccentIconButton(
                                        key: ValueKey(
                                          'delete-layer-${layer.id}',
                                        ),
                                        accent: layerAccent,
                                        onPressed: canDeleteLayer
                                            ? () => _showDeleteLayerDialog(
                                                  context,
                                                  notifier,
                                                  layer,
                                                )
                                            : null,
                                        icon: CupertinoIcons.trash,
                                        tooltip: canDeleteLayer
                                            ? 'Delete layer'
                                            : 'Suppression protégée : environnement attaché',
                                        iconSize: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dragFeedback(
    BuildContext context,
    MapLayer layer,
    Color layerAccent,
    Color label,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: layerAccent.withValues(alpha: 0.82),
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MacosIcon(
              _iconForLayer(layer),
              size: 16,
              color: layerAccent,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                layer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => CupertinoIcons.square_grid_2x2,
      collision: (_) => CupertinoIcons.shield,
      terrain: (_) => CupertinoIcons.tree,
      path: (_) => CupertinoIcons.map,
      // Surface painting/rendering is a later lot; the editor lists it
      // neutrally so maps containing SurfaceLayer do not break the panel.
      surface: (_) => CupertinoIcons.map,
      object: (_) => CupertinoIcons.square_stack_3d_up,
      environment: (_) => CupertinoIcons.cloud,
    );
  }

  String _labelForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => 'tile',
      collision: (_) => 'collision',
      terrain: (_) => 'terrain',
      path: (_) => 'path',
      surface: (surfaceLayer) =>
          'surface · ${surfaceLayer.placements.length} placement(s)',
      object: (_) => 'object',
      environment: (el) => 'environment · ${el.content.areaCount} area(s)',
    );
  }

  Future<void> _showRenameLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
    MapLayer layer,
  ) async {
    final controller = TextEditingController(text: layer.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Rename Layer',
      controller: controller,
      placeholder: 'Name',
      confirmLabel: 'Save',
    );
    if (!ok) return;
    notifier.renameMapLayer(layer.id, controller.text.trim());
  }

  Future<void> _showDeleteLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
    MapLayer layer,
  ) async {
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Delete Layer',
      message: 'Delete "${layer.name}"?',
      primaryLabel: 'Delete',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) return;
    notifier.deleteMapLayer(layer.id);
  }
}

class _LayerStatusText extends StatelessWidget {
  const _LayerStatusText(
    this.text, {
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

/// Pastilles icônes chaudes / acides, cohérentes avec la tuile « Layers ».
class _LayersAccentIconButton extends StatefulWidget {
  const _LayersAccentIconButton({
    super.key,
    required this.accent,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.iconSize = 15,
  });

  final Color accent;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final double iconSize;

  @override
  State<_LayersAccentIconButton> createState() =>
      _LayersAccentIconButtonState();
}

class _LayersAccentIconButtonState extends State<_LayersAccentIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final a = widget.accent;
    final bg = !enabled
        ? a.withValues(alpha: 0.08)
        : _hovered
            ? Color.lerp(a, const Color(0xFFFFF2E6), 0.4)!
            : Color.lerp(a, const Color(0xFF1A0C04), 0.52)!;
    final iconColor = enabled
        ? CupertinoColors.white
        : CupertinoColors.inactiveGray.resolveFrom(context);

    Widget core = MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: a.withValues(alpha: enabled ? 0.75 : 0.22),
              width: 1,
            ),
          ),
          child: MacosIcon(
            widget.icon,
            size: widget.iconSize,
            color: iconColor,
          ),
        ),
      ),
    );

    final tip = widget.tooltip;
    if (tip != null && tip.isNotEmpty) {
      return MacosTooltip(message: tip, child: core);
    }
    return core;
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Draggable, DragTarget, Material, MaterialType;
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
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
  border,
}

class LayersPanel extends ConsumerWidget {
  const LayersPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  static String _kindLabel(_LayerCreationKind k) {
    return switch (k) {
      _LayerCreationKind.tile => 'Couche de tuiles (Tile)',
      _LayerCreationKind.collision => 'Couche de collision',
      _LayerCreationKind.terrain => 'Couche de terrain',
      _LayerCreationKind.path => 'Couche de chemin (Path)',
      _LayerCreationKind.surface => 'Couche de surface',
      _LayerCreationKind.object => 'Couche d\'objets',
      _LayerCreationKind.environment => 'Couche d\'environnement',
      _LayerCreationKind.border => 'Couche de bordures',
    };
  }

  static MapLayerKind? _mapLayerKindFor(_LayerCreationKind k) {
    return switch (k) {
      _LayerCreationKind.tile => MapLayerKind.tile,
      _LayerCreationKind.collision => MapLayerKind.collision,
      _LayerCreationKind.terrain => MapLayerKind.terrain,
      _LayerCreationKind.path => MapLayerKind.path,
      _LayerCreationKind.surface => null,
      _LayerCreationKind.object => MapLayerKind.object,
      _LayerCreationKind.environment => MapLayerKind.environment,
      _LayerCreationKind.border => MapLayerKind.border,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final colors = context.pokeMapColors;

    final content = map == null
        ? Center(
            child: Text(
              'Aucune carte chargée',
              style: TextStyle(color: colors.textMuted),
            ),
          )
        : _LayerList(
            map: map,
            activeLayerId: state.activeLayerId,
            notifier: notifier,
          );

    if (embedded) {
      return Column(
        children: [
          _LayerActionsRow(
            map: map,
            notifier: notifier,
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
        color: colors.backgroundShell,
      ),
      child: Column(
        children: [
          _LayerActionsRow(
            map: map,
            notifier: notifier,
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
              'Ajouter un calque',
              style: editorMacosSheetTitleStyle(ctx),
            ),
            const SizedBox(height: 16),
            PokeMapDropdownField<_LayerCreationKind>(
              key: const ValueKey<String>('layers-panel-add-type-dropdown'),
              label: 'Type',
              value: selectedType,
              items: [
                for (final kind in _LayerCreationKind.values)
                  PokeMapDropdownItem<_LayerCreationKind>(
                    value: kind,
                    label: _kindLabel(kind),
                  ),
              ],
              onChanged: (picked) {
                setState(() {
                  selectedType = picked;
                  if (picked == _LayerCreationKind.surface &&
                      nameController.text.trim().isEmpty) {
                    nameController.text = 'Surfaces';
                  }
                  if (picked == _LayerCreationKind.environment &&
                      nameController.text.trim().isEmpty) {
                    nameController.text = 'Environnement';
                  }
                  if (picked == _LayerCreationKind.border &&
                      nameController.text.trim().isEmpty) {
                    nameController.text = 'Bordures';
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            MacosTextField(
              controller: nameController,
              autofocus: true,
              placeholder: 'Nom',
            ),
            if (selectedType == _LayerCreationKind.environment) ...[
              const SizedBox(height: 10),
              Text(
                'Zone auteur pour environnements organiques : forêts, bosquets, '
                'prairies, côtes rocheuses.',
                key: const Key('layers-panel-add-environment-description'),
                style: TextStyle(
                  color: ctx.pokeMapColors.textSecondary,
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
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 10),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    shouldSave = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Ajouter'),
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
      title: 'Supprimer tous les calques',
      message:
          'Tous les calques actuels seront supprimés. La carte peut rester sans aucun calque.',
      primaryLabel: 'Supprimer tout',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) return;
    notifier.deleteAllMapLayers(confirmBulkPlacementLoss: true);
  }
}

class _LayerActionsRow extends StatelessWidget {
  const _LayerActionsRow({
    required this.map,
    required this.notifier,
    required this.onAddLayer,
    required this.onDeleteAllLayers,
    this.compact = false,
  });

  final MapData? map;
  final EditorNotifier notifier;
  final VoidCallback onAddLayer;
  final VoidCallback onDeleteAllLayers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(8, 8, 8, 6)
          : const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              compact ? 'Actions du calque' : 'CALQUES',
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                letterSpacing: compact ? 0.4 : 1.0,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
          ),
          PokeMapIconButton(
            onPressed: map == null ? null : onAddLayer,
            icon: const Icon(CupertinoIcons.add),
            tooltip: 'Ajouter un calque',
          ),
          const SizedBox(width: 6),
          PokeMapIconButton(
            onPressed: map == null ? null : onDeleteAllLayers,
            icon: const Icon(CupertinoIcons.trash_slash),
            tooltip: 'Supprimer tous les calques',
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
    final colors = context.pokeMapColors;

    if (map.layers.isEmpty) {
      return Center(
        child: Text(
          'Aucun calque sur cette carte',
          style: TextStyle(color: colors.textMuted),
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
            key: const ValueKey('drop-layer-group-at-end'),
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              notifier.moveMapLayerGroupBeforeVisibleIndex(
                details.data,
                rows.length,
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
                            ? colors.brandPrimary
                            : colors.textMuted.withValues(alpha: 0.35),
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
        final canMoveUp = row.groupIndex > 0;
        final canMoveDown = row.groupIndex < rows.length - 1;
        final canDeleteLayer = !row.isDeleteProtectedByEnvironmentAttachment;

        return DragTarget<String>(
          key: ValueKey('drop-layer-group-before-${layer.id}'),
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            notifier.moveMapLayerGroupBeforeVisibleIndex(
              details.data,
              row.groupIndex,
            );
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
                          color: colors.brandPrimary,
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
                      key: ValueKey('drag-layer-group-${layer.id}'),
                      data: layer.id,
                      axis: Axis.vertical,
                      affinity: Axis.vertical,
                      feedback: Material(
                        type: MaterialType.transparency,
                        child: _dragFeedback(
                          context,
                          layer,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 6, 0),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: Icon(
                              CupertinoIcons.line_horizontal_3,
                              size: 16,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 6, 0),
                        child: MacosTooltip(
                          message: 'Faites glisser pour réordonner',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.line_horizontal_3,
                                  size: 16,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        key: ValueKey('layer-row-semantics-${layer.id}'),
                        container: true,
                        selected: isActive,
                        label: _layerRowSemanticsLabel(
                          row,
                          visibleIndex: index,
                          visibleCount: rows.length,
                        ),
                        child: PokeMapCard(
                          selected: isActive,
                          backgroundColor: isActive
                              ? colors.surfaceSelected
                              : colors.surfaceSubtle,
                          borderRadius: 8,
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                          child: ClipRect(
                            child: _buildLayerRowHeader(
                              context: context,
                              row: row,
                              notifier: notifier,
                              canMoveUp: canMoveUp,
                              canMoveDown: canMoveDown,
                              canDeleteLayer: canDeleteLayer,
                            ),
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

  Widget _buildLayerRowHeader({
    required BuildContext context,
    required LayerPanelPresentationRow row,
    required EditorNotifier notifier,
    required bool canMoveUp,
    required bool canMoveDown,
    required bool canDeleteLayer,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;
        final identity = PokeMapButton(
          key: ValueKey('select-layer-${row.layer.id}'),
          onPressed: () => notifier.setActiveLayer(row.layer.id),
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.small,
          isSelected: row.isActive,
          child: _buildLayerIdentity(context, row),
        );
        final actions = _buildLayerActions(
          context: context,
          row: row,
          notifier: notifier,
          canMoveUp: canMoveUp,
          canMoveDown: canMoveDown,
          canDeleteLayer: canDeleteLayer,
          wrap: compact,
        );
        final details = _buildLayerDetails(context, row.layer);
        final statuses = _buildLayerStatusBadges(row);
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: 2),
              details,
              if (statuses != null) ...[
                const SizedBox(height: 5),
                statuses,
              ],
              const SizedBox(height: 5),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 4),
                actions,
              ],
            ),
            const SizedBox(height: 2),
            details,
            if (statuses != null) ...[
              const SizedBox(height: 5),
              statuses,
            ],
          ],
        );
      },
    );
  }

  Widget _buildLayerIdentity(
    BuildContext context,
    LayerPanelPresentationRow row,
  ) {
    final colors = context.pokeMapColors;
    final layer = row.layer;
    return Row(
      children: [
        Icon(
          _iconForLayer(layer),
          size: 16,
          color: row.isActive ? colors.brandPrimary : colors.textSecondary,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            layer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: row.isActive ? FontWeight.w600 : FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayerDetails(
    BuildContext context,
    MapLayer layer,
  ) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        '${_labelForLayer(layer)} • ${layer.id}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, color: colors.textMuted),
      ),
    );
  }

  Widget? _buildLayerStatusBadges(LayerPanelPresentationRow row) {
    final badges = <Widget>[
      if (row.environmentAttachmentLabel != null)
        PokeMapBadge(
          label: row.environmentAttachmentLabel!,
          variant: PokeMapBadgeVariant.mapAccent,
        ),
      if (row.technicalEnvironmentSelectionLabel != null)
        PokeMapBadge(
          label: row.technicalEnvironmentSelectionLabel!,
          variant: PokeMapBadgeVariant.info,
        ),
      if (row.environmentWarningLabel != null)
        PokeMapBadge(
          label: row.environmentWarningLabel!,
          variant: PokeMapBadgeVariant.warning,
        ),
    ];
    if (badges.isEmpty) {
      return null;
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: badges,
    );
  }

  Widget _buildLayerActions({
    required BuildContext context,
    required LayerPanelPresentationRow row,
    required EditorNotifier notifier,
    required bool canMoveUp,
    required bool canMoveDown,
    required bool canDeleteLayer,
    required bool wrap,
  }) {
    final layer = row.layer;
    final buttons = <Widget>[
      PokeMapIconButton(
        onPressed: () =>
            notifier.setMapLayerVisibility(layer.id, !layer.isVisible),
        icon: Icon(
          layer.isVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
        ),
        tooltip: layer.isVisible ? 'Masquer le calque' : 'Afficher le calque',
        size: 26,
      ),
      PokeMapIconButton(
        key: ValueKey('move-layer-up-${layer.id}'),
        onPressed:
            canMoveUp ? () => notifier.moveMapLayerGroupUp(layer.id) : null,
        icon: const Icon(CupertinoIcons.arrow_up),
        tooltip: 'Monter le calque',
        size: 26,
      ),
      PokeMapIconButton(
        key: ValueKey('move-layer-down-${layer.id}'),
        onPressed:
            canMoveDown ? () => notifier.moveMapLayerGroupDown(layer.id) : null,
        icon: const Icon(CupertinoIcons.arrow_down),
        tooltip: 'Descendre le calque',
        size: 26,
      ),
      PokeMapIconButton(
        onPressed: () => _showRenameLayerDialog(context, notifier, layer),
        icon: const Icon(CupertinoIcons.pencil),
        tooltip: 'Renommer le calque',
        size: 26,
      ),
      PokeMapIconButton(
        key: ValueKey('delete-layer-${layer.id}'),
        onPressed: canDeleteLayer
            ? () => _showDeleteLayerDialog(context, notifier, layer)
            : null,
        icon: const Icon(CupertinoIcons.trash),
        tooltip: canDeleteLayer
            ? 'Supprimer le calque'
            : 'Suppression protégée : environnement attaché',
        variant: PokeMapIconButtonVariant.danger,
        size: 26,
      ),
    ];
    if (wrap) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 2,
        runSpacing: 2,
        children: buttons,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < buttons.length; index++) ...[
          if (index > 0) const SizedBox(width: 2),
          buttons[index],
        ],
      ],
    );
  }

  Widget _dragFeedback(
    BuildContext context,
    MapLayer layer,
  ) {
    final colors = context.pokeMapColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: PokeMapCard(
        selected: true,
        backgroundColor: colors.surfaceRaised,
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForLayer(layer),
              size: 16,
              color: colors.brandPrimary,
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
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _layerRowSemanticsLabel(
    LayerPanelPresentationRow row, {
    required int visibleIndex,
    required int visibleCount,
  }) {
    final parts = <String>[
      row.layer.name,
      _labelForLayer(row.layer),
      'position ${visibleIndex + 1} sur $visibleCount',
    ];
    final attachmentCount = row.attachedEnvironmentLayerIds.length;
    if (attachmentCount == 1) {
      parts.add('groupe avec 1 environnement attaché');
    } else if (attachmentCount > 1) {
      parts.add('groupe avec $attachmentCount environnements attachés');
    }
    if (row.technicalEnvironmentSelectionLabel != null) {
      parts.add(row.technicalEnvironmentSelectionLabel!);
    }
    if (row.environmentWarningLabel != null) {
      parts.add(row.environmentWarningLabel!);
    }
    return parts.join(', ');
  }

  IconData _iconForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => CupertinoIcons.square_grid_2x2,
      collision: (_) => CupertinoIcons.shield,
      terrain: (_) => CupertinoIcons.tree,
      path: (_) => CupertinoIcons.map,
      surface: (_) => CupertinoIcons.map,
      object: (_) => CupertinoIcons.square_stack_3d_up,
      environment: (_) => CupertinoIcons.cloud,
      border: (_) => CupertinoIcons.waveform_path,
    );
  }

  String _labelForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => 'tuiles',
      collision: (_) => 'collision',
      terrain: (_) => 'terrain',
      path: (_) => 'chemin',
      surface: (surfaceLayer) =>
          'surface · ${surfaceLayer.placements.length} placement(s)',
      object: (_) => 'objets',
      environment: (el) => 'environnement · ${el.content.areaCount} zone(s)',
      border: (borderLayer) =>
          'bordure · ${borderLayer.content.features.length} tracé(s)',
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
      title: 'Renommer le calque',
      controller: controller,
      placeholder: 'Nom',
      confirmLabel: 'Enregistrer',
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
      title: 'Supprimer le calque',
      message: 'Supprimer le calque « ${layer.name} » ?',
      primaryLabel: 'Supprimer',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) return;
    notifier.deleteMapLayer(layer.id);
  }
}

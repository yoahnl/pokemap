import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/layers_panel_presentation.dart';
import '../../application/map_context_target.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import '../../../../ui/canvas/map_canvas.dart';
import 'world_map_layer_mutation_dialogs.dart';
import 'world_map_layer_hover_preview.dart';
import 'world_map_paint_inspection_intent.dart';
import 'world_map_workspace_session.dart';

enum WorldMapLayerCreationKind {
  tile,
  collision,
  smartTerrain,
  smartPath,
  smartSurface,
  object,
  environment,
  border,
}

@immutable
final class WorldMapLayerContextMenuRequest {
  const WorldMapLayerContextMenuRequest({
    required this.target,
    required this.globalPosition,
    required this.invocation,
    required this.invokerFocusNode,
  });

  final MapLayerContextTarget target;
  final Offset globalPosition;
  final MapContextMenuInvocation invocation;
  final FocusNode invokerFocusNode;
}

typedef WorldMapLayerContextMenuRequested
    = ValueChanged<WorldMapLayerContextMenuRequest>;

const _allLayerTypesFilter = '__all_layer_types__';

class WorldMapLayersInspector extends ConsumerStatefulWidget {
  const WorldMapLayersInspector({
    super.key,
    this.onRenameRequested = showWorldMapLayerRenameDialog,
    this.onDeleteRequested = showWorldMapLayerDeleteDialog,
    this.onContextMenuRequested,
  });

  final WorldMapLayerRenameRequested onRenameRequested;
  final WorldMapLayerDeleteRequested onDeleteRequested;
  final WorldMapLayerContextMenuRequested? onContextMenuRequested;

  @override
  ConsumerState<WorldMapLayersInspector> createState() =>
      _WorldMapLayersInspectorState();
}

final class _WorldMapLayersInspectorState
    extends ConsumerState<WorldMapLayersInspector> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _typeFilter = _allLayerTypesFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _typeFilter = _allLayerTypesFilter;
    });
  }

  void _openLayerEditor({
    required EditorNotifier notifier,
    required WorldMapWorkspaceSessionController session,
    required MapLayer layer,
    bool ownsEnvironment = false,
  }) {
    final paintInspectionIntent =
        ref.read(worldMapPaintInspectionIntentProvider.notifier);
    // A layer carrying an environment is authored as an environment, whatever
    // the storage says it is underneath.
    if (ownsEnvironment) {
      paintInspectionIntent.clear();
      session.setActiveLayer(notifier, layer.id);
      session.pinInspector(WorldMapInspectorKind.environment);
      return;
    }
    final subtool = _paintSubtoolForLayer(layer);
    if (subtool == null) {
      paintInspectionIntent.clear();
      session.setActiveLayer(notifier, layer.id);
      return;
    }

    session.pinInspector(null);
    final routing = session.routePaintSubtool(
      notifier,
      subtool,
      chosenLayerId: layer.id,
    );
    final mapId = ref.read(editorNotifierProvider).activeMap?.id;
    switch (routing.outcome) {
      case WorldMapPaintRoutingOutcome.activated:
        paintInspectionIntent.clear();
      case WorldMapPaintRoutingOutcome.setupRequired:
        final targetLayerId = routing.layerId;
        if (mapId != null && targetLayerId != null) {
          paintInspectionIntent.showSetup(
            mapId: mapId,
            layerId: targetLayerId,
            subtool: subtool,
          );
        }
      case WorldMapPaintRoutingOutcome.choiceRequired:
        if (mapId != null) {
          paintInspectionIntent.showLayerChoice(
            mapId: mapId,
            subtool: subtool,
            compatibleLayerIds: routing.compatibleLayerIds,
          );
        }
      case WorldMapPaintRoutingOutcome.missingLayer:
        if (mapId != null) {
          paintInspectionIntent.showMissingLayer(
            mapId: mapId,
            subtool: subtool,
          );
        }
      case WorldMapPaintRoutingOutcome.rejected:
        paintInspectionIntent.clear();
    }
    session.setInspectorVisible(true);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          map: state.activeMap,
          activeLayerId: state.activeLayerId,
          project: state.project,
        ),
      ),
    );
    final notifier = ref.read(editorNotifierProvider.notifier);
    final session = ref.read(worldMapWorkspaceSessionProvider.notifier);
    final map = snapshot.map;
    if (map == null) {
      return const PokeMapEmptyState(
        icon: Icon(Icons.layers_clear_outlined),
        title: 'Aucune carte chargée',
        description: 'Ouvrez une carte pour gérer ses calques.',
      );
    }
    final rows = buildLayerPanelPresentationRows(
      map,
      activeLayerId: snapshot.activeLayerId,
    );
    final availableTypes = <String>[];
    for (final row in rows) {
      final label = _layerTypeLabel(
        row.layer,
        hasAttachedEnvironment: row.hasAttachedEnvironmentLayers,
      );
      if (!availableTypes.contains(label)) availableTypes.add(label);
    }
    final effectiveTypeFilter = availableTypes.contains(_typeFilter)
        ? _typeFilter
        : _allLayerTypesFilter;
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleRows = rows.where((row) {
      final typeLabel = _layerTypeLabel(
        row.layer,
        hasAttachedEnvironment: row.hasAttachedEnvironmentLayers,
      );
      if (effectiveTypeFilter != _allLayerTypesFilter &&
          typeLabel != effectiveTypeFilter) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;
      return '${row.layer.name} ${row.layer.id} $typeLabel'
          .toLowerCase()
          .contains(normalizedQuery);
    }).toList(growable: false);
    final filtersActive = normalizedQuery.isNotEmpty ||
        effectiveTypeFilter != _allLayerTypesFilter;

    return Semantics(
      container: true,
      label: 'Calques de la carte, du premier plan vers l’arrière-plan',
      child: CustomScrollView(
        key: const ValueKey<String>('world-map-layer-list'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PokeMapSectionHeader(
                    title: 'Calques',
                    description: filtersActive
                        ? _filteredLayerCountLabel(
                            visible: visibleRows.length,
                            total: rows.length,
                          )
                        : rows.length == 1
                            ? '1 groupe de calques'
                            : '${rows.length} groupes de calques',
                    trailing: PokeMapSplitButton<WorldMapLayerCreationKind>(
                      key: const ValueKey<String>('world-map-layer-add'),
                      onPressed: () => _addLayer(
                        notifier,
                        WorldMapLayerCreationKind.tile,
                      ),
                      items: [
                        for (final kind in WorldMapLayerCreationKind.values)
                          PokeMapMenuItem<WorldMapLayerCreationKind>(
                            value: kind,
                            label: _creationKindLabel(kind),
                          ),
                      ],
                      onSelected: (kind) {
                        final smartTileUsage = switch (kind) {
                          WorldMapLayerCreationKind.smartTerrain =>
                            SmartTileUsage.terrain,
                          WorldMapLayerCreationKind.smartPath =>
                            SmartTileUsage.path,
                          WorldMapLayerCreationKind.smartSurface =>
                            SmartTileUsage.forestSurface,
                          _ => null,
                        };
                        if (smartTileUsage != null) {
                          unawaited(
                            _addSmartTileLayerFromPreset(
                              context: context,
                              ref: ref,
                              notifier: notifier,
                              session: session,
                              project: snapshot.project,
                              expectedMapId: map.id,
                              usage: smartTileUsage,
                              subtool: smartTileUsage == SmartTileUsage.terrain
                                  ? WorldMapPaintSubtool.terrain
                                  : smartTileUsage == SmartTileUsage.path
                                      ? WorldMapPaintSubtool.path
                                      : WorldMapPaintSubtool.surface,
                            ),
                          );
                          return;
                        }
                        _addLayer(notifier, kind);
                      },
                      tooltip: 'Ajouter un calque de tuiles',
                      menuTooltip: 'Choisir le type de calque',
                      child: const Text('Ajouter'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final search = PokeMapSearchField(
                        key: const ValueKey<String>(
                          'world-map-layer-search',
                        ),
                        controller: _searchController,
                        hintText: 'Rechercher un calque…',
                        semanticLabel: 'Rechercher dans les calques',
                        onChanged: (value) => setState(() => _query = value),
                      );
                      final typeFilter = PokeMapDropdownField<String>(
                        key: const ValueKey<String>(
                          'world-map-layer-type-filter',
                        ),
                        label: 'Type de calque',
                        value: effectiveTypeFilter,
                        compact: true,
                        items: <PokeMapDropdownItem<String>>[
                          const PokeMapDropdownItem<String>(
                            value: _allLayerTypesFilter,
                            label: 'Tous les types',
                          ),
                          for (final type in availableTypes)
                            PokeMapDropdownItem<String>(
                              value: type,
                              label: type,
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _typeFilter = value),
                      );
                      if (constraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            search,
                            const SizedBox(height: 6),
                            typeFilter,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: search),
                          const SizedBox(width: 8),
                          SizedBox(width: 170, child: typeFilter),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (visibleRows.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              sliver: SliverToBoxAdapter(
                child: PokeMapEmptyState(
                  key: const ValueKey<String>('world-map-layer-filter-empty'),
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  title: 'Aucun calque trouvé',
                  description:
                      'Modifiez la recherche ou réinitialisez les filtres.',
                  compact: true,
                  action: PokeMapButton(
                    key: const ValueKey<String>('world-map-layer-filter-reset'),
                    onPressed: _resetFilters,
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.restart_alt_rounded),
                    child: const Text('Réinitialiser'),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              sliver: SliverReorderableList(
                itemCount: visibleRows.length,
                onReorderItem: (oldIndex, newIndex) {
                  if (filtersActive) return;
                  final beforeVisibleIndex =
                      newIndex > oldIndex ? newIndex + 1 : newIndex;
                  notifier.moveMapLayerGroupBeforeVisibleIndex(
                    visibleRows[oldIndex].layer.id,
                    beforeVisibleIndex,
                  );
                },
                itemBuilder: (context, index) {
                  final row = visibleRows[index];
                  return Padding(
                    key: ValueKey<String>(
                      'world-map-layer-row-${row.layer.id}',
                    ),
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                    child: _WorldMapLayerRow(
                      row: row,
                      reorderIndex: index,
                      notifier: notifier,
                      onActivate: () => _openLayerEditor(
                        notifier: notifier,
                        session: session,
                        layer: row.layer,
                        ownsEnvironment: row.hasAttachedEnvironmentLayers,
                      ),
                      readActiveMap: () =>
                          ref.read(editorNotifierProvider).activeMap,
                      onRenameRequested: widget.onRenameRequested,
                      onDeleteRequested: widget.onDeleteRequested,
                      onContextMenuRequested: widget.onContextMenuRequested,
                      reorderingDisabledByFilter: filtersActive,
                    ),
                  );
                },
              ),
            ),
          const SliverPadding(
            padding: EdgeInsets.all(10),
            sliver: SliverToBoxAdapter(
              child: PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.info,
                title: 'Calque d’environnement',
                message: 'Zone auteur pour environnements organiques : forêts, '
                    'bosquets, prairies, côtes rocheuses.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _filteredLayerCountLabel({
  required int visible,
  required int total,
}) {
  if (visible == 1) return '1 calque affiché sur $total';
  return '$visible calques affichés sur $total';
}

WorldMapPaintSubtool? _paintSubtoolForLayer(MapLayer layer) {
  return switch (layer) {
    TileLayer() => WorldMapPaintSubtool.tile,
    SmartTileLayer(:final usage) => switch (usage) {
        SmartTileUsage.terrain => WorldMapPaintSubtool.terrain,
        SmartTileUsage.path => WorldMapPaintSubtool.path,
        SmartTileUsage.forestSurface => WorldMapPaintSubtool.surface,
      },
    BorderLayer() => WorldMapPaintSubtool.border,
    CollisionLayer() => WorldMapPaintSubtool.collision,
    _ => null,
  };
}

final class _WorldMapLayerRow extends ConsumerWidget {
  const _WorldMapLayerRow({
    required this.row,
    required this.reorderIndex,
    required this.notifier,
    required this.onActivate,
    required this.readActiveMap,
    required this.onRenameRequested,
    required this.onDeleteRequested,
    required this.onContextMenuRequested,
    required this.reorderingDisabledByFilter,
  });

  final LayerPanelPresentationRow row;
  final int reorderIndex;
  final EditorNotifier notifier;
  final VoidCallback onActivate;
  final MapData? Function() readActiveMap;
  final WorldMapLayerRenameRequested onRenameRequested;
  final WorldMapLayerDeleteRequested onDeleteRequested;
  final WorldMapLayerContextMenuRequested? onContextMenuRequested;
  final bool reorderingDisabledByFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layer = row.layer;
    final layerId = layer.id;
    Widget buildTypeLabel() => PokeMapStatusLabel(
          key: ValueKey<String>('world-map-layer-type-$layerId'),
          label: _layerTypeLabel(
            layer,
            hasAttachedEnvironment: row.hasAttachedEnvironmentLayers,
          ),
          tone: _layerTone(
            layer,
            hasAttachedEnvironment: row.hasAttachedEnvironmentLayers,
          ),
        );
    Widget buildOpacitySlider() => PokeMapGuidedSlider(
          key: ValueKey<String>('world-map-layer-opacity-$layerId'),
          label: 'Opacité',
          layout: PokeMapGuidedSliderLayout.inline,
          value: (layer.opacity * 100).round(),
          onChangeStart:
              row.opacity.enabled ? (_) => notifier.beginMapStroke() : null,
          onChanged: row.opacity.enabled
              ? (value) => notifier.setMapLayerOpacity(
                    layerId,
                    value / 100,
                    partOfStroke: true,
                  )
              : (_) {},
          onChangeEnd:
              row.opacity.enabled ? (_) => notifier.endMapStroke() : null,
        );
    Widget buildDragHandle() {
      final enabled = !reorderingDisabledByFilter;
      return Tooltip(
        message: enabled
            ? 'Faites glisser pour réordonner'
            : 'Réinitialisez les filtres pour réordonner',
        child: ReorderableDragStartListener(
          key: ValueKey<String>('world-map-layer-drag-handle-$layerId'),
          index: reorderIndex,
          enabled: enabled,
          child: MouseRegion(
            cursor:
                enabled ? SystemMouseCursors.grab : SystemMouseCursors.basic,
            child: Semantics(
              label: 'Réordonner le calque ${layer.name}',
              enabled: enabled,
              child: SizedBox.square(
                dimension: 28,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: enabled
                      ? context.pokeMapColors.textMuted
                      : context.pokeMapColors.textDisabled,
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> buildReorderActions() => [
          PokeMapIconButton(
            key: ValueKey<String>('world-map-layer-move-up-$layerId'),
            tooltip: reorderingDisabledByFilter
                ? 'Réinitialisez les filtres pour réordonner'
                : row.moveUp.disabledReason ?? 'Monter le calque',
            onPressed: row.moveUp.enabled && !reorderingDisabledByFilter
                ? () => notifier.moveMapLayerGroupUp(layerId)
                : null,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
          const SizedBox(width: 4),
          PokeMapIconButton(
            key: ValueKey<String>('world-map-layer-move-down-$layerId'),
            tooltip: reorderingDisabledByFilter
                ? 'Réinitialisez les filtres pour réordonner'
                : row.moveDown.disabledReason ?? 'Descendre le calque',
            onPressed: row.moveDown.enabled && !reorderingDisabledByFilter
                ? () => notifier.moveMapLayerGroupDown(layerId)
                : null,
            icon: const Icon(Icons.arrow_downward_rounded),
          ),
        ];
    // An Environment layer is useless until it names the TileLayer it
    // decorates, and a TileLayer needs a way to grow one in the first place.
    // Both controls live here because the layer list is where the author
    // already selects what to work on.
    List<Widget> buildEnvironmentActions(BuildContext context) {
      if (layer is EnvironmentLayer) {
        final hasTarget = row.environmentTargetPendingLabel == null &&
            row.environmentWarningLabel == null;
        return <Widget>[
          const SizedBox(height: 6),
          PokeMapButton(
            key: ValueKey<String>('world-map-layer-environment-target-$layerId'),
            onPressed: () => _pickEnvironmentTarget(context, layerId),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.compact,
            leading: const Icon(Icons.adjust_outlined),
            child: Text(
              hasTarget
                  ? 'Changer de TileLayer cible'
                  : 'Choisir le TileLayer cible',
            ),
          ),
        ];
      }
      return const <Widget>[];
    }

    // Growing an environment is offered as an icon on the selected TileLayer:
    // a full-width button here would break the compact row rhythm the list
    // relies on to stay scannable.
    Widget? buildEnableEnvironmentAction() {
      if (layer is! TileLayer ||
          !row.isActive ||
          row.hasAttachedEnvironmentLayers) {
        return null;
      }
      return PokeMapIconButton(
        key: ValueKey<String>('world-map-layer-environment-enable-$layerId'),
        tooltip: 'Activer l’environnement sur ce calque',
        onPressed: notifier.enableEnvironmentForActiveTileLayer,
        icon: const Icon(Icons.park_outlined),
      );
    }

    final card = Semantics(
      key: ValueKey<String>('world-map-layer-semantics-$layerId'),
      container: true,
      selected: row.isActive,
      label: [
        layer.name,
        'Type ${_layerTypeLabel(layer, hasAttachedEnvironment: row.hasAttachedEnvironmentLayers)}',
        if (row.technicalEnvironmentSelectionLabel case final label?) label,
      ].join(', '),
      child: PokeMapPanel(
        key: ValueKey<String>('world-map-layer-card-$layerId'),
        borderRadius: 8,
        accentTone: _layerTone(
          layer,
          hasAttachedEnvironment: row.hasAttachedEnvironmentLayers,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final usesNarrowLayout = constraints.maxWidth < 300;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    buildDragHandle(),
                    Expanded(
                      child: PokeMapButton(
                        key: ValueKey<String>(
                            'world-map-layer-activate-$layerId'),
                        onPressed: row.activation.enabled ? onActivate : null,
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.compact,
                        isSelected: row.isActive,
                        leading: row.isActive
                            ? Icon(
                                Icons.check_circle_rounded,
                                key: ValueKey<String>(
                                  'world-map-layer-active-$layerId',
                                ),
                              )
                            : Icon(
                                _layerIcon(
                                  layer,
                                  hasAttachedEnvironment:
                                      row.hasAttachedEnvironmentLayers,
                                ),
                              ),
                        child: usesNarrowLayout
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  layer.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      layer.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  buildTypeLabel(),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (buildEnableEnvironmentAction() case final action?)
                      action,
                    PokeMapIconButton(
                      key: ValueKey<String>(
                          'world-map-layer-visibility-$layerId'),
                      tooltip: layer.isVisible
                          ? 'Masquer le calque'
                          : 'Afficher le calque',
                      isSelected: layer.isVisible,
                      onPressed: row.visibility.enabled
                          ? () => notifier.setMapLayerVisibility(
                                layerId,
                                !layer.isVisible,
                              )
                          : null,
                      icon: Icon(
                        layer.isVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    PokeMapIconButton(
                      key: ValueKey<String>('world-map-layer-rename-$layerId'),
                      tooltip:
                          row.rename.disabledReason ?? 'Renommer le calque',
                      onPressed: row.rename.enabled
                          ? () => _renameLayer(context, layer)
                          : null,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    PokeMapIconButton(
                      key: ValueKey<String>('world-map-layer-delete-$layerId'),
                      tooltip:
                          row.delete.disabledReason ?? 'Supprimer le calque',
                      variant: PokeMapIconButtonVariant.danger,
                      onPressed: row.delete.enabled
                          ? () => _deleteLayer(context, layerId)
                          : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                // One attachment is already announced by the layer type; only
                // the unusual case of several still needs spelling out.
                if (row.attachedEnvironmentLayerIds.length > 1 &&
                    row.environmentAttachmentLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    row.environmentAttachmentLabel!,
                    style: TextStyle(
                      color: context.pokeMapColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (row.technicalEnvironmentSelectionLabel
                    case final label?) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PokeMapBadge(
                      label: label,
                      variant: PokeMapBadgeVariant.info,
                    ),
                  ),
                ],
                if (row.environmentWarningLabel case final warning?) ...[
                  const SizedBox(height: 6),
                  PokeMapDiagnosticCallout(
                    severity: PokeMapDiagnosticSeverity.warning,
                    message: warning,
                  ),
                ],
                if (row.environmentTargetPendingLabel case final pending?) ...[
                  const SizedBox(height: 6),
                  PokeMapDiagnosticCallout(
                    severity: PokeMapDiagnosticSeverity.info,
                    message: '$pending — le masque est déjà peignable, la '
                        'cible sert à la génération.',
                  ),
                ],
                ...buildEnvironmentActions(context),
                const SizedBox(height: 4),
                if (usesNarrowLayout) ...[
                  Row(
                    children: [
                      Flexible(child: buildTypeLabel()),
                      const Spacer(),
                      ...buildReorderActions(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  buildOpacitySlider(),
                ] else
                  Row(
                    children: [
                      Expanded(child: buildOpacitySlider()),
                      const SizedBox(width: 4),
                      ...buildReorderActions(),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
    final hoverPreviewCard = layer is TileLayer
        ? MouseRegion(
            key: ValueKey<String>(
              'world-map-layer-hover-preview-$layerId',
            ),
            onEnter: (_) => ref
                .read(worldMapHoveredTileLayerIdProvider.notifier)
                .show(layerId),
            onExit: (_) => ref
                .read(worldMapHoveredTileLayerIdProvider.notifier)
                .clear(layerId),
            child: card,
          )
        : card;
    return _WorldMapLayerContextMenuInvoker(
      layerId: layerId,
      onRequested: onContextMenuRequested,
      child: hoverPreviewCard,
    );
  }

  Future<void> _pickEnvironmentTarget(
    BuildContext context,
    String environmentLayerId,
  ) async {
    final tileLayers = readActiveMap()
            ?.layers
            .whereType<TileLayer>()
            .toList(growable: false) ??
        const <TileLayer>[];
    final picked = await _showWorldMapEnvironmentTargetDialog(
      context: context,
      tileLayers: tileLayers,
    );
    if (picked == null) return;
    notifier.setEnvironmentLayerTargetTileLayer(
      environmentLayerId: environmentLayerId,
      targetTileLayerId: picked.id,
    );
  }

  Future<void> _renameLayer(BuildContext context, MapLayer layer) async {
    await runWorldMapLayerRenameFlow(
      context: context,
      layerId: layer.id,
      readActiveMap: readActiveMap,
      onRenameRequested: onRenameRequested,
      renameLayer: notifier.renameMapLayer,
    );
  }

  Future<void> _deleteLayer(BuildContext context, String layerId) async {
    await runWorldMapLayerDeleteFlow(
      context: context,
      layerId: layerId,
      readActiveMap: readActiveMap,
      onDeleteRequested: onDeleteRequested,
      deleteLayer: notifier.deleteMapLayer,
    );
  }
}

final class _WorldMapLayerContextMenuInvoker extends StatefulWidget {
  const _WorldMapLayerContextMenuInvoker({
    required this.layerId,
    required this.onRequested,
    required this.child,
  });

  final String layerId;
  final WorldMapLayerContextMenuRequested? onRequested;
  final Widget child;

  @override
  State<_WorldMapLayerContextMenuInvoker> createState() =>
      _WorldMapLayerContextMenuInvokerState();
}

final class _WorldMapLayerContextMenuInvokerState
    extends State<_WorldMapLayerContextMenuInvoker> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'World Map layer ${widget.layerId} context actions',
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _request({
    required Offset globalPosition,
    required MapContextMenuInvocation invocation,
  }) {
    widget.onRequested?.call(
      WorldMapLayerContextMenuRequest(
        target: MapLayerContextTarget(widget.layerId),
        globalPosition: globalPosition,
        invocation: invocation,
        invokerFocusNode: _focusNode,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isMenuKey = event.logicalKey == LogicalKeyboardKey.contextMenu;
    final isShiftF10 = event.logicalKey == LogicalKeyboardKey.f10 &&
        HardwareKeyboard.instance.isShiftPressed;
    if (!isMenuKey && !isShiftF10) return KeyEventResult.ignored;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return KeyEventResult.handled;
    }
    _request(
      globalPosition: renderObject.localToGlobal(renderObject.size.center(
        Offset.zero,
      )),
      invocation: MapContextMenuInvocation.keyboard,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: ValueKey<String>(
        'world-map-layer-context-focus-${widget.layerId}',
      ),
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onSecondaryTapDown: (details) {
          _focusNode.requestFocus();
          _request(
            globalPosition: details.globalPosition,
            invocation: MapContextMenuInvocation.pointer,
          );
        },
        child: widget.child,
      ),
    );
  }
}

void _addLayer(
  EditorNotifier notifier,
  WorldMapLayerCreationKind kind,
) {
  switch (kind) {
    case WorldMapLayerCreationKind.tile:
    case WorldMapLayerCreationKind.collision:
    case WorldMapLayerCreationKind.object:
    case WorldMapLayerCreationKind.environment:
    case WorldMapLayerCreationKind.border:
      notifier.addMapLayer(
        kind: _mapLayerKind(kind),
        name: _creationKindDefaultName(kind),
      );
    case WorldMapLayerCreationKind.smartTerrain:
    case WorldMapLayerCreationKind.smartPath:
    case WorldMapLayerCreationKind.smartSurface:
      throw StateError(
        'Terrain and path layers require a published preset.',
      );
  }
}

Future<void> _addSmartTileLayerFromPreset({
  required BuildContext context,
  required WidgetRef ref,
  required EditorNotifier notifier,
  required WorldMapWorkspaceSessionController session,
  required ProjectManifest? project,
  required String expectedMapId,
  required SmartTileUsage usage,
  required WorldMapPaintSubtool subtool,
}) async {
  final presets =
      (project?.smartTileCatalog.presets ?? const <ProjectSmartTilePreset>[])
          .where(
            (preset) =>
                preset.usage == usage &&
                preset.status == SmartTilePresetStatus.published,
          )
          .toList(growable: false)
        ..sort((left, right) {
          final order = left.sortOrder.compareTo(right.sortOrder);
          return order != 0 ? order : left.name.compareTo(right.name);
        });
  final preset = await _showWorldMapSmartTilePresetDialog(
    context: context,
    presets: presets,
    usage: usage,
  );
  if (preset == null || !context.mounted) return;

  final current = ref.read(editorNotifierProvider);
  if (current.activeMap?.id != expectedMapId) return;
  final stillPublished = current.project?.smartTileCatalog.presets.any(
        (candidate) =>
            candidate.id == preset.id &&
            candidate.usage == usage &&
            candidate.status == SmartTilePresetStatus.published,
      ) ??
      false;
  if (!stillPublished) return;

  final created = await notifier.createCanonicalSmartTileLayer(
    preset: preset,
    name: preset.name,
  );
  if (!created || !context.mounted) return;
  final updatedState = ref.read(editorNotifierProvider);
  final activeMap = updatedState.activeMap;
  final activeLayerId = updatedState.activeLayerId;
  final activeLayer =
      activeMap?.layers.where((layer) => layer.id == activeLayerId).firstOrNull;
  if (activeLayer is SmartTileLayer && activeLayer.presetId == preset.id) {
    if (preset.topology == SmartTileTopology.wangEdge4 ||
        preset.topology == SmartTileTopology.wangCorner4 ||
        preset.topology == SmartTileTopology.wang8) {
      return;
    }
    session.routePaintSubtool(
      notifier,
      subtool,
    );
  }
}

Future<ProjectSmartTilePreset?> _showWorldMapSmartTilePresetDialog({
  required BuildContext context,
  required List<ProjectSmartTilePreset> presets,
  required SmartTileUsage usage,
}) {
  final hasPresets = presets.isNotEmpty;
  final noun = switch (usage) {
    SmartTileUsage.terrain => 'terrain',
    SmartTileUsage.path => 'chemin',
    SmartTileUsage.forestSurface => 'surface forestière',
  };
  return showPokeMapConfirmationDialog<ProjectSmartTilePreset?>(
    context: context,
    title: 'Ajouter un $noun',
    message: hasPresets
        ? 'Choisissez un $noun publié. Le nouveau calque sera sélectionné '
            'et prêt à peindre immédiatement.'
        : 'Aucun $noun publié. Créez-en un dans Smart Tiles Studio, '
            'publiez-le, puis ajoutez-le ici.',
    details: hasPresets
        ? Builder(
            builder: (dialogContext) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final preset in presets) ...[
                  PokeMapButton(
                    key: ValueKey<String>(
                      'world-map-smart-${usage.name}-preset-${preset.id}',
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(preset),
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.auto_awesome_mosaic_outlined),
                    child: Text(preset.name),
                  ),
                  if (preset != presets.last) const SizedBox(height: 8),
                ],
              ],
            ),
          )
        : const PokeMapEmptyState(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            title: 'Aucun preset publié',
            description:
                'Créez et publiez d’abord votre preset dans Smart Tiles '
                'Studio. Il sera ensuite disponible directement ici.',
          ),
    actions: const <PokeMapDialogAction<ProjectSmartTilePreset?>>[
      PokeMapDialogAction<ProjectSmartTilePreset?>(
        label: 'Fermer',
        value: null,
      ),
    ],
    barrierLabel: 'Fermer le choix de $noun',
  );
}

/// Lets the author pick the TileLayer an Environment layer decorates.
///
/// The inspector that used to own this choice was dropped when the shell moved
/// to the World Maps inspectors, which left every Environment layer stuck
/// without a reachable way to name its target.
Future<TileLayer?> _showWorldMapEnvironmentTargetDialog({
  required BuildContext context,
  required List<TileLayer> tileLayers,
}) {
  final hasTileLayers = tileLayers.isNotEmpty;
  return showPokeMapConfirmationDialog<TileLayer?>(
    context: context,
    title: 'TileLayer cible',
    message: hasTileLayers
        ? 'Choisissez le calque de tuiles que cet environnement décore. '
            'La génération posera ses éléments dessus.'
        : 'Cette carte n’a aucun calque de tuiles. Ajoutez-en un, puis '
            'revenez choisir la cible.',
    details: hasTileLayers
        ? Builder(
            builder: (dialogContext) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final layer in tileLayers) ...[
                  PokeMapButton(
                    key: ValueKey<String>(
                      'world-map-environment-target-${layer.id}',
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(layer),
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.layers_outlined),
                    child: Text(layer.name),
                  ),
                  if (layer != tileLayers.last) const SizedBox(height: 8),
                ],
              ],
            ),
          )
        : const PokeMapEmptyState(
            icon: Icon(Icons.layers_outlined),
            title: 'Aucun calque de tuiles',
            description:
                'Un environnement décore un calque de tuiles. Créez-en un '
                'depuis « Ajouter », puis revenez ici.',
          ),
    actions: const <PokeMapDialogAction<TileLayer?>>[
      PokeMapDialogAction<TileLayer?>(
        label: 'Fermer',
        value: null,
      ),
    ],
    barrierLabel: 'Fermer le choix du TileLayer cible',
  );
}

MapLayerKind _mapLayerKind(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => MapLayerKind.tile,
    WorldMapLayerCreationKind.collision => MapLayerKind.collision,
    WorldMapLayerCreationKind.smartTerrain => throw StateError(
        'Smart Tile terrain layers require addSmartTileLayer.',
      ),
    WorldMapLayerCreationKind.smartPath => throw StateError(
        'Smart Tile path layers require addSmartTileLayer.',
      ),
    WorldMapLayerCreationKind.smartSurface => throw StateError(
        'Smart Tile organic surface layers require addSmartTileLayer.',
      ),
    WorldMapLayerCreationKind.object => MapLayerKind.object,
    WorldMapLayerCreationKind.environment => MapLayerKind.environment,
    WorldMapLayerCreationKind.border => MapLayerKind.border,
  };
}

String _creationKindLabel(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => 'Couche de tuiles (Tile)',
    WorldMapLayerCreationKind.collision => 'Couche de collision',
    WorldMapLayerCreationKind.smartTerrain => 'Terrain',
    WorldMapLayerCreationKind.smartPath => 'Chemin',
    WorldMapLayerCreationKind.smartSurface => 'Surface organique',
    WorldMapLayerCreationKind.object => 'Couche d’objets',
    WorldMapLayerCreationKind.environment => 'Couche d’environnement',
    WorldMapLayerCreationKind.border => 'Couche de bordures',
  };
}

String _creationKindDefaultName(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => 'Tuiles',
    WorldMapLayerCreationKind.collision => 'Collision',
    WorldMapLayerCreationKind.smartTerrain => 'Terrain intelligent',
    WorldMapLayerCreationKind.smartPath => 'Chemin intelligent',
    WorldMapLayerCreationKind.smartSurface => 'Surface organique intelligente',
    WorldMapLayerCreationKind.object => 'Objets',
    WorldMapLayerCreationKind.environment => 'Environnement',
    WorldMapLayerCreationKind.border => 'Bordures',
  };
}

/// A Tile layer carrying an attached Environment is presented as an
/// Environment layer: the pair is shown as one row, and the environment is what
/// the author came for. Tile painting still targets the same layer underneath.
String _layerTypeLabel(MapLayer layer, {bool hasAttachedEnvironment = false}) {
  if (layer is TileLayer && hasAttachedEnvironment) return 'Environnement';
  return switch (layer) {
    TileLayer() => 'Tuiles',
    CollisionLayer() => 'Collision',
    ObjectLayer() => 'Objets',
    EnvironmentLayer() => 'Environnement',
    BorderLayer() => 'Bordures',
    SmartTileLayer(usage: SmartTileUsage.terrain) => 'Terrain',
    SmartTileLayer(usage: SmartTileUsage.path) => 'Chemin',
    SmartTileLayer(usage: SmartTileUsage.forestSurface) => 'Forêt',
  };
}

PokeMapTone _layerTone(MapLayer layer, {bool hasAttachedEnvironment = false}) {
  if (layer is TileLayer && hasAttachedEnvironment) return PokeMapTone.success;
  return switch (layer) {
    TileLayer() => PokeMapTone.brand,
    CollisionLayer() => PokeMapTone.danger,
    EnvironmentLayer() ||
    SmartTileLayer(usage: SmartTileUsage.terrain) =>
      PokeMapTone.success,
    SmartTileLayer(usage: SmartTileUsage.path) => PokeMapTone.warning,
    ObjectLayer() => PokeMapTone.narrative,
    BorderLayer() => PokeMapTone.info,
    SmartTileLayer(usage: SmartTileUsage.forestSurface) => PokeMapTone.map,
  };
}

IconData _layerIcon(MapLayer layer, {bool hasAttachedEnvironment = false}) {
  if (layer is TileLayer && hasAttachedEnvironment) return Icons.park_outlined;
  return switch (layer) {
    TileLayer() => Icons.grid_view_rounded,
    CollisionLayer() => Icons.block_outlined,
    ObjectLayer() => Icons.category_outlined,
    EnvironmentLayer() => Icons.park_outlined,
    BorderLayer() => Icons.border_outer_rounded,
    SmartTileLayer(usage: SmartTileUsage.terrain) => Icons.landscape_outlined,
    SmartTileLayer(usage: SmartTileUsage.path) => Icons.route_outlined,
    SmartTileLayer(usage: SmartTileUsage.forestSurface) => Icons.park_outlined,
  };
}

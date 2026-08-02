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
import 'world_map_paint_inspection_intent.dart';
import 'world_map_workspace_session.dart';

enum WorldMapLayerCreationKind {
  tile,
  collision,
  smartTerrain,
  smartPath,
  object,
  environment,
  border,
  surface,
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
  }) {
    final paintInspectionIntent =
        ref.read(worldMapPaintInspectionIntentProvider.notifier);
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
      final label = _layerTypeLabel(row.layer);
      if (!availableTypes.contains(label)) availableTypes.add(label);
    }
    final effectiveTypeFilter = availableTypes.contains(_typeFilter)
        ? _typeFilter
        : _allLayerTypesFilter;
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleRows = rows.where((row) {
      final typeLabel = _layerTypeLabel(row.layer);
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
                                  : WorldMapPaintSubtool.path,
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
              sliver: SliverList.builder(
                itemCount: visibleRows.length,
                itemBuilder: (context, index) {
                  final row = visibleRows[index];
                  return Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                    child: _WorldMapLayerRow(
                      key: ValueKey<String>(
                        'world-map-layer-row-${row.layer.id}',
                      ),
                      row: row,
                      notifier: notifier,
                      onActivate: () => _openLayerEditor(
                        notifier: notifier,
                        session: session,
                        layer: row.layer,
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
        SmartTileUsage.forestSurface => null,
      },
    SurfaceLayer() => WorldMapPaintSubtool.surface,
    BorderLayer() => WorldMapPaintSubtool.border,
    CollisionLayer() => WorldMapPaintSubtool.collision,
    _ => null,
  };
}

final class _WorldMapLayerRow extends StatelessWidget {
  const _WorldMapLayerRow({
    required this.row,
    required this.notifier,
    required this.onActivate,
    required this.readActiveMap,
    required this.onRenameRequested,
    required this.onDeleteRequested,
    required this.onContextMenuRequested,
    required this.reorderingDisabledByFilter,
    super.key,
  });

  final LayerPanelPresentationRow row;
  final EditorNotifier notifier;
  final VoidCallback onActivate;
  final MapData? Function() readActiveMap;
  final WorldMapLayerRenameRequested onRenameRequested;
  final WorldMapLayerDeleteRequested onDeleteRequested;
  final WorldMapLayerContextMenuRequested? onContextMenuRequested;
  final bool reorderingDisabledByFilter;

  @override
  Widget build(BuildContext context) {
    final layer = row.layer;
    final layerId = layer.id;
    Widget buildTypeLabel() => PokeMapStatusLabel(
          key: ValueKey<String>('world-map-layer-type-$layerId'),
          label: _layerTypeLabel(layer),
          tone: _layerTone(layer),
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
    final card = Semantics(
      key: ValueKey<String>('world-map-layer-semantics-$layerId'),
      container: true,
      selected: row.isActive,
      label: [
        layer.name,
        'Type ${_layerTypeLabel(layer)}',
        if (row.technicalEnvironmentSelectionLabel case final label?) label,
      ].join(', '),
      child: PokeMapPanel(
        key: ValueKey<String>('world-map-layer-card-$layerId'),
        borderRadius: 8,
        accentTone: _layerTone(layer),
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
                            : Icon(_layerIcon(layer)),
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
                if (row.environmentAttachmentLabel case final label?) ...[
                  const SizedBox(height: 6),
                  Text(
                    label,
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
    return _WorldMapLayerContextMenuInvoker(
      layerId: layerId,
      onRequested: onContextMenuRequested,
      child: card,
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
    case WorldMapLayerCreationKind.surface:
      notifier.addSurfaceLayer(name: _creationKindDefaultName(kind));
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

  notifier.addSmartTileLayer(
    presetId: preset.id,
    usage: preset.usage,
    defaultMaterialId: preset.defaultMaterialId,
    name: preset.name,
  );
  final updatedState = ref.read(editorNotifierProvider);
  final activeMap = updatedState.activeMap;
  final activeLayerId = updatedState.activeLayerId;
  final activeLayer =
      activeMap?.layers.where((layer) => layer.id == activeLayerId).firstOrNull;
  if (activeLayer is SmartTileLayer && activeLayer.presetId == preset.id) {
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
    WorldMapLayerCreationKind.object => MapLayerKind.object,
    WorldMapLayerCreationKind.environment => MapLayerKind.environment,
    WorldMapLayerCreationKind.border => MapLayerKind.border,
    WorldMapLayerCreationKind.surface => throw StateError(
        'Surface layers must use addSurfaceLayer.',
      ),
  };
}

String _creationKindLabel(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => 'Couche de tuiles (Tile)',
    WorldMapLayerCreationKind.collision => 'Couche de collision',
    WorldMapLayerCreationKind.smartTerrain => 'Terrain',
    WorldMapLayerCreationKind.smartPath => 'Chemin',
    WorldMapLayerCreationKind.object => 'Couche d’objets',
    WorldMapLayerCreationKind.environment => 'Couche d’environnement',
    WorldMapLayerCreationKind.border => 'Couche de bordures',
    WorldMapLayerCreationKind.surface => 'Couche de surface',
  };
}

String _creationKindDefaultName(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => 'Tuiles',
    WorldMapLayerCreationKind.collision => 'Collision',
    WorldMapLayerCreationKind.smartTerrain => 'Terrain intelligent',
    WorldMapLayerCreationKind.smartPath => 'Chemin intelligent',
    WorldMapLayerCreationKind.object => 'Objets',
    WorldMapLayerCreationKind.environment => 'Environnement',
    WorldMapLayerCreationKind.border => 'Bordures',
    WorldMapLayerCreationKind.surface => 'Surfaces',
  };
}

String _layerTypeLabel(MapLayer layer) {
  return switch (layer) {
    TileLayer() => 'Tuiles',
    CollisionLayer() => 'Collision',
    TerrainLayer() => 'Terrain ancien',
    PathLayer() => 'Chemin ancien',
    ObjectLayer() => 'Objets',
    EnvironmentLayer() => 'Environnement',
    BorderLayer() => 'Bordures',
    SurfaceLayer() => 'Surface',
    SmartTileLayer(usage: SmartTileUsage.terrain) => 'Terrain',
    SmartTileLayer(usage: SmartTileUsage.path) => 'Chemin',
    SmartTileLayer(usage: SmartTileUsage.forestSurface) => 'Forêt',
  };
}

PokeMapTone _layerTone(MapLayer layer) {
  return switch (layer) {
    TileLayer() => PokeMapTone.brand,
    CollisionLayer() => PokeMapTone.danger,
    TerrainLayer() ||
    EnvironmentLayer() ||
    SmartTileLayer(usage: SmartTileUsage.terrain) =>
      PokeMapTone.success,
    PathLayer() ||
    SmartTileLayer(usage: SmartTileUsage.path) =>
      PokeMapTone.warning,
    ObjectLayer() => PokeMapTone.narrative,
    BorderLayer() => PokeMapTone.info,
    SurfaceLayer() => PokeMapTone.cinematic,
    SmartTileLayer(usage: SmartTileUsage.forestSurface) => PokeMapTone.map,
  };
}

IconData _layerIcon(MapLayer layer) {
  return switch (layer) {
    TileLayer() => Icons.grid_view_rounded,
    CollisionLayer() => Icons.block_outlined,
    TerrainLayer() => Icons.landscape_outlined,
    PathLayer() => Icons.route_outlined,
    ObjectLayer() => Icons.category_outlined,
    EnvironmentLayer() => Icons.park_outlined,
    BorderLayer() => Icons.border_outer_rounded,
    SurfaceLayer() => Icons.layers_outlined,
    SmartTileLayer(usage: SmartTileUsage.terrain) => Icons.landscape_outlined,
    SmartTileLayer(usage: SmartTileUsage.path) => Icons.route_outlined,
    SmartTileLayer(usage: SmartTileUsage.forestSurface) => Icons.park_outlined,
  };
}

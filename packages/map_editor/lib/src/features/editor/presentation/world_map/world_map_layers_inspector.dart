import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/layers_panel_presentation.dart';
import '../../application/map_context_target.dart';
import '../../state/editor_notifier.dart';
import '../../../../ui/canvas/map_canvas.dart';
import 'world_map_layer_mutation_dialogs.dart';
import 'world_map_workspace_session.dart';

enum WorldMapLayerCreationKind {
  tile,
  collision,
  terrain,
  path,
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

class WorldMapLayersInspector extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          map: state.activeMap,
          activeLayerId: state.activeLayerId,
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

    return Semantics(
      container: true,
      label: 'Calques de la carte, du premier plan vers l’arrière-plan',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapSectionHeader(
              title: 'Calques',
              description: rows.length == 1
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
                onSelected: (kind) => _addLayer(notifier, kind),
                tooltip: 'Ajouter un calque de tuiles',
                menuTooltip: 'Choisir le type de calque',
                child: const Text('Ajouter'),
              ),
            ),
            const SizedBox(height: 8),
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: 'Calque d’environnement',
              message: 'Zone auteur pour environnements organiques : forêts, '
                  'bosquets, prairies, côtes rocheuses.',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                key: const ValueKey<String>('world-map-layer-list'),
                itemCount: rows.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _WorldMapLayerRow(
                  key: ValueKey<String>(
                    'world-map-layer-row-${rows[index].layer.id}',
                  ),
                  row: rows[index],
                  notifier: notifier,
                  session: session,
                  readActiveMap: () =>
                      ref.read(editorNotifierProvider).activeMap,
                  onRenameRequested: onRenameRequested,
                  onDeleteRequested: onDeleteRequested,
                  onContextMenuRequested: onContextMenuRequested,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WorldMapLayerRow extends StatelessWidget {
  const _WorldMapLayerRow({
    required this.row,
    required this.notifier,
    required this.session,
    required this.readActiveMap,
    required this.onRenameRequested,
    required this.onDeleteRequested,
    required this.onContextMenuRequested,
    super.key,
  });

  final LayerPanelPresentationRow row;
  final EditorNotifier notifier;
  final WorldMapWorkspaceSessionController session;
  final MapData? Function() readActiveMap;
  final WorldMapLayerRenameRequested onRenameRequested;
  final WorldMapLayerDeleteRequested onDeleteRequested;
  final WorldMapLayerContextMenuRequested? onContextMenuRequested;

  @override
  Widget build(BuildContext context) {
    final layer = row.layer;
    final layerId = layer.id;
    final card = Semantics(
      key: ValueKey<String>('world-map-layer-semantics-$layerId'),
      container: true,
      selected: row.isActive,
      label: [
        layer.name,
        if (row.technicalEnvironmentSelectionLabel case final label?) label,
      ].join(', '),
      child: PokeMapPanel(
        borderRadius: 8,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: PokeMapButton(
                    key: ValueKey<String>('world-map-layer-activate-$layerId'),
                    onPressed: row.activation.enabled
                        ? () => session.setActiveLayer(notifier, layerId)
                        : null,
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
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(layer.name),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PokeMapIconButton(
                  key: ValueKey<String>('world-map-layer-visibility-$layerId'),
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
                  tooltip: row.rename.disabledReason ?? 'Renommer le calque',
                  onPressed: row.rename.enabled
                      ? () => _renameLayer(context, layer)
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                ),
                PokeMapIconButton(
                  key: ValueKey<String>('world-map-layer-delete-$layerId'),
                  tooltip: row.delete.disabledReason ?? 'Supprimer le calque',
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
            if (row.technicalEnvironmentSelectionLabel case final label?) ...[
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
            const SizedBox(height: 8),
            PokeMapGuidedSlider(
              key: ValueKey<String>('world-map-layer-opacity-$layerId'),
              label: 'Opacité',
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
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PokeMapIconButton(
                  key: ValueKey<String>('world-map-layer-move-up-$layerId'),
                  tooltip: row.moveUp.disabledReason ?? 'Monter le calque',
                  onPressed: row.moveUp.enabled
                      ? () => notifier.moveMapLayerGroupUp(layerId)
                      : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                const SizedBox(width: 4),
                PokeMapIconButton(
                  key: ValueKey<String>('world-map-layer-move-down-$layerId'),
                  tooltip: row.moveDown.disabledReason ?? 'Descendre le calque',
                  onPressed: row.moveDown.enabled
                      ? () => notifier.moveMapLayerGroupDown(layerId)
                      : null,
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
              ],
            ),
          ],
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
    case WorldMapLayerCreationKind.terrain:
    case WorldMapLayerCreationKind.path:
    case WorldMapLayerCreationKind.object:
    case WorldMapLayerCreationKind.environment:
    case WorldMapLayerCreationKind.border:
      notifier.addMapLayer(
        kind: _mapLayerKind(kind),
        name: _creationKindDefaultName(kind),
      );
  }
}

MapLayerKind _mapLayerKind(WorldMapLayerCreationKind kind) {
  return switch (kind) {
    WorldMapLayerCreationKind.tile => MapLayerKind.tile,
    WorldMapLayerCreationKind.collision => MapLayerKind.collision,
    WorldMapLayerCreationKind.terrain => MapLayerKind.terrain,
    WorldMapLayerCreationKind.path => MapLayerKind.path,
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
    WorldMapLayerCreationKind.terrain => 'Couche de terrain',
    WorldMapLayerCreationKind.path => 'Couche de chemin',
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
    WorldMapLayerCreationKind.terrain => 'Terrain',
    WorldMapLayerCreationKind.path => 'Chemins',
    WorldMapLayerCreationKind.object => 'Objets',
    WorldMapLayerCreationKind.environment => 'Environnement',
    WorldMapLayerCreationKind.border => 'Bordures',
    WorldMapLayerCreationKind.surface => 'Surfaces',
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
    SmartTileLayer() => Icons.auto_awesome_mosaic_outlined,
  };
}

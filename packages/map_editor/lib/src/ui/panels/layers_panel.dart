import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';

class LayersPanel extends ConsumerWidget {
  const LayersPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  static String _kindLabel(MapLayerKind k) {
    return switch (k) {
      MapLayerKind.tile => 'Tile Layer',
      MapLayerKind.collision => 'Collision Layer',
      MapLayerKind.terrain => 'Terrain Layer',
      MapLayerKind.path => 'Path Layer',
      MapLayerKind.object => 'Object Layer',
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
        color: EditorChrome.islandFill(context),
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
    var selectedType = MapLayerKind.tile;
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
                  final picked = await showCupertinoListPicker<MapLayerKind>(
                    context: ctx,
                    title: 'Layer type',
                    items: MapLayerKind.values,
                    labelOf: _kindLabel,
                  );
                  if (picked != null) {
                    setState(() => selectedType = picked);
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
    notifier.addMapLayer(
      kind: selectedType,
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
    final labelColor = CupertinoColors.secondaryLabel.resolveFrom(context);
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
          EditorToolbarIconButton(
            onPressed: map == null ? null : onAddLayer,
            icon: CupertinoIcons.add,
            tooltip: 'Add Layer',
            iconSize: 18,
          ),
          EditorToolbarIconButton(
            onPressed: map == null ? null : onDeleteAllLayers,
            icon: CupertinoIcons.trash_slash,
            tooltip: 'Remove All Layers',
            iconSize: 18,
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
    const layerAccent = EditorChrome.accentPrimary;
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      itemCount: map.layers.length,
      itemBuilder: (context, index) {
        final layer = map.layers[index];
        final isActive = layer.id == activeLayerId;
        final canMoveUp = index > 0;
        final canMoveDown = index < map.layers.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isActive
                  ? Color.lerp(
                      EditorChrome.islandFillElevated(context),
                      layerAccent,
                      0.22,
                    )!
                  : EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: layerAccent.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x28000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => notifier.setActiveLayer(layer.id),
                    child: Row(
                      children: [
                        MacosIcon(
                          _iconForLayer(layer),
                          size: 16,
                          color: isActive ? layerAccent : secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: isActive ? layerAccent : label,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_labelForLayer(layer)} • ${layer.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        EditorToolbarIconButton(
                          onPressed: () => notifier.setMapLayerVisibility(
                            layer.id,
                            !layer.isVisible,
                          ),
                          icon: layer.isVisible
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                          tooltip: layer.isVisible ? 'Hide layer' : 'Show layer',
                          iconSize: 18,
                        ),
                        EditorToolbarIconButton(
                          onPressed: canMoveUp
                              ? () => notifier.moveMapLayerUp(layer.id)
                              : null,
                          icon: CupertinoIcons.arrow_up,
                          tooltip: 'Move up',
                          iconSize: 18,
                        ),
                        EditorToolbarIconButton(
                          onPressed: canMoveDown
                              ? () => notifier.moveMapLayerDown(layer.id)
                              : null,
                          icon: CupertinoIcons.arrow_down,
                          tooltip: 'Move down',
                          iconSize: 18,
                        ),
                        EditorToolbarIconButton(
                          onPressed: () => _showRenameLayerDialog(
                            context,
                            notifier,
                            layer,
                          ),
                          icon: CupertinoIcons.pencil,
                          tooltip: 'Rename layer',
                          iconSize: 18,
                        ),
                        EditorToolbarIconButton(
                          onPressed: () => _showDeleteLayerDialog(
                            context,
                            notifier,
                            layer,
                          ),
                          icon: CupertinoIcons.trash,
                          tooltip: 'Delete layer',
                          iconSize: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => CupertinoIcons.square_grid_2x2,
      collision: (_) => CupertinoIcons.shield,
      terrain: (_) => CupertinoIcons.tree,
      path: (_) => CupertinoIcons.map,
      object: (_) => CupertinoIcons.square_stack_3d_up,
    );
  }

  String _labelForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => 'tile',
      collision: (_) => 'collision',
      terrain: (_) => 'terrain',
      path: (_) => 'path',
      object: (_) => 'object',
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

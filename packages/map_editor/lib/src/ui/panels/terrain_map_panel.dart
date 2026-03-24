import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';

enum TerrainMapPanelMode {
  combined,
  groundOnly,
  surfaceOnly,
}

class TerrainMapPanel extends ConsumerWidget {
  const TerrainMapPanel({
    super.key,
    this.embedded = false,
    this.mode = TerrainMapPanelMode.combined,
  });

  final bool embedded;
  final TerrainMapPanelMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;

    if (map == null) {
      final empty = Center(
        child: Text(
          'Open a map to edit base ground and surfaces',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
      if (embedded) {
        return empty;
      }
      return Container(
        decoration: BoxDecoration(
          color: EditorChrome.panelBackground(context),
          border: Border(
            bottom: BorderSide(color: EditorChrome.separator(context)),
          ),
        ),
        child: empty,
      );
    }

    final terrainLayers =
        map.layers.whereType<TerrainLayer>().toList(growable: false);
    final pathLayers = map.layers.whereType<PathLayer>().toList(growable: false);
    final activeLayer = _findLayerById(map, state.activeLayerId);
    final activeTerrainLayer = activeLayer is TerrainLayer ? activeLayer : null;
    final activePathLayer = activeLayer is PathLayer ? activeLayer : null;

    final terrainPresets = notifier.getTerrainPresets();
    final pathPresets = notifier.getPathPresets();
    final selectedTerrainPreset = notifier.getSelectedTerrainPreset();
    final selectedPathPreset = notifier.getSelectedPathPreset();
    final showGround = mode != TerrainMapPanelMode.surfaceOnly;
    final showSurfaces = mode != TerrainMapPanelMode.groundOnly;
    final sections = <Widget>[];

    if (showGround) {
      sections.add(
        _SurfaceSectionCard(
          title: 'Base Ground',
          subtitle: 'Terrain layers paint the map background only.',
          color: const Color(0xFF2B6F53),
          icon: CupertinoIcons.tree,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LayerSelector<TerrainLayer>(
                label: 'Active Terrain Layer',
                layers: terrainLayers,
                activeLayerId: activeTerrainLayer?.id,
                emptyLabel: 'No terrain layer yet',
                onSelected: notifier.setActiveLayer,
                onCreate: () => notifier.activateFirstTerrainLayer(
                  createIfMissing: true,
                ),
              ),
              const SizedBox(height: 10),
              _PresetPickerRow(
                label: 'Selected Terrain Preset',
                hint: 'No terrain preset',
                enabled: terrainPresets.isNotEmpty,
                currentLabel: selectedTerrainPreset == null
                    ? null
                    : '${selectedTerrainPreset.name} • ${_terrainLabel(selectedTerrainPreset.terrainType)}',
                onPick: () async {
                  final picked = await showCupertinoListPicker<ProjectTerrainPreset>(
                    context: context,
                    title: 'Terrain preset',
                    items: terrainPresets,
                    labelOf: (p) => '${p.name} • ${_terrainLabel(p.terrainType)}',
                  );
                  if (picked != null) {
                    notifier.selectTerrainPreset(picked.id);
                  }
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: activeTerrainLayer == null ||
                            selectedTerrainPreset == null
                        ? null
                        : () => notifier.selectTerrainPaintMode(
                              terrainType: selectedTerrainPreset.terrainType,
                            ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.paintbrush, size: 16),
                        SizedBox(width: 6),
                        Text('Paint Base'),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: activeTerrainLayer == null ||
                            selectedTerrainPreset == null
                        ? null
                        : () => notifier.fillActiveTerrainLayer(
                              selectedTerrainPreset.terrainType,
                            ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.drop, size: 16),
                        SizedBox(width: 6),
                        Text('Fill Base'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoStrip(
                text: activeTerrainLayer == null
                    ? 'Select or create a terrain layer to paint the map background.'
                    : selectedTerrainPreset == null
                        ? 'Create a terrain preset in the library to paint this background layer.'
                        : 'Active base: ${selectedTerrainPreset.name} on ${activeTerrainLayer.name}',
              ),
            ],
          ),
        ),
      );
    }

    if (showGround && showSurfaces) {
      sections.add(const SizedBox(height: 12));
    }

    if (showSurfaces) {
      sections.add(
        _SurfaceSectionCard(
          title: 'Surface Overlays',
          subtitle:
              'Path layers carry roads, water, tall grass, ice and every specialized surface.',
          color: const Color(0xFF7A4A1E),
          icon: CupertinoIcons.map,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LayerSelector<PathLayer>(
                label: 'Active Path Layer',
                layers: pathLayers,
                activeLayerId: activePathLayer?.id,
                emptyLabel: 'No path layer yet',
                onSelected: notifier.setActiveLayer,
                onCreate: () => notifier.activateFirstPathLayer(
                  createIfMissing: true,
                ),
              ),
              const SizedBox(height: 10),
              _PresetPickerRow(
                label: 'Assigned Surface Preset',
                hint: 'No surface preset',
                enabled: pathPresets.isNotEmpty,
                currentLabel: _pathPresetLabel(
                  activePathLayer,
                  pathPresets,
                  selectedPathPreset,
                ),
                onPick: () async {
                  final picked = await showCupertinoListPicker<ProjectPathPreset>(
                    context: context,
                    title: 'Surface preset',
                    items: pathPresets,
                    labelOf: (p) => '${p.name} • ${_pathSurfaceLabel(p.surfaceKind)}',
                  );
                  if (picked != null) {
                    if (activePathLayer != null) {
                      notifier.selectPathPresetForActivePathLayer(picked.id);
                    } else {
                      notifier.selectPathPreset(picked.id);
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: activePathLayer == null
                        ? null
                        : notifier.selectPathPaintMode,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.map, size: 16),
                        SizedBox(width: 6),
                        Text('Paint Surface'),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: activePathLayer == null
                        ? null
                        : () => notifier.selectTool(EditorToolType.eraser),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.delete_left, size: 16),
                        SizedBox(width: 6),
                        Text('Erase Surface'),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: () => notifier.activateFirstPathLayer(
                      createIfMissing: true,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.add_circled, size: 16),
                        SizedBox(width: 6),
                        Text('New Path Layer'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PathLayerPropertiesBlock(layer: activePathLayer),
              const SizedBox(height: 10),
              _InfoStrip(
                text: activePathLayer == null
                    ? 'Create a path layer for roads, water, tall grass and every surface overlay.'
                    : activePathLayer.presetId.trim().isEmpty
                        ? 'Assign a surface preset to ${activePathLayer.name} before painting.'
                        : 'Active surface layer: ${activePathLayer.name}',
              ),
            ],
          ),
        ),
      );
    }

    if (mode == TerrainMapPanelMode.combined) {
      sections.add(const SizedBox(height: 10));
      sections.add(
        _InfoStrip(
          text: state.activeTool == EditorToolType.terrainPaint
              ? state.terrainSelectionMode == TerrainSelectionMode.path
                  ? 'Surface paint mode enabled.'
                  : 'Base ground paint mode enabled.'
              : 'Use the controls above to switch between base ground and surface painting.',
        ),
      );
    }

    final content = SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections,
      ),
    );

    if (embedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.panelBackground(context),
        border: Border(
          bottom: BorderSide(color: EditorChrome.separator(context)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'MAP GROUND & SURFACES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const EditorHorizontalDivider(),
          Expanded(child: content),
        ],
      ),
    );
  }

  MapLayer? _findLayerById(MapData map, String? layerId) {
    if (layerId == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }
}

String? _pathPresetLabel(
  PathLayer? activePathLayer,
  List<ProjectPathPreset> pathPresets,
  ProjectPathPreset? selectedPathPreset,
) {
  if (activePathLayer != null &&
      pathPresets.any((p) => p.id == activePathLayer.presetId)) {
    final p = pathPresets.firstWhere((e) => e.id == activePathLayer.presetId);
    return '${p.name} • ${_pathSurfaceLabel(p.surfaceKind)}';
  }
  if (selectedPathPreset != null) {
    return '${selectedPathPreset.name} • ${_pathSurfaceLabel(selectedPathPreset.surfaceKind)}';
  }
  return null;
}

class _PresetPickerRow extends StatelessWidget {
  const _PresetPickerRow({
    required this.label,
    required this.hint,
    required this.enabled,
    required this.currentLabel,
    required this.onPick,
  });

  final String label;
  final String hint;
  final bool enabled;
  final String? currentLabel;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: enabled ? onPick : null,
          child: Text(
            currentLabel ?? hint,
            style: TextStyle(
              fontSize: 13,
              color: currentLabel == null
                  ? CupertinoColors.placeholderText.resolveFrom(context)
                  : CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurfaceSectionCard extends StatelessWidget {
  const _SurfaceSectionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: EditorPaintColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: EditorPaintColors.white70,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LayerSelector<T extends MapLayer> extends StatelessWidget {
  const _LayerSelector({
    required this.label,
    required this.layers,
    required this.activeLayerId,
    required this.emptyLabel,
    required this.onSelected,
    required this.onCreate,
  });

  final String label;
  final List<T> layers;
  final String? activeLayerId;
  final String emptyLabel;
  final ValueChanged<String> onSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (layers.isEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  emptyLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.placeholderText.resolveFrom(context),
                  ),
                ),
              ),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onPressed: onCreate,
                child: const Text('Create'),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () async {
                    final picked = await showCupertinoListPicker<T>(
                      context: context,
                      title: label,
                      items: layers,
                      labelOf: (l) => l.name,
                    );
                    if (picked != null) {
                      onSelected(picked.id);
                    }
                  },
                  child: Text(
                    layers
                        .firstWhere(
                          (l) => l.id == activeLayerId,
                          orElse: () => layers.first,
                        )
                        .name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              EditorToolbarIconButton(
                onPressed: onCreate,
                icon: CupertinoIcons.add_circled,
                tooltip: 'Create layer',
                iconSize: 18,
              ),
            ],
          ),
      ],
    );
  }
}

class _PathLayerPropertiesBlock extends StatelessWidget {
  const _PathLayerPropertiesBlock({required this.layer});

  final PathLayer? layer;

  @override
  Widget build(BuildContext context) {
    if (layer == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: EditorPaintColors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Layer properties become available once a path layer is active.',
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    final properties = layer!.properties.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorPaintColors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Path Layer Properties',
            style: TextStyle(
              fontSize: 11,
              color: EditorPaintColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (properties.isEmpty)
            Text(
              'No custom properties on this path layer.',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            )
          else
            ...properties.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: EditorPaintColors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorPaintColors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: EditorPaintColors.white70,
        ),
      ),
    );
  }
}

String _terrainLabel(TerrainType terrain) {
  return switch (terrain) {
    TerrainType.none => 'None',
    TerrainType.grass => 'Grass Base',
    TerrainType.dirt => 'Dirt Base',
    TerrainType.sand => 'Sand Base',
    TerrainType.rock => 'Rock Base',
    TerrainType.stone => 'Stone Base',
    TerrainType.indoor => 'Indoor Base',
  };
}

String _pathSurfaceLabel(PathSurfaceKind kind) {
  return switch (kind) {
    PathSurfaceKind.path => 'Path',
    PathSurfaceKind.road => 'Road',
    PathSurfaceKind.water => 'Water',
    PathSurfaceKind.tallGrass => 'Tall Grass',
    PathSurfaceKind.ice => 'Ice',
    PathSurfaceKind.lava => 'Lava',
    PathSurfaceKind.swamp => 'Swamp',
    PathSurfaceKind.rails => 'Rails',
    PathSurfaceKind.bridge => 'Bridge',
    PathSurfaceKind.special => 'Special',
    PathSurfaceKind.custom => 'Custom',
  };
}

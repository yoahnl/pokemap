import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';

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
      const empty = Center(
        child: Text(
          'Open a map to edit base ground and surfaces',
          style: TextStyle(color: Colors.white38),
        ),
      );
      if (embedded) {
        return empty;
      }
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: const Border(bottom: BorderSide(color: Colors.white10)),
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
          icon: Icons.landscape_outlined,
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
              _PresetDropdown(
                label: 'Selected Terrain Preset',
                value: selectedTerrainPreset?.id,
                hint: 'No terrain preset',
                items: terrainPresets
                    .map(
                      (preset) => DropdownMenuItem<String>(
                        value: preset.id,
                        child: Text(
                          '${preset.name} • ${_terrainLabel(preset.terrainType)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged:
                    terrainPresets.isEmpty ? null : notifier.selectTerrainPreset,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: activeTerrainLayer == null ||
                            selectedTerrainPreset == null
                        ? null
                        : () => notifier.selectTerrainPaintMode(
                              terrainType: selectedTerrainPreset.terrainType,
                            ),
                    icon: const Icon(Icons.brush_outlined, size: 16),
                    label: const Text('Paint Base'),
                  ),
                  OutlinedButton.icon(
                    onPressed: activeTerrainLayer == null ||
                            selectedTerrainPreset == null
                        ? null
                        : () => notifier.fillActiveTerrainLayer(
                              selectedTerrainPreset.terrainType,
                            ),
                    icon: const Icon(
                      Icons.format_color_fill_outlined,
                      size: 16,
                    ),
                    label: const Text('Fill Base'),
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
          icon: Icons.route_outlined,
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
              _PresetDropdown(
                label: 'Assigned Surface Preset',
                value: activePathLayer != null &&
                        pathPresets.any(
                          (preset) => preset.id == activePathLayer.presetId,
                        )
                    ? activePathLayer.presetId
                    : selectedPathPreset?.id,
                hint: 'No surface preset',
                items: pathPresets
                    .map(
                      (preset) => DropdownMenuItem<String>(
                        value: preset.id,
                        child: Text(
                          '${preset.name} • ${_pathSurfaceLabel(preset.surfaceKind)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: pathPresets.isEmpty
                    ? null
                    : (value) {
                        if (activePathLayer != null) {
                          notifier.selectPathPresetForActivePathLayer(value);
                        } else {
                          notifier.selectPathPreset(value);
                        }
                      },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: activePathLayer == null
                        ? null
                        : notifier.selectPathPaintMode,
                    icon: const Icon(Icons.route_outlined, size: 16),
                    label: const Text('Paint Surface'),
                  ),
                  OutlinedButton.icon(
                    onPressed: activePathLayer == null
                        ? null
                        : () => notifier.selectTool(EditorToolType.eraser),
                    icon: const Icon(Icons.auto_fix_off, size: 16),
                    label: const Text('Erase Surface'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => notifier.activateFirstPathLayer(
                      createIfMissing: true,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('New Path Layer'),
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
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'MAP GROUND & SURFACES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
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
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ),
              OutlinedButton(
                onPressed: onCreate,
                child: const Text('Create'),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: activeLayerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: layers
                      .map(
                        (layer) => DropdownMenuItem<String>(
                          value: layer.id,
                          child: Text(
                            layer.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onSelected(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onCreate,
                tooltip: 'Create layer',
                icon: const Icon(Icons.add_circle_outline, size: 18),
              ),
            ],
          ),
      ],
    );
  }
}

class _PresetDropdown extends StatelessWidget {
  const _PresetDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(hint),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: items,
          onChanged: onChanged,
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
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Layer properties become available once a path layer is active.',
          style: TextStyle(fontSize: 11, color: Colors.white60),
        ),
      );
    }

    final properties = layer!.properties.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Path Layer Properties',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (properties.isEmpty)
            const Text(
              'No custom properties on this path layer.',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            )
          else
            ...properties.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
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
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white70),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';

class TerrainMapPanel extends ConsumerWidget {
  const TerrainMapPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final terrainPresets = notifier.getTerrainPresets();
    final pathPresets = notifier.getPathPresets();
    final selectedTerrainPreset = notifier.getSelectedTerrainPreset();
    final selectedPathPreset = notifier.getSelectedPathPreset();
    final selectedTerrainType = state.selectedTerrainType;
    final isPathSelected = selectedTerrainType == TerrainType.path;

    final activeLayer = _resolveActiveLayer(map, state.activeLayerId);
    final activeIsTerrain = activeLayer is TerrainLayer;
    final activeIsPath = activeLayer is PathLayer;
    final activePathLayer = activeLayer is PathLayer ? activeLayer : null;
    final activePathLayerName = activePathLayer?.name ?? '';
    final displayedPathPreset = activePathLayer == null
        ? selectedPathPreset
        : notifier.getPathPresetById(activePathLayer.presetId) ??
            selectedPathPreset;
    final hasTerrainLayer =
        map?.layers.any((layer) => layer is TerrainLayer) ?? false;
    final hasPathLayer =
        map?.layers.any((layer) => layer is PathLayer) ?? false;
    final canPaint = map != null && (activeIsTerrain || activeIsPath);

    TerrainType paintTerrain;
    if (isPathSelected) {
      paintTerrain = TerrainType.path;
    } else if (selectedTerrainPreset != null) {
      paintTerrain = selectedTerrainPreset.terrainType;
    } else {
      paintTerrain = selectedTerrainType == TerrainType.none
          ? TerrainType.normal
          : selectedTerrainType;
    }

    final terrainSelectedValue =
        terrainPresets.any((preset) => preset.id == selectedTerrainPreset?.id)
            ? selectedTerrainPreset?.id
            : null;
    final pathSelectedValue = activePathLayer != null &&
            pathPresets.any((preset) => preset.id == activePathLayer.presetId)
        ? activePathLayer.presetId
        : pathPresets.any((preset) => preset.id == selectedPathPreset?.id)
            ? selectedPathPreset?.id
            : null;

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
                    'MAP SURFACES',
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
          if (map == null)
            const Expanded(
              child: Center(
                child: Text(
                  'Open a map to paint terrains',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLayerStatusCard(
                      activeLayer: activeLayer,
                      hasTerrainLayer: hasTerrainLayer,
                      hasPathLayer: hasPathLayer,
                      notifier: notifier,
                    ),
                    const SizedBox(height: 10),
                    _buildTerrainPicker(
                      notifier: notifier,
                      presets: terrainPresets,
                      selectedValue: terrainSelectedValue,
                      onChanged: notifier.selectTerrainPreset,
                    ),
                    const SizedBox(height: 10),
                    _buildPathPicker(
                      notifier: notifier,
                      presets: pathPresets,
                      selectedValue: pathSelectedValue,
                      onChanged: activeIsPath
                          ? notifier.selectPathPresetForActivePathLayer
                          : notifier.selectPathPreset,
                    ),
                    if (displayedPathPreset != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.brown.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.brown.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Path type: ${_terrainLabel(displayedPathPreset.groundTerrainType)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: canPaint
                                ? () {
                                    if (activeIsPath) {
                                      notifier.selectPathPaintMode();
                                    } else {
                                      notifier.selectTerrainPaintMode(
                                        terrainType: paintTerrain,
                                      );
                                    }
                                  }
                                : null,
                            icon: Icon(
                              activeIsPath
                                  ? Icons.route_outlined
                                  : Icons.brush_outlined,
                              size: 16,
                            ),
                            label: Text(
                              activeIsPath ? 'Draw Surface' : 'Paint Terrain',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: activeIsTerrain
                                ? () => notifier.fillActiveTerrainLayer(
                                      paintTerrain,
                                    )
                                : null,
                            icon: const Icon(
                              Icons.format_color_fill_outlined,
                              size: 16,
                            ),
                            label: const Text('Fill Layer'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        state.activeTool == EditorToolType.terrainPaint
                            ? (activeIsPath
                                ? ((activePathLayer?.presetId
                                            .trim()
                                            .isNotEmpty ??
                                        false)
                                    ? 'Active: path layer $activePathLayerName'
                                    : 'Active: path layer without preset')
                                : 'Active: terrain ${_terrainLabel(paintTerrain)}')
                            : 'Select terrain paint tool to paint on map',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  MapLayer? _resolveActiveLayer(MapData? map, String? activeLayerId) {
    if (map == null || activeLayerId == null) return null;
    for (final layer in map.layers) {
      if (layer.id == activeLayerId) {
        return layer;
      }
    }
    return null;
  }

  Widget _buildLayerStatusCard({
    required MapLayer? activeLayer,
    required bool hasTerrainLayer,
    required bool hasPathLayer,
    required EditorNotifier notifier,
  }) {
    final activeIsTerrain = activeLayer is TerrainLayer;
    final activeIsPath = activeLayer is PathLayer;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (activeIsTerrain || activeIsPath)
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.orangeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (activeIsTerrain || activeIsPath)
              ? Colors.greenAccent.withValues(alpha: 0.35)
              : Colors.orangeAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                activeIsTerrain
                    ? Icons.landscape_outlined
                    : activeIsPath
                        ? Icons.route_outlined
                        : Icons.warning_amber_rounded,
                size: 16,
                color: (activeIsTerrain || activeIsPath)
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeIsTerrain
                      ? 'Active terrain layer: ${activeLayer.name}'
                      : activeIsPath
                          ? 'Active path layer: ${activeLayer.name}'
                          : 'No active terrain/path layer',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!activeIsTerrain && !activeIsPath) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasTerrainLayer
                        ? notifier.activateFirstTerrainLayer
                        : null,
                    child: const Text('Use Terrain Layer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifier.activateFirstTerrainLayer(
                      createIfMissing: true,
                    ),
                    child: const Text('Add Terrain Layer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        hasPathLayer ? notifier.activateFirstPathLayer : null,
                    child: const Text('Use Path Layer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifier.activateFirstPathLayer(
                      createIfMissing: true,
                    ),
                    child: const Text('Add Path Layer'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTerrainPicker({
    required EditorNotifier notifier,
    required List<ProjectTerrainPreset> presets,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return _buildPickerCard(
      title: 'Terrain Preset',
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        hint: const Text('Choose terrain preset'),
        items: presets
            .map(
              (preset) => DropdownMenuItem<String>(
                value: preset.id,
                child: Text(
                  '${preset.name} (${_terrainLabel(preset.terrainType)})${_categorySuffix(notifier, preset.categoryId)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: presets.isEmpty ? null : onChanged,
      ),
    );
  }

  Widget _buildPathPicker({
    required EditorNotifier notifier,
    required List<ProjectPathPreset> presets,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return _buildPickerCard(
      title: 'Path Preset',
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        hint: const Text('Choose path preset'),
        items: presets
            .map(
              (preset) => DropdownMenuItem<String>(
                value: preset.id,
                child: Text(
                  '${preset.name} (${_terrainLabel(preset.groundTerrainType)})${_categorySuffix(notifier, preset.categoryId)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: presets.isEmpty ? null : onChanged,
      ),
    );
  }

  Widget _buildPickerCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _categorySuffix(EditorNotifier notifier, String? categoryId) {
    final path = notifier.resolveTerrainPresetCategoryPath(categoryId);
    if (path == null || path.isEmpty) return '';
    return ' - $path';
  }

  String _terrainLabel(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => 'None',
      TerrainType.normal => 'Normal Ground',
      TerrainType.path => 'Path',
      TerrainType.water => 'Water',
      TerrainType.tallGrass => 'Tall Grass',
      TerrainType.sand => 'Sand',
      TerrainType.ice => 'Ice',
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';

class TerrainEditorPanel extends ConsumerWidget {
  const TerrainEditorPanel({super.key});

  static const List<TerrainType> _backgroundTerrains = <TerrainType>[
    TerrainType.normal,
    TerrainType.water,
    TerrainType.tallGrass,
    TerrainType.sand,
    TerrainType.ice,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    MapLayer? activeLayer;
    if (map != null && state.activeLayerId != null) {
      for (final layer in map.layers) {
        if (layer.id == state.activeLayerId) {
          activeLayer = layer;
          break;
        }
      }
    }
    final hasTerrainLayer =
        map?.layers.any((layer) => layer is TerrainLayer) ?? false;
    final activeIsTerrain = activeLayer is TerrainLayer;
    final selectedTerrain = state.selectedTerrainType;
    final isTerrainPaintMode = state.activeTool == EditorToolType.terrainPaint;
    final isPathMode =
        isTerrainPaintMode && selectedTerrain == TerrainType.path;
    final fillTerrain = selectedTerrain == TerrainType.path
        ? TerrainType.normal
        : selectedTerrain;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TERRAIN EDITOR',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Icon(
                  isPathMode ? Icons.route_outlined : Icons.terrain_outlined,
                  size: 16,
                  color: isPathMode ? Colors.brown[300] : Colors.lightBlue[200],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (map == null)
            const Expanded(
              child: Center(
                child: Text(
                  'No map loaded',
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
                      context,
                      activeLayer: activeLayer,
                      hasTerrainLayer: hasTerrainLayer,
                      notifier: notifier,
                    ),
                    const SizedBox(height: 10),
                    _buildSectionTitle('Background'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _backgroundTerrains
                          .map(
                            (terrain) => _TerrainChoiceChip(
                              terrain: terrain,
                              selected: selectedTerrain == terrain,
                              onTap: () {
                                notifier.selectTerrainPaintMode(
                                    terrainType: terrain);
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: activeIsTerrain
                                ? () => notifier.selectTerrainPaintMode(
                                      terrainType: fillTerrain,
                                    )
                                : null,
                            icon: const Icon(Icons.brush_outlined, size: 16),
                            label: const Text('Paint'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: activeIsTerrain
                                ? () =>
                                    notifier.fillActiveTerrainLayer(fillTerrain)
                                : null,
                            icon: const Icon(Icons.format_color_fill_outlined,
                                size: 16),
                            label: const Text('Fill Layer'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSectionTitle('Paths'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.brown.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.brown.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route_outlined,
                                size: 16,
                                color: Colors.brown[200],
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Auto-connected path drawing',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Draw roads with automatic corners, T-junctions and crossings.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: activeIsTerrain
                                  ? notifier.selectPathPaintMode
                                  : null,
                              icon: const Icon(Icons.route_outlined, size: 16),
                              label: const Text('Draw Paths'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildModeIndicator(
                      context,
                      isPathMode: isPathMode,
                      selectedTerrain: selectedTerrain,
                      activeIsTerrain: activeIsTerrain,
                      isTerrainPaintMode: isTerrainPaintMode,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayerStatusCard(
    BuildContext context, {
    required MapLayer? activeLayer,
    required bool hasTerrainLayer,
    required EditorNotifier notifier,
  }) {
    final activeIsTerrain = activeLayer is TerrainLayer;
    final borderColor = activeIsTerrain
        ? Colors.greenAccent.withValues(alpha: 0.38)
        : Colors.orangeAccent.withValues(alpha: 0.38);
    final surfaceColor = activeIsTerrain
        ? Colors.greenAccent.withValues(alpha: 0.08)
        : Colors.orangeAccent.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                activeIsTerrain ? Icons.layers : Icons.warning_amber_rounded,
                size: 16,
                color:
                    activeIsTerrain ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeIsTerrain
                      ? 'Active terrain layer: ${activeLayer.name}'
                      : 'Terrain painting needs an active terrain layer',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!activeIsTerrain) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasTerrainLayer
                        ? () => notifier.activateFirstTerrainLayer()
                        : null,
                    child: const Text('Use Terrain Layer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifier.activateFirstTerrainLayer(
                        createIfMissing: true),
                    child: const Text('Add Terrain Layer'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeIndicator(
    BuildContext context, {
    required bool isPathMode,
    required TerrainType selectedTerrain,
    required bool activeIsTerrain,
    required bool isTerrainPaintMode,
  }) {
    final modeText = isPathMode
        ? 'Mode: Path Drawing'
        : 'Mode: Background (${_terrainLabel(selectedTerrain)})';
    final color = isPathMode ? Colors.brown[300]! : Colors.lightBlue[200]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        !activeIsTerrain
            ? 'Select a terrain layer to start editing terrains.'
            : isTerrainPaintMode
                ? modeText
                : 'Tip: activate terrain paint to draw terrains.',
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 0.9,
        color: Colors.white60,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _terrainLabel(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => 'None',
      TerrainType.normal => 'Normal',
      TerrainType.path => 'Path',
      TerrainType.water => 'Water',
      TerrainType.tallGrass => 'Tall Grass',
      TerrainType.sand => 'Sand',
      TerrainType.ice => 'Ice',
    };
  }
}

class _TerrainChoiceChip extends StatelessWidget {
  const _TerrainChoiceChip({
    required this.terrain,
    required this.selected,
    required this.onTap,
  });

  final TerrainType terrain;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _terrainColor(terrain);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.26)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.95) : Colors.white24,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_terrainIcon(terrain), size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              _terrainLabel(terrain),
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _terrainIcon(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => Icons.block_outlined,
      TerrainType.normal => Icons.square_outlined,
      TerrainType.path => Icons.route_outlined,
      TerrainType.water => Icons.water_outlined,
      TerrainType.tallGrass => Icons.grass_outlined,
      TerrainType.sand => Icons.landscape_outlined,
      TerrainType.ice => Icons.ac_unit_outlined,
    };
  }

  String _terrainLabel(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => 'None',
      TerrainType.normal => 'Normal',
      TerrainType.path => 'Path',
      TerrainType.water => 'Water',
      TerrainType.tallGrass => 'TallGrass',
      TerrainType.sand => 'Sand',
      TerrainType.ice => 'Ice',
    };
  }

  Color _terrainColor(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => Colors.blueGrey,
      TerrainType.normal => Colors.blueGrey.shade300,
      TerrainType.path => Colors.brown.shade300,
      TerrainType.water => Colors.lightBlueAccent,
      TerrainType.tallGrass => Colors.lightGreenAccent,
      TerrainType.sand => Colors.amberAccent,
      TerrainType.ice => Colors.cyanAccent,
    };
  }
}

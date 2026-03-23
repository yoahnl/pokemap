import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/inspector_section_card.dart';
import 'layers_panel.dart';
import 'map_connections_panel.dart';
import 'terrain_map_panel.dart';
import 'tileset_palette_panel.dart';
import 'trigger_properties_panel.dart';
import 'warp_properties_panel.dart';

enum _InspectorSectionId {
  layers,
  tiles,
  ground,
  surfaces,
  connections,
  triggers,
  warps,
}

class MapInspectorPanel extends ConsumerStatefulWidget {
  const MapInspectorPanel({super.key});

  @override
  ConsumerState<MapInspectorPanel> createState() => _MapInspectorPanelState();
}

class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
  final Map<_InspectorSectionId, bool> _expandedSections =
      <_InspectorSectionId, bool>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final activeMap = state.activeMap;
    final activeLayer = _findActiveLayer(activeMap, state.activeLayerId);

    if (activeMap == null) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        alignment: Alignment.center,
        child: const Text(
          'Open a map to inspect layers and map systems',
          style: TextStyle(color: Colors.white38),
          textAlign: TextAlign.center,
        ),
      );
    }

    final hasTileLayers = activeMap.layers.any((layer) => layer is TileLayer);
    final hasTerrainLayers =
        activeMap.layers.any((layer) => layer is TerrainLayer);
    final hasPathLayers = activeMap.layers.any((layer) => layer is PathLayer);
    final showTilesSection = activeLayer is TileLayer ||
        state.activeTool == EditorToolType.tilePaint ||
        (state.activeLayerId == null && hasTileLayers);
    final showGroundSection = hasTerrainLayers &&
        (activeLayer is TerrainLayer ||
            (activeLayer is! PathLayer &&
                state.activeTool == EditorToolType.terrainPaint &&
                state.terrainSelectionMode == TerrainSelectionMode.terrain));
    final showSurfaceSection = hasPathLayers &&
        (activeLayer is PathLayer ||
            (activeLayer is! TerrainLayer &&
                state.activeTool == EditorToolType.terrainPaint &&
                state.terrainSelectionMode == TerrainSelectionMode.path));
    const showConnectionsSection = true;
    final showTriggerSection = state.activeTool == EditorToolType.triggerPlacement ||
        state.selectedTriggerId != null ||
        activeMap.triggers.isNotEmpty;
    final showWarpSection = state.activeTool == EditorToolType.warpPlacement ||
        state.selectedWarpId != null ||
        activeMap.warps.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final paletteHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(420.0, 760.0).toDouble()
            : 560.0;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              children: [
                InspectorSectionCard(
                  title: 'Layers',
                  subtitle: activeLayer == null
                      ? 'Select the active layer for this map'
                      : 'Active: ${_layerLabel(activeLayer)}',
                  icon: Icons.layers_outlined,
                  badgeText: '${activeMap.layers.length}',
                  accentColor: const Color(0xFF4A90E2),
                  expanded: _isExpanded(_InspectorSectionId.layers, true),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.layers,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 260,
                  child: const LayersPanel(embedded: true),
                ),
                if (showTilesSection)
                  InspectorSectionCard(
                    title: 'Tiles & Elements',
                    subtitle: 'Tileset palette and element placement for tile layers.',
                    icon: Icons.grid_view_outlined,
                    accentColor: const Color(0xFF4D8BFF),
                    expanded: _isExpanded(
                      _InspectorSectionId.tiles,
                      activeLayer is TileLayer ||
                          state.activeTool == EditorToolType.tilePaint,
                    ),
                    onToggle: () => _toggleSection(
                      _InspectorSectionId.tiles,
                      defaultExpanded: activeLayer is TileLayer ||
                          state.activeTool == EditorToolType.tilePaint,
                    ),
                    expandedHeight: paletteHeight,
                    child: const TilesetPalettePanel(embedded: true),
                  ),
                if (showGroundSection)
                  InspectorSectionCard(
                    title: 'Base Ground',
                    subtitle: 'Terrain-only editing for the map background.',
                    icon: Icons.landscape_outlined,
                    accentColor: const Color(0xFF3E8D67),
                    expanded: _isExpanded(
                      _InspectorSectionId.ground,
                      true,
                    ),
                    onToggle: () => _toggleSection(
                      _InspectorSectionId.ground,
                      defaultExpanded: true,
                    ),
                    expandedHeight: 300,
                    child: const TerrainMapPanel(
                      embedded: true,
                      mode: TerrainMapPanelMode.groundOnly,
                    ),
                  ),
                if (showSurfaceSection)
                  InspectorSectionCard(
                    title: 'Surface Overlays',
                    subtitle: 'Path-only editing for roads and specialized surfaces.',
                    icon: Icons.route_outlined,
                    accentColor: const Color(0xFF9B6230),
                    expanded: _isExpanded(
                      _InspectorSectionId.surfaces,
                      true,
                    ),
                    onToggle: () => _toggleSection(
                      _InspectorSectionId.surfaces,
                      defaultExpanded: true,
                    ),
                    expandedHeight: 340,
                    child: const TerrainMapPanel(
                      embedded: true,
                      mode: TerrainMapPanelMode.surfaceOnly,
                    ),
                  ),
                if (showConnectionsSection)
                  InspectorSectionCard(
                    title: 'Connections',
                    subtitle: 'Link the current map to adjacent world maps.',
                    icon: Icons.alt_route_outlined,
                    badgeText: '${activeMap.connections.length}',
                    accentColor: const Color(0xFF6AA6FF),
                    expanded: _isExpanded(_InspectorSectionId.connections, false),
                    onToggle: () => _toggleSection(
                      _InspectorSectionId.connections,
                      defaultExpanded: false,
                    ),
                    expandedHeight: 520,
                    child: const MapConnectionsPanel(embedded: true),
                  ),
                if (showTriggerSection)
                  InspectorSectionCard(
                    title: 'Triggers',
                    subtitle: state.selectedTriggerId != null
                        ? 'Selected trigger ready for editing.'
                        : 'Gameplay zones and editable trigger areas.',
                    icon: Icons.crop_din_outlined,
                    badgeText: '${activeMap.triggers.length}',
                    accentColor: const Color(0xFFE59A2E),
                    expanded: _isExpanded(
                      _InspectorSectionId.triggers,
                      state.activeTool == EditorToolType.triggerPlacement ||
                          state.selectedTriggerId != null,
                    ),
                    onToggle: () => _toggleSection(
                      _InspectorSectionId.triggers,
                      defaultExpanded:
                          state.activeTool == EditorToolType.triggerPlacement ||
                              state.selectedTriggerId != null,
                    ),
                    expandedHeight: 520,
                    child: const TriggerPropertiesPanel(embedded: true),
                  ),
                if (showWarpSection)
                  InspectorSectionCard(
                    title: 'Warps',
                    subtitle: state.selectedWarpId != null
                        ? 'Selected warp ready for editing.'
                        : 'Map transitions such as doors, stairs and exits.',
                    icon: Icons.move_down_outlined,
                    badgeText: '${activeMap.warps.length}',
                    accentColor: const Color(0xFF31C3D9),
                    expanded: _isExpanded(
                      _InspectorSectionId.warps,
                      state.activeTool == EditorToolType.warpPlacement ||
                          state.selectedWarpId != null,
                    ),
                    onToggle: () => _toggleSection(
                      _InspectorSectionId.warps,
                      defaultExpanded:
                          state.activeTool == EditorToolType.warpPlacement ||
                              state.selectedWarpId != null,
                    ),
                    expandedHeight: 320,
                    child: const WarpPropertiesPanel(embedded: true),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isExpanded(_InspectorSectionId section, bool defaultExpanded) {
    return _expandedSections[section] ?? defaultExpanded;
  }

  void _toggleSection(
    _InspectorSectionId section, {
    required bool defaultExpanded,
  }) {
    setState(() {
      _expandedSections[section] = !(_expandedSections[section] ?? defaultExpanded);
    });
  }

  MapLayer? _findActiveLayer(MapData? map, String? activeLayerId) {
    if (map == null || activeLayerId == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == activeLayerId) {
        return layer;
      }
    }
    return null;
  }

  String _layerLabel(MapLayer layer) {
    return switch (layer) {
      TileLayer _ => 'Tile Layer',
      CollisionLayer _ => 'Collision Layer',
      TerrainLayer _ => 'Terrain Layer',
      PathLayer _ => 'Path Layer',
      ObjectLayer _ => 'Object Layer',
    };
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/terrain_selection_mode.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';
import 'encounter_tables_panel.dart';
import 'entity_properties_panel.dart';
import 'event_properties_panel.dart';
import 'gameplay_zone_properties_panel.dart';
import 'layers_panel.dart';
import 'map_connections_panel.dart';
import 'map_properties_panel.dart';
import 'terrain_map_panel.dart';
import 'tileset_palette_panel.dart';
import 'trigger_properties_panel.dart';
import 'warp_properties_panel.dart';

enum _InspectorSectionId {
  mapProperties,
  layers,
  tiles,
  ground,
  surfaces,
  entities,
  events,
  connections,
  triggers,
  warps,
  gameplayZones,
  encounterTables,
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
        alignment: Alignment.center,
        child: Text(
          'Open a map to inspect layers and map systems',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
          ),
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
    final showSurfaceSection = hasPathLayers && activeLayer is PathLayer;
    const showConnectionsSection = true;
    final showEntitySection =
        state.activeTool == EditorToolType.entityPlacement ||
            state.selectedEntityId != null ||
            activeMap.entities.isNotEmpty;
    final showEventSection =
        state.activeTool == EditorToolType.eventPlacement ||
            state.selectedMapEventId != null ||
            activeMap.events.isNotEmpty;
    final showTriggerSection =
        state.activeTool == EditorToolType.triggerPlacement ||
            state.selectedTriggerId != null ||
            activeMap.triggers.isNotEmpty;
    final showWarpSection = state.activeTool == EditorToolType.warpPlacement ||
        state.selectedWarpId != null ||
        activeMap.warps.isNotEmpty;
    final showGameplayZoneSection =
        state.activeTool == EditorToolType.gameplayZonePlacement ||
            state.selectedGameplayZoneId != null ||
            activeMap.gameplayZones.isNotEmpty;
    final showEncounterTablesSection =
        (state.project?.encounterTables.isNotEmpty ?? false) ||
            showGameplayZoneSection;

    return LayoutBuilder(
      builder: (context, constraints) {
        final paletteHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(420.0, 760.0).toDouble()
            : 560.0;

        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _InspectorOverviewCard(
                map: activeMap,
                activeLayer: activeLayer,
              ),
              InspectorSectionCard(
                title: 'Propriétés de carte',
                subtitle:
                    'Gameplay et présentation (météo, musique, spawn par défaut…)',
                icon: CupertinoIcons.slider_horizontal_3,
                accentColor: EditorChrome.inspectorJoyPlum,
                expanded: _isExpanded(
                  _InspectorSectionId.mapProperties,
                  false,
                ),
                onToggle: () => _toggleSection(
                  _InspectorSectionId.mapProperties,
                  defaultExpanded: false,
                ),
                expandedHeight: 460,
                child: const MapPropertiesPanel(embedded: true),
              ),
              InspectorSectionCard(
                title: 'Layers',
                subtitle: activeLayer == null
                    ? 'Select the active layer for this map'
                    : 'Active: ${_layerLabel(activeLayer)}',
                icon: CupertinoIcons.layers,
                badgeText: '${activeMap.layers.length}',
                accentColor: EditorChrome.inspectorJoyBlue,
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
                  subtitle:
                      'Palette de placement et gestion des instances posées sur le layer actif.',
                  icon: CupertinoIcons.square_grid_2x2,
                  accentColor: EditorChrome.inspectorJoyLilac,
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
                  icon: CupertinoIcons.tree,
                  accentColor: EditorChrome.inspectorJoyMint,
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
                  title: 'Paths',
                  subtitle:
                      'Edit the active path layer for roads and specialized surfaces.',
                  icon: CupertinoIcons.map,
                  accentColor: EditorChrome.inspectorJoyAmber,
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
              if (showEntitySection)
                InspectorSectionCard(
                  title: 'Map Entities',
                  subtitle: state.selectedEntityId != null
                      ? 'Selected entity ready for editing.'
                      : 'Visible world content such as NPCs, signs, items and spawn points.',
                  icon: CupertinoIcons.sparkles,
                  badgeText: '${activeMap.entities.length}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.entities,
                    state.activeTool == EditorToolType.entityPlacement ||
                        state.selectedEntityId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.entities,
                    defaultExpanded:
                        state.activeTool == EditorToolType.entityPlacement ||
                            state.selectedEntityId != null,
                  ),
                  expandedHeight: 560,
                  child: const EntityPropertiesPanel(embedded: true),
                ),
              if (showEventSection)
                InspectorSectionCard(
                  title: 'Map Events',
                  subtitle: state.selectedMapEventId != null
                      ? 'Selected event ready for editing.'
                      : 'Conditional event pages and script/message authoring.',
                  icon: CupertinoIcons.flag,
                  badgeText: '${activeMap.events.length}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.events,
                    state.activeTool == EditorToolType.eventPlacement ||
                        state.selectedMapEventId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.events,
                    defaultExpanded:
                        state.activeTool == EditorToolType.eventPlacement ||
                            state.selectedMapEventId != null,
                  ),
                  expandedHeight: 620,
                  child: const EventPropertiesPanel(embedded: true),
                ),
              if (showConnectionsSection)
                InspectorSectionCard(
                  title: 'Connections',
                  subtitle: 'Link the current map to adjacent world maps.',
                  icon: CupertinoIcons.arrow_branch,
                  badgeText: '${activeMap.connections.length}',
                  accentColor: EditorChrome.inspectorJoyPlum,
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
                  icon: CupertinoIcons.square,
                  badgeText: '${activeMap.triggers.length}',
                  accentColor: EditorChrome.inspectorJoyCoral,
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
                  icon: CupertinoIcons.arrow_down_circle,
                  badgeText: '${activeMap.warps.length}',
                  accentColor: EditorChrome.inspectorJoyOrchid,
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
              if (showGameplayZoneSection)
                InspectorSectionCard(
                  title: 'Gameplay Zones',
                  subtitle: state.selectedGameplayZoneId != null
                      ? 'Selected zone ready for editing.'
                      : 'Encounter areas, movement constraints and special zones.',
                  icon: CupertinoIcons.leaf_arrow_circlepath,
                  badgeText: '${activeMap.gameplayZones.length}',
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.gameplayZones,
                    state.activeTool == EditorToolType.gameplayZonePlacement ||
                        state.selectedGameplayZoneId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.gameplayZones,
                    defaultExpanded: state.activeTool ==
                            EditorToolType.gameplayZonePlacement ||
                        state.selectedGameplayZoneId != null,
                  ),
                  expandedHeight: 520,
                  child: const GameplayZonePropertiesPanel(embedded: true),
                ),
              if (showEncounterTablesSection)
                InspectorSectionCard(
                  title: 'Encounter Tables',
                  subtitle: 'Project-level encounter tables for wild Pokémon.',
                  icon: CupertinoIcons.list_bullet,
                  badgeText: '${state.project?.encounterTables.length ?? 0}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.encounterTables,
                    false,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.encounterTables,
                    defaultExpanded: false,
                  ),
                  expandedHeight: 480,
                  child: const EncounterTablesPanel(embedded: true),
                ),
            ],
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
      _expandedSections[section] =
          !(_expandedSections[section] ?? defaultExpanded);
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
      SurfaceLayer _ => 'Surface Layer',
      ObjectLayer _ => 'Object Layer',
    };
  }
}

class _InspectorOverviewCard extends StatelessWidget {
  const _InspectorOverviewCard({
    required this.map,
    required this.activeLayer,
  });

  final MapData map;
  final MapLayer? activeLayer;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const accentA = EditorChrome.inspectorJoyHoney;
    const accentB = EditorChrome.inspectorJoyApricot;
    final activeLayerText = activeLayer == null
        ? 'No active layer'
        : switch (activeLayer!) {
            TileLayer _ => 'Tile layer active',
            TerrainLayer _ => 'Ground layer active',
            PathLayer _ => 'Surface layer active',
            SurfaceLayer _ => 'Surface placement layer active',
            CollisionLayer _ => 'Collision layer active',
            ObjectLayer _ => 'Object layer active',
          };

    final hi = EditorChrome.islandFillElevated(context);
    final lo = EditorChrome.islandFill(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accentA, 0.44)!,
            Color.lerp(lo, accentB, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.lerp(accentA, accentB, 0.5)!.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: EditorChrome.inspectorTileHardShadows(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accentA, 0.78)!,
                  Color.lerp(accentB, const Color(0xFF1A0804), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentA.withValues(alpha: 0.9),
                width: 1.25,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.slider_horizontal_3,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  map.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${map.size.width} x ${map.size.height} tiles  •  ${map.layers.length} layers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeLayerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

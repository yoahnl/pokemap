import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';

import '../../application/models/tile_layer_environment_attachment_read_model.dart';
import '../../application/services/tile_layer_environment_attachment_read_model_builder.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/environment_generated_placement_add_element_provider.dart';
import '../../features/editor/state/environment_mask_brush_size_provider.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../../features/border_map_editing/presentation/border_layer_inspector_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';
import 'encounter_tables_panel.dart';
import 'entity_properties_panel.dart';
import 'event_properties_panel.dart';
import 'gameplay_zone_properties_panel.dart';
import 'environment_layer_inspector_panel.dart';
import 'layers_panel.dart';
import 'map_connections_panel.dart';
import 'map_properties_panel.dart';
import 'tile_layer_environment_inspector_section.dart';
import 'tileset_palette_panel.dart';
import 'trigger_properties_panel.dart';
import 'warp_properties_panel.dart';
import 'map_inspector_empty_state.dart';
import 'narrative_event_map_bridge_panel.dart';

enum _InspectorSectionId {
  mapProperties,
  layers,
  borders,
  tileLayerEnvironment,
  environmentLayer,
  tiles,
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
  String? _selectedEnvironmentPresetIdForNewArea;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final environmentMaskBrushSize =
        ref.watch(environmentMaskBrushSizeProvider);
    final selectedGeneratedPlacementElementId =
        ref.watch(environmentGeneratedPlacementAddElementProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final activeMap = state.activeMap;
    final activeLayer = _findActiveLayer(activeMap, state.activeLayerId);

    if (activeMap == null) {
      return const MapInspectorEmptyState();
    }

    final hasTileLayers = activeMap.layers.any((layer) => layer is TileLayer);
    final borderLayerCount = activeMap.layers.whereType<BorderLayer>().length;
    final showTileLayerEnvironmentSection =
        activeLayer is TileLayer || activeLayer is EnvironmentLayer;
    final tileLayerEnvironmentReadModel = showTileLayerEnvironmentSection
        ? buildTileLayerEnvironmentAttachmentReadModel(
            manifest: state.project,
            map: activeMap,
            selectedLayerId: state.activeLayerId,
            selectedEnvironmentAreaId: state.selectedEnvironmentAreaId,
            selectedGeneratedPlacementElementId:
                selectedGeneratedPlacementElementId,
          )
        : null;
    final effectiveTileLayerEnvironmentAreaId =
        tileLayerEnvironmentReadModel?.selectedEnvironmentAreaId;
    final environmentPresetOptions = _environmentPresetOptions(
        state.project?.environmentPresets ?? const []);
    final selectedPresetIdForNewArea =
        _selectedPresetIdForNewArea(environmentPresetOptions);
    final canCreateEnvironmentArea = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        _canCreateEnvironmentArea(tileLayerEnvironmentReadModel) &&
        selectedPresetIdForNewArea != null;
    final isTileLayerMaskPaintingActive = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        state.environmentMaskEditMode == EnvironmentMaskEditMode.paint &&
        effectiveTileLayerEnvironmentAreaId != null;
    final isTileLayerMaskErasingActive = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        state.environmentMaskEditMode == EnvironmentMaskEditMode.erase &&
        effectiveTileLayerEnvironmentAreaId != null;
    final isTileLayerGeneratedPlacementDeleteActive =
        activeLayer is TileLayer &&
            tileLayerEnvironmentReadModel != null &&
            state.environmentMaskEditMode ==
                EnvironmentMaskEditMode.generatedDelete &&
            effectiveTileLayerEnvironmentAreaId != null;
    final isTileLayerGeneratedPlacementAddActive = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        state.environmentMaskEditMode == EnvironmentMaskEditMode.generatedAdd &&
        effectiveTileLayerEnvironmentAreaId != null;
    final isTileLayerMaskEditingActive =
        isTileLayerMaskPaintingActive || isTileLayerMaskErasingActive;
    final isTileLayerEnvironmentActionActive = isTileLayerMaskEditingActive ||
        isTileLayerGeneratedPlacementDeleteActive ||
        isTileLayerGeneratedPlacementAddActive;
    final canStartTileLayerMaskEditing = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        tileLayerEnvironmentReadModel.canPaintMask &&
        !tileLayerEnvironmentReadModel.hasErrors &&
        effectiveTileLayerEnvironmentAreaId != null &&
        !isTileLayerEnvironmentActionActive;
    final canStartTileLayerGeneratedPlacementDelete =
        activeLayer is TileLayer &&
            tileLayerEnvironmentReadModel != null &&
            tileLayerEnvironmentReadModel.hasGeneratedPlacements &&
            !tileLayerEnvironmentReadModel.hasErrors &&
            effectiveTileLayerEnvironmentAreaId != null &&
            !isTileLayerEnvironmentActionActive;
    final canStartTileLayerGeneratedPlacementAdd = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        tileLayerEnvironmentReadModel.canAddGeneratedPlacement &&
        !tileLayerEnvironmentReadModel.hasErrors &&
        effectiveTileLayerEnvironmentAreaId != null &&
        !isTileLayerEnvironmentActionActive;
    final canEditTileLayerEnvironmentGenerationParams =
        activeLayer is TileLayer &&
            tileLayerEnvironmentReadModel != null &&
            tileLayerEnvironmentReadModel.canEditSelectedAreaGenerationParams &&
            effectiveTileLayerEnvironmentAreaId != null;
    final canGenerateTileLayerEnvironment = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        tileLayerEnvironmentReadModel.canGenerate &&
        !tileLayerEnvironmentReadModel.hasErrors &&
        effectiveTileLayerEnvironmentAreaId != null;
    final canClearTileLayerEnvironmentGeneratedPlacements =
        activeLayer is TileLayer &&
            tileLayerEnvironmentReadModel != null &&
            tileLayerEnvironmentReadModel.canClearGeneratedPlacements &&
            !tileLayerEnvironmentReadModel.hasErrors &&
            effectiveTileLayerEnvironmentAreaId != null;
    final canRegenerateTileLayerEnvironment = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        tileLayerEnvironmentReadModel.canRegenerate &&
        tileLayerEnvironmentReadModel.hasGeneratedPlacements &&
        !tileLayerEnvironmentReadModel.hasErrors &&
        effectiveTileLayerEnvironmentAreaId != null;
    final canShuffleTileLayerEnvironment = activeLayer is TileLayer &&
        tileLayerEnvironmentReadModel != null &&
        tileLayerEnvironmentReadModel.canShuffle &&
        tileLayerEnvironmentReadModel.hasGeneratedPlacements &&
        !tileLayerEnvironmentReadModel.hasErrors &&
        effectiveTileLayerEnvironmentAreaId != null;
    final showEnvironmentLayerSection = activeLayer is EnvironmentLayer;
    final showTilesSection = activeLayer is TileLayer ||
        state.activeTool == EditorToolType.tilePaint ||
        (state.activeLayerId == null && hasTileLayers);
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
              const NarrativeEventMapBridgePanel(),
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
                title: 'Calques',
                subtitle: activeLayer == null
                    ? 'Sélectionnez le calque actif pour cette carte'
                    : 'Actif : ${_layerLabel(activeLayer)}',
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
              InspectorSectionCard(
                title: 'Bordures',
                subtitle: activeLayer is BorderLayer
                    ? 'Feature et blueprint du calque actif'
                    : borderLayerCount == 0
                        ? 'Créez un calque de bordures dédié'
                        : 'Sélectionnez un calque de bordures',
                icon: CupertinoIcons.waveform_path,
                badgeText: '$borderLayerCount',
                accentColor: context.pokeMapColors.mapAccent,
                expanded: _isExpanded(
                  _InspectorSectionId.borders,
                  activeLayer is BorderLayer ||
                      state.activeTool == EditorToolType.borderPaint ||
                      state.activeTool == EditorToolType.borderErase,
                ),
                onToggle: () => _toggleSection(
                  _InspectorSectionId.borders,
                  defaultExpanded: activeLayer is BorderLayer ||
                      state.activeTool == EditorToolType.borderPaint ||
                      state.activeTool == EditorToolType.borderErase,
                ),
                expandedHeight: 680,
                child: const BorderLayerInspectorPanel(),
              ),
              if (tileLayerEnvironmentReadModel != null)
                InspectorSectionCard(
                  title: 'Environnement du calque',
                  subtitle: tileLayerEnvironmentReadModel.emptyStateTitle,
                  icon: CupertinoIcons.tree,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.tileLayerEnvironment,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.tileLayerEnvironment,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 470,
                  child: TileLayerEnvironmentInspectorSection(
                    readModel: tileLayerEnvironmentReadModel,
                    onEnableEnvironment: activeLayer is TileLayer &&
                            tileLayerEnvironmentReadModel.canEnableEnvironment
                        ? notifier.enableEnvironmentForActiveTileLayer
                        : null,
                    availablePresets: environmentPresetOptions,
                    selectedPresetIdForNewArea: selectedPresetIdForNewArea,
                    onSelectPresetForNewArea: environmentPresetOptions.length >
                            1
                        ? (presetId) {
                            setState(() {
                              _selectedEnvironmentPresetIdForNewArea = presetId;
                            });
                          }
                        : null,
                    onCreateArea: canCreateEnvironmentArea
                        ? () {
                            notifier.createEnvironmentAreaForActiveTileLayer(
                              presetId: selectedPresetIdForNewArea,
                            );
                          }
                        : null,
                    isMaskPaintingActive: isTileLayerMaskPaintingActive,
                    isMaskErasingActive: isTileLayerMaskErasingActive,
                    isDeletingGeneratedPlacement:
                        isTileLayerGeneratedPlacementDeleteActive,
                    isAddingGeneratedPlacement:
                        isTileLayerGeneratedPlacementAddActive,
                    onStartMaskPainting: canStartTileLayerMaskEditing
                        ? notifier
                            .startEnvironmentMaskPaintingForActiveTileLayer
                        : null,
                    onStartMaskErasing: canStartTileLayerMaskEditing
                        ? notifier.startEnvironmentMaskErasingForActiveTileLayer
                        : null,
                    onStopMaskPainting: isTileLayerMaskEditingActive
                        ? notifier.stopEnvironmentMaskPainting
                        : null,
                    onSelectGeneratedPlacementElement: activeLayer
                                is TileLayer &&
                            tileLayerEnvironmentReadModel
                                .hasGeneratedPlacements &&
                            tileLayerEnvironmentReadModel
                                .selectedAreaPaletteItems.isNotEmpty
                        ? notifier
                            .selectEnvironmentGeneratedPlacementElementForActiveTileLayer
                        : null,
                    onStartAddGeneratedPlacement:
                        canStartTileLayerGeneratedPlacementAdd
                            ? notifier
                                .startAddingGeneratedEnvironmentPlacementForActiveTileLayer
                            : null,
                    onStopAddGeneratedPlacement:
                        isTileLayerGeneratedPlacementAddActive
                            ? notifier.stopAddingGeneratedEnvironmentPlacement
                            : null,
                    onStartDeleteGeneratedPlacement:
                        canStartTileLayerGeneratedPlacementDelete
                            ? notifier
                                .startDeletingGeneratedEnvironmentPlacementForActiveTileLayer
                            : null,
                    onStopDeleteGeneratedPlacement:
                        isTileLayerGeneratedPlacementDeleteActive
                            ? notifier.stopDeletingGeneratedEnvironmentPlacement
                            : null,
                    environmentMaskBrushSize: environmentMaskBrushSize,
                    onSetEnvironmentMaskBrushSize:
                        notifier.setEnvironmentMaskBrushSize,
                    onSetGenerationParams:
                        canEditTileLayerEnvironmentGenerationParams
                            ? notifier
                                .setEnvironmentAreaParamsOverrideForActiveTileLayer
                            : null,
                    onResetGenerationParams:
                        canEditTileLayerEnvironmentGenerationParams &&
                                tileLayerEnvironmentReadModel
                                    .selectedAreaHasParamsOverride
                            ? notifier
                                .resetEnvironmentAreaParamsOverrideForActiveTileLayer
                            : null,
                    onSetSeed: canEditTileLayerEnvironmentGenerationParams
                        ? notifier.setEnvironmentAreaSeedForActiveTileLayer
                        : null,
                    onGenerateEnvironment: canGenerateTileLayerEnvironment
                        ? notifier
                            .generateEnvironmentAreaPlacementsForActiveTileLayer
                        : null,
                    onClearGeneratedPlacements:
                        canClearTileLayerEnvironmentGeneratedPlacements
                            ? notifier
                                .clearEnvironmentGeneratedPlacementsForActiveTileLayer
                            : null,
                    onRegenerateEnvironment: canRegenerateTileLayerEnvironment
                        ? notifier
                            .regenerateEnvironmentAreaPlacementsForActiveTileLayer
                        : null,
                    onShuffleEnvironment: canShuffleTileLayerEnvironment
                        ? notifier
                            .shuffleEnvironmentAreaPlacementsForActiveTileLayer
                        : null,
                  ),
                ),
              if (showEnvironmentLayerSection)
                InspectorSectionCard(
                  title: 'Calque d\'environnement',
                  subtitle: null,
                  icon: CupertinoIcons.cloud,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.environmentLayer,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.environmentLayer,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 560,
                  child: EnvironmentLayerInspectorPanel(
                    map: activeMap,
                    layer: activeLayer,
                    embedded: true,
                  ),
                ),
              if (showTilesSection)
                InspectorSectionCard(
                  title: 'Tuiles & éléments',
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
              if (showEntitySection)
                InspectorSectionCard(
                  title: 'Entités de carte',
                  subtitle: state.selectedEntityId != null
                      ? 'Entité sélectionnée prête pour édition.'
                      : 'Contenu du monde visible tel que les PNJ, panneaux, objets et points d\'apparition.',
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
                  title: 'Événements de carte',
                  subtitle: state.selectedMapEventId != null
                      ? 'Legacy — événement sélectionné prêt pour édition.'
                      : 'Legacy — pages d\'événements conditionnels et création de scripts/messages.',
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
                  title: 'Connexions',
                  subtitle:
                      'Lier la carte actuelle aux cartes du monde adjacentes.',
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
                  title: 'Déclencheurs',
                  subtitle: state.selectedTriggerId != null
                      ? 'Déclencheur sélectionné prêt pour édition.'
                      : 'Zones de gameplay et zones de déclencheurs éditables.',
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
                      ? 'Warp sélectionné prêt pour édition.'
                      : 'Transitions de carte telles que les portes, escaliers et sorties.',
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
                  title: 'Zones de gameplay',
                  subtitle: state.selectedGameplayZoneId != null
                      ? 'Zone sélectionnée prête pour édition.'
                      : 'Zones de rencontre, contraintes de mouvement et zones spéciales.',
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
                  title: 'Tables de rencontres',
                  subtitle:
                      'Tables de rencontres au niveau du projet pour les Pokémon sauvages.',
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
      TileLayer _ => 'Calque de tuiles',
      CollisionLayer _ => 'Calque de collision',
      SmartTileLayer _ => 'Calque Smart Tile',
      ObjectLayer _ => 'Calque d\'objets',
      EnvironmentLayer _ => 'Calque d\'environnement',
      BorderLayer _ => 'Calque de bordure',
    };
  }

  String? _selectedPresetIdForNewArea(
    List<TileLayerEnvironmentPresetOption> presets,
  ) {
    if (presets.length == 1) {
      return presets.single.id;
    }
    final selected = _selectedEnvironmentPresetIdForNewArea?.trim();
    if (selected == null || selected.isEmpty) {
      return null;
    }
    for (final preset in presets) {
      if (preset.id == selected) {
        return selected;
      }
    }
    return null;
  }
}

List<TileLayerEnvironmentPresetOption> _environmentPresetOptions(
  List<EnvironmentPreset> presets,
) {
  return [
    for (final preset in presets)
      TileLayerEnvironmentPresetOption(id: preset.id, name: preset.name),
  ];
}

bool _canCreateEnvironmentArea(
  TileLayerEnvironmentAttachmentReadModel model,
) {
  return model.hasAttachment &&
      !model.hasErrors &&
      (model.state == TileLayerEnvironmentAttachmentState.noArea ||
          model.state ==
              TileLayerEnvironmentAttachmentState.areaSelectionRequired);
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
    final colors = context.pokeMapColors;
    final activeLayerText = activeLayer == null
        ? 'Aucun calque actif'
        : switch (activeLayer!) {
            TileLayer _ => 'Calque de tuiles actif',
            SmartTileLayer _ => 'Calque Smart Tile actif',
            CollisionLayer _ => 'Calque de collision actif',
            ObjectLayer _ => 'Calque d\'objets actif',
            EnvironmentLayer _ => 'Calque d\'environnement actif',
            BorderLayer _ => 'Calque de bordure actif',
          };

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceBase,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.borderSubtle,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.slider_horizontal_3,
              color: colors.textSecondary,
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
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${map.size.width} × ${map.size.height} tuiles • ${map.layers.length} couches',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
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
                    color: colors.textMuted,
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

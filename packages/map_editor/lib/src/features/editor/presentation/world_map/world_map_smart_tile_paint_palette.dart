import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring.dart'
    show smartTileCanonicalLayerActionRequiredCode;
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../../smart_tiles_studio/presentation/smart_tile_behavior_action_menu.dart';
import '../../../smart_tiles_studio/presentation/smart_tile_sprite_preview.dart';
import '../../application/smart_tile_variant_density.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import '../../tools/editor_tool.dart';
import 'world_map_paint_inspection_intent.dart';
import 'world_map_smart_tile_density_section.dart';
import 'world_map_smart_tile_gesture_mode.dart';
import 'world_map_workspace_session.dart';

/// Direct, no-code access to the published Smart Tile presets used by Paint.
///
/// Choosing a preset selects an existing compatible layer, then arms the
/// matching paint tool. New layers are created canonically from Layers or the
/// Smart Tiles Studio publication handoff.
class WorldMapSmartTilePaintPalette extends ConsumerWidget {
  const WorldMapSmartTilePaintPalette({
    super.key,
    required this.subtool,
  }) : assert(
          subtool == WorldMapPaintSubtool.terrain ||
              subtool == WorldMapPaintSubtool.path ||
              subtool == WorldMapPaintSubtool.surface,
          'Smart Tile palette supports Terrain, Path, and Organic Surface.',
        );

  final WorldMapPaintSubtool subtool;

  SmartTileUsage get _usage => switch (subtool) {
        WorldMapPaintSubtool.terrain => SmartTileUsage.terrain,
        WorldMapPaintSubtool.path => SmartTileUsage.path,
        WorldMapPaintSubtool.surface => SmartTileUsage.forestSurface,
        _ => throw StateError('Unsupported Smart Tile paint subtool.'),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          project: state.project,
          map: state.activeMap,
          activeLayerId: state.activeLayerId,
          activeTool: state.activeTool,
          projectRootPath: state.projectRootPath,
        ),
      ),
    );
    final presets = _publishedPresets(snapshot.project, _usage);
    final activeLayer = _activeSmartTileLayer(
      snapshot.map,
      snapshot.activeLayerId,
      _usage,
    );
    final activePreset =
        activeLayer == null ? null : _presetById(presets, activeLayer.presetId);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final session = ref.read(worldMapWorkspaceSessionProvider.notifier);
    final intent = ref.read(worldMapPaintInspectionIntentProvider.notifier);
    final gestureMode = ref.watch(worldMapSmartTileGestureModeProvider);
    final gestureModeController =
        ref.read(worldMapSmartTileGestureModeProvider.notifier);
    final selectedMaterialId = ref.watch(worldMapSmartTileMaterialIdProvider);
    final materialController =
        ref.read(worldMapSmartTileMaterialIdProvider.notifier);
    final selectedPatternId = ref.watch(worldMapSmartTilePatternIdProvider);
    final patternController =
        ref.read(worldMapSmartTilePatternIdProvider.notifier);
    final paintMaterials = activePreset == null || snapshot.project == null
        ? const <ProjectSmartTileMaterial>[]
        : _paintMaterials(snapshot.project!, activePreset);
    final activeMaterialId = activePreset == null
        ? null
        : activePreset.allowedMaterialIds.contains(selectedMaterialId)
            ? selectedMaterialId
            : activePreset.defaultMaterialId;
    final paintPatterns = snapshot.project == null
        ? const <ProjectSmartTilePattern>[]
        : _paintPatterns(snapshot.project!, _usage);
    final activePattern = paintPatterns
        .where((pattern) => pattern.id == selectedPatternId)
        .firstOrNull;
    final noun = switch (subtool) {
      WorldMapPaintSubtool.terrain => 'terrain',
      WorldMapPaintSubtool.path => 'chemin',
      WorldMapPaintSubtool.surface => 'surface organique',
      _ => throw StateError('Unsupported Smart Tile paint subtool.'),
    };

    void activate(WorldMapToolActivationRequest request) {
      final result = session.activateTool(notifier, request);
      if (!result.accepted) return;
      if (request is ActivateWorldMapErase) {
        final current = ref.read(editorNotifierProvider);
        final mapId = current.activeMap?.id;
        final layerId = current.activeLayerId;
        if (mapId != null && layerId != null) {
          intent.showSetup(
            mapId: mapId,
            layerId: layerId,
            subtool: subtool,
          );
          return;
        }
      }
      intent.clear();
    }

    void selectPreset(ProjectSmartTilePreset preset) {
      final current = ref.read(editorNotifierProvider);
      final map = current.activeMap;
      if (map == null) return;
      final existing = _layerForPreset(
        map,
        presetId: preset.id,
        usage: preset.usage,
        preferredLayerId: current.activeLayerId,
      );
      if (existing == null) return;
      notifier.setActiveLayer(existing.id);
      materialController.select(preset.defaultMaterialId);
      patternController.clear();
      activate(ActivateWorldMapPaint(subtool));
    }

    final canEdit = activeLayer != null;
    final hasReusableLayer = snapshot.map != null &&
        presets.any(
          (preset) =>
              _layerForPreset(
                snapshot.map!,
                presetId: preset.id,
                usage: preset.usage,
                preferredLayerId: snapshot.activeLayerId,
              ) !=
              null,
        );
    final blockedCode = activeLayer == null && !hasReusableLayer
        ? smartTileCanonicalLayerActionRequiredCode
        : null;
    final isPainting =
        canEdit && snapshot.activeTool == EditorToolType.terrainPaint;
    final isErasing = canEdit && snapshot.activeTool == EditorToolType.eraser;

    return Semantics(
      key: ValueKey<String>('world-map-smart-tile-${_usage.name}-palette'),
      container: true,
      label: 'Presets de $noun publiés. ${presets.length} disponibles.',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapSectionHeader(
                title: switch (subtool) {
                  WorldMapPaintSubtool.terrain => 'Peindre un terrain',
                  WorldMapPaintSubtool.path => 'Peindre un chemin',
                  WorldMapPaintSubtool.surface =>
                    'Peindre une surface organique',
                  _ =>
                    throw StateError('Unsupported Smart Tile paint subtool.'),
                },
                description: activeLayer == null
                    ? hasReusableLayer
                        ? 'Choisissez un preset déjà présent sur cette carte.'
                        : 'Aucun calque compatible. Ajoutez-en un depuis '
                            'le panneau Calques.'
                    : 'Actif : ${activeLayer.name}',
              ),
              if (blockedCode != null) ...[
                const SizedBox(height: 8),
                PokeMapBadge(
                  key: ValueKey<String>(
                    'world-map-smart-tile-${_usage.name}-blocked',
                  ),
                  label: blockedCode,
                  variant: PokeMapBadgeVariant.warning,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PokeMapButton(
                      key: ValueKey<String>(
                        'world-map-smart-tile-${_usage.name}-paint',
                      ),
                      onPressed: canEdit
                          ? () => activate(ActivateWorldMapPaint(subtool))
                          : null,
                      variant: isPainting
                          ? PokeMapButtonVariant.primary
                          : PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.compact,
                      leading: const Icon(Icons.brush_outlined),
                      child: const Text('Peindre'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PokeMapButton(
                      key: ValueKey<String>(
                        'world-map-smart-tile-${_usage.name}-erase',
                      ),
                      onPressed: canEdit
                          ? () => activate(const ActivateWorldMapErase())
                          : null,
                      variant: isErasing
                          ? PokeMapButtonVariant.primary
                          : PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.compact,
                      leading: const Icon(Icons.auto_fix_off_outlined),
                      child: const Text('Effacer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const PokeMapSectionHeader(
                title: 'Forme du geste',
                description: 'Les formes sont prévisualisées puis appliquées '
                    'en une seule opération annulable.',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final mode in WorldMapSmartTileGestureMode.values)
                    PokeMapButton(
                      key: ValueKey<String>(
                        'world-map-smart-tile-gesture-${mode.name}',
                      ),
                      onPressed: canEdit &&
                              _patternSupportsGesture(activePattern, mode)
                          ? () => gestureModeController.select(mode)
                          : null,
                      variant: gestureMode == mode
                          ? PokeMapButtonVariant.primary
                          : PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.compact,
                      leading: Icon(_gestureModeIcon(mode)),
                      child: Text(_gestureModeLabel(mode)),
                    ),
                ],
              ),
              if (activePreset != null && paintMaterials.isNotEmpty) ...[
                const SizedBox(height: 10),
                const PokeMapSectionHeader(
                  title: 'Matière à peindre',
                  description: 'Chaque matière conserve ses propres raccords '
                      'et transitions automatiques.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final material in paintMaterials)
                      PokeMapButton(
                        key: ValueKey<String>(
                          'world-map-smart-tile-material-${material.id}',
                        ),
                        onPressed: canEdit
                            ? () {
                                materialController.select(material.id);
                                patternController.clear();
                                activate(ActivateWorldMapPaint(subtool));
                              }
                            : null,
                        variant: activeMaterialId == material.id
                            ? PokeMapButtonVariant.primary
                            : PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.compact,
                        leading: const Icon(Icons.texture_outlined),
                        child: Text(material.name),
                      ),
                  ],
                ),
              ],
              if (activePreset != null &&
                  activeLayer != null &&
                  snapshot.project != null)
                switch (smartTileFillRuleOf(activePreset)) {
                  null => const SizedBox.shrink(),
                  final fillRule => WorldMapSmartTileDensitySection(
                      key: ValueKey<String>(
                        'world-map-density-${activePreset.id}',
                      ),
                      rule: fillRule,
                      layerWeights: activeLayer.candidateWeights,
                      spriteBuilder: (candidate) => _candidateSpritePreview(
                        catalog: snapshot.project!.smartTileCatalog,
                        tilesets: snapshot.project!.tilesets,
                        projectRootPath: snapshot.projectRootPath,
                        candidate: candidate,
                      ),
                      isEditable: canEdit,
                      onApply: (scope, weights) => switch (scope) {
                        SmartTileDensityScope.layer =>
                          notifier.applySmartTileLayerVariantWeights(
                            mapId: snapshot.map!.id,
                            layerId: activeLayer.id,
                            weights: weights,
                          ),
                        SmartTileDensityScope.preset =>
                          notifier.applySmartTilePresetVariantWeights(
                            presetId: activePreset.id,
                            ruleId: fillRule.id,
                            weights: weights,
                          ),
                      },
                    ),
                },
              if (activeLayer != null && snapshot.project != null) ...[
                const SizedBox(height: 10),
                PokeMapSectionHeader(
                  title: 'Motifs réutilisables',
                  description: paintPatterns.isEmpty
                      ? 'Aucun motif compatible. Créez-en un dans Smart '
                          'Tiles Studio.'
                      : 'Tamponnez une forme complète ou répétez-la sur une '
                          'ligne ou une zone.',
                ),
                if (paintPatterns.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final pattern in paintPatterns)
                        PokeMapButton(
                          key: ValueKey<String>(
                            'world-map-smart-tile-pattern-${pattern.id}',
                          ),
                          onPressed: () {
                            patternController.select(pattern.id);
                            materialController.clear();
                            if (!_patternSupportsGesture(
                              pattern,
                              gestureMode,
                            )) {
                              gestureModeController
                                  .select(WorldMapSmartTileGestureMode.brush);
                            }
                            activate(ActivateWorldMapPaint(subtool));
                          },
                          variant: activePattern?.id == pattern.id
                              ? PokeMapButtonVariant.primary
                              : PokeMapButtonVariant.secondary,
                          size: PokeMapButtonSize.compact,
                          leading: Icon(
                            pattern.repeatMode ==
                                    SmartTilePatternRepeatMode.stamp
                                ? Icons.control_point_duplicate_outlined
                                : Icons.grid_view_outlined,
                          ),
                          child: Text(pattern.name),
                        ),
                    ],
                  ),
                  if (activePattern != null) ...[
                    const SizedBox(height: 6),
                    PokeMapBadge(
                      label: activePattern.repeatMode ==
                              SmartTilePatternRepeatMode.stamp
                          ? 'Tampon ${activePattern.width} × '
                              '${activePattern.height}'
                          : 'Répétition ${activePattern.width} × '
                              '${activePattern.height}',
                      variant: PokeMapBadgeVariant.info,
                    ),
                  ],
                ],
              ],
              if (snapshot.project != null &&
                  activeLayer != null &&
                  activePreset != null &&
                  activeMaterialId != null &&
                  activePattern == null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SmartTileBehaviorActionMenu(
                    map: snapshot.map,
                    smartTileLayer: activeLayer,
                    smartTilePresetId: activePreset.id,
                    materialId: activeMaterialId,
                    catalog: snapshot.project!.smartTileCatalog,
                    encounterTables: snapshot.project!.encounterTables,
                    notifier: notifier,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              presets.isEmpty
                  ? PokeMapEmptyState(
                      key: ValueKey<String>(
                        'world-map-smart-tile-${_usage.name}-empty',
                      ),
                      icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                      title: 'Aucun $noun publié',
                      description: 'Créez puis publiez un preset dans Smart '
                          'Tiles Studio. Il apparaîtra ici automatiquement.',
                      compact: true,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 400 ? 2 : 1;
                        return GridView.builder(
                          key: ValueKey<String>(
                            'world-map-smart-tile-${_usage.name}-presets',
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 76,
                          ),
                          itemCount: presets.length,
                          shrinkWrap: true,
                          primary: false,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final preset = presets[index];
                            final selected = activeLayer?.presetId == preset.id;
                            final reusableLayer = snapshot.map == null
                                ? null
                                : _layerForPreset(
                                    snapshot.map!,
                                    presetId: preset.id,
                                    usage: preset.usage,
                                    preferredLayerId: snapshot.activeLayerId,
                                  );
                            return PokeMapAssetCard(
                              key: ValueKey<String>(
                                'world-map-smart-tile-${_usage.name}-preset-${preset.id}',
                              ),
                              thumbnail: Icon(
                                switch (subtool) {
                                  WorldMapPaintSubtool.terrain =>
                                    Icons.landscape_outlined,
                                  WorldMapPaintSubtool.path =>
                                    Icons.route_outlined,
                                  WorldMapPaintSubtool.surface =>
                                    Icons.park_outlined,
                                  _ => Icons.auto_awesome_mosaic_outlined,
                                },
                              ),
                              label: preset.name,
                              description: selected && canEdit
                                  ? 'Prêt à peindre'
                                  : reusableLayer != null
                                      ? 'Cliquer pour utiliser'
                                      : 'Ajouter un calque depuis Calques',
                              selected: selected,
                              onPressed: reusableLayer == null
                                  ? null
                                  : () => selectPreset(preset),
                              trailing: selected
                                  ? const Icon(Icons.check_circle_outline)
                                  : null,
                            );
                          },
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

List<ProjectSmartTilePattern> _paintPatterns(
  ProjectManifest project,
  SmartTileUsage usage,
) {
  final patterns = project.smartTileCatalog.patterns
      .where((pattern) => pattern.usage == usage)
      .toList(growable: false);
  patterns.sort((left, right) {
    final order = left.sortOrder.compareTo(right.sortOrder);
    return order != 0 ? order : left.name.compareTo(right.name);
  });
  return patterns;
}

bool _patternSupportsGesture(
  ProjectSmartTilePattern? pattern,
  WorldMapSmartTileGestureMode mode,
) {
  if (pattern == null) return true;
  if (pattern.repeatMode == SmartTilePatternRepeatMode.stamp) {
    return mode == WorldMapSmartTileGestureMode.brush;
  }
  return mode != WorldMapSmartTileGestureMode.floodFill;
}

List<ProjectSmartTileMaterial> _paintMaterials(
  ProjectManifest project,
  ProjectSmartTilePreset preset,
) {
  final allowed = preset.allowedMaterialIds.toSet();
  final materials = project.smartTileCatalog.materials
      .where((material) => allowed.contains(material.id))
      .toList(growable: false);
  materials.sort((left, right) {
    final order = left.sortOrder.compareTo(right.sortOrder);
    return order != 0 ? order : left.name.compareTo(right.name);
  });
  return materials;
}

String _gestureModeLabel(WorldMapSmartTileGestureMode mode) => switch (mode) {
      WorldMapSmartTileGestureMode.brush => 'Pinceau',
      WorldMapSmartTileGestureMode.line => 'Ligne',
      WorldMapSmartTileGestureMode.rectangle => 'Rectangle',
      WorldMapSmartTileGestureMode.floodFill => 'Remplir',
    };

IconData _gestureModeIcon(WorldMapSmartTileGestureMode mode) => switch (mode) {
      WorldMapSmartTileGestureMode.brush => Icons.brush_outlined,
      WorldMapSmartTileGestureMode.line => Icons.show_chart,
      WorldMapSmartTileGestureMode.rectangle => Icons.crop_square_outlined,
      WorldMapSmartTileGestureMode.floodFill =>
        Icons.format_color_fill_outlined,
    };

ProjectSmartTilePreset? _presetById(
  List<ProjectSmartTilePreset> presets,
  String presetId,
) {
  for (final preset in presets) {
    if (preset.id == presetId) return preset;
  }
  return null;
}

List<ProjectSmartTilePreset> _publishedPresets(
  ProjectManifest? project,
  SmartTileUsage usage,
) {
  final presets =
      (project?.smartTileCatalog.presets ?? const <ProjectSmartTilePreset>[])
          .where(
            (preset) =>
                preset.usage == usage &&
                preset.status == SmartTilePresetStatus.published,
          )
          .toList(growable: false);
  presets.sort((left, right) {
    final order = left.sortOrder.compareTo(right.sortOrder);
    return order != 0 ? order : left.name.compareTo(right.name);
  });
  return presets;
}

SmartTileLayer? _activeSmartTileLayer(
  MapData? map,
  String? activeLayerId,
  SmartTileUsage usage,
) {
  if (map == null || activeLayerId == null) return null;
  for (final layer in map.layers) {
    if (layer.id == activeLayerId &&
        layer is SmartTileLayer &&
        layer.usage == usage) {
      return layer;
    }
  }
  return null;
}

SmartTileLayer? _layerForPreset(
  MapData map, {
  required String presetId,
  required SmartTileUsage usage,
  required String? preferredLayerId,
}) {
  final preferred = _activeSmartTileLayer(map, preferredLayerId, usage);
  if (preferred?.presetId == presetId) return preferred;
  for (final layer in map.layers.reversed) {
    if (layer is SmartTileLayer &&
        layer.usage == usage &&
        layer.presetId == presetId) {
      return layer;
    }
  }
  return null;
}

/// Vignette du premier visuel d'un candidat : la frame directe, ou la
/// première frame de son animation. Sans visuel résoluble, un simple gabarit
/// vide garde l'alignement des curseurs.
Widget _candidateSpritePreview({
  required ProjectSmartTileCatalog catalog,
  required Iterable<ProjectTilesetEntry> tilesets,
  required String? projectRootPath,
  required SmartTileCandidate candidate,
}) {
  final source = candidate.parts.isEmpty ? null : candidate.parts.first.source;
  final frame = switch (source) {
    SmartTileFrameSource(:final frame) => frame,
    SmartTileAnimationSource(:final animationId) => catalog.animations
        .where((animation) => animation.id == animationId)
        .firstOrNull
        ?.frames
        .firstOrNull
        ?.frame,
    null => null,
  };
  if (frame == null) return const SizedBox(width: 24, height: 24);
  return SmartTileSpritePreview(
    frame: frame,
    atlases: catalog.atlases,
    tilesets: tilesets,
    projectRootPath: projectRootPath,
    size: 24,
  );
}

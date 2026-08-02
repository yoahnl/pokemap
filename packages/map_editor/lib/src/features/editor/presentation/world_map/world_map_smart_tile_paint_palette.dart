import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring.dart'
    show
        smartTileNativeAuthoringRequiresStn03Code,
        smartTileWangPaintCompilerRequiredCode;
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import '../../tools/editor_tool.dart';
import 'world_map_paint_inspection_intent.dart';
import 'world_map_workspace_session.dart';

/// Direct, no-code access to the published Smart Tile presets used by Paint.
///
/// Choosing a preset selects an existing cell-field layer, then arms the
/// matching paint tool. Atomic layer creation remains deferred to STN-03.
class WorldMapSmartTilePaintPalette extends ConsumerWidget {
  const WorldMapSmartTilePaintPalette({
    super.key,
    required this.subtool,
  }) : assert(
          subtool == WorldMapPaintSubtool.terrain ||
              subtool == WorldMapPaintSubtool.path,
          'Smart Tile palette supports only Terrain and Path.',
        );

  final WorldMapPaintSubtool subtool;

  SmartTileUsage get _usage => switch (subtool) {
        WorldMapPaintSubtool.terrain => SmartTileUsage.terrain,
        WorldMapPaintSubtool.path => SmartTileUsage.path,
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
        ),
      ),
    );
    final presets = _publishedPresets(snapshot.project, _usage);
    final activeLayer = _activeSmartTileLayer(
      snapshot.map,
      snapshot.activeLayerId,
      _usage,
    );
    final notifier = ref.read(editorNotifierProvider.notifier);
    final session = ref.read(worldMapWorkspaceSessionProvider.notifier);
    final intent = ref.read(worldMapPaintInspectionIntentProvider.notifier);
    final noun = subtool == WorldMapPaintSubtool.terrain ? 'terrain' : 'chemin';

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
      final existing = _cellLayerForPreset(
        map,
        presetId: preset.id,
        usage: preset.usage,
        preferredLayerId: current.activeLayerId,
      );
      if (existing == null) return;
      notifier.setActiveLayer(existing.id);
      activate(ActivateWorldMapPaint(subtool));
    }

    final canEdit = activeLayer?.field is SmartTileCellField;
    final hasReusableCellLayer = snapshot.map != null &&
        presets.any(
          (preset) =>
              _cellLayerForPreset(
                snapshot.map!,
                presetId: preset.id,
                usage: preset.usage,
                preferredLayerId: snapshot.activeLayerId,
              ) !=
              null,
        );
    final blockedCode = activeLayer != null && !canEdit
        ? smartTileWangPaintCompilerRequiredCode
        : activeLayer == null && !hasReusableCellLayer
            ? smartTileNativeAuthoringRequiresStn03Code
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapSectionHeader(
              title: subtool == WorldMapPaintSubtool.terrain
                  ? 'Peindre un terrain'
                  : 'Peindre un chemin',
              description: activeLayer == null
                  ? hasReusableCellLayer
                      ? 'Choisissez un preset déjà présent sur cette carte.'
                      : 'Aucun calque compatible. Création disponible après '
                          'STN-03.'
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
            const SizedBox(height: 12),
            Expanded(
              child: presets.isEmpty
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
                          itemBuilder: (context, index) {
                            final preset = presets[index];
                            final selected = activeLayer?.presetId == preset.id;
                            final matchingLayer = snapshot.map == null
                                ? null
                                : _layerForPreset(
                                    snapshot.map!,
                                    presetId: preset.id,
                                    usage: preset.usage,
                                    preferredLayerId: snapshot.activeLayerId,
                                  );
                            final reusableCellLayer = snapshot.map == null
                                ? null
                                : _cellLayerForPreset(
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
                                subtool == WorldMapPaintSubtool.terrain
                                    ? Icons.landscape_outlined
                                    : Icons.route_outlined,
                              ),
                              label: preset.name,
                              description: selected && canEdit
                                  ? 'Prêt à peindre'
                                  : reusableCellLayer != null
                                      ? 'Cliquer pour utiliser'
                                      : matchingLayer != null
                                          ? 'Peinture disponible après STN-05'
                                          : 'Création disponible après STN-03',
                              selected: selected,
                              onPressed: reusableCellLayer == null
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
            ),
          ],
        ),
      ),
    );
  }
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

SmartTileLayer? _cellLayerForPreset(
  MapData map, {
  required String presetId,
  required SmartTileUsage usage,
  required String? preferredLayerId,
}) {
  final preferred = _activeSmartTileLayer(map, preferredLayerId, usage);
  if (preferred?.presetId == presetId &&
      preferred?.field is SmartTileCellField) {
    return preferred;
  }
  for (final layer in map.layers.reversed) {
    if (layer is SmartTileLayer &&
        layer.usage == usage &&
        layer.presetId == presetId &&
        layer.field is SmartTileCellField) {
      return layer;
    }
  }
  return null;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../border_map_editing/presentation/border_layer_inspector_panel.dart';
import '../../../border_map_editing/state/border_map_editing_providers.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import '../../../../ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';
import '../../application/world_map_subtool_body_projector.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import 'world_map_collision_inspector.dart';
import 'world_map_paint_inspection_intent.dart';
import 'world_map_subtool_disabled_guidance.dart';
import 'world_map_smart_tile_paint_palette.dart';
import 'world_map_workspace_session.dart';

class WorldMapPaintInspector extends ConsumerWidget {
  const WorldMapPaintInspector({
    super.key,
    this.debugOnPaletteBuild,
  });

  @visibleForTesting
  final VoidCallback? debugOnPaletteBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rememberedSubtool = ref.watch(
      worldMapWorkspaceSessionProvider.select(
        (session) => session.lastPaintSubtool,
      ),
    );
    final inspectionIntent = ref.watch(
      effectiveWorldMapPaintInspectionIntentProvider,
    );
    final subtool = inspectionIntent?.subtool ?? rememberedSubtool;
    final activationSource = ref.watch(
      editorNotifierProvider.select(worldMapToolActivationSourceFromState),
    );
    final notifier = ref.read(editorNotifierProvider.notifier);
    final session = ref.read(worldMapWorkspaceSessionProvider.notifier);
    final inspectionIntentController = ref.read(
      worldMapPaintInspectionIntentProvider.notifier,
    );
    final borderSelection = ref.watch(activeBorderFeatureControllerProvider);
    final projection = const WorldMapSubtoolBodyProjector().project(
      source: activationSource,
      request: ActivateWorldMapPaint(subtool),
      activeBorderFeatureId:
          borderSelection.activeLayerId == activationSource.activeLayerId
              ? borderSelection.activeFeatureId
              : null,
    );

    void reconcileRouting(WorldMapPaintRoutingResult result) {
      final mapId = ref.read(editorNotifierProvider).activeMap?.id;
      switch (result.outcome) {
        case WorldMapPaintRoutingOutcome.activated:
          inspectionIntentController.clear();
        case WorldMapPaintRoutingOutcome.setupRequired:
          final layerId = result.layerId;
          if (mapId != null && layerId != null) {
            inspectionIntentController.showSetup(
              mapId: mapId,
              layerId: layerId,
              subtool: result.request.subtool,
            );
          }
        case WorldMapPaintRoutingOutcome.choiceRequired:
          if (mapId != null) {
            inspectionIntentController.showLayerChoice(
              mapId: mapId,
              subtool: result.request.subtool,
              compatibleLayerIds: result.compatibleLayerIds,
            );
          }
        case WorldMapPaintRoutingOutcome.missingLayer:
          if (mapId != null) {
            inspectionIntentController.showMissingLayer(
              mapId: mapId,
              subtool: result.request.subtool,
            );
          }
        case WorldMapPaintRoutingOutcome.rejected:
          inspectionIntentController.clear();
      }
    }

    bool stillOwnsIntent(WorldMapPaintInspectionIntent expected) {
      final currentScope = worldMapDocumentScopeFromState(
        ref.read(editorNotifierProvider),
      );
      return currentScope == expected.scope &&
          ref.read(worldMapPaintInspectionIntentProvider) == expected;
    }

    if (subtool == WorldMapPaintSubtool.terrain ||
        subtool == WorldMapPaintSubtool.path ||
        subtool == WorldMapPaintSubtool.surface) {
      return KeyedSubtree(
        key: ValueKey<String>(
          'world-map-paint-body-${projection.bodyKind.name}',
        ),
        child: WorldMapSmartTilePaintPalette(subtool: subtool),
      );
    }

    if (inspectionIntent?.kind ==
        WorldMapPaintInspectionIntentKind.layerChoice) {
      final expectedIntent = inspectionIntent!;
      return _WorldMapPaintLayerChoiceGuidance(
        map: activationSource.activeMap!,
        intent: expectedIntent,
        onSelected: (layerId) {
          if (!stillOwnsIntent(expectedIntent)) {
            inspectionIntentController.clear();
            return;
          }
          reconcileRouting(
            session.routePaintSubtool(
              notifier,
              subtool,
              chosenLayerId: layerId,
            ),
          );
        },
      );
    }
    if (inspectionIntent?.kind ==
        WorldMapPaintInspectionIntentKind.missingLayer) {
      final expectedIntent = inspectionIntent!;
      return _WorldMapPaintMissingLayerGuidance(
        subtool: subtool,
        onAdd: () {
          if (!stillOwnsIntent(expectedIntent)) {
            inspectionIntentController.clear();
            return;
          }
          final map = notifier.worldMapToolActivationMap;
          final snapshot = notifier.worldMapToolActivationSessionSnapshot;
          final routing = map == null
              ? null
              : resolveWorldMapPaintLayerRouting(
                  map: map,
                  activeLayerId: snapshot.activeLayerId,
                  subtool: subtool,
                );
          if (routing?.kind != WorldMapPaintLayerRoutingKind.missing) {
            inspectionIntentController.clear();
            return;
          }
          if (!stillOwnsIntent(expectedIntent)) {
            inspectionIntentController.clear();
            return;
          }
          _addRequiredPaintLayer(notifier, subtool);
          reconcileRouting(session.routePaintSubtool(notifier, subtool));
        },
      );
    }
    if (!projection.canRenderBody) {
      return WorldMapSubtoolDisabledGuidance(
        title: 'Peindre · ${_paintSubtoolLabel(subtool)}',
        reason: projection.disabledReason!,
        icon: const Icon(Icons.brush_outlined),
      );
    }

    void activate(WorldMapToolActivationRequest request) {
      final result = session.activateTool(notifier, request);
      if (result.accepted) {
        inspectionIntentController.clear();
      }
    }

    final body = switch (projection.bodyKind) {
      WorldMapSubtoolBodyKind.tilesPalette => Semantics(
          container: true,
          label: 'Catalogue d’éléments à placer du calque actif',
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MapPaletteAssetBrowserLauncher(
                  label: 'Changer de source',
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: MapLayerAssetPalette(
                    debugOnBuild: debugOnPaletteBuild,
                  ),
                ),
              ],
            ),
          ),
        ),
      WorldMapSubtoolBodyKind.terrainPainter ||
      WorldMapSubtoolBodyKind.pathPainter =>
        throw StateError('Smart Tile paint bodies are routed above.'),
      WorldMapSubtoolBodyKind.surfacePainter => throw StateError(
          'Organic Surface Smart Tile bodies are routed above.',
        ),
      WorldMapSubtoolBodyKind.borderInspector => BorderLayerInspectorPanel(
          onPaintRequested: () => activate(
            const ActivateWorldMapPaint(WorldMapPaintSubtool.border),
          ),
          onEraseRequested: () => activate(const ActivateWorldMapErase()),
        ),
      WorldMapSubtoolBodyKind.collisionInspector =>
        const WorldMapCollisionInspector(),
      WorldMapSubtoolBodyKind.elementsPalette ||
      WorldMapSubtoolBodyKind.entityPlacement ||
      WorldMapSubtoolBodyKind.eventPlacement ||
      WorldMapSubtoolBodyKind.triggerPlacement ||
      WorldMapSubtoolBodyKind.warpPlacement ||
      WorldMapSubtoolBodyKind.gameplayZonePlacement =>
        throw StateError(
          'A placement body cannot be projected for Paint.',
        ),
    };

    return KeyedSubtree(
      key: ValueKey<String>(
        'world-map-paint-body-${projection.bodyKind.name}',
      ),
      child: projection.access == WorldMapSubtoolBodyAccess.setup
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: PokeMapDiagnosticCallout(
                    severity: PokeMapDiagnosticSeverity.warning,
                    title: 'Configuration requise',
                    message: projection.disabledReason!,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}

String _paintSubtoolLabel(WorldMapPaintSubtool subtool) {
  return switch (subtool) {
    WorldMapPaintSubtool.tile => 'Éléments',
    WorldMapPaintSubtool.terrain => 'Terrain',
    WorldMapPaintSubtool.path => 'Chemin',
    WorldMapPaintSubtool.surface => 'Surface',
    WorldMapPaintSubtool.border => 'Bordures',
    WorldMapPaintSubtool.collision => 'Collision',
  };
}

class _WorldMapPaintLayerChoiceGuidance extends StatelessWidget {
  const _WorldMapPaintLayerChoiceGuidance({
    required this.map,
    required this.intent,
    required this.onSelected,
  });

  final MapData map;
  final WorldMapPaintInspectionIntent intent;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final layerType = _requiredLayerLabel(intent.subtool);
    final layers = <MapLayer>[
      for (final layerId in intent.compatibleLayerIds)
        for (final layer in map.layers)
          if (layer.id == layerId) layer,
    ];
    return Semantics(
      key: const ValueKey<String>(
        'world-map-paint-layer-choice-guidance',
      ),
      container: true,
      label: 'Choix du calque de $layerType. '
          '${layers.length} calques compatibles.',
      child: SingleChildScrollView(
        key: const ValueKey<String>('world-map-paint-layer-choice-scroll'),
        child: PokeMapEmptyState(
          icon: const Icon(Icons.layers_outlined),
          title: 'Choisir un calque de $layerType',
          description: 'Plusieurs calques sont compatibles. Choisissez celui '
              'à utiliser avant de peindre.',
          action: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final layer in layers) ...[
                  Tooltip(
                    message: layer.name,
                    child: PokeMapButton(
                      key: ValueKey<String>(
                        'world-map-paint-layer-choice-${layer.id}',
                      ),
                      onPressed: () => onSelected(layer.id),
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.compact,
                      leading: const Icon(Icons.layers_outlined),
                      child: Text(layer.name),
                    ),
                  ),
                  if (layer != layers.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldMapPaintMissingLayerGuidance extends StatelessWidget {
  const _WorldMapPaintMissingLayerGuidance({
    required this.subtool,
    required this.onAdd,
  });

  final WorldMapPaintSubtool subtool;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final layerType = _requiredLayerLabel(subtool);
    final tool = _paintSubtoolLabel(subtool);
    final description =
        'L’outil $tool peint uniquement dans un calque de $layerType.';
    return Semantics(
      key: const ValueKey<String>(
        'world-map-paint-missing-layer-guidance',
      ),
      container: true,
      label: 'Calque de $layerType requis. $description',
      child: PokeMapEmptyState(
        icon: const Icon(Icons.add_to_photos_outlined),
        title: 'Calque de $layerType requis',
        description: description,
        action: PokeMapButton(
          key: const ValueKey<String>(
            'world-map-paint-add-required-layer',
          ),
          onPressed: onAdd,
          variant: PokeMapButtonVariant.primary,
          size: PokeMapButtonSize.compact,
          leading: const Icon(Icons.add_rounded),
          child: Text('Ajouter un calque de $layerType'),
        ),
      ),
    );
  }
}

void _addRequiredPaintLayer(
  EditorNotifier notifier,
  WorldMapPaintSubtool subtool,
) {
  switch (subtool) {
    case WorldMapPaintSubtool.surface:
      notifier.addSurfaceLayer(name: _requiredLayerDefaultName(subtool));
      return;
    case WorldMapPaintSubtool.tile:
    case WorldMapPaintSubtool.border:
    case WorldMapPaintSubtool.collision:
      notifier.addMapLayer(
        kind: switch (subtool) {
          WorldMapPaintSubtool.tile => MapLayerKind.tile,
          WorldMapPaintSubtool.border => MapLayerKind.border,
          WorldMapPaintSubtool.collision => MapLayerKind.collision,
          WorldMapPaintSubtool.surface => throw StateError('unreachable'),
          WorldMapPaintSubtool.terrain ||
          WorldMapPaintSubtool.path =>
            throw StateError('Smart Tile presets are selected in Paint.'),
        },
        name: _requiredLayerDefaultName(subtool),
      );
      return;
    case WorldMapPaintSubtool.terrain:
    case WorldMapPaintSubtool.path:
      throw StateError('Smart Tile presets are selected in Paint.');
  }
}

String _requiredLayerLabel(WorldMapPaintSubtool subtool) {
  return switch (subtool) {
    WorldMapPaintSubtool.tile => 'tuiles',
    WorldMapPaintSubtool.terrain => 'terrain',
    WorldMapPaintSubtool.path => 'chemin',
    WorldMapPaintSubtool.surface => 'surface',
    WorldMapPaintSubtool.border => 'bordures',
    WorldMapPaintSubtool.collision => 'collision',
  };
}

String _requiredLayerDefaultName(WorldMapPaintSubtool subtool) {
  return switch (subtool) {
    WorldMapPaintSubtool.tile => 'Éléments',
    WorldMapPaintSubtool.terrain => 'Terrain',
    WorldMapPaintSubtool.path => 'Chemins',
    WorldMapPaintSubtool.surface => 'Surfaces',
    WorldMapPaintSubtool.border => 'Bordures',
    WorldMapPaintSubtool.collision => 'Collision',
  };
}

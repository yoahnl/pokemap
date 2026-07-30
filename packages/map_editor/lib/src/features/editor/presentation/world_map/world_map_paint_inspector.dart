import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../border_map_editing/presentation/border_layer_inspector_panel.dart';
import '../../../border_map_editing/state/border_map_editing_providers.dart';
import '../../../surface_painter/surface_palette_panel.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/terrain_map_panel.dart';
import '../../../../ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import '../../../../ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';
import '../../application/world_map_subtool_body_projector.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import 'world_map_collision_inspector.dart';
import 'world_map_paint_inspection_intent.dart';
import 'world_map_subtool_disabled_guidance.dart';
import 'world_map_workspace_session.dart';

class WorldMapPaintInspector extends ConsumerWidget {
  const WorldMapPaintInspector({super.key});

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
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MapPaletteAssetBrowserLauncher(label: 'Changer de source'),
                SizedBox(height: 10),
                Expanded(
                  child: MapLayerAssetPalette(),
                ),
              ],
            ),
          ),
        ),
      WorldMapSubtoolBodyKind.terrainPainter => TerrainMapPanel(
          embedded: true,
          mode: TerrainMapPanelMode.groundOnly,
          onTerrainPaintRequested: () => activate(
            const ActivateWorldMapPaint(WorldMapPaintSubtool.terrain),
          ),
        ),
      WorldMapSubtoolBodyKind.pathPainter => TerrainMapPanel(
          embedded: true,
          mode: TerrainMapPanelMode.surfaceOnly,
          onPathPaintRequested: () => activate(
            const ActivateWorldMapPaint(WorldMapPaintSubtool.path),
          ),
          onEraseRequested: () => activate(const ActivateWorldMapErase()),
        ),
      WorldMapSubtoolBodyKind.surfacePainter => SurfacePainterPanel(
          embedded: true,
          onSurfacePresetSelected: notifier.selectSurfacePresetForSetup,
          onPaintRequested: () => activate(
            const ActivateWorldMapPaint(WorldMapPaintSubtool.surface),
          ),
          onEraseRequested: () => activate(const ActivateWorldMapErase()),
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
    WorldMapPaintSubtool.path => 'Path',
    WorldMapPaintSubtool.surface => 'Surface',
    WorldMapPaintSubtool.border => 'Bordures',
    WorldMapPaintSubtool.collision => 'Collision',
  };
}

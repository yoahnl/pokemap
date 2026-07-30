import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/entity_properties_panel.dart';
import '../../../../ui/panels/event_properties_panel.dart';
import '../../../../ui/panels/gameplay_zone_properties_panel.dart';
import '../../../../ui/panels/trigger_properties_panel.dart';
import '../../../../ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import '../../../../ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';
import '../../../../ui/panels/warp_properties_panel.dart';
import '../../application/world_map_subtool_body_projector.dart';
import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import 'world_map_subtool_disabled_guidance.dart';
import 'world_map_workspace_session.dart';

class WorldMapPlaceInspector extends ConsumerWidget {
  const WorldMapPlaceInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtool = ref.watch(
      worldMapWorkspaceSessionProvider.select(
        (session) => session.lastPlacementSubtool,
      ),
    );
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          source: worldMapToolActivationSourceFromState(state),
          selectedId: switch (subtool) {
            WorldMapPlacementSubtool.object => null,
            WorldMapPlacementSubtool.entity => state.selectedEntityId,
            WorldMapPlacementSubtool.event => state.selectedMapEventId,
            WorldMapPlacementSubtool.trigger => state.selectedTriggerId,
            WorldMapPlacementSubtool.warp => state.selectedWarpId,
            WorldMapPlacementSubtool.gameplayZone =>
              state.selectedGameplayZoneId,
          },
        ),
      ),
    );
    final projection = const WorldMapSubtoolBodyProjector().project(
      source: snapshot.source,
      request: ActivateWorldMapPlacement(subtool),
    );
    if (!projection.isAvailable) {
      return WorldMapSubtoolDisabledGuidance(
        title: 'Placer · ${_placementSubtoolLabel(subtool)}',
        reason: projection.disabledReason!,
        icon: const Icon(Icons.add_location_alt_outlined),
      );
    }

    return KeyedSubtree(
      key: ValueKey<String>(
        'world-map-place-body-${projection.bodyKind.name}',
      ),
      child: switch (projection.bodyKind) {
        WorldMapSubtoolBodyKind.elementsPalette => Semantics(
            container: true,
            label: 'Catalogue d’objets du calque actif',
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MapPaletteAssetBrowserLauncher(label: 'Changer de source'),
                  SizedBox(height: 10),
                  Expanded(
                    child: MapLayerAssetPalette(
                      mode: MapLayerAssetPaletteMode.elements,
                    ),
                  ),
                ],
              ),
            ),
          ),
        WorldMapSubtoolBodyKind.entityPlacement => _placementBody(
            subtool: subtool,
            bodyKind: projection.bodyKind,
            selectedId: snapshot.selectedId,
            items: snapshot.source.activeMap?.entities,
            readId: (item) => item.id,
            panel: const EntityPropertiesPanel(embedded: true),
            guidanceAction: const EntityPlacementKindPicker(),
          ),
        WorldMapSubtoolBodyKind.eventPlacement => _placementBody(
            subtool: subtool,
            bodyKind: projection.bodyKind,
            selectedId: snapshot.selectedId,
            items: snapshot.source.activeMap?.events,
            readId: (item) => item.id,
            panel: const EventPropertiesPanel(embedded: true),
          ),
        WorldMapSubtoolBodyKind.triggerPlacement => _placementBody(
            subtool: subtool,
            bodyKind: projection.bodyKind,
            selectedId: snapshot.selectedId,
            items: snapshot.source.activeMap?.triggers,
            readId: (item) => item.id,
            panel: const TriggerPropertiesPanel(embedded: true),
          ),
        WorldMapSubtoolBodyKind.warpPlacement => _placementBody(
            subtool: subtool,
            bodyKind: projection.bodyKind,
            selectedId: snapshot.selectedId,
            items: snapshot.source.activeMap?.warps,
            readId: (item) => item.id,
            panel: const WarpPropertiesPanel(embedded: true),
          ),
        WorldMapSubtoolBodyKind.gameplayZonePlacement => _placementBody(
            subtool: subtool,
            bodyKind: projection.bodyKind,
            selectedId: snapshot.selectedId,
            items: snapshot.source.activeMap?.gameplayZones,
            readId: (item) => item.id,
            panel: const GameplayZonePropertiesPanel(embedded: true),
          ),
        WorldMapSubtoolBodyKind.tilesPalette ||
        WorldMapSubtoolBodyKind.terrainPainter ||
        WorldMapSubtoolBodyKind.pathPainter ||
        WorldMapSubtoolBodyKind.surfacePainter ||
        WorldMapSubtoolBodyKind.borderInspector ||
        WorldMapSubtoolBodyKind.collisionInspector =>
          throw StateError(
            'A paint body cannot be projected for Place.',
          ),
      },
    );
  }
}

Widget _placementBody<T>({
  required WorldMapPlacementSubtool subtool,
  required WorldMapSubtoolBodyKind bodyKind,
  required String? selectedId,
  required Iterable<T>? items,
  required String Function(T item) readId,
  required Widget panel,
  Widget? guidanceAction,
}) {
  final resolved = selectedId != null &&
      items?.any((item) => readId(item) == selectedId) == true;
  if (resolved) {
    return KeyedSubtree(
      key: ValueKey<String>(
        'world-map-place-selection-${subtool.name}-$selectedId',
      ),
      child: panel,
    );
  }
  return _WorldMapPlacementGuidance(
    key: ValueKey<String>(
      'world-map-placement-guidance-${bodyKind.name}',
    ),
    subtool: subtool,
    action: guidanceAction,
  );
}

class _WorldMapPlacementGuidance extends StatelessWidget {
  const _WorldMapPlacementGuidance({
    super.key,
    required this.subtool,
    this.action,
  });

  final WorldMapPlacementSubtool subtool;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final label = _placementSubtoolLabel(subtool);
    return Semantics(
      container: true,
      label: 'Placement $label',
      child: PokeMapEmptyState(
        icon: const Icon(Icons.add_location_alt_outlined),
        title: 'Placer · $label',
        description:
            'Cliquez sur la carte pour placer un élément de ce type. Ses '
            'propriétés apparaîtront ici dès qu’il sera sélectionné.',
        action: action,
      ),
    );
  }
}

String _placementSubtoolLabel(WorldMapPlacementSubtool subtool) {
  return switch (subtool) {
    WorldMapPlacementSubtool.object => 'Objet',
    WorldMapPlacementSubtool.entity => 'Entity',
    WorldMapPlacementSubtool.event => 'Event',
    WorldMapPlacementSubtool.trigger => 'Trigger',
    WorldMapPlacementSubtool.warp => 'Warp',
    WorldMapPlacementSubtool.gameplayZone => 'Gameplay zone',
  };
}

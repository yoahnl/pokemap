import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import '../../../../ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';
import '../../application/world_map_tool_family.dart';
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
    if (subtool != WorldMapPlacementSubtool.object) {
      final label = _placementSubtoolLabel(subtool);
      return PokeMapEmptyState(
        icon: const Icon(Icons.add_location_alt_outlined),
        title: 'Placer · $label',
        description:
            'Les réglages dédiés à $label arriveront dans leur lot applicatif. '
            'Aucune donnée de carte n’est modifiée depuis cette guidance.',
      );
    }
    return Semantics(
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

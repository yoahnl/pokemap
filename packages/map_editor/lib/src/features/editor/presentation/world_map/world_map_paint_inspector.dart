import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import '../../../../ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';
import '../../application/world_map_tool_family.dart';
import 'world_map_workspace_session.dart';

class WorldMapPaintInspector extends ConsumerWidget {
  const WorldMapPaintInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtool = ref.watch(
      worldMapWorkspaceSessionProvider.select(
        (session) => session.lastPaintSubtool,
      ),
    );
    if (subtool != WorldMapPaintSubtool.tile) {
      final label = _paintSubtoolLabel(subtool);
      return PokeMapEmptyState(
        icon: const Icon(Icons.brush_outlined),
        title: 'Peindre · $label',
        description:
            'Les réglages dédiés à $label arriveront dans leur lot applicatif. '
            'Aucune donnée de carte n’est modifiée depuis cette guidance.',
      );
    }
    return Semantics(
      container: true,
      label: 'Palette de tuiles du calque actif',
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MapPaletteAssetBrowserLauncher(label: 'Changer de source'),
            SizedBox(height: 10),
            Expanded(
              child: MapLayerAssetPalette(
                mode: MapLayerAssetPaletteMode.tiles,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _paintSubtoolLabel(WorldMapPaintSubtool subtool) {
  return switch (subtool) {
    WorldMapPaintSubtool.tile => 'Tuiles',
    WorldMapPaintSubtool.terrain => 'Terrain',
    WorldMapPaintSubtool.path => 'Path',
    WorldMapPaintSubtool.surface => 'Surface',
    WorldMapPaintSubtool.border => 'Bordures',
    WorldMapPaintSubtool.collision => 'Collision',
  };
}

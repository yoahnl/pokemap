import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'map_encounter_mode_picker.dart';
import 'map_workspace_view_state.dart';

class MapWorkspaceToolStrip extends StatelessWidget {
  const MapWorkspaceToolStrip({
    super.key,
    required this.view,
    required this.onChanged,
    required this.onMoreTools,
    required this.onResources,
    required this.storyAvailable,
  });

  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback onMoreTools;
  final VoidCallback onResources;
  final bool storyAvailable;

  @override
  Widget build(BuildContext context) {
    final active = view.tool.name.startsWith('encounter')
        ? 'Zones'
        : switch (view.tool) {
            StudioMapTool.place => 'Décors',
            StudioMapTool.terrain => 'Terrains',
            StudioMapTool.gameplayZone || StudioMapTool.zone => 'Zones',
            StudioMapTool.warp => 'Passages',
            _ => 'Sélection',
          };
    void select(String label) {
      switch (label) {
        case 'Sélection':
          view.tool = StudioMapTool.select;
        case 'Décors':
          view.paletteTab = 'Décors';
          view.tool = view.brush == null
              ? StudioMapTool.select
              : StudioMapTool.place;
        case 'Terrains':
          view.paletteTab = 'Terrains';
          view.tool = view.terrain == null
              ? StudioMapTool.select
              : StudioMapTool.terrain;
        case 'Zones':
          view.tool = StudioMapTool.gameplayZone;
        case 'Passages':
          view.prepareWarpPlacement();
      }
      onChanged();
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StudioTool(
                key: const ValueKey('Sélectionner'),
                label: 'Sélectionner',
                icon: Icons.near_me_outlined,
                selected: active == 'Sélection',
                onPressed: () => select('Sélection'),
              ),
              const SizedBox(width: 6),
              StudioTool(
                label: 'Gomme de tuiles',
                icon: Icons.auto_fix_normal,
                selected: view.tool == StudioMapTool.erase,
                onPressed: () {
                  view.tool = StudioMapTool.erase;
                  onChanged();
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (label, icon) in const [
                        ('Décors', Icons.brush_outlined),
                        ('Terrains', Icons.terrain),
                        ('Zones', Icons.grid_on_outlined),
                        ('Passages', Icons.meeting_room_outlined),
                      ]) ...[
                        StudioButton(
                          label: label,
                          icon: icon,
                          secondary: active != label,
                          onPressed: () => select(label),
                        ),
                        const SizedBox(width: 6),
                      ],
                      StudioTool(
                        label: 'Autres outils de carte',
                        icon: Icons.more_horiz,
                        onPressed: onMoreTools,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              StudioButton(
                label: 'Gérer les ressources',
                secondary: true,
                onPressed: onResources,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              StudioTool(
                label: 'Déplacer la vue',
                icon: Icons.pan_tool_outlined,
                selected: view.tool == StudioMapTool.pan,
                onPressed: () {
                  view.tool = StudioMapTool.pan;
                  onChanged();
                },
              ),
              StudioTool(
                label: 'Peindre',
                icon: Icons.brush_outlined,
                onPressed:
                    view.tile == null &&
                        view.brush == null &&
                        view.terrain == null
                    ? null
                    : () {
                        view.tool = view.terrain != null
                            ? StudioMapTool.terrain
                            : view.brush != null
                            ? StudioMapTool.place
                            : StudioMapTool.paint;
                        onChanged();
                      },
              ),
              StudioTool(
                label: 'Placer un personnage',
                icon: Icons.person_add_alt,
                onPressed: () {
                  view.prepareCharacterPlacement();
                  onChanged();
                },
              ),
              StudioTool(
                label: 'Placer le départ du joueur',
                icon: Icons.flag_outlined,
                onPressed: () {
                  view.tool = StudioMapTool.spawn;
                  onChanged();
                },
              ),
              StudioTool(
                label: 'Placer un panneau',
                icon: Icons.signpost_outlined,
                onPressed: () {
                  view.tool = StudioMapTool.sign;
                  onChanged();
                },
              ),
              StudioTool(
                label: 'Dessiner une zone de jeu',
                icon: Icons.grass_outlined,
                onPressed: () {
                  view.tool = StudioMapTool.gameplayZone;
                  onChanged();
                },
              ),
              StudioTool(
                label: 'Dessiner une zone d’histoire',
                icon: Icons.crop_square,
                onPressed: storyAvailable
                    ? () {
                        view.tool = StudioMapTool.zone;
                        onChanged();
                      }
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: MapEncounterModePicker(view: view, onChanged: onChanged),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

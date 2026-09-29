import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'map_encounter_mode_picker.dart';
import 'map_workspace_tool_strip_selection.dart';
import 'map_workspace_view_state.dart';

class MapWorkspaceToolStrip extends StatelessWidget {
  const MapWorkspaceToolStrip({
    super.key,
    required this.view,
    required this.onChanged,
    required this.onMoreTools,
    required this.onResources,
    required this.storyAvailable,
    required this.paletteVisible,
    required this.onUndo,
    required this.onRedo,
  });

  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback onMoreTools;
  final VoidCallback onResources;
  final bool storyAvailable;
  final bool paletteVisible;
  final VoidCallback? onUndo, onRedo;

  @override
  Widget build(BuildContext context) {
    final extra = mapExtraToolSelection(view.tool);
    final active = view.tool.name.startsWith('encounter')
        ? 'Zones'
        : switch (view.tool) {
            StudioMapTool.place => 'Décors',
            StudioMapTool.terrain => 'Terrains',
            StudioMapTool.gameplayZone || StudioMapTool.zone => 'Zones',
            StudioMapTool.border => 'Bordures',
            StudioMapTool.collisionPaint ||
            StudioMapTool.collisionErase => 'Collisions',
            StudioMapTool.warp => 'Passages',
            StudioMapTool.select => 'Sélection',
            _ => '',
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
        case 'Bordures':
          view.tool = StudioMapTool.border;
        case 'Collisions':
          view.tool = StudioMapTool.collisionPaint;
        case 'Passages':
          view.prepareWarpPlacement();
      }
      onChanged();
      if (!paletteVisible &&
          (label == 'Décors' || label == 'Terrains' || label == 'Passages')) {
        onMoreTools();
      }
    }

    void selectExtra(String label) {
      switch (label) {
        case 'Déplacer la vue':
          view.tool = StudioMapTool.pan;
        case 'Peindre':
          view.tool = view.terrain != null
              ? StudioMapTool.terrain
              : view.brush != null
              ? StudioMapTool.place
              : StudioMapTool.paint;
        case 'Gomme de tuiles':
          view.tool = StudioMapTool.erase;
        case 'Gomme de décors':
          view.tool = StudioMapTool.eraseDecor;
        case 'Peindre les collisions':
          view.tool = StudioMapTool.collisionPaint;
        case 'Effacer les collisions':
          view.tool = StudioMapTool.collisionErase;
        case 'Placer un personnage':
          view.prepareCharacterPlacement();
        case 'Placer le départ du joueur':
          view.tool = StudioMapTool.spawn;
        case 'Placer un panneau':
          view.tool = StudioMapTool.sign;
        case 'Passages':
          view.prepareWarpPlacement();
        case 'Dessiner une zone de jeu':
          view.tool = StudioMapTool.gameplayZone;
        case 'Dessiner une zone d’histoire':
          view.tool = StudioMapTool.zone;
        case 'Palette complète':
          onMoreTools();
          return;
        case 'Gérer les ressources':
          onResources();
          return;
      }
      onChanged();
      if (!paletteVisible &&
          (label == 'Placer un personnage' || label == 'Passages')) {
        onMoreTools();
      }
    }

    final zonesVisible = active == 'Zones';
    final collisionsVisible = active == 'Collisions';
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (label, icon) in const [
                        ('Sélection', Icons.near_me_outlined),
                        ('Décors', Icons.brush_outlined),
                        ('Terrains', Icons.terrain),
                        ('Bordures', Icons.timeline),
                        ('Zones', Icons.grid_on_outlined),
                        ('Collisions', Icons.block_outlined),
                        ('Passages', Icons.meeting_room_outlined),
                      ]) ...[
                        StudioButton(
                          key: label == 'Sélection'
                              ? const ValueKey('Sélectionner')
                              : null,
                          label: label,
                          icon: icon,
                          secondary: active != label,
                          onPressed: () => select(label),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Autres outils de carte',
                constraints: const BoxConstraints(minWidth: 300, maxWidth: 340),
                onSelected: selectExtra,
                itemBuilder: (context) => [
                  for (final (label, icon) in const [
                    ('Déplacer la vue', Icons.pan_tool_outlined),
                    ('Peindre', Icons.brush_outlined),
                    ('Gomme de tuiles', Icons.auto_fix_normal),
                    ('Gomme de décors', Icons.delete_outline),
                    ('Peindre les collisions', Icons.block_outlined),
                    (
                      'Effacer les collisions',
                      Icons.cleaning_services_outlined,
                    ),
                    ('Placer un personnage', Icons.person_add_alt),
                    ('Placer le départ du joueur', Icons.flag_outlined),
                    ('Placer un panneau', Icons.signpost_outlined),
                    ('Passages', Icons.meeting_room_outlined),
                    ('Dessiner une zone de jeu', Icons.grass_outlined),
                    ('Palette complète', Icons.open_in_full),
                    ('Gérer les ressources', Icons.grid_view_outlined),
                  ])
                    PopupMenuItem(
                      value: label,
                      enabled:
                          label != 'Peindre' ||
                          view.tile != null ||
                          view.brush != null ||
                          view.terrain != null,
                      child: Row(
                        children: [
                          Icon(icon, size: 18),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (storyAvailable)
                    const PopupMenuItem(
                      value: 'Dessiner une zone d’histoire',
                      child: Row(
                        children: [
                          Icon(Icons.crop_square, size: 18),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Dessiner une zone d’histoire',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  key: extra == null
                      ? null
                      : const ValueKey('active-extra-tool'),
                  constraints: const BoxConstraints(minHeight: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: extra == null
                        ? null
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(extra?.$2 ?? Icons.more_horiz, size: 18),
                      if (extra != null) ...[
                        const SizedBox(width: 6),
                        Text(extra.$1),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              StudioTool(label: 'Annuler', icon: Icons.undo, onPressed: onUndo),
              const SizedBox(width: 6),
              StudioTool(
                label: 'Rétablir',
                icon: Icons.redo,
                onPressed: onRedo,
              ),
            ],
          ),
          if (zonesVisible) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: MapEncounterModePicker(
                    view: view,
                    onChanged: onChanged,
                  ),
                ),
                if (storyAvailable)
                  StudioTool(
                    label: 'Dessiner une zone d’histoire',
                    icon: Icons.crop_square,
                    selected: view.tool == StudioMapTool.zone,
                    onPressed: () {
                      view.tool = StudioMapTool.zone;
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
          if (collisionsVisible) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                StudioButton(
                  label: 'Bloquer les cases',
                  secondary: view.tool != StudioMapTool.collisionPaint,
                  onPressed: () {
                    view.tool = StudioMapTool.collisionPaint;
                    onChanged();
                  },
                ),
                StudioButton(
                  label: 'Libérer les cases',
                  secondary: view.tool != StudioMapTool.collisionErase,
                  onPressed: () {
                    view.tool = StudioMapTool.collisionErase;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'map_encounter_mode_picker.dart';
import 'map_workspace_tool_strip_selection.dart';
import 'map_workspace_view_state.dart';
part 'map_workspace_tool_strip_actions.dart';

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
            StudioMapTool.erase when view.terrain != null => 'Terrains',
            StudioMapTool.gameplayZone || StudioMapTool.zone => 'Zones',
            StudioMapTool.border => 'Bordures',
            StudioMapTool.environment => 'Environnements',
            StudioMapTool.collisionPaint ||
            StudioMapTool.collisionErase => 'Collisions',
            StudioMapTool.warp => 'Passages',
            StudioMapTool.select => 'Sélection',
            _ => '',
          };
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    const families = [
      ('Sélection', Icons.near_me_outlined),
      ('Décors', Icons.brush_outlined),
      ('Terrains', Icons.terrain),
      ('Bordures', Icons.timeline),
      ('Environnements', Icons.forest_outlined),
      ('Zones', Icons.grid_on_outlined),
      ('Collisions', Icons.block_outlined),
      ('Passages', Icons.meeting_room_outlined),
    ];
    Widget familyButton(String label, IconData icon) => StudioButton(
      key: label == 'Sélection' ? const ValueKey('Sélectionner') : null,
      label: label,
      icon: largeText ? null : icon,
      secondary: active != label,
      onPressed: () => _select(label),
    );
    final moreTools = PopupMenuButton<String>(
      tooltip: 'Autres outils de carte',
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 340),
      onSelected: _selectExtra,
      itemBuilder: (context) => [
        for (final (label, icon) in const [
          ('Déplacer la vue', Icons.pan_tool_outlined),
          ('Peindre', Icons.brush_outlined),
          ('Gomme de tuiles', Icons.auto_fix_normal),
          ('Gomme de décors', Icons.delete_outline),
          ('Peindre les collisions', Icons.block_outlined),
          ('Effacer les collisions', Icons.cleaning_services_outlined),
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
        key: extra == null ? null : const ValueKey('active-extra-tool'),
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
              Flexible(
                child: Text(
                  extra.$1,
                  maxLines: largeText ? 1 : null,
                  overflow: largeText ? TextOverflow.ellipsis : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final history = [
      StudioTool(label: 'Annuler', icon: Icons.undo, onPressed: onUndo),
      StudioTool(label: 'Rétablir', icon: Icons.redo, onPressed: onRedo),
    ];
    final zonesVisible = active == 'Zones';
    final collisionsVisible = active == 'Collisions';
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (largeText)
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (label, icon) in families.take(4))
                      Expanded(
                        flex: label.length + 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: familyButton(label, icon),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: moreTools),
                          for (final tool in history) ...[
                            const SizedBox(width: 6),
                            tool,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (label, icon) in families.skip(4))
                      Expanded(
                        flex: label.length + 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: familyButton(label, icon),
                        ),
                      ),
                  ],
                ),
              ],
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (label, icon) in families) familyButton(label, icon),
                moreTools,
                ...history,
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

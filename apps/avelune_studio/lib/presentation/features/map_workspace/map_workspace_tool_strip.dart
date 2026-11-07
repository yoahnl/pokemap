import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'map_encounter_mode_picker.dart';
import 'map_field_obstacle_placement_controls.dart';
import 'map_tool_command_runner.dart';
import 'map_workspace_commands.dart';
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
    this.spatial = false,
    this.exterior = false,
    this.elements = const [],
  });

  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback onMoreTools;
  final VoidCallback onResources;
  final bool storyAvailable;
  final bool spatial;
  final bool exterior;
  final List<ProjectElementEntry> elements;
  final bool paletteVisible;
  final VoidCallback? onUndo, onRedo;

  @override
  Widget build(BuildContext context) {
    final selection = mapExtraToolSelection(view.tool);
    final populating = mapPopulateToolSelection(view.tool);
    final extra = populating == null ? selection : null;
    final active = view.tool.name.startsWith('encounter')
        ? 'Zones'
        : switch (view.tool) {
            StudioMapTool.place => 'Décors',
            StudioMapTool.terrain => 'Terrains',
            StudioMapTool.erase when view.terrain != null || spatial =>
              'Terrains',
            StudioMapTool.gameplayZone || StudioMapTool.zone => 'Zones',
            StudioMapTool.border => 'Bordures',
            StudioMapTool.environment => 'Environnements',
            StudioMapTool.collisionPaint ||
            StudioMapTool.collisionErase => 'Collisions',
            StudioMapTool.warp => 'Passages',
            StudioMapTool.connection => 'Connexions',
            StudioMapTool.select => 'Sélection',
            _ => '',
          };
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final families = [
      ('Sélection', Icons.near_me_outlined),
      ('Décors', Icons.brush_outlined),
      ('Terrains', Icons.terrain),
      ('Bordures', Icons.timeline),
      ('Environnements', Icons.forest_outlined),
      if (!exterior) ...[
        ('Zones', Icons.grid_on_outlined),
        ('Collisions', Icons.block_outlined),
        ('Passages', Icons.meeting_room_outlined),
        ('Connexions', Icons.compare_arrows),
      ],
    ];
    final commandContext = MapCommandContext(
      spatial: spatial,
      exterior: exterior,
      storyAvailable: storyAvailable,
      paintReady:
          view.tile != null ||
          view.brush != null ||
          view.terrain != null ||
          (spatial && view.paletteTab == 'Terrains'),
    );
    String? unavailable(String label) =>
        mapCommandUnavailableForLabel(label, commandContext);
    bool supported(String label) => unavailable(label) == null;
    Widget familyButton(String label, IconData icon) => Tooltip(
      message: unavailable(label) ?? label,
      child: StudioButton(
        key: label == 'Sélection' ? const ValueKey('Sélectionner') : null,
        label: label,
        icon: largeText ? null : icon,
        secondary: active != label,
        onPressed: supported(label) ? () => _select(label) : null,
      ),
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
          ('Palette complète', Icons.open_in_full),
          ('Gérer les ressources', Icons.grid_view_outlined),
        ])
          if (!exterior || supported(label))
            PopupMenuItem(
              value: label,
              enabled: supported(label),
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
        if (supported('Dessiner une zone d’histoire'))
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
    final narrowPopulate = largeText || MediaQuery.sizeOf(context).width < 1280;
    final populate = PopupMenuButton<String>(
      tooltip: 'Peupler la carte',
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 460),
      onSelected: _selectExtra,
      itemBuilder: (context) => [
        for (final (label, icon) in mapPopulateTools)
          PopupMenuItem(
            value: label,
            enabled: supported(label),
            child: Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    supported(label)
                        ? label
                        : '$label · ${spatial ? 'indisponible en 3D' : 'indisponible'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        key: populating == null ? null : const ValueKey('active-populate-tool'),
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: populating == null
              ? null
              : Theme.of(context).colorScheme.primaryContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(populating?.$2 ?? Icons.person_add_alt, size: 18),
            if (populating != null || !narrowPopulate) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  populating?.$1 ?? 'Peupler',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
    final history = [
      StudioTool(label: 'Annuler', icon: Icons.undo, onPressed: onUndo),
      StudioTool(label: 'Rétablir', icon: Icons.redo, onPressed: onRedo),
    ];
    final zonesVisible = !exterior && active == 'Zones';
    final collisionsVisible = !exterior && active == 'Collisions';
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
                          if (!exterior) Flexible(child: populate),
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
                if (!exterior) populate,
                moreTools,
                ...history,
              ],
            ),
          if (view.tool == StudioMapTool.fieldObstacle && !spatial) ...[
            const SizedBox(height: 8),
            MapFieldObstaclePlacementControls(
              view: view,
              elements: elements,
              onChanged: onChanged,
            ),
          ],
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
                if (storyAvailable && !spatial)
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

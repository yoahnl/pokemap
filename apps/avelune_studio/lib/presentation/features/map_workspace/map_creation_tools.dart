import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'map_workspace_view_state.dart';

class MapCreationTools extends StatelessWidget {
  const MapCreationTools({
    super.key,
    required this.view,
    required this.onChanged,
    required this.storyAvailable,
  });
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final bool storyAvailable;

  @override
  Widget build(BuildContext context) {
    void activate(StudioMapTool tool) {
      view.tool = tool;
      onChanged();
    }

    final brush = view.character != null
        ? StudioMapTool.character
        : view.terrain != null
        ? StudioMapTool.terrain
        : view.brush != null
        ? StudioMapTool.place
        : StudioMapTool.paint;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Outils', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StudioTool(
                label: 'Sélectionner',
                icon: Icons.near_me_outlined,
                shortcut: 'Échap',
                selected: view.tool == StudioMapTool.select,
                onPressed: () => activate(StudioMapTool.select),
              ),
              StudioTool(
                label: 'Déplacer la vue',
                icon: Icons.pan_tool_outlined,
                selected: view.tool == StudioMapTool.pan,
                onPressed: () => activate(StudioMapTool.pan),
              ),
              StudioTool(
                label: 'Peindre',
                icon: Icons.brush_outlined,
                selected: [
                  StudioMapTool.paint,
                  StudioMapTool.place,
                  StudioMapTool.terrain,
                ].contains(view.tool),
                onPressed:
                    view.tile != null ||
                        view.brush != null ||
                        view.terrain != null
                    ? () => activate(brush)
                    : null,
              ),
              StudioTool(
                label: 'Gomme de tuiles',
                icon: Icons.auto_fix_normal,
                selected: view.tool == StudioMapTool.erase,
                onPressed: () => activate(StudioMapTool.erase),
              ),
              StudioTool(
                label: 'Placer un personnage',
                icon: Icons.person_add_alt,
                selected: view.tool == StudioMapTool.character,
                onPressed: () {
                  view.paletteTab = 'Personnages';
                  if (view.character != null) {
                    view.tool = StudioMapTool.character;
                  }
                  onChanged();
                },
              ),
              StudioTool(
                label: 'Dessiner une zone d’histoire',
                icon: Icons.crop_square,
                selected: view.tool == StudioMapTool.zone,
                onPressed: storyAvailable
                    ? () => activate(StudioMapTool.zone)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

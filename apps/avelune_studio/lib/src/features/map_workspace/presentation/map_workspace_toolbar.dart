import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../shared/design_system/studio_workspace_controls.dart';
import '../application/map_workspace_controller.dart';
import 'map_workspace_view_state.dart';

class MapWorkspaceToolbar extends StatelessWidget {
  const MapWorkspaceToolbar({
    super.key,
    required this.controller,
    required this.view,
    required this.onChanged,
    required this.onActivate,
    required this.onSave,
    required this.onTest,
    required this.onClose,
  });
  final MapWorkspaceController controller;
  final MapWorkspaceViewState? view;
  final VoidCallback onChanged;
  final void Function(ProjectMapEntry) onActivate;
  final VoidCallback? onSave;
  final VoidCallback? onTest;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    final document = controller.active;
    void tool(StudioMapTool tool) {
      view?.tool = tool;
      onChanged();
    }

    void zoom(double factor) {
      final transform = view?.transform;
      if (transform == null) return;
      final scale = transform.value.getMaxScaleOnAxis();
      if (scale * factor < .15 || scale * factor > 8) return;
      transform.value = transform.value.clone()
        ..scaleByDouble(factor, factor, 1, 1);
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 210,
            child: DropdownButton<String>(
              isExpanded: true,
              key: ValueKey(document?.base.mapId),
              value: document?.base.mapId,
              hint: const Text('Choisir une carte'),
              items: [
                for (final entry
                    in controller.project?.maps ?? <ProjectMapEntry>[])
                  DropdownMenuItem(
                    value: entry.id,
                    child: Text(
                      '${controller.documents[entry.id]?.dirty == true ? '• ' : ''}${entry.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                final entry = controller.project?.maps
                    .where((e) => e.id == id)
                    .firstOrNull;
                if (entry != null) onActivate(entry);
              },
            ),
          ),
          StudioTool(
            label: 'Sélectionner',
            icon: Icons.near_me_outlined,
            selected: view?.tool == StudioMapTool.select,
            onPressed: () => tool(StudioMapTool.select),
          ),
          StudioTool(
            label: 'Déplacer la vue',
            icon: Icons.pan_tool_outlined,
            selected: view?.tool == StudioMapTool.pan,
            onPressed: () => tool(StudioMapTool.pan),
          ),
          StudioTool(
            label: 'Gomme de tuiles',
            icon: Icons.auto_fix_normal,
            selected: view?.tool == StudioMapTool.erase,
            onPressed: () => tool(StudioMapTool.erase),
          ),
          StudioTool(
            label: 'Annuler',
            icon: Icons.undo,
            shortcut: '⌘Z / CtrlZ',
            onPressed: document?.canUndo == true
                ? () {
                    document!.restore(redo: false);
                    onChanged();
                  }
                : null,
          ),
          StudioTool(
            label: 'Rétablir',
            icon: Icons.redo,
            shortcut: '⌘⇧Z / Ctrl⇧Z',
            onPressed: document?.canRedo == true
                ? () {
                    document!.restore(redo: true);
                    onChanged();
                  }
                : null,
          ),
          StudioTool(
            label: 'Zoom arrière',
            icon: Icons.remove,
            onPressed: () => zoom(.8),
          ),
          StudioTool(
            label: 'Zoom avant',
            icon: Icons.add,
            onPressed: () => zoom(1.25),
          ),
          StudioTool(
            label: 'Recentrer',
            icon: Icons.center_focus_strong,
            onPressed: () {
              view?.recenter?.call();
            },
          ),
          StudioTool(
            label: 'Afficher la grille',
            icon: Icons.grid_on,
            selected: view?.grid ?? false,
            onPressed: () {
              if (view != null) view!.grid = !view!.grid;
              onChanged();
            },
          ),
          StudioTool(
            label: 'Enregistrer',
            icon: Icons.save_outlined,
            shortcut: '⌘S / CtrlS',
            onPressed: onSave,
          ),
          StudioTool(
            label: 'Enregistrer et tester',
            icon: Icons.play_arrow,
            onPressed: onTest,
          ),
          StudioTool(
            label: 'Fermer le projet',
            icon: Icons.close,
            onPressed: onClose,
          ),
          Text(
            document?.saving == true
                ? 'Enregistrement…'
                : document?.dirty == true
                ? 'Modifications non enregistrées'
                : 'Enregistré',
          ),
        ],
      ),
    );
  }
}

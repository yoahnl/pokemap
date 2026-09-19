import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
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
    required this.onPalette,
    required this.onInspector,
    required this.paletteVisible,
    required this.inspectorVisible,
  });
  final MapWorkspaceController controller;
  final MapWorkspaceViewState? view;
  final VoidCallback onChanged, onClose, onPalette, onInspector;
  final ValueChanged<ProjectMapEntry> onActivate;
  final VoidCallback? onSave, onTest;
  final bool paletteVisible, inspectorVisible;

  @override
  Widget build(BuildContext context) {
    final document = controller.active;
    void zoom(double factor) {
      final transform = view?.transform;
      if (transform == null) return;
      final scale = transform.value.getMaxScaleOnAxis();
      if (scale * factor < .15 || scale * factor > 8) return;
      transform.value = transform.value.clone()
        ..scaleByDouble(factor, factor, 1, 1);
    }

    final actions = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StudioTool(
          label: 'Annuler',
          icon: Icons.undo,
          shortcut: '⌘Z / CtrlZ',
          onPressed: document?.canUndo == true
              ? () {
                  controller.restore(redo: false);
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
                  controller.restore(redo: true);
                  onChanged();
                }
              : null,
        ),
        StudioButton(
          key: const ValueKey('Enregistrer'),
          label: 'Enregistrer',
          icon: Icons.save_outlined,
          secondary: true,
          onPressed: onSave,
        ),
        Tooltip(
          message: 'Enregistrer et tester',
          child: StudioButton(
            key: const ValueKey('Enregistrer et tester'),
            label: 'Tester la carte',
            icon: Icons.play_arrow,
            onPressed: onTest,
          ),
        ),
      ],
    );
    final controls = Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StudioTool(
          label: 'Zoom arrière',
          icon: Icons.remove,
          onPressed: () => zoom(.8),
        ),
        if (view != null)
          ValueListenableBuilder<Matrix4>(
            valueListenable: view!.transform,
            builder: (context, value, _) => SizedBox(
              width: MediaQuery.textScalerOf(context).scale(52),
              child: Text(
                '${(value.getMaxScaleOnAxis() * 100).round()} %',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        StudioTool(
          label: 'Zoom avant',
          icon: Icons.add,
          onPressed: () => zoom(1.25),
        ),
        StudioTool(
          label: 'Recentrer',
          icon: Icons.center_focus_strong,
          onPressed: () => view?.recenter?.call(),
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
          label: 'Palette',
          icon: Icons.view_sidebar_outlined,
          selected: paletteVisible,
          onPressed: onPalette,
        ),
        StudioTool(
          label: 'Inspecteur',
          icon: Icons.tune,
          selected: inspectorVisible,
          onPressed: onInspector,
        ),
      ],
    );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final map = SizedBox(
              width: bounds.maxWidth < 500 ? 170 : 210,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
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
                          maxLines: 1,
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
            );
            final status = Text(
              document?.saving == true
                  ? 'Enregistrement…'
                  : document?.dirty == true
                  ? 'Non enregistré'
                  : 'Enregistré',
              style: Theme.of(context).textTheme.bodySmall,
            );
            return Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [map, status, actions, controls],
            );
          },
        ),
      ),
    );
  }
}

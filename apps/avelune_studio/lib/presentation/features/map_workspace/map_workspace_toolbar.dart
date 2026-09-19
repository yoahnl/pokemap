import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';

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
  final VoidCallback onChanged;
  final void Function(ProjectMapEntry) onActivate;
  final VoidCallback? onSave;
  final VoidCallback? onTest;
  final VoidCallback onClose;
  final VoidCallback onPalette;
  final VoidCallback onInspector;
  final bool paletteVisible;
  final bool inspectorVisible;

  @override
  Widget build(BuildContext context) {
    final document = controller.active;
    final colors = Theme.of(context).colorScheme;
    void tool(StudioMapTool value) {
      view?.tool = value;
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

    return Material(
      color: colors.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_mosaic_outlined,
                  color: colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.session.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        document?.saving == true
                            ? 'Enregistrement…'
                            : document?.dirty == true
                            ? 'Modifications non enregistrées'
                            : 'Enregistré',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
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
                const SizedBox(width: 12),
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
                const SizedBox(width: 12),
                StudioTool(
                  label: 'Fermer le projet',
                  icon: Icons.close,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 195,
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        StudioTool(
                          label: 'Sélectionner',
                          icon: Icons.near_me_outlined,
                          selected: view?.tool == StudioMapTool.select,
                          onPressed: () => tool(StudioMapTool.select),
                        ),
                        StudioTool(
                          label: 'Peindre',
                          icon: Icons.brush_outlined,
                          selected:
                              view?.tool == StudioMapTool.paint ||
                              view?.tool == StudioMapTool.place ||
                              view?.tool == StudioMapTool.terrain ||
                              view?.tool == StudioMapTool.character,
                          onPressed:
                              view?.tile != null ||
                                  view?.brush != null ||
                                  view?.terrain != null ||
                                  view?.character != null
                              ? () => tool(
                                  view?.character != null
                                      ? StudioMapTool.character
                                      : view?.terrain != null
                                      ? StudioMapTool.terrain
                                      : view?.brush != null
                                      ? StudioMapTool.place
                                      : StudioMapTool.paint,
                                )
                              : null,
                        ),
                        StudioTool(
                          label: 'Gomme de tuiles',
                          icon: Icons.auto_fix_normal,
                          selected: view?.tool == StudioMapTool.erase,
                          onPressed: () => tool(StudioMapTool.erase),
                        ),
                        StudioTool(
                          label: 'Dessiner une zone d’histoire',
                          icon: Icons.crop_square,
                          selected: view?.tool == StudioMapTool.zone,
                          onPressed: () => tool(StudioMapTool.zone),
                        ),
                        StudioTool(
                          label: 'Déplacer la vue',
                          icon: Icons.pan_tool_outlined,
                          selected: view?.tool == StudioMapTool.pan,
                          onPressed: () => tool(StudioMapTool.pan),
                        ),
                        const SizedBox(width: 18),
                        StudioTool(
                          label: 'Zoom arrière',
                          icon: Icons.remove,
                          onPressed: () => zoom(.8),
                        ),
                        if (view != null)
                          ValueListenableBuilder<Matrix4>(
                            valueListenable: view!.transform,
                            builder: (context, value, _) => SizedBox(
                              width: MediaQuery.textScalerOf(context).scale(58),
                              child: Text(
                                '${(value.getMaxScaleOnAxis() * 100).round()} %',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_sidebar.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import '../../shared/widgets/layout/studio_depth_control.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';

class MapWorkspaceInspector extends StatefulWidget {
  const MapWorkspaceInspector({
    super.key,
    required this.project,
    required this.document,
    required this.visuals,
    required this.onChanged,
    this.onOpenResource,
    this.onEditResource,
  });
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onChanged;
  final ValueChanged<ProjectElementEntry>? onOpenResource;
  final ValueChanged<ProjectElementEntry>? onEditResource;
  @override
  State<MapWorkspaceInspector> createState() => _MapWorkspaceInspectorState();
}

class _MapWorkspaceInspectorState extends State<MapWorkspaceInspector> {
  late Map<String, ProjectElementEntry> entries;
  ProjectManifest get project => widget.project;
  EditableMapDocument get document => widget.document;
  MapWorkspaceVisuals get visuals => widget.visuals;
  VoidCallback get onChanged => widget.onChanged;
  @override
  void initState() {
    super.initState();
    _index();
  }

  @override
  void didUpdateWidget(MapWorkspaceInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(project, oldWidget.project)) _index();
  }

  void _index() {
    entries = {for (final entry in project.elements) entry.id: entry};
  }

  @override
  Widget build(BuildContext context) {
    final commands = MapEditingCommands(document, project);
    final position = document.stackPosition;
    final stack = position == null
        ? <MapPlacedElement>[]
        : commands.stack(position);
    final selected = document.selected;
    final entry = entries[selected?.elementId];
    final rank = stack.indexWhere((e) => e.id == selected?.id);
    void change(void Function() action) {
      action();
      onChanged();
    }

    return StudioSidebar(
      width: 270,
      child: CustomScrollView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspecteur',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (entry != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: StudioAssetPreview(
                      height: 120,
                      child: visuals.thumbnail(entry, size: 100),
                    ),
                  ),
                Text(
                  entry?.name ??
                      (selected == null
                          ? 'Cliquez un décor sur la carte.'
                          : 'Ressource manquante'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selected != null) ...[
                  const SizedBox(height: 6),
                  Text('Coordonnées : ${selected.pos.x}, ${selected.pos.y}'),
                  if (rank >= 0)
                    Text('Position ${rank + 1} / ${stack.length} · 1 = devant'),
                  if (entry != null) ...[
                    const SizedBox(height: 8),
                    const Text('Instance placée · définition partagée'),
                    StudioButton(
                      label: 'Ouvrir la ressource',
                      secondary: true,
                      onPressed: () => widget.onOpenResource?.call(entry),
                    ),
                    const SizedBox(height: 6),
                    StudioButton(
                      label: 'Modifier le décor',
                      secondary: true,
                      onPressed: () => widget.onEditResource?.call(entry),
                    ),
                  ],
                  const SizedBox(height: 8),
                  StudioDepthControl(
                    onForward: commands.canReorder(forward: true)
                        ? () => change(() => commands.reorder(forward: true))
                        : null,
                    onBackward: commands.canReorder(forward: false)
                        ? () => change(() => commands.reorder(forward: false))
                        : null,
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      StudioTool(
                        label: 'Supprimer le décor',
                        icon: Icons.delete_outline,
                        shortcut: '⌫',
                        onPressed: () => change(commands.deleteSelected),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ordre local entre décors compatibles.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Empilement ici',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (stack.isEmpty)
                  const Text(
                    'Cliquez une zone occupée pour retrouver un décor masqué.',
                  ),
              ],
            ),
          ),
          SliverList.builder(
            itemCount: stack.length,
            itemBuilder: (context, index) {
              final instance = stack[index];
              final element = entries[instance.elementId];
              return StudioChoice(
                label: element?.name ?? 'Ressource manquante',
                subtitle: 'Position ${index + 1} / ${stack.length}',
                leading: element == null
                    ? null
                    : visuals.thumbnail(element, size: 36),
                selected: instance.id == document.selectedId,
                onTap: () {
                  document.selectedId = instance.id;
                  onChanged();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

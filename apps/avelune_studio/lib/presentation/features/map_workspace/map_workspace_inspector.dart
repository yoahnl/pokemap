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
import 'map_workspace_view_state.dart';

class MapWorkspaceInspector extends StatefulWidget {
  const MapWorkspaceInspector({
    super.key,
    required this.project,
    required this.document,
    required this.visuals,
    required this.view,
    required this.onChanged,
    this.onOpenResource,
    this.onEditResource,
    this.width = 300,
    this.tool = StudioMapTool.select,
  });
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final ValueChanged<ProjectElementEntry>? onOpenResource;
  final ValueChanged<ProjectElementEntry>? onEditResource;
  final double width;
  final StudioMapTool tool;
  @override
  State<MapWorkspaceInspector> createState() => _MapWorkspaceInspectorState();
}

class _MapWorkspaceInspectorState extends State<MapWorkspaceInspector> {
  late Map<String, ProjectElementEntry> entries;
  ProjectManifest get project => widget.project;
  EditableMapDocument get document => widget.document;
  MapWorkspaceVisuals get visuals => widget.visuals;
  MapWorkspaceViewState get view => widget.view;
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
    final category = project.elementCategories
        .where((category) => category.id == entry?.categoryId)
        .firstOrNull;
    final rank = stack.indexWhere((e) => e.id == selected?.id);
    void change(void Function() action) {
      action();
      onChanged();
    }

    return StudioSidebar(
      width: widget.width,
      child: CustomScrollView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected == null ? 'La carte' : 'Élément sélectionné',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (entry != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: StudioAssetPreview(
                      height: 104,
                      child: visuals.thumbnail(entry, size: 100),
                    ),
                  ),
                Text(
                  entry?.name ??
                      (selected == null
                          ? document.current.name
                          : 'Ressource manquante'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (selected == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${document.current.size.width} × ${document.current.size.height} cases',
                  ),
                  const SizedBox(height: 20),
                  Text(switch (widget.tool) {
                    StudioMapTool.select =>
                      'Sélectionnez un décor ou un personnage pour retrouver ses propriétés ici.',
                    StudioMapTool.pan =>
                      'Faites glisser la carte pour explorer. Le zoom reste conservé.',
                    StudioMapTool.place =>
                      'Choisissez un décor dans la palette, puis cliquez sur la carte pour le placer.',
                    StudioMapTool.paint =>
                      'Choisissez une tuile, puis peignez sur la carte.',
                    StudioMapTool.terrain =>
                      'Peignez le terrain choisi : les raccords se calculent automatiquement.',
                    StudioMapTool.character =>
                      'Choisissez un personnage, puis cliquez sur sa case de départ.',
                    StudioMapTool.warp =>
                      'Choisissez la carte de destination, puis cliquez sur la case du passage.',
                    StudioMapTool.spawn =>
                      'Cliquez la case où le joueur apparaît au début du jeu.',
                    StudioMapTool.sign =>
                      'Cliquez la case du panneau, puis écrivez son texte.',
                    StudioMapTool.zone =>
                      'Tracez une zone sur la carte pour lui associer une interaction.',
                    StudioMapTool.gameplayZone =>
                      'Tracez une zone de jeu : rencontres, déplacement, effet ou danger.',
                    StudioMapTool.erase =>
                      'Cliquez ou faites glisser pour effacer avec la gomme.',
                  }),
                ],
                if (selected != null) ...[
                  const SizedBox(height: 6),
                  Text('Coordonnées : ${selected.pos.x}, ${selected.pos.y}'),
                  if (rank >= 0)
                    Text('Position ${rank + 1} / ${stack.length} · 1 = devant'),
                  if (category != null) Text('Décor · ${category.name}'),
                  if (entry != null) ...[
                    const SizedBox(height: 8),
                    const Text('Cette instance · décor placé sur la carte'),
                    const SizedBox(height: 4),
                    Text(
                      'Définition partagée : ${entry.name}',
                      style: Theme.of(context).textTheme.bodySmall,
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
                    'Ordre local entre décors compatibles. Les collisions restent inchangées.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (stack.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Empilement ici',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Devant en haut · 1 = devant'),
                  const SizedBox(height: 6),
                ],
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
                  view.select(
                    document,
                    MapSelectionFamily.decor,
                    instance.id,
                  );
                  onChanged();
                },
              );
            },
          ),
          if (entry != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudioButton(
                      label: 'Ouvrir la ressource',
                      secondary: true,
                      onPressed: widget.onOpenResource == null
                          ? null
                          : () => widget.onOpenResource!(entry),
                    ),
                    const SizedBox(height: 6),
                    StudioButton(
                      label: 'Modifier la définition',
                      secondary: true,
                      onPressed: widget.onEditResource == null
                          ? null
                          : () => widget.onEditResource!(entry),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

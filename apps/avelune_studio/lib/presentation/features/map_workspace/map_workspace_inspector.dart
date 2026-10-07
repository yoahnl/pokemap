import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering show ScrollCacheExtent;
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
import 'map_workspace_tool_strip_selection.dart';
import 'map_decor_geometry_panel.dart';
import 'map_catalogue_properties.dart';
import '../../../features/map_workspace/application/spatial_model_editing_commands.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_preview.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/inputs/studio_select.dart';

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
    this.onRenameMap,
    this.width = 300,
    this.tool = StudioMapTool.select,
    this.showSelectionSummary = true,
  });
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final ValueChanged<ProjectElementEntry>? onOpenResource, onEditResource;
  final VoidCallback? onRenameMap;
  final double width;
  final StudioMapTool tool;
  final bool showSelectionSummary;
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

  Widget _spatialInspector(
    BuildContext context,
    SpatialModelInstance instance,
  ) {
    final model = project.models3d
        .where((model) => model.id == instance.modelId)
        .firstOrNull;
    final commands = SpatialModelEditingCommands(document, project);
    bool change(void Function() action) {
      try {
        action();
        onChanged();
        return true;
      } on Object catch (error) {
        document.error = error.toString();
        onChanged();
        return false;
      }
    }

    Widget field(
      String id,
      String label,
      double value,
      void Function(double) update,
    ) => StudioCommitField(
      key: ValueKey('decor-geometry-$id'),
      label: label,
      value: '$value',
      tryCommit: (text) {
        final number = double.tryParse(text.trim());
        if (number == null || !number.isFinite) {
          document.error = 'Saisissez un nombre valide.';
          onChanged();
          return false;
        }
        return change(() => update(number));
      },
    );
    return StudioSidebar(
      width: widget.width,
      child: ListView(
        children: [
          if (widget.showSelectionSummary)
            Text(
              'Élément sélectionné',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          if (model != null)
            StudioAssetPreview(
              height: 104,
              child: resourcePreview(
                ResourceItem(
                  id: model.id,
                  name: model.name,
                  kind: ResourceKind.decors,
                  model3d: model,
                ),
                project,
                visuals,
                size: 100,
              ),
            ),
          Text(
            model?.name ?? 'Ressource manquante',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text('Cette instance · décor placé sur la carte'),
          const SizedBox(height: 12),
          field(
            'x',
            'X',
            instance.position.x,
            (number) => commands.update(instance.id, x: number),
          ),
          field(
            'y',
            'Y',
            instance.position.z,
            (number) => commands.update(instance.id, z: number),
          ),
          field(
            'rotation',
            'Rotation',
            instance.rotationDegrees,
            (number) => commands.update(instance.id, rotation: number),
          ),
          StudioSelect(
            label: 'Hauteur au-dessus du sol',
            value:
                ((instance.position.y -
                            document.current.spatialScene!.worldHeightAt(
                              instance.position.x,
                              instance.position.z,
                            )) /
                        document.current.spatialScene!.levelHeight)
                    .toStringAsFixed(0),
            options: {
              for (var level = 0; level <= 32; level++)
                '$level': '$level ${level == 1 ? "bloc" : "blocs"}',
            },
            onChanged: (value) => change(
              () => commands.update(instance.id, heightLevel: int.parse(value)),
            ),
          ),
          field(
            'scale',
            'Échelle',
            instance.scale,
            (number) => commands.update(instance.id, scale: number),
          ),
          StudioToggleRow(
            label: 'Bloque le passage',
            value: instance.blocksMovement,
            onChanged: (value) => change(
              () => commands.update(instance.id, blocksMovement: value),
            ),
          ),
          StudioButton(
            label: 'Dupliquer',
            secondary: true,
            onPressed: () => change(() {
              commands.duplicate(instance.id);
              view.select(
                document,
                MapSelectionFamily.decor,
                document.selectedId!,
              );
            }),
          ),
          StudioTool(
            label: 'Supprimer le décor',
            icon: Icons.delete_outline,
            shortcut: '⌫',
            onPressed: () => change(() => commands.delete(instance.id)),
          ),
        ],
      ),
    );
  }

  void _index() {
    entries = {for (final entry in project.elements) entry.id: entry};
  }

  @override
  Widget build(BuildContext context) {
    final spatial = SpatialModelEditingCommands(document, project).selected();
    if (spatial != null) return _spatialInspector(context, spatial);
    final commands = MapEditingCommands(document, project);
    final position = document.stackPosition;
    final stack = document.stackPixelPosition != null
        ? commands.stackAtPixel(document.stackPixelPosition!)
        : position == null
        ? <MapPlacedElement>[]
        : commands.stack(position);
    final selected = document.selected;
    final entry = entries[selected?.elementId];
    final category = project.elementCategories
        .where((category) => category.id == entry?.categoryId)
        .firstOrNull;
    final rank = stack.indexWhere((e) => e.id == selected?.id);
    final forwardReason = selected == null
        ? null
        : commands.reorderProblemAt(
            instanceId: selected.id,
            at: position ?? selected.pos,
            forward: true,
          );
    final backwardReason = selected == null
        ? null
        : commands.reorderProblemAt(
            instanceId: selected.id,
            at: position ?? selected.pos,
            forward: false,
          );
    void change(void Function() action) {
      action();
      onChanged();
    }

    return StudioSidebar(
      width: widget.width,
      child: CustomScrollView(
        scrollCacheExtent: const rendering.ScrollCacheExtent.pixels(0),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showSelectionSummary) ...[
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
                ],
                if (selected == null) ...[
                  MapCatalogueProperties(
                    map: document.current,
                    onRename: widget.onRenameMap,
                  ),
                  Text(mapToolHelp(widget.tool)),
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
                    onForward: forwardReason == null
                        ? () => change(() => commands.reorder(forward: true))
                        : null,
                    onBackward: backwardReason == null
                        ? () => change(() => commands.reorder(forward: false))
                        : null,
                  ),
                  if (forwardReason != null && backwardReason != null)
                    Text(
                      forwardReason,
                      style: Theme.of(context).textTheme.bodySmall,
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
                  if (entry != null) ...[
                    const SizedBox(height: 12),
                    MapDecorGeometryPanel(
                      key: ValueKey('decor-geometry-${selected.id}'),
                      document: document,
                      project: project,
                      instance: selected,
                      element: entry,
                      view: view,
                      onChanged: onChanged,
                    ),
                  ],
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
                  view.select(document, MapSelectionFamily.decor, instance.id);
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

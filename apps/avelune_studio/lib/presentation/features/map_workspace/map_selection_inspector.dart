import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/characters/application/character_editing_commands.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../characters/character_inspector.dart';
import 'map_workspace_inspector.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';

class MapSelectionInspector extends StatelessWidget {
  const MapSelectionInspector({
    super.key,
    required this.document,
    required this.project,
    required this.visuals,
    required this.view,
    required this.onChanged,
    required this.onOpenElement,
    required this.onEditElement,
    this.onEditInteraction,
    this.deletionBlocked,
    this.width = 300,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final ValueChanged<ProjectElementEntry> onOpenElement, onEditElement;
  final ValueChanged<MapEntity>? onEditInteraction;
  final bool Function(String)? deletionBlocked;
  final double width;

  @override
  Widget build(BuildContext context) {
    final commands = CharacterEditingCommands(document, project);
    final selected = commands.selected(view.selectedEntityId);
    final pos = document.stackPosition;
    final entities = pos == null ? <MapEntity>[] : commands.at(pos);
    final decors = pos == null
        ? <MapPlacedElement>[]
        : MapEditingCommands(document, project).stack(pos);
    return SizedBox(
      width: width,
      child: Column(
        children: [
          if (entities.isNotEmpty)
            StudioSidebar(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Objets à cet endroit',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: (entities.length + decors.length == 1) ? 65 : 130,
                    child: ListView.builder(
                      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                      itemCount: entities.length + decors.length,
                      itemBuilder: (context, i) {
                        if (i < entities.length) {
                          final entity = entities[i];
                          return StudioChoice(
                            label: entity.inspectorHeadline,
                            subtitle: 'Personnage',
                            selected: entity.id == view.selectedEntityId,
                            onTap: () {
                              view.selectedEntityId = entity.id;
                              document.selectedId = null;
                              onChanged();
                            },
                          );
                        }
                        final decor = decors[i - entities.length];
                        final definition = project.elements
                            .where((e) => e.id == decor.elementId)
                            .firstOrNull;
                        return StudioChoice(
                          label: definition?.name ?? 'Ressource manquante',
                          subtitle: 'Décor',
                          selected: document.selectedId == decor.id,
                          onTap: () {
                            document.selectedId = decor.id;
                            view.selectedEntityId = null;
                            onChanged();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: selected?.npc != null
                ? StudioSidebar(
                    width: width,
                    child: SingleChildScrollView(
                      child: CharacterInspector(
                        document: document,
                        project: project,
                        entity: selected!,
                        visuals: visuals,
                        onChanged: onChanged,
                        onSelect: (id) {
                          view.selectedEntityId = id;
                          onChanged();
                        },
                        onEditInteraction: onEditInteraction ?? (_) {},
                        deletionBlocked:
                            deletionBlocked?.call(selected.id) ?? false,
                      ),
                    ),
                  )
                : MapWorkspaceInspector(
                    project: project,
                    document: document,
                    visuals: visuals,
                    onChanged: onChanged,
                    onOpenResource: onOpenElement,
                    onEditResource: onEditElement,
                    width: width,
                    tool: view.tool,
                  ),
          ),
        ],
      ),
    );
  }
}

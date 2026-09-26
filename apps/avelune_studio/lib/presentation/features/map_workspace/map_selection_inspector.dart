import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/characters/application/character_editing_commands.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../../features/map_workspace/application/gameplay_zone_editing_commands.dart';
import '../../../features/map_workspace/application/map_entity_editing_commands.dart';
import '../../../features/map_workspace/application/trigger_editing_commands.dart';
import '../../../features/map_workspace/application/warp_editing_commands.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../characters/character_inspector.dart';
import 'map_marker_inspector.dart';
import 'map_trigger_inspector.dart';
import 'map_zone_inspector.dart';
import 'map_warp_inspector.dart';
import 'map_decor_inspector_tabs.dart';
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
    this.onOpenMap,
    this.referenceGuard,
    this.width = 300,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final ValueChanged<ProjectElementEntry> onOpenElement, onEditElement;
  final ValueChanged<MapEntity>? onEditInteraction;
  final ValueChanged<String>? onOpenMap;
  final MapReferenceGuard? referenceGuard;
  final double width;

  @override
  Widget build(BuildContext context) {
    final commands = CharacterEditingCommands(document, project);
    final mapId = document.current.id;
    final selected = commands.selected(
      view.selectedFor(mapId, MapSelectionFamily.character),
    );
    final warp = WarpEditingCommands(
      document,
      project,
    ).selected(view.selectedFor(mapId, MapSelectionFamily.warp));
    final marker = MapEntityEditingCommands(
      document,
      project,
      draftGuard: referenceGuard,
    ).selected(view.selectedFor(mapId, MapSelectionFamily.marker));
    final zone = GameplayZoneEditingCommands(
      document,
      project,
    ).selected(view.selectedFor(mapId, MapSelectionFamily.zone));
    final trigger = TriggerEditingCommands(
      document,
      project,
    ).selected(view.selectedFor(mapId, MapSelectionFamily.trigger));
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
                            selected:
                                entity.id ==
                                view.selectedFor(
                                  mapId,
                                  MapSelectionFamily.character,
                                ),
                            onTap: () {
                              view.select(
                                document,
                                MapSelectionFamily.character,
                                entity.id,
                              );
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
                            view.select(
                              document,
                              MapSelectionFamily.decor,
                              decor.id,
                            );
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
            child: trigger != null
                ? StudioSidebar(
                    width: width,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: MapTriggerInspector(
                        document: document,
                        project: project,
                        trigger: trigger,
                        onChanged: onChanged,
                        onDeleted: () {
                          view.clearSelection(document);
                          onChanged();
                        },
                      ),
                    ),
                  )
                : zone != null
                ? StudioSidebar(
                    width: width,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: MapZoneInspector(
                        document: document,
                        project: project,
                        zone: zone,
                        onChanged: onChanged,
                        onDeleted: () {
                          view.clearSelection(document);
                          onChanged();
                        },
                      ),
                    ),
                  )
                : marker != null
                ? StudioSidebar(
                    width: width,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: MapMarkerInspector(
                        document: document,
                        project: project,
                        entity: marker,
                        referenceGuard: referenceGuard,
                        onChanged: onChanged,
                        onDeleted: () {
                          view.clearSelection(document);
                          onChanged();
                        },
                      ),
                    ),
                  )
                : warp != null
                ? StudioSidebar(
                    width: width,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: MapWarpInspector(
                        document: document,
                        project: project,
                        warp: warp,
                        onChanged: onChanged,
                        onDeleted: () {
                          view.clearSelection(document);
                          onChanged();
                        },
                        onOpenDestination: onOpenMap,
                      ),
                    ),
                  )
                : selected?.npc != null
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
                          if (id == null) {
                            view.clearSelection(document);
                          } else {
                            view.select(
                              document,
                              MapSelectionFamily.character,
                              id,
                            );
                          }
                          onChanged();
                        },
                        onEditInteraction: onEditInteraction ?? (_) {},
                        deletionBlocked:
                            referenceGuard?.call(
                              mapId: mapId,
                              entityId: selected.id,
                            ) !=
                            null,
                      ),
                    ),
                  )
                : MapDecorInspectorTabs(
                    project: project,
                    document: document,
                    visuals: visuals,
                    view: view,
                    onChanged: onChanged,
                    onOpenResource: onOpenElement,
                    onEditResource: onEditElement,
                    width: width,
                  ),
          ),
        ],
      ),
    );
  }
}

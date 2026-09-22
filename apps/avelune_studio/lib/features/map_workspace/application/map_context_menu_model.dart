import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';

enum MapContextFamily { decor, character, marker, warp, zone, trigger, cell }

enum MapContextCommand {
  properties,
  openResource,
  editResource,
  openInteraction,
  openDestination,
  openNarrativeDocument,
  move,
  bringForward,
  sendBackward,
  copyCoordinates,
  eraseTile,
  delete,
}

class MapContextTarget {
  const MapContextTarget({
    required this.mapId,
    required this.family,
    required this.id,
    required this.label,
    required this.kindLabel,
  });
  final String mapId;
  final MapContextFamily family;
  final String id;
  final String label;
  final String kindLabel;

  /// Map, family and identifier together: two families may legitimately carry
  /// the same local id, and two projects the same map id.
  String get key => '$mapId\u001f${family.name}\u001f$id';

  bool sameAs(MapContextTarget? other) => other != null && other.key == key;
}

class MapContextAction {
  const MapContextAction(this.command, this.label, {this.unavailable});
  final MapContextCommand command;
  final String label;
  final String? unavailable;
  bool get enabled => unavailable == null;
}

/// Every element the author could mean at this cell, most specific first, so a
/// zone never hides the decor or the character standing on it.
List<MapContextTarget> mapContextTargetsAt(
  EditableMapDocument document,
  ProjectManifest project,
  GridPos position,
) {
  final map = document.current;
  final mapId = map.id;
  return [
    for (final entity in CharacterEditingCommands(
      document,
      project,
    ).at(position))
      MapContextTarget(
        mapId: mapId,
        family: MapContextFamily.character,
        id: entity.id,
        label: entity.inspectorHeadline,
        kindLabel: 'Personnage',
      ),
    for (final entity in MapEntityEditingCommands(
      document,
      project,
    ).at(position))
      MapContextTarget(
        mapId: mapId,
        family: MapContextFamily.marker,
        id: entity.id,
        label: entity.name.isEmpty ? 'Repère' : entity.name,
        kindLabel: entity.spawn != null ? 'Point d’apparition' : 'Panneau',
      ),
    for (final warp in WarpEditingCommands(document, project).at(position))
      MapContextTarget(
        mapId: mapId,
        family: MapContextFamily.warp,
        id: warp.id,
        label: _warpLabel(project, warp),
        kindLabel: 'Passage',
      ),
    for (final decor in MapEditingCommands(document, project).stack(position))
      MapContextTarget(
        mapId: mapId,
        family: MapContextFamily.decor,
        id: decor.id,
        label: _decorLabel(project, decor),
        kindLabel: 'Décor',
      ),
    for (final zone in GameplayZoneEditingCommands(
      document,
      project,
    ).at(position))
      MapContextTarget(
        mapId: mapId,
        family: MapContextFamily.zone,
        id: zone.id,
        label: zone.name.isEmpty ? 'Zone de jeu' : zone.name,
        kindLabel: 'Zone de jeu',
      ),
    for (final trigger in TriggerEditingCommands(
      document,
      project,
    ).at(position))
      if (trigger.type == TriggerType.event)
        MapContextTarget(
          mapId: mapId,
          family: MapContextFamily.trigger,
          id: trigger.id,
          label: trigger.name.isEmpty ? 'Zone d’histoire' : trigger.name,
          kindLabel: 'Zone d’histoire',
        ),
  ];
}

String _warpLabel(ProjectManifest project, MapWarp warp) {
  final destination = project.maps
      .where((entry) => entry.id == warp.targetMapId)
      .firstOrNull;
  return destination == null
      ? 'Passage sans destination'
      : 'Passage vers ${destination.name}';
}

String _decorLabel(ProjectManifest project, MapPlacedElement decor) =>
    project.elements
        .where((entry) => entry.id == decor.elementId)
        .firstOrNull
        ?.name ??
    'Ressource manquante';

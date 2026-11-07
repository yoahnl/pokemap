import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/domain/pokemon_combat_port.dart';

List<String> combatTableReferences(
  PokemonCombatSnapshot snapshot,
  ProjectEncounterTable table,
) => [
  for (final map in snapshot.maps)
    if (mapUsesEncounterTable(map, table.id)) 'Carte ${map.name}',
  for (final scene in snapshot.project.scenes)
    if (scene.graph.nodes.any(
      (node) =>
          node.payload is SceneBattlePayload &&
          (node.payload as SceneBattlePayload).battleTemplateId == table.id,
    ))
      'Scène ${scene.name}',
];

List<String> combatTrainerReferences(
  PokemonCombatSnapshot snapshot,
  ProjectTrainerEntry trainer,
) => [
  for (final map in snapshot.maps)
    if (map.entities.any((entity) => entity.npc?.trainerId == trainer.id))
      'Carte ${map.name}',
  for (final scene in snapshot.project.scenes)
    if (scene.graph.nodes.any(
      (node) =>
          node.payload is SceneBattlePayload &&
          (node.payload as SceneBattlePayload).trainerId == trainer.id,
    ))
      'Scène ${scene.name}',
];

bool mapUsesEncounterTable(MapData map, String tableId) =>
    map.gameplayZones.any(
      (zone) => zone.encounter?.encounterTableId == tableId,
    ) ||
    map.entities.any(
      (entity) => entity.interactiveEncounter?.encounterTableId == tableId,
    );

final class CombatUsage {
  const CombatUsage(this.kind, this.id, this.detailId, this.label);
  final String kind, id;
  final String? detailId;
  final String label;
}

List<CombatUsage> combatUsages(
  PokemonCombatSnapshot snapshot, {
  String? tableId,
  String? trainerId,
}) => [
  for (final map in snapshot.maps) ...[
    if (tableId != null &&
        map.gameplayZones.any(
          (zone) => zone.encounter?.encounterTableId == tableId,
        ))
      CombatUsage('map', map.id, null, 'Carte ${map.name} · zone de rencontre'),
    for (final entity in map.entities)
      if ((trainerId != null && entity.npc?.trainerId == trainerId) ||
          (tableId != null &&
              entity.interactiveEncounter?.encounterTableId == tableId))
        CombatUsage(
          'map',
          map.id,
          entity.id,
          'Carte ${map.name} · ${entity.inspectorHeadline}',
        ),
  ],
  for (final scene in snapshot.project.scenes)
    for (final node in scene.graph.nodes)
      if (node.payload case final SceneBattlePayload payload
          when (tableId != null && payload.battleTemplateId == tableId) ||
              (trainerId != null && payload.trainerId == trainerId))
        CombatUsage(
          'scene',
          scene.id,
          node.id,
          'Scène ${scene.name} · ${node.title?.trim().isNotEmpty == true ? node.title!.trim() : 'bloc Combat'}',
        ),
];

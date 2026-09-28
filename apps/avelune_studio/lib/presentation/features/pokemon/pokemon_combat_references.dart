import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/domain/pokemon_combat_port.dart';

List<String> combatTableReferences(
  PokemonCombatSnapshot snapshot,
  ProjectEncounterTable table,
) => [
  for (final map in snapshot.maps)
    if (map.gameplayZones.any(
      (zone) => zone.encounter?.encounterTableId == table.id,
    ))
      'Carte ${map.name}',
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

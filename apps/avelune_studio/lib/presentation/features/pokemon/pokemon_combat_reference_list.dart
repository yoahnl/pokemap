import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/domain/pokemon_combat_port.dart';

class PokemonCombatReferenceList extends StatelessWidget {
  const PokemonCombatReferenceList({
    super.key,
    required this.snapshot,
    this.tableId,
    this.trainerId,
    this.onOpenReference,
  });

  final PokemonCombatSnapshot snapshot;
  final String? tableId;
  final String? trainerId;
  final Future<void> Function(String kind, String id)? onOpenReference;

  @override
  Widget build(BuildContext context) {
    final maps = [
      for (final map in snapshot.maps)
        if (map.gameplayZones.any(
              (zone) =>
                  tableId != null &&
                  zone.encounter?.encounterTableId == tableId,
            ) ||
            map.entities.any(
              (entity) =>
                  trainerId != null && entity.npc?.trainerId == trainerId,
            ))
          map,
    ];
    final scenes = [
      for (final scene in snapshot.project.scenes)
        if (scene.graph.nodes.any((node) {
          final payload = node.payload;
          return payload is SceneBattlePayload &&
              ((tableId != null && payload.battleTemplateId == tableId) ||
                  (trainerId != null && payload.trainerId == trainerId));
        }))
          scene,
    ];
    if (maps.isEmpty && scenes.isEmpty) {
      return const Text('Aucune carte ou scène ne référence cette fiche.');
    }
    return Column(
      children: [
        for (final map in maps)
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text('Carte ${map.name}'),
            trailing: const Icon(Icons.open_in_new),
            onTap: onOpenReference == null
                ? null
                : () => onOpenReference!('map', map.id),
          ),
        for (final scene in scenes)
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: Text('Scène ${scene.name}'),
            trailing: const Icon(Icons.open_in_new),
            onTap: onOpenReference == null
                ? null
                : () => onOpenReference!('scene', scene.id),
          ),
      ],
    );
  }
}

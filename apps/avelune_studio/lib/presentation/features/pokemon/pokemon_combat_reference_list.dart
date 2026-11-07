import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_combat_port.dart';
import 'pokemon_combat_references.dart';

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
  final Future<void> Function(String kind, String id, [String? detailId])?
  onOpenReference;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.referencesComplete) {
      return const Text(
        'Lancez l’analyse des usages du projet pour afficher ses cartes et scènes liées.',
      );
    }
    final usages = combatUsages(
      snapshot,
      tableId: tableId,
      trainerId: trainerId,
    );
    if (usages.isEmpty) {
      return const Text('Aucune carte ou scène ne référence cette fiche.');
    }
    return Column(
      children: [
        for (final usage in usages)
          ListTile(
            leading: Icon(
              usage.kind == 'map'
                  ? Icons.map_outlined
                  : Icons.account_tree_outlined,
            ),
            title: Text(usage.label),
            trailing: const Icon(Icons.open_in_new),
            onTap: onOpenReference == null
                ? null
                : () => onOpenReference!(usage.kind, usage.id, usage.detailId),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';

Future<String?> chooseCombatSpecies(
  BuildContext context,
  PokemonWorkspaceIndex index,
) async {
  final available = index.entries.where((value) => value.enabled).toList();
  var query = '';
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) {
        final filtered = available
            .where(
              (value) =>
                  value.name.toLowerCase().contains(query) ||
                  value.id.toLowerCase().contains(query),
            )
            .toList(growable: false);
        return AlertDialog(
          title: const Text('Choisir une espèce'),
          content: SizedBox(
            width: 420,
            height: 400,
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher une espèce',
                  ),
                  onChanged: (value) =>
                      update(() => query = value.trim().toLowerCase()),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, position) {
                      final value = filtered[position];
                      return ListTile(
                        title: Text(value.name),
                        subtitle: Text(value.id),
                        onTap: () => Navigator.pop(context, value.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> chooseTrainerSpecies(
  BuildContext context,
  PokemonCombatController combat,
  PokemonWorkspaceIndex index,
) async {
  final chosen = await chooseCombatSpecies(context, index);
  if (chosen == null) return;
  combat.editTrainer(
    (current) => current.copyWith(
      team: [
        ...current.team,
        ProjectTrainerPokemonEntry(speciesId: chosen, level: 5),
      ],
    ),
  );
}

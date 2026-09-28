import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';

class PokemonCombatList extends StatelessWidget {
  const PokemonCombatList({
    super.key,
    required this.combat,
    required this.search,
    required this.onCreate,
    required this.onSearch,
    required this.onSelected,
    required this.onBlocked,
  });

  final PokemonCombatController combat;
  final TextEditingController search;
  final VoidCallback onCreate;
  final ValueChanged<String> onSearch;
  final VoidCallback onSelected;
  final VoidCallback onBlocked;

  @override
  Widget build(BuildContext context) {
    final trainers = combat.view == PokemonCombatView.trainers;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              StudioSearchField(
                controller: search,
                hint: 'Rechercher…',
                onChanged: onSearch,
              ),
              const SizedBox(height: 8),
              StudioButton(
                label: trainers
                    ? 'Créer un dresseur'
                    : combat.view == PokemonCombatView.unique
                    ? 'Créer une rencontre unique'
                    : 'Créer une table',
                icon: Icons.add,
                onPressed: combat.saving || combat.dirty ? null : onCreate,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: trainers
                ? combat.visibleTrainers.length
                : combat.visibleTables.length,
            itemBuilder: (context, index) {
              final trainer = trainers ? combat.visibleTrainers[index] : null;
              final table = trainers ? null : combat.visibleTables[index];
              return ListTile(
                selected: trainers
                    ? combat.trainer?.current.id == trainer?.id
                    : combat.table?.current.id == table?.id,
                title: Text(trainer?.name ?? table!.name),
                subtitle: Text(
                  trainers
                      ? '${trainer!.team.length} Pokémon'
                      : '${table!.entries.length} espèces',
                ),
                onTap: () {
                  final selected = trainers
                      ? combat.selectTrainer(trainer!)
                      : combat.selectTable(table!);
                  if (selected) {
                    onSelected();
                  } else {
                    onBlocked();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

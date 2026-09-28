import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'pokemon_ui_parts.dart';
import 'pokemon_combat_detail_header.dart';
import 'pokemon_combat_species_picker.dart';

class PokemonCombatTrainerDetail extends StatelessWidget {
  const PokemonCombatTrainerDetail({
    super.key,
    required this.combat,
    required this.index,
    required this.references,
    required this.onDelete,
    this.onOpenReference,
    this.onBack,
  });

  final PokemonCombatController combat;
  final PokemonWorkspaceIndex index;
  final List<String> references;
  final VoidCallback onDelete;
  final Future<void> Function(String kind, String id)? onOpenReference;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final draft = combat.trainer;
    if (draft == null) {
      return const PokemonEmptyState(
        title: 'Sélectionnez un dresseur',
        description:
            'Créez sa fiche, puis placez un PNJ ou un événement dans Carte et Histoire.',
      );
    }
    final trainer = draft.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokemonCombatDetailHeader(
          title: 'Dresseur',
          id: trainer.id,
          dirty: draft.dirty,
          created: draft.created,
          saving: combat.saving,
          onSave: () => combat.save(index),
          onDiscard: combat.discard,
          onDelete: onDelete,
          onBack: onBack,
        ),
        if (combat.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              combat.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StudioDraftField(
                key: ValueKey('${trainer.id}:name'),
                label: 'Nom du dresseur',
                value: trainer.name,
                onChanged: (value) => combat.editTrainer(
                  (current) => current.copyWith(name: value),
                ),
              ),
              const SizedBox(height: 12),
              StudioDraftField(
                key: ValueKey('${trainer.id}:class'),
                label: 'Classe',
                value: trainer.trainerClass,
                onChanged: (value) => combat.editTrainer(
                  (current) => current.copyWith(trainerClass: value),
                ),
              ),
              const SizedBox(height: 20),
              Text('Équipe', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < trainer.team.length; i++) ...[
                _teamEntry(context, trainer, i),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: StudioButton(
                  label: 'Ajouter un Pokémon',
                  secondary: true,
                  icon: Icons.add,
                  onPressed:
                      index.entries.where((value) => value.enabled).isEmpty
                      ? null
                      : () => chooseTrainerSpecies(context, combat, index),
                ),
              ),
              if (onBack != null) ...[
                const SizedBox(height: 18),
                Text(
                  'Implantation et scène',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (references.isEmpty)
                  const Text(
                    'Aucun PNJ ou bloc Combat ne référence encore ce dresseur. Placez-le dans Carte ou choisissez-le dans une scène Histoire.',
                  ),
                for (final map in combat.snapshot?.maps ?? const <MapData>[])
                  if (map.entities.any(
                    (entity) => entity.npc?.trainerId == trainer.id,
                  ))
                    ListTile(
                      leading: const Icon(Icons.map_outlined),
                      title: Text('Carte ${map.name}'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: onOpenReference == null
                          ? null
                          : () => onOpenReference!('map', map.id),
                    ),
                for (final scene
                    in combat.snapshot?.project.scenes ?? const <SceneAsset>[])
                  if (scene.graph.nodes.any(
                    (node) =>
                        node.payload is SceneBattlePayload &&
                        (node.payload as SceneBattlePayload).trainerId ==
                            trainer.id,
                  ))
                    ListTile(
                      leading: const Icon(Icons.account_tree_outlined),
                      title: Text('Scène ${scene.name}'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: onOpenReference == null
                          ? null
                          : () => onOpenReference!('scene', scene.id),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _teamEntry(
    BuildContext context,
    ProjectTrainerEntry trainer,
    int indexInTeam,
  ) {
    final pokemon = trainer.team[indexInTeam];
    final species = index.entries
        .where((value) => value.id == pokemon.speciesId)
        .firstOrNull;
    void change(ProjectTrainerPokemonEntry value) => combat.editTrainer(
      (current) => current.copyWith(
        team: [
          for (var i = 0; i < current.team.length; i++)
            if (i == indexInTeam) value else current.team[i],
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(species?.name ?? 'Espèce introuvable : ${pokemon.speciesId}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 140,
                  child: StudioDraftField(
                    key: ValueKey('${trainer.id}:$indexInTeam:level'),
                    label: 'Niveau',
                    value: combat.numericValue(
                      'team$indexInTeam:level',
                      pokemon.level,
                    ),
                    onChanged: (raw) => combat.editNumber(
                      'team$indexInTeam:level',
                      raw,
                      (value) => change(pokemon.copyWith(level: value)),
                    ),
                  ),
                ),
                if (species?.formIds.isNotEmpty == true)
                  SizedBox(
                    width: 180,
                    child: StudioSelect(
                      label: 'Forme',
                      value: pokemon.formId,
                      options: {for (final id in species!.formIds) id: id},
                      onChanged: (id) => change(pokemon.copyWith(formId: id)),
                    ),
                  ),
                if (index.items.isNotEmpty)
                  SizedBox(
                    width: 190,
                    child: StudioSelect(
                      label: 'Objet tenu',
                      value: pokemon.heldItemId,
                      options: {'': 'Aucun', ...index.items},
                      onChanged: (id) => change(
                        pokemon.copyWith(heldItemId: id.isEmpty ? null : id),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Retirer de l’équipe',
                  onPressed: () => combat.editTrainer(
                    (current) => current.copyWith(
                      team: [
                        for (var i = 0; i < current.team.length; i++)
                          if (i != indexInTeam) current.team[i],
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Attaques (${pokemon.moves.length}/4)'),
            for (final move in pokemon.moves)
              ListTile(
                dense: true,
                title: Text(
                  index.moves.entries
                          .where((value) => value.id == move)
                          .firstOrNull
                          ?.name ??
                      'Attaque introuvable : $move',
                ),
                trailing: IconButton(
                  tooltip: 'Retirer cette attaque',
                  onPressed: () => change(
                    pokemon.copyWith(
                      moves: pokemon.moves
                          .where((value) => value != move)
                          .toList(),
                    ),
                  ),
                  icon: const Icon(Icons.close),
                ),
              ),
            if (pokemon.moves.length < 4)
              StudioSelect(
                label: 'Ajouter une attaque',
                value: null,
                options: {
                  for (final move in index.moves.entries)
                    if (!pokemon.moves.contains(move.id)) move.id: move.name,
                },
                onChanged: (id) =>
                    change(pokemon.copyWith(moves: [...pokemon.moves, id])),
              ),
          ],
        ),
      ),
    );
  }
}

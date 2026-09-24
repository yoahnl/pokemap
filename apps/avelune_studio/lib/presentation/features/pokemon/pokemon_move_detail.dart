import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_move_emblem.dart';
import 'pokemon_ui_parts.dart';

class PokemonMoveDetail extends StatelessWidget {
  const PokemonMoveDetail({super.key, required this.move});

  final PokemonMoveSummary move;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PokemonSurface(
        emphasized: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PokemonMoveEmblem(move: move, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        move.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                if (move.type != null)
                  PokemonPill(label: pokemonTypeLabel(move.type!)),
                if (move.category != null)
                  PokemonPill(label: pokemonMoveCategoryLabel(move.category)),
                if (move.userCreated)
                  const PokemonPill(
                    label: 'Créée dans le projet',
                    icon: Icons.star_rounded,
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, bounds) {
          final first = StudioPanel(
            title: 'Caractéristiques',
            children: [
              PokemonDataRow(label: 'Cible', value: _targetLabel(move.target)),
              PokemonDataRow(
                label: 'Priorité',
                value: move.priority?.toString() ?? 'Non renseignée',
              ),
            ],
          );
          final second = StudioPanel(
            title: 'Valeurs du catalogue',
            children: [
              PokemonDataRow(
                label: 'Puissance',
                value: move.power?.toString() ?? 'Non renseignée',
              ),
              PokemonDataRow(
                label: 'Précision',
                value: move.accuracy ?? 'Non renseignée',
              ),
              PokemonDataRow(
                label: 'PP',
                value: move.pp?.toString() ?? 'Non renseignés',
              ),
            ],
          );
          if (bounds.maxWidth < 670 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(
              children: [first, const SizedBox(height: 12), second],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          );
        },
      ),
      if (move.description?.isNotEmpty == true) ...[
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Description source',
          children: [Text(move.description!)],
        ),
      ],
      const SizedBox(height: 12),
      StudioPanel(
        title: 'Détails techniques',
        children: [
          PokemonDataRow(label: 'Identifiant', value: move.id),
          PokemonDataRow(
            label: 'Origine',
            value: move.userCreated ? 'Créée dans le projet' : 'Catalogue',
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        'Les attaques sont consultables ici. Les apprentissages se modifient '
        'depuis la fiche de l’espèce.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

String _targetLabel(String? value) => switch (value?.split('.').last) {
  null => 'Non renseignée',
  'adjacentAlly' => 'Allié adjacent',
  'adjacentAllyOrSelf' => 'Allié adjacent ou utilisateur',
  'adjacentFoe' => 'Adversaire adjacent',
  'all' => 'Tous',
  'allAdjacent' => 'Tous les voisins',
  'allAdjacentFoes' => 'Tous les adversaires voisins',
  'allies' => 'Alliés',
  'allySide' => 'Côté allié',
  'allyTeam' => 'Équipe alliée',
  'any' => 'Une cible au choix',
  'foeSide' => 'Côté adverse',
  'normal' => 'Une cible',
  'randomNormal' => 'Une cible aléatoire',
  'scripted' => 'Définie par le scénario',
  'self' => 'Utilisateur',
  final String other => other,
};

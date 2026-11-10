import '../domain/pokemon_workspace_models.dart';
import '../../resources/domain/studio_search_text.dart';
import 'pokemon_reference_labels.dart';

typedef CombatChoice = ({String id, String label, String details});

String combatSpeciesDetails(PokemonSpeciesSummary species) => [
  'n° ${species.nationalDex.toString().padLeft(3, '0')}',
  if (species.types.isNotEmpty) species.types.map(pokemonTypeLabel).join(' / '),
  'Génération ${species.generation}',
].join(' · ');

String combatMoveDetails(PokemonMoveSummary move) => [
  move.type == null ? 'Type inconnu' : pokemonTypeLabel(move.type!),
  pokemonMoveCategoryLabel(move.category),
  move.power == null ? 'Sans puissance' : 'Puissance ${move.power}',
  if (move.accuracy != null) 'Précision ${move.accuracy}',
].join(' · ');

List<CombatChoice> combatSpeciesChoices(PokemonWorkspaceIndex index) => [
  for (final species in index.entries)
    if (species.enabled)
      (
        id: species.id,
        label: species.name,
        details: combatSpeciesDetails(species),
      ),
];

List<CombatChoice> combatMoveChoices(
  PokemonWorkspaceIndex index, {
  Iterable<String> exclude = const [],
}) {
  final taken = exclude.toSet();
  return [
    for (final move in index.moves.entries)
      if (!taken.contains(move.id))
        (id: move.id, label: move.name, details: combatMoveDetails(move)),
  ];
}

List<CombatChoice> combatChoiceSearch(
  Iterable<CombatChoice> choices,
  String query,
) => [
  for (final choice in choices)
    if (studioSearchMatches(
      '${choice.label} ${choice.details} ${choice.id}',
      query,
    ))
      choice,
];

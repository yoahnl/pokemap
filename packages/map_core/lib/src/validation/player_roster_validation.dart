import '../models/save_data.dart';

enum PlayerRosterValidationIssueCode {
  partyCapacityExceeded,
  boxCapacityExceeded,
  missingSpeciesId,
  unknownSpecies,
  unknownMove,
}

final class PlayerRosterValidationIssue {
  const PlayerRosterValidationIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final PlayerRosterValidationIssueCode code;
  final String path;
  final String message;
}

List<PlayerRosterValidationIssue> validatePlayerRoster({
  required PlayerParty party,
  required PokemonStorage storage,
  Set<String>? knownSpeciesIds,
  Set<String>? knownMoveIds,
}) {
  final issues = <PlayerRosterValidationIssue>[];
  if (party.members.length > maxPlayerPartySize) {
    issues.add(
      const PlayerRosterValidationIssue(
        code: PlayerRosterValidationIssueCode.partyCapacityExceeded,
        path: r'$.party.members',
        message: 'La party ne peut pas contenir plus de 6 Pokémon.',
      ),
    );
  }
  for (var index = 0; index < party.members.length; index += 1) {
    _validatePokemon(
      pokemon: party.members[index],
      path: r'$.party.members[' '$index]',
      knownSpeciesIds: knownSpeciesIds,
      knownMoveIds: knownMoveIds,
      issues: issues,
    );
  }
  for (var boxIndex = 0; boxIndex < storage.boxes.length; boxIndex += 1) {
    final box = storage.boxes[boxIndex];
    final boxPath = r'$.pokemonStorage.boxes[' '$boxIndex]';
    if (box.pokemon.length > box.capacity) {
      issues.add(
        PlayerRosterValidationIssue(
          code: PlayerRosterValidationIssueCode.boxCapacityExceeded,
          path: '$boxPath.pokemon',
          message: 'La box "${box.label}" dépasse sa capacité de '
              '${box.capacity} Pokémon.',
        ),
      );
    }
    for (var pokemonIndex = 0;
        pokemonIndex < box.pokemon.length;
        pokemonIndex += 1) {
      _validatePokemon(
        pokemon: box.pokemon[pokemonIndex],
        path: '$boxPath.pokemon[$pokemonIndex]',
        knownSpeciesIds: knownSpeciesIds,
        knownMoveIds: knownMoveIds,
        issues: issues,
      );
    }
  }
  return List<PlayerRosterValidationIssue>.unmodifiable(issues);
}

void _validatePokemon({
  required PlayerPokemon pokemon,
  required String path,
  required Set<String>? knownSpeciesIds,
  required Set<String>? knownMoveIds,
  required List<PlayerRosterValidationIssue> issues,
}) {
  final speciesId = pokemon.speciesId.trim();
  if (speciesId.isEmpty) {
    issues.add(
      PlayerRosterValidationIssue(
        code: PlayerRosterValidationIssueCode.missingSpeciesId,
        path: '$path.speciesId',
        message: 'Le Pokémon ne référence aucune espèce.',
      ),
    );
  } else if (knownSpeciesIds != null && !knownSpeciesIds.contains(speciesId)) {
    issues.add(
      PlayerRosterValidationIssue(
        code: PlayerRosterValidationIssueCode.unknownSpecies,
        path: '$path.speciesId',
        message: 'L’espèce "$speciesId" est inconnue du catalogue.',
      ),
    );
  }
  if (knownMoveIds == null) return;
  for (var moveIndex = 0;
      moveIndex < pokemon.knownMoveIds.length;
      moveIndex += 1) {
    final moveId = pokemon.knownMoveIds[moveIndex].trim();
    if (!knownMoveIds.contains(moveId)) {
      issues.add(
        PlayerRosterValidationIssue(
          code: PlayerRosterValidationIssueCode.unknownMove,
          path: '$path.knownMoveIds[$moveIndex]',
          message: 'La capacité "$moveId" est inconnue du catalogue.',
        ),
      );
    }
  }
}

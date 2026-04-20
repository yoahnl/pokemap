import 'package:map_core/map_core.dart';

import '../../application/battle_start_request.dart';
import '../../application/runtime_battle_setup_mapper.dart';
import '../../application/runtime_map_bundle.dart';
import '../../application/runtime_pokemon_species_loader.dart';
import 'battle_combatant_gender_resolver.dart';

Future<BattleCombatantGenderResolver> buildRuntimeBattleGenderResolver({
  required RuntimeMapBundle bundle,
  required GameState gameState,
  required BattleStartRequest request,
  required RuntimePlayerBattleLineupSelection playerLineup,
  RuntimePokemonSpeciesLoader speciesLoader = const RuntimePokemonSpeciesLoader(),
}) async {
  final playerGenderIdsByIndex = <int, String>{};
  for (final entry in playerLineup.lineupPartyIndices.asMap().entries) {
    final lineupIndex = entry.key;
    final partyIndex = entry.value;
    if (partyIndex < 0 || partyIndex >= gameState.party.members.length) {
      continue;
    }
    final resolvedGenderId = await _resolvePlayerPartyGenderId(
      bundle: bundle,
      speciesLoader: speciesLoader,
      playerPokemon: gameState.party.members[partyIndex],
    );
    if (resolvedGenderId != null) {
      playerGenderIdsByIndex[lineupIndex] = resolvedGenderId;
    }
  }

  final enemyGenderIdsByIndex = switch (request) {
    WildBattleStartRequest() => await _buildWildEnemyGenderIdsByIndex(
        bundle: bundle,
        speciesLoader: speciesLoader,
        request: request,
      ),
    TrainerBattleStartRequest() => await _buildTrainerEnemyGenderIdsByIndex(
        bundle: bundle,
        speciesLoader: speciesLoader,
        request: request,
      ),
  };

  return BattleCombatantGenderResolver(
    playerLineupGenderIdsByIndex:
        Map<int, String>.unmodifiable(playerGenderIdsByIndex),
    enemyLineupGenderIdsByIndex:
        Map<int, String>.unmodifiable(enemyGenderIdsByIndex),
  );
}

Future<Map<int, String>> _buildWildEnemyGenderIdsByIndex({
  required RuntimeMapBundle bundle,
  required RuntimePokemonSpeciesLoader speciesLoader,
  required WildBattleStartRequest request,
}) async {
  final resolvedGenderId = await _resolveSpeciesGenderId(
    bundle: bundle,
    speciesLoader: speciesLoader,
    speciesId: request.speciesId,
    stableSeed:
        '${request.requestId}|${request.mapId}|${request.zoneId}|${request.speciesId}|${request.level}',
  );
  if (resolvedGenderId == null) {
    return const <int, String>{};
  }
  return <int, String>{0: resolvedGenderId};
}

Future<Map<int, String>> _buildTrainerEnemyGenderIdsByIndex({
  required RuntimeMapBundle bundle,
  required RuntimePokemonSpeciesLoader speciesLoader,
  required TrainerBattleStartRequest request,
}) async {
  final trainer = bundle.manifest.trainers.firstWhere(
    (entry) => entry.id == request.trainerId,
    orElse: () => const ProjectTrainerEntry(
      id: '',
      name: '',
      trainerClass: '',
    ),
  );
  if (trainer.id.isEmpty) {
    return const <int, String>{};
  }

  final genderIdsByIndex = <int, String>{};
  for (final entry in trainer.team.asMap().entries) {
    final lineupIndex = entry.key;
    final teamMember = entry.value;
    final explicitGenderId = normalizeBattleGenderId(teamMember.gender);
    final resolvedGenderId = explicitGenderId ??
        await _resolveSpeciesGenderId(
          bundle: bundle,
          speciesLoader: speciesLoader,
          speciesId: teamMember.speciesId,
        );
    if (resolvedGenderId != null) {
      genderIdsByIndex[lineupIndex] = resolvedGenderId;
    }
  }
  return genderIdsByIndex;
}

Future<String?> _resolvePlayerPartyGenderId({
  required RuntimeMapBundle bundle,
  required RuntimePokemonSpeciesLoader speciesLoader,
  required PlayerPokemon playerPokemon,
}) async {
  final explicitGenderId = normalizeBattleGenderId(playerPokemon.gender);
  if (explicitGenderId != null) {
    return explicitGenderId;
  }
  return _resolveSpeciesGenderId(
    bundle: bundle,
    speciesLoader: speciesLoader,
    speciesId: playerPokemon.speciesId,
  );
}

Future<String?> _resolveSpeciesGenderId({
  required RuntimeMapBundle bundle,
  required RuntimePokemonSpeciesLoader speciesLoader,
  required String speciesId,
  String? stableSeed,
}) async {
  try {
    final species = await speciesLoader.loadById(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      speciesId: speciesId,
    );
    return resolveBattleGenderIdFromRatios(
      maleRatio: species.maleGenderRatio,
      femaleRatio: species.femaleGenderRatio,
      stableSeed: stableSeed,
    );
  } catch (_) {
    return null;
  }
}

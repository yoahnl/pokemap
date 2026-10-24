import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'battle_start_request.dart';
import 'runtime_battle_setup_mapper.dart';
import 'runtime_map_bundle.dart';

Future<GameState> prepareRuntimeBattleDemonstration({
  required RuntimeMapBundle bundle,
  required GameState state,
  required WildBattleStartRequest request,
}) async {
  final configuration = request.demonstration;
  if (configuration == null) return state;
  if (bundle.manifest.settings.dimension != ProjectDimension.threeD) {
    throw StateError('Battle demonstrations require a 3D runtime.');
  }
  final trainer = bundle.manifest.trainers
      .where((entry) => entry.id == configuration.playerTrainerId)
      .firstOrNull;
  if (trainer == null ||
      trainer.team.isEmpty ||
      trainer.team.length > 6 ||
      trainer.battleFormat != BattleFormat.singles) {
    throw StateError(
      'A demonstration requires an existing singles team with one to six Pokemon.',
    );
  }
  final mapper = RuntimeBattleSetupMapper();
  final members = <PlayerPokemon>[];
  for (var index = 0; index < trainer.team.length; index++) {
    final member = trainer.team[index];
    final generated = await mapper.hydrateWildRequest(
      bundle: bundle,
      request: WildBattleStartRequest(
        requestId: '${request.requestId}:demonstration:$index',
        createdAtEpochMs: request.createdAtEpochMs,
        returnContext: request.returnContext,
        mapId: request.mapId,
        encounterSourceId: request.encounterSourceId,
        encounterSourceKind: request.encounterSourceKind,
        tableId: request.tableId,
        encounterKind: request.encounterKind,
        speciesId: member.speciesId,
        level: member.level,
        minLevel: member.level,
        maxLevel: member.level,
        weight: 1,
        playerPos: request.playerPos,
        generationSeed: index + 1,
        pokemonOverrides: ProjectEncounterPokemonOverrides(
          natureId: member.natureId,
          abilityId: member.abilityId,
          gender: member.gender == 'any' ? null : member.gender,
          ivs: member.ivs,
          knownMoveIds: member.moves,
          shinyPolicy: member.shiny
              ? ProjectEncounterShinyPolicy.always
              : ProjectEncounterShinyPolicy.never,
        ),
      ),
    );
    final pokemon = generated.generatedPokemon!;
    if (member.formId != null && member.formId != pokemon.formId) {
      throw StateError('The demonstration team form is unavailable.');
    }
    members.add(
      pokemon.copyWith(
        individualId: '${request.requestId}:demonstration:$index',
        heldItemId: member.heldItemId ?? '',
        evs: member.evs ?? pokemon.evs,
      ),
    );
  }
  return state.copyWith(
    trainerProfile: state.trainerProfile.copyWith(name: trainer.name),
    party: PlayerParty(members: members),
    bag: Bag(entries: configuration.bagItems),
  );
}

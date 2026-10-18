import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../runtime_battle_setup_exception.dart';
import '../runtime_move_catalog_loader.dart';
import '../runtime_pokemon_learnset_loader.dart';
import '../runtime_pokemon_species_loader.dart';

final class RuntimeScenePokemonCatalogEntry {
  RuntimeScenePokemonCatalogEntry({
    required this.species,
    required this.learnset,
    required Map<String, int> maxPpByMoveId,
  }) : maxPpByMoveId = Map.unmodifiable(maxPpByMoveId);

  final WildPokemonGenerationSpecies species;
  final WildPokemonGenerationLearnset learnset;
  final Map<String, int> maxPpByMoveId;
}

final class RuntimeScenePokemonCatalog {
  RuntimeScenePokemonCatalog({
    required Map<String, RuntimeScenePokemonCatalogEntry> entries,
    Map<String, String> failures = const {},
  }) : entries = Map.unmodifiable(entries),
       failures = Map.unmodifiable(failures);

  final Map<String, RuntimeScenePokemonCatalogEntry> entries;
  final Map<String, String> failures;

  PlayerPokemon generate({
    required SceneGivePokemonFromCatalogConsequence consequence,
    required GameState state,
    required String operationId,
    required PokemonRulesetProfile ruleset,
  }) {
    final entry = entries[consequence.speciesId];
    if (entry == null || entry.species.formId != consequence.formId) {
      throw FormatException(
        failures[consequence.speciesId] ??
            'Catalog gift species/form pair is unavailable: ${consequence.speciesId}/${consequence.formId}.',
      );
    }
    var seed = 17;
    for (final unit
        in '${state.saveId.length}:${state.saveId}${operationId.length}:$operationId'
            .codeUnits) {
      seed = (seed * 31 + unit) & 0x7fffffff;
    }
    final generated = const WildPlayerPokemonGenerator()
        .generate(
          seed: seed,
          species: entry.species,
          learnset: entry.learnset,
          maxPpByMoveId: entry.maxPpByMoveId,
          level: consequence.level,
          ruleset: ruleset,
          context: WildPokemonGenerationContext(
            mapId: state.currentMapId,
            sourceId: operationId,
          ),
        )
        .pokemon;
    return generated.copyWith(
      individualId: '',
      provenance: PlayerPokemonProvenance(
        kind: PlayerPokemonOriginKind.gift,
        mapId: state.currentMapId,
        sourceId: operationId,
        metLevel: consequence.level,
      ),
    );
  }
}

Future<RuntimeScenePokemonCatalog?> loadRuntimeScenePokemonCatalog({
  required SceneAsset? scene,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  RuntimePokemonSpeciesLoader? speciesLoader,
  RuntimePokemonLearnsetLoader? learnsetLoader,
  RuntimeMoveCatalogLoader? moveCatalogLoader,
}) async {
  final gifts = <SceneGivePokemonFromCatalogConsequence>[
    for (final node in scene?.graph.nodes ?? const <SceneNode>[])
      if (node.payload case SceneActionPayload(
        consequence: final SceneGivePokemonFromCatalogConsequence gift,
      ))
        gift,
    for (final node in scene?.graph.nodes ?? const <SceneNode>[])
      if (node.payload case SceneActionPayload(interactiveCommand: final SceneReceivePokemonFromCatalogInteractiveCommand gift))
        SceneGivePokemonFromCatalogConsequence(speciesId: gift.speciesId, formId: gift.formId, level: gift.level),
  ];
  if (gifts.isEmpty) return null;
  final resolvedSpeciesLoader = speciesLoader ?? RuntimePokemonSpeciesLoader();
  final resolvedMoveLoader = moveCatalogLoader ?? RuntimeMoveCatalogLoader();
  final resolvedLearnsetLoader =
      learnsetLoader ??
      RuntimePokemonLearnsetLoader(moveCatalogLoader: resolvedMoveLoader);
  final entries = <String, RuntimeScenePokemonCatalogEntry>{};
  final failures = <String, String>{};
  for (final speciesId in gifts.map((gift) => gift.speciesId).toSet()) {
    final RuntimePokemonSpecies species;
    final RuntimePokemonLearnset learnset;
    final RuntimeMoveCatalog moves;
    try {
      species = await resolvedSpeciesLoader.loadById(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
        speciesId: speciesId,
      );
      learnset = await resolvedLearnsetLoader.loadByRef(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
        speciesRef: species.learnsetRef,
        fallbackSpeciesId: species.id,
      );
      moves = await resolvedMoveLoader.load(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
      );
    } on RuntimeBattleSetupException catch (error) {
      failures[speciesId] = error.toString();
      continue;
    } on FormatException catch (error) {
      failures[speciesId] = error.message;
      continue;
    } on TypeError catch (error) {
      failures[speciesId] = 'Malformed catalog gift data: $error';
      continue;
    } on FileSystemException catch (error) {
      failures[speciesId] = 'Unreadable catalog gift data: ${error.message}';
      continue;
    }
    final level = gifts
        .where((gift) => gift.speciesId == speciesId)
        .map((gift) => gift.level)
        .reduce((a, b) => a > b ? a : b);
    final moveIds = {
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      for (final move in learnset.levelUp)
        if (move.level <= level) move.moveId,
    };
    entries[speciesId] = RuntimeScenePokemonCatalogEntry(
      species: WildPokemonGenerationSpecies(
        id: species.id,
        formId: species.formId,
        baseStats: PokemonBaseStats(
          hp: species.baseHp,
          attack: species.baseAttack,
          defense: species.baseDefense,
          specialAttack: species.baseSpecialAttack,
          specialDefense: species.baseSpecialDefense,
          speed: species.baseSpeed,
        ),
        primaryAbilityId: species.primaryAbilityId,
        standardAbilityIds: species.standardAbilityIds,
        allowedAbilityIds: species.abilityIds,
        genderRatio: species.genderRatio,
        growthRateId: species.growthRateId,
        baseFriendship: species.baseFriendship,
      ),
      learnset: WildPokemonGenerationLearnset(
        startingMoves: learnset.startingMoves,
        relearnMoves: learnset.relearnMoves,
        levelUp: [
          for (final move in learnset.levelUp)
            WildPokemonLevelUpMove(moveId: move.moveId, level: move.level),
        ],
      ),
      maxPpByMoveId: {
        for (final id in moveIds)
          if (moves.lookup(id) case final move?) id: move.pp,
      },
    );
  }
  return RuntimeScenePokemonCatalog(entries: entries, failures: failures);
}

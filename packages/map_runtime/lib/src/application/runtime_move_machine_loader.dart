import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_battle_setup_exception.dart';
import 'runtime_item_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';

enum RuntimeMoveMachineKind { tm, hm }

final class RuntimeMoveMachineDefinition {
  const RuntimeMoveMachineDefinition({
    required this.itemId,
    required this.moveId,
    required this.kind,
    required this.consumable,
  });

  final String itemId;
  final String moveId;
  final RuntimeMoveMachineKind kind;
  final bool consumable;
}

/// Resolves authored machine-item metadata and species compatibility.
final class RuntimeMoveMachineLoader {
  RuntimeMoveMachineLoader({
    RuntimePokemonLearnsetLoader? learnsetLoader,
    RuntimeItemCatalogLoader? itemCatalogLoader,
  })  : learnsetLoader = learnsetLoader ?? RuntimePokemonLearnsetLoader(),
        itemCatalogLoader =
            itemCatalogLoader ?? const RuntimeItemCatalogLoader();

  final RuntimePokemonLearnsetLoader learnsetLoader;
  final RuntimeItemCatalogLoader itemCatalogLoader;

  Future<RuntimeMoveMachineDefinition?> loadDefinition({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String itemId,
  }) async {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) return null;
    try {
      final item = await itemCatalogLoader.loadDefinition(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
        itemId: normalizedItemId,
      );
      final machine = item?.machine;
      if (machine == null) return null;
      return RuntimeMoveMachineDefinition(
        itemId: normalizedItemId,
        moveId: machine.moveId,
        kind: switch (machine.kind) {
          ProjectMoveMachineKind.tm => RuntimeMoveMachineKind.tm,
          ProjectMoveMachineKind.hm => RuntimeMoveMachineKind.hm,
        },
        consumable: machine.consumable,
      );
    } on RuntimeBattleSetupException {
      rethrow;
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Les données de la machine Pokémon sont invalides.',
        debugDetails: 'itemId=$normalizedItemId, error=$error',
      );
    }
  }

  Future<PokemonMoveMachineCandidate?> loadCandidate({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String itemId,
    required String speciesRef,
    required String fallbackSpeciesId,
  }) async {
    final definition = await loadDefinition(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      itemId: itemId,
    );
    if (definition == null) return null;
    return learnsetLoader.loadMoveMachineCandidate(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: speciesRef,
      fallbackSpeciesId: fallbackSpeciesId,
      itemId: definition.itemId,
      moveId: definition.moveId,
      machineKind: definition.kind.name,
      consumable: definition.consumable,
    );
  }
}

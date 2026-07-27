import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';
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
  }) : learnsetLoader = learnsetLoader ?? RuntimePokemonLearnsetLoader();

  final RuntimePokemonLearnsetLoader learnsetLoader;

  Future<RuntimeMoveMachineDefinition?> loadDefinition({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String itemId,
  }) async {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) return null;
    final relativePath = pokemonConfig.catalogFiles['items']?.trim();
    if (relativePath == null || relativePath.isEmpty) return null;
    final file = _boundedFile(projectRootDirectory, relativePath);
    if (!await file.exists()) return null;

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic> ||
          decoded['catalog'] != 'items' ||
          decoded['entries'] is! List) {
        throw const FormatException('Canonical items catalog expected');
      }
      RuntimeMoveMachineDefinition? found;
      for (final rawEntry in decoded['entries'] as List) {
        if (rawEntry is! Map) continue;
        final entry = rawEntry.cast<String, dynamic>();
        if ((entry['id'] as String?)?.trim() != normalizedItemId) continue;
        if (found != null) {
          throw const FormatException('Duplicate item id');
        }
        final machine = entry['machine'];
        if (machine == null) return null;
        if (machine is! Map) {
          throw const FormatException('machine must be an object');
        }
        final typed = machine.cast<String, dynamic>();
        final rawKind = (typed['kind'] as String?)?.trim();
        final kind = switch (rawKind) {
          'tm' => RuntimeMoveMachineKind.tm,
          'hm' => RuntimeMoveMachineKind.hm,
          _ => null,
        };
        final moveId = (typed['moveId'] as String?)?.trim() ?? '';
        final rawConsumable = typed['consumable'];
        if (kind == null || moveId.isEmpty || rawConsumable is! bool) {
          throw const FormatException(
            'machine requires kind, moveId, and consumable',
          );
        }
        if (kind == RuntimeMoveMachineKind.hm && rawConsumable) {
          throw const FormatException('HM must be reusable');
        }
        found = RuntimeMoveMachineDefinition(
          itemId: normalizedItemId,
          moveId: moveId,
          kind: kind,
          consumable: rawConsumable,
        );
      }
      return found;
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Les données de la machine Pokémon sont invalides.',
        debugDetails:
            'itemId=$normalizedItemId, file=${file.path}, error=$error',
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

  File _boundedFile(String projectRootDirectory, String relativePath) {
    if (p.isAbsolute(relativePath)) {
      throw const RuntimeBattleSetupException(
        'Le catalogue des objets doit appartenir au projet.',
      );
    }
    final root = p.normalize(p.absolute(projectRootDirectory));
    final filePath = p.normalize(p.join(root, relativePath));
    if (!p.isWithin(root, filePath)) {
      throw const RuntimeBattleSetupException(
        'Le catalogue des objets doit appartenir au projet.',
      );
    }
    return File(filePath);
  }
}

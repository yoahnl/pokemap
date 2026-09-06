import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';
import 'runtime_pokemon_species_loader.dart';

/// Strict project-data adapter for the FG-055 typed evolution conditions.
///
/// Unsupported methods are intentionally ignored. A supported rule is either
/// complete and usable or fails closed.
final class RuntimePokemonEvolutionLoader {
  RuntimePokemonEvolutionLoader({
    RuntimePokemonSpeciesLoader? speciesLoader,
  }) : speciesLoader = speciesLoader ?? RuntimePokemonSpeciesLoader();

  final RuntimePokemonSpeciesLoader speciesLoader;

  Future<List<PokemonEvolutionCandidate>> loadLevelUpCandidates({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String sourceSpeciesId,
  }) {
    return _loadCandidates(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      sourceSpeciesId: sourceSpeciesId,
      acceptedTriggers: const <PokemonEvolutionTriggerKind>{
        PokemonEvolutionTriggerKind.levelUp,
      },
    );
  }

  Future<List<PokemonEvolutionCandidate>> loadItemUseCandidates({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String sourceSpeciesId,
    String? itemId,
  }) {
    return _loadCandidates(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      sourceSpeciesId: sourceSpeciesId,
      acceptedTriggers: const <PokemonEvolutionTriggerKind>{
        PokemonEvolutionTriggerKind.itemUse,
      },
      itemId: itemId,
    );
  }

  Future<List<PokemonEvolutionCandidate>> _loadCandidates({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String sourceSpeciesId,
    required Set<PokemonEvolutionTriggerKind> acceptedTriggers,
    String? itemId,
  }) async {
    final sourceId = _validatedSourceId(sourceSpeciesId);
    final file = _boundedEvolutionFile(
      projectRootDirectory: projectRootDirectory,
      configuredDirectory: pokemonConfig.evolutionsDir,
      sourceSpeciesId: sourceId,
    );
    final json = await _readJson(file, sourceSpeciesId: sourceId);
    final rawDeclaredId = json['speciesId'];
    final declaredId =
        rawDeclaredId is String && _isSafeSpeciesId(rawDeclaredId)
            ? rawDeclaredId
            : '';
    if (declaredId != sourceId) {
      throw RuntimeBattleSetupException(
        'Les données d’évolution Pokémon locales sont invalides.',
        debugDetails:
            'speciesId=$sourceId, file=${file.path}, declaredId=$declaredId',
      );
    }
    final rawEvolutions = json['evolutions'];
    if (rawEvolutions is! List) {
      throw RuntimeBattleSetupException(
        'Les données d’évolution Pokémon locales sont invalides.',
        debugDetails:
            'speciesId=$sourceId, file=${file.path}, evolutions must be a JSON list',
      );
    }

    final candidates = <PokemonEvolutionCandidate>[];
    for (var index = 0; index < rawEvolutions.length; index++) {
      final rawEntry = rawEvolutions[index];
      if (rawEntry is! Map) {
        throw _invalidRule(sourceId, file.path, index);
      }
      final entry = rawEntry.cast<String, dynamic>();
      final rawMethod = entry['method'];
      final method = rawMethod is String ? rawMethod.trim() : '';
      if (method.isEmpty) {
        throw _invalidRule(sourceId, file.path, index);
      }
      final declaredTrigger = switch (method) {
        'level_up' ||
        'friendship' ||
        'known_move' =>
          PokemonEvolutionTriggerKind.levelUp,
        'use_item' || 'item' => PokemonEvolutionTriggerKind.itemUse,
        _ => null,
      };
      if (declaredTrigger == null ||
          !acceptedTriggers.contains(declaredTrigger)) {
        continue;
      }
      final rawTargetId = entry['targetSpeciesId'];
      final targetId = rawTargetId is String && _isSafeSpeciesId(rawTargetId)
          ? rawTargetId
          : '';
      final condition = _conditionFor(
        entry,
        method: method,
        sourceSpeciesId: sourceId,
        filePath: file.path,
        index: index,
      );
      if (condition == null) continue;
      final normalizedItemFilter = itemId?.trim();
      if (normalizedItemFilter != null &&
          normalizedItemFilter.isNotEmpty &&
          condition.itemId != normalizedItemFilter) {
        continue;
      }
      if (targetId.isEmpty || targetId == sourceId) {
        throw _invalidRule(sourceId, file.path, index);
      }

      final RuntimePokemonSpecies target;
      try {
        target = await speciesLoader.loadById(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
          speciesId: targetId,
        );
      } on RuntimePokemonSpeciesDisabledException {
        continue;
      }
      try {
        candidates.add(
          PokemonEvolutionCandidate(
            opportunityId: _opportunityId(
              sourceSpeciesId: sourceId,
              targetSpeciesId: targetId,
              index: index,
              condition: condition,
            ),
            sourceSpeciesId: sourceId,
            targetSpeciesId: targetId,
            condition: condition,
            targetBaseStats: PokemonBaseStats(
              hp: target.baseHp,
              attack: target.baseAttack,
              defense: target.baseDefense,
              specialAttack: target.baseSpecialAttack,
              specialDefense: target.baseSpecialDefense,
              speed: target.baseSpeed,
            ),
            targetPrimaryAbilityId: target.primaryAbilityId,
            targetAbilityIds: target.abilityIds,
          ).validated(),
        );
      } on ArgumentError catch (error) {
        throw RuntimeBattleSetupException(
          'Les données de l’espèce cible d’évolution sont invalides.',
          debugDetails:
              'speciesId=$sourceId, targetSpeciesId=$targetId, evolutions[$index], abilities/stats invalid: $error',
        );
      }
    }

    final tokens = <String>{};
    for (final candidate in candidates) {
      if (!tokens.add(candidate.opportunityId)) {
        throw RuntimeBattleSetupException(
          'Les données d’évolution Pokémon locales sont ambiguës.',
          debugDetails:
              'speciesId=$sourceId, duplicate token=${candidate.opportunityId}',
        );
      }
    }
    return List<PokemonEvolutionCandidate>.unmodifiable(candidates);
  }

  PokemonEvolutionCondition? _conditionFor(
    Map<String, dynamic> entry, {
    required String method,
    required String sourceSpeciesId,
    required String filePath,
    required int index,
  }) {
    final minLevel = entry['minLevel'];
    final rawMinFriendship = entry['minFriendship'];
    final rawItemId = entry['itemId'];
    final itemId = rawItemId is String ? rawItemId.trim() : '';
    final rawMoveId = entry['requiredMoveId'];
    final moveId = rawMoveId is String ? rawMoveId.trim() : '';

    try {
      return switch (method) {
        'level_up' when rawMinFriendship != null =>
          PokemonEvolutionCondition.friendship(
            minFriendship: rawMinFriendship as int,
            minLevel: (minLevel as int?) ?? 2,
          ).validated(),
        'friendship' => PokemonEvolutionCondition.friendship(
            minFriendship: rawMinFriendship as int,
            minLevel: (minLevel as int?) ?? 2,
          ).validated(),
        'level_up' when moveId.isNotEmpty =>
          PokemonEvolutionCondition.knownMove(
            moveId: moveId,
            minLevel: (minLevel as int?) ?? 2,
          ).validated(),
        'known_move' => PokemonEvolutionCondition.knownMove(
            moveId: moveId,
            minLevel: (minLevel as int?) ?? 2,
          ).validated(),
        'level_up' => PokemonEvolutionCondition.level(
            minLevel: minLevel as int,
          ).validated(),
        'use_item' || 'item' => PokemonEvolutionCondition.item(
            itemId: itemId,
            minLevel: (minLevel as int?) ?? 1,
          ).validated(),
        _ => null,
      };
    } on Object {
      throw _invalidRule(sourceSpeciesId, filePath, index);
    }
  }

  String _conditionToken(PokemonEvolutionCondition condition) {
    return switch (condition.kind) {
      PokemonEvolutionConditionKind.level => '${condition.minLevel}',
      PokemonEvolutionConditionKind.friendship =>
        '${condition.minLevel}:${condition.minFriendship}',
      PokemonEvolutionConditionKind.item =>
        '${condition.minLevel}:${condition.itemId}',
      PokemonEvolutionConditionKind.knownMove =>
        '${condition.minLevel}:${condition.moveId}',
    };
  }

  String _opportunityId({
    required String sourceSpeciesId,
    required String targetSpeciesId,
    required int index,
    required PokemonEvolutionCondition condition,
  }) {
    if (condition.kind == PokemonEvolutionConditionKind.level) {
      return '$sourceSpeciesId:levelUp:$index:${condition.minLevel}:'
          '$targetSpeciesId';
    }
    return '$sourceSpeciesId:${condition.kind.name}:$index:'
        '${_conditionToken(condition)}:$targetSpeciesId';
  }

  String _validatedSourceId(String rawSourceSpeciesId) {
    if (!_isSafeSpeciesId(rawSourceSpeciesId)) {
      throw RuntimeBattleSetupException(
        'Impossible de déterminer les évolutions de cette espèce Pokémon.',
        debugDetails: 'Invalid source species id=$rawSourceSpeciesId',
      );
    }
    return rawSourceSpeciesId;
  }

  bool _isSafeSpeciesId(String speciesId) {
    return speciesId.isNotEmpty &&
        speciesId == speciesId.trim() &&
        speciesId != '.' &&
        speciesId != '..' &&
        !p.isAbsolute(speciesId) &&
        p.basename(speciesId) == speciesId &&
        !speciesId.contains('/') &&
        !speciesId.contains(r'\');
  }

  File _boundedEvolutionFile({
    required String projectRootDirectory,
    required String configuredDirectory,
    required String sourceSpeciesId,
  }) {
    final root = p.normalize(p.absolute(projectRootDirectory));
    final trimmedDirectory = configuredDirectory.trim();
    final relativeDirectory =
        trimmedDirectory.isEmpty ? 'data/pokemon/evolutions' : trimmedDirectory;
    if (p.isAbsolute(relativeDirectory)) {
      throw RuntimeBattleSetupException(
        'Le dossier d’évolution Pokémon doit appartenir au projet.',
        debugDetails: 'Absolute evolutionsDir is forbidden: $relativeDirectory',
      );
    }
    final directory = p.normalize(p.join(root, relativeDirectory));
    if (directory != root && !p.isWithin(root, directory)) {
      throw RuntimeBattleSetupException(
        'Le dossier d’évolution Pokémon doit appartenir au projet.',
        debugDetails: 'evolutionsDir escapes project root: $relativeDirectory',
      );
    }
    final filePath = p.normalize(p.join(directory, '$sourceSpeciesId.json'));
    if (!p.isWithin(directory, filePath)) {
      throw RuntimeBattleSetupException(
        'Le fichier d’évolution Pokémon doit appartenir au projet.',
        debugDetails: 'Evolution file escapes configured directory: $filePath',
      );
    }
    return File(filePath);
  }

  Future<Map<String, dynamic>> _readJson(
    File file, {
    required String sourceSpeciesId,
  }) async {
    if (!await file.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les évolutions Pokémon locales.',
        debugDetails:
            'speciesId=$sourceSpeciesId, evolution file not found: ${file.path}',
      );
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root JSON object expected');
      }
      return decoded;
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Impossible de lire les évolutions Pokémon locales.',
        debugDetails:
            'speciesId=$sourceSpeciesId, file=${file.path}, parse failed: $error',
      );
    }
  }

  RuntimeBattleSetupException _invalidRule(
    String sourceSpeciesId,
    String filePath,
    int index,
  ) {
    return RuntimeBattleSetupException(
      'Les données d’évolution Pokémon locales sont invalides.',
      debugDetails:
          'speciesId=$sourceSpeciesId, file=$filePath, evolutions[$index] requires a supported complete condition and a distinct targetSpeciesId',
    );
  }
}

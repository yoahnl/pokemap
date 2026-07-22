import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';
import 'runtime_pokemon_species_loader.dart';

/// Strict project-data adapter for the FG-047 level-evolution MVP.
///
/// Unsupported methods are intentionally ignored. A rule explicitly marked
/// `level_up`, however, is either complete and usable or fails closed.
final class RuntimePokemonEvolutionLoader {
  RuntimePokemonEvolutionLoader({
    RuntimePokemonSpeciesLoader? speciesLoader,
  }) : speciesLoader = speciesLoader ?? RuntimePokemonSpeciesLoader();

  final RuntimePokemonSpeciesLoader speciesLoader;

  Future<List<PokemonEvolutionCandidate>> loadLevelUpCandidates({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String sourceSpeciesId,
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
      if (method != 'level_up') continue;

      final rawTargetId = entry['targetSpeciesId'];
      final targetId = rawTargetId is String && _isSafeSpeciesId(rawTargetId)
          ? rawTargetId
          : '';
      final rawMinLevel = entry['minLevel'];
      if (targetId.isEmpty ||
          targetId == sourceId ||
          rawMinLevel is! int ||
          rawMinLevel < 2 ||
          rawMinLevel > 100) {
        throw _invalidRule(sourceId, file.path, index);
      }

      final target = await speciesLoader.loadById(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
        speciesId: targetId,
      );
      try {
        candidates.add(
          PokemonEvolutionCandidate(
            opportunityId: '$sourceId:levelUp:$index:$rawMinLevel:$targetId',
            sourceSpeciesId: sourceId,
            targetSpeciesId: targetId,
            minLevel: rawMinLevel,
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
          'speciesId=$sourceSpeciesId, file=$filePath, evolutions[$index] requires a method; level_up requires a distinct targetSpeciesId and integer minLevel in 2..100',
    );
  }
}

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit un payload PokeAPI de type `/pokemon/{id}` vers
/// [PokemonLearnsetFile].
///
/// Cette fondation couvre uniquement le lot 31 :
/// - lecture des méthodes d'apprentissage exposées par PokeAPI ;
/// - mapping vers les familles de learnset déjà existantes ;
/// - aucun accès réseau ;
/// - aucune écriture locale.
///
/// Décisions assumées :
/// - `level-up` alimente `levelUp` ;
/// - les moves niveau 1 alimentent aussi `startingMoves` et `relearnMoves` ;
/// - `machine`, `tutor` et `egg` sont mappés directement ;
/// - les méthodes spéciales héritées/spin-off sont repliées vers `event` ;
/// - les méthodes inconnues restantes sont repliées vers `transfer`.
class PokeApiPokemonLearnsetConverter {
  const PokeApiPokemonLearnsetConverter();

  PokemonLearnsetFile convert({
    required String speciesId,
    required Map<String, dynamic> payload,
  }) {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'PokeAPI learnset speciesId cannot be empty',
      );
    }

    final rawMoves = payload['moves'];
    if (rawMoves is! List) {
      throw const EditorPersistenceException(
        'PokeAPI learnset payload must contain a moves list',
      );
    }

    final startingMoves = <String>{};
    final relearnMoves = <String>{};
    final levelUp = <PokemonLearnsetLevelUpEntry>[];
    final tm = <PokemonLearnsetMoveEntry>[];
    final tutor = <PokemonLearnsetMoveEntry>[];
    final egg = <PokemonLearnsetMoveEntry>[];
    final event = <PokemonLearnsetMoveEntry>[];
    final transfer = <PokemonLearnsetMoveEntry>[];

    final moveEntryKeys = <String>{};
    final levelUpKeys = <String>{};

    for (var moveIndex = 0; moveIndex < rawMoves.length; moveIndex++) {
      final rawMoveEntry = rawMoves[moveIndex];
      if (rawMoveEntry is! Map) {
        throw EditorPersistenceException(
          'PokeAPI move entry at index $moveIndex must be an object',
        );
      }

      final moveEntry = rawMoveEntry.cast<String, dynamic>();
      final moveId = _readNamedResourceId(
        moveEntry['move'],
        field: 'moves[$moveIndex].move',
        canonicalizeSnakeCase: true,
      );

      final rawDetails = moveEntry['version_group_details'];
      if (rawDetails is! List) {
        throw EditorPersistenceException(
          'PokeAPI move entry "$moveId" must contain version_group_details',
        );
      }

      for (var detailIndex = 0;
          detailIndex < rawDetails.length;
          detailIndex++) {
        final rawDetail = rawDetails[detailIndex];
        if (rawDetail is! Map) {
          throw EditorPersistenceException(
            'PokeAPI version detail at moves[$moveIndex].version_group_details'
            '[$detailIndex] must be an object',
          );
        }

        final detail = rawDetail.cast<String, dynamic>();
        final method = _readNamedResourceId(
          detail['move_learn_method'],
          field:
              'moves[$moveIndex].version_group_details[$detailIndex].move_learn_method',
        );
        final versionGroup = _readNamedResourceId(
          detail['version_group'],
          field:
              'moves[$moveIndex].version_group_details[$detailIndex].version_group',
        );
        final level = _readOptionalInt(detail['level_learned_at']) ?? 0;

        switch (method) {
          case 'level-up':
            final levelKey = '$moveId|$versionGroup|$level';
            if (levelUpKeys.add(levelKey)) {
              levelUp.add(
                PokemonLearnsetLevelUpEntry(
                  moveId: moveId,
                  level: level <= 0 ? 1 : level,
                  source: 'level_up',
                  versionGroup: versionGroup,
                ),
              );
            }

            if (level <= 1) {
              startingMoves.add(moveId);
              relearnMoves.add(moveId);
            }
            break;
          case 'machine':
            _addMoveEntry(
              target: tm,
              keys: moveEntryKeys,
              bucket: 'tm',
              moveId: moveId,
              versionGroup: versionGroup,
            );
            break;
          case 'tutor':
            _addMoveEntry(
              target: tutor,
              keys: moveEntryKeys,
              bucket: 'tutor',
              moveId: moveId,
              versionGroup: versionGroup,
            );
            break;
          case 'egg':
            _addMoveEntry(
              target: egg,
              keys: moveEntryKeys,
              bucket: 'egg',
              moveId: moveId,
              versionGroup: versionGroup,
            );
            break;
          default:
            if (_isEventLikeMethod(method)) {
              _addMoveEntry(
                target: event,
                keys: moveEntryKeys,
                bucket: 'event',
                moveId: moveId,
                versionGroup: versionGroup,
              );
            } else {
              _addMoveEntry(
                target: transfer,
                keys: moveEntryKeys,
                bucket: 'transfer',
                moveId: moveId,
                versionGroup: versionGroup,
              );
            }
            break;
        }
      }
    }

    final learnset = PokemonLearnsetFile(
      speciesId: normalizedSpeciesId,
      // On stabilise explicitement l'ordre de sortie pour éviter les diffs
      // parasites et les tests fragiles quand l'ordre source varie.
      startingMoves: (startingMoves.toList(growable: false)..sort()),
      relearnMoves: (relearnMoves.toList(growable: false)..sort()),
      levelUp: _sortLevelUp(levelUp),
      tm: _sortMoveEntries(tm),
      tutor: _sortMoveEntries(tutor),
      egg: _sortMoveEntries(egg),
      event: _sortMoveEntries(event),
      transfer: _sortMoveEntries(transfer),
    );

    _validateLearnset(learnset);
    return learnset;
  }

  void _addMoveEntry({
    required List<PokemonLearnsetMoveEntry> target,
    required Set<String> keys,
    required String bucket,
    required String moveId,
    required String versionGroup,
  }) {
    final key = '$bucket|$moveId|$versionGroup';
    if (!keys.add(key)) {
      return;
    }

    target.add(
      PokemonLearnsetMoveEntry(
        moveId: moveId,
        versionGroup: versionGroup,
      ),
    );
  }

  bool _isEventLikeMethod(String method) {
    return method.contains('egg') ||
        method.contains('stadium') ||
        method.contains('colosseum') ||
        method.contains('xd') ||
        method.contains('form-change') ||
        method.contains('zygarde');
  }

  void _validateLearnset(PokemonLearnsetFile learnset) {
    final hasAnySection = learnset.startingMoves.isNotEmpty ||
        learnset.relearnMoves.isNotEmpty ||
        learnset.levelUp.isNotEmpty ||
        learnset.tm.isNotEmpty ||
        learnset.tutor.isNotEmpty ||
        learnset.egg.isNotEmpty ||
        learnset.event.isNotEmpty ||
        learnset.transfer.isNotEmpty;

    if (!hasAnySection) {
      throw const EditorValidationException(
        'PokeAPI learnset payload produced no usable move data',
      );
    }
  }

  List<PokemonLearnsetLevelUpEntry> _sortLevelUp(
    List<PokemonLearnsetLevelUpEntry> entries,
  ) {
    final sorted = List<PokemonLearnsetLevelUpEntry>.from(entries);
    sorted.sort((left, right) {
      final levelCompare = left.level.compareTo(right.level);
      if (levelCompare != 0) return levelCompare;

      final moveCompare = left.moveId.compareTo(right.moveId);
      if (moveCompare != 0) return moveCompare;

      final versionCompare = left.versionGroup.compareTo(right.versionGroup);
      if (versionCompare != 0) return versionCompare;

      return left.source.compareTo(right.source);
    });
    return sorted;
  }

  List<PokemonLearnsetMoveEntry> _sortMoveEntries(
    List<PokemonLearnsetMoveEntry> entries,
  ) {
    final sorted = List<PokemonLearnsetMoveEntry>.from(entries);
    sorted.sort((left, right) {
      final moveCompare = left.moveId.compareTo(right.moveId);
      if (moveCompare != 0) return moveCompare;
      return left.versionGroup.compareTo(right.versionGroup);
    });
    return sorted;
  }

  String _readNamedResourceId(
    Object? raw, {
    required String field,
    bool canonicalizeSnakeCase = false,
  }) {
    if (raw is! Map) {
      throw EditorPersistenceException(
        'PokeAPI field "$field" must be a named resource object',
      );
    }

    final name = (raw['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      throw EditorValidationException(
        'PokeAPI field "$field" must define a non-empty name',
      );
    }
    if (!canonicalizeSnakeCase) {
      return name;
    }

    return _normalizeSnakeCaseId(name);
  }

  int? _readOptionalInt(Object? raw) {
    return (raw as num?)?.toInt();
  }

  String _normalizeSnakeCaseId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final separated = trimmed.replaceAll(RegExp(r'[\s-]+'), '_');
    return separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }
}

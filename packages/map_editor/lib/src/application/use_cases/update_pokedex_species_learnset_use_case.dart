import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Surface d'édition locale du lot 41.
///
/// Le but est d'éditer le learnset déjà modélisé par le projet, pas d'inventer
/// une nouvelle notion "d'autorisation" parallèle.
class UpdatePokedexSpeciesLearnsetRequest {
  const UpdatePokedexSpeciesLearnsetRequest({
    required this.speciesId,
    required this.startingMoves,
    required this.relearnMoves,
    required this.levelUp,
    required this.tm,
    required this.tutor,
    required this.egg,
    required this.event,
    required this.transfer,
  });

  final String speciesId;
  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<PokemonLearnsetLevelUpEntry> levelUp;
  final List<PokemonLearnsetMoveEntry> tm;
  final List<PokemonLearnsetMoveEntry> tutor;
  final List<PokemonLearnsetMoveEntry> egg;
  final List<PokemonLearnsetMoveEntry> event;
  final List<PokemonLearnsetMoveEntry> transfer;
}

typedef PokedexSpeciesLearnsetSaver = Future<PokemonLearnsetFile> Function(
  ProjectWorkspace workspace,
  UpdatePokedexSpeciesLearnsetRequest request,
);

/// Réécrit le learnset local d'une espèce via le repository existant.
///
/// Le use case :
/// - relit l'espèce pour respecter sa ref learnset existante ;
/// - autorise la création du fichier learnset s'il n'existe pas encore ;
/// - applique une validation structurelle locale symétrique au lot 24 ;
/// - s'appuie sur le catalogue local `moves` quand il existe réellement ;
/// - n'écrit jamais ailleurs qu'au chemin déjà contractuel du repository.
class UpdatePokedexSpeciesLearnsetUseCase {
  const UpdatePokedexSpeciesLearnsetUseCase({
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonLearnsetFile> execute(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    final speciesId = request.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }

    final currentSpecies = await readRepository.readSpeciesById(
      workspace,
      speciesId,
    );
    final learnsetRef = currentSpecies.refs.learnset.trim();
    if (learnsetRef.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species learnset ref cannot be empty',
      );
    }

    final learnset = PokemonLearnsetFile(
      speciesId: learnsetRef,
      startingMoves: _normalizeMoveIds(request.startingMoves),
      relearnMoves: _normalizeMoveIds(request.relearnMoves),
      levelUp: _normalizeLevelUpEntries(request.levelUp),
      tm: _normalizeMoveEntries(request.tm),
      tutor: _normalizeMoveEntries(request.tutor),
      egg: _normalizeMoveEntries(request.egg),
      event: _normalizeMoveEntries(request.event),
      transfer: _normalizeMoveEntries(request.transfer),
    );

    _validateLearnset(learnset);
    await _validateAgainstLocalMovesCatalogIfAvailable(workspace, learnset);
    await writeRepository.saveLearnset(workspace, learnset);
    return learnset;
  }

  Future<void> _validateAgainstLocalMovesCatalogIfAvailable(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) async {
    // Intégration minimale utile de la 11B :
    // - si un vrai catalogue local des attaques est disponible, on l'utilise
    //   comme garde-fou avant d'écrire le learnset ;
    // - si le catalogue est absent ou illisible, on n'empêche pas l'édition,
    //   car la 11B ne doit pas transformer un problème de stockage global en
    //   blocage absolu de l'onglet Learnset.
    //
    // Cette règle garde l'éditeur utile dans un workspace partiellement
    // préparé, tout en apportant enfin une validation réellement exploitable
    // dès que le catalogue local existe.
    final availableMoveIds = await _readAvailableMoveIdsIfPossible(workspace);
    if (availableMoveIds == null || availableMoveIds.isEmpty) {
      return;
    }

    final missingMoveIds = _collectUsedMoveIds(learnset)
        .where((moveId) => !availableMoveIds.contains(moveId))
        .toList(growable: false)
      ..sort();
    if (missingMoveIds.isEmpty) {
      return;
    }

    throw EditorValidationException(
      'Pokemon learnset references moves absent from the local moves catalog: '
      '${missingMoveIds.join(', ')}. Synchronisez le catalogue local des '
      'attaques ou corrigez les move ids.',
    );
  }

  Future<Set<String>?> _readAvailableMoveIdsIfPossible(
    ProjectWorkspace workspace,
  ) async {
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
      return catalog.entries
          .map((entry) => (entry['id'] as String?)?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet();
    } on EditorApplicationException {
      // Non-objectif explicite :
      // on ne convertit pas ce use case local en validateur global de
      // catalogue. Les erreurs de lecture du catalogue restent traitées par
      // le validateur projet et par la surface 11B dédiée au sync.
      return null;
    }
  }

  Set<String> _collectUsedMoveIds(PokemonLearnsetFile learnset) {
    return <String>{
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp.map((entry) => entry.moveId),
      ...learnset.tm.map((entry) => entry.moveId),
      ...learnset.tutor.map((entry) => entry.moveId),
      ...learnset.egg.map((entry) => entry.moveId),
      ...learnset.event.map((entry) => entry.moveId),
      ...learnset.transfer.map((entry) => entry.moveId),
    }.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();
  }

  List<String> _normalizeMoveIds(List<String> values) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final rawValue in values) {
      final value = rawValue.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      normalized.add(value);
    }
    return normalized;
  }

  List<PokemonLearnsetLevelUpEntry> _normalizeLevelUpEntries(
    List<PokemonLearnsetLevelUpEntry> values,
  ) {
    return values
        .map(
          (entry) => PokemonLearnsetLevelUpEntry(
            moveId: entry.moveId.trim(),
            level: entry.level,
            source: entry.source.trim(),
            versionGroup: entry.versionGroup.trim(),
          ),
        )
        .toList(growable: false);
  }

  List<PokemonLearnsetMoveEntry> _normalizeMoveEntries(
    List<PokemonLearnsetMoveEntry> values,
  ) {
    return values
        .map(
          (entry) => PokemonLearnsetMoveEntry(
            moveId: entry.moveId.trim(),
            versionGroup: entry.versionGroup.trim(),
          ),
        )
        .toList(growable: false);
  }

  void _validateLearnset(PokemonLearnsetFile learnset) {
    if (learnset.speciesId.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset speciesId cannot be empty',
      );
    }

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
        'Pokemon learnset must contain at least one move section',
      );
    }

    for (final moveId in learnset.startingMoves) {
      if (moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset startingMoves cannot contain empty move ids',
        );
      }
    }

    for (final moveId in learnset.relearnMoves) {
      if (moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset relearnMoves cannot contain empty move ids',
        );
      }
    }

    for (final entry in learnset.levelUp) {
      if (entry.moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp moveId cannot be empty',
        );
      }
      if (entry.level <= 0) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp level must be positive',
        );
      }
      if (entry.source.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp source cannot be empty',
        );
      }
      if (entry.versionGroup.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp versionGroup cannot be empty',
        );
      }
    }

    void validateMoveEntries(
      List<PokemonLearnsetMoveEntry> entries,
      String label,
    ) {
      for (final entry in entries) {
        if (entry.moveId.trim().isEmpty) {
          throw EditorValidationException(
            'Pokemon learnset $label moveId cannot be empty',
          );
        }
        if (entry.versionGroup.trim().isEmpty) {
          throw EditorValidationException(
            'Pokemon learnset $label versionGroup cannot be empty',
          );
        }
      }
    }

    validateMoveEntries(learnset.tm, 'tm');
    validateMoveEntries(learnset.tutor, 'tutor');
    validateMoveEntries(learnset.egg, 'egg');
    validateMoveEntries(learnset.event, 'event');
    validateMoveEntries(learnset.transfer, 'transfer');
  }
}

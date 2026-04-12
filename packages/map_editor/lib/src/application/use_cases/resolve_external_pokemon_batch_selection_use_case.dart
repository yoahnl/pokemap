import '../errors/application_errors.dart';
import '../models/pokemon_external_batch_selection.dart';
import '../models/pokemon_external_query_resolution.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../services/pokemon_external_query_resolver.dart';

/// Résout une requête batch externe en vraies cibles Pokédex.
///
/// Ce use case répond exactement au besoin du lot 3 :
/// - réutiliser le résolveur du lot 1 ;
/// - accepter explicitement les formes batch prévues par la roadmap ;
/// - charger une source snapshot déjà branchée dans l'infrastructure ;
/// - produire une liste finale stable, dédupliquée et lisible.
///
/// Non-objectifs explicites :
/// - aucune écriture ;
/// - aucun dry-run d'import ici ;
/// - aucune logique UI ;
/// - aucun nouveau pipeline externe parallèle.
class ResolveExternalPokemonBatchSelectionUseCase {
  ResolveExternalPokemonBatchSelectionUseCase({
    required this.externalSourceRepository,
    required this.queryResolver,
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonExternalQueryResolver queryResolver;

  Future<_IndexedExternalBatchSpeciesSnapshot>? _cachedSnapshotFuture;

  Future<PokemonExternalBatchSelectionResult> execute(String rawQuery) async {
    final resolution = queryResolver.resolve(rawQuery);

    if (resolution is PokemonExternalInvalidQueryResolution) {
      if (resolution.code == PokemonExternalInvalidQueryCode.emptyQuery) {
        return PokemonExternalBatchSelectionResult.empty(
          rawQuery: resolution.rawQuery,
          normalizedQuery: resolution.normalizedQuery,
        );
      }
      return PokemonExternalBatchSelectionResult.invalidQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: resolution.message,
      );
    }

    if (resolution is PokemonExternalSingleQueryResolution) {
      return PokemonExternalBatchSelectionResult.outOfScopeQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Le mode batch attend une liste explicite, une plage Pokédex '
            'ou une génération.',
      );
    }

    try {
      final snapshotIndex = await _loadIndexedSnapshot();
      return switch (resolution) {
        PokemonExternalExplicitListQueryResolution explicitList =>
          _resolveExplicitList(snapshotIndex, explicitList),
        PokemonExternalNationalDexRangeQueryResolution range =>
          _resolveNationalDexRange(snapshotIndex, range),
        PokemonExternalGenerationQueryResolution generation =>
          _resolveGeneration(snapshotIndex, generation),
        PokemonExternalInvalidQueryResolution() ||
        PokemonExternalSingleQueryResolution() =>
          throw StateError('Unexpected resolution kind in batch resolver'),
      };
    } on EditorApplicationException catch (error) {
      return PokemonExternalBatchSelectionResult.error(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: error.message,
      );
    } catch (error) {
      return PokemonExternalBatchSelectionResult.error(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Résolution batch externe indisponible : $error',
      );
    }
  }

  Future<_IndexedExternalBatchSpeciesSnapshot> _loadIndexedSnapshot() {
    final cached = _cachedSnapshotFuture;
    if (cached != null) {
      return cached;
    }

    final future = () async {
      final snapshot =
          await externalSourceRepository.fetchShowdownPokedexSnapshot();
      return _IndexedExternalBatchSpeciesSnapshot.fromSnapshot(snapshot);
    }();

    _cachedSnapshotFuture = future;
    return future;
  }

  PokemonExternalBatchSelectionResult _resolveExplicitList(
    _IndexedExternalBatchSpeciesSnapshot snapshotIndex,
    PokemonExternalExplicitListQueryResolution resolution,
  ) {
    final unresolvedInputs = <String>[];
    final targetBuilders = <String, _BatchSelectionTargetBuilder>{};

    for (final query in resolution.queries) {
      final requestedInput = query.rawValue.trim();
      final resolvedSpecies = snapshotIndex.resolveExplicitQuery(query);
      if (resolvedSpecies == null) {
        unresolvedInputs.add(requestedInput);
        continue;
      }

      final builder = targetBuilders.putIfAbsent(
        resolvedSpecies.speciesId,
        () => _BatchSelectionTargetBuilder(
          speciesId: resolvedSpecies.speciesId,
          primaryName: resolvedSpecies.primaryName,
          nationalDex: resolvedSpecies.nationalDex,
          generation: resolvedSpecies.generation,
        ),
      );
      builder.addRequestedInput(requestedInput);
    }

    final targets = targetBuilders.values
        .map((builder) => builder.build())
        .toList(growable: false);

    if (targets.isEmpty) {
      return PokemonExternalBatchSelectionResult.noResults(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message:
            'Aucune espèce externe exploitable n’a été résolue pour cette liste.',
      );
    }

    if (unresolvedInputs.isNotEmpty) {
      final joinedInputs = unresolvedInputs.join(', ');
      return PokemonExternalBatchSelectionResult.invalidQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        targets: targets,
        message: unresolvedInputs.length == 1
            ? 'Impossible de résoudre la cible batch `$joinedInputs`.'
            : 'Impossible de résoudre les cibles batch suivantes : '
                '$joinedInputs.',
      );
    }

    return PokemonExternalBatchSelectionResult.resolved(
      rawQuery: resolution.rawQuery,
      normalizedQuery: resolution.normalizedQuery,
      resolution: resolution,
      targets: targets,
    );
  }

  PokemonExternalBatchSelectionResult _resolveNationalDexRange(
    _IndexedExternalBatchSpeciesSnapshot snapshotIndex,
    PokemonExternalNationalDexRangeQueryResolution resolution,
  ) {
    final targets = snapshotIndex
        .resolveNationalDexRange(
          startNationalDex: resolution.startNationalDex,
          endNationalDex: resolution.endNationalDex,
          requestedInput: resolution.normalizedQuery,
        )
        .toList(growable: false);

    if (targets.isEmpty) {
      return PokemonExternalBatchSelectionResult.noResults(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Aucune espèce de base n’a été trouvée pour cette plage '
            'Pokédex.',
      );
    }

    return PokemonExternalBatchSelectionResult.resolved(
      rawQuery: resolution.rawQuery,
      normalizedQuery: resolution.normalizedQuery,
      resolution: resolution,
      targets: targets,
    );
  }

  PokemonExternalBatchSelectionResult _resolveGeneration(
    _IndexedExternalBatchSpeciesSnapshot snapshotIndex,
    PokemonExternalGenerationQueryResolution resolution,
  ) {
    final targets = snapshotIndex
        .resolveGeneration(
          generation: resolution.generation,
          requestedInput: resolution.normalizedQuery,
        )
        .toList(growable: false);

    if (targets.isEmpty) {
      return PokemonExternalBatchSelectionResult.noResults(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Aucune espèce de base n’a été trouvée pour cette génération.',
      );
    }

    return PokemonExternalBatchSelectionResult.resolved(
      rawQuery: resolution.rawQuery,
      normalizedQuery: resolution.normalizedQuery,
      resolution: resolution,
      targets: targets,
    );
  }
}

class _IndexedExternalBatchSpeciesSnapshot {
  _IndexedExternalBatchSpeciesSnapshot({
    required this.baseEntries,
    required this.entriesBySpeciesId,
    required this.entriesByPrimaryName,
    required this.baseEntriesByNationalDex,
  });

  factory _IndexedExternalBatchSpeciesSnapshot.fromSnapshot(
    Map<String, dynamic> snapshot,
  ) {
    final baseEntries = <_IndexedExternalBatchSpeciesEntry>[];
    final entriesBySpeciesId = <String, _IndexedExternalBatchSpeciesEntry>{};
    final entriesByPrimaryName =
        <String, List<_IndexedExternalBatchSpeciesEntry>>{};
    final baseEntriesByNationalDex = <int, _IndexedExternalBatchSpeciesEntry>{};

    for (final entry in snapshot.entries) {
      final rawPayload = entry.value;
      if (rawPayload is! Map) {
        continue;
      }

      final speciesId = entry.key.trim().toLowerCase();
      if (speciesId.isEmpty) {
        continue;
      }

      final payload = rawPayload.cast<String, dynamic>();
      final nationalDex = (payload['num'] as num?)?.toInt() ?? 0;
      if (nationalDex <= 0) {
        continue;
      }

      final primaryName = (payload['name'] as String?)?.trim();
      if (primaryName == null || primaryName.isEmpty) {
        continue;
      }

      final generation = (payload['gen'] as num?)?.toInt();
      final baseSpecies = (payload['baseSpecies'] as String?)?.trim();
      final normalizedSpeciesId = _normalizeLookupToken(speciesId);
      final normalizedPrimaryName = _normalizeLookupToken(primaryName);
      final normalizedBaseSpecies = baseSpecies == null || baseSpecies.isEmpty
          ? null
          : _normalizeLookupToken(baseSpecies);
      final isBaseSpecies =
          normalizedBaseSpecies == null || normalizedBaseSpecies.isEmpty;

      final indexedEntry = _IndexedExternalBatchSpeciesEntry(
        speciesId: speciesId,
        primaryName: primaryName,
        nationalDex: nationalDex,
        generation: generation,
        normalizedSpeciesId: normalizedSpeciesId,
        normalizedPrimaryName: normalizedPrimaryName,
        isBaseSpecies: isBaseSpecies,
      );

      entriesBySpeciesId[normalizedSpeciesId] = indexedEntry;
      entriesByPrimaryName
          .putIfAbsent(
            normalizedPrimaryName,
            () => <_IndexedExternalBatchSpeciesEntry>[],
          )
          .add(indexedEntry);

      if (isBaseSpecies) {
        // Les requêtes batch par génération/plage/dex doivent rester lisibles
        // et stables. On n'y injecte donc pas les formes Showdown qui partagent
        // le même numéro Pokédex que leur espèce de base.
        baseEntries.add(indexedEntry);
        baseEntriesByNationalDex[nationalDex] = indexedEntry;
      }
    }

    baseEntries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) {
        return dexCompare;
      }
      return left.speciesId.compareTo(right.speciesId);
    });

    return _IndexedExternalBatchSpeciesSnapshot(
      baseEntries: List<_IndexedExternalBatchSpeciesEntry>.unmodifiable(
        baseEntries,
      ),
      entriesBySpeciesId:
          Map<String, _IndexedExternalBatchSpeciesEntry>.unmodifiable(
        entriesBySpeciesId,
      ),
      entriesByPrimaryName:
          Map<String, List<_IndexedExternalBatchSpeciesEntry>>.unmodifiable(
        entriesByPrimaryName.map(
          (key, value) =>
              MapEntry<String, List<_IndexedExternalBatchSpeciesEntry>>(
            key,
            List<_IndexedExternalBatchSpeciesEntry>.unmodifiable(value),
          ),
        ),
      ),
      baseEntriesByNationalDex:
          Map<int, _IndexedExternalBatchSpeciesEntry>.unmodifiable(
        baseEntriesByNationalDex,
      ),
    );
  }

  final List<_IndexedExternalBatchSpeciesEntry> baseEntries;
  final Map<String, _IndexedExternalBatchSpeciesEntry> entriesBySpeciesId;
  final Map<String, List<_IndexedExternalBatchSpeciesEntry>>
      entriesByPrimaryName;
  final Map<int, _IndexedExternalBatchSpeciesEntry> baseEntriesByNationalDex;

  _IndexedExternalBatchSpeciesEntry? resolveExplicitQuery(
    PokemonExternalSingleQuery query,
  ) {
    return switch (query.kind) {
      PokemonExternalSingleQueryKind.nationalDex =>
        baseEntriesByNationalDex[query.nationalDex],
      PokemonExternalSingleQueryKind.species =>
        _resolveExplicitSpeciesQuery(query.normalizedValue!),
    };
  }

  Iterable<PokemonExternalBatchSelectionTarget> resolveNationalDexRange({
    required int startNationalDex,
    required int endNationalDex,
    required String requestedInput,
  }) sync* {
    for (final entry in baseEntries) {
      if (entry.nationalDex < startNationalDex ||
          entry.nationalDex > endNationalDex) {
        continue;
      }
      yield entry.toSelectionTarget(
        requestedInputs: <String>[requestedInput],
      );
    }
  }

  Iterable<PokemonExternalBatchSelectionTarget> resolveGeneration({
    required int generation,
    required String requestedInput,
  }) sync* {
    for (final entry in baseEntries) {
      if (entry.generation != generation) {
        continue;
      }
      yield entry.toSelectionTarget(
        requestedInputs: <String>[requestedInput],
      );
    }
  }

  _IndexedExternalBatchSpeciesEntry? _resolveExplicitSpeciesQuery(
    String normalizedValue,
  ) {
    final exactSpeciesIdMatch = entriesBySpeciesId[normalizedValue];
    if (exactSpeciesIdMatch != null) {
      return exactSpeciesIdMatch;
    }

    final exactNameMatches = entriesByPrimaryName[normalizedValue];
    if (exactNameMatches == null || exactNameMatches.isEmpty) {
      return null;
    }
    if (exactNameMatches.length == 1) {
      return exactNameMatches.single;
    }

    final baseMatch = exactNameMatches.where((entry) => entry.isBaseSpecies);
    if (baseMatch.length == 1) {
      return baseMatch.single;
    }

    return null;
  }

  static String _normalizeLookupToken(String rawValue) {
    final lowered = rawValue.trim().toLowerCase();
    return lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class _IndexedExternalBatchSpeciesEntry {
  const _IndexedExternalBatchSpeciesEntry({
    required this.speciesId,
    required this.primaryName,
    required this.nationalDex,
    required this.generation,
    required this.normalizedSpeciesId,
    required this.normalizedPrimaryName,
    required this.isBaseSpecies,
  });

  final String speciesId;
  final String primaryName;
  final int nationalDex;
  final int? generation;
  final String normalizedSpeciesId;
  final String normalizedPrimaryName;
  final bool isBaseSpecies;

  PokemonExternalBatchSelectionTarget toSelectionTarget({
    required List<String> requestedInputs,
  }) {
    return PokemonExternalBatchSelectionTarget(
      speciesId: speciesId,
      primaryName: primaryName,
      nationalDex: nationalDex,
      generation: generation,
      requestedInputs: requestedInputs,
    );
  }
}

class _BatchSelectionTargetBuilder {
  _BatchSelectionTargetBuilder({
    required this.speciesId,
    required this.primaryName,
    required this.nationalDex,
    required this.generation,
  });

  final String speciesId;
  final String primaryName;
  final int nationalDex;
  final int? generation;
  final List<String> _requestedInputs = <String>[];

  void addRequestedInput(String input) {
    if (input.isEmpty || _requestedInputs.contains(input)) {
      return;
    }
    _requestedInputs.add(input);
  }

  PokemonExternalBatchSelectionTarget build() {
    return PokemonExternalBatchSelectionTarget(
      speciesId: speciesId,
      primaryName: primaryName,
      nationalDex: nationalDex,
      generation: generation,
      requestedInputs: _requestedInputs,
    );
  }
}

import '../models/pokemon_external_query_resolution.dart';

/// Résolveur pur de requête d'import Pokédex externe.
///
/// Ce service ne fait qu'une chose :
/// transformer une string utilisateur brute en intention structurée.
///
/// Non-objectifs explicites du lot 1 :
/// - aucun accès réseau ;
/// - aucune lecture PokeAPI / Showdown ;
/// - aucune écriture projet ;
/// - aucune preview d'import ;
/// - aucune exécution batch ;
/// - aucune logique UI.
///
/// Ce résolveur est volontairement conservateur :
/// - il accepte les formes explicitement supportées ;
/// - il refuse les saisies ambiguës plutôt que de deviner ;
/// - il déduplique les listes explicites ;
/// - il garde une sémantique strictement déterministe.
class PokemonExternalQueryResolver {
  const PokemonExternalQueryResolver();

  static final RegExp _digitsPattern = RegExp(r'^\d+$');
  static final RegExp _nationalDexRangePattern = RegExp(r'^(\d+)\s*-\s*(\d+)$');
  static final RegExp _generationPattern =
      RegExp(r'^(?:gen|generation)\s+(\d+)$');

  /// Règle volontairement stricte pour les requêtes unitaires textuelles.
  ///
  /// On accepte les ids/noms simples de type slug/identifiant. En revanche,
  /// une suite de mots séparés par des espaces sans virgule explicite est
  /// refusée pour éviter de prendre silencieusement une liste ambiguë pour une
  /// espèce unique.
  static final RegExp _singleSpeciesTokenPattern =
      RegExp(r"^[a-z0-9][a-z0-9._'-]*$");

  /// Résout une saisie brute en intention structurée.
  PokemonExternalQueryResolution resolve(String rawQuery) {
    final normalizedQuery = _normalizeGlobalInput(rawQuery);
    final loweredQuery = normalizedQuery.toLowerCase();

    if (normalizedQuery.isEmpty) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.emptyQuery,
        message: 'La requête est vide.',
      );
    }

    // Une liste n'est reconnue que si le séparateur est explicite.
    // Cela évite qu'une saisie du type "pikachu eevee abra" soit interprétée
    // silencieusement comme un batch, ce que le lot 1 doit refuser.
    if (normalizedQuery.contains(',')) {
      return _resolveExplicitList(rawQuery, normalizedQuery);
    }

    final rangeMatch = _nationalDexRangePattern.firstMatch(loweredQuery);
    if (rangeMatch != null) {
      return _resolveNationalDexRange(rawQuery, normalizedQuery, rangeMatch);
    }
    if (_looksLikeNationalDexRangeCandidate(loweredQuery)) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.invalidNationalDexRange,
        message:
            'La plage Pokédex demandée est invalide. Utilisez une forme du '
            'type `1-151`.',
      );
    }

    final generationMatch = _generationPattern.firstMatch(loweredQuery);
    if (generationMatch != null) {
      return _resolveGeneration(rawQuery, normalizedQuery, generationMatch);
    }
    if (_looksLikeGenerationCandidate(loweredQuery)) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.invalidGeneration,
        message: 'La génération demandée est invalide. Utilisez une forme du '
            'type `gen 1` ou `generation 1`.',
      );
    }

    if (_looksLikeAmbiguousWhitespaceSeparatedTerms(normalizedQuery)) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.ambiguousWhitespaceSeparatedTerms,
        message:
            'La requête contient plusieurs termes séparés par des espaces. '
            'Utilisez des virgules pour une liste explicite.',
      );
    }

    final singleQuery = _resolveSingleQuery(rawValue: normalizedQuery);

    if (singleQuery == null) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.unsupportedFormat,
        message:
            'Le format de requête n’est pas reconnu pour un import externe.',
      );
    }

    return PokemonExternalSingleQueryResolution(
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      query: singleQuery,
    );
  }

  PokemonExternalQueryResolution _resolveExplicitList(
    String rawQuery,
    String normalizedQuery,
  ) {
    final rawEntries = normalizedQuery.split(',');
    final queries = <PokemonExternalSingleQuery>[];
    final seenKeys = <String>{};

    for (final rawEntry in rawEntries) {
      final normalizedEntry = _normalizeGlobalInput(rawEntry);
      if (normalizedEntry.isEmpty) {
        return PokemonExternalInvalidQueryResolution(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          code: PokemonExternalInvalidQueryCode.invalidExplicitList,
          message: 'La liste explicite contient au moins une entrée vide ou un '
              'séparateur incohérent.',
        );
      }

      final loweredEntry = normalizedEntry.toLowerCase();
      if (_nationalDexRangePattern.hasMatch(loweredEntry) ||
          _generationPattern.hasMatch(loweredEntry) ||
          _looksLikeAmbiguousWhitespaceSeparatedTerms(normalizedEntry)) {
        return PokemonExternalInvalidQueryResolution(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          code: PokemonExternalInvalidQueryCode.invalidExplicitList,
          message: 'Chaque entrée de la liste doit être une cible simple '
              '(espèce ou numéro dex), séparée par des virgules.',
        );
      }

      final query = _resolveSingleQuery(rawValue: normalizedEntry);
      if (query == null) {
        return PokemonExternalInvalidQueryResolution(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          code: PokemonExternalInvalidQueryCode.invalidExplicitList,
          message: 'La liste explicite contient au moins une entrée invalide.',
        );
      }

      if (seenKeys.add(query.deduplicationKey)) {
        queries.add(query);
      }
    }

    return PokemonExternalExplicitListQueryResolution(
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      queries: queries,
    );
  }

  PokemonExternalQueryResolution _resolveNationalDexRange(
    String rawQuery,
    String normalizedQuery,
    RegExpMatch rangeMatch,
  ) {
    final start = int.tryParse(rangeMatch.group(1)!);
    final end = int.tryParse(rangeMatch.group(2)!);

    if (start == null ||
        end == null ||
        start <= 0 ||
        end <= 0 ||
        start >= end) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.invalidNationalDexRange,
        message: 'La plage Pokédex doit contenir deux nombres positifs dans '
            'l’ordre croissant.',
      );
    }

    return PokemonExternalNationalDexRangeQueryResolution(
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      startNationalDex: start,
      endNationalDex: end,
    );
  }

  PokemonExternalQueryResolution _resolveGeneration(
    String rawQuery,
    String normalizedQuery,
    RegExpMatch generationMatch,
  ) {
    final generation = int.tryParse(generationMatch.group(1)!);
    if (generation == null || generation <= 0) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.invalidGeneration,
        message: 'La génération demandée est invalide.',
      );
    }

    return PokemonExternalGenerationQueryResolution(
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      generation: generation,
    );
  }

  PokemonExternalSingleQuery? _resolveSingleQuery({
    required String rawValue,
  }) {
    final normalizedValue = _normalizeGlobalInput(rawValue);
    if (normalizedValue.isEmpty) {
      return null;
    }

    if (_digitsPattern.hasMatch(normalizedValue)) {
      final nationalDex = int.tryParse(normalizedValue);
      if (nationalDex == null || nationalDex <= 0) {
        return null;
      }
      return PokemonExternalSingleQuery.nationalDex(
        rawValue: normalizedValue,
        nationalDex: nationalDex,
      );
    }

    final loweredValue = normalizedValue.toLowerCase();
    if (!_singleSpeciesTokenPattern.hasMatch(loweredValue)) {
      return null;
    }

    return PokemonExternalSingleQuery.species(
      rawValue: normalizedValue,
      normalizedValue: loweredValue,
    );
  }

  bool _looksLikeAmbiguousWhitespaceSeparatedTerms(String value) {
    final collapsed = _normalizeGlobalInput(value);
    if (!collapsed.contains(' ')) {
      return false;
    }

    // Toute suite de plusieurs termes séparés par espaces, sans séparateur
    // explicite de liste, est traitée comme ambiguë dans ce lot. On préfère
    // refuser et demander des virgules plutôt que de parser silencieusement
    // une pseudo-liste dans l'UI.
    return collapsed.split(' ').where((token) => token.isNotEmpty).length > 1;
  }

  bool _looksLikeNationalDexRangeCandidate(String loweredValue) {
    return loweredValue.contains('-') &&
        RegExp(r'^[\d\s-]+$').hasMatch(loweredValue);
  }

  bool _looksLikeGenerationCandidate(String loweredValue) {
    return loweredValue == 'gen' ||
        loweredValue == 'generation' ||
        loweredValue.startsWith('gen ') ||
        loweredValue.startsWith('generation ');
  }

  String _normalizeGlobalInput(String rawValue) {
    return rawValue.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

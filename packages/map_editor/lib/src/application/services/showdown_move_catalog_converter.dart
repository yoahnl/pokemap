import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit `moves.json` de Pokémon Showdown vers le catalogue local `moves`.
///
/// Décision de phase 11B :
/// - Showdown est la source primaire retenue pour le bulk sync du catalogue,
///   car le snapshot expose déjà toutes les métadonnées structurées utiles ;
/// - PokeAPI a bien été auditée, mais n'est pas utilisée ici comme source
///   principale parce qu'elle imposerait une fan-out HTTP par move, hors du
///   scope minimal et raisonnable de cette phase ;
/// - on garde donc un import déterministe, compact et testable.
///
/// Invariants assumés :
/// - les ids locaux restent en `snake_case` pour rester cohérents avec les
///   learnsets déjà normalisés par le pipeline 11A ;
/// - seules les clés réellement utiles au catalogue local minimal sont mappées ;
/// - les champs non supportés localement sont ignorés au lieu d'être recopiés
///   aveuglément depuis la source externe.
class ShowdownMoveCatalogConverter {
  const ShowdownMoveCatalogConverter();

  /// Produit un [PokemonCatalogFile] local complet à partir du snapshot brut.
  ///
  /// Le catalogue de sortie reste volontairement simple :
  /// - `kind` et `catalog` suivent le contrat déjà stabilisé du repo ;
  /// - les entrées sont triées par `id` pour éviter les diffs parasites ;
  /// - la méta décrit explicitement la stratégie source retenue pour 11B.
  PokemonCatalogFile convert(Map<String, dynamic> snapshot) {
    if (snapshot.isEmpty) {
      throw const EditorValidationException(
        'Showdown moves snapshot cannot be empty',
      );
    }

    final entries = snapshot.entries
        .map(
          (snapshotEntry) => _convertEntry(
            rawId: snapshotEntry.key,
            rawEntry: snapshotEntry.value,
          ),
        )
        .toList(growable: false)
      ..sort(
        (left, right) => ((left['id'] as String?) ?? '').compareTo(
          (right['id'] as String?) ?? '',
        ),
      );

    return PokemonCatalogFile(
      schemaVersion: 1,
      kind: 'pokemon_catalog',
      catalog: 'moves',
      meta: const PokemonDataMeta(
        description:
            'Moves catalog synchronized from the Pokémon Showdown moves snapshot.',
        sourcePriority: <String>['showdown', 'local_merge'],
        notes: <String>[
          'Phase 11B keeps Showdown as the primary bulk source for local moves.',
          'PokeAPI move payloads were audited but not selected for bulk sync.',
          'Move ids are normalized to snake_case to stay consistent with learnsets.',
        ],
      ),
      entries: entries,
    );
  }

  Map<String, dynamic> _convertEntry({
    required String rawId,
    required Object? rawEntry,
  }) {
    if (rawEntry is! Map) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" must be an object',
      );
    }

    final entry = rawEntry.cast<String, dynamic>();
    final displayName = _readDisplayName(rawId, entry);
    final localId = _normalizeSnakeCaseId(displayName);
    if (localId.isEmpty) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" does not expose a usable local id',
      );
    }

    final type = _readLowerCaseString(entry['type']);
    final category = _readLowerCaseString(entry['category']);
    final target = _readLowerCaseString(entry['target']);
    final generation = _readOptionalInt(entry['gen']);
    final pp = _readOptionalInt(entry['pp']);
    final priority = _readOptionalInt(entry['priority']) ?? 0;
    final power = _readOptionalPower(entry['basePower']);
    final accuracy = _readOptionalNumericAccuracy(entry['accuracy']);
    final accuracyText = _readAccuracyText(entry['accuracy']);
    final shortDesc = _readTrimmedString(entry['shortDesc']);
    final description = _readTrimmedString(entry['desc']);

    return <String, dynamic>{
      'id': localId,
      'name': displayName,
      'names': <String, String>{'en': displayName},
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      'power': power,
      'accuracy': accuracy,
      if (accuracyText != null) 'accuracyText': accuracyText,
      if (pp != null) 'pp': pp,
      'priority': priority,
      if (target != null) 'target': target,
      if (shortDesc != null) 'shortDesc': shortDesc,
      if (description != null) 'description': description,
      if (generation != null) 'generation': generation,
    };
  }

  String _readDisplayName(String rawId, Map<String, dynamic> entry) {
    final explicitName = _readTrimmedString(entry['name']);
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }
    return _humanizeIdentifier(rawId);
  }

  String? _readLowerCaseString(Object? rawValue) {
    final value = _readTrimmedString(rawValue);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toLowerCase();
  }

  String? _readTrimmedString(Object? rawValue) {
    final value = rawValue as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  int? _readOptionalInt(Object? rawValue) {
    return (rawValue as num?)?.toInt();
  }

  int? _readOptionalPower(Object? rawValue) {
    final value = (rawValue as num?)?.toInt();
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  num? _readOptionalNumericAccuracy(Object? rawValue) {
    // Showdown encode certains moves "always hit" avec `true`. Le modèle local
    // minimal de 11B ne cherche pas à sur-typer tous les cas spéciaux : on
    // garde alors la valeur numérique quand elle existe, sinon on laisse
    // `accuracy` à null et on expose éventuellement un `accuracyText`.
    if (rawValue is num) {
      return rawValue;
    }
    return null;
  }

  String? _readAccuracyText(Object? rawValue) {
    if (rawValue == true) {
      return 'always';
    }
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      return rawValue.trim().toLowerCase();
    }
    return null;
  }

  String _normalizeSnakeCaseId(String rawValue) {
    final lowerCase = rawValue.trim().toLowerCase();
    if (lowerCase.isEmpty) {
      return '';
    }

    final separated = lowerCase.replaceAll(RegExp(r'[\s-]+'), '_');
    final asciiSafe = separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    final collapsed = asciiSafe.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }

  String _humanizeIdentifier(String rawId) {
    final prepared = rawId
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .trim();

    if (prepared.isEmpty) {
      return rawId;
    }

    return prepared
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

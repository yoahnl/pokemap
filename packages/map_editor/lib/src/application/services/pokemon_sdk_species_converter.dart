import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

final class PokemonSdkSpeciesConverter {
  const PokemonSdkSpeciesConverter();

  PokemonSpeciesFile convert(Map<String, Object?> payload) {
    final dbSymbol = _readRequiredString(
      payload,
      const <String>['dbSymbol', 'db_symbol'],
    );
    final id = _normalizeSnakeCaseId(dbSymbol);
    if (id.isEmpty) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio pokemon dbSymbol must be usable as an id',
      );
    }

    final names = _readNames(payload['name'], fallback: dbSymbol);
    final types = _readStringList(payload['types'])
        .map(_normalizeSnakeCaseId)
        .where((type) => type.isNotEmpty)
        .toList(growable: false);
    if (types.isEmpty) {
      throw EditorPersistenceException(
        'Pokemon SDK Studio pokemon "$dbSymbol" must define at least one type',
      );
    }

    final stats = _readStats(payload['baseStats'] ?? payload['base_stats']);
    final abilities = _readAbilities(payload['abilities']);

    return PokemonSpeciesFile(
      id: id,
      slug: id,
      nationalDex: _readInt(payload, const <String>['id', 'nationalDex']) ?? 0,
      names: names,
      speciesName: const <String, String>{},
      genIntroduced:
          _readInt(payload, const <String>['generation', 'genIntroduced']) ?? 0,
      typing: PokemonSpeciesTyping(types: types),
      baseStats: stats,
      abilities: abilities,
      breeding: const PokemonSpeciesBreeding(genderRatio: <String, double>{}),
      progression: const PokemonSpeciesProgression(
        growthRateId: '',
        baseExp: 0,
        catchRate: 0,
        baseFriendship: 0,
      ),
      refs: PokemonSpeciesRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
      dexContent: PokemonSpeciesDexContent(
        heightM: _readDouble(payload['height']),
        weightKg: _readDouble(payload['weight']),
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(),
      sourceMeta: const PokemonSpeciesSourceMeta(
        seededBy: 'pokemon_sdk_studio',
      ),
    );
  }

  String _readRequiredString(
    Map<String, Object?> payload,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    throw EditorPersistenceException(
      'Pokemon SDK Studio pokemon is missing required field ${keys.first}',
    );
  }

  int? _readInt(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value == null) continue;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
      throw EditorPersistenceException(
        'Pokemon SDK Studio pokemon field $key must be an integer',
      );
    }
    return null;
  }

  double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  PokemonSpeciesBaseStats _readStats(Object? value) {
    if (value is! Map) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio pokemon baseStats must be an object',
      );
    }
    final map = value.cast<String, Object?>();
    final hp = _readStat(map, const <String>['hp']);
    final atk = _readStat(map, const <String>['atk', 'attack']);
    final def = _readStat(map, const <String>['def', 'defense']);
    final spa = _readStat(
      map,
      const <String>['spa', 'spAtk', 'specialAttack'],
    );
    final spd = _readStat(
      map,
      const <String>['spd', 'spDef', 'specialDefense'],
    );
    final spe = _readStat(map, const <String>['spe', 'speed']);
    return PokemonSpeciesBaseStats(
      hp: hp,
      atk: atk,
      def: def,
      spa: spa,
      spd: spd,
      spe: spe,
      bst: hp + atk + def + spa + spd + spe,
    );
  }

  int _readStat(Map<String, Object?> payload, List<String> keys) {
    final value = _readInt(payload, keys);
    if (value == null) {
      throw EditorPersistenceException(
        'Pokemon SDK Studio pokemon baseStats is missing ${keys.first}',
      );
    }
    return value;
  }

  PokemonSpeciesAbilities _readAbilities(Object? value) {
    if (value is List) {
      final abilities = value
          .whereType<String>()
          .map(_normalizeSnakeCaseId)
          .where((ability) => ability.isNotEmpty)
          .toList(growable: false);
      if (abilities.isEmpty) {
        throw const EditorPersistenceException(
          'Pokemon SDK Studio pokemon abilities must not be empty',
        );
      }
      return PokemonSpeciesAbilities(
        primary: abilities.first,
        secondary: abilities.length > 2 ? abilities[1] : null,
        hidden: abilities.length > 1 ? abilities.last : null,
      );
    }
    if (value is Map) {
      final map = value.cast<String, Object?>();
      final primary = _readOptionalAbility(map, const <String>['0', 'primary']);
      final secondary =
          _readOptionalAbility(map, const <String>['1', 'secondary']);
      final hidden = _readOptionalAbility(map, const <String>['H', 'hidden']);
      if (primary == null) {
        throw const EditorPersistenceException(
          'Pokemon SDK Studio pokemon abilities must define a primary ability',
        );
      }
      return PokemonSpeciesAbilities(
        primary: primary,
        secondary: secondary,
        hidden: hidden,
      );
    }
    throw const EditorPersistenceException(
      'Pokemon SDK Studio pokemon abilities must be a list or object',
    );
  }

  String? _readOptionalAbility(
      Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return _normalizeSnakeCaseId(value);
      }
    }
    return null;
  }

  List<String> _readStringList(Object? value) {
    if (value is! List) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio pokemon types must be a list',
      );
    }
    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, String> _readNames(Object? value, {required String fallback}) {
    if (value is Map) {
      final names = <String, String>{};
      for (final entry in value.entries) {
        final key = entry.key;
        final rawValue = entry.value;
        if (key is String && rawValue is String) {
          final normalizedKey = key.trim();
          final normalizedValue = rawValue.trim();
          if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
            names[normalizedKey] = normalizedValue;
          }
        }
      }
      if (names.isNotEmpty) return names;
    }
    if (value is String && value.trim().isNotEmpty) {
      return <String, String>{'en': value.trim()};
    }
    return <String, String>{'en': _humanizeIdentifier(fallback)};
  }

  String _normalizeSnakeCaseId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final separated = trimmed.replaceAll(RegExp(r'[\s-]+'), '_');
    return separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }

  String _humanizeIdentifier(String identifier) {
    final spaced = identifier.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (spaced.isEmpty) return identifier;
    return spaced
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}

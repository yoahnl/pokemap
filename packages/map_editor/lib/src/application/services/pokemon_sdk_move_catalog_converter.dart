import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

final class PokemonSdkMoveCatalogConverter {
  const PokemonSdkMoveCatalogConverter();

  PokemonMove convert(Map<String, Object?> payload) {
    final dbSymbol = _readRequiredString(
      payload,
      const <String>['dbSymbol', 'db_symbol'],
    );
    final id = _normalizeSnakeCaseId(dbSymbol);
    if (id.isEmpty) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio move dbSymbol must be usable as an id',
      );
    }

    final names = _readNames(payload['name']);
    final displayName = _readDisplayName(payload['name'], fallback: dbSymbol);
    final battleEngineMethod = _readRequiredString(
      payload,
      const <String>['battleEngineMethod', 'battle_engine_method'],
    );
    final target = _readTarget(
      _readOptionalString(
        payload,
        const <String>[
          'battleEngineAimedTarget',
          'battle_engine_aimed_target',
          'aimedTarget',
          'aimed_target',
        ],
      ),
    );

    final move = PokemonMove(
      id: id,
      name: displayName,
      names: names,
      source: 'pokemon_sdk_studio',
      type: _normalizeSnakeCaseId(
        _readRequiredString(payload, const <String>['type']),
      ),
      category: _readCategory(payload['category']),
      target: target,
      basePower: _readInt(payload, const <String>['power', 'basePower']) ?? 0,
      accuracy: _readAccuracy(payload['accuracy']),
      pp: _readInt(payload, const <String>['pp']) ?? 0,
      priority: _readInt(payload, const <String>['priority']) ?? 0,
      critRatio:
          _readInt(payload, const <String>['criticalRate', 'critical_rate']) ??
              1,
      flags: _readFlags(payload['flags']),
      effects: _readEffects(payload),
      engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
      unsupportedReasons: <String>['psdk_method:$battleEngineMethod'],
    );

    try {
      return move.normalized();
    } on StateError catch (error) {
      throw EditorPersistenceException(
        'Invalid Pokemon SDK Studio move "$dbSymbol": ${error.message}',
      );
    }
  }

  PokemonCatalogFile convertCatalog(List<Map<String, Object?>> entries) {
    if (entries.isEmpty) {
      throw const EditorValidationException(
        'Pokemon SDK Studio moves catalog cannot be empty',
      );
    }

    final converted = entries.map(_convertCatalogEntry).toList(growable: false)
      ..sort(
        (left, right) => ((left['dbSymbol'] as String?) ?? '').compareTo(
          (right['dbSymbol'] as String?) ?? '',
        ),
      );

    return PokemonCatalogFile(
      schemaVersion: 1,
      kind: 'pokemon_catalog',
      catalog: 'moves',
      meta: const PokemonDataMeta(
        description:
            'Moves catalog synchronized from Pokemon SDK Studio data files.',
        sourcePriority: <String>['pokemon_sdk_studio', 'local_merge'],
        notes: <String>[
          'Converted through the canonical PokemonMove model.',
          'Battle behavior stays referenced by Pokemon SDK Studio method names.',
        ],
      ),
      entries: converted,
    );
  }

  Map<String, dynamic> _convertCatalogEntry(Map<String, Object?> payload) {
    final entry = convert(payload).toJson();
    final dbSymbol = _readRequiredString(
      payload,
      const <String>['dbSymbol', 'db_symbol'],
    ).trim();
    final battleEngineMethod = _readRequiredString(
      payload,
      const <String>['battleEngineMethod', 'battle_engine_method'],
    );

    entry['dbSymbol'] = dbSymbol;
    entry['battleEngineMethod'] = battleEngineMethod;

    final sourceRefs = (entry['sourceRefs'] as Map).cast<String, dynamic>();
    void keepSourceRef(String key, Object? value) {
      if (value != null) {
        sourceRefs[key] = value.toString();
      }
    }

    keepSourceRef(
      'psdkStudioMoveId',
      _readOptionalString(payload, const <String>['id']),
    );
    keepSourceRef('psdkDbSymbol', dbSymbol);
    keepSourceRef('psdkBattleEngineMethod', battleEngineMethod);
    keepSourceRef(
      'psdkScriptClass',
      _readOptionalString(
        payload,
        const <String>['scriptClass', 'script_class'],
      ),
    );
    keepSourceRef(
      'psdkScriptPath',
      _readOptionalString(
        payload,
        const <String>['scriptPath', 'script_path'],
      ),
    );
    keepSourceRef(
      'psdkAnimationId',
      _readOptionalString(
        payload,
        const <String>['animationId', 'animation_id'],
      ),
    );
    entry['sourceRefs'] = sourceRefs;
    return entry;
  }

  String _readRequiredString(
    Map<String, Object?> payload,
    List<String> keys,
  ) {
    final value = _readOptionalString(payload, keys);
    if (value == null || value.isEmpty) {
      throw EditorPersistenceException(
        'Pokemon SDK Studio move is missing required field ${keys.first}',
      );
    }
    return value;
  }

  String? _readOptionalString(
    Map<String, Object?> payload,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = payload[key];
      if (value == null) continue;
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      if (value is num || value is bool) {
        final stringValue = value.toString().trim();
        return stringValue.isEmpty ? null : stringValue;
      }
      throw EditorPersistenceException(
        'Pokemon SDK Studio move field $key must be scalar',
      );
    }
    return null;
  }

  int? _readInt(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      if (!payload.containsKey(key)) continue;
      final value = payload[key];
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
      throw EditorPersistenceException(
        'Pokemon SDK Studio move field $key must be an integer',
      );
    }
    return null;
  }

  int _readEffectChance(Map<String, Object?> payload) {
    final value = _readInt(
      payload,
      const <String>['effectChance', 'effect_chance'],
    );
    if (value == null || value == 0) {
      return 100;
    }
    if (value < 1 || value > 100) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio move effectChance must be between 0 and 100',
      );
    }
    return value;
  }

  PokemonMoveAccuracy _readAccuracy(Object? value) {
    if (value == null) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio move is missing required field accuracy',
      );
    }
    if (value is bool) {
      if (value) {
        return const PokemonMoveAccuracy.alwaysHits();
      }
      throw const EditorPersistenceException(
        'Pokemon SDK Studio move accuracy cannot be false',
      );
    }
    if (value is num) {
      if (value == 0) {
        return const PokemonMoveAccuracy.alwaysHits();
      }
      return PokemonMoveAccuracy.percent(value: value.toInt()).normalized();
    }
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == 'true' || trimmed == 'always' || trimmed == 'never_fail') {
        return const PokemonMoveAccuracy.alwaysHits();
      }
      final parsed = int.tryParse(trimmed);
      if (parsed != null) {
        if (parsed == 0) {
          return const PokemonMoveAccuracy.alwaysHits();
        }
        return PokemonMoveAccuracy.percent(value: parsed).normalized();
      }
    }
    throw const EditorPersistenceException(
      'Pokemon SDK Studio move accuracy must be a percent or always-hit flag',
    );
  }

  PokemonMoveCategory _readCategory(Object? value) {
    final normalized = _normalizeToken(value);
    return switch (normalized) {
      'physical' => PokemonMoveCategory.physical,
      'special' => PokemonMoveCategory.special,
      'status' => PokemonMoveCategory.status,
      _ => throw EditorPersistenceException(
          'Pokemon SDK Studio move category "$value" is unsupported',
        ),
    };
  }

  PokemonMoveTarget _readTarget(String? value) {
    final normalized = _normalizeToken(value);
    return switch (normalized) {
      '' || 'none' => PokemonMoveTarget.normal,
      'adjacentally' => PokemonMoveTarget.adjacentAlly,
      'adjacentallyorself' => PokemonMoveTarget.adjacentAllyOrSelf,
      'adjacentfoe' || 'adjacentpokemon' => PokemonMoveTarget.adjacentFoe,
      'alladjacent' => PokemonMoveTarget.allAdjacent,
      'alladjacentfoes' ||
      'adjacentallfoe' ||
      'adjacentallfoes' =>
        PokemonMoveTarget.allAdjacentFoes,
      'allbattlers' || 'allpokemon' => PokemonMoveTarget.all,
      'allfoes' => PokemonMoveTarget.allAdjacentFoes,
      'allallies' => PokemonMoveTarget.allies,
      'anyfoe' || 'bank' => PokemonMoveTarget.any,
      'randomfoe' => PokemonMoveTarget.randomNormal,
      'self' || 'user' => PokemonMoveTarget.self,
      'userside' => PokemonMoveTarget.allySide,
      'foeside' => PokemonMoveTarget.foeSide,
      _ => PokemonMoveTarget.scripted,
    };
  }

  List<PokemonMoveFlag> _readFlags(Object? value) {
    if (value == null) {
      return const <PokemonMoveFlag>[];
    }
    if (value is! Map) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio move flags must be an object',
      );
    }
    bool flag(String name) => _readBooleanFlag(value, name);

    return <PokemonMoveFlag>[
      if (flag('direct')) PokemonMoveFlag.contact,
      if (flag('blocable')) PokemonMoveFlag.protect,
      if (flag('mirrorMove')) PokemonMoveFlag.mirror,
      if (flag('gravity')) PokemonMoveFlag.gravity,
      if (flag('punch')) PokemonMoveFlag.punch,
      if (flag('soundAttack')) PokemonMoveFlag.sound,
      if (flag('slicingAttack')) PokemonMoveFlag.slicing,
      if (flag('wind')) PokemonMoveFlag.wind,
      if (flag('heal')) PokemonMoveFlag.heal,
      if (flag('bite')) PokemonMoveFlag.bite,
      if (flag('pulse')) PokemonMoveFlag.pulse,
      if (flag('powder')) PokemonMoveFlag.powder,
      if (flag('dance')) PokemonMoveFlag.dance,
      if (flag('ballistics')) PokemonMoveFlag.bullet,
      if (flag('unfreeze')) PokemonMoveFlag.defrost,
      if (flag('authentic')) PokemonMoveFlag.bypassSubstitute,
    ];
  }

  bool _readBooleanFlag(Map<Object?, Object?> flags, String field) {
    final candidates = <String>{
      field,
      _camelToSnake(field),
      field.toLowerCase(),
    };
    for (final entry in flags.entries) {
      final key = entry.key;
      if (key is! String) continue;
      if (!candidates.contains(key.trim())) continue;
      final value = entry.value;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        return switch (value.trim().toLowerCase()) {
          'true' || '1' || 'yes' => true,
          _ => false,
        };
      }
    }
    return false;
  }

  List<PokemonMoveEffect> _readEffects(Map<String, Object?> payload) {
    return <PokemonMoveEffect>[
      ..._readBattleStageEffects(payload),
      ..._readStatusEffects(payload),
    ];
  }

  List<PokemonMoveEffect> _readBattleStageEffects(
    Map<String, Object?> payload,
  ) {
    final raw = payload['battleStageMods'] ??
        payload['battle_stage_mods'] ??
        payload['battleStageMod'] ??
        payload['battle_stage_mod'];
    if (raw == null) {
      return const <PokemonMoveEffect>[];
    }
    if (raw is! List) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio move battleStageMods must be a list',
      );
    }
    return raw.map((entry) {
      if (entry is! Map) {
        throw const EditorPersistenceException(
          'Pokemon SDK Studio move battleStageMods entries must be objects',
        );
      }
      final map = entry.cast<String, Object?>();
      return PokemonMoveEffect.modifyStats(
        targetScope: _readTargetScope(
          _readOptionalString(
            map,
            const <String>['targetScope', 'target_scope'],
          ),
        ),
        chance: _readEffectChance(payload),
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: _readStatId(
              _readRequiredString(
                map,
                const <String>['stat', 'battleStage', 'battle_stage'],
              ),
            ),
            stages: _readInt(
                  map,
                  const <String>['stages', 'modificator', 'modifier'],
                ) ??
                0,
          ),
        ],
      ).normalized();
    }).toList(growable: false);
  }

  List<PokemonMoveEffect> _readStatusEffects(
    Map<String, Object?> payload,
  ) {
    final raw = payload['moveStatuses'] ??
        payload['move_statuses'] ??
        payload['moveStatus'] ??
        payload['move_status'];
    if (raw == null) {
      return const <PokemonMoveEffect>[];
    }
    if (raw is! List) {
      throw const EditorPersistenceException(
        'Pokemon SDK Studio move moveStatuses must be a list',
      );
    }
    return raw.map((entry) {
      if (entry is! Map) {
        throw const EditorPersistenceException(
          'Pokemon SDK Studio move moveStatuses entries must be objects',
        );
      }
      final map = entry.cast<String, Object?>();
      return PokemonMoveEffect.applyStatus(
        statusId: _normalizeSnakeCaseId(
          _readRequiredString(
            map,
            const <String>['status', 'statusId', 'status_id'],
          ),
        ),
        chance: _readInt(
              map,
              const <String>['chance', 'luckRate', 'luck_rate'],
            ) ??
            _readEffectChance(payload),
        targetScope: _readTargetScope(
          _readOptionalString(
            map,
            const <String>['targetScope', 'target_scope'],
          ),
        ),
      ).normalized();
    }).toList(growable: false);
  }

  PokemonMoveStatId _readStatId(String raw) {
    final normalized = _normalizeToken(raw);
    return switch (normalized) {
      'atk' || 'attack' => PokemonMoveStatId.attack,
      'def' || 'defense' => PokemonMoveStatId.defense,
      'ats' ||
      'spa' ||
      'spatk' ||
      'specialattack' =>
        PokemonMoveStatId.specialAttack,
      'dfs' ||
      'spd' ||
      'spdef' ||
      'specialdefense' =>
        PokemonMoveStatId.specialDefense,
      'spe' || 'spdstat' || 'speed' => PokemonMoveStatId.speed,
      'accuracy' => PokemonMoveStatId.accuracy,
      'evasion' || 'eva' => PokemonMoveStatId.evasion,
      _ => throw EditorPersistenceException(
          'Pokemon SDK Studio move stat "$raw" is unsupported',
        ),
    };
  }

  PokemonMoveEffectTargetScope _readTargetScope(String? raw) {
    final normalized = _normalizeToken(raw);
    return switch (normalized) {
      '' || 'target' => PokemonMoveEffectTargetScope.target,
      'self' || 'user' => PokemonMoveEffectTargetScope.self,
      'field' => PokemonMoveEffectTargetScope.field,
      'allyside' || 'userside' => PokemonMoveEffectTargetScope.allySide,
      'foeside' => PokemonMoveEffectTargetScope.foeSide,
      'slot' => PokemonMoveEffectTargetScope.slot,
      _ => PokemonMoveEffectTargetScope.target,
    };
  }

  Map<String, String> _readNames(Object? value) {
    if (value is Map) {
      final entries = <String, String>{};
      for (final entry in value.entries) {
        final key = entry.key;
        final rawValue = entry.value;
        if (key is String && rawValue is String) {
          final normalizedKey = key.trim();
          final normalizedValue = rawValue.trim();
          if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
            entries[normalizedKey] = normalizedValue;
          }
        }
      }
      return entries;
    }
    if (value is String && value.trim().isNotEmpty) {
      return <String, String>{'en': value.trim()};
    }
    return const <String, String>{};
  }

  String _readDisplayName(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is Map) {
      final english = value['en'];
      if (english is String && english.trim().isNotEmpty) {
        return english.trim();
      }
      final names = value.values.whereType<String>().map((name) => name.trim());
      for (final name in names) {
        if (name.isNotEmpty) return name;
      }
    }
    return _humanizeIdentifier(fallback);
  }

  String _normalizeToken(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String _normalizeSnakeCaseId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final separated = trimmed.replaceAll(RegExp(r'[\s-]+'), '_');
    return separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }

  String _camelToSnake(String value) {
    return value.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
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

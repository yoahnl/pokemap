Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> raw) {
  final next = Map<String, dynamic>.from(raw);
  if (!next.containsKey('dialogues')) {
    next['dialogues'] = <dynamic>[];
  }
  if (!next.containsKey('dialogueFolders')) {
    next['dialogueFolders'] = <dynamic>[];
  }
  if (!next.containsKey('tilesetFolders')) {
    next['tilesetFolders'] = <dynamic>[];
  }
  if (!next.containsKey('characters')) {
    next['characters'] = <dynamic>[];
  }
  final settings = raw['settings'];
  if (settings is Map) {
    final migratedSettings =
        Map<String, dynamic>.from(settings.cast<String, dynamic>());
    if (!migratedSettings.containsKey('defaultPlayerCharacterId') &&
        migratedSettings['playerCharacterId'] != null) {
      migratedSettings['defaultPlayerCharacterId'] =
          migratedSettings['playerCharacterId'];
    }
    next['settings'] = migratedSettings;
  }
  final legacyCategories = raw['terrainPresetCategories'];
  if (!next.containsKey('terrainCategories') && legacyCategories is List) {
    next['terrainCategories'] = legacyCategories
        .whereType<Map>()
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .where((entry) => entry['kind'] == 'terrain')
        .map((entry) {
      entry.remove('kind');
      return entry;
    }).toList(growable: false);
  }
  if (!next.containsKey('pathCategories') && legacyCategories is List) {
    next['pathCategories'] = legacyCategories
        .whereType<Map>()
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .where((entry) => entry['kind'] == 'path')
        .map((entry) {
      entry.remove('kind');
      return entry;
    }).toList(growable: false);
  }

  final pathPresets = raw['pathPresets'];
  if (pathPresets is! List) {
    final trainers = raw['trainers'];
    if (trainers is List) {
      next['trainers'] = trainers.map((entry) {
        if (entry is! Map) {
          return entry;
        }
        final trainer =
            Map<String, dynamic>.from(entry.cast<String, dynamic>());
        if (!trainer.containsKey('characterId')) {
          final legacyCharacterId = trainer['overworldCharacterId'] ??
              trainer['spriteCharacterId'] ??
              trainer['characterRef'];
          if (legacyCharacterId != null) {
            trainer['characterId'] = legacyCharacterId;
          }
        }
        return trainer;
      }).toList(growable: false);
    }
    return next;
  }

  next['pathPresets'] = pathPresets.map((entry) {
    if (entry is! Map) {
      return entry;
    }
    final preset = Map<String, dynamic>.from(entry.cast<String, dynamic>());
    if (!preset.containsKey('surfaceKind')) {
      preset['surfaceKind'] = _legacyPathSurfaceKindValue(
        preset['groundTerrainType']?.toString(),
      );
    }
    return preset;
  }).toList(growable: false);

  final trainers = raw['trainers'];
  if (trainers is List) {
    next['trainers'] = trainers.map((entry) {
      if (entry is! Map) {
        return entry;
      }
      final trainer = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      if (!trainer.containsKey('characterId')) {
        final legacyCharacterId = trainer['overworldCharacterId'] ??
            trainer['spriteCharacterId'] ??
            trainer['characterRef'];
        if (legacyCharacterId != null) {
          trainer['characterId'] = legacyCharacterId;
        }
      }
      return trainer;
    }).toList(growable: false);
  }

  return next;
}

String _legacyPathSurfaceKindValue(String? legacyValue) {
  return switch (legacyValue) {
    'water' => 'water',
    'ice' => 'ice',
    'lava' => 'lava',
    'mud' => 'swamp',
    'tallGrass' => 'tall_grass',
    'road' => 'road',
    'rails' => 'rails',
    'bridge' => 'bridge',
    'custom' => 'custom',
    _ => 'path',
  };
}

Map<String, dynamic> migrateMapDataJson(Map<String, dynamic> raw) {
  final next = Map<String, dynamic>.from(raw);
  final entities = raw['entities'];
  if (entities is List) {
    next['entities'] = entities.map((entry) {
      if (entry is! Map) {
        return entry;
      }
      final entity = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      final rawKind = entity['kind']?.toString();
      final rawType = entity['type']?.toString();
      entity['kind'] = _legacyEntityKindValue(rawKind ?? rawType);
      entity.remove('type');
      entity['name'] = (entity['name'] ?? entity['id'] ?? '').toString();

      if (!entity.containsKey('size')) {
        entity['size'] = <String, dynamic>{
          'width': 1,
          'height': 1,
        };
      }

      final rawProperties = entity['properties'];
      if (rawProperties is Map) {
        entity['properties'] = {
          for (final property in rawProperties.entries)
            property.key.toString(): property.value?.toString() ?? '',
        };
      } else {
        entity['properties'] = <String, String>{};
      }

      return entity;
    }).toList(growable: false);
  }

  final triggers = raw['triggers'];
  if (triggers is List) {
    next['triggers'] = triggers.map((entry) {
      if (entry is! Map) {
        return entry;
      }
      final trigger = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      if (!trigger.containsKey('area') && trigger['zone'] is Map) {
        trigger['area'] = Map<String, dynamic>.from(
            (trigger['zone'] as Map).cast<String, dynamic>());
      }
      trigger['name'] = (trigger['name'] ?? trigger['id'] ?? '').toString();

      final rawType = trigger['type']?.toString();
      trigger['type'] = switch (rawType) {
        'script' => 'event',
        'cutscene' => 'event',
        'battle' => 'event',
        'sound' => 'interaction',
        'warp' => 'warp',
        'message' => 'message',
        'interaction' => 'interaction',
        'event' => 'event',
        'spawn' => 'spawn',
        'camera' => 'camera',
        'custom' => 'custom',
        _ => 'event',
      };

      final rawProperties = trigger['properties'];
      if (rawProperties is Map) {
        trigger['properties'] = {
          for (final entry in rawProperties.entries)
            entry.key.toString(): entry.value?.toString() ?? '',
        };
      } else {
        trigger['properties'] = <String, String>{};
      }
      return trigger;
    }).toList(growable: false);
  }

  final md = next['mapMetadata'];
  if (md == null || md is! Map) {
    next['mapMetadata'] = <String, dynamic>{};
  }
  if (!next.containsKey('placedElements') || next['placedElements'] == null) {
    next['placedElements'] = <dynamic>[];
  }

  return next;
}

String _legacyEntityKindValue(String? legacyValue) {
  return switch (legacyValue) {
    'npc' => 'npc',
    'monster' => 'npc',
    'sign' => 'sign',
    'chest' => 'item',
    'item' => 'item',
    'spawn' => 'spawn',
    'custom' => 'custom',
    _ => 'custom',
  };
}

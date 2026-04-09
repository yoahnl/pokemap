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
  if (!next.containsKey('pokemon')) {
    next['pokemon'] = <String, dynamic>{};
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
    _migrateElementCollisionProfiles(next);
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

  _migrateElementCollisionProfiles(next);

  return next;
}

void _migrateElementCollisionProfiles(Map<String, dynamic> manifest) {
  // Collision profile compatibility:
  //
  // Older editor builds could save a "manual" building silhouette in a broken
  // shape:
  // - `source == manual`
  // - `padding == 0`
  // - `cells == full padding-derived rectangle`
  // - `manualAddedCells == intended building silhouette`
  //
  // The modern editor preview can reinterpret that payload in memory, but the
  // runtime only reads `collisionProfile.cells`. If we do not normalize the
  // manifest at load time, the runtime keeps blocking the full sprite bounds.
  //
  // We therefore repair only the proven legacy pattern here, at manifest-load
  // time, so editor, save/reload, and runtime all agree on the same final
  // `cells` without introducing a new runtime contract.
  final rawElements = manifest['elements'];
  if (rawElements is! List) {
    return;
  }

  final settings = manifest['settings'];
  final tileWidth =
      settings is Map ? (_asInt(settings['tileWidth']) ?? 16) : 16;
  final tileHeight =
      settings is Map ? (_asInt(settings['tileHeight']) ?? 16) : 16;

  manifest['elements'] = rawElements.map((entry) {
    if (entry is! Map) {
      return entry;
    }
    final element = Map<String, dynamic>.from(entry.cast<String, dynamic>());
    final rawProfile = element['collisionProfile'];
    if (rawProfile is! Map) {
      return element;
    }

    final sourceSize = _readElementSourceSize(element);
    if (sourceSize == null) {
      return element;
    }

    element['collisionProfile'] = _migrateCollisionProfileJson(
      rawProfile.cast<String, dynamic>(),
      sourceWidth: sourceSize.$1,
      sourceHeight: sourceSize.$2,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    return element;
  }).toList(growable: false);
}

Map<String, dynamic> _migrateCollisionProfileJson(
  Map<String, dynamic> rawProfile, {
  required int sourceWidth,
  required int sourceHeight,
  required int tileWidth,
  required int tileHeight,
}) {
  final profile = Map<String, dynamic>.from(rawProfile);
  final sourceMode = profile['source']?.toString() ?? 'generated';
  final padding = _readPadding(profile['padding']);
  final currentCells = _normalizeCells(
    profile['cells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final shapeCells = _normalizeCells(
    profile['shapeCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final manualAddedCells = _normalizeCells(
    profile['manualAddedCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final manualRemovedCells = _normalizeCells(
    profile['manualRemovedCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final paddingBaseCells = _deriveBaseCellsFromPadding(
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    padding: padding,
  );

  if (sourceMode == 'manual') {
    // Legacy broken payload:
    // `cells` persisted the full padding-derived base while the intended house
    // silhouette lived only in `manualAddedCells`. This is the exact failure
    // mode observed on the real `petite_maison_toit_bleu` project file.
    if (shapeCells.isEmpty &&
        manualAddedCells.isNotEmpty &&
        manualRemovedCells.isEmpty &&
        _sameCells(currentCells, paddingBaseCells)) {
      profile['shapeCells'] = _toJsonCells(manualAddedCells);
      profile['manualAddedCells'] = const <Map<String, dynamic>>[];
      profile['manualRemovedCells'] = const <Map<String, dynamic>>[];
      profile['cells'] = _toJsonCells(manualAddedCells);
      return profile;
    }

    // Older manual profiles may have stored the intended authored silhouette
    // directly in `cells` without `shapeCells`. Preserve that intent so future
    // saves stop bouncing back to a generated rectangle.
    if (shapeCells.isEmpty &&
        manualAddedCells.isEmpty &&
        manualRemovedCells.isEmpty &&
        currentCells.isNotEmpty &&
        !_sameCells(currentCells, paddingBaseCells)) {
      profile['shapeCells'] = _toJsonCells(currentCells);
      profile['cells'] = _toJsonCells(currentCells);
      return profile;
    }

    if (shapeCells.isNotEmpty) {
      final finalCells = _applyOverlay(
        baseCells: shapeCells,
        manualAddedCells: manualAddedCells,
        manualRemovedCells: manualRemovedCells,
      );
      profile['shapeCells'] = _toJsonCells(shapeCells);
      profile['manualAddedCells'] = _toJsonCells(manualAddedCells);
      profile['manualRemovedCells'] = _toJsonCells(manualRemovedCells);
      profile['cells'] = _toJsonCells(finalCells);
      return profile;
    }
  }

  // For generated profiles, keep the modern contract deterministic: `cells`
  // should reflect the padding base plus explicit overrides. This keeps runtime
  // truth aligned with the data the editor will display after reload.
  final generatedFinalCells = _applyOverlay(
    baseCells: paddingBaseCells,
    manualAddedCells: manualAddedCells,
    manualRemovedCells: manualRemovedCells,
  );
  profile['shapeCells'] = _toJsonCells(shapeCells);
  profile['manualAddedCells'] = _toJsonCells(manualAddedCells);
  profile['manualRemovedCells'] = _toJsonCells(manualRemovedCells);
  profile['cells'] = _toJsonCells(generatedFinalCells);
  return profile;
}

({int top, int right, int bottom, int left}) _readPadding(Object? rawPadding) {
  if (rawPadding is! Map) {
    return (top: 0, right: 0, bottom: 0, left: 0);
  }
  return (
    top: _asInt(rawPadding['top']) ?? 0,
    right: _asInt(rawPadding['right']) ?? 0,
    bottom: _asInt(rawPadding['bottom']) ?? 0,
    left: _asInt(rawPadding['left']) ?? 0,
  );
}

(int, int)? _readElementSourceSize(Map<String, dynamic> element) {
  final frames = element['frames'];
  if (frames is List && frames.isNotEmpty) {
    final first = frames.first;
    if (first is Map) {
      final source = first['source'];
      if (source is Map) {
        final width = _asInt(source['width']);
        final height = _asInt(source['height']);
        if (width != null && height != null && width > 0 && height > 0) {
          return (width, height);
        }
      }
    }
  }

  final legacySource = element['source'];
  if (legacySource is Map) {
    final width = _asInt(legacySource['width']);
    final height = _asInt(legacySource['height']);
    if (width != null && height != null && width > 0 && height > 0) {
      return (width, height);
    }
  }
  return null;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

List<Map<String, dynamic>> _toJsonCells(List<(int, int)> cells) {
  return cells
      .map((cell) => <String, dynamic>{'x': cell.$1, 'y': cell.$2})
      .toList(growable: false);
}

List<(int, int)> _normalizeCells(
  Object? rawCells, {
  required int sourceWidth,
  required int sourceHeight,
}) {
  if (rawCells is! List) {
    return const <(int, int)>[];
  }
  final unique = <String, (int, int)>{};
  for (final cell in rawCells) {
    if (cell is! Map) {
      continue;
    }
    final x = _asInt(cell['x']);
    final y = _asInt(cell['y']);
    if (x == null || y == null) {
      continue;
    }
    if (x < 0 || y < 0 || x >= sourceWidth || y >= sourceHeight) {
      continue;
    }
    unique['$x:$y'] = (x, y);
  }
  final out = unique.values.toList(growable: false);
  out.sort(_compareCells);
  return out;
}

List<(int, int)> _deriveBaseCellsFromPadding({
  required int sourceWidth,
  required int sourceHeight,
  required int tileWidth,
  required int tileHeight,
  required ({int top, int right, int bottom, int left}) padding,
}) {
  if (sourceWidth <= 0 ||
      sourceHeight <= 0 ||
      tileWidth <= 0 ||
      tileHeight <= 0) {
    return const <(int, int)>[];
  }

  final sourcePixelWidth = sourceWidth * tileWidth;
  final sourcePixelHeight = sourceHeight * tileHeight;
  final trimmedLeft = padding.left.clamp(0, sourcePixelWidth);
  final trimmedTop = padding.top.clamp(0, sourcePixelHeight);
  final trimmedRight =
      (sourcePixelWidth - padding.right.clamp(0, sourcePixelWidth))
          .clamp(trimmedLeft, sourcePixelWidth);
  final trimmedBottom =
      (sourcePixelHeight - padding.bottom.clamp(0, sourcePixelHeight))
          .clamp(trimmedTop, sourcePixelHeight);

  if (trimmedRight <= trimmedLeft || trimmedBottom <= trimmedTop) {
    return const <(int, int)>[];
  }

  final out = <(int, int)>[];
  for (var y = 0; y < sourceHeight; y++) {
    final cellTop = y * tileHeight;
    final cellBottom = cellTop + tileHeight;
    final overlapsY = cellBottom > trimmedTop && cellTop < trimmedBottom;
    if (!overlapsY) {
      continue;
    }
    for (var x = 0; x < sourceWidth; x++) {
      final cellLeft = x * tileWidth;
      final cellRight = cellLeft + tileWidth;
      final overlapsX = cellRight > trimmedLeft && cellLeft < trimmedRight;
      if (!overlapsX) {
        continue;
      }
      out.add((x, y));
    }
  }
  return out;
}

List<(int, int)> _applyOverlay({
  required List<(int, int)> baseCells,
  required List<(int, int)> manualAddedCells,
  required List<(int, int)> manualRemovedCells,
}) {
  final merged = <String, (int, int)>{
    for (final cell in baseCells) '${cell.$1}:${cell.$2}': cell,
  };
  for (final cell in manualAddedCells) {
    merged['${cell.$1}:${cell.$2}'] = cell;
  }
  for (final cell in manualRemovedCells) {
    merged.remove('${cell.$1}:${cell.$2}');
  }
  final out = merged.values.toList(growable: false);
  out.sort(_compareCells);
  return out;
}

bool _sameCells(List<(int, int)> a, List<(int, int)> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

int _compareCells((int, int) a, (int, int) b) {
  final yCompare = a.$2.compareTo(b.$2);
  if (yCompare != 0) {
    return yCompare;
  }
  return a.$1.compareTo(b.$1);
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

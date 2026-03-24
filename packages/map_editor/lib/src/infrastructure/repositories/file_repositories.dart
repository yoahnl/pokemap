import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';

class FileProjectRepository implements ProjectRepository {
  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    debugPrint('FileProjectRepository: Validating and saving project to $path');
    ProjectValidator.validate(project);
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = project.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<ProjectManifest> loadProject(String path) async {
    debugPrint('FileProjectRepository: Loading project from $path');
    final file = File(path);
    if (!await file.exists()) {
      throw const ProjectLoadException('Project file not found');
    }
    final content = await file.readAsString();
    try {
      final json = _migrateLegacyProjectJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
      final manifest = ProjectManifest.fromJson(json);
      ProjectValidator.validate(manifest);
      return manifest;
    } catch (e) {
      throw ProjectLoadException('Failed to load project: $e');
    }
  }
}

Map<String, dynamic> _migrateLegacyProjectJson(Map<String, dynamic> raw) {
  final next = Map<String, dynamic>.from(raw);
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

class FileMapRepository implements MapRepository {
  @override
  Future<void> saveMap(MapData map, String path) async {
    debugPrint('FileMapRepository: Validating and saving map to $path');
    MapValidator.validate(map);
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = map.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<MapData> loadMap(String path) async {
    debugPrint('FileMapRepository: Loading map from $path');
    final file = File(path);
    if (!await file.exists()) {
      throw MapLoadException('Map file not found: $path');
    }
    final content = await file.readAsString();
    try {
      final json = _migrateLegacyMapJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
      final map = MapData.fromJson(json);
      MapValidator.validate(map);
      return map;
    } catch (e) {
      throw MapLoadException('Failed to load map: $e');
    }
  }

  @override
  Future<void> deleteMap(String path) async {
    debugPrint('FileMapRepository: Deleting map at $path');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {
    debugPrint('FileMapRepository: Renaming map from $oldPath to $newPath');
    final file = File(oldPath);
    if (await file.exists()) {
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.rename(newPath);
    }
  }
}

Map<String, dynamic> _migrateLegacyMapJson(Map<String, dynamic> raw) {
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

class FileTilesetRepository implements TilesetRepository {
  @override
  Future<void> saveTileset(TilesetConfig tileset, String path) async {
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = tileset.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<TilesetConfig> loadTileset(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const AssetNotFoundException('Tileset file not found');
    }
    final content = await file.readAsString();
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return TilesetConfig.fromJson(json);
    } catch (e) {
      throw const ValidationException('Failed to load tileset');
    }
  }
}

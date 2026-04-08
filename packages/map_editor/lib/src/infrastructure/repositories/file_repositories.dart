import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/pokemon_read_repository.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_project_data_reader.dart';
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
      final json = migrateProjectManifestJson(
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

class FileMapRepository implements MapRepository {
  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    debugPrint('FileMapRepository: Validating and saving map to $path');
    MapValidator.validate(
      map,
      projectDialogueContext: projectDialogueContext,
    );
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
      final json = migrateMapDataJson(
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

/// Implémentation filesystem/workspace de la lecture locale Pokémon.
///
/// Cette classe sert de frontière infrastructurelle pour les use cases :
/// la mécanique JSON concrète reste déléguée au lecteur local existant.
class FilePokemonReadRepository implements PokemonReadRepository {
  const FilePokemonReadRepository({
    this.reader = const PokemonProjectDataReader(),
  });

  final PokemonProjectDataReader reader;

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    return reader.readManifest(workspace);
  }

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) {
    return reader.readCatalogByKey(workspace, catalogKey);
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    return reader.listSpeciesIndexEntries(workspace);
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readSpeciesById(workspace, speciesId);
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readLearnsetById(workspace, speciesId);
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readEvolutionById(workspace, speciesId);
  }
}

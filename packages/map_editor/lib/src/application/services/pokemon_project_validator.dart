import 'dart:convert';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../models/pokemon_validation_report.dart';
import '../ports/project_workspace.dart';

class PokemonProjectValidator {
  const PokemonProjectValidator({
    this.reader = const LocalProjectFileReader(),
    this.loader = const PokemonCatalogCoherenceLoader(),
  });

  final ProjectFileReader reader;
  final PokemonCatalogCoherenceLoader loader;

  Future<PokemonValidationReport> validate(ProjectWorkspace workspace) async {
    final projectRoot = await reader.canonicalizeDirectory(
      workspace.projectRoot,
    );
    final manifest = await _readManifest(projectRoot);
    return loader.validateProjectFiles(
      reader: reader,
      projectRoot: projectRoot,
      manifest: manifest,
    );
  }

  Future<ProjectManifest> _readManifest(String projectRoot) async {
    try {
      final bytes = await reader.readBytes(
        projectRoot: projectRoot,
        relativePath: 'project.json',
      );
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        throw const FormatException('Expected a JSON object.');
      }
      return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded));
    } on Object catch (error) {
      throw EditorPersistenceException(
        'Project manifest is invalid at $projectRoot/project.json: $error',
      );
    }
  }
}

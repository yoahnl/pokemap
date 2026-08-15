import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'game_package_format_exception.dart';
import 'game_package_manifest.dart';
import 'game_package_security_policy.dart';

/// Performs the pure project preflight available before staging/smoke.
final class GamePackageProjectValidator {
  const GamePackageProjectValidator(this.policy);

  final GamePackageSecurityPolicy policy;

  ProjectManifest validate(
    GamePackageManifest packageManifest,
    Uint8List projectBytes, {
    required Set<String> payloadPaths,
  }) {
    try {
      final decoded = jsonDecode(
        utf8.decode(projectBytes, allowMalformed: false),
      );
      if (decoded is! Map<String, dynamic>) {
        _fail('Project manifest must be a JSON object.');
      }
      _validateComplexity(decoded);
      final project = ProjectManifest.fromJson(decoded);
      ProjectValidator.validate(project);
      if (project.version.name != packageManifest.compatibility.projectFormat) {
        throw GamePackageFormatException(
          code: 'projectFormatMismatch',
          path: r'$.compatibility.projectFormat',
          message: 'Package and project formats do not match.',
        );
      }
      final referencedPaths = <String>[
        ...project.maps.map((entry) => entry.relativePath),
        ...project.tilesets.map((entry) => entry.relativePath),
        ...project.dialogues.map((entry) => entry.relativePath),
        ...project.cinematicMediaAssets.map((entry) => entry.relativePath),
      ];
      for (final relativePath in referencedPaths) {
        final packagePath = 'project/${relativePath.replaceAll(r'\', '/')}';
        if (!payloadPaths.contains(packagePath)) {
          throw GamePackageFormatException(
            code: 'missingFile',
            path: packagePath,
            message: 'Project manifest references a missing package file.',
          );
        }
      }
      return project;
    } on GamePackageFormatException {
      rethrow;
    } on Object {
      _fail('Project manifest failed its pure validation preflight.');
    }
  }

  void _validateComplexity(Map<String, dynamic> json) {
    const collectionFields = <String>{
      'maps',
      'groups',
      'tilesetFolders',
      'tilesets',
      'elementCategories',
      'elements',
      'terrainCategories',
      'pathCategories',
      'terrainPresets',
      'pathPresets',
      'pathPatternPresets',
      'environmentPresets',
      'encounterTables',
      'dialogueFolders',
      'dialogues',
      'scripts',
      'scenarios',
      'cinematics',
      'cinematicMediaAssets',
      'facts',
      'worldRules',
      'scenes',
      'storylines',
      'shops',
      'badges',
      'trainers',
      'characters',
    };
    var totalEntries = 0;
    for (final field in collectionFields) {
      final value = json[field];
      if (value is List) totalEntries += value.length;
    }
    if (totalEntries > policy.maxProjectCollectionEntries) {
      _complexityFail('Project collection entry count exceeds policy.');
    }

    _validateHierarchyComplexity(
      json['groups'],
      parentField: 'parentGroupId',
    );
    _validateHierarchyComplexity(
      json['tilesetFolders'],
      parentField: 'parentFolderId',
    );
    _validateHierarchyComplexity(
      json['dialogueFolders'],
      parentField: 'parentFolderId',
    );
    _validateHierarchyComplexity(
      json['elementCategories'],
      parentField: 'parentCategoryId',
    );
    _validateHierarchyComplexity(
      json['terrainCategories'],
      parentField: 'parentCategoryId',
    );
    _validateHierarchyComplexity(
      json['pathCategories'],
      parentField: 'parentCategoryId',
    );
  }

  void _validateHierarchyComplexity(
    Object? value, {
    required String parentField,
  }) {
    if (value is! List) return;
    if (value.length > policy.maxProjectHierarchyEntries) {
      _complexityFail('Project hierarchy entry count exceeds policy.');
    }
    final parentById = <String, String?>{};
    for (final entry in value) {
      if (entry is Map && entry['id'] is String) {
        parentById[entry['id'] as String] = entry[parentField] as String?;
      }
    }
    for (final id in parentById.keys) {
      var current = id;
      final visited = <String>{};
      while (true) {
        if (!visited.add(current) ||
            visited.length > policy.maxProjectHierarchyDepth) {
          _complexityFail('Project group hierarchy exceeds policy.');
        }
        final parent = parentById[current];
        if (parent == null || !parentById.containsKey(parent)) break;
        current = parent;
      }
    }
  }

  Never _fail(String message) {
    throw GamePackageFormatException(
      code: 'invalidProject',
      path: 'project/project.json',
      message: message,
    );
  }

  Never _complexityFail(String message) {
    throw GamePackageFormatException(
      code: 'projectComplexityExceeded',
      path: 'project/project.json',
      message: message,
    );
  }
}

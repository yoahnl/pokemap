import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'game_package_format_exception.dart';
import 'game_package_manifest.dart';
import 'game_package_security_policy.dart';
import 'game_package_spatial_project_validator.dart';

/// Performs the pure project preflight available before staging/smoke.
final class GamePackageProjectValidator {
  const GamePackageProjectValidator(this.policy);

  final GamePackageSecurityPolicy policy;

  ProjectManifest validate(
    GamePackageManifest packageManifest,
    Uint8List projectBytes, {
    required Set<String> payloadPaths,
    GamePackagePayloadReader? readPayload,
  }) {
    try {
      final decoded = jsonDecode(
        utf8.decode(projectBytes, allowMalformed: false),
      );
      if (decoded is! Map<String, dynamic>) {
        _fail('Project manifest must be a JSON object.');
      }
      if (!packageManifest.compatibility.requiredCapabilities
          .contains('catalog.partitioned@2')) {
        _fail('Partitioned catalog capability is required.');
      }
      if (readPayload == null) _fail('Catalog object reader is required.');
      final consumed = <String>{};
      var catalogBytes = projectBytes.length;
      var catalogValues = _jsonValues(decoded);
      final project = PortableCatalogPublication.decodeProjectSync(decoded,
          limits: CatalogStorageLimits(maxStoredBytes: policy.maxCatalogBytes),
          readObject: (reference) {
        final path =
            'project/${PortableCatalogPublication.objectPath(reference)}';
        final bytes = readPayload(path);
        if (bytes == null) _fail('Missing catalog object.');
        if (consumed.add(path)) {
          catalogBytes += bytes.length;
          catalogValues += _jsonValues(jsonDecode(utf8.decode(bytes)));
          if (catalogBytes > policy.maxCatalogBytes ||
              catalogValues > policy.maxCatalogJsonValues) {
            _complexityFail('Partitioned catalog exceeds its global quota.');
          }
        }
        return bytes;
      });
      final objectPaths = payloadPaths
          .where((path) => path.startsWith('project/catalog/objects/'))
          .toSet();
      if (objectPaths.length != consumed.length ||
          !objectPaths.containsAll(consumed)) {
        _fail('Unreachable catalog objects are forbidden.');
      }
      _validateComplexity(project.toJson());
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
        ...project.models3d.map((entry) => entry.relativePath),
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
      final spatial = project.settings.dimension == ProjectDimension.threeD;
      final gameplay = packageManifest.compatibility.requiredCapabilities
          .contains(SpatialGameplayCapabilities.capabilityId);
      if (spatial !=
              packageManifest.compatibility.requiredCapabilities
                  .contains('map3d@1') ||
          gameplay && !spatial ||
          spatial &&
              packageManifest.compatibility.requiredCapabilities
                  .contains('map@1')) {
        _fail('Project dimension and map capability do not match.');
      }
      if (spatial) {
        GamePackageSpatialProjectValidator(policy: policy, gameplay: gameplay)
            .validate(project, readPayload);
        if (SpatialGameplayCapabilities.requiresStory(project) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialGameplayCapabilities.storyCapabilityId)) {
          _fail('3D story playback requires map3d.story@1.');
        }
        final maps = project.maps.map((entry) {
          final map = MapData.fromJson(jsonDecode(
                  utf8.decode(readPayload('project/${entry.relativePath}')!))
              as Map<String, dynamic>);
          return map;
        });
        if (SpatialGameplayCapabilities.requiresModelAnimation(project,
                maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains('map3d.animation@1')) {
          _fail('Animated 3D decor requires map3d.animation@1.');
        }
        if (SpatialModelClipCapabilities.requiresCapability(project,
                maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialModelClipCapabilities.capabilityId)) {
          _fail('Clipped 3D models require map3d.model-clip@1.');
        }
        if (maps.any((map) => !map.spatialScene!.generateCliffs) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains('map3d.terrain-appearance@1')) {
          _fail(
              'Custom 3D terrain appearance requires map3d.terrain-appearance@1.');
        }
        if (maps.any((map) =>
                map.spatialScene!.terrainSurfaces.surfaces.isNotEmpty) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialTerrainSurfaceSet.capabilityId)) {
          _fail('Continuous 3D terrain requires map3d.terrain-surfaces@1.');
        }
        if (maps.any((map) => map.spatialScene!.navigation.ramps
                .any((ramp) => ramp.hasFractionalLevels)) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialRamp.fractionalLevelsCapabilityId)) {
          _fail(
              'Fractional stair endpoints require ${SpatialRamp.fractionalLevelsCapabilityId}.');
        }
      }
      return project;
    } on GamePackageFormatException {
      rethrow;
    } on Object {
      _fail('Project manifest failed its pure validation preflight.');
    }
  }

  int _jsonValues(Object? value) {
    var count = 0;
    final pending = <Object?>[value];
    while (pending.isNotEmpty) {
      final item = pending.removeLast();
      count++;
      if (item is Map) pending.addAll(item.values);
      if (item is List) pending.addAll(item);
    }
    return count;
  }

  void _validateComplexity(Map<String, dynamic> json) {
    const collectionFields = <String>{
      'maps',
      'models3d',
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

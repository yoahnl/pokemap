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
      if (project.cinematics.any((cinematic) => cinematic.allowMobileActorCrossing) && !packageManifest.compatibility.requiredCapabilities.contains(CinematicAsset.mobileActorCrossingCapabilityId)) {
        _fail('Mobile actor crossings require the explicit cinematic capability.');
      }
      final objectPaths = payloadPaths
          .where((path) => path.startsWith('project/catalog/objects/'))
          .toSet();
      if (objectPaths.length != consumed.length ||
          !objectPaths.containsAll(consumed)) {
        _fail('Unreachable catalog objects are forbidden.');
      }
      _validateComplexity(project.toJson());
      ProjectValidator.validate(project);
      if (GameCompletionPartyCapabilities.requiresCapability(project) &&
          packageManifest.compatibility.saveFormat !=
              SaveEnvelopeCodec.currentSaveFormat) {
        throw GamePackageFormatException(
          code: 'completionPartySaveFormatUnsupported',
          path: r'$.compatibility.saveFormat',
          message: 'Party recording requires save format '
              '${SaveEnvelopeCodec.currentSaveFormat}.',
        );
      }
      if (GameCompletionPartyCapabilities.requiresCapability(project) &&
          !packageManifest.compatibility.requiredCapabilities
              .contains(GameCompletionPartyCapabilities.capabilityId)) {
        _fail('Party recording requires '
            '${GameCompletionPartyCapabilities.capabilityId}.');
      }
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
      final atmosphereMaps = {for (final entry in project.maps) 'project/${SpatialAtmosphereDocument.relativePathForMap(entry.id)}':entry.id};
      for (final path in payloadPaths.where((path) => path.endsWith('.atmosphere.json'))) {
        final mapId = atmosphereMaps[path];
        if (mapId == null) _fail('Atmosphere sidecar must belong to an existing map.');
        final bytes = readPayload(path);
        if (bytes == null || bytes.length > SpatialAtmosphereDocument.maxBytes) _fail('Atmosphere sidecar is missing or exceeds its byte limit.');
        final document = SpatialAtmosphereDocument.fromJson(Map<String,dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
        if (document.mapId != mapId) _fail('Atmosphere map identity mismatch.');
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
      final demonstrations = project.scenes.expand((scene) => scene.graph.nodes).where((node) =>
          node.payload is SceneBattlePayload && (node.payload as SceneBattlePayload).demonstration != null);
      if (demonstrations.isNotEmpty && (!spatial ||
          !packageManifest.compatibility.requiredCapabilities.contains(SceneBattleDemonstration.capabilityId))) {
        _fail('Battle demonstrations require a 3D project and battle.demonstration@1.');
      }
      for (final node in demonstrations) {
        final battle = node.payload as SceneBattlePayload;
        final guide = project.trainers.where((trainer) => trainer.id == battle.demonstration!.playerTrainerId).firstOrNull;
        if (battle.battleKind != 'wild' || guide == null || guide.team.isEmpty || guide.team.length > 6 ||
            guide.battleFormat != BattleFormat.singles || battle.defeatRecovery != SceneBattleDefeatRecovery.continueScene) {
          _fail('The battle demonstration requires an existing temporary singles team and wild encounter.');
        }
      }
      if (project.contactDevice case final device?) {
        if (!spatial) _fail('Contact devices require a 3D project.');
        if (!packageManifest.compatibility.requiredCapabilities.contains(ProjectContactDeviceConfig.capabilityId)) _fail('Contact devices require project.contact-device@1.');
        final errors = device.referenceErrors(facts: project.facts, sceneIds: project.scenes.map((scene) => scene.id).toSet(), characterIds: project.characters.map((character) => character.id).toSet());
        if (errors.isNotEmpty) _fail(errors.join('; '));
      }
      if (spatial) {
        if (SpatialGameplayCapabilities.requiresSceneMusic(project) && !packageManifest.compatibility.requiredCapabilities.contains(SpatialGameplayCapabilities.sceneMusicCapabilityId)) _fail('Spatial scene music requires map3d.scene-music@1.');
        if (SpatialGameplayCapabilities.requiresAudio(project) && !packageManifest.compatibility.requiredCapabilities.contains(SpatialGameplayCapabilities.audioCapabilityId)) _fail('Spatial scene audio requires map3d.scene-audio@1.');
        if (project.partyCompanion.enabled && !packageManifest.compatibility.requiredCapabilities
            .contains(SpatialGameplayCapabilities.companionCapabilityId)) {
          _fail('A 3D party companion requires ${SpatialGameplayCapabilities.companionCapabilityId}.');
        }
        GamePackageSpatialProjectValidator(policy: policy, gameplay: gameplay)
            .validate(project, readPayload, payloadPaths: payloadPaths);
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
        if (SpatialActorOcclusionCapabilities.requiresCapability(project, maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities.contains(SpatialActorOcclusionCapabilities.capabilityId)) {
          _fail('3D actor occlusion requires map3d.actor-occlusion@1.');
        }
        if (SpatialModelClipCapabilities.requiresCapability(project,
                maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialModelClipCapabilities.capabilityId)) {
          _fail('Clipped 3D models require map3d.model-clip@1.');
        }
        if (SpatialActorContactShadowCapabilities.requiresCapability(project) &&
            !packageManifest.compatibility.requiredCapabilities.contains(
                SpatialActorContactShadowCapabilities.capabilityId)) {
          _fail('3D actor contact shadows require map3d.actor-contact-shadows@1.');
        }
        if (SpatialModelShadowCapabilities.requiresCapability(project,
                maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialModelShadowCapabilities.capabilityId)) {
          _fail('Shadow-casting 3D models require map3d.shadows@1.');
        }
        if (SpatialSceneLightingCapabilities.requiresDayNight(project,
                maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialSceneLightingCapabilities.dayNightCapabilityId)) {
          _fail('Visual 3D day/night cycles require map3d.day-night@1.');
        }
        if (SpatialSceneLightingCapabilities.requiresPointLights(project,
                maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialSceneLightingCapabilities.pointLightCapabilityId)) {
          _fail('Illuminated 3D models require map3d.point-light@1.');
        }
        if (SpatialSceneLightingCapabilities.requiresPointLightShadows(project,
                maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities.contains(
                SpatialSceneLightingCapabilities.pointLightShadowsCapabilityId)) {
          _fail('Occluded 3D point lights require map3d.point-light-shadows@1.');
        }
        if (maps.any((map) => map.spatialScene?.camera.projection == SpatialCameraProjection.orthographic) && !packageManifest.compatibility.requiredCapabilities.contains(SpatialCameraProfile.orthographicCapabilityId)) _fail('Orthographic cameras require map3d.camera-orthographic@1.');
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
        if (maps.any((map) => map.spatialScene!.instances.any((instance) => instance.entityId != null)) &&
            !packageManifest.compatibility.requiredCapabilities.contains(SpatialModelInstance.entityBindingCapabilityId)) {
          _fail('Entity-linked 3D models require ${SpatialModelInstance.entityBindingCapabilityId}.');
        }
        if (maps.any((map) => map.spatialScene!.navigation.ledges.isNotEmpty) &&
            !packageManifest.compatibility.requiredCapabilities.contains(SpatialLedge.capabilityId)) {
          _fail('Directional ledges require ${SpatialLedge.capabilityId}.');
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

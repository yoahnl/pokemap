import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'game_package_format_exception.dart';
import 'game_package_manifest.dart';
import 'game_package_security_policy.dart';
import 'game_package_spatial_project_validator.dart';
import 'game_package_exterior_decoration_validator.dart';

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
      final visualPaths = <String, String?>{
        'project/${SpatialVisualDocument.projectRelativePath}': null,
        for (final entry in project.maps)
          'project/${SpatialVisualDocument.relativePathForMap(entry.id)}':
              entry.id,
      };
      var visualProfiles = false;
      var weather = SpatialWeatherCapabilities.requiresProject(project);
      var extendedWeather = SpatialWeatherCapabilities.requiresExtendedProject(project);
      var weatherSound = SpatialWeatherCapabilities.requiresSoundProject(project);
      var worldEnvironment = WorldEnvironmentCapabilities.requiresProject(project);
      var weatherEpisodes = WorldEnvironmentCapabilities.requiresEpisodesProject(project);
      var realWeather = WorldEnvironmentCapabilities.requiresRealProject(project);
      var lightWorkshop = SpatialLightWorkshopCapabilities.requiresProject(project);
      for (final entry in visualPaths.entries) {
        if (!payloadPaths.contains(entry.key)) continue;
        visualProfiles = true;
        final bytes = readPayload(entry.key);
        if (bytes == null || bytes.length > SpatialVisualDocument.maxBytes) {
          _fail('Invalid visual settings payload.');
        }
        final document = SpatialVisualDocument.fromJson(
            Map<String, dynamic>.from(
                decodeNarrativeEventJsonStrict(utf8.decode(bytes)) as Map));
        lightWorkshop |= document.profile.requiresLightWorkshop;
        weather |= document.profile.requiresWeather;
        extendedWeather |= document.profile.requiresExtendedWeather;
        weatherSound |= document.profile.requiresWeatherSound;
        worldEnvironment |= document.profile.requiresWorldEnvironment;
        weatherEpisodes |= document.profile.requiresWeatherEpisodes;
        realWeather |= document.profile.requiresRealWeather;
        if (document.mapId != entry.value) {
          _fail('Visual settings identity mismatch.');
        }
      }
      if ((visualProfiles ||
              project.worldRules.any((rule) =>
                  rule.effect.kind == WorldRuleEffectKind.atmosphere) ||
              project.cinematics.any((asset) => asset.timeline.steps.any(
                  (step) =>
                      step.kind == CinematicTimelineStepKind.atmosphere)) ||
              project.scenes.any((scene) => scene.graph.nodes.any((node) =>
                  node.payload is SceneActionPayload &&
                  (node.payload as SceneActionPayload).interactiveCommand
                      is SceneWorldPresentationInteractiveCommand &&
                  const {
                    SceneWorldPresentationOperation.atmosphere,
                    SceneWorldPresentationOperation.restoreAtmosphere
                  }.contains(
                      ((node.payload as SceneActionPayload).interactiveCommand
                              as SceneWorldPresentationInteractiveCommand)
                          .operation)))) &&
          !packageManifest.compatibility.requiredCapabilities
              .contains(SpatialVisualDocument.capabilityId)) {
        _fail('Visual profiles require map3d.visual-profile@1.');
      }
      _validateComplexity(project.toJson());
      ProjectValidator.validate(project);
      final exterior = const GamePackageExteriorDecorationValidator().validate(
        project: project,
        payloadPaths: payloadPaths,
        readPayload: readPayload,
        requiredCapabilities: packageManifest.compatibility.requiredCapabilities,
      );
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
        final document = SpatialAtmosphereDocument.fromJson(Map<String,dynamic>.from(decodeNarrativeEventJsonStrict(utf8.decode(bytes)) as Map));
        lightWorkshop |= document.settings.hasFireflyStyle;
        weather |= document.settings.weather.hasSettings;
        extendedWeather |= document.settings.weather.kind.isExtended;
        weatherSound |= document.settings.weather.hasSoundSettings;
        if (document.mapId != mapId) _fail('Atmosphere map identity mismatch.');
      }
      if (lightWorkshop && !packageManifest.compatibility.requiredCapabilities.contains(SpatialLightWorkshopCapabilities.capabilityId)) {
        _fail('Extended lights require map3d.light-workshop@1.');
      }
      if (weather && !packageManifest.compatibility.requiredCapabilities.contains(SpatialWeatherCapabilities.capabilityId)) {
        _fail('Weather requires map3d.weather@1.');
      }
      if (extendedWeather && !packageManifest.compatibility.requiredCapabilities.contains(SpatialWeatherCapabilities.extendedCapabilityId)) {
        _fail('Extended weather requires map3d.weather-states@1.');
      }
      if (weatherSound && !packageManifest.compatibility.requiredCapabilities.contains(SpatialWeatherCapabilities.soundCapabilityId)) {
        _fail('Weather audio requires map3d.weather-audio@1.');
      }
      if (worldEnvironment && !packageManifest.compatibility.requiredCapabilities.contains(WorldEnvironmentCapabilities.capabilityId)) {
        _fail('World environment requires map3d.world-environment@1.');
      }
      if (weatherEpisodes && !packageManifest.compatibility.requiredCapabilities.contains(WorldEnvironmentCapabilities.weatherEpisodesCapabilityId)) {
        _fail('Occasional weather requires map3d.weather-episodes@1.');
      }
      if (realWeather && !packageManifest.compatibility.requiredCapabilities.contains(WorldEnvironmentCapabilities.realWeatherCapabilityId)) {
        _fail('Real weather requires map3d.real-weather@1.');
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
      if (project.battleSavings != null &&
          !packageManifest.compatibility.requiredCapabilities
              .contains(ProjectBattleSavingsConfig.capabilityId)) {
        _fail('Battle savings require ${ProjectBattleSavingsConfig.capabilityId}.');
      }
      if (SpatialGameplayCapabilities.requiresEggGift(project) && !packageManifest.compatibility.requiredCapabilities.contains(SpatialGameplayCapabilities.eggGiftCapabilityId)) {
        _fail('Egg gifts require gameplay.egg-gift@1.');
      }
      if (SpatialGameplayCapabilities.requiresNpcTrade(project) && !packageManifest.compatibility.requiredCapabilities.contains(SpatialGameplayCapabilities.npcTradeCapabilityId)) {
        _fail('NPC trade offers require gameplay.npc-trade@1.');
      }
      if (project.contactDevice case final device?) {
        if (!spatial) _fail('Contact devices require a 3D project.');
        if (!packageManifest.compatibility.requiredCapabilities.contains(ProjectContactDeviceConfig.capabilityId)) _fail('Contact devices require project.contact-device@1.');
        final errors = device.referenceErrors(facts: project.facts, sceneIds: project.scenes.map((scene) => scene.id).toSet(), characterIds: project.characters.map((character) => character.id).toSet());
        if (errors.isNotEmpty) _fail(errors.join('; '));
      }
      if (spatial) {
        if (SpatialGameplayCapabilities.requiresCinematicFade(project) &&
            !packageManifest.compatibility.requiredCapabilities.contains(
                SpatialGameplayCapabilities.cinematicFadeCapabilityId)) {
          _fail('Spatial cinematic fades require map3d.cinematic-fade@1.');
        }
        if (SpatialGameplayCapabilities.requiresSceneMusic(project) && !packageManifest.compatibility.requiredCapabilities.contains(SpatialGameplayCapabilities.sceneMusicCapabilityId)) _fail('Spatial scene music requires map3d.scene-music@1.');
        if (SpatialGameplayCapabilities.requiresAudio(project) && !packageManifest.compatibility.requiredCapabilities.contains(SpatialGameplayCapabilities.audioCapabilityId)) _fail('Spatial scene audio requires map3d.scene-audio@1.');
        if (project.partyCompanion.enabled && !packageManifest.compatibility.requiredCapabilities
            .contains(SpatialGameplayCapabilities.companionCapabilityId)) {
          _fail('A 3D party companion requires ${SpatialGameplayCapabilities.companionCapabilityId}.');
        }
        GamePackageSpatialProjectValidator(policy: policy, gameplay: gameplay,
          trainerSpotting: packageManifest.compatibility.requiredCapabilities
            .contains(SpatialGameplayCapabilities.trainerSpottingCapabilityId))
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
        }).toList()..addAll(exterior.visualMaps);
        if (SpatialGameplayCapabilities.requiresLadders(maps) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialGameplayCapabilities.ladderCapabilityId)) {
          _fail('Spatial ladders require map3d.ladder@1.');
        }
        if (SpatialGameplayCapabilities.requiresLifts(maps) && !packageManifest.compatibility.requiredCapabilities.contains(SpatialGameplayCapabilities.liftCapabilityId)) _fail('Spatial lifts require map3d.lift@1.');
        final hasModelShadows = exterior.modelShadows || SpatialModelShadowCapabilities.requiresCapability(project, maps: maps);
        final hasPointLights = exterior.pointLights || SpatialSceneLightingCapabilities.requiresPointLights(project, maps: maps);
        if (SpatialGameplayCapabilities.requiresConnectedCinematics(project,
                maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities.contains(
                SpatialGameplayCapabilities.cinematicConnectedCapabilityId)) {
          _fail('Connected spatial cinematics require map3d.cinematic-connected@1.');
        }
        if ((exterior.animatedModels || SpatialGameplayCapabilities.requiresModelAnimation(project,
                maps: maps)) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains('map3d.animation@1')) {
          _fail('Animated 3D decor requires map3d.animation@1.');
        }
        if (SpatialActorOcclusionCapabilities.requiresCapability(project, maps: maps) &&
            !packageManifest.compatibility.requiredCapabilities.contains(SpatialActorOcclusionCapabilities.capabilityId)) {
          _fail('3D actor occlusion requires map3d.actor-occlusion@1.');
        }
        if ((exterior.modelClips || SpatialModelClipCapabilities.requiresCapability(project,
                maps: maps)) &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialModelClipCapabilities.capabilityId)) {
          _fail('Clipped 3D models require map3d.model-clip@1.');
        }
        if (SpatialActorContactShadowCapabilities.requiresCapability(project) &&
            !packageManifest.compatibility.requiredCapabilities.contains(
                SpatialActorContactShadowCapabilities.capabilityId)) {
          _fail('3D actor contact shadows require map3d.actor-contact-shadows@1.');
        }
        if (hasModelShadows &&
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
        if (hasPointLights &&
            !packageManifest.compatibility.requiredCapabilities
                .contains(SpatialSceneLightingCapabilities.pointLightCapabilityId)) {
          _fail('Illuminated 3D models require map3d.point-light@1.');
        }
        if (hasPointLights && hasModelShadows &&
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

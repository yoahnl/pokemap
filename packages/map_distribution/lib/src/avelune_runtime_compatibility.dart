import 'package:map_core/map_core.dart';
import 'game_package_compatibility.dart';
import 'package:pub_semver/pub_semver.dart';

abstract final class AveluneRuntimeCompatibility {
  static const studioBaseline = '0.3.31+331';
  static const runtimeApiExpression = '>=1.0.0 <2.0.0';
  static const minimumHubVersion = '0.1.0';

  static GamePackageHostCompatibility host() => GamePackageHostCompatibility(
        hubVersion: Version.parse(minimumHubVersion),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const <String>{
          GameCompletionPartyCapabilities.capabilityId,
          'catalog.partitioned@2',
          'dialogue.choices@1',
          'map@1',
          'map3d@1',
          MapExteriorDecoration.capabilityId,
          'map3d.animation@1',
          SpatialModelShadowCapabilities.capabilityId,
          SpatialActorContactShadowCapabilities.capabilityId,
          SpatialActorOcclusionCapabilities.capabilityId,
          SpatialSceneLightingCapabilities.dayNightCapabilityId,
          SpatialSceneLightingCapabilities.pointLightCapabilityId,
          SpatialSceneLightingCapabilities.pointLightShadowsCapabilityId,
          SpatialModelClipCapabilities.capabilityId,
          'map3d.terrain-appearance@1',
          SpatialTerrainSurfaceSet.capabilityId,
          SpatialRamp.fractionalLevelsCapabilityId,
          SpatialLedge.capabilityId,
          SpatialModelInstance.entityBindingCapabilityId,
          SpatialGameplayCapabilities.capabilityId,
          SpatialGameplayCapabilities.storyCapabilityId,
          SpatialGameplayCapabilities.companionCapabilityId,
          SpatialCameraProfile.orthographicCapabilityId,
          SpatialVisualDocument.capabilityId,
          SpatialLightWorkshopCapabilities.capabilityId,
          SpatialLightWorkshopCapabilities.flameCapabilityId,
          SpatialLightWorkshopCapabilities.crackleCapabilityId,
          SpatialWeatherCapabilities.capabilityId,
          SpatialWeatherCapabilities.extendedCapabilityId,
          SpatialWeatherCapabilities.soundCapabilityId,
          WorldEnvironmentCapabilities.capabilityId,
          WorldEnvironmentCapabilities.realWeatherCapabilityId,
          WorldEnvironmentCapabilities.weatherEpisodesCapabilityId,
          ProjectContactDeviceConfig.capabilityId,
          ProjectBattleSavingsConfig.capabilityId,
          SurfGameplayCapabilities.capabilityId,
          FieldAbilityActivationCapabilities.capabilityId,
          ProjectAudioCapabilities.capabilityId,
          SpatialGameplayCapabilities.audioCapabilityId,
          SpatialGameplayCapabilities.sceneMusicCapabilityId,
          SpatialGameplayCapabilities.npcTradeCapabilityId,
          SpatialGameplayCapabilities.eggGiftCapabilityId,
          SpatialGameplayCapabilities.liftCapabilityId,
          SpatialGameplayCapabilities.ladderCapabilityId,
          SpatialGameplayCapabilities.cinematicFadeCapabilityId,
          SpatialGameplayCapabilities.cinematicConnectedCapabilityId,
          SpatialGameplayCapabilities.trainerSpottingCapabilityId,
          SceneBattleDemonstration.capabilityId,
          CinematicAsset.mobileActorCrossingCapabilityId,
          'overworld.menu@1',
          'world.shop@1',
        },
        supportedProjectFormats: <String>{
          ProjectVersion.v8.name,
          ProjectVersion.v9.name,
        },
        currentProjectFormat: ProjectVersion.v8.name,
        currentProjectFormats: <String>{
          ProjectVersion.v8.name,
          ProjectVersion.v9.name,
        },
        supportedSaveFormats: const <int>{SaveEnvelopeCodec.currentSaveFormat},
      );
}

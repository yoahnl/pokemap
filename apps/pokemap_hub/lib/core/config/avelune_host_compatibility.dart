import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';

GamePackageHostCompatibility aveluneHostCompatibility() =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('0.1.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const <String>{
        GameCompletionPartyCapabilities.capabilityId,
        'catalog.partitioned@2',
        'dialogue.choices@1',
        'map@1',
        'map3d@1',
        'map3d.animation@1',
        SpatialModelClipCapabilities.capabilityId,
        'map3d.terrain-appearance@1',
        SpatialTerrainSurfaceSet.capabilityId,
        SpatialRamp.fractionalLevelsCapabilityId,
        SpatialGameplayCapabilities.capabilityId,
        SpatialGameplayCapabilities.storyCapabilityId,
        SpatialGameplayCapabilities.companionCapabilityId,
          SpatialCameraProfile.orthographicCapabilityId,
          ProjectContactDeviceConfig.capabilityId,
          SpatialGameplayCapabilities.audioCapabilityId,
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

import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'support/spatial_feature_capabilities_fixture.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test('local cinematic in connected maps keeps its previous requirements', () {
    final files = spatialFeaturePayload('cinematicConnected');
    final json = jsonDecode(utf8.decode(files['project/project.json']!)) as Map<String, dynamic>;
    json['cinematics'][0]['stageContext']['stagePoints'][0]['x'] = 4.5;
    files['project/project.json'] = utf8.encode(jsonEncode(json));
    final built = const GamePackageBuilder().build(
        manifest: spatialManifest(capabilities: ['map3d@1', 'map3d.gameplay@1']),
        payloadFiles: files);
    expect(const GamePackageInspector().inspect(built.packageBytes).manifest
        .compatibility.requiredCapabilities, isNot(contains('map3d.cinematic-connected@1')));
  });

  final features = {
    'ladder': SpatialGameplayCapabilities.ladderCapabilityId,
    'cinematicConnected': 'map3d.cinematic-connected@1',
    'camera': SpatialCameraProfile.orthographicCapabilityId,
    'companion': SpatialGameplayCapabilities.companionCapabilityId,
    'contact': ProjectContactDeviceConfig.capabilityId,
    'audio': SpatialGameplayCapabilities.audioCapabilityId,
    'sceneMusic': SpatialGameplayCapabilities.sceneMusicCapabilityId,
    'npcTrade': SpatialGameplayCapabilities.npcTradeCapabilityId,
    'actorOcclusion': SpatialActorOcclusionCapabilities.capabilityId,
    'cinematicFade': SpatialGameplayCapabilities.cinematicFadeCapabilityId,
  };
  for (final entry in features.entries) {
    final base = ['map3d@1', if (entry.key != 'camera') 'map3d.gameplay@1'];
    test('${entry.key} requires its capability and rejects an older host', () {
      final files = spatialFeaturePayload(entry.key);
      expect(
          () => const GamePackageBuilder().build(
              manifest: spatialManifest(capabilities: base),
              payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.message, 'message', contains(entry.value))));
      final built = const GamePackageBuilder().build(
          manifest: spatialManifest(capabilities: [...base, entry.value]),
          payloadFiles: files);
      expect(
          const GamePackageInspector()
              .inspect(built.packageBytes)
              .manifest
              .compatibility
              .requiredCapabilities,
          contains(entry.value));
      final host = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: {...base, 'catalog.partitioned@2'},
        supportedProjectFormats: {'v9'},
        currentProjectFormat: 'v9',
        supportedSaveFormats: {1},
      );
      expect(
          () => GamePackageInspector(hostCompatibility: host)
              .inspect(built.packageBytes),
          throwsA(isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'capabilityUnsupported')));
    });
  }
  for (final invalid in ['missing', 'disabled', 'wrong-form', 'duplicate']) {
    test('companion rejects $invalid species before publication', () {
      final files = spatialFeaturePayload('companion');
      const path = 'project/data/pokemon/species/bronze-bird.json';
      if (invalid == 'missing') {
        files.remove(path);
      } else if (invalid == 'duplicate') {
        files['project/data/pokemon/species/duplicate.json'] = files[path]!;
      } else {
        final species =
            jsonDecode(utf8.decode(files[path]!)) as Map<String, dynamic>;
        if (invalid == 'disabled') {
          (species['classification'] as Map)['isEnabledInProject'] = false;
        } else {
          (species['forms'] as Map)['formId'] = 'silver';
        }
        files[path] = utf8.encode(jsonEncode(species));
      }
      expect(
          () => const GamePackageBuilder().build(
              manifest: spatialManifest(capabilities: [
                'map3d@1',
                'map3d.gameplay@1',
                SpatialGameplayCapabilities.companionCapabilityId,
              ]),
              payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.code,
              'code',
              'runtime3d.companion_species_invalid')));
    });
  }
  test('contact device refuses a 2D package rather than silently hiding it',
      () {
    final files = spatialFeaturePayload('contact');
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!)));
    files['project/project.json'] = utf8.encode(jsonEncode(project
        .copyWith(
          version: ProjectVersion.v8,
          settings: project.settings.copyWith(dimension: ProjectDimension.twoD),
        )
        .toJson()));
    final map = jsonDecode(utf8.decode(files['project/maps/map.json']!))
        as Map<String, dynamic>;
    map.remove('spatialScene');
    map['version'] = 'v8';
    files['project/maps/map.json'] = utf8.encode(jsonEncode(map));
    final manifestJson = spatialManifest(capabilities: [
      'map@1',
      ProjectContactDeviceConfig.capabilityId,
    ]).toJson();
    (manifestJson['compatibility'] as Map<String, dynamic>)['projectFormat'] =
        'v8';
    final manifest = const GamePackageManifestCodec().decodeJson(manifestJson);
    expect(
        () => const GamePackageBuilder()
            .build(manifest: manifest, payloadFiles: files),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains('requires a 3D project'))));
  });

  for (final missing in ['fact', 'scene', 'character']) {
    test('contact rejects missing $missing references before publication', () {
      final files = spatialFeaturePayload('contact');
      final project = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!)));
      final changed = switch (missing) {
        'fact' => project.copyWith(facts: []),
        'scene' => project.copyWith(scenes: []),
        _ => project.copyWith(characters: []),
      };
      files['project/project.json'] = utf8.encode(jsonEncode(changed.toJson()));
      expect(
          () => const GamePackageBuilder().build(
              manifest: spatialManifest(capabilities: [
                'map3d@1',
                'map3d.gameplay@1',
                ProjectContactDeviceConfig.capabilityId
              ]),
              payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()));
    });
  }
  test('audio rejects a missing registered media reference before publication',
      () {
    final files = spatialFeaturePayload('audio');
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!)));
    files['project/project.json'] = utf8.encode(
        jsonEncode(project.copyWith(cinematicMediaAssets: []).toJson()));
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(capabilities: [
              'map3d@1',
              'map3d.gameplay@1',
              SpatialGameplayCapabilities.audioCapabilityId
            ]),
            payloadFiles: files),
        throwsA(isA<GamePackageFormatException>()));
  });
  for (final invalid in ['wrong-kind', 'looping']) {
    test('audio rejects $invalid media before publication', () {
      final files = spatialFeaturePayload('audio');
      final project = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!)));
      final asset = project.cinematicMediaAssets.single;
      files['project/project.json'] =
          utf8.encode(jsonEncode(project.copyWith(cinematicMediaAssets: [
        CinematicMediaAsset(
          id: asset.id,
          label: asset.label,
          relativePath: asset.relativePath,
          kind: invalid == 'wrong-kind'
              ? CinematicMediaAssetKind.music
              : CinematicMediaAssetKind.sound,
          loopByDefault: invalid == 'looping',
        )
      ]).toJson()));
      expect(
          () => const GamePackageBuilder().build(
              manifest: spatialManifest(capabilities: [
                'map3d@1',
                'map3d.gameplay@1',
                SpatialGameplayCapabilities.audioCapabilityId
              ]),
              payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()));
    });
  }
}

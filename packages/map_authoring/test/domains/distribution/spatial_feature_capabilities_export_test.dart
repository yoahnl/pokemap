import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('local cinematic in connected maps does not require a newer Player', () async {
    final root = await Directory.systemTemp.createTemp('connected-local-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = spatialFeaturePayload('cinematicConnected');
    final json = jsonDecode(utf8.decode(files['project/project.json']!)) as Map<String, dynamic>;
    json['cinematics'][0]['stageContext']['stagePoints'][0]['x'] = 4.5;
    files['project/project.json'] = utf8.encode(jsonEncode(json));
    for (final entry in files.entries) {
      final file = File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(gameId: 'games.example.local',
          gameVersion: '0.1.0', title: 'Local', authorName: 'Yoahn',
          defaultLocale: 'fr', supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest);
    expect(result.manifest.compatibility.requiredCapabilities,
        isNot(contains('map3d.cinematic-connected@1')));
    for (final entry in files.entries) {
      expect(await File('${root.path}/${entry.key.substring('project/'.length)}').readAsBytes(), entry.value);
    }
  });

  test('point shadow export combines a lamp and caster placed in separate maps', () async {
    final root = await Directory.systemTemp.createTemp('cross-map-point-shadow-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = spatialPayload();
    final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
    final map = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/map.json']!)));
    final lamp = ProjectModel3dEntry.fromJson({...project.models3d.single.toJson(),
      'id': 'lamp', 'sourceAssetId': 'lamp-source', 'relativePath': 'assets/models3d/lamp.glb'})
      .copyWith(light: Model3dPointLight(localPosition: Model3dVector3.zero));
    files['project/assets/models3d/lamp.glb'] = files['project/assets/models3d/model.glb']!;
    final catalog = jsonDecode(utf8.decode(files['project/assets/.pokemap-assets.json']!)) as Map<String, dynamic>;
    final records = catalog['records'] as List;
    records.add({...records.first as Map<String, dynamic>, 'id': 'lamp-source', 'logicalPath': lamp.relativePath});
    files['project/assets/.pokemap-assets.json'] = utf8.encode(jsonEncode(catalog));
    files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(models3d: [
      project.models3d.single.copyWith(castsShadowsByDefault: true), lamp], maps: [
      ...project.maps, const ProjectMapEntry(id: 'lamp-map', name: 'Lamp', relativePath: 'maps/lamp-map.json'),
    ]).toJson()));
    files['project/maps/lamp-map.json'] = utf8.encode(jsonEncode(MapData.fromJson({
      ...map.toJson(), 'id': 'lamp-map',
    }).copyWith(spatialScene: map.spatialScene!.copyWith(instances: [
      SpatialModelInstance(id: 'lamp-placement', modelId: lamp.id, position: Model3dVector3.zero),
    ])).toJson()));
    for (final entry in files.entries) {
      final file = File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final result = await const CanonicalGamePackageExportService().build(projectRoot: root,
      profile: GamePackageExportProfile(gameId: 'games.example.crossmapshadows', gameVersion: '0.1.0',
        title: 'Cross map shadows', authorName: 'Yoahn', defaultLocale: 'fr', supportedLocales: ['fr']),
      mode: GamePackageExportMode.localTest);
    expect(result.manifest.compatibility.requiredCapabilities, contains('map3d.point-light-shadows@1'));
    for (final path in ['project/project.json', 'project/maps/map.json', 'project/maps/lamp-map.json']) {
      expect(await File('${root.path}/${path.substring('project/'.length)}').readAsBytes(), files[path]);
    }
  });
  for (final (assetDefault, override, required) in [
    (false, null, false), (true, null, true), (true, false, false), (false, true, true),
  ]) {
    test('point shadow export resolves casting $assetDefault/$override without source mutation', () async {
      final root = await Directory.systemTemp.createTemp('point-shadow-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
      final map = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/map.json']!)));
      files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(models3d: [
        for (final model in project.models3d) model.copyWith(castsShadowsByDefault: assetDefault,
          light: Model3dPointLight(localPosition: Model3dVector3.zero)),
      ]).toJson()));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(spatialScene:
        map.spatialScene!.copyWith(instances: [for (final instance in map.spatialScene!.instances)
          instance.copyWith(castsShadows: override, clearCastsShadows: override == null)])).toJson()));
      for (final entry in files.entries) {
        final file = File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final result = await const CanonicalGamePackageExportService().build(projectRoot: root,
        profile: GamePackageExportProfile(gameId: 'games.example.pointshadows', gameVersion: '0.1.0',
          title: 'Point shadows', authorName: 'Yoahn', defaultLocale: 'fr', supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest);
      expect(result.manifest.compatibility.requiredCapabilities.contains('map3d.point-light-shadows@1'), required);
      for (final path in ['project/project.json', 'project/maps/map.json']) {
        expect(await File('${root.path}/${path.substring('project/'.length)}').readAsBytes(), files[path]);
      }
    });
  }
  for (final (cycleEnabled, lampEnabled) in [(false, false), (true, false), (false, true), (true, true)]) {
    test('lighting export derives cycle $cycleEnabled and placed lamp $lampEnabled without source mutation', () async {
      final root = await Directory.systemTemp.createTemp('lighting-feature-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
      final map = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/map.json']!)));
      files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(models3d: [
        for (final model in project.models3d) model.copyWith(light: lampEnabled
          ? Model3dPointLight(localPosition: Model3dVector3(x: 0, y: 2.25, z: 0)) : null),
      ]).toJson()));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(spatialScene:
        map.spatialScene!.copyWith(dayNightCycle: cycleEnabled ? SpatialDayNightCycle() : null)).toJson()));
      for (final entry in files.entries) {
        final file = File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final beforeProject = await File('${root.path}/project.json').readAsBytes();
      final beforeMap = await File('${root.path}/maps/map.json').readAsBytes();
      final result = await const CanonicalGamePackageExportService().build(projectRoot: root,
        profile: GamePackageExportProfile(gameId: 'games.example.lighting', gameVersion: '0.1.0',
          title: 'Lighting', authorName: 'Yoahn', defaultLocale: 'fr', supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest);
      final capabilities = result.manifest.compatibility.requiredCapabilities;
      expect(capabilities.contains(SpatialSceneLightingCapabilities.dayNightCapabilityId), cycleEnabled);
      expect(capabilities.contains(SpatialSceneLightingCapabilities.pointLightCapabilityId), lampEnabled);
      expect(await File('${root.path}/project.json').readAsBytes(), beforeProject);
      expect(await File('${root.path}/maps/map.json').readAsBytes(), beforeMap);
    });
  }
  for (final (assetDefault, override, required) in [
    (false, null, false), (true, null, true), (true, false, false), (false, true, true),
  ]) {
    test('shadow export derives effective casting $assetDefault/$override without source mutation', () async {
      final root = await Directory.systemTemp.createTemp('shadow-feature-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
      final configured = project.copyWith(models3d: [
        for (final model in project.models3d) model.copyWith(castsShadowsByDefault: assetDefault),
      ]);
      final map = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/map.json']!)));
      files['project/project.json'] = utf8.encode(jsonEncode(configured.toJson()));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [
          for (final instance in map.spatialScene!.instances)
            instance.copyWith(castsShadows: override, clearCastsShadows: override == null),
        ]),
      ).toJson()));
      for (final entry in files.entries) {
        final file = File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final beforeProject = await File('${root.path}/project.json').readAsBytes();
      final beforeMap = await File('${root.path}/maps/map.json').readAsBytes();
      final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(gameId: 'games.example.shadows', gameVersion: '0.1.0',
          title: 'Shadows', authorName: 'Yoahn', defaultLocale: 'fr', supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest,
      );
      expect(result.manifest.compatibility.requiredCapabilities.contains(SpatialModelShadowCapabilities.capabilityId), required);
      expect(await File('${root.path}/project.json').readAsBytes(), beforeProject);
      expect(await File('${root.path}/maps/map.json').readAsBytes(), beforeMap);
    });
  }
  final features = {
    'cinematicConnected': 'map3d.cinematic-connected@1',
    'camera': SpatialCameraProfile.orthographicCapabilityId,
    'companion': SpatialGameplayCapabilities.companionCapabilityId,
    'contact': ProjectContactDeviceConfig.capabilityId,
    'audio': SpatialGameplayCapabilities.audioCapabilityId,
    'sceneMusic': SpatialGameplayCapabilities.sceneMusicCapabilityId,
    'actorOcclusion': SpatialActorOcclusionCapabilities.capabilityId,
    'cinematicFade': SpatialGameplayCapabilities.cinematicFadeCapabilityId,
  };
  for (final entry in features.entries) {
    test(
        'canonical export discovers ${entry.key} capability without source mutation',
        () async {
      final root =
          await Directory.systemTemp.createTemp('spatial-feature-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialFeaturePayload(entry.key);
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      if (entry.key == 'companion') {
        for (final family in ['species', 'learnsets', 'evolutions', 'media']) {
          await Directory('${root.path}/data/pokemon/$family')
              .create(recursive: true);
        }
      }
      final before = await File('${root.path}/project.json').readAsBytes();
      final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
            gameId: 'games.example.features',
            gameVersion: '0.1.0',
            title: 'Features',
            authorName: 'Yoahn',
            defaultLocale: 'fr',
            supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest,
      );
      expect(result.manifest.compatibility.requiredCapabilities,
          contains(entry.value));
      expect(await File('${root.path}/project.json').readAsBytes(), before);
      expect(jsonDecode(utf8.decode(before)), isA<Map>());
    });
  }
  for (final invalid in ['missing', 'disabled', 'wrong-form']) {
    test('canonical export rejects $invalid companion species', () async {
      final root = await Directory.systemTemp.createTemp('companion-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialFeaturePayload('companion');
      const path = 'project/data/pokemon/species/bronze-bird.json';
      if (invalid == 'disabled') {
        final species =
            jsonDecode(utf8.decode(files[path]!)) as Map<String, dynamic>;
        (species['classification'] as Map)['isEnabledInProject'] = false;
        files[path] = utf8.encode(jsonEncode(species));
      } else {
        final project = jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>;
        final mapping = ((project['partyCompanion'] as Map)['mappings'] as List)
            .single as Map;
        mapping[invalid == 'missing' ? 'speciesId' : 'formId'] =
            invalid == 'missing' ? 'missing-species' : 'silver';
        files['project/project.json'] = utf8.encode(jsonEncode(project));
      }
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      await expectLater(
          const CanonicalGamePackageExportService().build(
              projectRoot: root,
              profile: GamePackageExportProfile(
                  gameId: 'games.example.companion',
                  gameVersion: '0.1.0',
                  title: 'Companion',
                  authorName: 'Yoahn',
                  defaultLocale: 'fr',
                  supportedLocales: ['fr']),
              mode: GamePackageExportMode.localTest),
          throwsA(isA<GamePackageExportException>().having(
              (error) => error.code,
              'code',
              'runtime3d.companion_species_invalid')));
    });
  }
}

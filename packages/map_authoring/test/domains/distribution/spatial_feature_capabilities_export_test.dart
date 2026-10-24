import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_feature_capabilities_fixture.dart';

void main() {
  final features = {
    'camera': SpatialCameraProfile.orthographicCapabilityId,
    'companion': SpatialGameplayCapabilities.companionCapabilityId,
    'contact': ProjectContactDeviceConfig.capabilityId,
    'audio': SpatialGameplayCapabilities.audioCapabilityId,
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

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/cs_audio_package_fixture.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test('$dimension export adds v2 only for activation-only CS', () async {
      final files = csAudioPayload(dimension,
          fieldAbilities:
              ProjectFieldAbilitiesSettings.fromIds(['rock_climb', 'defog']));
      final root = await Directory.systemTemp.createTemp('cs11-export-');
      addTearDown(() => root.delete(recursive: true));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final original = await File('${root.path}/project.json').readAsBytes();
      final artifact = await const CanonicalGamePackageExportService().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.example.cs11',
              gameVersion: '0.1.0',
              title: 'Generic CS11',
              authorName: 'Yoahn',
              defaultLocale: 'fr',
              supportedLocales: ['fr']),
          mode: GamePackageExportMode.localTest);
      expect(artifact.manifest.compatibility.requiredCapabilities,
          contains(FieldAbilityActivationCapabilities.extendedCapabilityId));
      expect(artifact.manifest.compatibility.requiredCapabilities,
          contains(FieldAbilityActivationCapabilities.capabilityId));
      expect(await File('${root.path}/project.json').readAsBytes(), original);
    });

    for (final empty in [false, true]) {
      test(
          '$dimension legacy export keeps its existing capabilities empty=$empty',
          () async {
        final files = csAudioPayload(dimension,
            fieldAbilities:
                empty ? const ProjectFieldAbilitiesSettings.empty() : null,
            audio: empty ? ProjectAudioSettings() : null);
        final root =
            await Directory.systemTemp.createTemp('cs-audio-legacy-export-');
        addTearDown(() => root.delete(recursive: true));
        for (final entry in files.entries) {
          final file =
              File('${root.path}/${entry.key.substring('project/'.length)}');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(entry.value);
        }
        final artifact = await const CanonicalGamePackageExportService().build(
            projectRoot: root,
            profile: GamePackageExportProfile(
                gameId: 'games.example.cs-audio',
                gameVersion: '0.1.0',
                title: 'Generic CS Audio',
                authorName: 'Yoahn',
                defaultLocale: 'fr',
                supportedLocales: ['fr']),
            mode: GamePackageExportMode.localTest);
        expect(artifact.manifest.compatibility.requiredCapabilities, [
          'catalog.partitioned@2',
          dimension == ProjectDimension.twoD ? 'map@1' : 'map3d@1'
        ]);
      });
    }
    test('$dimension export refuses an unresolved custom project sound',
        () async {
      final files = csAudioPayload(dimension,
          audio: ProjectAudioSettings(cues: {
            ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
                source: ProjectSoundSource.custom, mediaId: 'missing'),
          }));
      final root =
          await Directory.systemTemp.createTemp('cs-audio-invalid-export-');
      addTearDown(() => root.delete(recursive: true));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final source = File('${root.path}/project.json');
      final original = await source.readAsBytes();
      await expectLater(
          const CanonicalGamePackageExportService().build(
              projectRoot: root,
              profile: GamePackageExportProfile(
                  gameId: 'games.example.cs-audio',
                  gameVersion: '0.1.0',
                  title: 'Generic CS Audio',
                  authorName: 'Yoahn',
                  defaultLocale: 'fr',
                  supportedLocales: ['fr']),
              mode: GamePackageExportMode.localTest),
          throwsA(isA<GamePackageExportException>().having((e) => e.message,
              'missing media', contains('missing audio media'))));
      expect(await source.readAsBytes(), original);
    });
    test('$dimension export refuses actual PNG bytes forged as WAV metadata',
        () async {
      final files = csAudioPayload(dimension,
          audio: ProjectAudioSettings(cues: {
            ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
                source: ProjectSoundSource.custom, mediaId: 'bell'),
          }));
      addCsAudioMedia(files,
          sourceMediaType: 'application/octet-stream',
          sourceBytes: image.encodePng(image.Image(width: 1, height: 1)),
          logicalPath: 'assets/fake.png');
      final root =
          await Directory.systemTemp.createTemp('cs-audio-forged-export-');
      addTearDown(() => root.delete(recursive: true));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final source = File('${root.path}/assets/.pokemap-assets.json');
      final original = await source.readAsBytes();
      await expectLater(
          const CanonicalGamePackageExportService().build(
              projectRoot: root,
              profile: GamePackageExportProfile(
                  gameId: 'games.example.cs-audio',
                  gameVersion: '0.1.0',
                  title: 'Generic CS Audio',
                  authorName: 'Yoahn',
                  defaultLocale: 'fr',
                  supportedLocales: ['fr']),
              mode: GamePackageExportMode.localTest),
          throwsA(isA<GamePackageExportException>()));
      expect(await source.readAsBytes(), original);
    });
    for (final sourceMime in ['application/octet-stream', 'audio/ogg']) {
      test(
          '$dimension exports probed WAV with compatible source MIME $sourceMime',
          () async {
        final files = csAudioPayload(dimension,
            audio: ProjectAudioSettings(cues: {
              ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
                  source: ProjectSoundSource.custom, mediaId: 'bell'),
            }));
        final blob = addCsAudioMedia(files, sourceMediaType: sourceMime);
        final root =
            await Directory.systemTemp.createTemp('cs-audio-generic-export-');
        addTearDown(() => root.delete(recursive: true));
        for (final entry in files.entries) {
          final file =
              File('${root.path}/${entry.key.substring('project/'.length)}');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(entry.value);
        }
        final assetFile = File('${root.path}/assets/.pokemap-assets.json');
        final original = await assetFile.readAsBytes();
        final future = const CanonicalGamePackageExportService().build(
            projectRoot: root,
            profile: GamePackageExportProfile(
                gameId: 'games.example.cs-audio',
                gameVersion: '0.1.0',
                title: 'Generic CS Audio',
                authorName: 'Yoahn',
                defaultLocale: 'fr',
                supportedLocales: ['fr']),
            mode: GamePackageExportMode.localTest);
        if (sourceMime == 'application/octet-stream') {
          final artifact = await future;
          final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
          final catalog = jsonDecode(utf8.decode(archive
              .findFile('project/assets/.pokemap-assets.json')!
              .content)) as Map;
          final source = (catalog['records'] as List)
              .singleWhere((r) => r['id'] == 'sound-source') as Map;
          expect(source['artifact']['mediaType'], sourceMime);
          expect(archive.findFile(blob)!.content, files[blob]);
        } else {
          await expectLater(future, throwsA(isA<GamePackageExportException>()));
        }
        expect(await assetFile.readAsBytes(), original);
      });
    }
    for (final custom in [false, true]) {
      test(
          '$dimension canonical export retains CS and ${custom ? 'custom' : 'silent'} audio',
          () async {
        final files = csAudioPayload(dimension,
            fieldAbilities: ProjectFieldAbilitiesSettings(
                disabledAbilities: [FieldAbility.dive]),
            audio: ProjectAudioSettings(cues: {
              ProjectSoundCue.uiConfirm: ProjectSoundBinding(
                  source: custom
                      ? ProjectSoundSource.custom
                      : ProjectSoundSource.silent,
                  mediaId: custom ? 'bell' : null)
            }));
        final blob = custom ? addCsAudioMedia(files) : null;
        final root = await Directory.systemTemp.createTemp('cs-audio-export-');
        addTearDown(() => root.delete(recursive: true));
        for (final entry in files.entries) {
          final file =
              File('${root.path}/${entry.key.substring('project/'.length)}');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(entry.value);
        }
        final source = File('${root.path}/project.json');
        final original = await source.readAsBytes();
        final artifact = await const CanonicalGamePackageExportService().build(
            projectRoot: root,
            profile: GamePackageExportProfile(
                gameId: 'games.example.cs-audio',
                gameVersion: '0.1.0',
                title: 'Generic CS Audio',
                authorName: 'Yoahn',
                defaultLocale: 'fr',
                supportedLocales: ['fr']),
            mode: GamePackageExportMode.localTest);
        final capabilities =
            artifact.manifest.compatibility.requiredCapabilities;
        expect(capabilities,
            contains(FieldAbilityActivationCapabilities.capabilityId));
        expect(
            capabilities,
            isNot(contains(
                FieldAbilityActivationCapabilities.extendedCapabilityId)));
        expect(capabilities, contains(ProjectAudioCapabilities.capabilityId));
        expect(artifact.manifest.compatibility.projectFormat,
            dimension == ProjectDimension.twoD ? 'v8' : 'v9');
        if (custom) {
          final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
          expect(archive.findFile(blob!), isNotNull);
          final media = jsonDecode(utf8.decode(archive
              .findFile('project/assets/.pokemap-media.json')!
              .content)) as Map;
          expect((media['entries'] as List).single['id'], 'bell');
          final assets = jsonDecode(utf8.decode(archive
              .findFile('project/assets/.pokemap-assets.json')!
              .content)) as Map;
          expect(
              (assets['records'] as List).any((r) => r['id'] == 'sound-source'),
              isTrue);
          expect(archive.findFile(blob)!.content, files[blob]);
        }
        expect(await source.readAsBytes(), original);
      });
    }
  }
}

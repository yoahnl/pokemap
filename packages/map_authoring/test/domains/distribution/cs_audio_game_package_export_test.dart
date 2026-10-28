import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/cs_audio_package_fixture.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
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

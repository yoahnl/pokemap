import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/cs_audio_package_fixture.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test('$dimension legacy package retains its capability set', () {
      final built = const GamePackageBuilder().build(
          manifest: csAudioManifest(dimension, []),
          payloadFiles: csAudioPayload(dimension));
      final inspected =
          const GamePackageInspector().inspect(built.packageBytes);
      expect(inspected.manifest.compatibility.requiredCapabilities,
          isNot(contains(FieldAbilityActivationCapabilities.capabilityId)));
      expect(inspected.manifest.compatibility.requiredCapabilities,
          isNot(contains(ProjectAudioCapabilities.capabilityId)));
    });
    for (final audio in [false, true]) {
      test('$dimension requires explicit ${audio ? 'audio' : 'CS'} capability',
          () {
        final files = csAudioPayload(dimension,
            fieldAbilities: audio
                ? null
                : ProjectFieldAbilitiesSettings(
                    disabledAbilities: [FieldAbility.dive]),
            audio: audio
                ? ProjectAudioSettings(cues: {
                    ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
                        source: ProjectSoundSource.silent)
                  })
                : null);
        final id = audio
            ? ProjectAudioCapabilities.capabilityId
            : FieldAbilityActivationCapabilities.capabilityId;
        expect(
            () => const GamePackageBuilder().build(
                manifest: csAudioManifest(dimension, []), payloadFiles: files),
            throwsA(isA<GamePackageFormatException>()
                .having((e) => e.message, 'capability', contains(id))));
        final built = const GamePackageBuilder().build(
            manifest: csAudioManifest(dimension, [id]), payloadFiles: files);
        expect(
            const GamePackageInspector()
                .inspect(built.packageBytes)
                .manifest
                .compatibility
                .requiredCapabilities,
            contains(id));
        expect(AveluneRuntimeCompatibility.host().capabilities, contains(id));
      });
    }
    for (final defect in [
      'missing-media',
      'wrong-kind',
      'missing-source',
      'missing-blob',
      'corrupt-blob',
      'metadata-mismatch',
      'unknown-source-field',
      'duplicate-source-path'
    ]) {
      test('$dimension refuses custom sound $defect and preserves inputs', () {
        final files = csAudioPayload(dimension,
            audio: ProjectAudioSettings(cues: {
              ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
                  source: ProjectSoundSource.custom, mediaId: 'bell'),
            }));
        final blob = addCsAudioMedia(files,
            kind: defect == 'wrong-kind'
                ? ProjectMediaKind.image
                : ProjectMediaKind.audio);
        if (defect == 'missing-media') {
          files.remove('project/assets/.pokemap-media.json');
        }
        if (defect == 'missing-source') {
          final path = 'project/assets/.pokemap-assets.json';
          final catalog = jsonDecode(utf8.decode(files[path]!)) as Map;
          (catalog['records'] as List)
              .removeWhere((r) => r['id'] == 'sound-source');
          files[path] = utf8.encode(jsonEncode(catalog));
        }
        if (defect == 'missing-blob') files.remove(blob);
        if (defect == 'corrupt-blob') files[blob] = List.filled(52, 0);
        if (defect == 'metadata-mismatch') {
          final path = 'project/assets/.pokemap-media.json';
          final catalog = jsonDecode(utf8.decode(files[path]!)) as Map;
          (catalog['entries'] as List).single['technicalMetadata']
              ['sizeBytes'] = 53;
          files[path] = utf8.encode(jsonEncode(catalog));
        }
        if (defect == 'unknown-source-field' ||
            defect == 'duplicate-source-path') {
          final path = 'project/assets/.pokemap-assets.json';
          final catalog = jsonDecode(utf8.decode(files[path]!)) as Map;
          final records = catalog['records'] as List;
          final source =
              records.singleWhere((r) => r['id'] == 'sound-source') as Map;
          if (defect == 'unknown-source-field') {
            (source['artifact'] as Map)['future'] = true;
          }
          if (defect == 'duplicate-source-path') {
            source['logicalPath'] = records.first['logicalPath'];
          }
          files[path] = utf8.encode(jsonEncode(catalog));
        }
        final original = jsonEncode(files);
        expect(
            () => const GamePackageBuilder().build(
                manifest: csAudioManifest(
                    dimension, [ProjectAudioCapabilities.capabilityId]),
                payloadFiles: files),
            throwsA(isA<GamePackageFormatException>()));
        expect(jsonEncode(files), original);
      });
    }
    test(
        '$dimension valid custom sound is accepted with its canonical media closure',
        () {
      final files = csAudioPayload(dimension,
          audio: ProjectAudioSettings(cues: {
            ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
                source: ProjectSoundSource.custom, mediaId: 'bell'),
          }));
      addCsAudioMedia(files);
      final built = const GamePackageBuilder().build(
          manifest: csAudioManifest(
              dimension, [ProjectAudioCapabilities.capabilityId]),
          payloadFiles: files);
      expect(
          const GamePackageInspector()
              .inspect(built.packageBytes)
              .manifest
              .compatibility
              .projectFormat,
          dimension == ProjectDimension.twoD ? 'v8' : 'v9');
    });
  }
}

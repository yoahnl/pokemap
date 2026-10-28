import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/cs_audio_package_fixture.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    for (final id in ['rock_climb', 'defog']) {
      test('$dimension activation-only $id requires capability v2', () {
        final files = csAudioPayload(dimension,
            fieldAbilities: ProjectFieldAbilitiesSettings.fromIds([id]));
        expect(
            () => const GamePackageBuilder().build(
                manifest: csAudioManifest(dimension,
                    [FieldAbilityActivationCapabilities.capabilityId]),
                payloadFiles: files),
            throwsA(isA<GamePackageFormatException>().having(
                (e) => e.message,
                'capability',
                contains(
                    FieldAbilityActivationCapabilities.extendedCapabilityId))));
        final built = const GamePackageBuilder().build(
            manifest: csAudioManifest(dimension, [
              FieldAbilityActivationCapabilities.capabilityId,
              FieldAbilityActivationCapabilities.extendedCapabilityId
            ]),
            payloadFiles: files);
        expect(
            const GamePackageInspector()
                .inspect(built.packageBytes)
                .manifest
                .compatibility
                .requiredCapabilities,
            contains(FieldAbilityActivationCapabilities.extendedCapabilityId));
        expect(AveluneRuntimeCompatibility.host().capabilities,
            contains(FieldAbilityActivationCapabilities.extendedCapabilityId));
      });
    }

    for (final randomAccess in [false, true]) {
      test(
          '$dimension rejects capability v2 before project parsing via ${randomAccess ? 'random access' : 'memory'}',
          () {
        final files = csAudioPayload(dimension,
            fieldAbilities:
                ProjectFieldAbilitiesSettings.fromIds(['rock_climb', 'defog']));
        final originalFiles = jsonEncode(files);
        final built = const GamePackageBuilder().build(
            manifest: csAudioManifest(dimension, [
              FieldAbilityActivationCapabilities.capabilityId,
              FieldAbilityActivationCapabilities.extendedCapabilityId,
            ]),
            payloadFiles: files);
        final originalPackage = List<int>.of(built.packageBytes);
        final current = AveluneRuntimeCompatibility.host();
        GamePackageHostCompatibility host({required bool extended}) =>
            GamePackageHostCompatibility(
                hubVersion: built.manifest.compatibility.minHubVersion,
                runtimeApiVersion: current.runtimeApiVersion,
                supportedRuntimeApiVersions:
                    current.supportedRuntimeApiVersions,
                capabilities: {...current.capabilities}..removeAll(extended
                    ? []
                    : [
                        FieldAbilityActivationCapabilities.extendedCapabilityId
                      ]),
                supportedProjectFormats: current.supportedProjectFormats,
                currentProjectFormat: current.currentProjectFormat,
                currentProjectFormats: current.currentProjectFormats,
                supportedSaveFormats: {
                  ...current.supportedSaveFormats,
                  built.manifest.compatibility.saveFormat,
                });
        final olderHost = host(extended: false);
        expect(olderHost.capabilities,
            contains(FieldAbilityActivationCapabilities.capabilityId));
        final poisoned = _withInvalidProjectDescriptor(built);
        final originalPoisoned = List<int>.of(poisoned);
        GamePackageInspectionResult inspect(
            List<int> bytes, GamePackageHostCompatibility compatibility) {
          final inspector =
              GamePackageInspector(hostCompatibility: compatibility);
          return randomAccess
              ? inspector.inspectSourceSync(_MemorySource(bytes))
              : inspector.inspect(bytes);
        }

        for (final bytes in [built.packageBytes, poisoned]) {
          expect(
              () => inspect(bytes, olderHost),
              throwsA(isA<GamePackageFormatException>()
                  .having((error) => error.code, 'compatibility rejection',
                      'capabilityUnsupported')
                  .having((error) => error.path, 'compatibility boundary',
                      r'$.compatibility')));
        }
        expect(inspect(built.packageBytes, host(extended: true)).manifest.toJson(),
            built.manifest.toJson());
        expect(
            () => inspect(poisoned, host(extended: true)),
            throwsA(isA<GamePackageFormatException>().having(
                (error) => error.code,
                'project payload reaches parsing on supported host',
                'executableContent')));
        expect(built.packageBytes, originalPackage);
        expect(poisoned, originalPoisoned);
        expect(jsonEncode(files), originalFiles);
      });
    }

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
    for (final inspect in [false, true]) {
      test(
          '$dimension refuses real PNG bytes forged as project audio at ${inspect ? 'inspection' : 'build'}',
          () {
        final files = csAudioPayload(dimension,
            audio: ProjectAudioSettings(cues: {
              ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
                  source: ProjectSoundSource.custom, mediaId: 'bell'),
            }));
        addCsAudioMedia(files,
            sourceMediaType: 'application/octet-stream',
            sourceBytes: image.encodePng(image.Image(width: 1, height: 1)),
            logicalPath: 'assets/fake.png');
        final original = jsonEncode(files);
        expect(
            () => inspect
                ? const GamePackageInspector()
                    .inspect(_uncheckedAudioPackage(dimension, files))
                : const GamePackageBuilder().build(
                    manifest: csAudioManifest(
                        dimension, [ProjectAudioCapabilities.capabilityId]),
                    payloadFiles: files),
            throwsA(isA<GamePackageFormatException>().having((e) => e.code,
                'audio bytes verification', 'projectAudioInvalid')));
        expect(jsonEncode(files), original);
      });
    }
    for (final sourceMime in ['application/octet-stream', 'audio/ogg']) {
      test('$dimension probed WAV preserves source MIME $sourceMime', () {
        final files = csAudioPayload(dimension,
            audio: ProjectAudioSettings(cues: {
              ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
                  source: ProjectSoundSource.custom, mediaId: 'bell'),
            }));
        addCsAudioMedia(files, sourceMediaType: sourceMime);
        final original = jsonEncode(files);
        GamePackageBuildResult build() => const GamePackageBuilder().build(
            manifest: csAudioManifest(
                dimension, [ProjectAudioCapabilities.capabilityId]),
            payloadFiles: files);
        if (sourceMime == 'application/octet-stream') {
          final built = build();
          expect(
              const GamePackageInspector()
                  .inspect(built.packageBytes)
                  .manifest
                  .compatibility
                  .requiredCapabilities,
              contains(ProjectAudioCapabilities.capabilityId));
        } else {
          expect(build, throwsA(isA<GamePackageFormatException>()));
        }
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
      final mediaPath = 'project/assets/.pokemap-media.json';
      final savedMedia = jsonDecode(utf8.decode(files[mediaPath]!)) as Map;
      (savedMedia['entries'] as List).single['technicalMetadata']
          ['durationMilliseconds'] = 2;
      files[mediaPath] = utf8.encode(jsonEncode(savedMedia));
      final originalMediaBytes = List<int>.of(files[mediaPath]!);
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
      expect(files[mediaPath], originalMediaBytes);
    });
  }
}

List<int> _withInvalidProjectDescriptor(GamePackageBuildResult built) {
  final payload = <String, List<int>>{
    for (final file in ZipDecoder().decodeBytes(built.packageBytes))
      if (file.name != 'game-manifest.json')
        file.name: List<int>.of(file.content as List<int>),
    'project/project.json': utf8.encode('{invalid-project-descriptor'),
  };
  final manifestJson = built.manifest.toJson();
  manifestJson['content'] =
      const GamePackageInventoryBuilder().build(payload).toJson();
  final manifest = const GamePackageManifestCodec().decodeJson(manifestJson);
  final entries = [
    MapEntry('game-manifest.json',
        const GamePackageManifestCodec().encodeCanonicalUtf8(manifest)),
    ...payload.entries,
  ]..sort((left, right) => left.key.compareTo(right.key));
  return DeterministicZipEncoder.encode(entries);
}

final class _MemorySource implements RandomAccessPackageSource {
  _MemorySource(List<int> bytes) : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;

  @override
  int get length => bytes.length;

  @override
  Uint8List readAtSync(int offset, int length) =>
      Uint8List.sublistView(bytes, offset, offset + length);
}

List<int> _uncheckedAudioPackage(
    ProjectDimension dimension, Map<String, List<int>> files) {
  final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!))
          as Map<String, dynamic>);
  final publication = PortableCatalogPublication.encodeProject(project);
  final payload = <String, List<int>>{
    ...files,
    'project/project.json': CanonicalJson.encodeUtf8(publication.descriptor),
    for (final object in publication.storage.objects.entries)
      'project/catalog/objects/${object.key}.json': object.value,
  };
  final manifestJson =
      csAudioManifest(dimension, [ProjectAudioCapabilities.capabilityId])
          .toJson();
  (manifestJson['compatibility'] as Map)['requiredCapabilities'] = [
    dimension == ProjectDimension.twoD ? 'map@1' : 'map3d@1',
    ProjectAudioCapabilities.capabilityId,
    'catalog.partitioned@2'
  ];
  manifestJson['content'] =
      const GamePackageInventoryBuilder().build(payload).toJson();
  final manifest = const GamePackageManifestCodec().decodeJson(manifestJson);
  final entries = [
    MapEntry('game-manifest.json',
        const GamePackageManifestCodec().encodeCanonicalUtf8(manifest)),
    ...payload.entries,
  ]..sort((left, right) => left.key.compareTo(right.key));
  return DeterministicZipEncoder.encode(entries);
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../support/project_audio_test_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'legacy and builtin settings open without reading a media catalog',
    () async {
      for (final settings in <ProjectAudioSettings?>[
        null,
        ProjectAudioSettings(
          cues: {
            ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
              source: ProjectSoundSource.builtin,
            ),
          },
        ),
      ]) {
        final audio = await loadRuntimeProjectAudio(
          projectRootDirectory: '/no-project-catalog',
          mixer: RuntimeAudioMixer(),
          settings: settings,
          driver: ProjectAudioTestDriver(),
        );
        expect(audio.lastFailure, isNull);
        await audio.dispose();
      }
    },
  );
  test('resolves only selected audio blobs once with MIME and no per event catalog access', () async {
    final root = await Directory.systemTemp.createTemp('audio-catalog-');
    addTearDown(() => root.delete(recursive: true));
    final record = await _catalog(root);
    final driver = ProjectAudioTestDriver();
    final audio = await loadRuntimeProjectAudio(
      projectRootDirectory: root.path,
      mixer: RuntimeAudioMixer(),
      settings: _settings,
      driver: driver,
    );
    addTearDown(audio.dispose);
    final selected = audio.resolve(ProjectSoundCue.uiConfirm)!;
    expect(
      selected.path,
      '${root.path}/${assetBlobStorageKey(record.artifact)}',
    );
    expect(selected.mimeType, 'audio/ogg');
    await File('${root.path}/$projectMediaCatalogStorageKey').delete();
    await File('${root.path}/$assetCatalogStorageKey').delete();
    expect(await audio.play(ProjectSoundCue.uiConfirm), isTrue);
    driver.complete(1);
    expect(await audio.play(ProjectSoundCue.uiConfirm), isTrue);
    expect(driver.paths, [selected.path]);
    expect(driver.replays, 1);
  });
  test(
    'rejects missing selected media and symlinked sources without falling back',
    () async {
      final root = await Directory.systemTemp.createTemp('audio-catalog-');
      addTearDown(() => root.delete(recursive: true));
      final record = await _catalog(root);
      final source = File(
        '${root.path}/${assetBlobStorageKey(record.artifact)}',
      );
      await source.delete();
      await expectLater(
        loadRuntimeProjectAudio(
          projectRootDirectory: root.path,
          mixer: RuntimeAudioMixer(),
          settings: _settings,
          driver: ProjectAudioTestDriver(),
        ),
        throwsA(isA<FileSystemException>()),
      );
      final outside = await Directory.systemTemp.createTemp('audio-outside-');
      addTearDown(() => outside.delete(recursive: true));
      final other = await File('${outside.path}/file.ogg')
          .writeAsBytes([1, 2, 3]);
      await Link(source.path).create(other.path);
      await expectLater(
        loadRuntimeProjectAudio(
          projectRootDirectory: root.path,
          mixer: RuntimeAudioMixer(),
          settings: _settings,
          driver: ProjectAudioTestDriver(),
        ),
        throwsStateError,
      );
    },
  );
}

final _settings = ProjectAudioSettings(
  cues: {
    ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
      source: ProjectSoundSource.custom,
      mediaId: 'confirm',
    ),
  },
);

Future<AssetRecord> _catalog(Directory root) async {
  final bytes = [1, 2, 3];
  final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: 'audio/ogg');
  final record = AssetRecord(
    id: 'confirm-source',
    logicalPath: 'assets/audio/confirm.ogg',
    artifact: artifact,
  );
  final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
  await blob.parent.create(recursive: true);
  await blob.writeAsBytes(bytes);
  final assets = AssetCatalog(records: [record]);
  await File('${root.path}/$assetCatalogStorageKey')
      .writeAsString(jsonEncode(assets.toJson()));
  final catalog = ProjectMediaCatalog(
    entries: [
      ProjectMediaAsset(
        id: 'confirm',
        label: 'Confirm',
        kind: ProjectMediaKind.audio,
        sourceAssetId: record.id,
        technicalMetadata: ProjectMediaTechnicalMetadata(
          mediaType: 'audio/ogg',
          container: 'ogg',
          codec: 'vorbis',
          sizeBytes: bytes.length,
        ),
      ),
      ProjectMediaAsset(
        id: 'unrelated',
        label: 'Unrelated',
        kind: ProjectMediaKind.audio,
        sourceAssetId: 'not-loaded-source',
      ),
    ],
  );
  await File('${root.path}/$projectMediaCatalogStorageKey')
      .writeAsString(jsonEncode(catalog.toJson()));
  return record;
}

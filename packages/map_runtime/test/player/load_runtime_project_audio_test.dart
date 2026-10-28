import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../support/project_audio_test_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('runtime reads a shared sound blob once for multiple selected media identities', () async {
    final root = await Directory.systemTemp.createTemp('audio-shared-');
    addTearDown(() => root.delete(recursive: true));
    final source = await _catalog(root);
    final file = File('${root.path}/$projectMediaCatalogStorageKey');
    final catalog = decodeProjectMediaCatalogBytes(await file.readAsBytes());
    await file.writeAsBytes(
      encodeProjectMediaCatalogBytes(
        ProjectMediaCatalog(
          entries: [
            ...catalog.entries,
            ProjectMediaAsset.fromJson({
              ...catalog.entries.first.toJson(),
              'id': 'second',
              'label': 'Second',
            }),
          ],
        ),
      ),
    );
    final settings = ProjectAudioSettings(
      cues: {
        ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
          source: ProjectSoundSource.custom,
          mediaId: 'confirm',
        ),
        ProjectSoundCue.doorOpen: const ProjectSoundBinding(
          source: ProjectSoundSource.custom,
          mediaId: 'second',
        ),
      },
    );
    final io = _ReadCountingOverrides();
    final blobPath = '${root.path}/${assetBlobStorageKey(source.artifact)}';
    await IOOverrides.runWithIOOverrides(() async {
      final audio = await loadRuntimeProjectAudio(projectRootDirectory: root.path,
          mixer: RuntimeAudioMixer(), settings: settings, driver: ProjectAudioTestDriver());
      addTearDown(audio.dispose);
      expect(io.reads.where((path) => path == blobPath), hasLength(1));
      await audio.play(ProjectSoundCue.uiConfirm);
      await audio.play(ProjectSoundCue.doorOpen);
      expect(io.reads.where((path) => path == blobPath), hasLength(1));
    }, io);
  });
  test('shared source verification rejects a later alias with contradictory byte length', () async {
    final root = await Directory.systemTemp.createTemp('audio-alias-');
    addTearDown(() => root.delete(recursive: true));
    final source = await _catalog(root);
    final badArtifact = ContentArtifactRef(
      digest: source.artifact.digest,
      mediaType: source.artifact.mediaType,
      byteLength: source.artifact.byteLength + 1,
    );
    await File('${root.path}/$assetCatalogStorageKey').writeAsString(
      jsonEncode(
        AssetCatalog(
          records: [
            source,
            AssetRecord(
              id: 'bad-source',
              logicalPath: 'assets/audio/alias.wav',
              artifact: badArtifact,
            ),
          ],
        ).toJson(),
      ),
    );
    final file = File('${root.path}/$projectMediaCatalogStorageKey');
    final catalog = decodeProjectMediaCatalogBytes(await file.readAsBytes());
    await file.writeAsBytes(
      encodeProjectMediaCatalogBytes(
        ProjectMediaCatalog(
          entries: [
            ...catalog.entries,
            ProjectMediaAsset(
              id: 'bad',
              label: 'Bad',
              kind: ProjectMediaKind.audio,
              sourceAssetId: 'bad-source',
              technicalMetadata: ProjectMediaTechnicalMetadata(
                mediaType: 'audio/wav',
                container: 'wav',
                codec: 'pcm',
                sizeBytes: badArtifact.byteLength,
              ),
            ),
          ],
        ),
      ),
    );
    final settings = ProjectAudioSettings(
      cues: {
        ProjectSoundCue.uiConfirm: const ProjectSoundBinding(
          source: ProjectSoundSource.custom,
          mediaId: 'confirm',
        ),
        ProjectSoundCue.doorOpen: const ProjectSoundBinding(
          source: ProjectSoundSource.custom,
          mediaId: 'bad',
        ),
      },
    );
    await expectLater(
      loadRuntimeProjectAudio(
        projectRootDirectory: root.path,
        mixer: RuntimeAudioMixer(),
        settings: settings,
        driver: ProjectAudioTestDriver(),
      ),
      throwsA(anything),
    );
  });
  test('runtime rejects same size audio byte changes after import', () async {
    final root = await Directory.systemTemp.createTemp('audio-changed-');
    addTearDown(() => root.delete(recursive: true));
    final source = await _catalog(root);
    final blob = File('${root.path}/${assetBlobStorageKey(source.artifact)}');
    final bytes = await blob.readAsBytes();
    bytes[bytes.length - 1] = 1;
    await blob.writeAsBytes(bytes);
    await expectLater(
      loadRuntimeProjectAudio(
        projectRootDirectory: root.path,
        mixer: RuntimeAudioMixer(),
        settings: _settings,
        driver: ProjectAudioTestDriver(),
      ),
      throwsA(isA<ProjectAudioSourceException>()),
    );
    expect(await blob.readAsBytes(), bytes);
  });
  test(
    'runtime rejects a real PNG forged as audio without mutating its source',
    () async {
      for (final sourceMime in ['application/octet-stream', 'audio/wav']) {
        final root = await Directory.systemTemp.createTemp('audio-forged-png-');
        addTearDown(() => root.delete(recursive: true));
        final png = img.encodePng(img.Image(width: 1, height: 1));
        final source = await _catalog(
          root,
          content: png,
          sourceMime: sourceMime,
          mediaMime: 'audio/wav',
        );
        final before = await File('${root.path}/$assetCatalogStorageKey')
            .readAsBytes();
        await expectLater(
          loadRuntimeProjectAudio(
            projectRootDirectory: root.path,
            mixer: RuntimeAudioMixer(),
            settings: _settings,
            driver: ProjectAudioTestDriver(),
          ),
          throwsA(isA<Exception>()),
        );
        expect(
          await File('${root.path}/$assetCatalogStorageKey').readAsBytes(),
          before,
        );
        expect(
          await File('${root.path}/${assetBlobStorageKey(source.artifact)}')
              .readAsBytes(),
          png,
        );
      }
    },
  );
  test('runtime uses probed WAV MIME for a generic legacy source and rejects contradictory audio MIME', () async {
    for (final sourceMime in ['application/octet-stream', 'audio/ogg']) {
      final root = await Directory.systemTemp.createTemp('audio-catalog-');
      addTearDown(() => root.delete(recursive: true));
      await _catalog(
        root,
        content: _wav(),
        sourceMime: sourceMime,
        mediaMime: 'audio/wav',
      );
      final before = await File('${root.path}/$assetCatalogStorageKey')
          .readAsBytes();
      final loading = loadRuntimeProjectAudio(
        projectRootDirectory: root.path,
        mixer: RuntimeAudioMixer(),
        settings: _settings,
        driver: ProjectAudioTestDriver(),
      );
      if (sourceMime == 'audio/ogg') {
        await expectLater(loading, throwsStateError);
      } else {
        final audio = await loading;
        expect(audio.resolve(ProjectSoundCue.uiConfirm)!.mimeType, 'audio/wav');
        expect(await audio.play(ProjectSoundCue.uiConfirm), isTrue);
        await audio.dispose();
      }
      expect(
        await File('${root.path}/$assetCatalogStorageKey').readAsBytes(),
        before,
      );
    }
  });
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
    expect(selected.mimeType, 'audio/wav');
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

Future<AssetRecord> _catalog(
  Directory root, {
  List<int>? content,
  String sourceMime = 'audio/wav',
  String mediaMime = 'audio/wav',
}) async {
  final bytes = content ?? _wav();
  final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: sourceMime);
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
          mediaType: mediaMime,
          container: mediaMime == 'audio/wav' ? 'wav' : 'ogg',
          codec: mediaMime == 'audio/wav' ? 'pcm' : 'vorbis',
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

List<int> _wav() {
  final bytes = Uint8List(1644);
  final view = ByteData.sublistView(bytes);
  void text(int offset, String value) =>
      bytes.setRange(offset, offset + value.length, ascii.encode(value));
  text(0, 'RIFF');
  view.setUint32(4, bytes.length - 8, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little);
  view.setUint16(22, 1, Endian.little);
  view.setUint32(24, 8000, Endian.little);
  view.setUint32(28, 16000, Endian.little);
  view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little);
  text(36, 'data');
  view.setUint32(40, bytes.length - 44, Endian.little);
  return bytes;
}

final class _ReadCountingOverrides extends IOOverrides {
  final reads = <String>[];
  @override
  File createFile(String path) =>
      _ReadCountingFile(super.createFile(path), reads);
}

final class _ReadCountingFile extends Fake implements File {
  _ReadCountingFile(this.file, this.reads);
  final File file;
  final List<String> reads;
  @override
  String get path => file.path;
  @override
  bool get isAbsolute => file.isAbsolute;
  @override
  Future<String> resolveSymbolicLinks() => file.resolveSymbolicLinks();
  @override
  Future<int> length() => file.length();
  @override
  Future<Uint8List> readAsBytes() {
    reads.add(path);
    return file.readAsBytes();
  }
}

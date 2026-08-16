import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/session/domain/repositories/package_asset_port.dart';

final class HubInstalledPresentationMedia {
  const HubInstalledPresentationMedia({
    required this.catalog,
    required this.mediaUris,
  });

  final ProjectMediaCatalog catalog;
  final Map<String, Uri> mediaUris;
}

enum HubInstalledPresentationMediaErrorCode {
  mediaCatalogUnreadable,
  assetCatalogUnreadable,
  assetCatalogInvalid,
  mediaAssetMissing,
  mediaBlobMissing,
  mediaBlobInvalid,
}

final class HubInstalledPresentationMediaException implements Exception {
  const HubInstalledPresentationMediaException({
    required this.code,
    required this.safeMessage,
    this.mediaId,
    this.sourceAssetId,
  });

  final HubInstalledPresentationMediaErrorCode code;
  final String safeMessage;
  final String? mediaId;
  final String? sourceAssetId;

  @override
  String toString() =>
      'HubInstalledPresentationMediaException(${code.name}): $safeMessage';
}

final class HubInstalledPresentationMediaLoader {
  const HubInstalledPresentationMediaLoader();

  static const _mediaCatalogPath = 'project/assets/.pokemap-media.json';
  static const _assetCatalogPath = 'project/assets/.pokemap-assets.json';
  static final _digest = RegExp(r'^sha256:([a-f0-9]{64})$');

  Future<HubInstalledPresentationMedia> load(PackageAssetPort assets) async {
    final mediaCatalog = await _loadMediaCatalog(assets);
    final assetCatalog = await _loadObject(
      assets,
      _assetCatalogPath,
      HubInstalledPresentationMediaErrorCode.assetCatalogUnreadable,
      'The installed asset catalog could not be read.',
    );
    if (assetCatalog['schemaVersion'] != 1 ||
        assetCatalog['records'] is! List<Object?>) {
      throw const HubInstalledPresentationMediaException(
        code: HubInstalledPresentationMediaErrorCode.assetCatalogInvalid,
        safeMessage: 'The installed asset catalog is invalid.',
      );
    }
    final digestsByAssetId = <String, String>{};
    for (final raw in assetCatalog['records']! as List<Object?>) {
      if (raw is! Map) {
        throw const HubInstalledPresentationMediaException(
          code: HubInstalledPresentationMediaErrorCode.assetCatalogInvalid,
          safeMessage: 'The installed asset catalog is invalid.',
        );
      }
      final record = Map<String, Object?>.from(raw);
      final artifact = record['artifact'];
      if (record['id'] is! String || artifact is! Map) {
        throw const HubInstalledPresentationMediaException(
          code: HubInstalledPresentationMediaErrorCode.assetCatalogInvalid,
          safeMessage: 'The installed asset catalog is invalid.',
        );
      }
      final digest = Map<String, Object?>.from(artifact)['digest'];
      if (digest is! String || _digest.firstMatch(digest) == null) {
        throw const HubInstalledPresentationMediaException(
          code: HubInstalledPresentationMediaErrorCode.assetCatalogInvalid,
          safeMessage: 'The installed asset catalog is invalid.',
        );
      }
      digestsByAssetId[record['id']! as String] =
          _digest.firstMatch(digest)!.group(1)!;
    }
    final mediaUris = <String, Uri>{};
    for (final media in mediaCatalog.entries) {
      final digest = digestsByAssetId[media.sourceAssetId];
      if (digest == null) {
        throw HubInstalledPresentationMediaException(
          code: HubInstalledPresentationMediaErrorCode.mediaAssetMissing,
          safeMessage: 'A Presentation media asset is missing.',
          mediaId: media.id,
          sourceAssetId: media.sourceAssetId,
        );
      }
      final file = await _resolveMediaBlob(assets, media, digest);
      mediaUris[media.id] = file.uri;
    }
    return HubInstalledPresentationMedia(
      catalog: mediaCatalog,
      mediaUris: Map<String, Uri>.unmodifiable(mediaUris),
    );
  }

  Future<ProjectMediaCatalog> _loadMediaCatalog(PackageAssetPort assets) async {
    final raw = await _loadObject(
      assets,
      _mediaCatalogPath,
      HubInstalledPresentationMediaErrorCode.mediaCatalogUnreadable,
      'The installed media catalog could not be read.',
    );
    try {
      return ProjectMediaCatalog.fromJson(raw);
    } catch (_) {
      throw const HubInstalledPresentationMediaException(
        code: HubInstalledPresentationMediaErrorCode.mediaCatalogUnreadable,
        safeMessage: 'The installed media catalog could not be read.',
      );
    }
  }

  Future<File> _resolveMediaBlob(
    PackageAssetPort assets,
    ProjectMediaAsset media,
    String digest,
  ) async {
    try {
      final file = await assets.resolveFile(
        'project/assets/.pokemap-store/$digest.blob',
      );
      final actualDigest =
          computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
            NarrativeProjectFingerprintEntry(
              relativePath: 'artifact-content',
              bytes: await file.readAsBytes(),
            ),
          ]);
      if (actualDigest != 'sha256:$digest') {
        throw const FormatException('Presentation media digest mismatch.');
      }
      return file;
    } on FormatException {
      throw HubInstalledPresentationMediaException(
        code: HubInstalledPresentationMediaErrorCode.mediaBlobInvalid,
        safeMessage: 'A Presentation media blob is invalid.',
        mediaId: media.id,
        sourceAssetId: media.sourceAssetId,
      );
    } catch (_) {
      throw HubInstalledPresentationMediaException(
        code: HubInstalledPresentationMediaErrorCode.mediaBlobMissing,
        safeMessage: 'A Presentation media blob is missing.',
        mediaId: media.id,
        sourceAssetId: media.sourceAssetId,
      );
    }
  }

  Future<Map<String, Object?>> _loadObject(
    PackageAssetPort assets,
    String path,
    HubInstalledPresentationMediaErrorCode code,
    String safeMessage,
  ) async {
    try {
      return await _decodeObject(await assets.resolveFile(path));
    } catch (_) {
      throw HubInstalledPresentationMediaException(
        code: code,
        safeMessage: safeMessage,
      );
    }
  }
}

final class HubInstalledPresentationRuntime {
  HubInstalledPresentationRuntime({
    required this.runtimeSourceId,
    required HubInstalledPresentationMedia media,
    required PresentationMediaTargetPlatform targetPlatform,
    required RuntimeAudioMixer audioMixer,
    required bool reducedMotion,
    RuntimePresentationFrameDeltas? frameDeltas,
    RuntimePresentationBeforeTerminal? beforeTerminal,
  }) : controller = player_ui.RuntimePresentationSurfaceController(
         catalog: media.catalog,
         mediaUris: media.mediaUris,
         targetPlatform: targetPlatform,
         videoDriver: player_ui.VideoPlayerPresentationPlaybackDriver(),
         audioMixer: audioMixer,
         reduceMotion: reducedMotion,
         frameDeltas: frameDeltas,
         beforeTerminal: beforeTerminal,
       );

  final String runtimeSourceId;
  final player_ui.RuntimePresentationSurfaceController controller;

  RuntimeNewGamePreSessionRunner buildPreSessionRunner({
    required ProjectManifest project,
    required String projectRootDirectory,
    required String projectRevision,
    required String sceneId,
  }) => RuntimeTextPreSessionSceneRunner(
    project: project,
    projectRootDirectory: projectRootDirectory,
    sceneId: sceneId,
    presentationCinematic: ScenePresentationCinematicRuntimeAwaitableAdapter(
      runtimeSourceId: runtimeSourceId,
      projectRevision: projectRevision,
      assets: project.presentationCinematics,
      player: controller,
    ),
  );

  void cancelActive() => unawaited(controller.cancelActive());

  Future<void> close() => controller.close();
}

PresentationMediaTargetPlatform currentPresentationMediaTargetPlatform() {
  if (Platform.isAndroid) return PresentationMediaTargetPlatform.android;
  if (Platform.isIOS) return PresentationMediaTargetPlatform.ios;
  if (Platform.isMacOS) return PresentationMediaTargetPlatform.macos;
  if (Platform.isWindows) return PresentationMediaTargetPlatform.windows;
  if (Platform.isLinux) return PresentationMediaTargetPlatform.linux;
  return PresentationMediaTargetPlatform.web;
}

Future<Map<String, Object?>> _decodeObject(File file) async {
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map) {
    throw const FormatException('Installed JSON document must be an object.');
  }
  return Map<String, Object?>.from(decoded);
}

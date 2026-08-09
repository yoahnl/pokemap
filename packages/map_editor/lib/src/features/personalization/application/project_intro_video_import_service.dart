import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

final class ProjectIntroVideoImportException implements Exception {
  const ProjectIntroVideoImportException({
    required this.code,
    required this.message,
    this.path,
    this.cause,
  });

  final String code;
  final String message;
  final String? path;
  final Object? cause;

  @override
  String toString() => 'ProjectIntroVideoImportException($code): $message';
}

final class IntroVideoProbeResult {
  const IntroVideoProbeResult({
    required this.duration,
    required this.width,
    required this.height,
  });

  final Duration duration;
  final int width;
  final int height;
}

abstract interface class IntroVideoProbe {
  Future<IntroVideoProbeResult> probe(File videoFile);
}

final class VideoPlayerIntroVideoProbe implements IntroVideoProbe {
  const VideoPlayerIntroVideoProbe();

  @override
  Future<IntroVideoProbeResult> probe(File videoFile) async {
    final controller = VideoPlayerController.file(videoFile);
    try {
      await controller.initialize();
      final value = controller.value;
      if (!value.isInitialized ||
          value.duration <= Duration.zero ||
          value.size.isEmpty) {
        throw const ProjectIntroVideoImportException(
          code: 'introDecoderRejected',
          message: 'The platform video decoder rejected this intro.',
        );
      }
      return IntroVideoProbeResult(
        duration: value.duration,
        width: value.size.width.round(),
        height: value.size.height.round(),
      );
    } on ProjectIntroVideoImportException {
      rethrow;
    } on Object catch (error) {
      throw ProjectIntroVideoImportException(
        code: 'introDecoderRejected',
        path: videoFile.path,
        message: 'The platform video decoder rejected this intro.',
        cause: error,
      );
    } finally {
      await controller.dispose();
    }
  }
}

abstract interface class ProjectIntroVideoImporter {
  Future<ProjectIntroVideoProfile> importIntoProject({
    required Directory projectRoot,
    required File videoFile,
    required File posterFile,
    File? captionsFile,
    String reducedMotionBehavior = 'poster',
    bool allowReplay = true,
  });
}

final class ProjectIntroVideoImportService
    implements ProjectIntroVideoImporter {
  const ProjectIntroVideoImportService({
    this.probe = const VideoPlayerIntroVideoProbe(),
  });

  final IntroVideoProbe probe;

  @override
  Future<ProjectIntroVideoProfile> importIntoProject({
    required Directory projectRoot,
    required File videoFile,
    required File posterFile,
    File? captionsFile,
    String reducedMotionBehavior = 'poster',
    bool allowReplay = true,
  }) async {
    await _requireFile(videoFile, 'introVideoMissing');
    await _requireFile(posterFile, 'introPosterMissing');
    if (captionsFile != null) {
      await _requireFile(captionsFile, 'introCaptionsMissing');
    }
    final videoBytes = await videoFile.readAsBytes();
    if (videoBytes.length > projectIntroVideoMaxSizeBytes) {
      throw ProjectIntroVideoImportException(
        code: 'introSizeExceeded',
        path: videoFile.path,
        message: 'Intro video must not exceed 100 MiB.',
      );
    }
    final signature = latin1.decode(videoBytes, allowInvalid: true);
    if (!videoFile.path.toLowerCase().endsWith('.mp4') ||
        !signature.contains('ftyp') ||
        !(signature.contains('avc1') || signature.contains('avc3'))) {
      throw ProjectIntroVideoImportException(
        code: 'introCodecUnsupported',
        path: videoFile.path,
        message: 'Choose an MP4 video encoded with H.264.',
      );
    }
    final audioCodec = signature.contains('mp4a') ? 'aac' : 'none';
    final posterBytes = await posterFile.readAsBytes();
    if (image.decodeImage(posterBytes) == null) {
      throw ProjectIntroVideoImportException(
        code: 'introPosterInvalid',
        path: posterFile.path,
        message: 'Choose a valid PNG, JPEG, or WebP poster.',
      );
    }
    List<int>? captionsBytes;
    if (captionsFile != null) {
      captionsBytes = await captionsFile.readAsBytes();
      late final String captions;
      try {
        captions = utf8.decode(captionsBytes, allowMalformed: false);
      } on FormatException catch (error) {
        throw ProjectIntroVideoImportException(
          code: 'introCaptionsInvalid',
          path: captionsFile.path,
          message: 'Captions must use UTF-8 WebVTT.',
          cause: error,
        );
      }
      if (!captions.startsWith('WEBVTT')) {
        throw ProjectIntroVideoImportException(
          code: 'introCaptionsInvalid',
          path: captionsFile.path,
          message: 'Captions must use WebVTT.',
        );
      }
    }

    final media = await probe.probe(videoFile);
    final durationMilliseconds = media.duration.inMilliseconds;
    final bitrateKbps = durationMilliseconds <= 0
        ? 0
        : ((videoBytes.length * 8) / durationMilliseconds).ceil();
    final digest = sha256
        .convert(<int>[
          ...videoBytes,
          ...posterBytes,
          ...?captionsBytes,
        ])
        .toString()
        .substring(0, 16);
    final posterExtension = p.extension(posterFile.path).toLowerCase();
    final videoPath = 'assets/presentation/intro/intro-$digest.mp4';
    final posterPath =
        'assets/presentation/intro/poster-$digest$posterExtension';
    final captionsPath = captionsBytes == null
        ? null
        : 'assets/presentation/intro/captions-$digest.vtt';
    final profile = ProjectIntroVideoProfile(
      media: ProjectResponsiveVideoProfile(
        landscape: ProjectVideoVariantProfile(
          videoPath: videoPath,
          posterPath: posterPath,
          captionsPath: captionsPath,
          durationMilliseconds: durationMilliseconds,
          width: media.width,
          height: media.height,
          bitrateKbps: bitrateKbps,
          sizeBytes: videoBytes.length,
          videoCodec: 'h264',
          audioCodec: audioCodec,
        ),
      ),
      reducedMotionBehavior: reducedMotionBehavior,
      allowReplay: allowReplay,
    );
    final diagnostics = validateProjectPresentationProfile(
      ProjectPresentationProfile(intro: profile),
    );
    for (final diagnostic in diagnostics) {
      if (diagnostic.severity == ProjectPresentationDiagnosticSeverity.error) {
        throw ProjectIntroVideoImportException(
          code: diagnostic.code,
          path: diagnostic.path,
          message: diagnostic.message,
        );
      }
    }

    await _persistAtomically(
      projectRoot: projectRoot,
      files: <String, List<int>>{
        videoPath: videoBytes,
        posterPath: posterBytes,
        if (captionsPath != null) captionsPath: captionsBytes!,
      },
      token: digest,
    );
    return profile;
  }

  Future<void> _requireFile(File file, String code) async {
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw ProjectIntroVideoImportException(
        code: code,
        path: file.path,
        message: 'Choose a regular file.',
      );
    }
  }

  Future<void> _persistAtomically({
    required Directory projectRoot,
    required Map<String, List<int>> files,
    required String token,
  }) async {
    final destination =
        Directory(p.join(projectRoot.path, 'assets', 'presentation', 'intro'));
    final staging = Directory(p.join(destination.path, '.import-$token'));
    try {
      await staging.create(recursive: true);
      for (final entry in files.entries) {
        await File(p.join(staging.path, p.basename(entry.key)))
            .writeAsBytes(entry.value, flush: true);
      }
      for (final entry in files.entries) {
        final staged = File(p.join(staging.path, p.basename(entry.key)));
        final target = File(p.join(projectRoot.path, entry.key));
        if (await target.exists()) {
          await staged.delete();
        } else {
          await staged.rename(target.path);
        }
      }
    } on Object catch (error) {
      throw ProjectIntroVideoImportException(
        code: 'introImportWriteFailed',
        path: projectRoot.path,
        message: 'The intro assets could not be imported into the project.',
        cause: error,
      );
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }
}

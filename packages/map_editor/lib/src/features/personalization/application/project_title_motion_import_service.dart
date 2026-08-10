import 'dart:io';

import 'package:map_core/map_core.dart';

import 'project_intro_video_import_service.dart';

enum ProjectTitleMotionLoopRole { prompt, menu }

abstract interface class ProjectTitleMotionLoopImporter {
  Future<ProjectResponsiveVideoProfile> importIntoProject({
    required Directory projectRoot,
    required File videoFile,
    required File posterFile,
    File? captionsFile,
  });
}

final class ProjectTitleMotionImportService
    implements ProjectTitleMotionLoopImporter {
  const ProjectTitleMotionImportService({
    this.introImporter = const ProjectIntroVideoImportService(),
    this.probe = const VideoPlayerIntroVideoProbe(),
  });

  final ProjectIntroVideoImporter introImporter;
  final IntroVideoProbe probe;

  @override
  Future<ProjectResponsiveVideoProfile> importIntoProject({
    required Directory projectRoot,
    required File videoFile,
    required File posterFile,
    File? captionsFile,
  }) async {
    final size = await videoFile.length();
    if (size > projectTitleLoopMaxSizeBytes) {
      throw ProjectIntroVideoImportException(
        code: 'titleMotionLoopSizeExceeded',
        path: videoFile.path,
        message: 'Title loops must not exceed 24 MiB.',
      );
    }
    final probeResult = await probe.probe(videoFile);
    if (probeResult.duration.inMilliseconds >
        projectTitleLoopMaxDurationMilliseconds) {
      throw ProjectIntroVideoImportException(
        code: 'titleMotionLoopDurationExceeded',
        path: videoFile.path,
        message: 'Title loops must not exceed 15 seconds.',
      );
    }
    final intro = await introImporter.importIntoProject(
      projectRoot: projectRoot,
      videoFile: videoFile,
      posterFile: posterFile,
      captionsFile: captionsFile,
      reducedMotionBehavior: 'poster',
      allowReplay: false,
    );
    final media = intro.media;
    final diagnostics = validateProjectPresentationProfile(
      ProjectPresentationProfile(
        titleMotion: ProjectTitleMotionProfile(promptLoop: media),
      ),
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
    return media;
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/personalization/application/project_intro_video_import_service.dart';
import 'package:map_editor/src/features/personalization/application/project_title_motion_import_service.dart';

void main() {
  late Directory root;
  late File video;
  late File poster;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('title-motion-import-');
    video = File('${root.path}/loop.mp4');
    poster = File('${root.path}/poster.png');
    await video.writeAsBytes(<int>[0]);
    await poster.writeAsBytes(<int>[0]);
  });

  tearDown(() => root.delete(recursive: true));

  test('returns validated responsive media for a short bounded loop', () async {
    final importer = _RecordingIntroImporter();
    final service = ProjectTitleMotionImportService(
      introImporter: importer,
      probe: const _Probe(Duration(seconds: 12)),
    );

    final media = await service.importIntoProject(
      projectRoot: root,
      videoFile: video,
      posterFile: poster,
    );

    expect(media, _media);
    expect(importer.calls, 1);
    expect(importer.reducedMotionBehavior, 'poster');
    expect(importer.allowReplay, isFalse);
  });

  test('rejects a loop longer than fifteen seconds before copying', () async {
    final importer = _RecordingIntroImporter();
    final service = ProjectTitleMotionImportService(
      introImporter: importer,
      probe: const _Probe(Duration(milliseconds: 15001)),
    );

    await expectLater(
      service.importIntoProject(
        projectRoot: root,
        videoFile: video,
        posterFile: poster,
      ),
      throwsA(
        isA<ProjectIntroVideoImportException>().having(
          (error) => error.code,
          'code',
          'titleMotionLoopDurationExceeded',
        ),
      ),
    );
    expect(importer.calls, 0);
  });
}

final class _Probe implements IntroVideoProbe {
  const _Probe(this.duration);

  final Duration duration;

  @override
  Future<IntroVideoProbeResult> probe(File videoFile) async =>
      IntroVideoProbeResult(duration: duration, width: 1280, height: 720);
}

final class _RecordingIntroImporter implements ProjectIntroVideoImporter {
  int calls = 0;
  String? reducedMotionBehavior;
  bool? allowReplay;

  @override
  Future<ProjectIntroVideoProfile> importIntoProject({
    required Directory projectRoot,
    required File videoFile,
    required File posterFile,
    File? captionsFile,
    String reducedMotionBehavior = 'poster',
    bool allowReplay = true,
  }) async {
    calls += 1;
    this.reducedMotionBehavior = reducedMotionBehavior;
    this.allowReplay = allowReplay;
    return const ProjectIntroVideoProfile(media: _media);
  }
}

const _media = ProjectResponsiveVideoProfile(
  landscape: ProjectVideoVariantProfile(
    videoPath: 'assets/presentation/intro/loop.mp4',
    posterPath: 'assets/presentation/intro/poster.png',
    durationMilliseconds: 12000,
    width: 1280,
    height: 720,
    bitrateKbps: 512,
    sizeBytes: 1024,
    videoCodec: 'h264',
    audioCodec: 'none',
  ),
);

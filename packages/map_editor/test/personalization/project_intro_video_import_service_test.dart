import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:path/path.dart' as p;

import '../game_export/game_export_test_fixture.dart';

void main() {
  test('imports a probed MP4, poster, and WebVTT into project-owned assets',
      () async {
    final source = await Directory.systemTemp.createTemp('intro-source-');
    final project = await Directory.systemTemp.createTemp('intro-project-');
    addTearDown(() => source.delete(recursive: true));
    addTearDown(() => project.delete(recursive: true));
    final video = await File(p.join(source.path, 'opening.mp4'))
        .writeAsBytes(_h264Mp4Fixture, flush: true);
    final poster = await File(p.join(source.path, 'poster.png'))
        .writeAsBytes(onePixelPng, flush: true);
    final captions =
        await File(p.join(source.path, 'captions.vtt')).writeAsString(
      'WEBVTT\n\n00:00.000 --> 00:01.000\nBienvenue\n',
      flush: true,
    );

    final profile = await const ProjectIntroVideoImportService(
      probe: _Probe(
        IntroVideoProbeResult(
          duration: Duration(seconds: 1),
          width: 1280,
          height: 720,
        ),
      ),
    ).importIntoProject(
      projectRoot: project,
      videoFile: video,
      posterFile: poster,
      captionsFile: captions,
    );

    expect(profile.videoCodec, 'h264');
    expect(profile.audioCodec, 'aac');
    expect(profile.captionsPath, endsWith('.vtt'));
    expect(
      await File(p.join(project.path, profile.videoPath)).exists(),
      isTrue,
    );
    expect(
      await File(p.join(project.path, profile.posterPath)).exists(),
      isTrue,
    );
  });

  test('rejects over-limit media before writing project assets', () async {
    final source = await Directory.systemTemp.createTemp('intro-source-');
    final project = await Directory.systemTemp.createTemp('intro-project-');
    addTearDown(() => source.delete(recursive: true));
    addTearDown(() => project.delete(recursive: true));
    final video = await File(p.join(source.path, 'opening.mp4'))
        .writeAsBytes(_h264Mp4Fixture, flush: true);
    final poster = await File(p.join(source.path, 'poster.png'))
        .writeAsBytes(onePixelPng, flush: true);
    const service = ProjectIntroVideoImportService(
      probe: _Probe(
        IntroVideoProbeResult(
          duration: Duration(seconds: 121),
          width: 1280,
          height: 720,
        ),
      ),
    );

    expect(
      () => service.importIntoProject(
        projectRoot: project,
        videoFile: video,
        posterFile: poster,
      ),
      throwsA(
        isA<ProjectIntroVideoImportException>().having(
          (error) => error.code,
          'code',
          'introDurationExceeded',
        ),
      ),
    );
    expect(
      await Directory(p.join(project.path, 'assets', 'presentation', 'intro'))
          .exists(),
      isFalse,
    );
  });
}

final class _Probe implements IntroVideoProbe {
  const _Probe(this.result);

  final IntroVideoProbeResult result;

  @override
  Future<IntroVideoProbeResult> probe(File videoFile) async => result;
}

final List<int> _h264Mp4Fixture = <int>[
  0,
  0,
  0,
  24,
  ...utf8.encode('ftypisom'),
  0,
  0,
  0,
  0,
  ...utf8.encode('isomavc1mp4a'),
];

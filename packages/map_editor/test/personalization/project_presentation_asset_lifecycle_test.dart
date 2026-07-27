import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/personalization/application/project_presentation_asset_lifecycle.dart';

void main() {
  group('ProjectPresentationAssetLifecycle', () {
    test('deletes only stale assets explicitly owned by the previous profile',
        () async {
      final root =
          Directory.systemTemp.createTempSync('presentation-assets-cleanup-');
      addTearDown(() => root.deleteSync(recursive: true));
      final oldVideo = _write(root, 'assets/presentation/intro/old.mp4');
      final oldPoster = _write(root, 'assets/presentation/intro/old.png');
      final oldCaptions = _write(root, 'assets/presentation/intro/old.vtt');
      final oldFont = _write(root, 'assets/presentation/fonts/body-old.otf');
      final oldLicense =
          _write(root, 'assets/presentation/fonts/body-old-license.txt');
      final newVideo = _write(root, 'assets/presentation/intro/new.mp4');
      final unknown =
          _write(root, 'assets/presentation/intro/do-not-touch.mp4');
      final previous = _profile(
        videoPath: 'assets/presentation/intro/old.mp4',
        posterPath: 'assets/presentation/intro/old.png',
        captionsPath: 'assets/presentation/intro/old.vtt',
        fontPath: 'assets/presentation/fonts/body-old.otf',
        licensePath: 'assets/presentation/fonts/body-old-license.txt',
      );
      final current = _profile(
        videoPath: 'assets/presentation/intro/new.mp4',
        posterPath: 'assets/presentation/intro/old.png',
      );

      final result =
          await const ProjectPresentationAssetLifecycle().cleanStaleAssets(
        projectRoot: root,
        previousProfile: previous,
        currentProfile: current,
      );

      expect(
        result.deletedPaths,
        <String>{
          'assets/presentation/intro/old.mp4',
          'assets/presentation/intro/old.vtt',
          'assets/presentation/fonts/body-old.otf',
          'assets/presentation/fonts/body-old-license.txt',
        },
      );
      expect(result.failures, isEmpty);
      expect(oldVideo.existsSync(), isFalse);
      expect(oldCaptions.existsSync(), isFalse);
      expect(oldFont.existsSync(), isFalse);
      expect(oldLicense.existsSync(), isFalse);
      expect(oldPoster.existsSync(), isTrue);
      expect(newVideo.existsSync(), isTrue);
      expect(unknown.existsSync(), isTrue);
    });

    test('rejects traversal, absolute paths, and symbolic links', () async {
      final root =
          Directory.systemTemp.createTempSync('presentation-assets-safety-');
      addTearDown(() => root.deleteSync(recursive: true));
      final outside = File('${root.parent.path}/pokemap-outside-asset.txt')
        ..writeAsStringSync('outside');
      addTearDown(() {
        if (outside.existsSync()) outside.deleteSync();
      });
      final managedTarget =
          _write(root, 'assets/presentation/intro/symlink-target.mp4');
      final link = Link('${root.path}/assets/presentation/intro/linked.mp4')
        ..createSync(managedTarget.path);
      final previous = ProjectPresentationProfile(
        intro: ProjectIntroVideoProfile(
          videoPath: 'assets/presentation/intro/linked.mp4',
          posterPath: '../${outside.uri.pathSegments.last}',
          durationMilliseconds: 1,
          width: 1,
          height: 1,
          bitrateKbps: 1,
          sizeBytes: 1,
          videoCodec: 'h264',
        ),
        typography: ProjectTypographyProfile(
          body: ProjectTypographyRoleProfile(
            fontPath: outside.path,
            licensePath: 'assets/presentation/fonts/../intro/not-safe.txt',
          ),
        ),
      );

      final result =
          await const ProjectPresentationAssetLifecycle().cleanStaleAssets(
        projectRoot: root,
        previousProfile: previous,
        currentProfile: const ProjectPresentationProfile(),
      );

      expect(result.deletedPaths, isEmpty);
      expect(
        result.skippedPaths,
        containsAll(<String>[
          'assets/presentation/intro/linked.mp4',
          '../${outside.uri.pathSegments.last}',
          outside.path,
          'assets/presentation/fonts/../intro/not-safe.txt',
        ]),
      );
      expect(outside.existsSync(), isTrue);
      expect(link.existsSync(), isTrue);
      expect(managedTarget.existsSync(), isTrue);
    });

    test('reports a missing stale file without scanning managed directories',
        () async {
      final root =
          Directory.systemTemp.createTempSync('presentation-assets-missing-');
      addTearDown(() => root.deleteSync(recursive: true));
      final unknown =
          _write(root, 'assets/presentation/fonts/unreferenced.ttf');
      final previous = _profile(
        fontPath: 'assets/presentation/fonts/missing.ttf',
        licensePath: 'assets/presentation/fonts/missing-license.txt',
      );

      final result =
          await const ProjectPresentationAssetLifecycle().cleanStaleAssets(
        projectRoot: root,
        previousProfile: previous,
        currentProfile: const ProjectPresentationProfile(),
      );

      expect(result.deletedPaths, isEmpty);
      expect(
        result.skippedPaths,
        <String>{
          'assets/presentation/fonts/missing.ttf',
          'assets/presentation/fonts/missing-license.txt',
        },
      );
      expect(unknown.existsSync(), isTrue);
    });
  });
}

ProjectPresentationProfile _profile({
  String? videoPath,
  String? posterPath,
  String? captionsPath,
  String? fontPath,
  String? licensePath,
}) {
  return ProjectPresentationProfile(
    intro: videoPath == null
        ? null
        : ProjectIntroVideoProfile(
            videoPath: videoPath,
            posterPath: posterPath,
            captionsPath: captionsPath,
            durationMilliseconds: 1,
            width: 1,
            height: 1,
            bitrateKbps: 1,
            sizeBytes: 1,
            videoCodec: 'h264',
          ),
    typography: fontPath == null && licensePath == null
        ? null
        : ProjectTypographyProfile(
            body: ProjectTypographyRoleProfile(
              fontPath: fontPath,
              licensePath: licensePath,
            ),
          ),
  );
}

File _write(Directory root, String relativePath) {
  final file = File('${root.path}/$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(relativePath);
  return file;
}

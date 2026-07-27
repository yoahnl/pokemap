import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native decoder plays landscape H.264/AAC', (tester) async {
    await _verifyNativePlayback(
      tester,
      assetPath: 'assets/certification/intro_landscape_h264_aac.mp4',
      expectedSize: const Size(320, 180),
    );
  });

  testWidgets('native decoder plays portrait H.264/AAC', (tester) async {
    await _verifyNativePlayback(
      tester,
      assetPath: 'assets/certification/intro_portrait_h264_aac.mp4',
      expectedSize: const Size(180, 320),
    );
  });
}

Future<void> _verifyNativePlayback(
  WidgetTester tester, {
  required String assetPath,
  required Size expectedSize,
}) async {
  final temporaryDirectory = await Directory.systemTemp.createTemp(
    'pokemap-native-codec-',
  );
  addTearDown(() => temporaryDirectory.delete(recursive: true));
  final bytes = await rootBundle.load(assetPath);
  final videoFile = File(
    '${temporaryDirectory.path}/${assetPath.split('/').last}',
  );
  await videoFile.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );

  final controller = VideoPlayerController.file(videoFile);
  addTearDown(controller.dispose);
  await controller.initialize();
  await controller.setLooping(false);
  await controller.setVolume(0);

  expect(controller.value.isInitialized, isTrue);
  expect(controller.value.hasError, isFalse);
  expect(controller.value.size, expectedSize);
  expect(controller.value.duration, greaterThan(const Duration(seconds: 1)));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    ),
  );
  await controller.play();
  await Future<void>.delayed(const Duration(milliseconds: 750));
  await tester.pump();

  expect(controller.value.hasError, isFalse);
  expect(controller.value.position,
      greaterThan(const Duration(milliseconds: 250)));
  expect(controller.value.isPlaying, isTrue);

  await controller.pause();
  await tester.pumpWidget(const SizedBox.shrink());
}

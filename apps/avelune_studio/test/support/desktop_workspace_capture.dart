import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settleDesktopWorkspace(
  WidgetTester tester,
  StudioMapResources resources,
) async {
  for (var round = 0; round < 3; round++) {
    await tester.pump();
    await awaitDesktopIo(tester, resources.settled);
    await tester.pumpAndSettle();
  }
}

Future<void> awaitDesktopIo(WidgetTester tester, Future<void> future) async {
  var done = false;
  Object? failure;
  future.then<void>(
    (_) {
      done = true;
    },
    onError: (Object error) {
      failure = error;
      done = true;
    },
  );
  final elapsed = Stopwatch()..start();
  while (!done && elapsed.elapsed < const Duration(seconds: 20)) {
    await tester.pump();
    if (!done) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
  }
  if (failure != null) throw failure!;
  expect(
    done,
    isTrue,
    reason: 'Les E/S réelles ne terminent pas entre les frames en 20 secondes.',
  );
}

Future<void> captureDesktopWorkspace(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final directory = Platform.environment['AVELUNE_CAPTURE_DIR'];
  if (directory == null || directory.isEmpty) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> captureM3Widget(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final destination = Platform.environment['AVELUNE_CAPTURE_DIR'];
  if (destination == null || destination.isEmpty) return;
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final pixels = await boundary.toImage(pixelRatio: 1);
    final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
    await Directory(destination).create(recursive: true);
    await File(
      '$destination/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    pixels.dispose();
  });
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

Future<Uint8List> pngBytes(int width, int height, int argb) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(ui.Color(argb), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
}

Future<List<int>> decodedPixel(
  RuntimeTilesetImage image, [
  ui.Rect? source,
]) async {
  final recorder = ui.PictureRecorder();
  final region = source ?? const ui.Rect.fromLTWH(0, 0, 1, 1);
  image.drawImageRect(
    ui.Canvas(recorder),
    region,
    ui.Offset.zero & region.size,
    ui.Paint(),
  );
  final picture = recorder.endRecording();
  final output = await picture.toImage(
    region.width.toInt(),
    region.height.toInt(),
  );
  picture.dispose();
  final bytes = await output.toByteData();
  output.dispose();
  final pixels = bytes!.buffer.asUint8List(
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
  for (var offset = 4; offset < pixels.length; offset += 4) {
    expect(pixels.sublist(offset, offset + 4), pixels.sublist(0, 4));
  }
  return pixels.sublist(0, 4);
}

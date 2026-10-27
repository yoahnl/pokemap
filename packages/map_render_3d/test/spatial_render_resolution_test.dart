import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final viewport = Vector2(800, 450);

  Size sizeFor(double scale, {double devicePixelRatio = 2}) =>
      World3D.renderSizeFor(
        viewport,
        devicePixelRatio: devicePixelRatio,
        resolutionScale: scale,
      );

  test('a full resolution scale renders at physical pixels', () {
    expect(sizeFor(1), const Size(1600, 900));
  });

  test('half resolution renders a quarter of the pixels', () {
    expect(sizeFor(.5), const Size(800, 450));
    expect(sizeFor(.5, devicePixelRatio: 3), const Size(1200, 675));
  });

  test('scales above native resolution are capped to physical pixels', () {
    expect(sizeFor(2), const Size(1600, 900));
  });

  test('invalid or tiny scales stay renderable', () {
    expect(sizeFor(double.nan), const Size(1600, 900));
    expect(sizeFor(double.infinity), const Size(1600, 900));
    expect(sizeFor(0), sizeFor(World3D.minimumResolutionScale));
    expect(sizeFor(-1), const Size(400, 225));
  });
}

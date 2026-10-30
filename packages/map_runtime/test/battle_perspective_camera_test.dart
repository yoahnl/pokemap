import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';

void main() {
  for (final viewport in [
    const Rect.fromLTWH(0, 0, 390, 430),
    const Rect.fromLTWH(0, 0, 540, 390),
    const Rect.fromLTWH(0, 0, 960, 400),
  ]) {
    test('home projection preserves ground anchors in $viewport', () {
      final camera = BattlePerspectiveCamera(viewport: viewport);
      final foot = Offset(viewport.width * .28, viewport.height * .88);
      final ground = camera.groundAt(foot);
      final result = camera.project(ground);
      expect(result.position.dx, closeTo(foot.dx, .001));
      expect(result.position.dy, closeTo(foot.dy, .001));
      expect(camera.billboardAt(foot).scale, closeTo(1, .001));
    });

    test('focus changes depth separately and reset restores both actors', () {
      final camera = BattlePerspectiveCamera(viewport: viewport);
      final player = Offset(viewport.width * .28, viewport.height * .88);
      final enemy = Offset(viewport.width * .75, viewport.height * .55);
      camera.focus(enemy, playerSide: false, durationSeconds: .4);
      camera.update(.2);
      final near = camera.billboardAt(player);
      final far = camera.billboardAt(enemy);
      expect(near.position, isNot(player));
      expect(far.position, isNot(enemy));
      expect((near.scale - far.scale).abs(), greaterThan(.01));
      camera.update(2);
      expect(camera.isMoving, isFalse);
      final settled = camera.billboardAt(enemy);
      camera.update(10);
      expect(camera.billboardAt(enemy).position, settled.position);
      camera.reset(durationSeconds: .3);
      camera.update(.3);
      expect(camera.isHome, isTrue);
      expect(camera.billboardAt(enemy).position.dx, closeTo(enemy.dx, .001));
      expect(camera.billboardAt(player).scale, closeTo(1, .001));
    });
  }

  test('camera trajectory is independent of display refresh rate', () {
    BattlePerspectiveCamera camera() => BattlePerspectiveCamera(
      viewport: const Rect.fromLTWH(0, 0, 390, 430),
    )..focus(const Offset(292, 236), playerSide: false, durationSeconds: .4);
    final slow = camera();
    final fast = camera();
    for (var i = 0; i < 12; i++) {
      slow.update(1 / 30);
    }
    for (var i = 0; i < 48; i++) {
      fast.update(1 / 120);
    }
    expect(slow.eye.distanceTo(fast.eye), lessThan(.0001));
    expect(slow.isMoving, isFalse);
    expect(fast.isMoving, isFalse);
  });
}

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/battle_projection_contract.dart';
import 'package:map_render_3d/src/battle_stage_camera.dart';

void main() {
  test('unconfigured camera starts with a finite usable projection', () {
    final camera = BattleStageCamera();
    expect(
      camera.viewProjectionMatrix.storage.every((value) => value.isFinite),
      isTrue,
    );
    final projected = camera.project(Model3dVector3(x: 0, y: 0, z: -1))!;
    expect(projected.dx, closeTo(.5, 1e-7));
    expect(projected.dy, closeTo(.55, 1e-7));
  });

  test('GPU rejects invalid frames atomically and reports the rejection', () {
    final camera = BattleStageCamera();
    final eye = Model3dVector3(x: 1, y: 2, z: 10);
    final aim = Model3dVector3(x: 0, y: 1, z: 0);
    const size = Size(390, 430);
    expect(
      camera.setFrame(eye: eye, aim: aim, size: size, focalLength: 585),
      isTrue,
    );
    final projection = camera.viewProjectionMatrix.clone();
    for (final center in [
      const Offset(double.nan, 0),
      const Offset(0, double.infinity),
    ]) {
      expect(
        camera.setFrame(
          eye: aim,
          aim: eye,
          size: size,
          focalLength: 200,
          projectionCenter: center,
        ),
        isFalse,
      );
      expect(camera.frameSize, size);
      expect(camera.focal, 585);
      expect(camera.principalPoint, isNull);
      expect(
        camera.viewProjectionMatrix.storage,
        orderedEquals(projection.storage),
      );
    }
    expect(
      camera.setFrame(
        eye: Model3dVector3(x: 1e300, y: 0, z: 0),
        aim: aim,
        size: size,
        focalLength: 585,
      ),
      isFalse,
    );
    expect(
      camera.viewProjectionMatrix.storage,
      orderedEquals(projection.storage),
    );
  });

  test(
    'camera rejects exact depth planes and keeps the actual nearby depth',
    () {
      final camera = BattleStageCamera();
      for (final depth in [
        BattleProjectionContract.near,
        BattleProjectionContract.far,
      ]) {
        expect(camera.project(Model3dVector3(x: 0, y: 0, z: -depth)), isNull);
      }
      expect(camera.project(Model3dVector3(x: 0, y: 0, z: -.1)), isNotNull);
      expect(BattleProjectionContract.containsDepth(.01), isFalse);
      expect(BattleProjectionContract.containsDepth(.1), isTrue);
      expect(BattleProjectionContract.containsDepth(1000), isFalse);
    },
  );
}

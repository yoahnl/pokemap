import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/battle_stage_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';

void main() {
  const viewport = Rect.fromLTWH(12, 24, 390, 430);
  BattlePerspectiveCamera camera() =>
      BattlePerspectiveCamera(viewport: viewport);

  test('constructor rejects unusable initial viewports', () {
    for (final invalid in [
      Rect.zero,
      const Rect.fromLTWH(0, 0, -1, 430),
      const Rect.fromLTWH(0, 0, double.infinity, 430),
      const Rect.fromLTWH(double.nan, 0, 390, 430),
    ]) {
      expect(
        () => BattlePerspectiveCamera(viewport: invalid),
        throwsArgumentError,
      );
    }
  });

  test(
    'transient invalid resize retains the last valid viewport and focal',
    () {
      final subject = camera();
      final focal = subject.focal;
      for (final invalid in [
        Rect.zero,
        const Rect.fromLTWH(0, 0, double.nan, 430),
        const Rect.fromLTWH(0, 0, 390, double.infinity),
      ]) {
        subject.viewport = invalid;
        expect(subject.viewport, viewport);
        expect(subject.focal, focal);
      }
    },
  );

  test(
    'invalid goals and durations are rejected before mutating animation',
    () {
      final subject = camera();
      subject.focus(
        const Offset(120, 390),
        playerSide: true,
        durationSeconds: .4,
      );
      subject.update(.1);
      final eye = subject.eye;
      final aim = subject.aim;
      for (final goal in [
        (eye: const BattleCameraPoint(double.nan, 1, 2), aim: aim),
        (eye: eye, aim: eye),
        (eye: eye, aim: eye + const BattleCameraPoint(0, 1, 0)),
        (eye: const BattleCameraPoint(double.infinity, 1, 2), aim: aim),
      ]) {
        expect(
          () =>
              subject.moveTo(eye: goal.eye, aim: goal.aim, durationSeconds: .4),
          throwsArgumentError,
        );
        expect(subject.eye, same(eye));
        expect(subject.aim, same(aim));
        expect(subject.isMoving, isTrue);
      }
      for (final duration in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => subject.reset(durationSeconds: duration),
          throwsArgumentError,
        );
      }
    },
  );

  test('strict projection rejects behind, near, far and nonfinite points', () {
    final subject = camera();
    final forward = (subject.aim - subject.eye).normalized;
    for (final depth in [-1.0, 0.0, .005, 1001.0]) {
      expect(
        () => subject.project(subject.eye + forward * depth),
        throwsStateError,
        reason: 'depth $depth must not be clamped into the visible volume',
      );
    }
    expect(
      () => subject.project(const BattleCameraPoint(double.nan, 0, 0)),
      throwsStateError,
    );
    expect(
      subject.project(subject.eye + forward * .1).depth,
      closeTo(.1, 1e-10),
    );
  });

  test(
    'ground inverse rejects horizontal and sky rays instead of inventing land',
    () {
      final subject = camera();
      final horizon = Offset(viewport.center.dx, subject.groundHorizonY);
      expect(() => subject.groundAt(horizon), throwsStateError);
      expect(
        () => subject.groundAt(horizon - const Offset(0, 1)),
        throwsStateError,
      );
      expect(
        () => subject.groundAt(const Offset(double.nan, 0)),
        throwsStateError,
      );
      final screen = Offset(viewport.center.dx, viewport.bottom);
      final ground = subject.groundAt(screen);
      expect(ground.y, closeTo(0, 1e-10));
      expect(
        (subject.project(ground).position - screen).distance,
        lessThan(1e-8),
      );
    },
  );

  test('GPU frame rejection preserves the whole last valid frame', () {
    final subject = BattleStageCamera();
    final eye = Model3dVector3(x: 6.7, y: 6.7, z: 17.3);
    final aim = Model3dVector3(x: 0, y: 2.6, z: 0);
    subject.setFrame(eye: eye, aim: aim, size: viewport.size, focalLength: 585);
    final matrix = subject.viewProjectionMatrix.clone();
    for (final invalid in [
      (eye: eye, aim: eye, size: viewport.size, focal: 585.0),
      (eye: eye, aim: aim, size: Size.zero, focal: 585.0),
      (eye: eye, aim: aim, size: viewport.size, focal: 0.0),
      (eye: eye, aim: aim, size: viewport.size, focal: double.nan),
      (
        eye: eye,
        aim: Model3dVector3(x: 6.7, y: 0, z: 17.3),
        size: viewport.size,
        focal: 585.0,
      ),
    ]) {
      subject.setFrame(
        eye: invalid.eye,
        aim: invalid.aim,
        size: invalid.size,
        focalLength: invalid.focal,
      );
      expect(
        subject.viewProjectionMatrix.storage,
        orderedEquals(matrix.storage),
      );
    }
  });

  test('GPU point projection follows near and far clipping', () {
    final subject = BattleStageCamera();
    subject.setFrame(
      eye: Model3dVector3(x: 0, y: 0, z: 0),
      aim: Model3dVector3(x: 0, y: 0, z: -1),
      size: viewport.size,
      focalLength: 585,
    );
    for (final depth in [-1.0, 0.0, .005, 1001.0]) {
      expect(subject.project(Model3dVector3(x: 0, y: 0, z: -depth)), isNull);
    }
    expect(
      () => Model3dVector3(x: double.nan, y: 0, z: -1),
      throwsFormatException,
    );
    expect(subject.project(Model3dVector3(x: 0, y: 0, z: -.1)), isNotNull);
  });
  test('degenerate intermediate pose keeps the last valid camera frame', () {
    final subject = camera();
    subject.moveTo(
      eye: BattlePerspectiveCamera.homeAim,
      aim: BattlePerspectiveCamera.homeEye,
      durationSeconds: 1,
    );
    subject.update(.375);
    expect(subject.isHome, isTrue);
    expect(subject.isMoving, isFalse);
    final point = subject.project(const BattleCameraPoint(0, 0, 0));
    expect(point.position.dx.isFinite, isTrue);
    expect(point.position.dy.isFinite, isTrue);
  });

  test('nullable primitives and ellipses propagate unavailable geometry', () {
    final subject = camera();
    final sky = Offset(viewport.center.dx, subject.groundHorizonY - 1);
    expect(subject.tryGroundAt(sky), isNull);
    expect(subject.tryBillboardAt(sky), isNull);
    expect(subject.tryBillboardWorldGeometry(sky, viewport), isNull);
    expect(
      subject.groundEllipse(sky, const Size(10, 10)).getBounds(),
      Rect.zero,
    );
    const foot = Offset(120, 390);
    subject.moveTo(
      eye: BattlePerspectiveCamera.homeEye,
      aim:
          BattlePerspectiveCamera.homeEye * 2 - BattlePerspectiveCamera.homeAim,
      durationSeconds: 0,
    );
    expect(subject.tryProject(subject.groundAt(foot)), isNull);
    expect(subject.tryBillboardAt(foot), isNull);
    expect(subject.tryBillboardWorldGeometry(foot, viewport), isNull);
    expect(
      subject.groundEllipse(foot, const Size(10, 10)).getBounds(),
      Rect.zero,
    );
  });

  test(
    'invalid direct pose writes and focus strengths leave the camera intact',
    () {
      final subject = camera();
      expect(() => subject.eye = subject.aim, throwsArgumentError);
      expect(() => subject.aim = subject.eye, throwsArgumentError);
      expect(
        () => subject.focus(
          const Offset(120, 390),
          playerSide: true,
          durationSeconds: .4,
          strength: double.nan,
        ),
        throwsArgumentError,
      );
      expect(subject.isHome, isTrue);
      expect(subject.isMoving, isFalse);
    },
  );

  for (final frame in [
    const Rect.fromLTWH(12, 24, 390, 430),
    const Rect.fromLTWH(10, 5, 844, 390),
  ]) {
    test('CPU and GPU agree on visibility and coordinates for $frame', () {
      final cpu = BattlePerspectiveCamera(viewport: frame);
      final gpu = BattleStageCamera();
      void check() {
        expect(
          gpu.setFrame(
            eye: Model3dVector3(x: cpu.eye.x, y: cpu.eye.y, z: cpu.eye.z),
            aim: Model3dVector3(x: cpu.aim.x, y: cpu.aim.y, z: cpu.aim.z),
            size: Size(frame.right + 18, frame.bottom + 42),
            focalLength: cpu.focal,
            projectionCenter: Offset(
              frame.center.dx,
              frame.top + frame.height * .55,
            ),
          ),
          isTrue,
        );
        final forward = (cpu.aim - cpu.eye).normalized;
        final right = forward
            .cross(const BattleCameraPoint(0, 1, 0))
            .normalized;
        for (final depth in [-5.0, 0.0, .005, .05, .1, 20.0, 999.0, 1001.0]) {
          final point = cpu.eye + forward * depth + right * (depth * .1);
          final expected = cpu.tryProject(point);
          final actual = gpu.project(
            Model3dVector3(x: point.x, y: point.y, z: point.z),
          );
          expect(actual == null, expected == null, reason: 'depth $depth');
          if (actual != null && expected != null) {
            expect(
              (actual - expected.position).distance,
              lessThan(.05),
              reason: 'depth $depth',
            );
          }
        }
      }

      check();
      cpu.focus(
        Offset(frame.left + frame.width * .72, frame.top + frame.height * .66),
        playerSide: false,
        durationSeconds: .4,
      );
      cpu.update(.2);
      check();
      cpu.update(.2);
      check();
    });
  }
  test(
    'CPU and GPU classify adjacent double values at both depth planes equally',
    () {
      final cpu = camera();
      final gpu = BattleStageCamera();
      const eye = BattleCameraPoint(0, 0, 0);
      const aim = BattleCameraPoint(0, 0, -1);
      cpu.moveTo(eye: eye, aim: aim, durationSeconds: 0);
      gpu.setFrame(
        eye: Model3dVector3(x: eye.x, y: eye.y, z: eye.z),
        aim: Model3dVector3(x: aim.x, y: aim.y, z: aim.z),
        size: viewport.size,
        focalLength: cpu.focal,
      );
      for (final depth in [
        .0099999999,
        .01,
        .0100000001,
        999.9999999999,
        1000.0,
        1000.0000000001,
      ]) {
        final expected = depth > .01 && depth < 1000;
        final point = BattleCameraPoint(0, 0, -depth);
        expect(
          cpu.tryProject(point) != null,
          expected,
          reason: 'CPU depth $depth',
        );
        expect(
          gpu.project(Model3dVector3(x: 0, y: 0, z: -depth)) != null,
          expected,
          reason: 'GPU helper depth $depth',
        );
      }
    },
  );
}

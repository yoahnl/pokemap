import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_camera_projection.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';

Future<BattleSplStaticPlayback> playback({
  bool follows = true,
  bool child = false,
  int childDelay = 0,
}) async {
  final value = jsonDecode(
    await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
  ) as Map<String, dynamic>;
  final emitter = (value['emitters'] as List).single as Map<String, dynamic>;
  final emission = emitter['emission'] as Map<String, dynamic>;
  emission['followEmitter'] = follows;
  if (child) {
    emission['duration'] = 1;
    emitter['child'] = {
      'velocityRatio': 0,
      'randomVelocityMagnitude': 0,
      'scaleRatio': 64,
      'color': {'red': 0, 'green': 31, 'blue': 0},
      'rotation': 'none',
      'lifetime': 4,
      'texture': 'spark',
      'emissionCount': 1,
      'emissionDelay': childDelay,
      'emissionInterval': 1,
      'fadeAlpha': false,
    };
  }
  final result = BattleSplStaticAdmission.prepare(
    definition: BattleSplParticleDefinition.fromJson(value),
    textureIndices: {'tex': 0, if (child) 'spark': 1},
    emitters: const [
      BattleSplStaticEmitter(
        emitterIndex: 0,
        startTick: 0,
        position: (x: 0, y: 0, z: 0),
      ),
    ],
    seed: 0,
    poolCapacity: 16,
    maxTicks: 80,
  );
  return result.playback!;
}

Future<ui.Image> redImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xffff0000),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(2, 2);
  } finally {
    picture.dispose();
  }
}

Future<ui.Image> greenImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xff00ff00),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(2, 2);
  } finally {
    picture.dispose();
  }
}

BattleSplCameraProjection cameraProjection(
  BattlePerspectiveCamera camera,
  ui.Offset? Function() resolveFoot,
) => BattleSplCameraProjection(
  camera: camera,
  bindings: [
    BattleSplCameraBinding(
      resolveNeutralFoot: resolveFoot,
      resolveAnchor: () {
        final foot = resolveFoot();
        if (foot == null) return null;
        final projected = camera.tryBillboardAt(foot);
        return projected == null
            ? null
            : Vector2(projected.position.dx, projected.position.dy);
      },
    ),
  ],
);

Future<bool> hasRedPixels(BattleSplStaticComponent component) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(32, 32);
  try {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    for (var i = 0; i < bytes.length; i += 4) {
      if (bytes[i] > 0 && bytes[i + 3] > 0) return true;
    }
    return false;
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<ui.Offset> redCentroid(
  BattleSplStaticComponent component, {
  int channel = 0,
  int width = 390,
  int height = 844,
}) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    var xSum = 0;
    var ySum = 0;
    var count = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        if (bytes[offset + channel] != 0 && bytes[offset + 3] != 0) {
          xSum += x;
          ySum += y;
          count++;
        }
      }
    }
    expect(count, greaterThan(0));
    return ui.Offset(xSum / count, ySum / count);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders admitted particles and notifies completion once', () async {
    final effect = await playback();
    final source = await redImage();
    var complete = 0;
    final failures = <BattleSplAdmissionFailure>[];
    final created = <ui.Image>[];
    final disposed = <ui.Image>[];
    final previousCreate = ui.Image.onCreate;
    final previousDispose = ui.Image.onDispose;
    ui.Image.onCreate = created.add;
    ui.Image.onDispose = disposed.add;
    final component = BattleSplStaticComponent(
      playback: effect,
      textures: {0: source},
      origin: const ui.Offset(12, 12),
      pixelsPerUnit: 4,
      onComplete: () => complete++,
      onFailure: failures.add,
    );
    final ownedImage = created.single;
    source.dispose();
    addTearDown(() {
      component.dispose();
      ui.Image.onCreate = previousCreate;
      ui.Image.onDispose = previousDispose;
    });
    expect(await hasRedPixels(component), isFalse);
    component.update(1 / 60);
    expect(await hasRedPixels(component), isTrue);
    for (var i = 0; i < 80 && !effect.isComplete; i++) {
      component.update(1 / 60);
    }
    expect(effect.isComplete, isTrue);
    expect(effect.activeParticles, 0);
    expect(failures, isEmpty);
    expect(complete, 1);
    expect(
      disposed.where((image) => identical(image, ownedImage)),
      hasLength(1),
    );
    component.update(1);
    expect(complete, 1);
  });

  test(
    'bounds catch-up work and releases images and particles on cancel',
    () async {
      final effect = await playback();
      final source = await redImage();
      var complete = 0;
      final created = <ui.Image>[];
      final disposed = <ui.Image>[];
      final previousCreate = ui.Image.onCreate;
      final previousDispose = ui.Image.onDispose;
      ui.Image.onCreate = created.add;
      ui.Image.onDispose = disposed.add;
      addTearDown(() {
        ui.Image.onCreate = previousCreate;
        ui.Image.onDispose = previousDispose;
      });
      final component = BattleSplStaticComponent(
        playback: effect,
        textures: {0: source},
        origin: const ui.Offset(12, 12),
        pixelsPerUnit: 4,
        onComplete: () => complete++,
        onFailure: (_) => fail('unexpected playback failure'),
        maxTicksPerUpdate: 1,
      );
      final ownedImage = created.single;
      source.dispose();
      component.update(1);
      expect(effect.tick, 1);
      expect(effect.activeParticles, greaterThan(0));
      component.update(0);
      expect(effect.tick, 2);
      component.cancel();
      expect(effect.activeParticles, 0);
      expect(
        disposed.where((image) => identical(image, ownedImage)),
        hasLength(1),
      );
      component.update(1);
      expect(complete, 0);
      component.dispose();
      component.dispose();
      expect(
        disposed.where((image) => identical(image, ownedImage)),
        hasLength(1),
      );
    },
  );

  test('rejects missing textures without consuming the caller image', () async {
    final effect = await playback();
    final source = await redImage();
    expect(
      () => BattleSplStaticComponent(
        playback: effect,
        textures: {1: source},
        origin: const ui.Offset(12, 12),
        pixelsPerUnit: 4,
        onComplete: () {},
        onFailure: (_) {},
      ),
      throwsFormatException,
    );
    expect(source.width, 2);
    effect.cancel();
    source.dispose();
  });

  test('projects a particle when the real battle camera moves', () async {
    final camera = BattlePerspectiveCamera(
      viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
    );
    const foot = ui.Offset(190, 600);
    const relativeAnchor = ui.Offset(0, -20);
    final beforeProjection = camera.billboardAt(foot);
    final beforeAnchor =
        beforeProjection.position + relativeAnchor * beforeProjection.scale;
    final projection = BattleSplCameraProjection(
      camera: camera,
      bindings: [
        BattleSplCameraBinding(
          resolveNeutralFoot: () => foot,
          resolveAnchor: () {
            final billboard = camera.tryBillboardAt(foot);
            if (billboard == null) return null;
            final point = billboard.position + relativeAnchor * billboard.scale;
            return Vector2(point.dx, point.dy);
          },
        ),
      ],
    );
    final effect = await playback();
    final source = await redImage();
    final component = BattleSplStaticComponent(
      playback: effect,
      textures: {0: source},
      origin: ui.Offset.zero,
      pixelsPerUnit: 12,
      projection: projection,
      onComplete: () {},
      onFailure: (_) => fail('unexpected playback failure'),
    );
    source.dispose();
    addTearDown(component.dispose);
    component.update(1 / 60);
    final before = await redCentroid(component);
    camera.moveTo(
      eye: camera.eye + const BattleCameraPoint(4, 0, 0),
      aim: camera.aim,
      durationSeconds: .2,
    );
    camera.update(.2);
    expect(component.refreshAttachment(), isTrue);
    final afterProjection = camera.billboardAt(foot);
    final afterAnchor =
        afterProjection.position + relativeAnchor * afterProjection.scale;
    expect((afterAnchor - beforeAnchor).distance, greaterThan(5));
    final expected =
        afterAnchor +
        (before - beforeAnchor) *
            (afterProjection.scale / beforeProjection.scale);
    final after = await redCentroid(component);
    expect((after - expected).distance, lessThan(3));
  });

  for (final follows in [true, false]) {
    test(
      'particles ${follows ? 'follow' : 'remain at'} their emission anchor',
      () async {
        final camera = BattlePerspectiveCamera(
          viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
        );
        var foot = const ui.Offset(150, 600);
        final effect = await playback(follows: follows);
        final image = await redImage();
        final component = BattleSplStaticComponent(
          playback: effect,
          textures: {0: image},
          origin: ui.Offset.zero,
          pixelsPerUnit: 12,
          projection: cameraProjection(camera, () => foot),
          onComplete: () {},
          onFailure: (_) => fail('unexpected projection failure'),
        );
        image.dispose();
        addTearDown(component.dispose);
        component.update(1 / 60);
        final before = await redCentroid(component);
        final emissionFoot = foot;
        foot += const ui.Offset(40, 0);
        expect(component.refreshAttachment(), isTrue);
        final after = await redCentroid(component);
        expect(after.dx - before.dx, closeTo(follows ? 40 : 0, 2));
        if (!follows) {
          final originalProjection = camera.billboardAt(emissionFoot);
          camera.moveTo(
            eye: camera.eye + const BattleCameraPoint(4, 0, 0),
            aim: camera.aim,
            durationSeconds: .2,
          );
          camera.update(.2);
          expect(component.refreshAttachment(), isTrue);
          final movedProjection = camera.billboardAt(emissionFoot);
          final expected =
              movedProjection.position +
              (after - originalProjection.position) *
                  (movedProjection.scale / originalProjection.scale);
          final afterCamera = await redCentroid(component);
          expect((afterCamera - expected).distance, lessThan(3));
        }
      },
    );
  }

  test(
    'a detached child inherits its detached parent emission anchor',
    () async {
      final camera = BattlePerspectiveCamera(
        viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
      );
      const originalFoot = ui.Offset(150, 600);
      var foot = originalFoot;
      final effect = await playback(
        follows: false,
        child: true,
        childDelay: 64,
      );
      final red = await redImage();
      final green = await greenImage();
      final component = BattleSplStaticComponent(
        playback: effect,
        textures: {0: red, 1: green},
        origin: ui.Offset.zero,
        pixelsPerUnit: 12,
        projection: cameraProjection(camera, () => foot),
        onComplete: () {},
        onFailure: (_) => fail('unexpected projection failure'),
      );
      red.dispose();
      green.dispose();
      addTearDown(component.dispose);
      component.update(1 / 60);
      foot += const ui.Offset(60, 0);
      component.update(1 / 60);
      final child = await redCentroid(component, channel: 1);
      expect((child - originalFoot).distance, lessThan(20));
      expect((child - foot).distance, greaterThan(40));
    },
  );

  test(
    'an invalidated anchor stops playback and reports failure once',
    () async {
      final camera = BattlePerspectiveCamera(
        viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
      );
      ui.Offset? foot = const ui.Offset(150, 600);
      final effect = await playback();
      final image = await redImage();
      final failures = <BattleSplAdmissionFailure>[];
      var complete = 0;
      final component = BattleSplStaticComponent(
        playback: effect,
        textures: {0: image},
        origin: ui.Offset.zero,
        pixelsPerUnit: 12,
        projection: cameraProjection(camera, () => foot),
        onComplete: () => complete++,
        onFailure: failures.add,
      );
      image.dispose();
      addTearDown(component.dispose);
      component.update(1 / 60);
      expect(effect.activeParticles, greaterThan(0));
      foot = null;
      expect(component.refreshAttachment(), isFalse);
      expect(component.refreshAttachment(), isFalse);
      expect(effect.activeParticles, 0);
      expect(failures, [BattleSplAdmissionFailure.projectionUnavailable]);
      expect(complete, 0);
    },
  );

  test(
    'a detached particle keeps its world position when the viewport changes',
    () async {
      final camera = BattlePerspectiveCamera(
        viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
      );
      var foot = const ui.Offset(190, 550);
      final originalFoot = foot;
      final ground = camera.groundAt(foot);
      final worldUnit = camera
          .billboardWorldGeometry(
            foot,
            ui.Rect.fromLTWH(foot.dx - .5, foot.dy - 1, 1, 1),
          )
          .width;
      final effect = await playback(follows: false);
      final image = await redImage();
      final component = BattleSplStaticComponent(
        playback: effect,
        textures: {0: image},
        origin: ui.Offset.zero,
        pixelsPerUnit: 12,
        projection: cameraProjection(camera, () => foot),
        onComplete: () {},
        onFailure: (_) => fail('unexpected projection failure'),
      );
      image.dispose();
      addTearDown(component.dispose);
      component.update(1 / 60);
      final before = await redCentroid(component);
      camera.viewport = const ui.Rect.fromLTWH(0, 0, 844, 390);
      foot = const ui.Offset(400, 330);
      expect(component.refreshAttachment(), isTrue);
      final projected = camera.project(ground);
      final scale = camera.focal * worldUnit / projected.depth;
      final expected = projected.position + (before - originalFoot) * scale;
      final after = await redCentroid(component, width: 844, height: 390);
      expect((after - expected).distance, lessThan(3));
    },
  );

  test(
    'a detached particle retains its elevated world anchor as the camera turns',
    () async {
      final camera = BattlePerspectiveCamera(
        viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
      );
      const foot = ui.Offset(190, 550);
      const relativeAnchor = ui.Offset(0, -80);
      final geometry = camera.billboardWorldGeometry(
        foot,
        ui.Rect.fromLTWH(
          foot.dx + relativeAnchor.dx - .5,
          foot.dy + relativeAnchor.dy - 1,
          1,
          1,
        ),
      );
      final initialProjection = camera.project(geometry.position);
      final initialScale =
          camera.focal * geometry.width / initialProjection.depth;
      final projection = BattleSplCameraProjection(
        camera: camera,
        bindings: [
          BattleSplCameraBinding(
            resolveNeutralFoot: () => foot,
            resolveAnchor: () {
              final billboard = camera.tryBillboardAt(foot);
              if (billboard == null) return null;
              final anchor =
                  billboard.position + relativeAnchor * billboard.scale;
              return Vector2(anchor.dx, anchor.dy);
            },
          ),
        ],
      );
      final effect = await playback(follows: false);
      final image = await redImage();
      final component = BattleSplStaticComponent(
        playback: effect,
        textures: {0: image},
        origin: ui.Offset.zero,
        pixelsPerUnit: 12,
        projection: projection,
        onComplete: () {},
        onFailure: (_) => fail('unexpected projection failure'),
      );
      image.dispose();
      addTearDown(component.dispose);
      component.update(1 / 60);
      final before = await redCentroid(component);
      camera.moveTo(
        eye: camera.eye + const BattleCameraPoint(4, 2, 0),
        aim: camera.aim,
        durationSeconds: .2,
      );
      camera.update(.2);
      expect(component.refreshAttachment(), isTrue);
      final movedProjection = camera.project(geometry.position);
      final movedScale = camera.focal * geometry.width / movedProjection.depth;
      final expected =
          movedProjection.position +
          (before - initialProjection.position) * (movedScale / initialScale);
      final after = await redCentroid(component);
      expect((after - expected).distance, lessThan(3));
    },
  );
}

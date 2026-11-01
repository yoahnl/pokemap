import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';

Future<BattleSplStaticPlayback> playback() async {
  final value = jsonDecode(
    await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
  );
  final result = BattleSplStaticAdmission.prepare(
    definition: BattleSplParticleDefinition.fromJson(
      value as Map<String, dynamic>,
    ),
    textureIndices: const {'tex': 0},
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
}

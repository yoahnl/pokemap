import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_child_initializer.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_color_texture_animation.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_configured_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_emitter_lifecycle.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_motion.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_pool.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_point_emitter_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_point_preview_painter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_scalar_animation.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_vector.dart';

void main() {
  test('renders all four verified source 218 emitters and their children in a bounded isolated preview', () async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final sourceBytes = await _fetch(
      client,
      'particles.json',
      'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9',
    );
    final source = jsonDecode(utf8.decode(sourceBytes)) as Map<String, dynamic>;
    final emitter =
        (source['emitters'] as List<dynamic>)[0] as Map<String, dynamic>;
    final secondEmitter =
        (source['emitters'] as List<dynamic>)[1] as Map<String, dynamic>;
    final impactEmitter =
        (source['emitters'] as List<dynamic>)[2] as Map<String, dynamic>;
    final burstEmitter =
        (source['emitters'] as List<dynamic>)[3] as Map<String, dynamic>;

    final textureHashes = <int, String>{
      0: 'd03979b4d9e7cc4146cd28313006fc7e770e8aa83c8bffb06797f8cb5076bab1',
      1: 'a3dbf0ea435572f668f8ba2beb676587036035fdb6989a4583605dfa68d9e06e',
      2: '3d10133124483c7c68bf8ef9df9e50d8a2bab9ed4c0f9882b5291ce8bc96260f',
      3: '3eee20e4f1adbc946d4623f42fe12203fcd4919ec23988aa8fb2b932203bf137',
      4: 'ebce49dd55ea712ac46fa7032218fce2e8109062ff6380c55257172d6e0d44f0',
      5: '9c83ad9fe9503947791501b1ecbe2705ccb67564f21e6c7aa26950c338da7e6e',
    };
    final images = <int, ui.Image>{};
    addTearDown(() {
      for (final image in images.values) {
        image.dispose();
      }
    });
    for (final entry in textureHashes.entries) {
      final bytes = await _fetch(
        client,
        'texture0${entry.key}.png',
        entry.value,
      );
      final codec = await ui.instantiateImageCodec(bytes);
      images[entry.key] = (await codec.getNextFrame()).image;
      codec.dispose();
    }

    final random = BattleSplRandom(seed: 0);
    final pool = BattleSplParticlePool(capacity: 64);
    final first = _sourceEmitter(emitter, images, random, pool);
    final second = _sourceEmitter(secondEmitter, images, random, pool);
    final burst = _sourceEmitter(burstEmitter, images, random, pool);
    final impact = _sourceEmitter(impactEmitter, images, random, pool);
    final converted = Gen5SplParticleConverter.convert(
      sourceBytes,
      particleId: 218,
      sourceRevision: '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c',
      sourcePath: 'res/particles/btlv_effvm_particles/218/particles.json',
      expectedSha256:
          'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9',
      textureResourceIds: {
        for (var i = 0; i < 6; i++) 'texture0$i': 'texture0$i',
      },
    );
    final convertedRandom = BattleSplRandom(seed: 0);
    final convertedPool = BattleSplParticlePool(capacity: 64);
    final configured = [
      for (final definition in converted.definition.emitters)
        BattleSplConfiguredEmitter(
          definition: definition,
          textureIndices: {for (var i = 0; i < 6; i++) 'texture0$i': i},
          random: convertedRandom,
          pool: convertedPool,
        ),
    ];
    addTearDown(() {
      for (final emitter in configured) {
        emitter.cancel();
      }
      for (final playback in [
        first.playback,
        second.playback,
        impact.playback,
        burst.playback,
      ]) {
        playback.cancel();
      }
    });
    final capture = Platform.environment['AVELUNE_SPL_PREVIEW_CAPTURE'] == '1';
    Directory? directory;
    String? captureOutput;
    if (capture) {
      final rootPath = Platform.environment['AVELUNE_SPL_PREVIEW_QA_DIR'];
      if (rootPath == null) {
        throw StateError('AVELUNE_SPL_PREVIEW_QA_DIR is required for capture');
      }
      final root = Directory(rootPath);
      if (!root.isAbsolute || !await root.exists()) {
        throw StateError('The SPL preview QA directory must already exist');
      }
      final resolved = await root.resolveSymbolicLinks();
      if (Platform.isMacOS) {
        final allowed = await Directory('/Users/karim/Library/Caches/AveluneQA')
            .resolveSymbolicLinks();
        if (!resolved.startsWith('$allowed/')) {
          throw StateError('The SPL preview QA directory is outside AveluneQA');
        }
      }
      directory = await Directory(resolved).createTemp('frames-');
      addTearDown(() => directory!.delete(recursive: true));
      captureOutput = '${directory.path}.gif';
      if (await File(captureOutput).exists()) {
        throw StateError('The SPL preview capture already exists');
      }
    }
    var changedPixels = 0;
    var impactPixels = 0;
    var childPixels = 0;
    var sawImpactParent = false;
    var sawImpactChild = false;
    for (var tick = 0; tick < 125; tick++) {
      if (tick >= 46) {
        impact.playback.step(managerFrame: tick % 2);
        configured[2].step(
          managerFrame: tick % 2,
          position: (x: 0, y: 0, z: 0),
        );
        burst.playback.step(managerFrame: tick % 2);
        configured[3].step(
          managerFrame: tick % 2,
          position: (x: 0, y: 0, z: 0),
        );
        sawImpactParent |= impact.playback.particles.any(
          (particle) => particle.parentId == null,
        );
        sawImpactChild |= impact.playback.particles.any(
          (particle) => particle.parentId != null,
        );
      }
      second.playback.step(managerFrame: tick % 2);
      configured[1].step(managerFrame: tick % 2, position: (x: 0, y: 0, z: 0));
      first.playback.step(managerFrame: tick % 2);
      configured[0].step(managerFrame: tick % 2, position: (x: 0, y: 0, z: 0));
      final originals = [
        first.playback,
        second.playback,
        impact.playback,
        burst.playback,
      ];
      for (var i = 0; i < originals.length; i++) {
        expect(
          _particleState(configured[i].playback),
          _particleState(originals[i]),
          reason: 'emitter $i, tick $tick',
        );
      }
      if (tick == 0) {
        expect(first.playback.particles, hasLength(1));
        expect(second.playback.particles, hasLength(1));
        expect(first.playback.particles.single.texture, 1);
        expect(second.playback.particles.single.texture, 4);
        expect(pool.inUse, 2);
      }
      if (!capture && tick != 20 && tick != 60) continue;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 480, 160),
        ui.Paint()..color = const ui.Color(0xff10131d),
      );
      if (tick >= 46) {
        impact.painter.paint(
          canvas,
          origin: const ui.Offset(330, 100),
          particles: impact.playback.particles,
        );
        burst.painter.paint(
          canvas,
          origin: const ui.Offset(330, 100),
          particles: burst.playback.particles,
        );
      }
      second.painter.paint(
        canvas,
        origin: const ui.Offset(35, 110),
        particles: second.playback.particles,
      );
      first.painter.paint(
        canvas,
        origin: const ui.Offset(35, 110),
        particles: first.playback.particles,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(480, 160);
      picture.dispose();
      if (tick == 20) {
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final bytes = pixels.buffer.asUint8List();
        for (var index = 0; index < bytes.length; index += 4) {
          if (bytes[index] != 16 ||
              bytes[index + 1] != 19 ||
              bytes[index + 2] != 29) {
            changedPixels++;
          }
        }
      }
      if (tick == 60) {
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final bytes = pixels.buffer.asUint8List();
        for (var y = 0; y < 160; y++) {
          for (var x = 280; x < 480; x++) {
            final index = (y * 480 + x) * 4;
            if (bytes[index] != 16 ||
                bytes[index + 1] != 19 ||
                bytes[index + 2] != 29) {
              impactPixels++;
            }
          }
        }
        final childRecorder = ui.PictureRecorder();
        impact.painter.paint(
          ui.Canvas(childRecorder),
          origin: const ui.Offset(330, 100),
          particles: impact.playback.particles
              .where((particle) => particle.parentId != null)
              .toList(growable: false),
        );
        final childPicture = childRecorder.endRecording();
        final childImage = await childPicture.toImage(480, 160);
        childPicture.dispose();
        final childData = (await childImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final childBytes = childData.buffer.asUint8List();
        for (var index = 3; index < childBytes.length; index += 4) {
          if (childBytes[index] != 0) childPixels++;
        }
        childImage.dispose();
      }
      if (capture) {
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File(
          '${directory!.path}/frame_${tick.toString().padLeft(3, '0')}.png',
        ).writeAsBytes(png.buffer.asUint8List());
      }
      image.dispose();
    }
    expect(changedPixels, greaterThan(100));
    expect(impactPixels, greaterThan(10));
    expect(childPixels, greaterThan(0));
    expect(first.playback.isComplete, isTrue);
    expect(second.playback.isComplete, isTrue);
    expect(burst.playback.isComplete, isTrue);
    expect(impact.playback.isComplete, isTrue);
    expect(sawImpactParent, isTrue);
    expect(sawImpactChild, isTrue);
    expect(pool.inUse, 0);
    expect(configured.every((emitter) => emitter.playback.isComplete), isTrue);
    expect(convertedPool.inUse, 0);
    if (capture) {
      final result = await Process.run('ffmpeg', [
        '-n',
        '-hide_banner',
        '-loglevel',
        'error',
        '-framerate',
        '30',
        '-i',
        '${directory!.path}/frame_%03d.png',
        '-filter_complex',
        '[0:v]scale=960:320:flags=neighbor,split[a][b];'
            '[a]palettegen[p];[b][p]paletteuse=dither=none',
        '-loop',
        '0',
        captureOutput!,
      ]);
      if (result.exitCode != 0) {
        final partial = File(captureOutput);
        if (await partial.exists()) await partial.delete();
        fail('Capture failed: ${result.stdout}\n${result.stderr}');
      }
      stdout.writeln('SPL_PREVIEW_CAPTURE=$captureOutput');
    }
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');
}

List<List<Object?>> _particleState(BattleSplPointEmitterPlayback playback) => [
  for (final particle in playback.particles)
    [
      particle.id,
      particle.parentId,
      particle.motion.position,
      particle.motion.velocity,
      particle.motion.rotation,
      particle.motion.angularVelocity,
      particle.emitterPosition,
      particle.baseScale4096,
      particle.baseAlpha5,
      particle.animatedAlpha5,
      particle.scale4096,
      particle.color,
      particle.alpha5,
      particle.texture,
    ],
];

({BattleSplPointEmitterPlayback playback, BattleSplPointPreviewPainter painter})
_sourceEmitter(
  Map<String, dynamic> emitter,
  Map<int, ui.Image> images,
  BattleSplRandom random,
  BattleSplParticlePool pool,
) {
  final spherical = emitter['emissionType'] == 'sphere_surface';
  expect(emitter['emissionType'], spherical ? 'sphere_surface' : 'point');
  expect(
    emitter['drawType'],
    spherical ? 'directional_billboard' : 'billboard',
  );
  expect(emitter['scaleAnimDir'], spherical ? 'x' : 'xy');
  expect(emitter['lifeTimeVariance'], 0);
  expect(emitter['scaleVariance'], spherical ? 51 : 0);
  expect(emitter['velocityVariance'], 0);
  expect(emitter['initVelPositionAmplifier'], 0);
  expect(emitter['hasRotation'], isFalse);
  expect(emitter['randomInitAngle'], !spherical);
  expect(emitter['randomLoopOffset'], isFalse);
  expect(emitter.keys.where((key) => key.endsWith('Behavior')), [
    'gravityBehavior',
  ]);
  final scale = emitter['scaleAnim'] as Map<String, dynamic>;
  final color = emitter['colorAnim'] as Map<String, dynamic>;
  final alpha = emitter['alphaAnim'] as Map<String, dynamic>;
  final texture = emitter['textureAnim'] as Map<String, dynamic>?;
  final textureNames = texture == null
      ? [emitter['texture'] as String]
      : (texture['textures'] as List<dynamic>).cast<String>();
  final textureIds = textureNames
      .map((value) => int.parse(value.substring('texture'.length)))
      .toList(growable: false);
  final gravity =
      (emitter['gravityBehavior'] as Map<String, dynamic>)['magnitude']
          as Map<String, dynamic>;
  final axis = emitter['axis'] as Map<String, dynamic>;
  final velocity = emitter['initVelAxisAmplifier'] as int;
  final child = emitter['childResource'] as Map<String, dynamic>?;
  if (child != null) {
    expect(child['hasBehaviors'], isFalse);
    expect(child['hasScaleAnim'], isFalse);
    expect(child['hasAlphaAnim'], isTrue);
    expect(child['followEmitter'], isFalse);
    expect(child['useChildColor'], isTrue);
    expect(child['rotationType'], 'angle_and_velocity');
    expect(child['texture'], 'texture05');
  }
  expect(color['randomStart'], isFalse);
  if (texture != null) expect(texture['randomStart'], isFalse);
  expect(alpha['randomRange'], 0);

  final playback = BattleSplPointEmitterPlayback(
    lifecycle: BattleSplEmitterLifecycle(
      emitterLifetime: emitter['emitterLifeTime'] as int,
      emissionInterval: emitter['emissionInterval'] as int,
      emissionRate4096: emitter['emissionCount'] as int,
      particleLifetime: emitter['particleLifeTime'] as int,
      particleLifetimeVariance: emitter['lifeTimeVariance'] as int,
      maxParticles: 64,
      particlePool: pool,
      startDelay: emitter['startDelay'] as int,
      autoTerminate: emitter['autoTerminate'] as bool,
      captureEvents: true,
      child: child == null
          ? null
          : BattleSplChildTiming(
              emissionCount: child['emissionCount'] as int,
              emissionDelay256: child['emissionDelay'] as int,
              emissionInterval: child['emissionInterval'] as int,
              lifetime: child['lifeTime'] as int,
            ),
    ),
    loopTime: emitter['loopTime'] as int,
    gravity: _vector(gravity),
    emitterVelocity: (x: 0, y: 0, z: 0),
    airResistance: emitter['airResistance'] as int,
    initialTexture: textureIds.first,
    initializeParent: (_) {
      final position = spherical
          ? BattleSplVectorMath.sphereSurface(
              random,
              radius: emitter['radius'] as int,
            )
          : (x: 0, y: 0, z: 0);
      random.vary(0, variance: 0);
      final speed = random.vary(velocity, variance: 0);
      if (!spherical) BattleSplVectorMath.randomUnitVector(random);
      final initialScale = random.vary(
        emitter['baseScale'] as int,
        variance: emitter['scaleVariance'] as int,
      );
      final rotation = spherical
          ? emitter['initAngle'] as int
          : random.next() & 65535;
      random.next();
      return (
        motion: BattleSplParticleMotion(
          position: position,
          velocity: (
            x: ((axis['x'] as int) * speed + 2048) >> 12,
            y: ((axis['y'] as int) * speed + 2048) >> 12,
            z: ((axis['z'] as int) * speed + 2048) >> 12,
          ),
          rotation: rotation,
          angularVelocity: 0,
        ),
        emitterPosition: (x: 0, y: 0, z: 0),
        baseScale4096: initialScale,
      );
    },
    childFadeAlpha: child != null,
    childInitializer: child == null
        ? null
        : (_, parent) => BattleSplChildInitializer.create(
            random: random,
            parentMotion: parent.motion,
            parentEmitterPosition: parent.emitterPosition,
            parentBaseScale: parent.baseScale4096,
            parentAnimatedScale: parent.scale4096,
            parentBaseAlpha: parent.baseAlpha5,
            parentAnimatedAlpha: parent.animatedAlpha5,
            parentColor: parent.color,
            velocityRatio: child['velocityRatio'] as int,
            randomVelocityMagnitude: child['randomInitVelMag'] as int,
            scaleRatio: child['scaleRatio'] as int,
            colorOverride: _color(child['color'] as Map<String, dynamic>),
            rotation: BattleSplChildRotation.angleAndVelocity,
            lifetime: child['lifeTime'] as int,
            texture: 5,
          ),
    scale: BattleSplScalarAnimation(
      start: scale['start'] as int,
      middle: scale['mid'] as int,
      end: scale['end'] as int,
      fadeIn: scale['in'] as int,
      fadeOut: scale['out'] as int,
    ),
    color: BattleSplColorAnimation(
      start: _color(color['start'] as Map<String, dynamic>),
      middle: _color(emitter['color'] as Map<String, dynamic>),
      end: _color(color['end'] as Map<String, dynamic>),
      fadeIn: color['in'] as int,
      peak: color['peak'] as int,
      fadeOut: color['out'] as int,
      interpolate: color['interpolate'] as bool,
    ),
    alpha: BattleSplAlphaAnimation(
      start: alpha['start'] as int,
      middle: alpha['mid'] as int,
      end: alpha['end'] as int,
      fadeIn: alpha['in'] as int,
      fadeOut: alpha['out'] as int,
      randomRange: alpha['randomRange'] as int,
    ),
    texture: BattleSplTextureAnimation(
      textures: textureIds,
      step: texture == null ? 255 : texture['step'] as int,
    ),
    nextAlphaByte: () => random.next() >> 24,
    baseAlpha: emitter['baseAlpha'] as int,
    scaleLoops: scale['loop'] as bool,
    colorLoops: color['loop'] as bool,
    alphaLoops: alpha['loop'] as bool,
    textureLoops: texture == null ? false : texture['loop'] as bool,
  );
  return (
    playback: playback,
    painter: BattleSplPointPreviewPainter(
      textures: images,
      pixelsPerUnit: 12,
      aspectRatio4096: emitter['aspectRatio'] as int,
      directionalParents: spherical,
      scaleAxis: spherical
          ? BattleSplPreviewScaleAxis.x
          : BattleSplPreviewScaleAxis.xy,
    ),
  );
}

BattleSplVector _vector(Map<String, dynamic> value) =>
    (x: value['x'] as int, y: value['y'] as int, z: value['z'] as int);

BattleSplRgb5 _color(Map<String, dynamic> value) => (
  red: value['red'] as int,
  green: value['green'] as int,
  blue: value['blue'] as int,
);

Future<Uint8List> _fetch(HttpClient client, String name, String hash) async {
  const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
  final request = await client
      .getUrl(
        Uri.https(
          'raw.githubusercontent.com',
          '/fuddlesworth/pokebw2/$revision/res/particles/btlv_effvm_particles/218/$name',
        ),
      )
      .timeout(const Duration(seconds: 20));
  request.followRedirects = false;
  final response = await request.close().timeout(const Duration(seconds: 20));
  expect(response.statusCode, HttpStatus.ok);
  final builder = BytesBuilder(copy: false);
  await for (final bytes in response.timeout(const Duration(seconds: 20))) {
    if (builder.length + bytes.length > 64 * 1024) {
      throw const FormatException('SPL preview source exceeds test limit');
    }
    builder.add(bytes);
  }
  final bytes = builder.takeBytes();
  expect(sha256.convert(bytes).toString(), hash);
  return bytes;
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_camera_projection.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_spl_loader.dart';

BattleSplCameraProjection _projection({bool world = false}) {
  final camera = BattlePerspectiveCamera(
    viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
  );
  const foot = ui.Offset(190, 600);
  return BattleSplCameraProjection(
    camera: camera,
    bindings: [
      BattleSplCameraBinding(
        resolveNeutralFoot: () => foot,
        resolveAnchor: () {
          final projected = camera.tryBillboardAt(foot);
          return projected == null
              ? null
              : Vector2(projected.position.dx, projected.position.dy);
        },
      ),
    ],
    worldTransform: world
        ? const BattleSplWorldTransform(worldUnitsPerUnit: .03, yawRadians: 0)
        : null,
  );
}

Future<BattleSplParticleDefinition> _fixture() async =>
    BattleSplParticleDefinition.fromJson(
      jsonDecode(
        await File('../map_core/test/fixtures/spl_particle_v2.json')
            .readAsString(),
      ) as Map<String, dynamic>,
    );

Uint8List _png() =>
    Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));

Future<BattleExperimentalSplPreparation> _create(
  BattleExperimentalSplLoader loader,
  BattleSplParticleDefinition definition,
  Uint8List png, {
  String? expectedHash,
}) => loader.create(
  definition: definition,
  sourceEmitterIndices: const [17],
  textureBytes: {'tex': png},
  textureSha256: {'tex': expectedHash ?? sha256.convert(png).toString()},
  emitters: const [
    BattleSplStaticEmitter(
      emitterIndex: 17,
      startTick: 0,
      position: (x: 0, y: 0, z: 0),
    ),
  ],
  seed: 0,
  poolCapacity: 64,
  maxTicks: 80,
  origin: ui.Offset.zero,
  pixelsPerUnit: 4,
  projection: _projection(),
  onComplete: () {},
  onFailure: (_) => fail('unexpected SPL failure'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'prepares one mapped emitter and releases its owned reservation',
    () async {
      final budget = RuntimeResourceBudget();
      final loader = BattleExperimentalSplLoader(resourceBudget: budget);
      final prepared = await _create(loader, await _fixture(), _png());
      expect(prepared.failure, isNull);
      final component = prepared.component!;
      expect(component.playback.tick, 0);
      expect(component.playback.frames.single.emitterIndex, 0);
      expect(budget.residentBytes, greaterThan(0));
      expect(budget.transientBytes, 0);
      component.update(1 / 60);
      expect(component.playback.tick, 1);
      prepared.dispose();
      prepared.dispose();
      expect(component.playback.isComplete, isTrue);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );

  test('rejects a wrong hash and releases the reservation', () async {
    final budget = RuntimeResourceBudget();
    final loader = BattleExperimentalSplLoader(resourceBudget: budget);
    await expectLater(
      _create(loader, await _fixture(), _png(), expectedHash: '0' * 64),
      throwsFormatException,
    );
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('cancel releases a prepared component and its reservation', () async {
    final budget = RuntimeResourceBudget();
    final loader = BattleExperimentalSplLoader(resourceBudget: budget);
    final prepared = await _create(loader, await _fixture(), _png());
    loader.cancel();
    expect(prepared.component!.playback.isComplete, isTrue);
    expect(budget.residentBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('normal completion releases the component reservation', () async {
    final budget = RuntimeResourceBudget();
    final loader = BattleExperimentalSplLoader(resourceBudget: budget);
    final prepared = await _create(loader, await _fixture(), _png());
    final component = prepared.component!;
    for (var i = 0; i < 80 && !component.playback.isComplete; i++) {
      component.update(1 / 60);
    }
    expect(component.playback.isComplete, isTrue);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('modified bytes while queued fail verification before decode', () async {
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
    );
    final held = await budget.acquire(transientBytes: 1);
    final loader = BattleExperimentalSplLoader(resourceBudget: budget);
    final png = _png();
    final pending = _create(loader, await _fixture(), png);
    await Future<void>.delayed(Duration.zero);
    expect(budget.pendingDecodes, 1);
    png[png.length - 1] ^= 1;
    held.release();
    await expectLater(pending, throwsFormatException);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test(
    'cancel unblocks a queued budget request and releases it when drained',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
      );
      final held = await budget.acquire(transientBytes: 1);
      final loader = BattleExperimentalSplLoader(resourceBudget: budget);
      final pending = _create(loader, await _fixture(), _png());
      await Future<void>.delayed(Duration.zero);
      expect(budget.pendingDecodes, 1);
      loader.cancel();
      await expectLater(pending, throwsStateError);
      held.release();
      await Future<void>.delayed(Duration.zero);
      expect(budget.pendingDecodes, 0);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );

  final qaRoot = Platform.environment['BW2_SOURCE_QA_ROOT'];
  final surfRoot = Platform.environment['AVELUNE_SURF_SOURCE_ROOT'];
  test('renders the five source Surf emitters using their original textures', () async {
    const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
    const sourceHash = '3e191c2e53d6eb9ff35b21e232c3ff8371516d09d4a55e8d0595cd43c149b8cc';
    const hashes = {
      'texture00': '93949a859e9770ad42aa1c728d157cf9d48f55b12bfad45264db1f0989575cae',
      'texture01': '1017acef39e89b4848ee5cbac3342d95100917734a2a60d5e7f312b3dd7bda22',
      'texture02': '0dbb771d83475a2d3a1ee16f6036d1c906bcb70e20e06dc933bdcfe6944763ef',
      'texture03': '627979d1de8f1963b913216ea4dfe2c76fe71993196b679c0c1c00cb4756379a',
    };
    final converted = Gen5SplParticleConverter.convert(
      await File('$surfRoot/particles.json').readAsBytes(),
      particleId: 222,
      sourceRevision: revision,
      sourcePath: 'res/particles/btlv_effvm_particles/222/particles.json',
      expectedSha256: sourceHash,
      textureResourceIds: {for (final id in hashes.keys) id: id},
      experimentalSourceEmitterIndices: const [3, 1, 4, 5, 2],
    );
    final textures = <String, Uint8List>{};
    for (final id in converted.definition.textureIds) {
      textures[id] = await File('$surfRoot/$id.png').readAsBytes();
    }
    for (final entry in {3: 8, 1: 105, 4: 12, 5: 70, 2: 8}.entries) {
      final budget = RuntimeResourceBudget();
      final loader = BattleExperimentalSplLoader(resourceBudget: budget);
      final prepared = await loader.create(
        definition: converted.definition,
        sourceEmitterIndices: converted.sourceEmitterIndices,
        textureBytes: textures,
        textureSha256: {for (final id in textures.keys) id: hashes[id]!},
        emitters: [BattleSplStaticEmitter(
          emitterIndex: entry.key, startTick: 0, position: (x: 0, y: 0, z: 0),
        )],
        seed: 0, poolCapacity: 256, maxTicks: 300,
        origin: ui.Offset.zero, pixelsPerUnit: 4, projection: _projection(world: true),
        onComplete: () {},
        onFailure: (failure) => fail('Surf emitter ${entry.key}: $failure'),
      );
      expect(prepared.failure, isNull, reason: 'Surf emitter ${entry.key}');
      final component = prepared.component!;
      for (var tick = 0; tick < entry.value; tick++) {
        component.update(1 / 60);
      }
      expect(component.playback.activeParticles, greaterThan(0),
          reason: 'Surf emitter ${entry.key}');
      final recorder = ui.PictureRecorder();
      component.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(390, 844);
      try {
        final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        var opaquePixels = 0;
        for (var offset = 3; offset < rgba.lengthInBytes; offset += 4) {
          if (rgba.getUint8(offset) != 0) opaquePixels++;
        }
        expect(opaquePixels, greaterThan(0), reason: 'Surf emitter ${entry.key}');
      } finally {
        image.dispose();
        picture.dispose();
        prepared.dispose();
      }
      expect(budget.residentBytes, 0);
    }
  }, skip: surfRoot == null ? 'AVELUNE_SURF_SOURCE_ROOT not provided' : false);

  test('real source 199 and 220 load emitters zero and one independently', () async {
    const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
    const sourceHashes = {
      199: '0a2edc30e578f3f9d7650d6f3b6916fb673b8a494547d22557e2c5a34915955e',
      220: 'c50300370f0a622a514d45bea7cce595d4794d2197122cdc8ee90cb6c8a0afb1',
    };
    const pngHashes = {
      199: {
        'texture00':
            '93949a859e9770ad42aa1c728d157cf9d48f55b12bfad45264db1f0989575cae',
        'texture01':
            '43f48ed0f5ac422b13287f9ec164825e184a9335dda497ffbc1a38c33f472e85',
        'texture02':
            '93ced19a99ab479e47dc9493885b064ec2f173b6b678b99b7e4c735612f5fd6e',
        'texture03':
            '1b467f4c3e2079b0997af43f43bbc7a0d4d01a983cb924e2cfcea01f7262f80a',
        'texture04':
            'ff3981a5f0a6df5dd2204a5ad560a13e82e13ea2d145324d00585f7448f55c87',
      },
      220: {
        'texture00':
            '435763858fb1c993fab93f50bad385f6fcc54e28387df7dcc6763190ed1e64c0',
        'texture01':
            'ebce49dd55ea712ac46fa7032218fce2e8109062ff6380c55257172d6e0d44f0',
        'texture02':
            '9c83ad9fe9503947791501b1ecbe2705ccb67564f21e6c7aa26950c338da7e6e',
      },
    };
    for (final id in [199, 220]) {
      final dir = Directory('$qaRoot/$id');
      final hashes = pngHashes[id]!;
      final converted = Gen5SplParticleConverter.convert(
        await File('${dir.path}/particles.json').readAsBytes(),
        particleId: id,
        sourceRevision: revision,
        sourcePath: 'res/particles/btlv_effvm_particles/$id/particles.json',
        expectedSha256: sourceHashes[id]!,
        textureResourceIds: {for (final key in hashes.keys) key: key},
        experimentalSourceEmitterIndices: id == 220 ? [0, 1] : null,
      );
      final bytes = <String, Uint8List>{};
      final digests = <String, String>{};
      for (final texture in converted.definition.textureIds) {
        bytes[texture] = await File('${dir.path}/$texture.png').readAsBytes();
        digests[texture] = hashes[texture]!;
      }
      for (final sourceIndex in [0, 1]) {
        final budget = RuntimeResourceBudget();
        final loader = BattleExperimentalSplLoader(resourceBudget: budget);
        final result = await loader.create(
          definition: converted.definition,
          sourceEmitterIndices: converted.sourceEmitterIndices,
          textureBytes: bytes,
          textureSha256: digests,
          emitters: [
            BattleSplStaticEmitter(
              emitterIndex: sourceIndex,
              startTick: 0,
              position: (x: 0, y: 0, z: 0),
            ),
          ],
          seed: 0,
          poolCapacity: 256,
          maxTicks: 300,
          origin: ui.Offset.zero,
          pixelsPerUnit: 4,
          projection: _projection(),
          onComplete: () {},
          onFailure: (failure) =>
              fail('particle $id emitter $sourceIndex: $failure'),
        );
        expect(
          result.failure,
          isNull,
          reason: 'particle $id emitter $sourceIndex',
        );
        final component = result.component!;
        expect(component.playback.tick, 0);
        var maximumParticles = 0;
        for (
          var tick = 0;
          tick < 60 && !component.playback.isComplete;
          tick++
        ) {
          component.update(1 / 60);
          if (component.playback.activeParticles > maximumParticles) {
            maximumParticles = component.playback.activeParticles;
          }
        }
        expect(
          maximumParticles,
          greaterThan(0),
          reason: 'particle $id emitter $sourceIndex',
        );
        result.dispose();
        expect(budget.residentBytes, 0);
        expect(budget.transientBytes, 0);
        expect(budget.activeDecodes, 0);
      }
    }
  }, skip: qaRoot == null ? 'BW2_SOURCE_QA_ROOT not provided' : false);
}

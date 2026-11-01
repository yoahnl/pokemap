import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';

import 'support/load_flame_component.dart';

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const _sourceHashes = {
  'src/ov168/btlv_mcss.c':
      '55c46c84664ab00138426870827c68bdb672117303c86547a5f4c6ecbbb9392c',
  'src/ov168/btlv_effvm.c':
      '66e692fa70cf939d36650acf7e515529b3f83fa10b42135a4e1f7b6b911311b4',
  'src/ov168/btlv_camera.c':
      '5738fa92eaa836e0de5b761fd0cb93319dcd37118f5f9bf04d0f5923c19f6387',
  'res/battle/animations/moves/flamethrower.s':
      '4cec7ed1fd757ee10d8e6f07941cefcd709cbaaac365ecf7782593a5dcc897f9',
  'res/particles/btlv_effvm_particles/218/particles.json':
      'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9',
};

const _sourcePlayer = BattleCameraPoint(
  0x800 / 4096,
  0x666 / 4096,
  0x7000 / 4096,
);
const _sourceEnemy = BattleCameraPoint(
  0x4cd / 4096,
  0x666 / 4096,
  -0xa000 / 4096,
);
const _sourceEmitterOffset = BattleCameraPoint(0, 0x2000 / 4096, 0x500 / 4096);

final class _RealHttpOverrides extends HttpOverrides {}

Future<Map<String, String>> _readPinnedSources() async {
  final client = HttpClient();
  try {
    final result = <String, String>{};
    for (final entry in _sourceHashes.entries) {
      final uri = Uri.https(
        'raw.githubusercontent.com',
        '/fuddlesworth/pokebw2/$_revision/${entry.key}',
      );
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Source returned ${response.statusCode}', uri: uri);
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        if (builder.length + chunk.length > 262144) {
          throw const FormatException('Source exceeds the test budget');
        }
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      expect(sha256.convert(bytes).toString(), entry.value);
      result[entry.key] = utf8.decode(bytes);
    }
    return result;
  } finally {
    client.close(force: true);
  }
}

BattleCameraPoint _lerp(BattleCameraPoint a, BattleCameraPoint b, double t) =>
    a + (b - a) * t;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'pinned BW2 source identifies the camera, anchors and jet axis',
    () async {
      final sources = await HttpOverrides.runWithHttpOverrides(
        _readPinnedSources,
        _RealHttpOverrides(),
      );
      final mcss = sources['src/ov168/btlv_mcss.c']!;
      expect(mcss, contains('{ 0x800, 0x666, 0x7000 }'));
      expect(mcss, contains('{ 0x4cd, 0x666, -0xa000 }'));
      final vm = sources['src/ov168/btlv_effvm.c']!;
      expect(vm, contains('from.z += 0x500;'));
      expect(vm, contains('to.z += 0x500;'));
      expect(vm, contains('param->offset.y = VM_Read32(vm);'));
      expect(vm, contains('VEC_CrossProduct(&vec, &flat, &rotAxis);'));
      expect(vm, contains('ParticleEmitter_SetAxis(emitter, &emitterAxis);'));
      expect(vm, contains('work->frames = param->motionFrames >> FX32_SHIFT;'));
      expect(vm, contains('if (work->frames != 0 && type != 0)'));
      final camera = sources['src/ov168/btlv_camera.c']!;
      expect(
        camera,
        contains('FX32_CONST(6.7), FX32_CONST(6.7), FX32_CONST(17.3)'),
      );
      expect(camera, contains('{ 0, FX32_CONST(2.6), 0 }'));
      final script = sources['res/battle/animations/moves/flamethrower.s']!;
      expect(
        script,
        contains(
          'EmitterMove 218, 0, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0, 0, 0x1000, 0x1000, 0',
        ),
      );
      final particle = jsonDecode(
        sources['res/particles/btlv_effvm_particles/218/particles.json']!,
      ) as Map<String, dynamic>;
      for (final emitter in (particle['emitters'] as List).take(2)) {
        expect((emitter as Map)['axis'], {'x': 4096, 'y': 0, 'z': 0});
        expect(emitter['initVelAxisAmplifier'], greaterThan(0));
      }
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1',
  );

  test('nominal BW2 jet points along depth in both directions', () {
    final forward = _sourceEnemy - _sourcePlayer;
    final horizontal = math.sqrt(forward.x * forward.x + forward.z * forward.z);
    expect(forward.y, 0);
    expect(forward.x / horizontal, closeTo(-0.01176102015, 1e-9));
    expect(forward.z / horizontal, closeTo(-0.99993083681, 1e-9));
    final reverse = _sourcePlayer - _sourceEnemy;
    expect(reverse.x / horizontal, closeTo(0.01176102015, 1e-9));
    expect(reverse.z / horizontal, closeTo(0.99993083681, 1e-9));
  });

  for (final viewport in [Vector2(390, 844), Vector2(844, 390)]) {
    test('maps and projects both jet directions at $viewport', () async {
      const stats = BattleStatsSnapshot(
        attack: 20,
        defense: 20,
        specialAttack: 20,
        specialDefense: 20,
        speed: 20,
      );
      const pokemon = BattleCombatantData(
        speciesId: 'synthetic',
        level: 7,
        maxHp: 25,
        currentHp: 25,
        stats: stats,
        moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
      );
      final overlay = BattleOverlayComponent(
        session: createBattleSession(
          BattleSetup.pokeMapBetaV1ForTest(
            playerPokemon: pokemon,
            enemyPokemon: pokemon,
            isTrainerBattle: false,
            trainerId: null,
          ),
        ),
        viewportSize: viewport,
        onPlayerChoice: (_) {},
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final camera = overlay.children
          .whereType<BattleStage3DComponent>()
          .single
          .camera;
      final layout = overlay.currentSceneLayout;
      expect(camera.viewport, layout.stageRect);
      expect(camera.eye.isFinite, isTrue);
      expect(camera.aim.isFinite, isTrue);
      final initialEye = camera.eye;
      final initialAim = camera.aim;
      final player = camera.tryGroundAt(layout.playerFootAnchor)!;
      final enemy = camera.tryGroundAt(layout.enemyFootAnchor)!;
      final playerFoot = camera
          .tryBillboardAt(layout.playerFootAnchor)!
          .position;
      final enemyFoot = camera.tryBillboardAt(layout.enemyFootAnchor)!.position;
      expect(
        (camera.project(player).position - playerFoot).distance,
        lessThan(1e-6),
      );
      expect(
        (camera.project(enemy).position - enemyFoot).distance,
        lessThan(1e-6),
      );

      final sourceVector = _sourceEnemy - _sourcePlayer;
      final worldVector = enemy - player;
      final sourceLength = math.sqrt(
        sourceVector.x * sourceVector.x + sourceVector.z * sourceVector.z,
      );
      final worldLength = math.sqrt(
        worldVector.x * worldVector.x + worldVector.z * worldVector.z,
      );
      expect(sourceLength, greaterThan(0));
      expect(worldLength, greaterThan(0));
      final scale = worldLength / sourceLength;
      final angle =
          math.atan2(worldVector.z, worldVector.x) -
          math.atan2(sourceVector.z, sourceVector.x);
      final cosine = math.cos(angle);
      final sine = math.sin(angle);
      BattleCameraPoint mapSource(BattleCameraPoint point) {
        final delta = point - _sourcePlayer;
        return player +
            BattleCameraPoint(
              (delta.x * cosine - delta.z * sine) * scale,
              delta.y * scale,
              (delta.x * sine + delta.z * cosine) * scale,
            );
      }

      expect(mapSource(_sourcePlayer).distanceTo(player), lessThan(1e-8));
      expect(mapSource(_sourceEnemy).distanceTo(enemy), lessThan(1e-8));
      final start = _sourcePlayer + _sourceEmitterOffset;
      final end = _sourceEnemy + _sourceEmitterOffset;
      const samples = [0.0, .25, .5, .75, 1.0];
      for (final movedCamera in [false, true]) {
        if (movedCamera) {
          camera.moveTo(
            eye: initialEye + const BattleCameraPoint(1, .5, -.5),
            aim: initialAim,
            durationSeconds: 0,
          );
        }
        final forward = [
          for (final t in samples)
            camera.project(mapSource(_lerp(start, end, t))).position,
        ];
        final reverse = [
          for (final t in samples)
            camera.project(mapSource(_lerp(end, start, t))).position,
        ];
        for (var i = 0; i < samples.length; i++) {
          expect(
            (forward[i] - reverse[samples.length - 1 - i]).distance,
            lessThan(1e-6),
          );
        }
        expect((forward.last - forward.first).distance, greaterThan(1));
        final withoutDepth = BattleCameraPoint(end.x, end.y, start.z);
        final flatEnd = camera.project(mapSource(withoutDepth)).position;
        expect((forward.last - flatEnd).distance, greaterThan(1));
      }
    });
  }
}

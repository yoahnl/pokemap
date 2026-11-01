import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_configured_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_pool.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';

Future<Map<String, dynamic>> fixture() async => jsonDecode(
  await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
) as Map<String, dynamic>;

BattleSplStaticPreparation prepare(
  Map<String, dynamic> raw, {
  int poolCapacity = 16,
  int maxTicks = 80,
}) => BattleSplStaticAdmission.prepare(
  definition: BattleSplParticleDefinition.fromJson(raw),
  textureIndices: const {'tex': 0},
  emitters: const [
    BattleSplStaticEmitter(
      emitterIndex: 0,
      startTick: 0,
      position: (x: 0, y: 0, z: 0),
    ),
  ],
  seed: 0,
  poolCapacity: poolCapacity,
  maxTicks: maxTicks,
);

void main() {
  test('preflights and replays the same deterministic particles', () async {
    final raw = await fixture();
    final result = prepare(raw);
    expect(result.failure, isNull);
    final playback = result.playback!;
    final pool = BattleSplParticlePool(capacity: 16);
    final expected = BattleSplConfiguredEmitter(
      definition: BattleSplParticleDefinition.fromJson(raw).emitters.single,
      textureIndices: const {'tex': 0},
      random: BattleSplRandom(seed: 0),
      pool: pool,
    );
    var tick = 0;
    while (!playback.isComplete) {
      expect(playback.advance(), isNull);
      expected.step(managerFrame: tick & 1, position: (x: 0, y: 0, z: 0));
      final actual = playback.frames.single.particles;
      final reference = expected.playback.particles;
      expect(
        actual
            .map(
              (p) => (
                p.id,
                p.motion.position,
                p.motion.velocity,
                p.alpha5,
                p.texture,
              ),
            )
            .toList(),
        reference
            .map(
              (p) => (
                p.id,
                p.motion.position,
                p.motion.velocity,
                p.alpha5,
                p.texture,
              ),
            )
            .toList(),
      );
      tick++;
    }
    expect(tick, greaterThan(0));
    expect(expected.playback.isComplete, isTrue);
    expect(playback.activeParticles, 0);
    expect(pool.inUse, 0);
    playback.cancel();
  });

  test(
    'refuses an overflowing effect before starting the fallback battle plan',
    () async {
      final raw = await fixture();
      final emitter = (raw['emitters'] as List).single as Map;
      final emission = emitter['emission'] as Map;
      emission['duration'] = 1;
      emission['particleLifetime'] = 20;
      emission['axisVelocity'] = 0;
      final motion = emitter['motion'] as Map;
      (motion['gravity'] as Map)['x'] = 32767;
      motion['airResistance'] = 255;
      final result = prepare(raw);
      expect(result.playback, isNull);
      expect(result.failure, BattleSplAdmissionFailure.arithmetic);
      final events = <String>[];
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (_) {},
        onScreenFlash: (_) {},
        onCombatantMotion: (_) {},
        onCombatantFlash: (_) {},
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) => events.add('hp'),
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
        onPlaySe: (step) => events.add(step.seName),
        onStartTrackedEffect: (_, _) {
          events.add('imported');
          return () {};
        },
      );
      const imported = BattleAnimationPlan(
        steps: [StartTrackedEffectStep(effectId: 'spl')],
      );
      const fallback = BattleAnimationPlan(
        steps: [
          PlaySeStep(seName: 'legacy'),
          HudHpTweenStep(side: BattleSideId.enemy, fromHp: 40, toHp: 20),
        ],
      );
      runner.start(result.playback == null ? fallback : imported);
      expect(events, ['legacy', 'hp']);
    },
  );

  test('refuses pool exhaustion and work beyond the frame budget', () async {
    final dense = await fixture();
    (((dense['emitters'] as List).single as Map)['emission'] as Map)['rate'] =
        2 * 4096;
    final crowded = prepare(dense, poolCapacity: 1);
    expect(crowded.playback, isNull);
    expect(crowded.failure, BattleSplAdmissionFailure.poolExhausted);
    final long = await fixture();
    final limited = prepare(long, maxTicks: 1);
    expect(limited.playback, isNull);
    expect(limited.failure, BattleSplAdmissionFailure.frameLimit);
    final work = prepare(await fixture(), poolCapacity: 4096, maxTicks: 80);
    expect(work.playback, isNull);
    expect(work.failure, BattleSplAdmissionFailure.workLimit);
  });

  test('starts only the emitters scheduled for the current tick', () async {
    final definition = BattleSplParticleDefinition.fromJson(await fixture());
    final result = BattleSplStaticAdmission.prepare(
      definition: definition,
      textureIndices: const {'tex': 0},
      emitters: const [
        BattleSplStaticEmitter(
          emitterIndex: 0,
          startTick: 0,
          position: (x: 0, y: 0, z: 0),
        ),
        BattleSplStaticEmitter(
          emitterIndex: 0,
          startTick: 2,
          position: (x: 4096, y: 0, z: 0),
        ),
      ],
      seed: 0,
      poolCapacity: 16,
      maxTicks: 80,
    );
    final playback = result.playback!;
    expect(playback.advance(), isNull);
    expect(playback.frames[0].particles, isNotEmpty);
    expect(playback.frames[1].particles, isEmpty);
    expect(playback.advance(), isNull);
    expect(playback.frames[1].particles, isEmpty);
    expect(playback.advance(), isNull);
    expect(playback.frames[1].particles, isNotEmpty);
    playback.cancel();
    expect(playback.activeParticles, 0);
  });

  test('rejects invalid schedules and ambiguous texture mappings', () async {
    final definition = BattleSplParticleDefinition.fromJson(await fixture());
    BattleSplStaticPreparation prepareSchedule({
      required List<BattleSplStaticEmitter> emitters,
      Map<String, int> textures = const {'tex': 0},
      int maxTicks = 80,
    }) => BattleSplStaticAdmission.prepare(
      definition: definition,
      textureIndices: textures,
      emitters: emitters,
      seed: 0,
      poolCapacity: 16,
      maxTicks: maxTicks,
    );
    expect(() => prepareSchedule(emitters: []), throwsFormatException);
    expect(
      () => prepareSchedule(
        emitters: const [
          BattleSplStaticEmitter(
            emitterIndex: 1,
            startTick: 0,
            position: (x: 0, y: 0, z: 0),
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => prepareSchedule(
        emitters: const [
          BattleSplStaticEmitter(
            emitterIndex: 0,
            startTick: 80,
            position: (x: 0, y: 0, z: 0),
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => prepareSchedule(
        emitters: const [
          BattleSplStaticEmitter(
            emitterIndex: 0,
            startTick: 0,
            position: (x: 0, y: 0, z: 0),
          ),
        ],
        textures: const {'tex': 256},
      ),
      throwsFormatException,
    );
  });

  test(
    'preflights all four source 218 emitters with an explicit static schedule',
    () async {
      const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
      const path = 'res/particles/btlv_effvm_particles/218/particles.json';
      const expectedHash =
          'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9';
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final request = await client
          .getUrl(
            Uri.https(
              'raw.githubusercontent.com',
              '/fuddlesworth/pokebw2/$revision/$path',
            ),
          )
          .timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      expect(response.statusCode, HttpStatus.ok);
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        if (builder.length + chunk.length > 262144) {
          throw const FormatException('Source too large');
        }
        builder.add(chunk);
      }
      final source = builder.takeBytes();
      expect(sha256.convert(source).toString(), expectedHash);
      final converted = Gen5SplParticleConverter.convert(
        source,
        particleId: 218,
        sourceRevision: revision,
        sourcePath: path,
        expectedSha256: expectedHash,
        textureResourceIds: {
          for (var i = 0; i < 6; i++) 'texture0$i': 'texture0$i',
        },
      );
      final result = BattleSplStaticAdmission.prepare(
        definition: converted.definition,
        textureIndices: {for (var i = 0; i < 6; i++) 'texture0$i': i},
        emitters: [
          for (var i = 0; i < 4; i++)
            BattleSplStaticEmitter(
              emitterIndex: i,
              startTick: i < 2 ? 0 : 46,
              position: (x: i * 4096, y: 0, z: 0),
            ),
        ],
        seed: 0,
        poolCapacity: 128,
        maxTicks: 200,
      );
      expect(result.failure, isNull);
      final playback = result.playback!;
      final seen = <int>{};
      var childSeen = false;
      while (!playback.isComplete) {
        expect(playback.advance(), isNull);
        for (final frame in playback.frames) {
          if (frame.particles.isNotEmpty) seen.add(frame.emitterIndex);
          if (frame.particles.any((particle) => particle.parentId != null)) {
            childSeen = true;
          }
        }
      }
      expect(seen, {0, 1, 2, 3});
      expect(childSeen, isTrue);
      expect(playback.activeParticles, 0);
      playback.cancel();
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1',
  );

  test(
    'cancellation releases particles and stops the prepared playback',
    () async {
      final playback = prepare(await fixture()).playback!;
      expect(playback.advance(), isNull);
      expect(playback.activeParticles, greaterThan(0));
      playback.cancel();
      expect(playback.activeParticles, 0);
      expect(playback.isComplete, isTrue);
      expect(playback.frames.single.particles, isEmpty);
    },
  );
}

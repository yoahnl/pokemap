import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_particle_timeline.dart';

void main() {
  const flame = BattleParticleEmitterTiming(
    textureId: 'flame',
    emissionDurationMs: 100,
    emissionIntervalMs: 40,
    particleLifetimeMs: 90,
    particlesPerEmission: 2,
  );

  test(
    'emits continuously and completes only after the last particles expire',
    () {
      final timeline = BattleParticleTimeline([flame]);
      final first = timeline.advance(Duration.zero);
      expect(
        first.map(
          (event) => (event.kind, event.at.inMilliseconds, event.count),
        ),
        [(BattleParticleEventKind.emission, 0, 2)],
      );
      expect(timeline.activeParticles, 2);
      final middle = timeline.advance(const Duration(milliseconds: 100));
      expect(
        middle.map(
          (event) => (event.kind, event.at.inMilliseconds, event.count),
        ),
        [
          (BattleParticleEventKind.emission, 40, 2),
          (BattleParticleEventKind.emission, 80, 2),
          (BattleParticleEventKind.expiration, 90, 2),
        ],
      );
      expect(timeline.isComplete, isFalse);
      expect(timeline.activeParticles, 4);
      timeline.advance(const Duration(milliseconds: 69));
      expect(timeline.isComplete, isFalse);
      final last = timeline.advance(const Duration(milliseconds: 1));
      expect(last.single.kind, BattleParticleEventKind.expiration);
      expect(last.single.at, const Duration(milliseconds: 170));
      expect(timeline.activeParticles, 0);
      expect(timeline.isComplete, isTrue);
    },
  );

  test('delays emission and carries fractional particles between batches', () {
    final timeline = BattleParticleTimeline([
      const BattleParticleEmitterTiming(
        textureId: 'fractional',
        startDelayMs: 10,
        emissionDurationMs: 40,
        emissionIntervalMs: 10,
        particleLifetimeMs: 15,
        particlesPerEmission: 1,
        fractionalEmission4096: 2048,
      ),
    ]);
    expect(timeline.advance(const Duration(milliseconds: 9)), isEmpty);
    final first = timeline.advance(const Duration(milliseconds: 1));
    expect(first.single.count, 1);
    expect(first.single.at, const Duration(milliseconds: 10));
    final remaining = timeline.advance(const Duration(milliseconds: 45));
    expect(
      [first.single, ...remaining]
          .where((event) => event.kind == BattleParticleEventKind.emission)
          .map((event) => (event.at.inMilliseconds, event.count)),
      [(10, 1), (20, 2), (30, 1), (40, 2)],
    );
    expect(
      remaining
          .where((event) => event.kind == BattleParticleEventKind.expiration)
          .map((event) => event.count),
      [1, 2, 1, 2],
    );
    expect(timeline.activeParticles, 0);
    expect(timeline.isComplete, isTrue);
  });

  test(
    'a rate below one retains its fraction without exceeding work limits',
    () {
      const timing = BattleParticleEmitterTiming(
        textureId: 'fractional',
        emissionDurationMs: 40,
        emissionIntervalMs: 10,
        particleLifetimeMs: 15,
        particlesPerEmission: 0,
        fractionalEmission4096: 2048,
      );
      final timeline = BattleParticleTimeline([timing]);
      final events = timeline.advance(const Duration(milliseconds: 45));
      expect(
        events
            .where((event) => event.kind == BattleParticleEventKind.emission)
            .map((event) => event.count),
        [1, 1],
      );
      expect(
        events
            .where((event) => event.kind == BattleParticleEventKind.expiration)
            .map((event) => event.count),
        [1, 1],
      );
      expect(timeline.activeParticles, 0);
      expect(timeline.isComplete, isTrue);
      final trailingEmpty = BattleParticleTimeline([
        const BattleParticleEmitterTiming(
          textureId: 'fractional',
          emissionDurationMs: 21,
          emissionIntervalMs: 10,
          particleLifetimeMs: 1,
          particlesPerEmission: 0,
          fractionalEmission4096: 2048,
        ),
      ]);
      final trailingEvents = trailingEmpty.advance(
        const Duration(milliseconds: 20),
      );
      expect(trailingEvents.map((event) => event.count), [1, 1]);
      expect(trailingEmpty.isComplete, isTrue);
      expect(trailingEmpty.activeParticles, 0);
      expect(
        () => BattleParticleTimeline([
          const BattleParticleEmitterTiming(
            textureId: 'too-many-batches',
            emissionDurationMs: 4097,
            emissionIntervalMs: 1,
            particleLifetimeMs: 1,
            particlesPerEmission: 0,
            fractionalEmission4096: 1,
          ),
        ]),
        throwsFormatException,
      );
    },
  );

  test(
    'fractional delayed schedules are stable across work and frame budgets',
    () {
      const timings = [
        BattleParticleEmitterTiming(
          textureId: 'a',
          startDelayMs: 13,
          emissionDurationMs: 100,
          emissionIntervalMs: 7,
          particleLifetimeMs: 14,
          particlesPerEmission: 0,
          fractionalEmission4096: 2048,
        ),
        BattleParticleEmitterTiming(
          textureId: 'b',
          startDelayMs: 4,
          emissionDurationMs: 90,
          emissionIntervalMs: 9,
          particleLifetimeMs: 21,
          particlesPerEmission: 1,
          fractionalEmission4096: 1024,
        ),
      ];
      final whole = BattleParticleTimeline(timings);
      final partitioned = BattleParticleTimeline(timings);
      final expected = whole.advance(const Duration(milliseconds: 150));
      final actual = <BattleParticleEvent>[];
      for (var frame = 0; frame < 15; frame++) {
        actual.addAll(
          partitioned.advance(const Duration(milliseconds: 10), workBudget: 2),
        );
        while (partitioned.hasPendingEvents) {
          actual.addAll(partitioned.advance(Duration.zero, workBudget: 2));
        }
      }
      expect(
        actual.map(
          (event) => (
            event.kind,
            event.emitterIndex,
            event.batchIndex,
            event.at,
            event.count,
          ),
        ),
        expected.map(
          (event) => (
            event.kind,
            event.emitterIndex,
            event.batchIndex,
            event.at,
            event.count,
          ),
        ),
      );
      expect(partitioned.isComplete, isTrue);
      expect(partitioned.activeParticles, 0);
    },
  );

  test('empty emission attempts consume the per-update work budget', () {
    final timeline = BattleParticleTimeline([
      const BattleParticleEmitterTiming(
        textureId: 'sparse',
        emissionDurationMs: 100,
        emissionIntervalMs: 1,
        particleLifetimeMs: 1,
        particlesPerEmission: 0,
        fractionalEmission4096: 1,
      ),
    ]);
    expect(
      timeline.advance(const Duration(milliseconds: 100), workBudget: 2),
      isEmpty,
    );
    expect(timeline.elapsed, const Duration(milliseconds: 1));
    expect(timeline.hasPendingEvents, isTrue);
    expect(timeline.advance(Duration.zero, workBudget: 2), isEmpty);
    expect(timeline.elapsed, const Duration(milliseconds: 3));
    expect(timeline.hasPendingEvents, isTrue);
  });

  test(
    'tick schedules use absolute time without accumulating rounding drift',
    () {
      final timeline = BattleParticleTimeline([
        const BattleParticleEmitterTiming.ticks(
          textureId: 'ticks',
          ticksPerSecond: 60,
          startDelayTicks: 1,
          emissionDurationTicks: 60,
          emissionIntervalTicks: 1,
          particleLifetimeTicks: 2,
          particlesPerEmission: 1,
        ),
      ]);
      final events = timeline.advance(const Duration(seconds: 1));
      final emitted = events
          .where((event) => event.kind == BattleParticleEventKind.emission)
          .toList();
      expect(emitted.length, 60);
      expect(emitted[0].at.inMicroseconds, 16666);
      expect(emitted[2].at.inMicroseconds, 50000);
      expect(emitted[29].at.inMicroseconds, 500000);
      expect(emitted[59].at.inMicroseconds, 1000000);
      expect(timeline.isComplete, isFalse);
      timeline.advance(const Duration(microseconds: 33333));
      expect(timeline.isComplete, isTrue);
      expect(timeline.activeParticles, 0);
    },
  );

  test('rejects invalid tick frequencies and out-of-budget durations', () {
    BattleParticleEmitterTiming timing({
      int rate = 60,
      int duration = 60,
      int delay = 0,
    }) => BattleParticleEmitterTiming.ticks(
      textureId: 'ticks',
      ticksPerSecond: rate,
      startDelayTicks: delay,
      emissionDurationTicks: duration,
      emissionIntervalTicks: 1,
      particleLifetimeTicks: 1,
      particlesPerEmission: 1,
    );
    for (final invalid in [
      timing(rate: 0),
      timing(rate: 1001),
      timing(duration: 3601),
      timing(delay: -1),
      timing(delay: 3601),
    ]) {
      expect(() => BattleParticleTimeline([invalid]), throwsFormatException);
    }
  });

  test(
    'tick and millisecond emitters retain ordering across frame budgets',
    () {
      const timings = [
        BattleParticleEmitterTiming.ticks(
          textureId: 'ticks',
          ticksPerSecond: 60,
          startDelayTicks: 1,
          emissionDurationTicks: 8,
          emissionIntervalTicks: 1,
          particleLifetimeTicks: 2,
          particlesPerEmission: 1,
          fractionalEmission4096: 2048,
        ),
        BattleParticleEmitterTiming(
          textureId: 'milliseconds',
          startDelayMs: 50,
          emissionDurationMs: 60,
          emissionIntervalMs: 10,
          particleLifetimeMs: 20,
          particlesPerEmission: 1,
        ),
      ];
      final whole = BattleParticleTimeline(timings);
      final partitioned = BattleParticleTimeline(timings);
      final expected = whole.advance(const Duration(milliseconds: 200));
      final actual = <BattleParticleEvent>[];
      for (var frame = 0; frame < 100; frame++) {
        actual.addAll(
          partitioned.advance(const Duration(milliseconds: 2), workBudget: 2),
        );
        while (partitioned.hasPendingEvents) {
          actual.addAll(partitioned.advance(Duration.zero, workBudget: 2));
        }
      }
      expect(
        actual.map(
          (event) => (
            event.kind,
            event.emitterIndex,
            event.batchIndex,
            event.at,
            event.count,
          ),
        ),
        expected.map(
          (event) => (
            event.kind,
            event.emitterIndex,
            event.batchIndex,
            event.at,
            event.count,
          ),
        ),
      );
      expect(partitioned.isComplete, isTrue);
      expect(partitioned.activeParticles, 0);
    },
  );

  test('rejects invalid fractions, delays and excessive particle counts', () {
    BattleParticleEmitterTiming timing({
      int count = 1,
      int fraction = 0,
      int delay = 0,
      int duration = 100,
      int interval = 10,
    }) => BattleParticleEmitterTiming(
      textureId: 'x',
      startDelayMs: delay,
      emissionDurationMs: duration,
      emissionIntervalMs: interval,
      particleLifetimeMs: 10,
      particlesPerEmission: count,
      fractionalEmission4096: fraction,
    );
    for (final invalid in [
      timing(count: 0),
      timing(fraction: -1),
      timing(fraction: 4096),
      timing(count: 64, fraction: 1),
      timing(delay: -1),
      timing(delay: 60001),
      timing(count: 64, duration: 650, interval: 10),
    ]) {
      expect(() => BattleParticleTimeline([invalid]), throwsFormatException);
    }
  });

  test('event order and results do not depend on frame partitioning', () {
    const spark = BattleParticleEmitterTiming(
      textureId: 'spark',
      emissionDurationMs: 80,
      emissionIntervalMs: 20,
      particleLifetimeMs: 40,
      particlesPerEmission: 1,
    );
    final one = BattleParticleTimeline([flame, spark]);
    final many = BattleParticleTimeline([flame, spark]);
    final expected = one.advance(const Duration(milliseconds: 200));
    final actual = <BattleParticleEvent>[];
    for (var i = 0; i < 20; i++) {
      actual.addAll(many.advance(const Duration(milliseconds: 10)));
    }
    expect(
      actual.map((e) => (e.kind, e.emitterIndex, e.batchIndex, e.at, e.count)),
      expected.map(
        (e) => (e.kind, e.emitterIndex, e.batchIndex, e.at, e.count),
      ),
    );
    expect(many.isComplete, isTrue);
  });

  test(
    'expires an old batch before emitting a new batch at the same instant',
    () {
      final timeline = BattleParticleTimeline([
        const BattleParticleEmitterTiming(
          textureId: 'x',
          emissionDurationMs: 21,
          emissionIntervalMs: 10,
          particleLifetimeMs: 10,
          particlesPerEmission: 1,
        ),
      ]);
      final events = timeline.advance(const Duration(milliseconds: 10));
      expect(events.map((e) => (e.kind, e.at.inMilliseconds)), [
        (BattleParticleEventKind.emission, 0),
        (BattleParticleEventKind.expiration, 10),
        (BattleParticleEventKind.emission, 10),
      ]);
      expect(timeline.activeParticles, 1);
    },
  );

  test('bounded work preserves elapsed debt and zero-time calls drain it', () {
    final expected = BattleParticleTimeline([flame])
        .advance(const Duration(seconds: 1));
    final timeline = BattleParticleTimeline([flame]);
    final events = timeline
        .advance(const Duration(seconds: 1), workBudget: 1)
        .toList();
    expect(timeline.hasPendingEvents, isTrue);
    expect(timeline.isComplete, isFalse);
    while (timeline.hasPendingEvents) {
      events.addAll(timeline.advance(Duration.zero, workBudget: 1));
    }
    expect(
      events.map((e) => (e.kind, e.batchIndex, e.at)),
      expected.map((e) => (e.kind, e.batchIndex, e.at)),
    );
    expect(timeline.isComplete, isTrue);
  });

  test('cancellation discards work, and invalid inputs are rejected', () {
    final timeline = BattleParticleTimeline([flame]);
    timeline.advance(Duration.zero);
    timeline.cancel();
    expect(timeline.activeParticles, 0);
    expect(timeline.isCancelled, isTrue);
    expect(timeline.advance(const Duration(seconds: 1)), isEmpty);
    expect(() => BattleParticleTimeline([]), throwsFormatException);
    expect(
      () => BattleParticleTimeline([
        const BattleParticleEmitterTiming(
          textureId: 'x',
          emissionDurationMs: 100,
          emissionIntervalMs: 0,
          particleLifetimeMs: 100,
          particlesPerEmission: 1,
        ),
      ]),
      throwsFormatException,
    );
    expect(
      () =>
          BattleParticleTimeline([flame])
              .advance(const Duration(microseconds: -1)),
      throwsArgumentError,
    );
  });

  test('reads verified synthetic definition bytes into a real timeline', () {
    final texture = <int>[1, 2, 3];
    final definition = utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'emitters': [
          {
            'textureId': 'tex',
            'emissionDurationMs': 100,
            'emissionIntervalMs': 40,
            'particleLifetimeMs': 90,
            'particlesPerEmission': 2,
          },
        ],
      }),
    );
    Map<String, dynamic> resource(
      String id,
      String role,
      String type,
      List<int> bytes,
    ) => {
      'id': id,
      'role': role,
      'mediaType': type,
      'sizeBytes': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
    };
    final recipe = BattleMoveAnimationRecipe.fromJson({
      'schemaVersion': 1,
      'recipeId': 'synthetic',
      'revision': '1',
      'moveSourceId': 'flamethrower',
      'variant': 'default',
      'requiredCapabilities': ['startParticle'],
      'provenance': {
        'source': 'synthetic',
        'sourceRevision': '1',
        'sourcePaths': <String>[],
        'converter': 'test/1',
      },
      'resources': [
        {
          ...resource(
            'particle',
            'particleDefinition',
            'application/vnd.avelune.particle+json',
            definition,
          ),
          'definitionVersion': 1,
          'dependencies': ['tex'],
        },
        resource('tex', 'texture', 'image/png', texture),
      ],
      'program': {
        'kind': 'startParticle',
        'resourceId': 'particle',
        'from': 'userMouth',
        'to': 'targetImpact',
      },
    });
    final typed = recipe.readVerifiedParticleDefinitions(
      {'particle': definition, 'tex': texture},
      availableCapabilities: {'startParticle'},
    );
    final timeline = BattleParticleTimeline.fromDefinition(typed['particle']!);
    final events = timeline.advance(const Duration(milliseconds: 170));
    expect(
      events.where((e) => e.kind == BattleParticleEventKind.emission).length,
      3,
    );
    expect(events.last.at, const Duration(milliseconds: 170));
    expect(timeline.isComplete, isTrue);
    expect(
      () => recipe.readVerifiedParticleDefinitions(
        {
          'particle': definition,
          'tex': [9],
        },
        availableCapabilities: {'startParticle'},
      ),
      throwsFormatException,
    );
  });

  test('tracked effect barrier waits for the synthetic timeline tail', () {
    final timeline = BattleParticleTimeline([flame]);
    final sounds = <String>[];
    late void Function() complete;
    final runner = BattleAnimationRunner(
      onPresentationChanged: () {},
      onSpawnFx: (_) {},
      onScreenFlash: (_) {},
      onCombatantMotion: (_) {},
      onCombatantFlash: (_) {},
      onCombatantShake: (_) {},
      onFaintCombatant: (_) {},
      onHudHpTween: (_) {},
      onBarrierPulse: (_) {},
      onSwapCombatantVisual: (_) {},
      onPlaySe: (step) => sounds.add(step.seName),
      onStartTrackedEffect: (_, done) {
        complete = done;
        timeline.advance(Duration.zero);
        return timeline.cancel;
      },
    );
    runner.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(effectId: 'synthetic'),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'after'),
        ],
      ),
    );
    timeline.advance(const Duration(milliseconds: 100));
    runner.update(.1);
    expect(sounds, isEmpty);
    timeline.advance(const Duration(milliseconds: 69));
    runner.update(.069);
    expect(sounds, isEmpty);
    timeline.advance(const Duration(milliseconds: 1));
    if (timeline.isComplete) complete();
    runner.update(.001);
    expect(sounds, ['after']);
    expect(runner.isActive, isFalse);
  });
}

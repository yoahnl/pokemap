import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_emitter_lifecycle.dart';

void main() {
  test('keeps children alive after their parents and emitter stop', () {
    final lifecycle = BattleSplEmitterLifecycle(
      startDelay: 2,
      emitterLifetime: 2,
      emissionInterval: 1,
      emissionRate4096: 4096,
      particleLifetime: 2,
      particleLifetimeVariance: 0,
      maxParticles: 16,
      child: const BattleSplChildTiming(
        emissionCount: 1,
        emissionDelay256: 0,
        emissionInterval: 1,
        lifetime: 1,
      ),
    );

    final steps = [
      for (var tick = 0; tick < 7; tick++)
        lifecycle.step(managerFrame: tick % 2),
    ];

    expect(steps.map((step) => step.emittedParents), [0, 0, 1, 1, 0, 0, 0]);
    expect(steps.map((step) => step.emittedChildren), [0, 0, 1, 2, 2, 1, 0]);
    expect(steps.map((step) => step.activeParents), [0, 0, 1, 2, 1, 0, 0]);
    expect(steps.map((step) => step.activeChildren), [0, 0, 1, 2, 2, 1, 0]);
    expect(steps.map((step) => step.complete), [
      false,
      false,
      false,
      false,
      false,
      false,
      true,
    ]);
    expect(lifecycle.step(managerFrame: 1).complete, isTrue);
  });

  test('carries fractional emission without accumulating rounding', () {
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 6,
      emissionInterval: 1,
      emissionRate4096: 2048,
      particleLifetime: 1,
      particleLifetimeVariance: 0,
      maxParticles: 8,
    );
    final steps = [
      for (var tick = 0; tick < 7; tick++)
        lifecycle.step(managerFrame: tick % 2),
    ];

    expect(steps.map((step) => step.emittedParents), [0, 1, 0, 1, 0, 1, 0]);
    expect(steps.last.complete, isTrue);
  });

  test('uses the fractional child delay and updates newborns immediately', () {
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 1,
      emissionInterval: 1,
      emissionRate4096: 4096,
      particleLifetime: 5,
      particleLifetimeVariance: 0,
      maxParticles: 8,
      child: const BattleSplChildTiming(
        emissionCount: 1,
        emissionDelay256: 128,
        emissionInterval: 2,
        lifetime: 1,
      ),
    );
    final steps = [
      for (var tick = 0; tick < 7; tick++)
        lifecycle.step(managerFrame: tick % 2),
    ];

    expect(steps.map((step) => step.emittedChildren), [0, 0, 0, 1, 0, 1, 0]);
    expect(steps.map((step) => step.activeParents), [1, 1, 1, 1, 1, 0, 0]);
    expect(steps.map((step) => step.activeChildren), [0, 0, 0, 1, 0, 1, 0]);
    expect(steps.last.complete, isTrue);
  });

  test('ages start delay only on the selected manager frame', () {
    final lifecycle = BattleSplEmitterLifecycle(
      startDelay: 2,
      emitterLifetime: 1,
      emissionInterval: 1,
      emissionRate4096: 4096,
      particleLifetime: 2,
      particleLifetimeVariance: 0,
      updateCycle: 1,
      maxParticles: 8,
    );
    final steps = [
      for (var tick = 0; tick < 5; tick++)
        lifecycle.step(managerFrame: tick % 2),
    ];

    expect(steps.map((step) => step.emittedParents), [0, 0, 0, 0, 1]);
    expect(steps.map((step) => step.started), [
      false,
      false,
      false,
      true,
      true,
    ]);
  });

  test('uses one bounded pool before freeing particles later in the tick', () {
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 2,
      emissionInterval: 1,
      emissionRate4096: 4096,
      particleLifetime: 2,
      particleLifetimeVariance: 0,
      maxParticles: 2,
      child: const BattleSplChildTiming(
        emissionCount: 1,
        emissionDelay256: 0,
        emissionInterval: 1,
        lifetime: 1,
      ),
    );

    final first = lifecycle.step(managerFrame: 0);
    final second = lifecycle.step(managerFrame: 1);
    expect((first.activeParents, first.activeChildren), (1, 1));
    expect((second.droppedParents, second.droppedChildren), (1, 1));
    expect((second.activeParents, second.activeChildren), (1, 0));
  });

  test('rejects invalid or unbounded lifecycle parameters', () {
    expect(
      () => BattleSplEmitterLifecycle(
        emitterLifetime: 2,
        emissionInterval: 0,
        emissionRate4096: 4096,
        particleLifetime: 2,
        particleLifetimeVariance: 0,
        maxParticles: 8,
      ),
      throwsFormatException,
    );
    expect(
      () => BattleSplEmitterLifecycle(
        emitterLifetime: 2,
        emissionInterval: 1,
        emissionRate4096: 4096,
        particleLifetime: 1,
        particleLifetimeVariance: 0,
        maxParticles: 8,
        child: const BattleSplChildTiming(
          emissionCount: 1,
          emissionDelay256: 0,
          emissionInterval: 1,
          lifetime: 1,
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => BattleSplEmitterLifecycle(
        emitterLifetime: 2,
        emissionInterval: 1,
        emissionRate4096: 4096,
        particleLifetime: 5,
        particleLifetimeVariance: 1,
        maxParticles: 8,
      ),
      throwsFormatException,
    );
    expect(
      () => BattleSplEmitterLifecycle(
        emitterLifetime: 2,
        emissionInterval: 1,
        emissionRate4096: 4096,
        particleLifetime: 65535,
        particleLifetimeVariance: 0,
        maxParticles: 8,
        child: const BattleSplChildTiming(
          emissionCount: 1,
          emissionDelay256: 255,
          emissionInterval: 1,
          lifetime: 1,
        ),
      ),
      throwsFormatException,
    );
  });

  test('keeps the original 16-bit emitter age for continuous emission', () {
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 0,
      emissionInterval: 3,
      emissionRate4096: 4096,
      particleLifetime: 1,
      particleLifetimeVariance: 0,
      maxParticles: 8,
    );
    for (var tick = 0; tick < 65536; tick++) {
      lifecycle.step(managerFrame: tick % 2);
    }
    expect(lifecycle.step(managerFrame: 0).emittedParents, 1);
  });

  test('pause and termination do not discard living children', () {
    final lifecycle = BattleSplEmitterLifecycle(
      emitterLifetime: 0,
      emissionInterval: 1,
      emissionRate4096: 4096,
      particleLifetime: 2,
      particleLifetimeVariance: 0,
      maxParticles: 8,
      child: const BattleSplChildTiming(
        emissionCount: 1,
        emissionDelay256: 0,
        emissionInterval: 1,
        lifetime: 1,
      ),
    );
    final first = lifecycle.step(managerFrame: 0);
    final paused = lifecycle.step(
      managerFrame: 1,
      paused: true,
      terminate: true,
    );
    final resumed = lifecycle.step(managerFrame: 0);
    expect((first.activeParents, first.activeChildren), (1, 1));
    expect((paused.activeParents, paused.activeChildren), (1, 1));
    expect(paused.complete, isFalse);
    expect(resumed.emittedParents, 0);
    expect(resumed.emittedChildren, 1);
    lifecycle.step(managerFrame: 1);
    expect(lifecycle.step(managerFrame: 0).complete, isTrue);
  });

  test(
    'counts source 218 emitters and children without loading their textures',
    () async {
      const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
      final client = HttpClient();
      try {
        final request = await client
            .getUrl(
              Uri.https(
                'raw.githubusercontent.com',
                '/fuddlesworth/pokebw2/$revision/res/particles/'
                    'btlv_effvm_particles/218/particles.json',
              ),
            )
            .timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
        expect(response.statusCode, HttpStatus.ok);
        final data = BytesBuilder(copy: false);
        await for (final bytes in response.timeout(
          const Duration(seconds: 20),
        )) {
          if (data.length + bytes.length > 64 * 1024) {
            throw const FormatException('Particle source exceeds test limit');
          }
          data.add(bytes);
        }
        final bytes = data.takeBytes();
        expect(
          sha256.convert(bytes).toString(),
          'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9',
        );
        final source = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final emitters = source['emitters'] as List<dynamic>;
        expect(emitters, hasLength(4));
        expect(source['textures'], hasLength(6));
        final parentTotals = <int>[];
        final childTotals = <int>[];
        final completionTicks = <int>[];
        for (final raw in emitters) {
          final emitter = raw as Map<String, dynamic>;
          expect(emitter['lifeTimeVariance'], 0);
          final rawChild = emitter['childResource'] as Map<String, dynamic>?;
          final lifecycle = BattleSplEmitterLifecycle(
            startDelay: emitter['startDelay'] as int,
            emitterLifetime: emitter['emitterLifeTime'] as int,
            emissionInterval: emitter['emissionInterval'] as int,
            emissionRate4096: emitter['emissionCount'] as int,
            particleLifetime: emitter['particleLifeTime'] as int,
            particleLifetimeVariance: emitter['lifeTimeVariance'] as int,
            autoTerminate: emitter['autoTerminate'] as bool,
            maxParticles: 256,
            child: rawChild == null
                ? null
                : BattleSplChildTiming(
                    emissionCount: rawChild['emissionCount'] as int,
                    emissionDelay256: rawChild['emissionDelay'] as int,
                    emissionInterval: rawChild['emissionInterval'] as int,
                    lifetime: rawChild['lifeTime'] as int,
                  ),
          );
          var parents = 0;
          var children = 0;
          var completionTick = -1;
          for (var tick = 0; tick < 300; tick++) {
            final step = lifecycle.step(managerFrame: tick % 2);
            parents += step.emittedParents;
            children += step.emittedChildren;
            expect(step.droppedParents + step.droppedChildren, 0);
            if (step.complete) {
              completionTick = tick;
              break;
            }
          }
          parentTotals.add(parents);
          childTotals.add(children);
          completionTicks.add(completionTick);
        }
        expect(parentTotals, [15, 12, 2, 20]);
        expect(childTotals, [0, 0, 128, 0]);
        expect(completionTicks, [74, 62, 75, 68]);
      } finally {
        client.close(force: true);
      }
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] == '1'
        ? false
        : 'Requires network access to the pinned source',
  );
}

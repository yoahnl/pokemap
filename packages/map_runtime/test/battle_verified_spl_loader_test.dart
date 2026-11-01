import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_spl_loader.dart';

Future<InspectedBattleRecipeBundle> bundle({bool crowded = false}) async {
  final raw = jsonDecode(
    await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
  ) as Map<String, dynamic>;
  if (crowded) {
    (((raw['emitters'] as List).single as Map)['emission'] as Map)['rate'] =
        2 * 4096;
  }
  final particle = Uint8List.fromList(utf8.encode(jsonEncode(raw)));
  final png = Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));
  final recipeBytes = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'recipeId': 'spl',
        'revision': '1',
        'moveSourceId': 'source',
        'variant': 'default',
        'requiredCapabilities': ['startParticle', 'splParticleV2'],
        'provenance': {
          'source': 'synthetic',
          'sourceRevision': '1',
          'sourcePaths': <String>[],
          'converter': 'test',
        },
        'resources': [
          {
            'id': 'tex',
            'role': 'texture',
            'mediaType': 'image/png',
            'sizeBytes': png.length,
            'sha256': sha256.convert(png).toString(),
          },
          {
            'id': 'particle',
            'role': 'particleDefinition',
            'mediaType': 'application/vnd.avelune.particle+json',
            'sizeBytes': particle.length,
            'sha256': sha256.convert(particle).toString(),
            'definitionVersion': 2,
            'dependencies': ['tex'],
          },
        ],
        'program': {
          'kind': 'startParticle',
          'resourceId': 'particle',
          'from': 'userMouth',
          'to': 'targetImpact',
        },
      }),
    ),
  );
  final binding = BattleMoveRecipeBinding.fromJson({
    'schemaVersion': 1,
    'projectMoveId': 'local',
    'sourceMoveId': 'source',
    'catalogReleaseId': 'test',
    'recipeId': 'spl',
    'variant': 'default',
    'revision': '1',
    'recipeSha256': sha256.convert(recipeBytes).toString(),
  });
  return const BattleRecipeBundleInspector().inspect(
    binding,
    recipeBytes,
    {'tex': png, 'particle': particle},
    limits: const BattleRecipeBundleLimits(
      maxTextures: 2,
      maxTextureBytes: 10000,
      maxBundleBytes: 30000,
      maxDimension: 16,
      maxTexturePixels: 256,
      maxTotalPixels: 256,
    ),
    availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    expectedProjectMoveId: 'local',
    expectedCatalogReleaseId: 'test',
  );
}

const schedule = [
  BattleSplStaticEmitter(
    emitterIndex: 0,
    startTick: 0,
    position: (x: 0, y: 0, z: 0),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'creates a static effect only from the verified versioned bundle',
    () async {
      final loader = BattleVerifiedSplLoader(await bundle());
      var complete = 0;
      final result = await loader.create(
        'particle',
        emitters: schedule,
        seed: 0,
        poolCapacity: 16,
        maxTicks: 80,
        origin: const ui.Offset(10, 10),
        pixelsPerUnit: 4,
        onComplete: () => complete++,
        onFailure: (_) => fail('failure'),
      );
      expect(result.failure, isNull);
      final component = result.component!;
      addTearDown(component.dispose);
      component.update(1 / 60);
      expect(component.playback.activeParticles, greaterThan(0));
      for (var i = 0; i < 80 && !component.playback.isComplete; i++) {
        component.update(1 / 60);
      }
      expect(complete, 1);
      await expectLater(
        loader.create(
          'particle',
          emitters: schedule,
          seed: 0,
          poolCapacity: 16,
          maxTicks: 80,
          origin: ui.Offset.zero,
          pixelsPerUnit: 4,
          onComplete: () {},
          onFailure: (_) {},
        ),
        throwsStateError,
      );
    },
  );

  test('returns fallback before preparing a pool-exhausting effect', () async {
    final loader = BattleVerifiedSplLoader(await bundle(crowded: true));
    final result = await loader.create(
      'particle',
      emitters: schedule,
      seed: 0,
      poolCapacity: 1,
      maxTicks: 80,
      origin: ui.Offset.zero,
      pixelsPerUnit: 4,
      onComplete: () => fail('played'),
      onFailure: (_) => fail('played'),
    );
    expect(result.component, isNull);
    expect(result.failure, BattleSplAdmissionFailure.poolExhausted);
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
      steps: [StartTrackedEffectStep(effectId: 'particle')],
    );
    const fallback = BattleAnimationPlan(
      steps: [
        PlaySeStep(seName: 'legacy'),
        HudHpTweenStep(side: BattleSideId.enemy, fromHp: 40, toHp: 20),
      ],
    );
    runner.start(result.component == null ? fallback : imported);
    expect(events, ['legacy', 'hp']);
  });

  test(
    'rejects missing or cancelled resources without starting an effect',
    () async {
      final missing = BattleVerifiedSplLoader(await bundle());
      await expectLater(
        missing.create(
          'other',
          emitters: schedule,
          seed: 0,
          poolCapacity: 16,
          maxTicks: 80,
          origin: ui.Offset.zero,
          pixelsPerUnit: 4,
          onComplete: () {},
          onFailure: (_) {},
        ),
        throwsFormatException,
      );
      final cancelled = BattleVerifiedSplLoader(await bundle())..cancel();
      await expectLater(
        cancelled.create(
          'particle',
          emitters: schedule,
          seed: 0,
          poolCapacity: 16,
          maxTicks: 80,
          origin: ui.Offset.zero,
          pixelsPerUnit: 4,
          onComplete: () {},
          onFailure: (_) {},
        ),
        throwsStateError,
      );
    },
  );

  test('cancellation during decoding releases every created image', () async {
    final loader = BattleVerifiedSplLoader(await bundle());
    final created = <ui.Image>[];
    final disposed = <ui.Image>[];
    final previousCreate = ui.Image.onCreate;
    final previousDispose = ui.Image.onDispose;
    ui.Image.onCreate = (image) {
      created.add(image);
      loader.cancel();
    };
    ui.Image.onDispose = disposed.add;
    addTearDown(() {
      ui.Image.onCreate = previousCreate;
      ui.Image.onDispose = previousDispose;
    });

    await expectLater(
      loader.create(
        'particle',
        emitters: schedule,
        seed: 0,
        poolCapacity: 16,
        maxTicks: 80,
        origin: ui.Offset.zero,
        pixelsPerUnit: 4,
        onComplete: () => fail('played'),
        onFailure: (_) => fail('played'),
      ),
      throwsStateError,
    );
    expect(created, isNotEmpty);
    expect(disposed, containsAll(created));
  });

  test('construction failure releases decoded images', () async {
    final loader = BattleVerifiedSplLoader(await bundle());
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

    await expectLater(
      loader.create(
        'particle',
        emitters: schedule,
        seed: 0,
        poolCapacity: 16,
        maxTicks: 80,
        origin: ui.Offset.zero,
        pixelsPerUnit: 0,
        onComplete: () => fail('played'),
        onFailure: (_) => fail('played'),
      ),
      throwsFormatException,
    );
    expect(created, isNotEmpty);
    expect(disposed, containsAll(created));
  });
}

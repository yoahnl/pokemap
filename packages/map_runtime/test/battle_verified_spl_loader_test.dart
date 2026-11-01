import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_camera_projection.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_spl_loader.dart';

import 'support/load_flame_component.dart';

Future<InspectedBattleRecipeBundle> bundle({
  bool crowded = false,
  bool opaque = false,
}) async {
  final raw = jsonDecode(
    await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
  ) as Map<String, dynamic>;
  if (crowded) {
    (((raw['emitters'] as List).single as Map)['emission'] as Map)['rate'] =
        2 * 4096;
  }
  final particle = Uint8List.fromList(utf8.encode(jsonEncode(raw)));
  final texture = img.Image(width: 2, height: 2);
  if (opaque) {
    img.fill(texture, color: img.ColorRgba8(255, 0, 0, 255));
  }
  final png = Uint8List.fromList(img.encodePng(texture));
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

BattleSplCameraProjection testProjection({bool Function()? isValid}) {
  final camera = BattlePerspectiveCamera(
    viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
  );
  const foot = ui.Offset(190, 600);
  return BattleSplCameraProjection(
    camera: camera,
    bindings: [
      BattleSplCameraBinding(
        resolveNeutralFoot: () => isValid?.call() == false ? null : foot,
        resolveAnchor: () {
          if (isValid?.call() == false) return null;
          final projected = camera.tryBillboardAt(foot);
          return projected == null
              ? null
              : Vector2(projected.position.dx, projected.position.dy);
        },
      ),
    ],
  );
}

List<String> runWithManualFallback(BattleVerifiedSplPreparation result) {
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
  return events;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'refuses scene playback before starting if projection is unavailable',
    () async {
      final loader = BattleVerifiedSplLoader(await bundle());
      final result = await loader.create(
        'particle',
        emitters: schedule,
        seed: 0,
        poolCapacity: 16,
        maxTicks: 80,
        origin: ui.Offset.zero,
        pixelsPerUnit: 4,
        onComplete: () => fail('played'),
        onFailure: (_) => fail('played'),
      );
      addTearDown(() => result.component?.dispose());
      expect(result.component, isNull);
      expect(result.failure, BattleSplAdmissionFailure.projectionUnavailable);
      expect(runWithManualFallback(result), ['legacy', 'hp']);
    },
  );

  test('refuses missing and non-finite bindings before playback', () async {
    final inspectedBundle = await bundle();
    final camera = BattlePerspectiveCamera(
      viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
    );
    final cases = <({ui.Offset? foot, Vector2? anchor})>[
      (foot: null, anchor: Vector2(190, 600)),
      (foot: const ui.Offset(190, 600), anchor: null),
      (foot: const ui.Offset(double.nan, 600), anchor: Vector2(190, 600)),
      (foot: const ui.Offset(190, double.infinity), anchor: Vector2(190, 600)),
      (foot: const ui.Offset(190, 600), anchor: Vector2(double.nan, 600)),
      (foot: const ui.Offset(190, 600), anchor: Vector2(190, double.infinity)),
    ];
    for (final value in cases) {
      final projection = BattleSplCameraProjection(
        camera: camera,
        bindings: [
          BattleSplCameraBinding(
            resolveNeutralFoot: () => value.foot,
            resolveAnchor: () => value.anchor,
          ),
        ],
      );
      final result = await BattleVerifiedSplLoader(inspectedBundle).create(
        'particle',
        emitters: schedule,
        seed: 0,
        poolCapacity: 16,
        maxTicks: 80,
        origin: ui.Offset.zero,
        pixelsPerUnit: 4,
        projection: projection,
        onComplete: () => fail('played'),
        onFailure: (_) => fail('played'),
      );
      expect(result.component, isNull, reason: '$value');
      expect(
        result.failure,
        BattleSplAdmissionFailure.projectionUnavailable,
        reason: '$value',
      );
    }
  });

  test('refuses a binding count that differs from the emitter count', () async {
    final result = await BattleVerifiedSplLoader(await bundle()).create(
      'particle',
      emitters: [...schedule, ...schedule],
      seed: 0,
      poolCapacity: 16,
      maxTicks: 80,
      origin: ui.Offset.zero,
      pixelsPerUnit: 4,
      projection: testProjection(),
      onComplete: () => fail('played'),
      onFailure: (_) => fail('played'),
    );
    expect(result.component, isNull);
    expect(result.failure, BattleSplAdmissionFailure.projectionUnavailable);
  });

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
        projection: testProjection(),
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
      projection: testProjection(),
      onComplete: () => fail('played'),
      onFailure: (_) => fail('played'),
    );
    expect(result.component, isNull);
    expect(result.failure, BattleSplAdmissionFailure.poolExhausted);
    expect(runWithManualFallback(result), ['legacy', 'hp']);
  });

  test(
    'losing the projection after playback starts recovers the remaining turn',
    () async {
      var valid = true;
      late void Function() completeEffect;
      late void Function() failEffect;
      final result = await BattleVerifiedSplLoader(await bundle()).create(
        'particle',
        emitters: schedule,
        seed: 0,
        poolCapacity: 16,
        maxTicks: 80,
        origin: ui.Offset.zero,
        pixelsPerUnit: 4,
        projection: testProjection(isValid: () => valid),
        onComplete: () => completeEffect(),
        onFailure: (_) => failEffect(),
      );
      final component = result.component!;
      addTearDown(component.dispose);
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
        onStartRecoverableTrackedEffect: (_, done, failed) {
          completeEffect = done;
          failEffect = failed;
          return component.cancel;
        },
      );
      runner.start(
        const BattleAnimationPlan(
          steps: [
            StartTrackedEffectStep(
              effectId: 'particle',
              fallbackSteps: [PlaySeStep(seName: 'legacy')],
            ),
            WaitTrackedEffectsStep(),
            PlaySeStep(seName: 'impact'),
            HudHpTweenStep(side: BattleSideId.enemy, fromHp: 40, toHp: 20),
          ],
        ),
      );
      component.update(1 / 60);
      expect(component.playback.activeParticles, greaterThan(0));
      valid = false;
      component.update(1 / 60);
      runner.update(0);
      expect(component.playback.activeParticles, 0);
      expect(events, ['legacy', 'impact', 'hp']);
    },
  );

  test('scene recovers after SPL loses projection', () async {
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
    late void Function() completeEffect;
    late void Function() failEffect;
    late BattleSplStaticComponent component;
    final sounds = <String>[];
    final hpTransitions = <int>[];
    final failures = <BattleSplAdmissionFailure>[];
    var hpWasTweening = false;
    var cancellations = 0;
    var valid = true;
    final overlay = BattleOverlayComponent(
      session: createBattleSession(
        BattleSetup.pokeMapBetaV1ForTest(
          playerPokemon: pokemon,
          enemyPokemon: pokemon,
          isTrainerBattle: false,
          trainerId: null,
        ),
      ),
      viewportSize: Vector2(390, 844),
      onPlayerChoice: (_) {},
      onCommandOverlaySnapshotChanged: (snapshot) {
        final hud = snapshot?.enemyHud;
        final isTweening = hud?.targetDisplayedHp == 15;
        if (isTweening && !hpWasTweening) {
          hpTransitions.add(hud!.hpTweenRevision);
        }
        hpWasTweening = isTweening;
      },
      playSfx: (name, {volume = 100, pitch = 100}) => sounds.add(name),
      onStartRecoverableTrackedEffect: (_, done, failed) {
        completeEffect = done;
        failEffect = failed;
        return () {
          cancellations++;
          component.cancel();
        };
      },
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(overlay.onRemove);
    final camera = overlay.children
        .whereType<BattleStage3DComponent>()
        .single
        .camera;
    const slot = BattleSlotRef.active(BattleSideId.player);
    final actor = overlay.debugPlayerCombatant!;
    final projection = BattleSplCameraProjection(
      camera: camera,
      bindings: [
        BattleSplCameraBinding(
          resolveNeutralFoot: () =>
              overlay.currentSceneLayout.combatantGeometry(slot).footAnchor,
          resolveAnchor: () {
            if (!valid || overlay.debugPlayerCombatant != actor) return null;
            final rect = actor.currentEffectAttachmentSpriteRect;
            return rect.isEmpty
                ? null
                : Vector2(rect.center.dx, rect.center.dy);
          },
        ),
      ],
    );
    final result = await BattleVerifiedSplLoader(await bundle(opaque: true))
        .create(
          'particle',
          emitters: schedule,
          seed: 0,
          poolCapacity: 16,
          maxTicks: 80,
          origin: ui.Offset.zero,
          pixelsPerUnit: 4,
          projection: projection,
          onComplete: () => completeEffect(),
          onFailure: (failure) {
            failures.add(failure);
            failEffect();
          },
        );
    expect(result.failure, isNull);
    component = result.component!..priority = 9999;
    addTearDown(component.dispose);
    overlay.add(component);
    overlay.findGame()!.processLifecycleEvents();
    await component.loaded;
    overlay.findGame()!.processLifecycleEvents();

    Future<Uint8List> scenePixels() async {
      final recorder = ui.PictureRecorder();
      overlay.renderTree(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(390, 844);
      try {
        return Uint8List.fromList(
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
              .asUint8List(),
        );
      } finally {
        image.dispose();
        picture.dispose();
      }
    }

    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(
            effectId: 'particle',
            fallbackSteps: [
              PlaySeStep(seName: 'fallback'),
              WaitStep(durationSeconds: .05),
            ],
          ),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'impact'),
          HudHpTweenStep(
            side: BattleSideId.enemy,
            fromHp: 25,
            toHp: 15,
            durationMs: 320,
          ),
          PlaySeStep(seName: 'after-hp'),
        ],
      ),
    );
    overlay.updateTree(1 / 60);
    expect(component.playback.activeParticles, greaterThan(0));
    final visible = await scenePixels();
    component.scale.setValues(0, 0);
    final hidden = await scenePixels();
    component.scale.setValues(1, 1);
    expect(visible, isNot(orderedEquals(hidden)));
    expect(sounds, isEmpty);
    expect(hpTransitions, isEmpty);

    valid = false;
    overlay.updateTree(.001);
    expect(failures, [BattleSplAdmissionFailure.projectionUnavailable]);
    expect(component.playback.activeParticles, 0);
    expect(cancellations, 1);
    expect(sounds, ['fallback']);
    expect(hpTransitions, isEmpty);

    completeEffect();
    failEffect();
    overlay.updateTree(.06);
    expect(sounds, ['fallback', 'impact']);
    expect(hpTransitions, [1]);
    final hud = overlay.currentCommandOverlaySnapshot!.enemyHud;
    expect(hud.displayedHp, 25);
    expect(hud.targetDisplayedHp, 15);
    completeEffect();
    failEffect();
    overlay.updateTree(.4);
    expect(sounds, ['fallback', 'impact', 'after-hp']);
    expect(hpTransitions, [1]);
    expect(cancellations, 1);
    expect(failures, [BattleSplAdmissionFailure.projectionUnavailable]);
    overlay.findGame()!.processLifecycleEvents();
    expect(component.isMounted, isFalse);
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
        projection: testProjection(),
        onComplete: () => fail('played'),
        onFailure: (_) => fail('played'),
      ),
      throwsStateError,
    );
    expect(created, isNotEmpty);
    expect(disposed, containsAll(created));
  });

  test(
    'projection lost during decoding refuses playback and releases images',
    () async {
      final loader = BattleVerifiedSplLoader(await bundle());
      var valid = true;
      final created = <ui.Image>[];
      final disposed = <ui.Image>[];
      final previousCreate = ui.Image.onCreate;
      final previousDispose = ui.Image.onDispose;
      ui.Image.onCreate = (image) {
        created.add(image);
        valid = false;
      };
      ui.Image.onDispose = disposed.add;
      addTearDown(() {
        ui.Image.onCreate = previousCreate;
        ui.Image.onDispose = previousDispose;
      });

      final result = await loader.create(
        'particle',
        emitters: schedule,
        seed: 0,
        poolCapacity: 16,
        maxTicks: 80,
        origin: ui.Offset.zero,
        pixelsPerUnit: 4,
        projection: testProjection(isValid: () => valid),
        onComplete: () => fail('played'),
        onFailure: (_) => fail('played'),
      );
      expect(result.component, isNull);
      expect(result.failure, BattleSplAdmissionFailure.projectionUnavailable);
      expect(created, isNotEmpty);
      expect(disposed, containsAll(created));
    },
  );

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
        projection: testProjection(),
        onComplete: () => fail('played'),
        onFailure: (_) => fail('played'),
      ),
      throwsFormatException,
    );
    expect(created, isNotEmpty);
    expect(disposed, containsAll(created));
  });
}

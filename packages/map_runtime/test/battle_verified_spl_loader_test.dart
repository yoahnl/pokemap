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
  bool grouped = false,
  bool radial = false,
}) async {
  final raw = jsonDecode(
    await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString(),
  ) as Map<String, dynamic>;
  if (radial) {
    raw['schemaVersion'] = 3;
    (((raw['emitters'] as List).single as Map)['emission']
            as Map)['positionVelocity'] =
        914;
  }
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
        'requiredCapabilities': [
          if (grouped) 'parallel',
          'startParticle',
          radial ? 'splParticleV3' : 'splParticleV2',
        ],
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
            'definitionVersion': radial ? 3 : 2,
            'dependencies': ['tex'],
          },
          if (grouped)
            {
              'id': 'particle2',
              'role': 'particleDefinition',
              'mediaType': 'application/vnd.avelune.particle+json',
              'sizeBytes': particle.length,
              'sha256': sha256.convert(particle).toString(),
              'definitionVersion': radial ? 3 : 2,
              'dependencies': ['tex'],
            },
        ],
        'program': grouped
            ? {
                'kind': 'parallel',
                'steps': [
                  {
                    'kind': 'startParticle',
                    'resourceId': 'particle',
                    'from': 'userMouth',
                    'to': 'targetImpact',
                  },
                  {
                    'kind': 'startParticle',
                    'resourceId': 'particle2',
                    'from': 'targetImpact',
                    'to': 'targetImpact',
                  },
                ],
              }
            : {
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
    {'tex': png, 'particle': particle, if (grouped) 'particle2': particle},
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

  test('loads versioned radial emitters into one verified group', () async {
    final inspected = await bundle(grouped: true, radial: true);
    final baseProjection = testProjection();
    final result = await BattleVerifiedSplLoader(inspected).createGrouped(
      ['particle', 'particle2'],
      emitters: const [
        BattleSplStaticEmitter(
          emitterIndex: 0,
          startTick: 0,
          position: (x: 0, y: 0, z: 0),
        ),
        BattleSplStaticEmitter(
          emitterIndex: 1,
          startTick: 0,
          position: (x: 0, y: 0, z: 0),
        ),
      ],
      seed: 0,
      poolCapacity: 32,
      maxTicks: 80,
      origin: ui.Offset.zero,
      pixelsPerUnit: 4,
      projection: BattleSplCameraProjection(
        camera: baseProjection.camera,
        bindings: [
          baseProjection.bindings.single,
          baseProjection.bindings.single,
        ],
      ),
      onComplete: () {},
      onFailure: (_) => fail('unexpected failure'),
    );
    expect(result.failure, isNull);
    final component = result.component!;
    addTearDown(component.dispose);
    expect(component.playback.advance(), isNull);
    expect(
      component.playback.frames.expand((frame) => frame.particles),
      isNotEmpty,
    );
  });

  test('prepares grouped SPL definitions with one shared playback', () async {
    final inspected = await bundle(grouped: true);
    final loader = BattleVerifiedSplLoader(inspected);
    final baseProjection = testProjection();
    final projection = BattleSplCameraProjection(
      camera: baseProjection.camera,
      bindings: [
        baseProjection.bindings.single,
        baseProjection.bindings.single,
      ],
    );
    const emitters = [
      BattleSplStaticEmitter(
        emitterIndex: 0,
        startTick: 0,
        position: (x: 0, y: 0, z: 0),
      ),
      BattleSplStaticEmitter(
        emitterIndex: 1,
        startTick: 0,
        position: (x: 0, y: 4096, z: 0),
      ),
    ];
    final result = await loader.createGrouped(
      ['particle', 'particle2'],
      emitters: emitters,
      seed: 0,
      poolCapacity: 32,
      maxTicks: 80,
      origin: ui.Offset.zero,
      pixelsPerUnit: 4.0,
      projection: projection,
      onComplete: () {},
      onFailure: (BattleSplAdmissionFailure _) => fail('unexpected failure'),
    );
    expect(result.failure, isNull);
    final component = result.component!;
    addTearDown(component.dispose);
    final definitions = inspected.recipe.readVerifiedSplParticleDefinitions(
      inspected.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    );
    final combined = BattleSplParticleDefinition.fromJson({
      'schemaVersion': 2,
      'emitters': [
        ...definitions['particle']!.toJson()['emitters'] as List,
        ...definitions['particle2']!.toJson()['emitters'] as List,
      ],
    });
    final expected = BattleSplStaticAdmission.prepare(
      definition: combined,
      textureIndices: {'tex': 0},
      emitters: emitters,
      seed: 0,
      poolCapacity: 32,
      maxTicks: 80,
    ).playback!;
    addTearDown(expected.cancel);
    List<Object?> snapshot(BattleSplStaticPlayback playback) => [
      for (final frame in playback.frames)
        [
          for (final particle in frame.particles)
            [
              particle.id,
              particle.parentId,
              particle.motion.position,
              particle.motion.velocity,
              particle.scale4096,
              particle.alpha5,
              particle.color,
              particle.texture,
            ],
        ],
    ];
    for (var i = 0; i < 80 && !expected.isComplete; i++) {
      expect(component.playback.advance(), isNull);
      expect(expected.advance(), isNull);
      expect(
        snapshot(component.playback),
        snapshot(expected),
        reason: 'tick $i',
      );
    }
    expect(component.playback.isComplete, isTrue);
  });

  test('rejects incomplete or oversized SPL groups before decoding', () async {
    final inspected = await bundle(grouped: true);
    final created = <ui.Image>[];
    final previousCreate = ui.Image.onCreate;
    ui.Image.onCreate = created.add;
    addTearDown(() => ui.Image.onCreate = previousCreate);

    for (final ids in [
      <String>[],
      ['particle', 'missing'],
      List.filled(33, 'particle'),
    ]) {
      final loader = BattleVerifiedSplLoader(inspected);
      await expectLater(
        loader.createGrouped(
          ids,
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
        throwsFormatException,
      );
    }
    expect(created, isEmpty);
  });

  test(
    'scene clock subdivides uneven frames for grouped SPL effects',
    () async {
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
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final base = testProjection();
      final failures = <BattleSplAdmissionFailure>[];
      final result = await BattleVerifiedSplLoader(await bundle(grouped: true))
          .createGrouped(
            ['particle', 'particle2'],
            emitters: const [
              BattleSplStaticEmitter(
                emitterIndex: 0,
                startTick: 0,
                position: (x: 0, y: 0, z: 0),
              ),
              BattleSplStaticEmitter(
                emitterIndex: 1,
                startTick: 0,
                position: (x: 0, y: 0, z: 0),
              ),
            ],
            seed: 0,
            poolCapacity: 32,
            maxTicks: 80,
            origin: ui.Offset.zero,
            pixelsPerUnit: 4,
            projection: BattleSplCameraProjection(
              camera: base.camera,
              bindings: List.filled(2, base.bindings.single),
            ),
            onComplete: () {},
            onFailure: failures.add,
          );
      final component = result.component!;
      addTearDown(component.dispose);
      overlay.add(component);
      overlay.findGame()!.processLifecycleEvents();
      await component.loaded;
      overlay.findGame()!.processLifecycleEvents();
      overlay.updateTree(1.5 / 60);
      expect(component.playback.tick, 1);
      overlay.updateTree(1.5 / 60);
      expect(component.playback.tick, 3);
      expect(failures, isEmpty);
    },
  );

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

  test('scene recovers after a particle crosses the camera plane', () async {
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
    final failures = <BattleSplAdmissionFailure>[];
    var hpTransitions = 0;
    var hpWasTweening = false;
    var cancellations = 0;
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
        final isTweening = snapshot?.enemyHud.targetDisplayedHp == 15;
        if (isTweening && !hpWasTweening) {
          hpTransitions++;
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
    final projection = BattleSplCameraProjection(
      camera: camera,
      worldTransform: const BattleSplWorldTransform(
        worldUnitsPerUnit: 1,
        yawRadians: 0,
      ),
      bindings: [
        BattleSplCameraBinding(
          resolveNeutralFoot: () =>
              overlay.currentSceneLayout.combatantGeometry(slot).footAnchor,
          resolveAnchor: () {
            final foot = overlay.currentSceneLayout
                .combatantGeometry(slot)
                .footAnchor;
            final point = camera.tryBillboardAt(foot)?.position;
            return point == null ? null : Vector2(point.dx, point.dy);
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
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(
            effectId: 'particle',
            fallbackSteps: [PlaySeStep(seName: 'fallback')],
          ),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'impact'),
          HudHpTweenStep(
            side: BattleSideId.enemy,
            fromHp: 25,
            toHp: 15,
            durationMs: 320,
          ),
        ],
      ),
    );
    overlay.updateTree(1 / 60);
    expect(component.playback.activeParticles, greaterThan(0));
    final visibleRecorder = ui.PictureRecorder();
    component.render(ui.Canvas(visibleRecorder));
    final visiblePicture = visibleRecorder.endRecording();
    final visibleImage = await visiblePicture.toImage(390, 844);
    try {
      final bytes = (await visibleImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      expect(bytes.any((value) => value != 0), isTrue);
    } finally {
      visibleImage.dispose();
      visiblePicture.dispose();
    }
    expect(sounds, isEmpty);
    final anchor = projection.capture()!.single;
    final particle = component.playback.frames.single.particles.first;
    final position = particle.motion.position;
    final emitter = particle.emitterPosition;
    final delta = BattleCameraPoint(
      (position.x + emitter.x) / 4096,
      (position.y + emitter.y) / 4096,
      (position.z + emitter.z) / 4096,
    );
    expect(delta.length, greaterThan(.04));
    final anchorPosition = BattleCameraPoint(anchor.x, anchor.y, anchor.z);
    camera.moveTo(
      eye: anchorPosition + delta * .5,
      aim: anchorPosition,
      durationSeconds: 0,
    );
    expect(component.refreshAttachment(), isTrue);
    final recorder = ui.PictureRecorder();
    component.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
    overlay.updateTree(0);
    expect(failures, [BattleSplAdmissionFailure.projectionUnavailable]);
    expect(cancellations, 1);
    expect(sounds, ['fallback', 'impact']);
    expect(hpTransitions, 1);
    expect(
      overlay.currentCommandOverlaySnapshot!.enemyHud.targetDisplayedHp,
      15,
    );
    completeEffect();
    failEffect();
    overlay.updateTree(.4);
    expect(failures, [BattleSplAdmissionFailure.projectionUnavailable]);
    expect(cancellations, 1);
    expect(sounds, ['fallback', 'impact']);
    expect(hpTransitions, 1);
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

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_particle_synthetic_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_particle_loader.dart';

import 'support/load_flame_component.dart';

Future<ui.Image> redTexture() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xffff0000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  picture.dispose();
  return image;
}

BattleParticleDefinition definition(
  Uint8List png, {
  int emissionDurationMs = 100,
  int emissionIntervalMs = 100,
  int particleLifetimeMs = 100,
}) {
  final bytes = utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'emitters': [
        {
          'textureId': 'tex',
          'emissionDurationMs': emissionDurationMs,
          'emissionIntervalMs': emissionIntervalMs,
          'particleLifetimeMs': particleLifetimeMs,
          'particlesPerEmission': 1,
        },
      ],
    }),
  );
  Map<String, dynamic> resource(
    String id,
    String role,
    String type,
    List<int> data,
  ) => {
    'id': id,
    'role': role,
    'mediaType': type,
    'sizeBytes': data.length,
    'sha256': sha256.convert(data).toString(),
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
          bytes,
        ),
        'definitionVersion': 1,
        'dependencies': ['tex'],
      },
      resource('tex', 'texture', 'image/png', png),
    ],
    'program': {
      'kind': 'startParticle',
      'resourceId': 'particle',
      'from': 'userMouth',
      'to': 'targetImpact',
    },
  });
  return recipe.readVerifiedParticleDefinitions(
    {'particle': bytes, 'tex': png},
    availableCapabilities: {'startParticle'},
  )['particle']!;
}

Future<List<int>> frame(
  BattleParticleSyntheticComponent component, {
  int x = 2,
  int y = 2,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  component.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 8);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final pixel = List<int>.of(
    data.buffer.asUint8List().sublist((y * 8 + x) * 4, (y * 8 + x) * 4 + 4),
  );
  image.dispose();
  picture.dispose();
  return pixel;
}

Future<List<int>> sceneFrame(
  BattleOverlayComponent overlay, {
  int x = 2,
  int y = 2,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  overlay.renderTree(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(390, 844);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = (y * 390 + x) * 4;
  final pixel = List<int>.of(
    data.buffer.asUint8List().sublist(offset, offset + 4),
  );
  image.dispose();
  picture.dispose();
  return pixel;
}

InspectedBattleRecipeBundle inspectedFixture(Uint8List png) {
  final particle = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'emitters': [
          {
            'textureId': 'tex',
            'emissionDurationMs': 100,
            'emissionIntervalMs': 100,
            'particleLifetimeMs': 100,
            'particlesPerEmission': 1,
          },
        ],
      }),
    ),
  );
  Map<String, dynamic> resource(
    String id,
    String role,
    String type,
    Uint8List bytes,
  ) => {
    'id': id,
    'role': role,
    'mediaType': type,
    'sizeBytes': bytes.length,
    'sha256': sha256.convert(bytes).toString(),
  };
  final recipe = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'recipeId': 'fire',
        'revision': '1',
        'moveSourceId': 'fire',
        'variant': 'default',
        'requiredCapabilities': ['startParticle'],
        'provenance': {
          'source': 'synthetic',
          'sourceRevision': '1',
          'sourcePaths': <String>[],
          'converter': 'test',
        },
        'resources': [
          {
            ...resource(
              'particle',
              'particleDefinition',
              'application/vnd.avelune.particle+json',
              particle,
            ),
            'definitionVersion': 1,
            'dependencies': ['tex'],
          },
          resource('tex', 'texture', 'image/png', png),
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
    'projectMoveId': 'fire',
    'sourceMoveId': 'fire',
    'catalogReleaseId': 'test',
    'recipeId': 'fire',
    'variant': 'default',
    'revision': '1',
    'recipeSha256': sha256.convert(recipe).toString(),
  });
  return const BattleRecipeBundleInspector().inspect(
    binding,
    recipe,
    {'particle': particle, 'tex': png},
    limits: const BattleRecipeBundleLimits(
      maxTextures: 1,
      maxTextureBytes: 10000,
      maxBundleBytes: 20000,
      maxDimension: 8,
      maxTexturePixels: 64,
      maxTotalPixels: 64,
    ),
    availableCapabilities: {'startParticle'},
    expectedProjectMoveId: 'fire',
    expectedCatalogReleaseId: 'test',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('follows a live anchor and stops when its subject disappears', () async {
    final image = await redTexture();
    final png = Uint8List.fromList(
      (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    final center = Vector2(3, 3);
    var subjectIsCurrent = true;
    var invalidations = 0;
    var completions = 0;
    final created = <ui.Image>[];
    final disposed = <ui.Image>[];
    final previousCreate = ui.Image.onCreate;
    final previousDispose = ui.Image.onDispose;
    ui.Image.onCreate = created.add;
    ui.Image.onDispose = disposed.add;
    final component = BattleParticleSyntheticComponent(
      definition: definition(png),
      textures: {'tex': image},
      centers: const [ui.Offset(3, 3)],
      centerResolvers: [() => subjectIsCurrent ? center : null],
      maxTextures: 1,
      maxDimension: 8,
      maxTotalPixels: 64,
      onComplete: () => completions++,
      onInvalidated: () => invalidations++,
    );
    final ownedImage = created.single;
    addTearDown(() {
      component.dispose();
      image.dispose();
      ui.Image.onCreate = previousCreate;
      ui.Image.onDispose = previousDispose;
    });
    component.update(0);
    expect(await frame(component), [255, 0, 0, 255]);
    center.setValues(6, 6);
    component.update(0);
    expect(await frame(component), [0, 0, 0, 0]);
    expect(await frame(component, x: 5, y: 5), [255, 0, 0, 255]);
    subjectIsCurrent = false;
    component.update(0);
    expect(await frame(component, x: 5, y: 5), [0, 0, 0, 0]);
    expect(disposed.any((value) => identical(value, ownedImage)), isTrue);
    expect(invalidations, 1);
    expect(completions, 0);
    component.update(1);
    expect(invalidations, 1);
    expect(completions, 0);
  });

  test('verified particles retain live attachment and invalidation', () async {
    final image = await redTexture();
    final png = Uint8List.fromList(
      (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    image.dispose();
    final center = Vector2(3, 3);
    var valid = true;
    var invalidations = 0;
    final component = await BattleVerifiedParticleLoader(inspectedFixture(png))
        .create(
          'particle',
          centers: const [ui.Offset(3, 3)],
          centerResolvers: [() => valid ? center : null],
          onInvalidated: () => invalidations++,
        );
    addTearDown(component.dispose);
    component.update(0);
    center.setValues(6, 6);
    expect(component.refreshAttachment(), isTrue);
    expect(await frame(component, x: 5, y: 5), [255, 0, 0, 255]);
    valid = false;
    expect(component.refreshAttachment(), isFalse);
    expect(await frame(component, x: 5, y: 5), [0, 0, 0, 0]);
    expect(invalidations, 1);
  });

  test('an invalid anchor releases its tracked effect barrier', () async {
    final image = await redTexture();
    final png = Uint8List.fromList(
      (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    var center = Vector2(3, 3);
    late void Function() finishEffect;
    final component = BattleParticleSyntheticComponent(
      definition: definition(png),
      textures: {'tex': image},
      centers: const [ui.Offset(3, 3)],
      centerResolvers: [() => center],
      maxTextures: 1,
      maxDimension: 8,
      maxTotalPixels: 64,
      onComplete: () => finishEffect(),
      onInvalidated: () => finishEffect(),
    );
    addTearDown(() {
      component.dispose();
      image.dispose();
    });
    final events = <String>[];
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
      onPlaySe: (step) => events.add(step.seName),
      onStartTrackedEffect: (_, finish) {
        finishEffect = finish;
        return component.cancel;
      },
    );
    runner.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(effectId: 'particle'),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'after'),
        ],
      ),
    );
    component.update(0);
    expect(events, isEmpty);
    center = Vector2(double.nan, 3);
    component.update(0);
    runner.update(0);
    expect(events, ['after']);
    expect(await frame(component), [0, 0, 0, 0]);
  });

  test('renders the inspected snapshot after the input bytes change', () async {
    final original = await redTexture();
    final png = Uint8List.fromList(
      (await original.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    original.dispose();
    final bundle = inspectedFixture(png);
    png.fillRange(0, png.length, 0);
    final load = BattleVerifiedParticleLoader(bundle);
    final component = await load.create(
      'particle',
      centers: const [ui.Offset(3, 3)],
    );
    addTearDown(component.dispose);
    component.update(0);
    expect(await frame(component), [255, 0, 0, 255]);
    component.dispose();
    expect(await frame(component), [0, 0, 0, 0]);
  });

  test(
    'cancelling an in-flight decode prevents a component from escaping',
    () async {
      final original = await redTexture();
      final png = Uint8List.fromList(
        (await original.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      original.dispose();
      final load = BattleVerifiedParticleLoader(inspectedFixture(png));
      final result = load.create('particle', centers: const [ui.Offset(3, 3)]);
      load.cancel();
      await expectLater(result, throwsStateError);
    },
  );

  test(
    'cancellation after image creation disposes the decoded handle',
    () async {
      final original = await redTexture();
      final png = Uint8List.fromList(
        (await original.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      original.dispose();
      final load = BattleVerifiedParticleLoader(inspectedFixture(png));
      final created = <ui.Image>[];
      final disposed = <ui.Image>[];
      final previousCreate = ui.Image.onCreate;
      final previousDispose = ui.Image.onDispose;
      ui.Image.onCreate = (image) {
        created.add(image);
        load.cancel();
      };
      ui.Image.onDispose = disposed.add;
      addTearDown(() {
        ui.Image.onCreate = previousCreate;
        ui.Image.onDispose = previousDispose;
      });
      await expectLater(
        load.create('particle', centers: const [ui.Offset(3, 3)]),
        throwsStateError,
      );
      expect(created, isNotEmpty);
      expect(disposed, containsAll(created));
    },
  );

  test('construction failure disposes decoded handles', () async {
    final original = await redTexture();
    final png = Uint8List.fromList(
      (await original.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    original.dispose();
    final load = BattleVerifiedParticleLoader(inspectedFixture(png));
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
      load.create('particle', centers: const []),
      throwsFormatException,
    );
    expect(created, isNotEmpty);
    expect(disposed, containsAll(created));
  });

  test('renders the synthetic texture until the timeline completes', () async {
    final original = await redTexture();
    final png = Uint8List.fromList(
      (await original.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    var completions = 0;
    final component = BattleParticleSyntheticComponent(
      definition: definition(png),
      textures: {'tex': original},
      centers: const [ui.Offset(3, 3)],
      maxTextures: 1,
      maxDimension: 8,
      maxTotalPixels: 64,
      onComplete: () => completions++,
    );
    original.dispose();
    addTearDown(component.dispose);
    component.update(0);
    expect(await frame(component), [255, 0, 0, 255]);
    component.update(.099);
    expect(await frame(component), [255, 0, 0, 255]);
    expect(completions, 0);
    component.update(.001);
    expect(await frame(component), [0, 0, 0, 0]);
    expect(completions, 1);
    component.update(1);
    expect(completions, 1);
    expect(component.isComplete, isTrue);
    component.dispose();
    expect(component.isComplete, isTrue);
  });

  test(
    'cancellation clears pixels without claiming natural completion',
    () async {
      final image = await redTexture();
      final png = Uint8List.fromList(
        (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      var completions = 0;
      final component = BattleParticleSyntheticComponent(
        definition: definition(png),
        textures: {'tex': image},
        centers: const [ui.Offset(3, 3)],
        maxTextures: 1,
        maxDimension: 8,
        maxTotalPixels: 64,
        onComplete: () => completions++,
      );
      addTearDown(() {
        component.dispose();
        image.dispose();
      });
      component.update(0);
      component.cancel();
      expect(await frame(component), [0, 0, 0, 0]);
      component.update(1);
      expect(completions, 0);
    },
  );

  test('refuses missing textures and decoded dimensions over budget', () async {
    final image = await redTexture();
    addTearDown(image.dispose);
    final png = Uint8List.fromList(
      (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    final spec = definition(png);
    expect(
      () => BattleParticleSyntheticComponent(
        definition: spec,
        textures: {'tex': image},
        centers: const [ui.Offset(3, 3)],
        centerResolvers: [() => Vector2(3, 3)],
        maxTextures: 1,
        maxDimension: 8,
        maxTotalPixels: 64,
      ),
      throwsFormatException,
    );
    expect(
      () => BattleParticleSyntheticComponent(
        definition: spec,
        textures: const {},
        centers: const [ui.Offset(3, 3)],
        maxTextures: 1,
        maxDimension: 8,
        maxTotalPixels: 64,
      ),
      throwsFormatException,
    );
    expect(
      () => BattleParticleSyntheticComponent(
        definition: spec,
        textures: {'tex': image},
        centers: const [ui.Offset(3, 3)],
        maxTextures: 1,
        maxDimension: 1,
        maxTotalPixels: 64,
      ),
      throwsFormatException,
    );
    expect(
      () => BattleParticleSyntheticComponent(
        definition: spec,
        textures: {'tex': image},
        centers: const [ui.Offset(3, 3)],
        maxTextures: 1,
        maxDimension: 8,
        maxTotalPixels: 3,
      ),
      throwsFormatException,
    );
  });

  test(
    'does not signal completion while the event budget has pending work',
    () async {
      final image = await redTexture();
      final png = Uint8List.fromList(
        (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      var completions = 0;
      final component = BattleParticleSyntheticComponent(
        definition: definition(
          png,
          emissionDurationMs: 300,
          emissionIntervalMs: 1,
          particleLifetimeMs: 300,
        ),
        textures: {'tex': image},
        centers: const [ui.Offset(3, 3)],
        maxTextures: 1,
        maxDimension: 8,
        maxTotalPixels: 64,
        onComplete: () => completions++,
      );
      addTearDown(() {
        component.dispose();
        image.dispose();
      });
      component.update(.3);
      expect(component.hasPendingEvents, isTrue);
      expect(component.activeParticles, 256);
      expect(completions, 0);
      component.update(0);
      expect(component.hasPendingEvents, isFalse);
      component.update(.299);
      expect(component.hasPendingEvents, isTrue);
      expect(completions, 0);
      component.update(0);
      expect(component.isComplete, isTrue);
      expect(completions, 1);
    },
  );

  test(
    'the battle scene clock drives rendered pixels and releases its barrier',
    () async {
      final original = await redTexture();
      final png = Uint8List.fromList(
        (await original.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      original.dispose();
      final codec = await ui.instantiateImageCodec(png);
      final decoded = (await codec.getNextFrame()).image;
      codec.dispose();
      late void Function() complete;
      final center = Vector2(3, 3);
      final component = BattleParticleSyntheticComponent(
        definition: definition(png),
        textures: {'tex': decoded},
        centers: const [ui.Offset(3, 3)],
        centerResolvers: [() => center],
        maxTextures: 1,
        maxDimension: 8,
        maxTotalPixels: 64,
        onComplete: () => complete(),
        onInvalidated: () => complete(),
      );
      component.priority = 9999;
      decoded.dispose();
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
      final sounds = <String>[];
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
        playSfx: (name, {volume = 100, pitch = 100}) => sounds.add(name),
        onStartTrackedEffect: (_, done) {
          complete = done;
          return component.cancel;
        },
      );
      overlay.add(component);
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(() {
        overlay.onRemove();
        component.dispose();
      });
      overlay.presentPostBattlePlan(
        const BattleAnimationPlan(
          steps: [
            StartTrackedEffectStep(effectId: 'synthetic'),
            WaitTrackedEffectsStep(),
            PlaySeStep(seName: 'after'),
          ],
        ),
      );
      overlay.updateTree(.05);
      expect(await frame(component), [255, 0, 0, 255]);
      expect(await sceneFrame(overlay), [255, 0, 0, 255]);
      expect(sounds, isEmpty);
      center.setValues(6, 6);
      overlay.updateTree(.001);
      expect(await frame(component), [0, 0, 0, 0]);
      expect(await sceneFrame(overlay, x: 5, y: 5), [255, 0, 0, 255]);
      overlay.updateTree(.048);
      expect(sounds, isEmpty);
      overlay.updateTree(.001);
      expect(await frame(component), [0, 0, 0, 0]);
      expect(await sceneFrame(overlay), isNot([255, 0, 0, 255]));
      expect(sounds, ['after']);
    },
  );

  test('battle scene recovers once when a particle loses its anchor', () async {
    final image = await redTexture();
    final png = Uint8List.fromList(
      (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    var valid = true;
    late void Function() completeEffect;
    late void Function() failEffect;
    final component = BattleParticleSyntheticComponent(
      definition: definition(png),
      textures: {'tex': image},
      centers: const [ui.Offset(3, 3)],
      centerResolvers: [() => valid ? Vector2(3, 3) : null],
      maxTextures: 1,
      maxDimension: 8,
      maxTotalPixels: 64,
      onComplete: () => completeEffect(),
      onInvalidated: () => failEffect(),
    )..priority = 9999;
    image.dispose();
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
    final sounds = <String>[];
    final hpTransitions = <int>[];
    var hpWasTweening = false;
    var starts = 0;
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
        final hud = snapshot?.enemyHud;
        final isTweening = hud?.targetDisplayedHp == 15;
        if (isTweening && !hpWasTweening) {
          hpTransitions.add(hud!.hpTweenRevision);
        }
        hpWasTweening = isTweening;
      },
      playSfx: (name, {volume = 100, pitch = 100}) => sounds.add(name),
      onStartRecoverableTrackedEffect: (_, done, failed) {
        starts++;
        completeEffect = done;
        failEffect = failed;
        return () {
          cancellations++;
          component.cancel();
        };
      },
    );
    overlay.add(component);
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(() {
      overlay.onRemove();
      component.dispose();
    });
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(
            effectId: 'synthetic',
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
    overlay.updateTree(.04);
    expect(starts, 1);
    expect(await sceneFrame(overlay), [255, 0, 0, 255]);
    expect(sounds, isEmpty);
    expect(hpTransitions, isEmpty);

    valid = false;
    overlay.updateTree(.001);
    expect(await frame(component), [0, 0, 0, 0]);
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
  });

  test('fractional frame durations retain their accumulated time', () async {
    final image = await redTexture();
    final png = Uint8List.fromList(
      (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    var completions = 0;
    final component = BattleParticleSyntheticComponent(
      definition: definition(png),
      textures: {'tex': image},
      centers: const [ui.Offset(3, 3)],
      maxTextures: 1,
      maxDimension: 8,
      maxTotalPixels: 64,
      onComplete: () => completions++,
    );
    addTearDown(() {
      component.dispose();
      image.dispose();
    });
    for (var i = 0; i < 5; i++) {
      component.update(1 / 60);
    }
    expect(completions, 0);
    component.update(1 / 60);
    expect(completions, 1);
  });
}

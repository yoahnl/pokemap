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

Future<List<int>> frame(BattleParticleSyntheticComponent component) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  component.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 8);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final pixel = List<int>.of(
    data.buffer.asUint8List().sublist((2 * 8 + 2) * 4, (2 * 8 + 2) * 4 + 4),
  );
  image.dispose();
  picture.dispose();
  return pixel;
}

Future<List<int>> sceneFrame(BattleOverlayComponent overlay) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  overlay.renderTree(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(390, 844);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = (2 * 390 + 2) * 4;
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
      final component = BattleParticleSyntheticComponent(
        definition: definition(png),
        textures: {'tex': decoded},
        centers: const [ui.Offset(3, 3)],
        maxTextures: 1,
        maxDimension: 8,
        maxTotalPixels: 64,
        onComplete: () => complete(),
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
      overlay.updateTree(.049);
      expect(sounds, isEmpty);
      overlay.updateTree(.001);
      expect(await frame(component), [0, 0, 0, 0]);
      expect(await sceneFrame(overlay), isNot([255, 0, 0, 255]));
      expect(sounds, ['after']);
    },
  );

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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_spl_loader.dart';

import 'support/load_flame_component.dart';

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const _directory = 'res/particles/btlv_effvm_particles/218';
const _hashes = {
  'particles.json':
      'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9',
  'texture00.png':
      'd03979b4d9e7cc4146cd28313006fc7e770e8aa83c8bffb06797f8cb5076bab1',
  'texture01.png':
      'a3dbf0ea435572f668f8ba2beb676587036035fdb6989a4583605dfa68d9e06e',
  'texture02.png':
      '3d10133124483c7c68bf8ef9df9e50d8a2bab9ed4c0f9882b5291ce8bc96260f',
  'texture03.png':
      '3eee20e4f1adbc946d4623f42fe12203fcd4919ec23988aa8fb2b932203bf137',
  'texture04.png':
      'ebce49dd55ea712ac46fa7032218fce2e8109062ff6380c55257172d6e0d44f0',
  'texture05.png':
      '9c83ad9fe9503947791501b1ecbe2705ccb67564f21e6c7aa26950c338da7e6e',
};

final class _RealHttpOverrides extends HttpOverrides {}

Future<InspectedBattleRecipeBundle> _source218Bundle() async {
  final client = HttpClient();
  try {
    Future<Uint8List> fetch(String name) async {
      final request = await client
          .getUrl(
            Uri.https(
              'raw.githubusercontent.com',
              '/fuddlesworth/pokebw2/$_revision/$_directory/$name',
            ),
          )
          .timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('Source $name returned ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        if (builder.length + chunk.length > 262144) {
          throw const FormatException('Source too large');
        }
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (sha256.convert(bytes).toString() != _hashes[name]) {
        throw StateError('Source digest mismatch: $name');
      }
      return bytes;
    }

    final results = await Future.wait(_hashes.keys.map(fetch));
    final sources = Map.fromIterables(_hashes.keys, results);
    final converted = Gen5SplParticleConverter.convert(
      sources['particles.json']!,
      particleId: 218,
      sourceRevision: _revision,
      sourcePath: '$_directory/particles.json',
      expectedSha256: _hashes['particles.json']!,
      textureResourceIds: {
        for (var i = 0; i < 6; i++) 'texture0$i': 'texture0$i',
      },
    );
    final particle = Uint8List.fromList(
      utf8.encode(jsonEncode(converted.definition.toJson())),
    );
    final media = <String, Uint8List>{
      'particle': particle,
      for (var i = 0; i < 6; i++) 'texture0$i': sources['texture0$i.png']!,
    };
    Map<String, dynamic> resource(String id, String role, String mediaType) => {
      'id': id,
      'role': role,
      'mediaType': mediaType,
      'sizeBytes': media[id]!.length,
      'sha256': sha256.convert(media[id]!).toString(),
    };
    final recipe = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'schemaVersion': 1,
          'recipeId': 'source218',
          'revision': '1',
          'moveSourceId': 'flamethrower',
          'variant': 'default',
          'requiredCapabilities': ['startParticle', 'splParticleV2'],
          'provenance': {
            'source': 'pokebw2',
            'sourceRevision': _revision,
            'sourcePaths': ['$_directory/particles.json'],
            'converter': 'test',
          },
          'resources': [
            for (var i = 0; i < 6; i++)
              resource('texture0$i', 'texture', 'image/png'),
            {
              ...resource(
                'particle',
                'particleDefinition',
                'application/vnd.avelune.particle+json',
              ),
              'definitionVersion': 2,
              'dependencies': [for (var i = 0; i < 6; i++) 'texture0$i'],
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
      'projectMoveId': 'fire',
      'sourceMoveId': 'flamethrower',
      'catalogReleaseId': 'test',
      'recipeId': 'source218',
      'variant': 'default',
      'revision': '1',
      'recipeSha256': sha256.convert(recipe).toString(),
    });
    return const BattleRecipeBundleInspector().inspect(
      binding,
      recipe,
      media,
      limits: const BattleRecipeBundleLimits(
        maxTextures: 6,
        maxTextureBytes: 65536,
        maxBundleBytes: 524288,
        maxDimension: 512,
        maxTexturePixels: 262144,
        maxTotalPixels: 524288,
      ),
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      expectedProjectMoveId: 'fire',
      expectedCatalogReleaseId: 'test',
    );
  } finally {
    client.close(force: true);
  }
}

Future<Uint8List> _scenePixels(BattleOverlayComponent overlay) async {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'source 218 renders in the battle scene and releases the runner barrier',
    () async {
      final bundle = await HttpOverrides.runWithHttpOverrides(
        _source218Bundle,
        _RealHttpOverrides(),
      );
      late void Function() finishEffect;
      final prepared = await BattleVerifiedSplLoader(bundle).create(
        'particle',
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
        origin: const ui.Offset(90, 140),
        pixelsPerUnit: 5,
        onComplete: () => finishEffect(),
        onFailure: (failure) => fail('Unexpected SPL failure: $failure'),
      );
      expect(prepared.failure, isNull);
      final effect = prepared.component!..priority = 9999;
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
          finishEffect = done;
          return effect.cancel;
        },
      );
      overlay.add(effect);
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(() {
        overlay.onRemove();
        effect.dispose();
      });
      overlay.presentPostBattlePlan(
        const BattleAnimationPlan(
          steps: [
            StartTrackedEffectStep(effectId: 'source218'),
            WaitTrackedEffectsStep(),
            PlaySeStep(seName: 'after'),
          ],
        ),
      );

      final seen = <int>{};
      var childSeen = false;
      for (var i = 0; i < 12; i++) {
        overlay.updateTree(1 / 60);
        for (final frame in effect.playback.frames) {
          if (frame.particles.isNotEmpty) seen.add(frame.emitterIndex);
          if (frame.particles.any((particle) => particle.parentId != null)) {
            childSeen = true;
          }
        }
      }
      expect(effect.playback.activeParticles, greaterThan(0));
      expect(sounds, isEmpty);
      final visible = await _scenePixels(overlay);
      effect.scale.setValues(0, 0);
      final hidden = await _scenePixels(overlay);
      effect.scale.setValues(1, 1);
      var changed = 0;
      for (var i = 0; i < visible.length; i += 4) {
        if (visible[i] != hidden[i] ||
            visible[i + 1] != hidden[i + 1] ||
            visible[i + 2] != hidden[i + 2] ||
            visible[i + 3] != hidden[i + 3]) {
          changed++;
        }
      }
      expect(changed, greaterThan(0));

      for (var i = 12; i < 205 && sounds.isEmpty; i++) {
        overlay.updateTree(1 / 60);
        for (final frame in effect.playback.frames) {
          if (frame.particles.isNotEmpty) seen.add(frame.emitterIndex);
          if (frame.particles.any((particle) => particle.parentId != null)) {
            childSeen = true;
          }
        }
      }
      expect(seen, {0, 1, 2, 3});
      expect(childSeen, isTrue);
      expect(effect.playback.activeParticles, 0);
      expect(sounds, ['after']);
      overlay.findGame()!.processLifecycleEvents();
      expect(effect.isMounted, isFalse);
      expect(overlay.children.contains(effect), isFalse);
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1',
  );
}

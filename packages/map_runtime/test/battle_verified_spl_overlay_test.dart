import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
import 'package:map_runtime/src/presentation/flame/battle_spl_camera_projection.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_spl_loader.dart';

import '../../map_authoring/test/support/bw2_vm_trace.dart';
import 'support/load_flame_component.dart';

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const _directory = 'res/particles/btlv_effvm_particles/218';
const _scriptPath = 'res/battle/animations/moves/flamethrower.s';
const _scriptHash =
    '4cec7ed1fd757ee10d8e6f07941cefcd709cbaaac365ecf7782593a5dcc897f9';
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

Future<({InspectedBattleRecipeBundle bundle, Uint8List script})>
_source218Bundle() async {
  final client = HttpClient();
  try {
    Future<Uint8List> fetch(String path, String expectedHash) async {
      final request = await client
          .getUrl(
            Uri.https(
              'raw.githubusercontent.com',
              '/fuddlesworth/pokebw2/$_revision/$path',
            ),
          )
          .timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('Source $path returned ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        if (builder.length + chunk.length > 262144) {
          throw const FormatException('Source too large');
        }
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (sha256.convert(bytes).toString() != expectedHash) {
        throw StateError('Source digest mismatch: $path');
      }
      return bytes;
    }

    final results = await Future.wait([
      for (final entry in _hashes.entries)
        fetch('$_directory/${entry.key}', entry.value),
      fetch(_scriptPath, _scriptHash),
    ]);
    final sources = Map.fromIterables(
      _hashes.keys,
      results.take(_hashes.length),
    );
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
    final bundle = const BattleRecipeBundleInspector().inspect(
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
    return (bundle: bundle, script: results.last);
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

Future<Uint8List> _effectPixels(BattleSplStaticComponent effect) async {
  final recorder = ui.PictureRecorder();
  effect.render(ui.Canvas(recorder));
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

bool _hasPixelNear(Uint8List pixels, ui.Offset point, int radius) {
  final left = math.max(0, (point.dx - radius).floor());
  final right = math.min(389, (point.dx + radius).ceil());
  final top = math.max(0, (point.dy - radius).floor());
  final bottom = math.min(843, (point.dy + radius).ceil());
  for (var y = top; y <= bottom; y++) {
    for (var x = left; x <= right; x++) {
      if (pixels[(y * 390 + x) * 4 + 3] != 0) return true;
    }
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'source 218 follows traced timing with camera and sound intents',
    () async {
      final source = await HttpOverrides.runWithHttpOverrides(
        _source218Bundle,
        _RealHttpOverrides(),
      );
      final trace = traceBw2VmSegment(
        source.script,
        sourceRevision: _revision,
        sourcePath: _scriptPath,
        expectedSha256: _scriptHash,
      );
      final emitterEvents = trace
          .where(
            (event) =>
                event.instruction == 'EmitterMove' ||
                event.instruction == 'EmitterAdd',
          )
          .toList();
      final firstEmitterCall = emitterEvents.first.call;
      expect(
        emitterEvents
            .map(
              (event) => (
                int.parse(event.arguments[1]),
                event.call - firstEmitterCall,
              ),
            )
            .toList(),
        [(0, 0), (1, 1), (3, 52), (2, 53)],
      );
      final cameraEvent = trace.singleWhere(
        (event) => event.instruction == 'CameraMovePreset',
      );
      expect(cameraEvent.arguments, ['1', '11', '16', '0', '8']);
      final cameraStart = cameraEvent.call - firstEmitterCall;
      final cameraDuration = int.parse(cameraEvent.arguments[2]);
      expect(cameraStart, 23);
      expect(
        trace
            .where((event) => event.instruction == 'WaitFrames')
            .map((event) => event.arguments.single),
        ['20', '26'],
      );
      final soundEvents = trace
          .where((event) => event.instruction == 'PlaySE')
          .toList();
      expect(soundEvents.map((event) => event.arguments.first), [
        'SEQ_SE_W307_01',
        'SEQ_SE_W027_01',
        'SEQ_SE_W001_01',
        'SEQ_SE_BE_SE_016',
        'SEQ_SE_BE_SE_016',
        'SEQ_SE_W307_02',
      ]);
      expect(soundEvents.map((event) => event.call - firstEmitterCall), [
        -1,
        -1,
        51,
        51,
        51,
        51,
      ]);
      expect(soundEvents.map((event) => int.parse(event.arguments[3])), [
        0,
        0,
        0,
        0,
        30,
        10,
      ]);
      expect(
        soundEvents.map((event) => (event.arguments[4], event.arguments[5])),
        [
          ('0', '120'),
          ('2000', '100'),
          ('-500', '100'),
          ('0', '127'),
          ('0', '127'),
          ('0', '127'),
        ],
      );
      final soundAutomation = trace
          .where(
            (event) =>
                event.instruction == 'MoveSE' || event.instruction == 'PanSE',
          )
          .toList();
      expect(soundAutomation.map((event) => event.arguments), [
        ['2', '0', '0', '-3000', '0', '0', '60', '0', '0'],
        ['1', '0', 'EFFVM_ATTACKER', 'EFFVM_DEFENDER', '0', '40', '0', '0'],
        ['2', '0', 'EFFVM_ATTACKER', 'EFFVM_DEFENDER', '0', '40', '0', '0'],
      ]);
      expect(soundAutomation.map((event) => event.call - firstEmitterCall), [
        -1,
        -1,
        -1,
      ]);
      final impactSound = soundEvents[2];
      final soundStart = impactSound.call - firstEmitterCall;
      final marker = 'trace:${impactSound.arguments.first}';
      final schedule = <BattleSplStaticEmitter>[];
      for (final event in emitterEvents) {
        final moving = event.instruction == 'EmitterMove';
        expect(event.arguments.first, '218');
        final from = event.arguments[moving ? 3 : 2];
        expect(from, moving ? 'EFFVM_EMIT_ATTACKER' : 'EFFVM_EMIT_DEFENDER');
        expect(
          event.arguments[moving ? 4 : 3],
          moving ? 'EFFVM_EMIT_DEFENDER' : '8',
        );
        if (moving) {
          expect(event.arguments[2], '1');
          expect(event.arguments[6], '0');
        }
        schedule.add(
          BattleSplStaticEmitter(
            emitterIndex: int.parse(event.arguments[1]),
            startTick: event.call - firstEmitterCall,
            position: (
              x: 0,
              y: int.parse(event.arguments[moving ? 5 : 4]),
              z: 0,
            ),
          ),
        );
      }
      late void Function() finishEffect;
      late BattleSplStaticComponent effect;
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
      int? markerTick;
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
        playSfx: (name, {volume = 100, pitch = 100}) {
          sounds.add(name);
          if (name == marker) markerTick = effect.playback.tick;
        },
        onStartTrackedEffect: (_, done) {
          finishEffect = done;
          return effect.cancel;
        },
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);
      final camera = overlay.children
          .whereType<BattleStage3DComponent>()
          .single
          .camera;
      final player = overlay.debugPlayerCombatant!;
      final enemy = overlay.debugEnemyCombatant!;
      BattleSplCameraBinding binding(bool attacker) {
        final actor = attacker ? player : enemy;
        final slot = BattleSlotRef.active(
          attacker ? BattleSideId.player : BattleSideId.enemy,
        );
        return BattleSplCameraBinding(
          resolveNeutralFoot: () =>
              overlay.currentSceneLayout.combatantGeometry(slot).footAnchor,
          resolveAnchor: () {
            if ((attacker
                    ? overlay.debugPlayerCombatant
                    : overlay.debugEnemyCombatant) !=
                actor) {
              return null;
            }
            final rect = actor.currentEffectAttachmentSpriteRect;
            if (rect.isEmpty) return null;
            return Vector2(rect.center.dx, rect.center.dy);
          },
        );
      }

      final projection = BattleSplCameraProjection(
        camera: camera,
        bindings: [
          for (final event in emitterEvents)
            binding(event.instruction == 'EmitterMove'),
        ],
      );
      final prepared = await BattleVerifiedSplLoader(source.bundle).create(
        'particle',
        emitters: schedule,
        seed: 0,
        poolCapacity: 128,
        maxTicks: 200,
        origin: ui.Offset.zero,
        pixelsPerUnit: 5,
        projection: projection,
        onComplete: () => finishEffect(),
        onFailure: (failure) => fail('Unexpected SPL failure: $failure'),
      );
      expect(prepared.failure, isNull);
      effect = prepared.component!..priority = 9999;
      overlay.add(effect);
      overlay.findGame()!.processLifecycleEvents();
      await effect.loaded;
      overlay.findGame()!.processLifecycleEvents();
      addTearDown(() {
        effect.dispose();
      });
      Future<bool> attachedPixels(int emitterIndex, bool attacker) async {
        final actor = attacker ? player : enemy;
        final slot = BattleSlotRef.active(
          attacker ? BattleSideId.player : BattleSideId.enemy,
        );
        final frame = effect.playback.frames.singleWhere(
          (value) => value.emitterIndex == emitterIndex,
        );
        final billboard = camera.tryBillboardAt(
          overlay.currentSceneLayout.combatantGeometry(slot).footAnchor,
        );
        if (billboard == null) return false;
        final anchor = actor.currentEffectAttachmentSpriteRect.center;
        final pixels = await _effectPixels(effect);
        for (final particle in frame.particles) {
          if (particle.alpha5 == 0 || particle.scale4096 == 0) continue;
          final point =
              anchor +
              ui.Offset(
                (particle.motion.position.x + particle.emitterPosition.x) /
                    4096 *
                    5 *
                    billboard.scale,
                -(particle.motion.position.y + particle.emitterPosition.y) /
                    4096 *
                    5 *
                    billboard.scale,
              );
          if (_hasPixelNear(pixels, point, 12)) return true;
        }
        return false;
      }

      final initialEye = camera.eye;
      overlay.presentPostBattlePlan(
        BattleAnimationPlan(
          steps: [
            const StartTrackedEffectStep(effectId: 'source218'),
            WaitStep(durationSeconds: cameraStart / 60),
            CameraFocusStep(
              target: BattleCameraFocusTarget.target,
              durationSeconds: cameraDuration / 60,
            ),
            WaitStep(
              durationSeconds: (soundStart - cameraStart - cameraDuration) / 60,
            ),
            PlaySeStep(seName: marker),
            const WaitTrackedEffectsStep(),
            const PlaySeStep(seName: 'after'),
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
      expect(await attachedPixels(0, true), isTrue);
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

      final playerBeforeMotion =
          player.currentEffectAttachmentSpriteRect.center;
      await player.playLunge(
        towardOpponent: true,
        distancePx: 45,
        durationSeconds: .5,
      );
      for (var i = 0; i < 6; i++) {
        overlay.updateTree(1 / 60);
      }
      expect(
        (player.currentEffectAttachmentSpriteRect.center - playerBeforeMotion)
            .distance,
        greaterThan(2),
      );
      expect(await attachedPixels(0, true), isTrue);

      int? cameraTick;
      var cameraMoved = false;
      var cameraAttachmentChecked = false;
      var impactAttachmentChecked = false;
      for (var i = 18; i < 205 && !sounds.contains('after'); i++) {
        overlay.updateTree(1 / 60);
        cameraMoved = cameraMoved || camera.eye.distanceTo(initialEye) > .01;
        if (cameraMoved && !cameraAttachmentChecked) {
          expect(await attachedPixels(0, true), isTrue);
          cameraAttachmentChecked = true;
        }
        final impact = effect.playback.frames.singleWhere(
          (frame) => frame.emitterIndex == 3,
        );
        if (impact.particles.isNotEmpty && !impactAttachmentChecked) {
          expect(await attachedPixels(3, false), isTrue);
          impactAttachmentChecked = true;
        }
        if (overlay.battleCameraFocusSubject?.slot.side == BattleSideId.enemy) {
          cameraTick ??= effect.playback.tick;
        }
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
      expect(cameraTick, isNotNull);
      expect(cameraMoved, isTrue);
      expect(cameraAttachmentChecked, isTrue);
      expect(impactAttachmentChecked, isTrue);
      expect((cameraTick! - cameraStart).abs(), lessThanOrEqualTo(1));
      expect(markerTick, isNotNull);
      expect((markerTick! - soundStart).abs(), lessThanOrEqualTo(1));
      expect(sounds, [marker, 'after']);
      overlay.findGame()!.processLifecycleEvents();
      expect(effect.isMounted, isFalse);
      expect(overlay.children.contains(effect), isFalse);
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1',
  );
}

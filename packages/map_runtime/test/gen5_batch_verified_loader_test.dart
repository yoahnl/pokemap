import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_recipe_compiler.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_recipe_audio_program.dart';
import 'package:map_runtime/src/presentation/flame/battle_sfx_player.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_camera_projection.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_motion.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_point_emitter_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_verified_spl_loader.dart';
import 'package:map_runtime/src/presentation/flame/runtime_input_event.dart';
import 'package:map_runtime/src/spatial/spatial_battle_runtime.dart';
import 'package:path/path.dart' as p;

import 'support/offline_recipe_package_fixture.dart';
import 'source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;
import 'spatial_battle_runtime_test.dart' show readyContextualCaptureBattle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bundleRoot = Platform.environment['AVELUNE_BW2_BUNDLE_QA_DIR'];

  test('projects emitters in opposite directions independently', () {
    final camera = BattlePerspectiveCamera(
      viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
    );
    const foot = ui.Offset(190, 600);
    final binding = BattleSplCameraBinding(
      resolveNeutralFoot: () => foot,
      resolveAnchor: () {
        final point = camera.tryBillboardAt(foot);
        return point == null
            ? null
            : Vector2(point.position.dx, point.position.dy);
      },
    );
    const forward = BattleSplWorldTransform(
      worldUnitsPerUnit: 1,
      yawRadians: 0,
    );
    const reverse = BattleSplWorldTransform(
      worldUnitsPerUnit: 1,
      yawRadians: math.pi,
    );
    final projection = BattleSplCameraProjection(
      camera: camera,
      bindings: [binding, binding],
      worldTransform: forward,
      emitterTransforms: const [forward, reverse],
    );
    const anchor = (x: 0.0, y: 0.0, z: 0.0, unit: 1.0);
    final particle = BattleSplPointParticle(
      id: 1,
      motion: BattleSplParticleMotion(
        position: (x: 4096, y: 0, z: 0),
        velocity: (x: 4096, y: 0, z: 0),
        rotation: 0,
        angularVelocity: 0,
      ),
      emitterPosition: (x: 0, y: 0, z: 0),
      baseScale4096: 4096,
      baseAlpha5: 31,
      animatedAlpha5: 31,
      scale4096: 4096,
      color: (red: 31, green: 0, blue: 0),
      alpha5: 31,
      texture: 0,
    );
    final first = projection.projectParticle(
      anchor,
      particle,
      emitterIndex: 0,
    )!;
    final second = projection.projectParticle(
      anchor,
      particle,
      emitterIndex: 1,
    )!;
    final expectedForward = BattleSplCameraProjection(
      camera: camera,
      bindings: [binding],
      worldTransform: forward,
    ).projectParticle(anchor, particle)!;
    final expectedReverse = BattleSplCameraProjection(
      camera: camera,
      bindings: [binding],
      worldTransform: reverse,
    ).projectParticle(anchor, particle)!;
    expect(first.position, expectedForward.position);
    expect(second.position, expectedReverse.position);
    expect(first.position, isNot(second.position));
    expect(first.direction, expectedForward.direction);
    expect(second.direction, expectedReverse.direction);
    expect(
      projection.projectParticle(anchor, particle, emitterIndex: 2),
      isNull,
    );
    expect(
      () => BattleSplCameraProjection(
        camera: camera,
        bindings: [binding, binding],
        worldTransform: forward,
        emitterTransforms: const [forward],
      ),
      throwsFormatException,
    );
  });

  test('prepares Poison Jab from the converted batch', () async {
    final fetched = await groupedSplRecipeFixture(
      moveSourceId: 'poison-bw2-qa',
    );
    final recipe = fetched.bundle.recipe;
    final selection = const BattleMoveRecipeCompiler().selectGroupedSpl(
      recipe,
    )!;
    final definitions = recipe.readVerifiedSplParticleDefinitions(
      fetched.bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    );
    final count = selection.particles.fold<int>(
      0,
      (sum, particle) =>
          sum + definitions[particle.resourceId]!.emitters.length,
    );
    final camera = BattlePerspectiveCamera(
      viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
    );
    const foot = ui.Offset(190, 600);
    final binding = BattleSplCameraBinding(
      resolveNeutralFoot: () => foot,
      resolveAnchor: () {
        final point = camera.tryBillboardAt(foot);
        return point == null
            ? null
            : Vector2(point.position.dx, point.position.dy);
      },
    );
    final result = await BattleVerifiedSplLoader(fetched.bundle).createGrouped(
      selection.particles.map((particle) => particle.resourceId).toList(),
      emitters: [
        for (var index = 0; index < count; index++)
          BattleSplStaticEmitter(
            emitterIndex: index,
            startTick: 0,
            position: (x: 0, y: 0, z: 0),
          ),
      ],
      seed: 0,
      poolCapacity: 128,
      maxTicks: 200,
      origin: ui.Offset.zero,
      pixelsPerUnit: 5,
      projection: BattleSplCameraProjection(
        camera: camera,
        bindings: List.filled(count, binding),
      ),
      onComplete: () {},
      onFailure: (_) {},
    );
    expect(result.component, isNotNull, reason: 'failure=${result.failure}');
    result.component?.dispose();
  }, skip: bundleRoot == null);

  final batchRoot = Platform.environment['AVELUNE_BW2_BATCH_CANDIDATES'];
  group('audio initialization across widget tests', () {
    setUp(() async {
      installConvertedQaHeadlessAudio(completePlayback: true);
      await AudioPlayer.global.ensureInitialized();
    });
    for (final id in [2, 398]) {
      testWidgets('prepares audio on the widget clock for $id', (tester) async {
        final fetched = (await tester.runAsync(
          () => _fetchBatchRecipe(batchRoot!, id),
        ))!;
        final player = FlameAudioBattleSfxPlayer();
        final coordinator = BattleRecipeAudioCoordinator(
          player: player,
          bundle: fetched.bundle,
          preparationTimeout: const Duration(seconds: 2),
          startTimeout: const Duration(seconds: 1),
        );
        BattleRecipeAudioResult? result;
        unawaited(
          coordinator
              .prepare(const BattleMoveClipAudio('cue'))
              .then((value) => result = value),
        );
        for (var i = 0; i < 100 && result == null; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 1)),
          );
        }
        expect(
          result?.status,
          BattleRecipeAudioStatus.ready,
          reason: 'failure=${result?.failure}',
        );
        var closed = false;
        unawaited(
          coordinator
              .cancel()
              .then((_) => player.dispose())
              .then((_) => closed = true),
        );
        for (var i = 0; i < 100 && !closed; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 1)),
          );
        }
        expect(closed, isTrue);
      }, skip: batchRoot == null);
    }
  });
  for (final id in [2, 398]) {
    testWidgets('prepares batch audio in a real-time test zone: $id', (
      tester,
    ) async {
      installConvertedQaHeadlessAudio(completePlayback: true);
      final result = await tester.runAsync(() async {
        final fetched = await _fetchBatchRecipe(batchRoot!, id);
        final player = FlameAudioBattleSfxPlayer();
        final coordinator = BattleRecipeAudioCoordinator(
          player: player,
          bundle: fetched.bundle,
          preparationTimeout: const Duration(seconds: 2),
          startTimeout: const Duration(seconds: 1),
        );
        try {
          final audio = await coordinator.prepare(
            const BattleMoveClipAudio('cue'),
          );
          return (status: audio.status, failure: audio.failure);
        } finally {
          await coordinator.cancel();
          await player.dispose();
        }
      });
      expect(
        result?.status,
        BattleRecipeAudioStatus.ready,
        reason: 'failure=${result?.failure}',
      );
    }, skip: batchRoot == null);
  }
  testWidgets(
    'plays a bidirectional batch recipe in an offline spatial battle',
    (tester) async {
      installConvertedQaHeadlessAudio(completePlayback: true);
      await HttpOverrides.runZoned(
        () async {
          final fetched = (await tester.runAsync(
            () => _fetchBatchRecipe(batchRoot!, 155),
          ))!;
          final fixture = (await tester.runAsync(
            () => offlineRecipePackageFixture(fetchedRecipe: fetched),
          ))!;
          final runtime = SpatialBattleRuntime(
            readGameState: () => fixture.state,
            commitGameState: (_, _) => true,
          );
          addTearDown(runtime.dispose);
          unawaited(
            runtime.start(
              bundle: fixture.bundle,
              request: WildBattleStartRequest(
                requestId: 'batch-bidirectional',
                createdAtEpochMs: 1,
                returnContext: const OverworldReturnContext(
                  mapId: 'map',
                  playerPos: GridPos(x: 1, y: 1),
                  playerFacing: Direction.east,
                ),
                mapId: 'map',
                encounterSourceId: 'grass',
                encounterSourceKind: EncounterSourceKind.gameplayZone,
                tableId: 'wild',
                encounterKind: EncounterKind.walk,
                speciesId: 'clockbird',
                level: 2,
                minLevel: 2,
                maxLevel: 2,
                weight: 1,
                playerPos: const GridPos(x: 1, y: 1),
              ),
            ),
          );
          await readyContextualCaptureBattle(tester, runtime);
          final fight = runtime.displaySession!.decisionRequest.allowedChoices
              .whereType<PlayerBattleChoiceFight>()
              .first;
          bool? accepted;
          final submitted = runtime.submitChoice(fight).then((value) {
            accepted = value;
            return value;
          });
          var sawTracked = false;
          var sawOpposingTransforms = false;
          var sawParticles = false;
          var sawActive = false;
          for (var i = 0; i < 2000; i++) {
            await tester.pump(const Duration(milliseconds: 20));
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 1)),
            );
            final overlay = runtime.battleOverlay;
            if (overlay != null) {
              sawActive = sawActive || overlay.isTurnPresentationActive;
              sawTracked =
                  sawTracked ||
                  overlay.debugActiveAnimationPlan.flattenedSteps
                      .whereType<StartTrackedEffectStep>()
                      .isNotEmpty;
              for (final effect
                  in overlay.children.whereType<BattleSplStaticComponent>()) {
                sawParticles =
                    sawParticles || effect.playback.activeParticles > 0;
                final transforms =
                    effect.projection?.emitterTransforms ?? const [];
                sawOpposingTransforms =
                    sawOpposingTransforms ||
                    transforms.any(
                      (a) => transforms.any(
                        (b) => (a.yawRadians - b.yawRadians).abs() > 3,
                      ),
                    );
              }
              if (runtime.phase == SpatialBattlePhase.battle &&
                  overlay.isTurnPresentationActive) {
                runtime.handleInput(
                  const RuntimeInputEvent.press(RuntimeInputControl.primary),
                );
              }
            }
            if (accepted == false ||
                (accepted == true &&
                    sawActive &&
                    !(runtime.battleOverlay?.isTurnPresentationActive ??
                        false))) {
              break;
            }
          }
          expect(accepted, isNotNull, reason: '${runtime.error}');
          expect(await submitted, isTrue);
          expect(sawTracked, isTrue, reason: 'No tracked particle effect');
          expect(sawParticles, isTrue, reason: 'No active particles');
          expect(
            sawOpposingTransforms,
            isTrue,
            reason: 'Opposite directions were not preserved',
          );
          expect(runtime.error, isNull);
          runtime.cancel();
        },
        createHttpClient: (_) =>
            throw StateError('Network disabled for this test'),
      );
    },
    skip: batchRoot == null,
  );

  test('qualifies batch bundles through verified image decoding', () async {
    final root = batchRoot!;
    final manifest = jsonDecode(
      await File(p.join(root, 'manifest.json')).readAsString(),
    ) as Map;
    final counts = <String, int>{};
    final rows = <Map<String, Object?>>[];
    final camera = BattlePerspectiveCamera(
      viewport: const ui.Rect.fromLTWH(0, 0, 390, 844),
    );
    const foot = ui.Offset(190, 600);
    final binding = BattleSplCameraBinding(
      resolveNeutralFoot: () => foot,
      resolveAnchor: () {
        final point = camera.tryBillboardAt(foot);
        return point == null
            ? null
            : Vector2(point.position.dx, point.position.dy);
      },
    );
    const otherFoot = ui.Offset(250, 500);
    final otherBinding = BattleSplCameraBinding(
      resolveNeutralFoot: () => otherFoot,
      resolveAnchor: () {
        final point = camera.tryBillboardAt(otherFoot);
        return point == null
            ? null
            : Vector2(point.position.dx, point.position.dy);
      },
    );
    final anchors = BattleSplCameraProjection(
      camera: camera,
      bindings: [binding, otherBinding],
    ).capture()!;
    final anchorByName = {'userMouth': anchors[0], 'targetImpact': anchors[1]};
    final bindingByName = {'userMouth': binding, 'targetImpact': otherBinding};
    for (final row in (manifest['moves'] as List).cast<Map>()) {
      if (row['status'] != 'review' || row['apiValidation'] != 'passed') {
        continue;
      }
      var outcome = 'prepared';
      try {
        final encoded = jsonDecode(
          await File(p.join(root, row['bundle'] as String)).readAsString(),
        ) as Map;
        final recipeBytes = base64.decode(encoded['recipe'] as String);
        final data = jsonDecode(utf8.decode(recipeBytes)) as Map;
        final media = <String, Uint8List>{
          for (final entry in (encoded['media'] as Map).entries)
            entry.key as String: base64.decode(entry.value as String),
        };
        final recipeBinding = BattleMoveRecipeBinding.fromJson({
          'schemaVersion': 1,
          'projectMoveId': row['move'],
          'sourceMoveId': row['move'],
          'catalogReleaseId': 'bw2-batch-local',
          'recipeId': data['recipeId'],
          'variant': data['variant'],
          'revision': data['revision'],
          'recipeSha256': row['recipeSha256'],
        });
        final inspected = const BattleRecipeBundleInspector().inspect(
          recipeBinding,
          recipeBytes,
          media,
          limits: const BattleRecipeBundleLimits(
            maxTextures: 16,
            maxTextureBytes: 8 * 1024 * 1024,
            maxBundleBytes: 32 * 1024 * 1024,
            maxDimension: 2048,
            maxTexturePixels: 4000000,
            maxTotalPixels: 16000000,
          ),
          availableCapabilities:
              BattleMoveAnimationRecipe.recognizedCapabilities,
          expectedProjectMoveId: row['move'] as String,
          expectedCatalogReleaseId: 'bw2-batch-local',
        );
        final recipe = inspected.recipe;
        final selected = const BattleMoveRecipeCompiler().selectGroupedSpl(
          recipe,
        );
        if (selected == null) {
          outcome = 'fallback:unsupported-recipe-shape';
        } else {
          final definitions = recipe.readVerifiedSplParticleDefinitions(
            inspected.media,
            availableCapabilities:
                BattleMoveAnimationRecipe.recognizedCapabilities,
          );
          final count = selected.particles.fold<int>(
            0,
            (sum, part) => sum + definitions[part.resourceId]!.emitters.length,
          );
          final yaws = <({String from, String to}), double>{};
          for (final part in selected.particles.where(
            (part) => part.from != part.to,
          )) {
            final from = anchorByName[part.from]!;
            final to = anchorByName[part.to]!;
            final dx = to.x - from.x;
            final dz = to.z - from.z;
            if (dx.abs() + dz.abs() < .000001) {
              throw const FormatException('Coincident anchors');
            }
            yaws[(from: part.from, to: part.to)] = math.atan2(dz, dx);
          }
          final defaultYaw = yaws.isEmpty ? 0.0 : yaws.values.first;
          final bindings = <BattleSplCameraBinding>[];
          final transforms = <BattleSplWorldTransform>[];
          for (final part in selected.particles) {
            for (final _ in definitions[part.resourceId]!.emitters) {
              bindings.add(bindingByName[part.from]!);
              transforms.add(
                BattleSplWorldTransform(
                  worldUnitsPerUnit: anchors[0].unit * 5,
                  yawRadians:
                      yaws[(from: part.from, to: part.to)] ?? defaultYaw,
                ),
              );
            }
          }
          final result = await BattleVerifiedSplLoader(inspected).createGrouped(
            selected.particles.map((part) => part.resourceId).toList(),
            emitters: [
              for (var i = 0; i < count; i++)
                BattleSplStaticEmitter(
                  emitterIndex: i,
                  startTick: 0,
                  position: (x: 0, y: 0, z: 0),
                ),
            ],
            seed: 0,
            poolCapacity: 128,
            maxTicks: 200,
            origin: ui.Offset.zero,
            pixelsPerUnit: 5,
            projection: BattleSplCameraProjection(
              camera: camera,
              bindings: bindings,
              worldTransform: BattleSplWorldTransform(
                worldUnitsPerUnit: anchors[0].unit * 5,
                yawRadians: defaultYaw,
              ),
              emitterTransforms: transforms,
            ),
            onComplete: () {},
            onFailure: (_) {},
          );
          if (result.component == null) {
            outcome = 'fallback:${result.failure?.name ?? 'unknown'}';
          }
          result.component?.dispose();
        }
      } on Object catch (error) {
        outcome = 'error:${error.runtimeType}';
      }
      counts.update(outcome, (count) => count + 1, ifAbsent: () => 1);
      rows.add({'id': row['id'], 'move': row['move'], 'outcome': outcome});
    }
    expect(rows, isNotEmpty);
    expect(counts.keys.where((key) => key.startsWith('error:')), isEmpty);
    const bidirectional = {155, 285, 289, 369, 384, 385, 391, 470, 471};
    final checked = rows
        .where((row) => bidirectional.contains(row['id']))
        .toList();
    expect(checked, hasLength(bidirectional.length));
    expect(checked.map((row) => row['outcome']), everyElement('prepared'));
    await File(p.join(root, 'verified-loader-qualification.json'))
        .writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'scope': 'verified-bundle-static-admission-and-image-decode',
            'counts': counts,
            'moves': rows,
          }),
        );
    stdout.writeln(
      jsonEncode({'verifiedLoader': counts, 'count': rows.length}),
    );
  }, skip: batchRoot == null);
}

Future<FetchedBattleRecipe> _fetchBatchRecipe(String root, int id) async {
  final manifest = jsonDecode(
    await File(p.join(root, 'manifest.json')).readAsString(),
  ) as Map;
  final row = (manifest['moves'] as List).cast<Map>().singleWhere(
    (item) => item['id'] == id,
  );
  final encoded = jsonDecode(
    await File(p.join(root, row['bundle'] as String)).readAsString(),
  ) as Map;
  final recipeBytes = base64.decode(encoded['recipe'] as String);
  final recipe = jsonDecode(utf8.decode(recipeBytes)) as Map;
  final media = <String, Uint8List>{
    for (final entry in (encoded['media'] as Map).entries)
      entry.key as String: base64.decode(entry.value as String),
  };
  final binding = BattleMoveRecipeBinding.fromJson({
    'schemaVersion': 1,
    'projectMoveId': row['move'],
    'sourceMoveId': row['move'],
    'catalogReleaseId': 'bw2-batch-local',
    'recipeId': recipe['recipeId'],
    'variant': recipe['variant'],
    'revision': recipe['revision'],
    'recipeSha256': row['recipeSha256'],
  });
  final inspected = const BattleRecipeBundleInspector().inspect(
    binding,
    recipeBytes,
    media,
    limits: const BattleRecipeBundleLimits(
      maxTextures: 16,
      maxTextureBytes: 8 * 1024 * 1024,
      maxBundleBytes: 32 * 1024 * 1024,
      maxDimension: 2048,
      maxTexturePixels: 4000000,
      maxTotalPixels: 16000000,
    ),
    availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    expectedProjectMoveId: row['move'] as String,
    expectedCatalogReleaseId: 'bw2-batch-local',
  );
  return (
    binding: binding,
    bundle: inspected,
    catalogMoveId: row['move'] as String,
    recipeMediaId: 'local-batch-$id',
  );
}

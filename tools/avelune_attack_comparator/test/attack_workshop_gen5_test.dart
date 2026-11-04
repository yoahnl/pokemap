import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:avelune_attack_compare/main.dart' show PreviewPanel, extractPreviewResources;
import 'package:avelune_attack_compare/preview_game.dart';
import 'package:avelune_attack_compare/workshop_reference_pokemon.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_background.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobal = MethodChannel('xyz.luan/audioplayers.global');
  const audioEvents = MethodChannel('xyz.luan/audioplayers.global/events');
  setUpAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioGlobal, (_) async => null);
    messenger.setMockMethodCallHandler(audioEvents, (_) async => null);
  });
  tearDownAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioGlobal, null);
    messenger.setMockMethodCallHandler(audioEvents, null);
  });
  setUp(rootBundle.clear);
  testWidgets('clips battle visuals to the simulated phone screen', (tester) async {
    const boundaryKey = ValueKey('preview-boundary');
    const screenKey = ValueKey('phone-screen');
    await tester.pumpWidget(MaterialApp(
      home: Center(child: SizedBox(width: 400, height: 300,
        child: RepaintBoundary(key: boundaryKey, child: PreviewPanel(
          eyebrow: 'TEST', title: 'Combat', aspectRatio: 0.4,
          child: CustomPaint(key: screenKey, painter: _OverflowPainter()),
        )),
      )),
    ));
    final screen = tester.getRect(find.byKey(screenKey));
    final origin = tester.getTopLeft(find.byKey(boundaryKey));
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
    final bytes = await tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
    final x = (screen.left - origin.dx - 10).floor();
    final y = (screen.center.dy - origin.dy).floor();
    expect(bytes!.getUint8((y * image!.width + x) * 4), lessThan(100));
    image.dispose();
  });

  test('Quick Attack bundles its source program and both impact emitters', () async {
    expect(PreviewMove.quickAttack.unavailableReason, isNull);
    final program = jsonDecode(
      await rootBundle.loadString('assets/bw2/quick_attack.json'),
    ) as Map<String, dynamic>;
    expect(program['conversion'], 'supported');
    final instructions = (program['instructions'] as List).cast<Map>();
    expect(instructions.where((item) => item['op'] == 'circleCombatant'), hasLength(1));
    expect(instructions.where((item) => item['op'] == 'startOrthoEmitter'), hasLength(2));
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/bw2/particle270/manifest.json'),
    ) as Map<String, dynamic>;
    expect(manifest['sourceEmitterIndices'], [0, 1]);
    expect(await rootBundle.loadString('assets/bw2/particle270/texture00.b64'), isNotEmpty);
  });

  test('Hydro Pump bundles its source program and decoded background', () async {
    expect(PreviewMove.hydroPump.unavailableReason, isNull);
    final bundle = jsonDecode(
      await rootBundle.loadString(PreviewMove.hydroPump.bundleAsset!),
    ) as Map<String, dynamic>;
    expect(bundle['particle'], 221);
    expect((bundle['program'] as Map)['conversion'], 'supported');
    final bytes = base64Decode((bundle['backgrounds'] as Map)['18'] as String);
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      expect((frame.image.width, frame.image.height), (512, 512));
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  });

  test('Fire Blast bundles its source background palette cycle', () async {
    expect(PreviewMove.fireBlast.unavailableReason, isNull);
    final bundle = jsonDecode(
      await rootBundle.loadString(PreviewMove.fireBlast.bundleAsset!),
    ) as Map<String, dynamic>;
    final animation = (bundle['backgroundAnimations'] as Map)['6'] as Map;
    expect(animation['background'], 60);
    expect(animation['durations'], [6, 6, 6, 6, 6, 6]);
    expect(animation['frames'], hasLength(6));
    for (final frame in animation['frames'] as List) {
      final codec = await ui.instantiateImageCodec(base64Decode(frame as String));
      try {
        final image = (await codec.getNextFrame()).image;
        expect((image.width, image.height), (512, 512));
        image.dispose();
      } finally {
        codec.dispose();
      }
    }
  });

  test('selected source variants are available once in the workshop', () async {
    final index = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/index.json'),
    ) as List;
    final ids = [
      for (final move in PreviewMove.values)
        if (move.unavailableReason == null) move.id,
      for (final row in index.cast<Map>()) row['id'] as String,
    ];
    expect(ids.toSet(), hasLength(ids.length));
    for (final move in [PreviewMove.fly, PreviewMove.thief]) {
      expect(move.unavailableReason, isNull);
      expect(move.approximations, contains('source-variant:first-only'));
      final bundle = jsonDecode(await rootBundle.loadString(move.bundleAsset!)) as Map;
      expect(bundle['id'], move.id);
      expect((bundle['program'] as Map)['conversion'], 'supported');
    }
  });

  test('multi-variant source programs disclose that only one variant is shown', () async {
    final index = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/index.json'),
    ) as List;
    final missing = <String>[];
    for (final row in index.cast<Map>()) {
      final bundle = jsonDecode(await rootBundle.loadString(row['bundleAsset'] as String)) as Map;
      final program = bundle['program'] as Map;
      if ((program['variants'] as List).length > 1 &&
          (!(row['approximations'] as List).contains('source-variant:first-only') ||
           !(bundle['approximations'] as List).contains('source-variant:first-only'))) {
        missing.add(row['id'] as String);
      }
    }
    expect(missing, isEmpty);
  });

  test('Roar bundles its source visuals and declares its preview limitations', () async {
    final move = PreviewMove.roar;
    expect(move.unavailableReason, isNull);
    expect(move.bundleAsset, 'assets/bw2/batch/roar.json');
    expect(move.approximations, contains('source-audio:cry-and-timing-unavailable'));
    expect(move.approximations, contains('source-gauge:preview-restored'));
    final bundle = jsonDecode(await rootBundle.loadString(move.bundleAsset!)) as Map;
    expect(bundle['sourceId'], 46);
    expect(bundle['particle'], 211);
    final program = bundle['program'] as Map;
    expect(program['conversion'], 'supported');
    final instructions = (program['instructions'] as List).cast<Map>();
    expect(instructions.any((item) => item['op'] == 'setSourceGauge'), isTrue);
    expect(instructions.any((item) => item['op'] == 'startMovingEmitter'), isTrue);
  });

  test('Whirlwind bundles its source rotation and particles', () async {
    final index = jsonDecode(await rootBundle.loadString(
      'assets/bw2/batch/index.json',
    )) as List;
    final row = index.cast<Map>().singleWhere((item) => item['id'] == 'whirlwind');
    expect(row['particle'], 183);
    expect(row['approximations'], contains('source-gauge:preview-restored'));
    final bundle = jsonDecode(await rootBundle.loadString(row['bundleAsset'] as String)) as Map;
    final program = bundle['program'] as Map;
    expect(bundle['sourceId'], 18);
    expect(program['conversion'], 'supported');
    final instructions = (program['instructions'] as List).cast<Map>();
    expect(instructions.any((item) => item['op'] == 'rotateCombatant' &&
        (item['args'] as Map)['type'] == 1), isTrue);
  });

  test('Dark Void bundles its source background and particles', () async {
    final index = jsonDecode(await rootBundle.loadString(
      'assets/bw2/batch/index.json',
    )) as List;
    final row = index.cast<Map>().singleWhere((item) => item['id'] == 'dark-void');
    expect(row['particle'], 644);
    final bundle = jsonDecode(await rootBundle.loadString(row['bundleAsset'] as String)) as Map;
    expect(bundle['sourceId'], 464);
    expect((bundle['program'] as Map)['conversion'], 'supported');
    expect((bundle['backgrounds'] as Map).containsKey('192'), isTrue);
  });

  test('context-dependent moves use the same examples as their BW references', () async {
    for (final example in [
      (id: 'mirror-move', bundle: 'jump-kick',
          source: 'res/battle/animations/moves/jump_kick.s',
          context: 'source-context:copied-jump-kick'),
      (id: 'nature-power', bundle: 'rock-slide',
          source: 'res/battle/animations/moves/rock_slide.s',
          context: 'source-context:cave-rock-slide'),
    ]) {
      final move = PreviewMove.values.singleWhere((item) => item.id == example.id);
      expect(move.unavailableReason, isNull);
      expect(move.referenceUrl, isNotNull);
      expect(move.bundleAsset, 'assets/bw2/batch/${example.bundle}.json');
      expect(move.approximations, contains(example.context));
      final bundle = jsonDecode(await rootBundle.loadString(move.bundleAsset!)) as Map;
      expect(((bundle['program'] as Map)['source'] as Map)['path'], example.source);
      expect((bundle['program'] as Map)['conversion'], 'supported');
    }
  });

  test('Ally Switch bundles the original source program', () async {
    final move = PreviewMove.allySwitch;
    expect(move.unavailableReason, isNull);
    final bundle = jsonDecode(await rootBundle.loadString(move.bundleAsset!)) as Map;
    final program = bundle['program'] as Map;
    expect((program['source'] as Map)['path'], 'res/battle/animations/moves/ally_switch.s');
    expect(program['conversion'], 'supported');
    expect(program['instructions'], hasLength(36));
  });

  test('Secret Power first source variant follows its Body Slam redirect', () async {
    final alias = jsonDecode(await rootBundle.loadString(
      'assets/bw2/batch/secret-power.json',
    )) as Map;
    final target = jsonDecode(await rootBundle.loadString(
      'assets/bw2/batch/body-slam.json',
    )) as Map;
    expect(alias['sourceId'], 290);
    expect(alias['sourceRedirect'], {
      'path': 'res/battle/animations/moves/secret_power.s',
      'sha256': '961b433e0fa193f776067de085612bd346b83bcadf975c704f4d1918903a729a',
      'variant': 'SecretPower', 'target': 'body-slam',
    });
    expect(alias['program'], target['program']);
    expect(alias['approximations'], contains('source-variant:first-only'));
  });

  test('retains BW2 cylinder particles even when their radius is zero', () async {
    final ember = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/ember.json'),
    ) as Map;
    final definition = ember['definition'] as Map;
    final emission = (((definition['emitters'] as List).single as Map)
        ['emission']) as Map;
    expect(definition['schemaVersion'], 8);
    expect(emission['shape'], 'cylinderSurface');
    expect(emission['radius'], 0);
    expect(emission['length'], 0);
    expect(ember['approximations'],
        isNot(contains('particle-shape:cylinder_surface->sphere_surface')));
    expect(ember['approximations'], isNot(contains('particle-zero-radius:point')));
  });

  test('retains source particle lifetime variance in single and grouped attacks', () async {
    final bubble = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/bubble.json'),
    ) as Map;
    final bubbleDefinition = bubble['definition'] as Map;
    expect(bubbleDefinition['schemaVersion'], 7);
    expect(
      [for (final emitter in bubbleDefinition['emitters'] as List)
        ((emitter as Map)['emission'] as Map)['particleLifetimeVariance']],
      [9, 0],
    );
    final fissure = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/fissure.json'),
    ) as Map;
    final groups = fissure['particleGroups'] as Map;
    final first = (groups['261'] as Map)['definition'] as Map;
    expect(first['schemaVersion'], 7);
    expect(
      ((((first['emitters'] as List).single as Map)['emission']) as Map)
          ['particleLifetimeVariance'],
      20,
    );
  });

  test('all batch textures decode from the bundled workshop catalog', () async {
    final index = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/index.json'),
    ) as List;
    final failures = <String>[];
    var decoded = 0;
    for (final row in index.cast<Map<String, dynamic>>()) {
      try {
        final bundle = jsonDecode(
          await rootBundle.loadString(row['bundleAsset'] as String),
        ) as Map<String, dynamic>;
        if (bundle['id'] != row['id']) {
          throw const FormatException('Wrong bundle');
        }
        final groups = bundle['particleGroups'] as Map?;
        for (final group in groups?.values ?? [bundle]) {
          final textures = ((group as Map)['textures'] as Map).cast<String, String>();
          for (final texture in textures.entries) {
            final codec = await ui.instantiateImageCodec(
              base64Decode(texture.value),
            );
            try {
              final frame = await codec.getNextFrame();
              frame.image.dispose();
              decoded++;
            } finally {
              codec.dispose();
            }
          }
        }
        for (final data in (bundle['backgrounds'] as Map? ?? const {}).values) {
          final codec = await ui.instantiateImageCodec(base64Decode(data as String));
          try {
            final frame = await codec.getNextFrame();
            if (frame.image.width != 512 || frame.image.height != 512) {
              frame.image.dispose();
              throw const FormatException('Invalid source background dimensions');
            }
            frame.image.dispose();
          } finally {
            codec.dispose();
          }
        }
      } on Object catch (error) {
        failures.add('${row['id']}: $error');
      }
    }
    expect(index, isNotEmpty);
    expect(decoded, greaterThanOrEqualTo(index.length));
    expect(failures, isEmpty);
    debugPrint('Decoded $decoded batch textures for ${index.length} attacks');
  });

  final rootPath = Platform.environment['AVELUNE_ATTACK_WORKSHOP_QA'];
  for (final scenario in [
    (id: 'dragon-breath', label: 'Draco-Souffle', particle: 395,
      attacker: 'archen', target: 'gurdurr'),
    (id: 'hyper-beam', label: 'Ultralaser', particle: 228,
      attacker: 'swoobat', target: 'buizel'),
  ]) {
    for (final size in [const Size(393, 852), const Size(600, 800), const Size(852, 393)]) {
      testWidgets('${scenario.label} aims at the opponent at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final root = (await tester.runAsync(
          () => extractPreviewResources(parent: Directory(rootPath!)),
        ))!;
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        PreparedReferencePair? referencePokemon;
        if (Platform.environment['AVELUNE_ATTACK_REFERENCE_QA'] == '1') {
          final previousOverrides = HttpOverrides.current;
          HttpOverrides.global = null;
          addTearDown(() => HttpOverrides.global = previousOverrides);
          final store = WorkshopReferencePokemonStore(root: root);
          addTearDown(store.close);
          referencePokemon = await tester.runAsync<PreparedReferencePair?>(() => store.prepare(
            (attacker: scenario.attacker, target: scenario.target),
          ));
          expect(referencePokemon, isNotNull, reason: 'Pokémon de référence indisponibles');
          final captureDir = Platform.environment['AVELUNE_ATTACK_AIM_CAPTURES'];
          if (captureDir != null) {
            await tester.runAsync(() async {
              for (final (id, view) in [
                (scenario.attacker, 'back'), (scenario.target, 'front'),
              ]) {
                for (final ext in ['gif', 'png']) {
                  final file = File('${root.path}/assets/pokemon/comparator/$id-$view.$ext');
                  if (await file.exists()) await file.copy('$captureDir/$id-$view.$ext');
                }
              }
            });
          }
        }
        final status = ValueNotifier<String>('Preparing');
        addTearDown(status.dispose);
        final game = BattlePreviewGame(
          projectRoot: root.path,
          move: PreviewMove(
            scenario.id, scenario.label, null, 'normal',
            PsdkBattleMoveCategory.special,
            particle: scenario.particle,
            bundleAsset: 'assets/bw2/batch/${scenario.id}.json',
          ),
          status: status,
          referencePokemon: referencePokemon,
          loadMoveAudio: (_) async => null,
        );
        const boundaryKey = ValueKey('laser-portrait-proof');
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: size.width, height: size.height, child: GameWidget(game: game),
            ),
          ),
        ));
        for (var tick = 0;
            tick < 360 && status.value != 'Combat prêt · appuie sur Lancer'; tick++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
        }
        expect(status.value, 'Combat prêt · appuie sur Lancer');
        final scene = game.children.whereType<BattleOverlayComponent>().single;
        final movingTargetProjection = scene.experimentalGen5Projection(
          attacker: true,
          towardOpponent: true,
          centerTargetedBeam: true,
        );
        expect(movingTargetProjection.capture(), isNotNull);
        final initialYaw = movingTargetProjection.worldTransform!.yawRadians;
        scene.debugEnemyCombatant!.setIdleLateralOffset(40);
        expect(movingTargetProjection.capture(), isNotNull);
        expect(movingTargetProjection.worldTransform!.yawRadians,
            isNot(closeTo(initialYaw, .000001)));
        scene.debugEnemyCombatant!.setIdleLateralOffset(0);
        expect(movingTargetProjection.capture(), isNotNull);
        expect(movingTargetProjection.worldTransform!.yawRadians,
            closeTo(initialYaw, .000001));
        unawaited(game.play());
        var measured = 0;
        var towardTarget = 0;
        var afterFirstParticle = 0;
        var reachedTarget = false;
        int? beamCorePixels;
        final impactHeights = <double>[];
        final initialImpactHeights = <double>[];
        for (var tick = 0; tick < 400; tick++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
          for (final overlay in game.children.whereType<BattleOverlayComponent>()) {
            final target = overlay.debugEnemyCombatant?.currentEffectAttachmentSpriteRect;
            for (final effect in overlay.children.whereType<BattleSplStaticComponent>()) {
              final projection = effect.projection;
              final anchors = projection?.capture();
              for (final frame in effect.playback.frames) {
                for (final particle in frame.particles.where((item) => item.parentId == null)) {
                  final velocity = particle.motion.velocity;
                  if (math.max(velocity.x.abs(), velocity.z.abs()) < 2000) continue;
                  measured++;
                  if (velocity.z > velocity.x.abs() * 2) towardTarget++;
                  if (target != null && projection != null && anchors != null) {
                    final projected = projection.projectParticle(
                      anchors.first, particle,
                      relativeBasePosition: frame.relativeBasePosition,
                    );
                    final impact = Rect.fromLTWH(
                      target.left + target.width * .2,
                      target.top + target.height * .2,
                      target.width * .6, target.height * .6,
                    );
                    reachedTarget |= projected != null && impact.contains(projected.position);
                    if (projected != null &&
                        (projected.position.dx - target.center.dx).abs() < target.width * .15) {
                      final offset = (projected.position.dy - target.center.dy) / target.height;
                      impactHeights.add(offset);
                      if (afterFirstParticle < 30) initialImpactHeights.add(offset);
                    }
                  }
                }
              }
            }
          }
          if (measured > 0) afterFirstParticle++;
          final captureDir = Platform.environment['AVELUNE_ATTACK_AIM_CAPTURES'];
          final captureFrame = captureDir != null && afterFirstParticle > 0 &&
              afterFirstParticle <= 60 && afterFirstParticle % 10 == 0;
          final measureBeam = scenario.id == 'hyper-beam' && size.height > size.width &&
              afterFirstParticle == 20;
          if (captureFrame || measureBeam) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
            final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
            if (measureBeam) {
              final rgba = (await tester.runAsync(() => image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              )))!.buffer.asUint8List();
              final attacker = scene.debugPlayerCombatant!.currentEffectAttachmentSpriteRect;
              final target = scene.debugEnemyCombatant!.currentEffectAttachmentSpriteRect;
              final middle = Offset.lerp(attacker.center, target.center, .5)!;
              final x = middle.dx.round().clamp(0, image.width - 1);
              final top = (middle.dy - target.height * .6).floor().clamp(0, image.height - 1);
              final bottom = (middle.dy + target.height * .6).ceil().clamp(0, image.height - 1);
              beamCorePixels = 0;
              for (var y = top; y <= bottom; y++) {
                final pixel = (y * image.width + x) * 4;
                if (rgba[pixel] > 215 && rgba[pixel + 1] < 190 && rgba[pixel + 2] < 190) {
                  beamCorePixels = beamCorePixels! + 1;
                }
              }
            }
            if (captureFrame) {
              final bytes = await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
              await tester.runAsync(() => File(
                '$captureDir/${scenario.id}-${size.width.toInt()}-$afterFirstParticle.png',
              ).writeAsBytes(bytes!.buffer.asUint8List()));
            }
            image.dispose();
          }
          if (afterFirstParticle == 80) break;
        }
        expect(measured, greaterThan(0), reason: status.value);
        expect(towardTarget / measured, greaterThan(.9));
        expect(reachedTarget, isTrue, reason: 'Le faisceau doit atteindre le centre du Pokémon adverse');
        impactHeights.sort();
        initialImpactHeights.sort();
        debugPrint('[laser-aim] ${scenario.id} $size count=${impactHeights.length} '
            'median=${impactHeights.isEmpty ? null : impactHeights[impactHeights.length ~/ 2]}');
        expect(impactHeights, isNotEmpty);
        expect(initialImpactHeights, isNotEmpty);
        final maxImpactOffset = size.height > size.width ? .12 : .22;
        expect(impactHeights[impactHeights.length ~/ 2].abs(), lessThan(maxImpactOffset));
        expect(initialImpactHeights[initialImpactHeights.length ~/ 2].abs(), lessThan(maxImpactOffset));
        if (scenario.id == 'hyper-beam' && size.height > size.width) {
          debugPrint('[laser-width] $size core=$beamCorePixels');
          final minimumCorePixels = size.width == 393 ? 24 : 16;
          expect(beamCorePixels, greaterThanOrEqualTo(minimumCorePixels),
              reason: 'Le cœur du rayon doit rester visible en portrait');
        }
        await tester.pumpWidget(const SizedBox());
      }, skip: rootPath == null);
    }
  }
  for (final cancel in [false, true]) {
    testWidgets(cancel
        ? 'does not start a source attack after leaving while the reference loads'
        : 'waits for the reference before starting a source attack', (tester) async {
      final root = (await tester.runAsync(
        () => extractPreviewResources(parent: Directory(rootPath!)),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final status = ValueNotifier<String>('Preparing');
      final game = BattlePreviewGame(
        projectRoot: root.path,
        move: PreviewMove.surf,
        status: status,
      );
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 393, height: 852, child: GameWidget(game: game)),
      ));
      for (var i = 0; i < 360 && status.value != 'Combat prêt · appuie sur Lancer'; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(status.value, 'Combat prêt · appuie sur Lancer');
      var referenceRequested = false;
      var finished = false;
      unawaited(game.play(onStart: () async {
        referenceRequested = true;
        await gate.future;
        return true;
      }).whenComplete(() => finished = true));
      for (var i = 0; i < 360 && !referenceRequested; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(referenceRequested, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(status.value, 'Chargement de Surf…');
      if (cancel) {
        await tester.pumpWidget(const SizedBox());
      }
      gate.complete();
      for (var i = 0; i < 500 && !finished; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(finished, isTrue);
      if (cancel) {
        expect(status.value, 'Chargement de Surf…');
      } else {
        expect(status.value, contains('terminée'));
      }
      await tester.pumpWidget(const SizedBox());
      status.dispose();
    }, skip: rootPath == null);
  }

  for (final scenario in [
    (size: const Size(393, 852), cancel: false),
    (size: const Size(852, 393), cancel: false),
    (size: const Size(393, 852), cancel: true),
    (size: const Size(852, 393), cancel: true),
  ]) {
    testWidgets('Ally Switch preserves allies ${scenario.cancel ? 'on interruption' : 'after swapping'} at ${scenario.size}', (tester) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final root = (await tester.runAsync(
        () => extractPreviewResources(parent: Directory(rootPath!)),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final status = ValueNotifier<String>('Preparing');
      final game = BattlePreviewGame(projectRoot: root.path,
          move: PreviewMove.allySwitch, status: status);
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
        child: SizedBox(width: scenario.size.width, height: scenario.size.height,
          child: GameWidget(game: game))));
      BattleOverlayComponent? overlay() =>
          game.children.whereType<BattleOverlayComponent>().firstOrNull;
      for (var tick = 0; tick < 360 && status.value != 'Combat prêt · appuie sur Lancer'; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(status.value, 'Combat prêt · appuie sur Lancer');
      final scene = overlay()!;
      final actors = scene.children.whereType<BattleSceneCombatantComponent>().toList();
      expect(actors, hasLength(4));
      final player = scene.debugPlayerCombatant!;
      final partner = actors.singleWhere((actor) => actor.isPlayerSide && !identical(actor, player));
      expect(player.currentSpeciesLabel, 'Kaiminus');
      expect(partner.currentSpeciesLabel, 'Roucool');
      for (var tick = 0; tick < 360; tick++) {
        if (player.currentSpriteSourcePath == 'gen5:totodile' &&
            partner.currentSpriteSourcePath == 'gen5:pidgey') {
          break;
        }
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(player.currentSpriteSourcePath, 'gen5:totodile');
      expect(partner.currentSpriteSourcePath, 'gen5:pidgey');
      final initialOffset = player.currentVisualOffset;
      final initialPartnerOffset = partner.currentVisualOffset;
      var started = false;
      var moved = false;
      var faded = false;
      unawaited(game.play(onStart: () => started = true));
      for (var tick = 0; tick < 600; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
        moved |= player.currentVisualOffset != initialOffset;
        faded |= player.stageTint.a < .99;
        if (scenario.cancel && faded) break;
        if (status.value.contains('terminée') || status.value.contains('Impossible')) break;
      }
      expect(started, isTrue, reason: status.value);
      expect(moved, isTrue, reason: status.value);
      expect(faded, isTrue, reason: status.value);
      if (scenario.cancel) {
        await tester.pumpWidget(const SizedBox());
        expect(player.currentSpeciesLabel, 'Kaiminus');
        expect(partner.currentSpeciesLabel, 'Roucool');
        expect(player.stageTint.a, closeTo(1, .01));
        expect(partner.stageTint.a, closeTo(1, .01));
        expect(player.currentVisualOffset, initialOffset);
        expect(partner.currentVisualOffset, initialPartnerOffset);
      } else {
        expect(status.value, contains('terminée'));
        expect(player.currentSpeciesLabel, 'Roucool');
        expect(partner.currentSpeciesLabel, 'Kaiminus');
        for (var tick = 0; tick < 360; tick++) {
          if (player.currentSpriteSourcePath == 'gen5:pidgey' &&
              partner.currentSpriteSourcePath == 'gen5:totodile') {
            break;
          }
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
        }
        expect(player.currentSpriteSourcePath, 'gen5:pidgey');
        expect(partner.currentSpriteSourcePath, 'gen5:totodile');
        final huds = scene.currentCommandOverlaySnapshot!.combatantHuds;
        expect(huds.singleWhere((hud) => hud.effectiveSlot ==
            const BattleSlotRef.active(BattleSideId.player)).combatantId, 'player_ally');
        expect(huds.singleWhere((hud) => hud.effectiveSlot ==
            const BattleSlotRef(side: BattleSideId.player, slotIndex: 1)).combatantId, 'player');
        expect(player.stageTint.a, closeTo(1, .01));
        await tester.pumpWidget(const SizedBox());
      }
      status.dispose();
    }, skip: rootPath == null);
  }

  for (final scenario in [
    (size: const Size(393, 852), cancel: false),
    (size: const Size(852, 393), cancel: false),
    (size: const Size(393, 852), cancel: true),
  ]) {
    testWidgets('Morphing ${scenario.cancel ? 'cleans up when interrupted' : 'copies the target with mosaic'} at ${scenario.size}',
        (tester) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      expect(PreviewMove.transform.unavailableReason, isNull);
      final root = (await tester.runAsync(
        () => extractPreviewResources(parent: Directory(rootPath!)),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final status = ValueNotifier<String>('Preparing');
      final game = BattlePreviewGame(
        projectRoot: root.path,
        move: PreviewMove.transform,
        status: status,
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: scenario.size.width,
          height: scenario.size.height,
          child: GameWidget(game: game),
        ),
      ));
      BattleOverlayComponent? overlay() =>
          game.children.whereType<BattleOverlayComponent>().firstOrNull;
      for (var tick = 0; tick < 360 && status.value != 'Combat prêt · appuie sur Lancer'; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(status.value, 'Combat prêt · appuie sur Lancer');
      final actor = overlay()!.debugPlayerCombatant!;
      final enemy = overlay()!.debugEnemyCombatant!;
      for (var tick = 0; tick < 360; tick++) {
        if (actor.currentSpriteSourcePath == 'gen5:totodile' &&
            enemy.currentSpriteSourcePath == 'gen5:pidgey') {
          break;
        }
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(actor.currentSpriteSourcePath, 'gen5:totodile');
      expect(enemy.currentSpriteSourcePath, 'gen5:pidgey');
      var started = false;
      var largestMosaic = 0;
      var sawAlpha = false;
      unawaited(game.play(onStart: () => started = true));
      for (var tick = 0; tick < 600; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
        largestMosaic = math.max(largestMosaic, actor.debugBattleScriptMosaicLevel);
        sawAlpha |= actor.stageTint.a < .99;
        if (scenario.cancel && largestMosaic > 0) break;
        if (status.value.contains('terminée') || status.value.contains('Impossible')) break;
      }
      expect(started, isTrue, reason: status.value);
      expect(largestMosaic, greaterThan(0), reason: status.value);
      expect(sawAlpha, isTrue);
      if (scenario.cancel) {
        await tester.pumpWidget(const SizedBox());
        expect(actor.debugBattleScriptMosaicLevel, 0);
        expect(actor.debugBattleSpriteAnimationPaused, isFalse);
        expect(actor.stageTint.a, closeTo(1, .01));
      } else {
        expect(status.value, contains('terminée'));
        expect(status.value, contains('sans son source'));
        expect(largestMosaic, 8);
        expect(actor.currentSpriteSourcePath, 'gen5:pidgey');
        expect(actor.debugBattleScriptMosaicLevel, 0);
        expect(actor.debugBattleSpriteAnimationPaused, isFalse);
        expect(actor.stageTint.a, closeTo(1, .01));
        expect(actor.isPlayerSide, isTrue);
        final playerBytes = await tester.runAsync(
          () async => (await actor.stageImage!.toByteData())!.buffer.asUint8List(),
        );
        final enemyBytes = await tester.runAsync(
          () async => (await enemy.stageImage!.toByteData())!.buffer.asUint8List(),
        );
        expect(playerBytes, isNot(equals(enemyBytes)));
        await tester.pumpWidget(const SizedBox());
      }
      status.dispose();
    }, skip: rootPath == null);
  }

  for (final scenario in [
    (size: const Size(393, 852), id: 'harden', label: 'Armure',
        particle: 276, requireMovement: false),
    (size: const Size(852, 393), id: 'harden', label: 'Armure',
        particle: 276, requireMovement: false),
    (size: const Size(393, 852), id: 'double-kick', label: 'Double Pied',
        particle: 190, requireMovement: false),
    (size: const Size(852, 393), id: 'double-kick', label: 'Double Pied',
        particle: 190, requireMovement: false),
    (size: const Size(393, 852), id: 'surf', label: 'Surf',
        particle: 222, requireMovement: false),
    (size: const Size(852, 393), id: 'surf', label: 'Surf',
        particle: 222, requireMovement: false),
    (size: const Size(393, 852), id: 'roar', label: 'Hurlement',
        particle: 211, requireMovement: false),
    (size: const Size(852, 393), id: 'roar', label: 'Hurlement',
        particle: 211, requireMovement: false),
    (size: const Size(393, 852), id: 'whirlwind', label: 'Cyclone',
        particle: 183, requireMovement: false),
    (size: const Size(852, 393), id: 'whirlwind', label: 'Cyclone',
        particle: 183, requireMovement: false),
    (size: const Size(393, 852), id: 'dark-void', label: 'Trou Noir',
        particle: 644, requireMovement: false),
    (size: const Size(852, 393), id: 'dark-void', label: 'Trou Noir',
        particle: 644, requireMovement: false),
    (size: const Size(393, 852), id: 'mirror-move', label: 'Mimique',
        particle: 192, requireMovement: false),
    (size: const Size(852, 393), id: 'mirror-move', label: 'Mimique',
        particle: 192, requireMovement: false),
    (size: const Size(393, 852), id: 'nature-power', label: 'Force Nature',
        particle: 325, requireMovement: false),
    (size: const Size(852, 393), id: 'nature-power', label: 'Force Nature',
        particle: 325, requireMovement: false),
    for (final move in <({String id, String label, int particle})>[
      (id: 'trump-card', label: 'Atout', particle: 555),
      (id: 'hone-claws', label: 'Aiguisage', particle: 648),
      (id: 'scald', label: 'Ébullition', particle: 674),
      (id: 'hidden-power', label: 'Puissance Cachée', particle: 408),
      (id: 'flash-cannon', label: 'Luminocanon', particle: 609),
      (id: 'thunderbolt', label: 'Tonnerre', particle: 253),
      (id: 'thunder', label: 'Fatal-Foudre', particle: 256),
      (id: 'light-screen', label: 'Mur Lumière', particle: 282),
      (id: 'tri-attack', label: 'Triplattaque', particle: 329),
      (id: 'metal-claw', label: 'Griffe Acier', particle: 402),
      (id: 'taunt', label: 'Provoc', particle: 438),
      (id: 'ingrain', label: 'Racines', particle: 444),
      (id: 'crush-claw', label: 'Éclate Griffe', particle: 476),
      (id: 'gravity', label: 'Gravité', particle: 533),
      (id: 'echoed-voice', label: 'Écho', particle: 212),
      (id: 'struggle-bug', label: 'Survinsecte', particle: 425),
      (id: 'agility', label: 'Hâte', particle: 269),
      (id: 'swords-dance', label: 'Danse Lames', particle: 179),
      (id: 'psybeam', label: 'Rafale Psy', particle: 225),
      (id: 'sky-uppercut', label: 'Stratopercut', particle: 501),
      (id: 'night-slash', label: 'Tranche-Nuit', particle: 579),
      (id: 'searing-shot', label: 'Incendie', particle: 714),
      (id: 'ice-ball', label: 'Ball’Glace', particle: 471),
      (id: 'avalanche', label: 'Avalanche', particle: 598),
      (id: 'mist-ball', label: 'Ball’Brume', particle: 466),
      (id: 'electro-ball', label: 'Boule Élek', particle: 661),
      (id: 'volt-switch', label: 'Change Éclair', particle: 692),
      (id: 'secret-sword', label: 'Lame Ointe', particle: 721),
      (id: 'mirror-shot', label: 'Miroi-Tir', particle: 608),
      (id: 'psycho-boost', label: 'Psycho-Boost', particle: 531),
      (id: 'explosion', label: 'Explosion', particle: 321),
      (id: 'aqua-jet', label: 'Aqua-Jet', particle: 632),
      (id: 'eruption', label: 'Éruption', particle: 455),
      (id: 'guard-split', label: 'Partage Garde', particle: 564),
      (id: 'dragon-claw', label: 'Draco-Griffe', particle: 511),
      (id: 'sky-drop', label: 'Chute Libre', particle: 460),
      (id: 'fissure', label: 'Abîme', particle: 261),
      (id: 'power-split', label: 'Partage Force', particle: 563),
      (id: 'shadow_ball', label: 'Ball’Ombre', particle: 418),
      (id: 'fusion-flare', label: 'Flamme Croix', particle: 735),
      (id: 'fusion-bolt', label: 'Éclair Croix', particle: 737),
      (id: 'heart-swap', label: 'Permucœur', particle: 570),
      (id: 'magma-storm', label: 'Vortex Magma', particle: 643),
      (id: 'hurricane', label: 'Vent Violent', particle: 711),
      (id: 'spikes', label: 'Picots', particle: 361),
      (id: 'toxic-spikes', label: 'Pics Toxik', particle: 569),
      (id: 'stealth-rock', label: 'Piège de Roc', particle: 625),
      (id: 'leech-seed', label: 'Vampigraine', particle: 238),
      (id: 'secret-power', label: 'Force Cachée', particle: 200),
      (id: 'sweet-scent', label: 'Doux Parfum', particle: 400),
      (id: 'crush-grip', label: 'Presse', particle: 641),
    ])
      for (final size in [const Size(393, 852), const Size(852, 393)])
        (size: size, id: move.id, label: move.label,
            particle: move.particle, requireMovement: false),
    for (final size in [const Size(393, 852), const Size(852, 393)])
      (size: size, id: 'wonder-room', label: 'Zone Étrange',
          particle: null, requireMovement: false),
    for (final move in <({String id, String label, int particle})>[
      (id: 'fusion-bolt--variant-2', label: 'Éclair Croix renforcée', particle: 738),
      (id: 'fusion-flare--variant-2', label: 'Flamme Croix renforcée', particle: 736),
    ])
      for (final size in [const Size(393, 852), const Size(852, 393)])
        (size: size, id: move.id, label: move.label,
            particle: move.particle, requireMovement: false),
    for (final size in [const Size(393, 852), const Size(852, 393)])
      (size: size, id: 'magic-room', label: 'Zone Magique',
          particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'defog', label: 'Anti-Brume',
        particle: 612, requireMovement: false),
    (size: const Size(852, 393), id: 'defog', label: 'Anti-Brume',
        particle: 612, requireMovement: false),
    (size: const Size(393, 852), id: 'growl', label: 'Rugissement',
        particle: 210, requireMovement: false),
    (size: const Size(852, 393), id: 'growl', label: 'Rugissement',
        particle: 210, requireMovement: false),
    (size: const Size(393, 852), id: 'hyper-voice', label: 'Mégaphone',
        particle: 474, requireMovement: false),
    (size: const Size(852, 393), id: 'hyper-voice', label: 'Mégaphone',
        particle: 474, requireMovement: false),
    (size: const Size(393, 852), id: 'howl', label: 'Grondement',
        particle: 510, requireMovement: false),
    (size: const Size(852, 393), id: 'howl', label: 'Grondement',
        particle: 510, requireMovement: false),
    (size: const Size(393, 852), id: 'chatter', label: 'Babil',
        particle: 627, requireMovement: true),
    (size: const Size(852, 393), id: 'chatter', label: 'Babil',
        particle: 627, requireMovement: true),
    (size: const Size(393, 852), id: 'haze', label: 'Buée Noire',
        particle: 284, requireMovement: false),
    (size: const Size(852, 393), id: 'haze', label: 'Buée Noire',
        particle: 284, requireMovement: false),
    (size: const Size(393, 852), id: 'rock-tomb', label: 'Tomberoche',
        particle: 491, requireMovement: false),
    (size: const Size(852, 393), id: 'rock-tomb', label: 'Tomberoche',
        particle: 491, requireMovement: false),
    (size: const Size(393, 852), id: 'smack-down', label: 'Anti-Air',
        particle: 654, requireMovement: false),
    (size: const Size(852, 393), id: 'smack-down', label: 'Anti-Air',
        particle: 654, requireMovement: false),
    (size: const Size(393, 852), id: 'flame-charge', label: 'Nitrocharge',
        particle: 663, requireMovement: true),
    (size: const Size(852, 393), id: 'flame-charge', label: 'Nitrocharge',
        particle: 663, requireMovement: true),
    (size: const Size(393, 852), id: 'round', label: 'Chant Canon',
        particle: 668, requireMovement: false),
    (size: const Size(852, 393), id: 'round', label: 'Chant Canon',
        particle: 668, requireMovement: false),
    (size: const Size(393, 852), id: 'night-daze', label: 'Explonuit',
        particle: 708, requireMovement: true),
    (size: const Size(852, 393), id: 'night-daze', label: 'Explonuit',
        particle: 708, requireMovement: true),
    (size: const Size(393, 852), id: 'teleport', label: 'Téléport',
        particle: 272, requireMovement: true),
    (size: const Size(852, 393), id: 'teleport', label: 'Téléport',
        particle: 272, requireMovement: true),
    (size: const Size(393, 852), id: 'rapid-spin', label: 'Tour Rapide',
        particle: 399, requireMovement: false),
    (size: const Size(852, 393), id: 'rapid-spin', label: 'Tour Rapide',
        particle: 399, requireMovement: false),
    (size: const Size(393, 852), id: 'metal-sound', label: 'Strido-Son',
        particle: 493, requireMovement: false),
    (size: const Size(852, 393), id: 'metal-sound', label: 'Strido-Son',
        particle: 493, requireMovement: false),
    (size: const Size(393, 852), id: 'focus-blast', label: 'Exploforce',
        particle: 590, requireMovement: false),
    (size: const Size(852, 393), id: 'focus-blast', label: 'Exploforce',
        particle: 590, requireMovement: false),
    (size: const Size(393, 852), id: 'acrobatics', label: 'Acrobatie',
        particle: 682, requireMovement: true),
    (size: const Size(852, 393), id: 'acrobatics', label: 'Acrobatie',
        particle: 682, requireMovement: true),
    for (final move in [
      (id: 'fake-tears', label: 'Croco Larme', particle: 488),
      (id: 'telekinesis', label: 'Lévikinésie', particle: 367),
      (id: 'captivate', label: 'Séduction', particle: 624),
      (id: 'attract', label: 'Attraction', particle: 383),
      (id: 'covet', label: 'Implore', particle: 519),
      (id: 'tickle', label: 'Chatouille', particle: 495),
    ])
      for (final size in [const Size(393, 852), const Size(852, 393)])
        (size: size, id: move.id, label: move.label,
          particle: move.particle, requireMovement: false),
    (size: const Size(393, 852), id: 'skull-bash', label: 'Coud’Krâne',
        particle: null, requireMovement: true),
    (size: const Size(852, 393), id: 'skull-bash', label: 'Coud’Krâne',
        particle: null, requireMovement: true),
    (size: const Size(393, 852), id: 'entrainment', label: 'Ten-Danse',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'entrainment', label: 'Ten-Danse',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'after-you', label: 'Après Vous',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'after-you', label: 'Après Vous',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'dig', label: 'Tunnel',
        particle: 263, requireMovement: true),
    (size: const Size(852, 393), id: 'dig', label: 'Tunnel',
        particle: 263, requireMovement: true),
    (size: const Size(393, 852), id: 'extreme-speed', label: 'Vitesse Extrême',
        particle: 416, requireMovement: true),
    (size: const Size(852, 393), id: 'extreme-speed', label: 'Vitesse Extrême',
        particle: 416, requireMovement: true),
    (size: const Size(393, 852), id: 'dive', label: 'Plongée',
        particle: 461, requireMovement: true),
    (size: const Size(852, 393), id: 'dive', label: 'Plongée',
        particle: 461, requireMovement: true),
    (size: const Size(393, 852), id: 'bide', label: 'Patience',
        particle: 287, requireMovement: false),
    (size: const Size(852, 393), id: 'bide', label: 'Patience',
        particle: 287, requireMovement: false),
    (size: const Size(393, 852), id: 'sky-attack', label: 'Piqué',
        particle: 312, requireMovement: false),
    (size: const Size(852, 393), id: 'sky-attack', label: 'Piqué',
        particle: 312, requireMovement: false),
    (size: const Size(393, 852), id: 'thief', label: 'Larcin',
        particle: 338, requireMovement: false),
    (size: const Size(852, 393), id: 'thief', label: 'Larcin',
        particle: 338, requireMovement: false),
    (size: const Size(393, 852), id: 'snatch', label: 'Saisie',
        particle: null, requireMovement: true),
    (size: const Size(852, 393), id: 'snatch', label: 'Saisie',
        particle: null, requireMovement: true),
    (size: const Size(393, 852), id: 'doom-desire', label: 'Vœu Destructeur',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'doom-desire', label: 'Vœu Destructeur',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'dragon-rush', label: 'Draco-Charge',
        particle: 586, requireMovement: false),
    (size: const Size(852, 393), id: 'dragon-rush', label: 'Draco-Charge',
        particle: 586, requireMovement: false),
    (size: const Size(393, 852), id: 'fly', label: 'Vol',
        particle: 184, requireMovement: false),
    (size: const Size(852, 393), id: 'fly', label: 'Vol',
        particle: 184, requireMovement: false),
    (size: const Size(393, 852), id: 'acid-armor', label: 'Acidarmure',
        particle: 319, requireMovement: false),
    (size: const Size(852, 393), id: 'acid-armor', label: 'Acidarmure',
        particle: 319, requireMovement: false),
    (size: const Size(393, 852), id: 'sketch', label: 'Gribouille',
        particle: 336, requireMovement: false),
    (size: const Size(852, 393), id: 'sketch', label: 'Gribouille',
        particle: 336, requireMovement: false),
    (size: const Size(393, 852), id: 'nightmare', label: 'Cauchemar',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'nightmare', label: 'Cauchemar',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'camouflage', label: 'Camouflage',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'camouflage', label: 'Camouflage',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'feint-attack', label: 'Feinte',
        particle: 355, requireMovement: false),
    (size: const Size(852, 393), id: 'feint-attack', label: 'Feinte',
        particle: 355, requireMovement: false),
    (size: const Size(393, 852), id: 'bounce', label: 'Rebond',
        particle: 515, requireMovement: false),
    (size: const Size(852, 393), id: 'bounce', label: 'Rebond',
        particle: 515, requireMovement: false),
    (size: const Size(393, 852), id: 'u-turn', label: 'Demi-Tour',
        particle: 547, requireMovement: false),
    (size: const Size(852, 393), id: 'u-turn', label: 'Demi-Tour',
        particle: 547, requireMovement: false),
    (size: const Size(393, 852), id: 'brave-bird', label: 'Rapace',
        particle: 592, requireMovement: false),
    (size: const Size(852, 393), id: 'brave-bird', label: 'Rapace',
        particle: 592, requireMovement: false),
    (size: const Size(393, 852), id: 'shadow-force', label: 'Revenant',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'shadow-force', label: 'Revenant',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'perish-song', label: 'Requiem',
        particle: 365, requireMovement: false),
    (size: const Size(852, 393), id: 'perish-song', label: 'Requiem',
        particle: 365, requireMovement: false),
    (size: const Size(393, 852), id: 'rain-dance', label: 'Danse Pluie',
        particle: 411, requireMovement: false),
    (size: const Size(852, 393), id: 'rain-dance', label: 'Danse Pluie',
        particle: 411, requireMovement: false),
    (size: const Size(393, 852), id: 'sunny-day', label: 'Zénith',
        particle: 412, requireMovement: false),
    (size: const Size(852, 393), id: 'sunny-day', label: 'Zénith',
        particle: 412, requireMovement: false),
    (size: const Size(393, 852), id: 'hail', label: 'Grêle',
        particle: 428, requireMovement: false),
    (size: const Size(852, 393), id: 'hail', label: 'Grêle',
        particle: 428, requireMovement: false),
    (size: const Size(393, 852), id: 'trick', label: 'Tour de Magie',
        particle: 441, requireMovement: false),
    (size: const Size(852, 393), id: 'trick', label: 'Tour de Magie',
        particle: 441, requireMovement: false),
    (size: const Size(393, 852), id: 'aromatherapy', label: 'Aromathérapie',
        particle: 487, requireMovement: false),
    (size: const Size(852, 393), id: 'aromatherapy', label: 'Aromathérapie',
        particle: 487, requireMovement: false),
    (size: const Size(393, 852), id: 'volt-tackle', label: 'Électacle',
        particle: 521, requireMovement: false),
    (size: const Size(852, 393), id: 'volt-tackle', label: 'Électacle',
        particle: 521, requireMovement: false),
    (size: const Size(393, 852), id: 'water-pulse', label: 'Vibraqua',
        particle: 529, requireMovement: false),
    (size: const Size(852, 393), id: 'water-pulse', label: 'Vibraqua',
        particle: 529, requireMovement: false),
    (size: const Size(393, 852), id: 'switcheroo', label: 'Passe-Passe',
        particle: 594, requireMovement: false),
    (size: const Size(852, 393), id: 'switcheroo', label: 'Passe-Passe',
        particle: 594, requireMovement: false),
    (size: const Size(393, 852), id: 'water-spout', label: 'Giclédo',
        particle: 497, requireMovement: false),
    (size: const Size(852, 393), id: 'water-spout', label: 'Giclédo',
        particle: 497, requireMovement: false),
    (size: const Size(393, 852), id: 'draco-meteor', label: 'Draco-Météore',
        particle: 613, requireMovement: false),
    (size: const Size(852, 393), id: 'draco-meteor', label: 'Draco-Météore',
        particle: 613, requireMovement: false),
    (size: const Size(393, 852), id: 'poison-gas', label: 'Gaz Toxik',
        particle: 308, requireMovement: false),
    (size: const Size(852, 393), id: 'poison-gas', label: 'Gaz Toxik',
        particle: 308, requireMovement: false),
    (size: const Size(393, 852), id: 'psywave', label: 'Vague Psy',
        particle: 317, requireMovement: false),
    (size: const Size(852, 393), id: 'psywave', label: 'Vague Psy',
        particle: 317, requireMovement: false),
    (size: const Size(393, 852), id: 'blizzard', label: 'Blizzard',
        particle: 224, requireMovement: false),
    (size: const Size(852, 393), id: 'blizzard', label: 'Blizzard',
        particle: 224, requireMovement: false),
    (size: const Size(393, 852), id: 'rollout', label: 'Roulade',
        particle: 375, requireMovement: false),
    (size: const Size(852, 393), id: 'rollout', label: 'Roulade',
        particle: 375, requireMovement: false),
    (size: const Size(393, 852), id: 'double-team', label: 'Reflet',
        particle: null, requireMovement: true),
    (size: const Size(852, 393), id: 'double-team', label: 'Reflet',
        particle: null, requireMovement: true),
    (size: const Size(393, 852), id: 'strength', label: 'Force',
        particle: 235, requireMovement: true),
    (size: const Size(852, 393), id: 'strength', label: 'Force',
        particle: 235, requireMovement: true),
    (size: const Size(393, 852), id: 'earthquake', label: 'Séisme',
        particle: 260, requireMovement: false),
    (size: const Size(852, 393), id: 'earthquake', label: 'Séisme',
        particle: 260, requireMovement: false),
    (size: const Size(393, 852), id: 'magnitude', label: 'Ampleur',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'magnitude', label: 'Ampleur',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'reversal', label: 'Contre',
        particle: 350, requireMovement: false),
    (size: const Size(852, 393), id: 'reversal', label: 'Contre',
        particle: 350, requireMovement: false),
    (size: const Size(393, 852), id: 'fury-cutter', label: 'Taillade',
        particle: 380, requireMovement: false),
    (size: const Size(852, 393), id: 'fury-cutter', label: 'Taillade',
        particle: 380, requireMovement: false),
    (size: const Size(393, 852), id: 'absorb', label: 'Vole-Vie',
        particle: 236, requireMovement: false),
    (size: const Size(852, 393), id: 'absorb', label: 'Vole-Vie',
        particle: 236, requireMovement: false),
    (size: const Size(393, 852), id: 'jump-kick', label: 'Pied Sauté',
        particle: 192, requireMovement: false),
    (size: const Size(852, 393), id: 'jump-kick', label: 'Pied Sauté',
        particle: 192, requireMovement: false),
    (size: const Size(393, 852), id: 'mud-bomb', label: 'Boue-Bombe',
        particle: 605, requireMovement: false),
    (size: const Size(852, 393), id: 'mud-bomb', label: 'Boue-Bombe',
        particle: 605, requireMovement: false),
    (size: const Size(393, 852), id: 'drain-punch', label: 'Vampi-Poing',
        particle: 588, requireMovement: false),
    (size: const Size(852, 393), id: 'drain-punch', label: 'Vampi-Poing',
        particle: 588, requireMovement: false),
    (size: const Size(393, 852), id: 'heat-wave', label: 'Canicule',
        particle: 427, requireMovement: false),
    (size: const Size(852, 393), id: 'heat-wave', label: 'Canicule',
        particle: 427, requireMovement: false),
    (size: const Size(393, 852), id: 'cotton-spore', label: 'Spore Coton',
        particle: 349, requireMovement: false),
    (size: const Size(852, 393), id: 'cotton-spore', label: 'Spore Coton',
        particle: 349, requireMovement: false),
    (size: const Size(393, 852), id: 'flare-blitz', label: 'Boutefeu',
        particle: 573, requireMovement: true),
    (size: const Size(852, 393), id: 'flare-blitz', label: 'Boutefeu',
        particle: 573, requireMovement: true),
    (size: const Size(393, 852), id: 'aerial-ace', label: 'Aéropique',
        particle: 506, requireMovement: true),
    (size: const Size(852, 393), id: 'aerial-ace', label: 'Aéropique',
        particle: 506, requireMovement: true),
    (size: const Size(393, 852), id: 'meditate', label: 'Yoga',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'mud-sport', label: 'Lance-Boue',
        particle: 470, requireMovement: false),
    (size: const Size(393, 852), id: 'night-shade', label: 'Ombre Nocturne',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'shell-smash', label: 'Exuviation',
        particle: 675, requireMovement: false),
    (size: const Size(393, 852), id: 'spit-up', label: 'Relâche',
        particle: 425, requireMovement: true),
    (size: const Size(393, 852), id: 'bulk-up', label: 'Gonflette',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'bulldoze', label: 'Piétisol',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'flash', label: 'Flash',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'future-sight', label: 'Prescience',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'minimize', label: 'Lilliput',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'role-play', label: 'Imitation',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'spite', label: 'Dépit',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'tail-whip', label: 'Mimi-Queue',
        particle: null, requireMovement: true),
    (size: const Size(393, 852), id: 'growth', label: 'Croissance',
        particle: 241, requireMovement: false),
    (size: const Size(852, 393), id: 'confusion', label: 'Choc Mental',
        particle: 266, requireMovement: false),
    (size: const Size(393, 852), id: 'frenzy-plant', label: 'Végé-Attaque',
        particle: 514, requireMovement: false),
    (size: const Size(852, 393), id: 'aqua-tail', label: 'Hydro-Queue',
        particle: 580, requireMovement: false),
    (size: const Size(393, 852), id: 'freeze-shock', label: 'Éclair Gelé',
        particle: 726, requireMovement: false),
    (size: const Size(393, 852), id: 'quick_attack', label: 'Vive-Attaque',
        particle: 270, requireMovement: true),
    (size: const Size(852, 393), id: 'quick_attack', label: 'Vive-Attaque',
        particle: 270, requireMovement: true),
    (size: const Size(393, 852), id: 'astonish', label: 'Étonnement',
        particle: 481, requireMovement: true),
    (size: const Size(852, 393), id: 'facade', label: 'Façade',
        particle: 433, requireMovement: false),
    (size: const Size(393, 852), id: 'grass-pledge', label: 'Aire d’Herbe',
        particle: 690, requireMovement: false),
    (size: const Size(852, 393), id: 'charm', label: 'Charme',
        particle: 374, requireMovement: false),
    (size: const Size(393, 852), id: 'thunder-fang', label: 'Crocs Éclair',
        particle: 601, requireMovement: false),
    (size: const Size(852, 393), id: 'sharpen', label: 'Affûtage',
        particle: 327, requireMovement: false),
    (size: const Size(393, 852), id: 'protect', label: 'Abri',
        particle: 352, requireMovement: false),
    (size: const Size(852, 393), id: 'acid-spray', label: 'Bombe Acide',
        particle: 665, requireMovement: false),
    (size: const Size(393, 852), id: 'hydro_pump', label: 'Hydrocanon',
        particle: 221, requireMovement: false),
    (size: const Size(852, 393), id: 'hydro_pump', label: 'Hydrocanon',
        particle: 221, requireMovement: false),
    (size: const Size(393, 852), id: 'solar-beam', label: 'Lance-Soleil',
        particle: 243, requireMovement: false),
    (size: const Size(852, 393), id: 'solar-beam', label: 'Lance-Soleil',
        particle: 243, requireMovement: false),
    (size: const Size(852, 393), id: 'thunder-wave', label: 'Cage Éclair',
        particle: 255, requireMovement: false),
    (size: const Size(393, 852), id: 'focus-punch', label: 'Mitra-Poing',
        particle: 434, requireMovement: false),
    (size: const Size(852, 393), id: 'close-combat', label: 'Close Combat',
        particle: 549, requireMovement: false),
    (size: const Size(393, 852), id: 'calm-mind', label: 'Plénitude',
        particle: 524, requireMovement: false),
    (size: const Size(852, 393), id: 'leaf-storm', label: 'Tempête Verte',
        particle: 616, requireMovement: false),
    (size: const Size(393, 852), id: 'lunar-dance', label: 'Danse Lune',
        particle: 640, requireMovement: false),
    (size: const Size(852, 393), id: 'lunar-dance', label: 'Danse Lune',
        particle: 640, requireMovement: false),
    (size: const Size(393, 852), id: 'psychic', label: 'Psyko',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'psychic', label: 'Psyko',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'waterfall', label: 'Cascade',
        particle: 296, requireMovement: false),
    (size: const Size(852, 393), id: 'waterfall', label: 'Cascade',
        particle: 296, requireMovement: false),
    (size: const Size(393, 852), id: 'sacred-fire', label: 'Feu Sacré',
        particle: 392, requireMovement: false),
    (size: const Size(852, 393), id: 'whirlpool', label: 'Siphon',
        particle: 420, requireMovement: false),
    (size: const Size(393, 852), id: 'inferno', label: 'Feu d’Enfer',
        particle: 687, requireMovement: false),
    (size: const Size(852, 393), id: 'blue-flare', label: 'Flamme Bleue',
        particle: 724, requireMovement: false),
    (size: const Size(393, 852), id: 'sing', label: 'Berceuse',
        particle: 212, requireMovement: false),
    (size: const Size(852, 393), id: 'sing', label: 'Berceuse',
        particle: 212, requireMovement: false),
    (size: const Size(852, 393), id: 'powder-snow', label: 'Poudreuse',
        particle: 351, requireMovement: false),
    (size: const Size(393, 852), id: 'frost-breath', label: 'Souffle Glacé',
        particle: 694, requireMovement: false),
    (size: const Size(393, 852), id: 'ember', label: 'Flammèche',
        particle: 217, requireMovement: false),
    (size: const Size(852, 393), id: 'ember', label: 'Flammèche',
        particle: 217, requireMovement: false),
    (size: const Size(393, 852), id: 'bind', label: 'Étreinte',
        particle: 186, requireMovement: false),
    (size: const Size(852, 393), id: 'bind', label: 'Étreinte',
        particle: 186, requireMovement: false),
    (size: const Size(393, 852), id: 'bubble', label: 'Écume',
        particle: 314, requireMovement: false),
    (size: const Size(393, 852), id: 'megahorn', label: 'Mégacorne',
        particle: 394, requireMovement: false),
    (size: const Size(852, 393), id: 'megahorn', label: 'Mégacorne',
        particle: 394, requireMovement: false),
    (size: const Size(393, 852), id: 'mist', label: 'Brume',
        particle: 219, requireMovement: false),
    (size: const Size(852, 393), id: 'thrash', label: 'Mania',
        particle: 203, requireMovement: false),
    (size: const Size(393, 852), id: 'lava-plume', label: 'Ébullilave',
        particle: 615, requireMovement: false),
    (size: const Size(852, 393), id: 'overheat', label: 'Surchauffe',
        particle: 490, requireMovement: false),
    (size: const Size(852, 393), id: 'rage', label: 'Frénésie',
        particle: 271, requireMovement: false),
    (size: const Size(393, 852), id: 'synchronoise', label: 'Synchropeine',
        particle: 660, requireMovement: false),
    (size: const Size(393, 852), id: 'fire_blast', label: 'Déflagration',
        particle: 295, requireMovement: false),
    (size: const Size(852, 393), id: 'fire_blast', label: 'Déflagration',
        particle: 295, requireMovement: false),
  ]) {
    testWidgets('${scenario.label} runs in the workshop at ${scenario.size}', (tester) async {
      final size = scenario.size;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final root = (await tester.runAsync(
        () => extractPreviewResources(parent: Directory(rootPath!)),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final status = ValueNotifier<String>('Preparing');
      final game = BattlePreviewGame(
        projectRoot: root.path,
        move: scenario.id == 'surf' ? PreviewMove.surf :
            scenario.id == 'roar' ? PreviewMove.roar :
            {'mirror-move', 'nature-power'}.contains(scenario.id)
                ? PreviewMove.values.singleWhere((move) => move.id == scenario.id) :
            scenario.id == 'shadow_ball' ? PreviewMove.shadowBall :
            scenario.id == 'quick_attack' ? PreviewMove.quickAttack :
            scenario.id == 'hydro_pump' ? PreviewMove.hydroPump :
            scenario.id == 'fire_blast' ? PreviewMove.fireBlast :
            scenario.id == 'psychic' ? PreviewMove.psychic :
            scenario.id == 'fly' ? PreviewMove.fly :
            scenario.id == 'thief' ? PreviewMove.thief : PreviewMove(
          scenario.id.split('--').first, scenario.label, null, 'normal', PsdkBattleMoveCategory.physical,
          particle: scenario.particle,
          bundleAsset: 'assets/bw2/batch/${scenario.id}.json',
        ),
        status: status,
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: size.width, height: size.height,
            child: GameWidget(game: game)),
      ));
      BattleOverlayComponent? overlay() {
        final values = game.children.whereType<BattleOverlayComponent>();
        return values.isEmpty ? null : values.first;
      }
      for (var tick = 0; tick < 360 && status.value != 'Combat prêt · appuie sur Lancer'; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(status.value, 'Combat prêt · appuie sur Lancer');
      final initial = overlay()!.debugPlayerCombatant!.currentVisualOffset;
      final initialEnemy = overlay()!.debugEnemyCombatant!.currentVisualOffset;
      final initialRotation = overlay()!.debugPlayerCombatant!.currentVisualRotation;
      final initialEnemyRotation = overlay()!.debugEnemyCombatant!.currentVisualRotation;
      final initialCameraEye = overlay()!.battleCameraPose!.eye;
      final initialSize = overlay()!.debugPlayerCombatant!
          .currentCameraNeutralRenderedSpriteRect.size;
      final initialPlayerAlpha = overlay()!.debugPlayerCombatant!.stageTint.a;
      final initialEnemyAlpha = overlay()!.debugEnemyCombatant!.stageTint.a;
      var started = false;
      var sawParticles = false;
      var sawMovement = false;
      var sawEnemyMovement = false;
      var sawScale = false;
      var sawChildParticle = false;
      var sawPolygonOffset = false;
      var sawHiddenParentEmitter = false;
      var sawBackground = false;
      var sawWave = false;
      var sawPaletteAnimation = false;
      var sawCameraMovement = false;
      var sawAlpha = false;
      var sawHidden = false;
      var sawRotation = false;
      var sawBothPalettes = false;
      final emitterPositions = <BattleSplStaticComponent, Set<(int, int, int)>>{};
      unawaited(game.play(onStart: () => started = true));
      for (var tick = 0; tick < 600; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
        final scene = overlay();
        if (scene != null) {
          final camera = scene.battleCameraPose;
          if (camera != null) {
            sawCameraMovement |= camera.eye.distanceTo(initialCameraEye) > .0001;
          }
          sawParticles |= scene.children.whereType<BattleSplStaticComponent>()
              .any((effect) => effect.playback.activeParticles > 0);
          sawChildParticle |= scene.children.whereType<BattleSplStaticComponent>()
              .any((effect) => effect.playback.frames.any((frame) =>
                  frame.particles.any((particle) => particle.parentId != null)));
          sawPolygonOffset |= scene.children.whereType<BattleSplStaticComponent>()
              .any((effect) => effect.playback.frames.any((frame) =>
                  frame.polygonX != 0 || frame.polygonY != 0));
          sawHiddenParentEmitter |= scene.children.whereType<BattleSplStaticComponent>()
              .any((effect) => effect.playback.frames.any((frame) =>
                  frame.hideParent && frame.particles.any((particle) => particle.parentId == null)));
          if ({'magma-storm', 'hurricane', 'leech-seed'}.contains(scenario.id)) {
            for (final effect in scene.children.whereType<BattleSplStaticComponent>()) {
              if (effect.advanceEmitterPosition == null) continue;
              for (final frame in effect.playback.frames) {
                for (final particle in frame.particles) {
                  emitterPositions.putIfAbsent(effect, () => {}).add(
                    (particle.emitterPosition.x, particle.emitterPosition.y,
                        particle.emitterPosition.z),
                  );
                }
              }
            }
          }
          sawMovement |= scene.debugPlayerCombatant!.currentVisualOffset != initial;
          sawEnemyMovement |= scene.debugEnemyCombatant!.currentVisualOffset != initialEnemy;
          sawAlpha |= scene.debugPlayerCombatant!.stageTint.a < initialPlayerAlpha - 0.05 ||
              scene.debugEnemyCombatant!.stageTint.a < initialEnemyAlpha - 0.05;
          sawHidden |= scene.debugPlayerCombatant!.isHiddenForBattleScript;
          sawBothPalettes |= scene.debugPlayerCombatant!.hasBattleScriptPalette &&
              scene.debugEnemyCombatant!.hasBattleScriptPalette;
          sawRotation |= (scene.debugPlayerCombatant!.currentVisualRotation - initialRotation).abs() > .001 ||
              (scene.debugEnemyCombatant!.currentVisualRotation - initialEnemyRotation).abs() > .001;
          sawScale |= scene.debugPlayerCombatant!
              .currentCameraNeutralRenderedSpriteRect.size != initialSize;
          sawBackground |= scene.children.whereType<BattleGen5SourceBackground>()
              .any((background) => background.visible || background.hideField);
          sawWave |= scene.children.whereType<BattleGen5SourceBackground>()
              .any((background) => background.isWaving);
          sawPaletteAnimation |= scene.children.whereType<BattleGen5SourceBackground>()
              .any((background) => background.isPaletteAnimating);
        }
        if (status.value.contains('terminée') ||
            status.value.contains('Impossible') ||
            status.value.contains('interrompue')) {
          break;
        }
      }
      expect(started, isTrue, reason: status.value);
      if ({'acid-armor', 'sketch', 'nightmare', 'camouflage'}.contains(scenario.id)) {
        expect(sawAlpha, isTrue, reason: status.value);
      }
      if (scenario.id == 'fly') {
        expect(sawHidden, isTrue, reason: status.value);
      }
      if ({'fake-tears', 'telekinesis', 'captivate', 'attract', 'covet', 'tickle',
          'skull-bash', 'entrainment', 'after-you', 'whirlwind'}.contains(scenario.id)) {
        expect(sawRotation, isTrue, reason: status.value);
      }
      if (scenario.id == 'defog') {
        expect(sawBothPalettes, isTrue, reason: status.value);
      }
      if (scenario.particle != null) {
        expect(sawParticles, isTrue, reason: status.value);
      }
      if ({'mist-ball', 'electro-ball', 'volt-switch', 'fusion-bolt', 'fusion-flare',
        'fusion-bolt--variant-2', 'fusion-flare--variant-2',
        'secret-sword', 'mirror-shot', 'thunderbolt', 'psycho-boost', 'explosion'}
          .contains(scenario.id)) {
        expect(sawChildParticle, isTrue, reason: status.value);
      }
      if ({'agility', 'swords-dance', 'fissure', 'fusion-flare', 'extreme-speed'}
          .contains(scenario.id)) {
        expect(sawPolygonOffset, isTrue, reason: status.value);
      }
      if ({'lunar-dance', 'flash-cannon', 'psybeam', 'sky-uppercut', 'night-slash',
        'agility', 'searing-shot', 'ice-ball', 'avalanche', 'sketch', 'extreme-speed'}
          .contains(scenario.id)) {
        expect(sawHiddenParentEmitter, isTrue, reason: status.value);
      }
      if ({'magma-storm', 'hurricane', 'leech-seed'}.contains(scenario.id)) {
        expect(emitterPositions.values.any((positions) => positions.length > 1),
            isTrue, reason: 'Les particules doivent suivre leur trajectoire.');
      }
      if (scenario.requireMovement) {
        expect(sawMovement, isTrue, reason: status.value);
      }
      if ({'roar', 'whirlwind', 'dark-void'}.contains(scenario.id)) {
        expect(sawEnemyMovement, isTrue, reason: status.value);
      }
      if ({'magnitude', 'water-spout', 'draco-meteor', 'fusion-flare', 'fusion-bolt',
        'fusion-bolt--variant-2', 'fusion-flare--variant-2'}.contains(scenario.id)) {
        expect(sawCameraMovement, isTrue, reason: status.value);
      }
      if ({'bulk-up', 'minimize', 'meditate', 'night-shade', 'doom-desire',
        'shell-smash', 'spit-up', 'wonder-room', 'magic-room'}.contains(scenario.id)) {
        expect(sawScale, isTrue, reason: status.value);
      }
      if ({'hydro_pump', 'focus-punch', 'close-combat', 'leaf-storm', 'lunar-dance', 'fire_blast', 'psychic',
        'waterfall', 'sacred-fire', 'whirlpool', 'inferno', 'blue-flare', 'megahorn', 'overheat',
        'flare-blitz', 'aerial-ace', 'fissure', 'wonder-room', 'magic-room', 'dark-void'}
          .contains(scenario.id)) {
        expect(sawBackground, isTrue, reason: status.value);
      }
      if ({'fire_blast', 'megahorn', 'flare-blitz', 'aerial-ace'}.contains(scenario.id)) {
        expect(sawPaletteAnimation, isTrue, reason: status.value);
      }
      if ({'psychic', 'waterfall', 'sacred-fire', 'whirlpool', 'inferno', 'blue-flare', 'flare-blitz'}
          .contains(scenario.id)) {
        expect(sawWave, isTrue, reason: status.value);
      }
      expect(status.value, contains('terminée'));
      expect(overlay()!.debugPlayerCombatant!.currentVisualOffset, initial);
      if ({'dig', 'extreme-speed', 'dive', 'roar', 'whirlwind', 'dark-void'}.contains(scenario.id)) {
        expect(overlay()!.debugEnemyCombatant!.currentVisualOffset, initialEnemy);
      }
      if ({'fake-tears', 'telekinesis', 'captivate', 'attract', 'covet', 'tickle',
          'skull-bash', 'entrainment', 'after-you', 'whirlwind'}.contains(scenario.id)) {
        expect(overlay()!.debugPlayerCombatant!.currentVisualRotation, closeTo(initialRotation, .001));
        expect(overlay()!.debugEnemyCombatant!.currentVisualRotation, closeTo(initialEnemyRotation, .001));
      }
      if ({'acid-armor', 'sketch', 'nightmare', 'camouflage'}.contains(scenario.id)) {
        expect(overlay()!.debugPlayerCombatant!.stageTint.a, closeTo(initialPlayerAlpha, .001));
        expect(overlay()!.debugEnemyCombatant!.stageTint.a, closeTo(initialEnemyAlpha, .001));
      }
      await tester.pumpWidget(const SizedBox());
      status.dispose();
    }, skip: rootPath == null);
  }

  for (final scenario in [
    (move: PreviewMove.waterGun, enemy: 'Roucool'),
    (move: PreviewMove.surf, enemy: 'Miamiasme'),
  ]) {
    testWidgets('preview shows only ${scenario.move.label}', (tester) async {
      final root = (await tester.runAsync(
        () => extractPreviewResources(parent: Directory(rootPath!)),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final status = ValueNotifier<String>('Preparing');
      addTearDown(status.dispose);
      final game = BattlePreviewGame(
        projectRoot: root.path,
        move: scenario.move,
        status: status,
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 393, height: 852, child: GameWidget(game: game)),
      ));
      BattleOverlayComponent? overlay() {
        final values = game.children.whereType<BattleOverlayComponent>();
        return values.isEmpty ? null : values.first;
      }

      for (var tick = 0;
          tick < 360 && status.value != 'Combat prêt · appuie sur Lancer';
          tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(status.value, 'Combat prêt · appuie sur Lancer');
      final initialHp = overlay()!.debugSession.state.player.currentHp;
      final messages = <String>{};
      int? finishedAt;
      unawaited(game.play());
      for (var tick = 0; tick < 1000; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
        final message = overlay()?.debugCurrentAnimationMessage;
        if (message != null) messages.add(message);
        if (status.value.contains('terminée')) finishedAt ??= tick;
        if (finishedAt != null && tick - finishedAt >= 180) break;
      }
      expect(status.value, contains('terminée'));
      expect(messages.any((message) => message.contains(scenario.move.label)), isTrue);
      expect(messages.any((message) => message.contains('${scenario.enemy} utilise')), isFalse);
      final turn = overlay()!.debugSession.state.currentTurn!;
      expect(
        turn.timeline.whereType<BattleTurnExecutionEvent>()
            .map((event) => event.execution.attackerSide),
        [BattleSideId.player],
      );
      expect(overlay()!.debugSession.state.player.currentHp, initialHp);
      await tester.pumpWidget(const SizedBox());
    }, skip: rootPath == null);
  }

  for (final scenario in [
    (move: PreviewMove.tackle, player: 'gen5:totodile', enemy: 'gen5:pidgey'),
    (
      move: PreviewMove.surf,
      player: 'herdier-back.gif',
      enemy: 'trubbish-front.gif',
    ),
  ]) {
    testWidgets('attack workshop loads sprites for ${scenario.move.label}', (
      tester,
    ) async {
      final root = (await tester.runAsync(
        () => extractPreviewResources(parent: Directory(rootPath!)),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final status = ValueNotifier<String>('Preparing');
      final game = BattlePreviewGame(
        projectRoot: root.path,
        move: scenario.move,
        status: status,
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 393,
            height: 852,
            child: GameWidget(game: game),
          ),
        ),
      );
      BattleOverlayComponent? overlay() {
        final values = game.children.whereType<BattleOverlayComponent>();
        return values.isEmpty ? null : values.first;
      }

      for (var i = 0; i < 360; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 3)),
        );
        if ((overlay()?.debugPlayerCombatant?.currentSpriteSourcePath ?? '')
                .endsWith(scenario.player) &&
            (overlay()?.debugEnemyCombatant?.currentSpriteSourcePath ?? '')
                .endsWith(scenario.enemy)) {
          break;
        }
      }
      expect(
        overlay()?.debugPlayerCombatant?.currentSpriteSourcePath,
        endsWith(scenario.player),
      );
      expect(
        overlay()?.debugEnemyCombatant?.currentSpriteSourcePath,
        endsWith(scenario.enemy),
      );
      await tester.pumpWidget(const SizedBox());
      status.dispose();
    }, skip: rootPath == null);
  }
}

class _OverflowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(-24, 0, 24, size.height),
        Paint()..color = const Color(0xffff0000));
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xff00ff00));
  }

  @override
  bool shouldRepaint(covariant _OverflowPainter oldDelegate) => false;
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_ball_capture_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:path/path.dart' as p;

import 'support/load_flame_component.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory project;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('project-capture-overlay-');
  });

  tearDown(() => project.delete(recursive: true));

  test('intro and capture never request a bundled battle ball without media',
      () async {
    final assets = <String>[];
    final messenger = binding.defaultBinaryMessenger;
    final original = messenger.allMessagesHandler;
    messenger.allMessagesHandler = (channel, handler, message) {
      if (channel == 'flutter/assets' && message != null) {
        assets.add(utf8.decode(message.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        )));
      }
      if (original != null) return original(channel, handler, message);
      return handler?.call(message) ??
          messenger.delegate.send(channel, message);
    };
    addTearDown(() => messenger.allMessagesHandler = original);

    for (final introEnabled in [false, true]) {
      final before = _session();
      final overlay = await _mount(before, introEnabled: introEnabled);
      if (introEnabled) {
        overlay.startIntro();
        await _finishTurn(overlay);
      }
      final after = before.applyChoice(
        const PlayerBattleChoiceCapture(itemId: 'custom-orb'),
      );
      overlay.updateState(after);
      await overlay.waitForPendingVisualSync();
      await _finishTurn(overlay);

      expect(overlay.children.whereType<BattleBallCaptureComponent>(), isEmpty);
    }

    expect(assets.where((asset) => asset.contains('battle/balls/')), isEmpty);
  });

  test('preloads the exact capture item before starting its presentation',
      () async {
    final sprite = await _sheet(project, 'custom.png', 10);
    final loadedPath = Completer<String?>();
    final requestedItem = Completer<String>();
    final before = _session();
    final overlay = await _mount(
      before,
      resolveBallSpritePath: (itemId) {
        requestedItem.complete(itemId);
        return loadedPath.future;
      },
    );
    addTearDown(() {
      if (!loadedPath.isCompleted) loadedPath.complete(null);
    });
    final after = before.applyChoice(
      const PlayerBattleChoiceCapture(itemId: 'custom-orb'),
    );

    overlay.updateState(after);
    expect(await requestedItem.future, 'custom-orb');
    expect(after.state.currentTurn!.captureAttemptEvents.single.ballId,
        'custom-orb');
    expect(overlay.isTurnPresentationActive, isFalse);
    overlay.updateTree(2);
    expect(overlay.debugCurrentAnimationMessage, isNull);
    expect(overlay.children.whereType<BattleBallCaptureComponent>(), isEmpty);

    loadedPath.complete(sprite.path);
    await overlay.waitForPendingVisualSync();

    expect(overlay.isTurnPresentationActive, isTrue);
    final ball = await _captureComponent(overlay);
    expect(await _redPixel(ball.sheet), 10);
    await _finishTurn(overlay);
  });

  test('two capture items keep their distinct project sheets in one battle',
      () async {
    final first = await _sheet(project, 'first.png', 20);
    final second = await _sheet(project, 'second.png', 40);
    final paths = {'first-orb': first.path, 'second-orb': second.path};
    final requested = <String>[];
    final before = _session(failedCapture: true);
    final overlay = await _mount(
      before,
      resolveBallSpritePath: (itemId) async {
        requested.add(itemId);
        return paths[itemId];
      },
    );
    final firstTurn = before.applyChoice(
      const PlayerBattleChoiceCapture(itemId: 'first-orb'),
    );
    expect(firstTurn.state.isFinished, isFalse);
    overlay.updateState(firstTurn);
    await overlay.waitForPendingVisualSync();
    final firstBall = await _captureComponent(overlay);
    expect(await _redPixel(firstBall.sheet), 20);
    await _finishTurn(overlay);

    final secondTurn = firstTurn.applyChoice(
      const PlayerBattleChoiceCapture(itemId: 'second-orb'),
    );
    overlay.updateState(secondTurn);
    await overlay.waitForPendingVisualSync();
    final secondBall = await _captureComponent(overlay);

    expect(await _redPixel(secondBall.sheet), 40);
    expect(identical(firstBall.sheet, secondBall.sheet), isFalse);
    expect(requested, ['first-orb', 'second-orb']);
    await _finishTurn(overlay);
  });

  test('a pending capture preload cannot restart an overlay after removal',
      () async {
    final sprite = await _sheet(project, 'late.png', 10);
    final loadedPath = Completer<String?>();
    final requested = Completer<void>();
    final before = _session();
    final overlay = await _mount(
      before,
      resolveBallSpritePath: (_) {
        requested.complete();
        return loadedPath.future;
      },
    );
    addTearDown(() {
      if (!loadedPath.isCompleted) loadedPath.complete(null);
    });
    overlay.updateState(before.applyChoice(
      const PlayerBattleChoiceCapture(itemId: 'custom-orb'),
    ));
    await requested.future;

    overlay.onRemove();
    loadedPath.complete(sprite.path);
    await overlay.waitForPendingVisualSync();

    expect(overlay.isTurnPresentationActive, isFalse);
    expect(overlay.children.whereType<BattleBallCaptureComponent>(), isEmpty);
  });

  test('a pending intro preload cannot recreate its plan after removal',
      () async {
    final sprite = await _sheet(project, 'late-intro.png', 10);
    final loadedPath = Completer<String?>();
    final requested = Completer<void>();
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
      introEnabled: true,
      resolveCombatantBallItemId: (_, __) => 'custom-orb',
      resolveBallSpritePath: (_) {
        requested.complete();
        return loadedPath.future;
      },
    );
    addTearDown(overlay.onRemove);
    addTearDown(() {
      if (!loadedPath.isCompleted) loadedPath.complete(null);
    });
    final loading = loadFlameComponent(overlay);
    await requested.future;

    overlay.onRemove();
    loadedPath.complete(sprite.path);
    await loading;

    expect(overlay.isTurnPresentationActive, isFalse);
    overlay.startIntro();
    expect(overlay.isTurnPresentationActive, isFalse);
  });

  test('missing and corrupt project media never prevent the capture outcome',
      () async {
    final corrupt = File(p.join(project.path, 'corrupt.png'));
    await corrupt.writeAsBytes([1, 2, 3]);
    final wrongLayout =
        await _sheet(project, 'wrong-layout.png', 10, height: 64);
    for (final path in [
      null,
      p.join(project.path, 'missing.png'),
      corrupt.path,
      wrongLayout.path,
    ]) {
      final outcomes = <BattleOutcome>[];
      final before = _session();
      final overlay = await _mount(
        before,
        resolveBallSpritePath: (_) async => path,
        onOutcomePresented: outcomes.add,
      );
      final after = before.applyChoice(
        const PlayerBattleChoiceCapture(itemId: 'custom-orb'),
      );
      expect(after.state.outcome?.isCaptured, isTrue);

      overlay.updateState(after);
      await overlay.waitForPendingVisualSync();
      expect(overlay.isTurnPresentationActive, isTrue);
      await _finishTurn(overlay);

      expect(overlay.children.whereType<BattleBallCaptureComponent>(), isEmpty);
      expect(outcomes.single.isCaptured, isTrue);
      expect(outcomes.single.captureItemId, 'custom-orb');
    }
  });

  test('the Flutter bundle excludes all former ball PNGs and retains emotes',
      () async {
    final names = [
      for (var index = 1; index <= 28; index++) 'ball_$index.png',
      'ball-retreat.png',
      'ball_catch.png',
      'ball_s1.png',
      'ball_s2.png',
      'ball_stars.png',
    ];
    for (final name in names) {
      await expectLater(
        () => rootBundle.load('packages/map_runtime/assets/battle/balls/$name'),
        throwsFlutterError,
        reason: name,
      );
      await expectLater(
        () => rootBundle.load('assets/battle/balls/$name'),
        throwsFlutterError,
        reason: name,
      );
    }
    expect(
      (await rootBundle.load(
        'packages/map_runtime/assets/cinematics/emotes/emotions.png',
      ))
          .lengthInBytes,
      greaterThan(0),
    );
  });
}

BattleSession _session({bool failedCapture = false}) => createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: const BattleCombatantData(
          speciesId: 'player',
          level: 10,
          maxHp: 100,
          stats: _stats,
          moves: [BattleMoveData(id: 'wait', name: 'Wait', power: 0)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'wild',
          level: 10,
          maxHp: 100,
          currentHp: failedCapture ? 100 : 1,
          catchRate: failedCapture ? 1 : 255,
          majorStatus:
              failedCapture ? null : const BattleMajorStatusState.slp(),
          stats: _stats,
          moves: const [BattleMoveData(id: 'wait', name: 'Wait', power: 0)],
        ),
        allowCapture: true,
        isTrainerBattle: false,
        trainerId: null,
      ),
      rng: failedCapture
          ? const BattleSeededRng(state: 47)
          : const BattleScriptedRng([1]),
    );

const _stats = BattleStatsSnapshot(
  attack: 30,
  defense: 30,
  specialAttack: 30,
  specialDefense: 30,
  speed: 30,
);

Future<BattleOverlayComponent> _mount(
  BattleSession session, {
  bool introEnabled = false,
  Future<String?> Function(String itemId)? resolveBallSpritePath,
  void Function(BattleOutcome outcome)? onOutcomePresented,
}) async {
  final overlay = BattleOverlayComponent(
    session: session,
    viewportSize: Vector2(960, 540),
    onPlayerChoice: (_) {},
    introEnabled: introEnabled,
    resolveBallSpritePath: resolveBallSpritePath,
    onOutcomePresented: onOutcomePresented,
  );
  addTearDown(overlay.onRemove);
  await loadFlameComponent(overlay);
  await overlay.waitForPendingVisualSync();
  return overlay;
}

Future<BattleBallCaptureComponent> _captureComponent(
    BattleOverlayComponent overlay) async {
  for (var index = 0; index < 40; index++) {
    overlay.updateTree(0.05);
    await Future<void>.delayed(Duration.zero);
    final balls = overlay.children.whereType<BattleBallCaptureComponent>();
    if (balls.isNotEmpty) return balls.single;
  }
  fail('The capture sprite was not mounted');
}

Future<void> _finishTurn(BattleOverlayComponent overlay) async {
  for (var index = 0;
      index < 200 && overlay.isTurnPresentationActive;
      index++) {
    overlay.updateTree(0.1);
    await Future<void>.delayed(Duration.zero);
  }
  expect(overlay.isTurnPresentationActive, isFalse);
  await overlay.waitForPendingVisualSync();
}

Future<int> _redPixel(ui.Image sheet) async {
  final bytes = await sheet.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes!.getUint8(0);
}

Future<File> _sheet(Directory project, String name, int red,
    {int height = 2048}) async {
  final pixels = image.Image(width: 64, height: height);
  pixels.setPixelRgba(0, 0, red, 1, 2, 255);
  return File(p.join(project.path, name)).writeAsBytes(image.encodePng(pixels));
}

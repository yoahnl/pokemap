import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/runtime_input_event.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_overlay_component.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';
import 'package:map_runtime/src/spatial/spatial_battle_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_battle_view.dart';
import 'package:path/path.dart' as p;

import 'support/load_flame_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'battle entry renders its authored curtain over the overworld before commands',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    var commits = 0;
    final runtime = SpatialBattleRuntime(
      readGameState: () => fixture.state,
      commitGameState: (_, __) {
        commits++;
        return true;
      },
    );
    addTearDown(runtime.dispose);
    late Future<bool> completion;
    await tester.runAsync(() async {
      completion = runtime.start(
        bundle: fixture.bundle.copyWith(
          manifest: fixture.bundle.manifest.copyWith(
            battleTransitions: const ProjectBattleTransitionConfig(
              wildTransitionId: 'rby_wild',
              trainerTransitionId: 'dpp_trainer',
            ),
          ),
        ),
        request: _wild('entry-curtain'),
      );
      await _ready(runtime);
    });
    await tester.pumpWidget(MaterialApp(
      home: SpatialBattleView(runtime: runtime),
    ));
    await _mountBattleView(tester, runtime, advanceTime: false);
    final game = tester
        .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget))
        .game! as SpatialBattlePresentation;
    final curtains = game.camera.viewport.children
        .whereType<BattleTransitionOverlayComponent>()
        .toList();
    expect(curtains, hasLength(1));
    final curtain = curtains.single;
    expect(curtain.spec.id, 'rby_wild+grass');
    expect(runtime.phase, SpatialBattlePhase.loading);
    expect(runtime.battlePresentationListenable.value, isNull);
    const worldColor = ui.Color(0xFF20A060);
    expect(await tester.runAsync(() => _viewportPixel(game, worldColor)),
        worldColor);
    curtain.update(0.2);
    expect(await tester.runAsync(() => _viewportPixel(game, worldColor)),
        isNot(worldColor));
    runtime.pause();
    curtain.debugHoldBlackNowForTest();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(curtain.isHoldingBlack, true);
    expect(await tester.runAsync(() => _viewportPixel(game, worldColor)),
        const ui.Color(0xFF000000));
    expect(runtime.battlePresentationListenable.value, isNull);
    expect(
        runtime.handleInput(
            const RuntimeInputEvent.press(RuntimeInputControl.primary)),
        true);
    expect(await runtime.submitChoice(const PlayerBattleChoiceRun()), false);
    expect(commits, 0);
    runtime.resume();
    await _finishBattleEntry(tester, runtime);
    expect(runtime.phase, SpatialBattlePhase.battle);
    expect(
        runtime.battlePresentationListenable.value!.interactionsEnabled, true);
    expect(
        game.camera.viewport.children
            .whereType<BattleTransitionOverlayComponent>(),
        isEmpty);
    expect(await tester.runAsync(() => _viewportPixel(game, worldColor)),
        isNot(worldColor));
    runtime.cancel();
    expect(await tester.runAsync(() => completion), false);
    expect(commits, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'entry curtain covers the real portrait viewport and stays centered after rotation',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    final runtime = SpatialBattleRuntime(
      readGameState: () => fixture.state,
      commitGameState: (_, __) => true,
    );
    addTearDown(runtime.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(393, 852));
    late Future<bool> completion;
    await tester.runAsync(() async {
      completion = runtime.start(
        bundle: fixture.bundle,
        request: _wild('portrait-entry'),
      );
      await _ready(runtime);
    });
    await tester
        .pumpWidget(MaterialApp(home: SpatialBattleView(runtime: runtime)));
    await _mountBattleView(tester, runtime, advanceTime: false);
    final game = tester
        .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget))
        .game! as SpatialBattlePresentation;
    final curtain = runtime.entryTransition!;
    runtime.pause();
    curtain.debugHoldBlackNowForTest();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (final viewportSize in [const Size(393, 852), const Size(852, 393)]) {
      await tester.binding.setSurfaceSize(viewportSize);
      await tester.pump();
      expect(game.camera.viewport.size,
          Vector2(viewportSize.width, viewportSize.height));
      expect(curtain.size, game.camera.viewport.size);
      expect(runtime.entryTransition, same(curtain));
      expect(curtain.size.x / 2, viewportSize.width / 2);
      expect(curtain.size.y / 2, viewportSize.height / 2);
      expect(curtain.isHoldingBlack, true);
      expect(runtime.phase, SpatialBattlePhase.loading);
      expect(runtime.battlePresentationListenable.value, isNull);
      expect(
        await tester.runAsync(() => _viewportCornersAndCenter(game)),
        everyElement(const ui.Color(0xFF000000)),
      );
    }
    runtime.cancel();
    expect(await tester.runAsync(() => completion), false);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'entry curtain follows a resize while its assets are still loading',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    final runtime = SpatialBattleRuntime(
      readGameState: () => fixture.state,
      commitGameState: (_, __) => true,
    );
    addTearDown(runtime.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(393, 852));
    late Future<bool> completion;
    await tester.runAsync(() async {
      completion = runtime.start(
        bundle: fixture.bundle,
        request: _wild('loading-resize-entry'),
      );
      await _ready(runtime);
    });
    final sheetReady = Completer<ui.Image?>();
    final curtain = runtime.entryTransition = BattleTransitionOverlayComponent(
      spec: runtime.entryTransition!.spec,
      viewportSize: Vector2(640, 480),
      onBlackHeld: () {},
      loadSheet: (_) => sheetReady.future,
    );
    await tester
        .pumpWidget(MaterialApp(home: SpatialBattleView(runtime: runtime)));
    for (var i = 0; i < 100 && !curtain.isLoading; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)));
    }
    expect(curtain.isLoading, true);
    expect(curtain.isMounted, false);
    expect(curtain.size, Vector2(393, 852));
    await tester.binding.setSurfaceSize(const Size(852, 393));
    await tester.pump();
    expect(curtain.isMounted, false);
    expect(curtain.size, Vector2(852, 393));
    sheetReady.complete(null);
    for (var i = 0; i < 100 && !curtain.isMounted; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)));
    }
    expect(curtain.isMounted, true);
    expect(curtain.size, Vector2(852, 393));
    runtime.cancel();
    expect(await tester.runAsync(() => completion), false);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('a lifecycle pause cannot resume a battle still held by its menu owner',
      () {
    final runtime = SpatialBattleRuntime(
        readGameState: () => const GameState(saveId: 'pause'),
        commitGameState: (_, __) => true);
    addTearDown(runtime.dispose);
    final lifecycle = Object();
    runtime.pause();
    runtime.pause(owner: lifecycle);
    runtime.resume(owner: lifecycle);
    expect(runtime.isPaused, true);
    runtime.resume();
    expect(runtime.isPaused, false);
  });
  test('spatial entry resolves the authored wild and trainer configurations',
      () async {
    final fixture = await _fixture();
    final runtime = SpatialBattleRuntime(
      readGameState: () => fixture.state,
      commitGameState: (_, __) => true,
    );
    addTearDown(runtime.dispose);
    final bundle = fixture.bundle.copyWith(
      manifest: fixture.bundle.manifest.copyWith(
        battleTransitions: const ProjectBattleTransitionConfig(
          wildTransitionId: 'dpp_trainer',
          trainerTransitionId: 'rby_wild',
        ),
      ),
    );
    final wild = _wild('configured-wild');
    final first = runtime.start(bundle: bundle, request: wild);
    expect(runtime.entryTransition!.spec.id, 'dpp_trainer+grass');
    runtime.cancel();
    expect(await first, false);
    final trainer = TrainerBattleStartRequest(
      requestId: 'configured-trainer',
      createdAtEpochMs: 1,
      returnContext: wild.returnContext,
      trainerId: 'authored-trainer',
      npcEntityId: 'trainer-npc',
      mapId: wild.mapId,
      playerPos: wild.playerPos,
    );
    final second = runtime.start(bundle: bundle, request: trainer);
    expect(runtime.entryTransition!.spec.id, 'rby_wild');
    runtime.cancel();
    expect(await second, false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(runtime.entryTransition, isNull);
    expect(runtime.battleOverlay, isNull);
    expect(runtime.battlePresentationListenable.value, isNull);
  });
  testWidgets(
      'black held before preparation waits for the mounted battle intro',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    var commits = 0;
    final runtime = SpatialBattleRuntime(
      readGameState: () => fixture.state,
      commitGameState: (_, __) {
        commits++;
        return true;
      },
    );
    addTearDown(runtime.dispose);
    late Future<bool> completion;
    await tester.runAsync(() async {
      completion = runtime.start(
        bundle: fixture.bundle,
        request: _wild('black-before-setup'),
      );
      runtime.entryTransition!.debugHoldBlackNowForTest();
      expect(runtime.displaySession, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(runtime.phase, SpatialBattlePhase.loading);
      expect(runtime.entryTransition!.isHoldingBlack, true);
      expect(runtime.battlePresentationListenable.value, isNull);
      expect(await runtime.submitChoice(const PlayerBattleChoiceRun()), false);
      await _ready(runtime);
    });
    await tester
        .pumpWidget(MaterialApp(home: SpatialBattleView(runtime: runtime)));
    await _mountBattleView(tester, runtime, advanceTime: false);
    final game = tester
        .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget))
        .game! as SpatialBattlePresentation;
    expect(runtime.phase, SpatialBattlePhase.loading);
    expect(runtime.battlePresentationListenable.value, isNull);
    expect(
        await tester
            .runAsync(() => _viewportPixel(game, const ui.Color(0xFF20A060))),
        const ui.Color(0xFF000000));
    await _finishBattleEntry(tester, runtime);
    expect(runtime.phase, SpatialBattlePhase.battle);
    expect(
        runtime.battlePresentationListenable.value!.interactionsEnabled, true);
    expect(commits, 0);
    runtime.cancel();
    expect(await tester.runAsync(() => completion), false);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final fail in [false, true]) {
    testWidgets(
        'a ${fail ? 'failed' : 'cancelled'} black-held entry clears its presentation and permits restart',
        (tester) async {
      final fixture = (await tester.runAsync(_fixture))!;
      var commits = 0;
      final runtime = SpatialBattleRuntime(
        readGameState: () => fixture.state,
        commitGameState: (_, __) {
          commits++;
          return true;
        },
      );
      addTearDown(runtime.dispose);
      late Future<bool> first;
      await tester.runAsync(() async {
        first = runtime.start(bundle: fixture.bundle, request: _wild('held'));
        await _ready(runtime);
      });
      await tester.pumpWidget(MaterialApp(
        home: SpatialBattleView(runtime: runtime),
      ));
      await _mountBattleView(tester, runtime, advanceTime: false);
      final oldCurtain = runtime.entryTransition!;
      runtime.pause();
      oldCurtain.debugHoldBlackNowForTest();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(oldCurtain.isHoldingBlack, true);
      if (fail) {
        runtime.reportPresentationFailure(StateError('entry asset failure'));
        expect(runtime.error, isA<StateError>());
      } else {
        runtime.cancel();
      }
      expect(await tester.runAsync(() => first), false);
      await tester.pump();
      expect(oldCurtain.isMounted, false);
      expect(runtime.entryTransition, isNull);
      expect(runtime.battlePresentationListenable.value, isNull);
      expect(commits, 0);
      runtime.resume();
      late Future<bool> second;
      await tester.runAsync(() async {
        second =
            runtime.start(bundle: fixture.bundle, request: _wild('restart'));
        await _ready(runtime);
      });
      await _mountBattleView(tester, runtime, advanceTime: false);
      final nextCurtain = runtime.entryTransition;
      oldCurtain.onBlackHeld();
      oldCurtain.onDismissed?.call();
      expect(runtime.entryTransition, same(nextCurtain));
      expect(runtime.phase, SpatialBattlePhase.loading);
      expect(runtime.battlePresentationListenable.value, isNull);
      await _finishBattleEntry(tester, runtime);
      expect(runtime.battlePresentationListenable.value!.interactionsEnabled,
          true);
      expect(commits, 0);
      runtime.cancel();
      expect(await tester.runAsync(() => second), false);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
      'wild handoff stays pending until presentation and commits flee once at the spatial position',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    var state = fixture.state;
    var commits = 0;
    final runtime = SpatialBattleRuntime(
        readGameState: () => state,
        commitGameState: (expected, next) {
          if (state != expected) return false;
          state = next;
          commits++;
          return true;
        });
    addTearDown(runtime.dispose);
    var completed = false;
    final battle = runtime
        .start(bundle: fixture.bundle, request: _wild('flee'))
        .then((result) {
      completed = true;
      return result;
    });
    await _readyInView(tester, runtime);
    expect(completed, false);
    expect(runtime.context!.request, isA<WildBattleStartRequest>());
    runtime.pause();
    expect(
        await _submit(tester, runtime, const PlayerBattleChoiceRun()), false);
    expect(commits, 0);
    runtime.resume();
    for (var i = 0; i < 10 && runtime.postBattleOverlay == null; i++) {
      await _submit(tester, runtime, const PlayerBattleChoiceRun());
    }
    expect(runtime.postBattleOverlay, isNotNull);
    expect(commits, 0);
    await _acknowledge(tester, runtime);
    expect(await battle, true);
    expect(commits, 1);
    expect(state.playerSpatialPosition, fixture.state.playerSpatialPosition);
    expect(state.completedBattleRequestIds, contains('flee'));
    expect(runtime.isActive, false);
  });
  test('cancelling a real asynchronous setup never publishes a late state',
      () async {
    final fixture = await _fixture();
    var commits = 0;
    final runtime = SpatialBattleRuntime(
        readGameState: () => fixture.state,
        commitGameState: (_, __) {
          commits++;
          return true;
        });
    final battle =
        runtime.start(bundle: fixture.bundle, request: _wild('cancel'));
    runtime.cancel();
    expect(await battle, false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(commits, 0);
    expect(runtime.isActive, false);
    runtime.dispose();
  });
  test('loading battle scene consumes player input until mounted', () async {
    final fixture = await _fixture();
    final runtime = SpatialBattleRuntime(
      readGameState: () => fixture.state,
      commitGameState: (expected, next) => true,
    );
    addTearDown(runtime.dispose);
    final completion = runtime.start(
      bundle: fixture.bundle,
      request: _wild('not-mounted'),
    );
    await _ready(runtime);
    await loadFlameComponent(runtime.battleOverlay!);
    expect(runtime.battleOverlay!.isMounted, false);
    final displaySession = runtime.displaySession;
    expect(runtime.battlePresentationListenable.value, isNull);
    expect(
      runtime.dispatchBattlePresentationCommand(const BattleSelectEntryCommand(
        snapshotRevision: 0,
        expectedMode: BattleCommandOverlayMode.root,
        entryIndex: 0,
      )),
      false,
    );
    expect(
        runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        true);
    expect(
        runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        true);
    expect(runtime.battlePresentationListenable.value, isNull);
    expect(runtime.displaySession, same(displaySession));
    runtime.cancel();
    expect(await completion, false);
  });
  testWidgets(
      'a restarted spatial battle rejects commands from the previous battle',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    final runtime = SpatialBattleRuntime(
      readGameState: () => fixture.state,
      commitGameState: (expected, next) => true,
    );
    addTearDown(runtime.dispose);
    late Future<bool> first;
    await tester.runAsync(() async {
      first = runtime.start(
          bundle: fixture.bundle, request: _wild('old-presentation'));
      await _ready(runtime);
    });
    await tester
        .pumpWidget(MaterialApp(home: SpatialBattleView(runtime: runtime)));
    await _mountBattleView(tester, runtime);
    await _finishBattleEntry(tester, runtime);
    final old = runtime.battlePresentationListenable.value!;
    runtime.cancel();
    expect(await tester.runAsync(() => first), false);
    late Future<bool> second;
    await tester.runAsync(() async {
      second = runtime.start(
          bundle: fixture.bundle, request: _wild('new-presentation'));
      await _ready(runtime);
    });
    await _mountBattleView(tester, runtime);
    await _finishBattleEntry(tester, runtime);
    final current = runtime.battlePresentationListenable.value!;
    expect(current.mode, old.mode);
    expect(
      runtime.dispatchBattlePresentationCommand(BattleSelectEntryCommand(
        snapshotRevision: old.revision,
        expectedMode: old.mode,
        entryIndex: 0,
      )),
      false,
    );
    expect(current.revision, greaterThan(old.revision));
    expect(
      runtime.dispatchBattlePresentationCommand(BattleSelectEntryCommand(
        snapshotRevision: current.revision,
        expectedMode: current.mode,
        entryIndex: 0,
      )),
      true,
    );
    runtime.cancel();
    expect(await tester.runAsync(() => second), false);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'chained battle started during build clears the previous Flutter snapshot before its curtain',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    final runtime = SpatialBattleRuntime(
      readGameState: () => fixture.state,
      commitGameState: (_, __) => true,
    );
    addTearDown(runtime.dispose);
    final restart = ValueNotifier(false);
    addTearDown(restart.dispose);
    late Future<bool> first;
    Future<bool>? second;
    await tester.runAsync(() async {
      first =
          runtime.start(bundle: fixture.bundle, request: _wild('first-frame'));
      await _ready(runtime);
    });
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: restart,
        builder: (context, shouldRestart, child) {
          if (shouldRestart && second == null) {
            runtime.cancel();
            second = runtime.start(
              bundle: fixture.bundle,
              request: _wild('second-frame'),
            );
          }
          return SpatialBattleView(runtime: runtime);
        },
      ),
    ));
    await _mountBattleView(tester, runtime);
    await _finishBattleEntry(tester, runtime);
    expect(runtime.battlePresentationListenable.value, isNotNull);
    restart.value = true;
    await tester.pump();
    expect(runtime.phase, SpatialBattlePhase.loading);
    expect(runtime.entryTransition, isNotNull);
    expect(runtime.battlePresentationListenable.value, isNull);
    expect(await tester.runAsync(() => first), false);
    runtime.cancel();
    expect(await tester.runAsync(() => second!), false);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'completion awaits the narrative callback with terminal engine context',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    var state = fixture.state;
    var commits = 0;
    final entered = Completer<void>();
    final released = Completer<void>();
    late SpatialBattleRuntime runtime;
    runtime = SpatialBattleRuntime(
        readGameState: () => state,
        commitGameState: (expected, next) {
          if (state != expected) return false;
          state = next;
          commits++;
          return true;
        },
        onCompleted: (outcome) async {
          expectSync(outcome.isRunaway, true);
          expectSync(runtime.engineState!.isFinished, true);
          expectSync(runtime.context!.request.requestId, 'async-publication');
          expectSync(
              state.completedBattleRequestIds, contains('async-publication'));
          entered.complete();
          await released.future;
        });
    addTearDown(runtime.dispose);
    var completed = false;
    final battle = runtime
        .start(bundle: fixture.bundle, request: _wild('async-publication'))
        .then((result) {
      completed = true;
      return result;
    });
    await _readyInView(tester, runtime);
    for (var i = 0; i < 10 && runtime.postBattleOverlay == null; i++) {
      await _submit(tester, runtime, const PlayerBattleChoiceRun());
    }
    for (var i = 0; i < 2000 && !entered.isCompleted; i++) {
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary));
      await _pumpPresentation(tester);
    }
    expect(entered.isCompleted, true,
        reason:
            '${runtime.phase} / ${runtime.error} / ${runtime.battlePresentationListenable.value?.prompt}');
    expect(completed, false);
    expect(runtime.isActive, true);
    expect(commits, 1);
    released.complete();
    await _acknowledge(tester, runtime);
    expect(await battle, true);
    expect(runtime.engineState, null);
  });
  testWidgets(
      'pausing then cancelling a captured battle discards its private writes',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    final state = fixture.state.copyWith(
        bag: Bag(entries: const [BagEntry(itemId: 'poke-ball', quantity: 50)]));
    var commits = 0;
    final runtime = SpatialBattleRuntime(
        readGameState: () => state,
        commitGameState: (_, __) {
          commits++;
          return true;
        });
    addTearDown(runtime.dispose);
    final battle = runtime.start(
        bundle: fixture.bundle, request: _wild('cancel-after-capture'));
    await _readyInView(tester, runtime);
    for (var i = 0; i < 30 && runtime.postBattleOverlay == null; i++) {
      await _submit(tester, runtime,
          const PlayerBattleChoiceCapture(itemId: 'poke-ball'));
    }
    expect(runtime.displaySession!.state.outcome!.isCaptured, true);
    runtime.pause();
    for (var i = 0; i < 10; i++) {
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary));
    }
    expect(commits, 0);
    runtime.cancel();
    runtime.resume();
    expect(await battle, false);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(commits, 0);
    expect(state.bag.entries.single.quantity, 50);
    expect(state.completedBattleRequestIds,
        isNot(contains('cancel-after-capture')));
  });
  testWidgets(
      'capture charges each accepted ball once and persists the hydrated individual after acknowledgement',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    var state = fixture.state.copyWith(
        bag: Bag(entries: const [BagEntry(itemId: 'poke-ball', quantity: 50)]));
    final original = state;
    var commits = 0;
    final runtime = SpatialBattleRuntime(
        readGameState: () => state,
        commitGameState: (expected, next) {
          if (state != expected) return false;
          state = next;
          commits++;
          return true;
        });
    addTearDown(runtime.dispose);
    final battle =
        runtime.start(bundle: fixture.bundle, request: _wild('capture'));
    await _readyInView(tester, runtime);
    var attempts = 0;
    while (runtime.postBattleOverlay == null && attempts < 30) {
      expect(
          await _submit(tester, runtime,
              const PlayerBattleChoiceCapture(itemId: 'poke-ball')),
          true,
          reason:
              '${runtime.error} / ${runtime.displaySession?.decisionRequest}');
      attempts++;
    }
    expect(runtime.displaySession!.state.outcome!.isCaptured, true);
    expect(state, original);
    await _acknowledge(tester, runtime);
    expect(await battle, true);
    expect(commits, 1);
    expect(state.bag.entries.single.quantity, 50 - attempts);
    expect(state.party.members.length, original.party.members.length + 1);
    expect(state.party.members.last.individualId, isNotEmpty);
    expect(state.party.members.last.currentPpByMoveId, isNotEmpty);
    expect(state.playerSpatialPosition, original.playerSpatialPosition);
  });
  testWidgets(
      'victory persists HP PP XP level and real move replacement and evolution decisions',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    final curve = PokemonExperienceCurve.fromId('medium_slow');
    final hero = fixture.state.party.members.first.copyWith(
        level: 4,
        experience: curve.totalExperienceForLevel(5) - 1,
        knownMoveIds: [
          'tackle',
          'growl',
          'scratch',
          'leer'
        ],
        currentPpByMoveId: {
          'tackle': 35,
          'growl': 40,
          'scratch': 35,
          'leer': 40
        });
    var state = fixture.state
        .copyWith(party: fixture.state.party.copyWith(members: [hero]));
    final movesFile = File(p.join(fixture.bundle.projectRootDirectory,
        fixture.bundle.manifest.pokemon.catalogFiles['moves']!));
    final moves = jsonDecode((await tester.runAsync(movesFile.readAsString))!)
        as Map<String, dynamic>;
    moves['entries'].add({
      ...moves['entries'][0] as Map<String, dynamic>,
      'id': 'scratch',
      'name': 'Scratch'
    });
    moves['entries'].add({
      ...moves['entries'][1] as Map<String, dynamic>,
      'id': 'leer',
      'name': 'Leer'
    });
    await tester.runAsync(() => movesFile.writeAsString(jsonEncode(moves)));
    await tester.runAsync(() => File(p.join(fixture.bundle.projectRootDirectory,
                fixture.bundle.manifest.pokemon.evolutionsDir, 'sproutle.json'))
            .writeAsString(jsonEncode({
          'schemaVersion': 1,
          'speciesId': 'sproutle',
          'evolutions': [
            {
              'method': 'level_up',
              'targetSpeciesId': 'sparkitten',
              'minLevel': 5
            }
          ]
        })));
    final original = state;
    final runtime = SpatialBattleRuntime(
        readGameState: () => state,
        commitGameState: (expected, next) {
          if (state != expected) return false;
          state = next;
          return true;
        });
    addTearDown(runtime.dispose);
    final battle =
        runtime.start(bundle: fixture.bundle, request: _wild('victory'));
    await _readyInView(tester, runtime);
    await _fight(tester, runtime);
    expect(runtime.displaySession!.state.outcome!.isVictory, true);
    expect(state, original);
    expect(runtime.postBattleOverlay!.currentTransaction!.pendingMoveLearning,
        isNotNull);
    await _acknowledge(tester, runtime, replaceIndex: 1);
    expect(await battle, true);
    expect(state.party.members.first.experience, greaterThan(hero.experience!));
    expect(state.party.members.first.level, greaterThan(hero.level));
    expect(state.party.members.first.knownMoveIds, contains('vine_whip'));
    expect(state.party.members.first.speciesId, 'sparkitten');
    expect(state.playerSpatialPosition, original.playerSpatialPosition);
    expect(state.party.members.first.currentHp, greaterThan(0));
    expect(
        state.party.members.first.currentPpByMoveId!['tackle'], lessThan(35));
    expect(state.party.members.first.currentPpByMoveId!['vine_whip'], 25);
  });
  testWidgets(
      'defeat uses the real pure recovery and preserves completed battle identity',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    var state = fixture.state.copyWith(
        party: fixture.state.party.copyWith(members: [
          fixture.state.party.members.first.copyWith(currentHp: 1)
        ]),
        trainerProfile: fixture.state.trainerProfile.copyWith(money: 100));
    state = recordPlayerRecoveryPoint(state);
    final runtime = SpatialBattleRuntime(
        readGameState: () => state,
        commitGameState: (expected, next) {
          if (state != expected) return false;
          state = next;
          return true;
        });
    addTearDown(runtime.dispose);
    final battle = runtime.start(
        bundle: fixture.bundle, request: _wild('defeat', level: 50));
    await _readyInView(tester, runtime);
    await _fight(tester, runtime);
    expect(runtime.displaySession!.state.outcome!.isDefeat, true);
    await _acknowledge(tester, runtime);
    expect(await battle, true);
    expect(state.party.members.first.currentHp, greaterThan(1));
    expect(state.party.members.first.currentPpByMoveId!['tackle'], 35);
    expect(state.trainerProfile.money, 90);
    expect(state.playerSpatialPosition, isNull);
    expect(state.completedBattleRequestIds, contains('defeat'));
  });
  testWidgets('a changed owner state rejects the whole post battle commit',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    var state = fixture.state;
    final runtime = SpatialBattleRuntime(
        readGameState: () => state,
        commitGameState: (expected, next) {
          if (state != expected) return false;
          state = next;
          return true;
        });
    addTearDown(runtime.dispose);
    final battle =
        runtime.start(bundle: fixture.bundle, request: _wild('conflict'));
    await _readyInView(tester, runtime);
    await _submit(tester, runtime, const PlayerBattleChoiceRun());
    state = state.copyWith(metadata: {'changed': 'save-load'});
    final concurrent = state;
    await _acknowledge(tester, runtime);
    expect(await battle, false);
    expect(state, concurrent);
    expect(runtime.error, isA<StateError>());
  });
  testWidgets(
      'battle scene mounts sprites and routes canonical commands with lifecycle pause',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    final runtime = SpatialBattleRuntime(
        readGameState: () => fixture.state, commitGameState: (_, __) => true);
    late Future<bool> battle;
    await tester.runAsync(() async {
      battle = runtime.start(bundle: fixture.bundle, request: _wild('host'));
      await _ready(runtime);
    });
    await tester.pumpWidget(MaterialApp(
        home: SizedBox.expand(
            child: Stack(children: [
      const Placeholder(key: Key('overworld')),
      SpatialBattleView(runtime: runtime)
    ]))));
    for (var i = 0; i < 100 && !runtime.battleOverlay!.isMounted; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)));
    }
    expect(runtime.battleOverlay!.isMounted, true);
    await _finishBattleEntry(tester, runtime);
    final game = tester
        .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget))
        .game! as SpatialBattlePresentation;
    expect(game.camera.viewport.children, contains(runtime.battleOverlay));
    expect(find.byKey(const Key('overworld')), findsOneWidget);
    final before = runtime.battlePresentationListenable.value!;
    await tester.pump(const Duration(milliseconds: 20));
    final current = runtime.battlePresentationListenable.value!;
    expect(
        runtime.dispatchBattlePresentationCommand(BattleSelectEntryCommand(
            snapshotRevision: current.revision,
            expectedMode: current.mode,
            entryIndex: 0)),
        true);
    await tester.pump(const Duration(milliseconds: 50));
    expect(
        runtime.battlePresentationListenable.value!.mode, isNot(before.mode));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(runtime.isPaused, true);
    expect(game.isPaused, true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(runtime.isPaused, false);
    expect(game.isPaused, false);
    runtime.pause();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(runtime.isPaused, true);
    expect(game.isPaused, true);
    runtime.resume();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(await tester.runAsync(() => battle), false);
    expect(runtime.isActive, false);
    expect(runtime.battlePresentationListenable.value, isNull);
    runtime.dispose();
  });
}

Future<void> _mountBattleView(WidgetTester tester, SpatialBattleRuntime runtime,
    {bool advanceTime = true}) async {
  for (var i = 0; i < 100 && !runtime.battleOverlay!.isMounted; i++) {
    await tester.pump(advanceTime ? const Duration(milliseconds: 20) : null);
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1)));
  }
  expect(runtime.battleOverlay!.isMounted, true);
}

Future<ui.Color> _viewportPixel(
    SpatialBattlePresentation game, ui.Color worldColor) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(worldColor, ui.BlendMode.src);
  game.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(800, 600);
  picture.dispose();
  final bytes = (await image.toByteData())!;
  image.dispose();
  final offset = (8 * 800 + 8) * 4;
  return ui.Color.fromARGB(bytes.getUint8(offset + 3), bytes.getUint8(offset),
      bytes.getUint8(offset + 1), bytes.getUint8(offset + 2));
}

Future<List<ui.Color>> _viewportCornersAndCenter(
    SpatialBattlePresentation game) async {
  final width = game.camera.viewport.size.x.round();
  final height = game.camera.viewport.size.y.round();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFF20A060), ui.BlendMode.src);
  game.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final bytes = (await image.toByteData())!;
  image.dispose();
  return [
    (x: 8, y: 8),
    (x: width - 9, y: 8),
    (x: 8, y: height - 9),
    (x: width - 9, y: height - 9),
    (x: width ~/ 2, y: height ~/ 2),
  ].map((point) {
    final offset = (point.y * width + point.x) * 4;
    return ui.Color.fromARGB(bytes.getUint8(offset + 3), bytes.getUint8(offset),
        bytes.getUint8(offset + 1), bytes.getUint8(offset + 2));
  }).toList();
}

Future<void> _finishBattleEntry(
    WidgetTester tester, SpatialBattleRuntime runtime) async {
  for (var i = 0;
      i < 500 &&
          runtime.battlePresentationListenable.value?.interactionsEnabled !=
              true;
      i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1)));
    if (runtime.battlePresentationListenable.value?.phase ==
        BattlePresentationPhase.presentingTurn) {
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary));
    }
  }
  expect(runtime.battlePresentationListenable.value?.interactionsEnabled, true,
      reason: '${runtime.error}');
}

Future<void> _fight(WidgetTester tester, SpatialBattleRuntime runtime) async {
  for (var i = 0; i < 50 && runtime.postBattleOverlay == null; i++) {
    final choices = runtime.displaySession!.decisionRequest.allowedChoices;
    final fight = choices.whereType<PlayerBattleChoiceFight>().firstOrNull;
    final replacement =
        choices.whereType<PlayerBattleChoiceSwitch>().firstOrNull;
    expect(
        await _submit(tester, runtime, fight ?? replacement ?? choices.first),
        true,
        reason: '${runtime.error}');
  }
  expect(runtime.postBattleOverlay, isNotNull, reason: '${runtime.error}');
}

Future<void> _ready(SpatialBattleRuntime runtime) async {
  for (var i = 0;
      i < 500 && runtime.displaySession == null && runtime.isActive;
      i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(runtime.displaySession, isNotNull, reason: '${runtime.error}');
}

Future<void> _readyInView(
    WidgetTester tester, SpatialBattleRuntime runtime) async {
  await tester
      .pumpWidget(MaterialApp(home: SpatialBattleView(runtime: runtime)));
  for (var i = 0;
      i < 2000 && runtime.battleOverlay == null && runtime.isActive;
      i++) {
    await _pumpPresentation(tester);
  }
  expect(runtime.battleOverlay, isNotNull, reason: '${runtime.error}');
  await _mountBattleView(tester, runtime);
  await _finishBattleEntry(tester, runtime);
}

Future<void> _pumpPresentation(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 20));
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1)));
}

Future<bool> _submit(WidgetTester tester, SpatialBattleRuntime runtime,
    PlayerBattleChoice choice) async {
  bool? result;
  final future = runtime.submitChoice(choice).then((accepted) {
    result = accepted;
    return accepted;
  });
  for (var i = 0; i < 2000 && result == null; i++) {
    await _pumpPresentation(tester);
    if (runtime.phase == SpatialBattlePhase.battle &&
        runtime.battleOverlay?.isTurnPresentationActive == true) {
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary));
    }
  }
  expect(result, isNotNull, reason: '${runtime.error}');
  return future;
}

Future<void> _acknowledge(WidgetTester tester, SpatialBattleRuntime runtime,
    {int replaceIndex = 0}) async {
  for (var i = 0; i < 2000 && runtime.isActive; i++) {
    final snapshot = runtime.battlePresentationListenable.value;
    if (snapshot?.mode == BattleCommandOverlayMode.decision) {
      runtime.battleOverlay!.selectRootEntry(
        snapshot!.entries.length > 2 ? replaceIndex : 0,
      );
    }
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await _pumpPresentation(tester);
  }
  expect(runtime.isActive, false, reason: '${runtime.error}');
}

WildBattleStartRequest _wild(String id, {int level = 2}) =>
    WildBattleStartRequest(
        requestId: id,
        createdAtEpochMs: 1,
        returnContext: const OverworldReturnContext(
            mapId: 'golden_field',
            playerPos: GridPos(x: 1, y: 1),
            playerFacing: Direction.east),
        mapId: 'golden_field',
        encounterSourceId: 'grass',
        encounterSourceKind: EncounterSourceKind.gameplayZone,
        tableId: 'wild',
        encounterKind: EncounterKind.walk,
        speciesId: 'sparkitten',
        level: level,
        minLevel: level,
        maxLevel: level,
        weight: 1,
        playerPos: const GridPos(x: 1, y: 1));

Future<({RuntimeMapBundle bundle, GameState state})> _fixture() async {
  final root = p.normalize(p.join(Directory.current.path, '..', '..',
      'examples', 'playable_runtime_host', 'golden_battle_slice'));
  final bundle = await loadRuntimeMapBundle(
      projectFilePath: p.join(root, 'project.json'), mapId: 'golden_field');
  final temporary =
      await Directory.systemTemp.createTemp('avelune-spatial-battle-');
  addTearDown(() => temporary.delete(recursive: true));
  for (final file
      in Directory(root).listSync(recursive: true).whereType<File>()) {
    final target =
        File(p.join(temporary.path, p.relative(file.path, from: root)));
    await target.parent.create(recursive: true);
    await file.copy(target.path);
  }
  const items = ProjectItemCatalog(schemaVersion: 1, entries: [
    ProjectItemDefinition(
        id: 'poke-ball',
        displayName: 'Poké Ball',
        pocketId: 'balls',
        capture: ProjectCaptureItemDefinition(
            rateNumerator: 255,
            rateDenominator: 1,
            allowedEncounterKinds: {EncounterKind.walk}))
  ]);
  await File(p.join(temporary.path, 'items.json'))
      .writeAsString(jsonEncode(items.toJson()));
  final evolutions =
      Directory(p.join(temporary.path, bundle.manifest.pokemon.evolutionsDir));
  await evolutions.create(recursive: true);
  for (final species in ['sproutle', 'sparkitten']) {
    await File(p.join(evolutions.path, '$species.json')).writeAsString(
        jsonEncode(
            {'schemaVersion': 1, 'speciesId': species, 'evolutions': []}));
  }
  final portable = bundle.copyWith(
      projectRootDirectory: temporary.path,
      map: MapData(
          version: ProjectVersion.v9,
          id: bundle.map.id,
          name: bundle.map.name,
          size: bundle.map.size,
          spatialScene: MapSpatialScene(
              width: bundle.map.size.width, depth: bundle.map.size.height)),
      manifest: bundle.manifest.copyWith(
          version: ProjectVersion.v9,
          settings: bundle.manifest.settings
              .copyWith(dimension: ProjectDimension.threeD),
          pokemon: bundle.manifest.pokemon.copyWith(catalogFiles: {
            ...bundle.manifest.pokemon.catalogFiles,
            'items': 'items.json'
          })));
  final save = SaveData.fromJson(jsonDecode(
      await File(p.join(root, 'runtime_host_launch_save.json'))
          .readAsString()) as Map<String, dynamic>);
  final state = gameStateFromSaveData(save)
      .copyWith(playerSpatialPosition: PlayerSpatialPosition(x: 1.25, z: 1.5));
  return (bundle: portable, state: state);
}

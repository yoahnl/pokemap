import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_post_battle_decision_coordinator.dart';
import 'package:map_runtime/src/presentation/flame/runtime_input_event.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_panel_component.dart';
import 'package:map_runtime/src/spatial/spatial_battle_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_battle_view.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
  test(
      'wild handoff stays pending until presentation and commits flee once at the spatial position',
      () async {
    final fixture = await _fixture();
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
    await _ready(runtime);
    expect(completed, false);
    expect(runtime.context!.request, isA<WildBattleStartRequest>());
    runtime.pause();
    expect(await runtime.submitChoice(const PlayerBattleChoiceRun()), false);
    expect(commits, 0);
    runtime.resume();
    for (var i = 0; i < 10 && runtime.postBattleOverlay == null; i++) {
      await runtime.submitChoice(const PlayerBattleChoiceRun());
    }
    expect(runtime.postBattleOverlay, isNotNull);
    expect(commits, 0);
    await _acknowledge(runtime);
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
  test('completion awaits the narrative callback with terminal engine context',
      () async {
    final fixture = await _fixture();
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
          expect(outcome.isRunaway, true);
          expect(runtime.engineState!.isFinished, true);
          expect(runtime.context!.request.requestId, 'async-publication');
          expect(
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
    await _ready(runtime);
    for (var i = 0; i < 10 && runtime.postBattleOverlay == null; i++) {
      await runtime.submitChoice(const PlayerBattleChoiceRun());
    }
    for (var i = 0; i < 100 && !entered.isCompleted; i++) {
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary));
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(entered.isCompleted, true);
    expect(completed, false);
    expect(runtime.isActive, true);
    expect(commits, 1);
    released.complete();
    expect(await battle, true);
    expect(runtime.engineState, null);
  });
  test('pausing then cancelling a captured battle discards its private writes',
      () async {
    final fixture = await _fixture();
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
    await _ready(runtime);
    for (var i = 0; i < 30 && runtime.postBattleOverlay == null; i++) {
      await runtime
          .submitChoice(const PlayerBattleChoiceCapture(itemId: 'poke-ball'));
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
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(commits, 0);
    expect(state.bag.entries.single.quantity, 50);
    expect(state.completedBattleRequestIds,
        isNot(contains('cancel-after-capture')));
  });
  test(
      'capture charges each accepted ball once and persists the hydrated individual after acknowledgement',
      () async {
    final fixture = await _fixture();
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
    await _ready(runtime);
    var attempts = 0;
    while (runtime.postBattleOverlay == null && attempts < 30) {
      expect(
          await runtime.submitChoice(
              const PlayerBattleChoiceCapture(itemId: 'poke-ball')),
          true,
          reason:
              '${runtime.error} / ${runtime.displaySession?.decisionRequest}');
      attempts++;
    }
    expect(runtime.displaySession!.state.outcome!.isCaptured, true);
    expect(state, original);
    await _acknowledge(runtime);
    expect(await battle, true);
    expect(commits, 1);
    expect(state.bag.entries.single.quantity, 50 - attempts);
    expect(state.party.members.length, original.party.members.length + 1);
    expect(state.party.members.last.individualId, isNotEmpty);
    expect(state.party.members.last.currentPpByMoveId, isNotEmpty);
    expect(state.playerSpatialPosition, original.playerSpatialPosition);
  });
  test(
      'victory persists HP PP XP level and real move replacement and evolution decisions',
      () async {
    final fixture = await _fixture();
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
    final moves =
        jsonDecode(await movesFile.readAsString()) as Map<String, dynamic>;
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
    await movesFile.writeAsString(jsonEncode(moves));
    await File(p.join(fixture.bundle.projectRootDirectory,
            fixture.bundle.manifest.pokemon.evolutionsDir, 'sproutle.json'))
        .writeAsString(jsonEncode({
      'schemaVersion': 1,
      'speciesId': 'sproutle',
      'evolutions': [
        {'method': 'level_up', 'targetSpeciesId': 'sparkitten', 'minLevel': 5}
      ]
    }));
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
    await _ready(runtime);
    await _fight(runtime);
    expect(runtime.displaySession!.state.outcome!.isVictory, true);
    expect(state, original);
    expect(runtime.postBattleOverlay!.currentTransaction!.pendingMoveLearning,
        isNotNull);
    await _acknowledge(runtime, replaceIndex: 1);
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
  test(
      'defeat uses the real pure recovery and preserves completed battle identity',
      () async {
    final fixture = await _fixture();
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
    await _ready(runtime);
    await _fight(runtime);
    expect(runtime.displaySession!.state.outcome!.isDefeat, true);
    await _acknowledge(runtime);
    expect(await battle, true);
    expect(state.party.members.first.currentHp, greaterThan(1));
    expect(state.party.members.first.currentPpByMoveId!['tackle'], 35);
    expect(state.trainerProfile.money, 90);
    expect(state.playerSpatialPosition, isNull);
    expect(state.completedBattleRequestIds, contains('defeat'));
  });
  test('a changed owner state rejects the whole post battle commit', () async {
    final fixture = await _fixture();
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
    await _ready(runtime);
    await runtime.submitChoice(const PlayerBattleChoiceRun());
    state = state.copyWith(metadata: {'changed': 'save-load'});
    final concurrent = state;
    await _acknowledge(runtime);
    expect(await battle, false);
    expect(state, concurrent);
    expect(runtime.error, isA<StateError>());
  });
  testWidgets(
      'battle host mounts the real overlay over the scene and accepts touch with lifecycle pause',
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
    final game = tester
        .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget))
        .game! as SpatialBattlePresentation;
    expect(game.camera.viewport.children, contains(runtime.battleOverlay));
    expect(find.byKey(const Key('overworld')), findsOneWidget);
    final before = runtime.battleOverlay!.currentMenuMode;
    await tester.pump(const Duration(milliseconds: 20));
    final panel = runtime.battleOverlay!.children
        .whereType<BattleCommandPanelComponent>()
        .single;
    final button = panel
        .descendants()
        .where((component) =>
            component is PositionComponent && component is TapCallbacks)
        .cast<PositionComponent>()
        .first;
    final target = button.absolutePosition + button.size / 2;
    await tester.tapAt(Offset(target.x, target.y));
    await tester.pump(const Duration(milliseconds: 50));
    expect(runtime.battleOverlay!.currentMenuMode, isNot(before));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(runtime.isPaused, true);
    expect(game.paused, true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(runtime.isPaused, false);
    expect(game.paused, false);
    runtime.pause();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(runtime.isPaused, true);
    expect(game.paused, true);
    runtime.resume();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(await tester.runAsync(() => battle), false);
    expect(runtime.isActive, false);
    runtime.dispose();
  });
}

Future<void> _fight(SpatialBattleRuntime runtime) async {
  for (var i = 0; i < 50 && runtime.postBattleOverlay == null; i++) {
    final choices = runtime.displaySession!.decisionRequest.allowedChoices;
    final fight = choices.whereType<PlayerBattleChoiceFight>().firstOrNull;
    final replacement =
        choices.whereType<PlayerBattleChoiceSwitch>().firstOrNull;
    expect(
        await runtime.submitChoice(fight ?? replacement ?? choices.first), true,
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

Future<void> _acknowledge(SpatialBattleRuntime runtime,
    {int replaceIndex = 0}) async {
  for (var i = 0; i < 100 && runtime.isActive; i++) {
    if (runtime.postBattleOverlay?.currentMessageKind ==
        RuntimePostBattleMessageKind.moveReplacementPrompt) {
      runtime.postBattleOverlay!.selectDecision(replaceIndex);
    }
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await Future<void>.delayed(const Duration(milliseconds: 1));
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

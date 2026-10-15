import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/player_service_runtime_controller.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart';
import 'package:map_runtime/src/player/runtime_world_service_models.dart';

GameState _state([int count = 1]) => GameState(
  saveId: 'healing-display',
  currentMapId: 'center',
  party: PlayerParty(
    members: [
      for (var i = 0; i < count; i++)
        PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          individualId: 'member-$i',
          currentHp: i == 0 ? 0 : 1,
          statusId: 'poison',
          knownMoveIds: const ['tackle'],
          currentPpByMoveId: const {'tackle': 1},
        ),
    ],
  ),
);

MapData _map() => MapData(
  id: 'center',
  name: 'Centre',
  size: const GridSize(width: 20, height: 20),
  entities: [
    MapEntity(
      id: 'healing-balls',
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 7, y: 4),
      blocksMovement: false,
      healingDisplay: MapEntityHealingDisplayData(
        variantElementIds: [for (var i = 1; i <= 6; i++) 'balls-$i'],
      ),
    ),
  ],
);

RuntimePlayerServiceRecoveryCaps _caps(GameState state) =>
    RuntimePlayerServiceRecoveryCaps(
      maxHpByPartyIndex: {
        for (var i = 0; i < state.party.members.length; i++) i: 20,
      },
      maxPpByPartyIndex: {
        for (var i = 0; i < state.party.members.length; i++) i: {'tackle': 35},
      },
    );

const _direct = OpenHealService(
  interactionId: 'source-nurse',
  requiresConfirmation: false,
  displayEntityId: 'healing-balls',
);
const _confirmed = OpenHealService(
  interactionId: 'authored-nurse',
  displayEntityId: 'healing-balls',
);

RuntimeHealServiceContent? _content(
  PlayerServiceRuntimeController controller,
) => controller.worldServiceSnapshot?.content as RuntimeHealServiceContent?;

void main() {
  for (final confirmed in [false, true]) {
    for (final fails in [false, true]) {
      test(
        'dispose waits for healing save confirmed=$confirmed failure=$fails',
        () async {
          var state = _state();
          final original = state;
          final saveStarted = Completer<void>();
          final releaseSave = Completer<void>();
          final locks = <bool>[];
          var commits = 0;
          final controller = PlayerServiceRuntimeController.contextual(
            currentGameState: () => state,
            healingDisplayMapReader: (_) => _map(),
            waitForHealingDisplay: (_) async {},
            commitAndSave: (next) async {
              saveStarted.complete();
              await releaseSave.future;
              if (fails) throw StateError('storage unavailable');
              state = next;
              commits++;
            },
            setInputLocked: locks.add,
            loadRecoveryCaps: (value) async => _caps(value),
          );
          final operation = controller.openHealCenter(
            request: confirmed ? _confirmed : _direct,
          );
          Future<RuntimeWorldServiceCommandResult>? confirmation;
          if (confirmed) {
            if (controller.worldServiceSnapshot == null) {
              await controller.worldServiceSnapshots.firstWhere(
                (snapshot) => snapshot != null,
              );
            }
            confirmation = controller.dispatchWorldService(
              RuntimeWorldServiceCommand(
                action: RuntimeWorldServiceAction.confirm,
                snapshotRevision: controller.worldServiceSnapshot!.revision,
              ),
            );
          }
          await saveStarted.future.timeout(const Duration(seconds: 5));
          var finished = false;
          var disposed = false;
          operation.then((_) => finished = true);
          final disposal = controller.dispose().then((_) => disposed = true);
          await Future<void>.delayed(Duration.zero);
          final finishedBeforeSave = finished;
          final disposedBeforeSave = disposed;
          final locksBeforeSave = List<bool>.of(locks);
          final stateBeforeSave = state;
          releaseSave.complete();
          await disposal;
          if (confirmation != null) await confirmation;
          final result = await operation;
          expect(finishedBeforeSave, isFalse);
          expect(disposedBeforeSave, isFalse);
          expect(locksBeforeSave, [true]);
          expect(stateBeforeSave, same(original));
          expect(controller.worldServiceSnapshot, isNull);
          expect(locks, [true, false]);
          expect(commits, fails ? 0 : 1);
          expect(
            result.status,
            fails
                ? PlayerServiceRuntimeStatus.failed
                : PlayerServiceRuntimeStatus.completed,
          );
          expect(state.party.members.single.currentHp, fails ? 0 : 20);
        },
      );
    }
  }

  for (var count = 1; count <= 6; count++) {
    test(
      'accepted native heal displays $count actual members including fainted members before durable commit',
      () async {
        final initial = _state(count);
        var state = initial;
        final wait = Completer<void>();
        final applying = Completer<void>();
        final committing = Completer<void>();
        final commitEntered = Completer<GameState>();
        final locks = <bool>[];
        final controller = PlayerServiceRuntimeController.contextual(
          currentGameState: () => state,
          healingDisplayMapReader: (_) => _map(),
          waitForHealingDisplay: (duration) {
            expect(duration, const Duration(milliseconds: 2900));
            applying.complete();
            return wait.future;
          },
          commitAndSave: (next) async {
            commitEntered.complete(next);
            await committing.future;
            state = next;
          },
          setInputLocked: locks.add,
          loadRecoveryCaps: (value) async => _caps(value),
        );
        final operation = controller.openHealCenter(request: _direct);
        await applying.future;
        expect(state, initial);
        expect(
          controller.worldServiceSnapshot!.stage,
          RuntimeWorldServiceStage.applying,
        );
        expect(controller.worldServiceSnapshot!.actions, isEmpty);
        final display = _content(controller)!.display!;
        expect(
          (display.mapId, display.entityId, display.memberCount),
          ('center', 'healing-balls', count),
        );
        expect(_content(controller)!.members.first.currentHp, 0);
        expect(_content(controller)!.wasHealed, isFalse);
        expect(locks, [true]);
        wait.complete();
        final recovered = await commitEntered.future;
        expect(state, initial);
        expect(_content(controller)!.display!.memberCount, count);
        expect(
          recovered.party.members.every(
            (member) =>
                member.currentHp == 20 &&
                member.statusId.isEmpty &&
                member.currentPpByMoveId!['tackle'] == 35,
          ),
          isTrue,
        );
        committing.complete();
        final result = await operation;
        expect(result.status, PlayerServiceRuntimeStatus.completed);
        expect(state, recovered);
        expect(controller.worldServiceSnapshot, isNull);
        expect(locks, [true, false]);
        await controller.dispose();
      },
    );
  }

  test(
    'No or cancel before confirmation never displays or heals members',
    () async {
      final initial = _state();
      var commits = 0;
      var waits = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => initial,
        healingDisplayMapReader: (_) => _map(),
        commitAndSave: (_) async {
          commits++;
        },
        setInputLocked: (_) {},
        waitForHealingDisplay: (_) async {
          waits++;
        },
        loadRecoveryCaps: (value) async => _caps(value),
      );
      final operation = controller.openHealCenter(request: _confirmed);
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.worldServiceSnapshot!.stage,
        RuntimeWorldServiceStage.active,
      );
      expect(_content(controller)!.display, isNull);
      final result = await controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.cancel,
          snapshotRevision: controller.worldServiceSnapshot!.revision,
        ),
      );
      expect(result.status, RuntimeWorldServiceCommandStatus.accepted);
      expect((await operation).status, PlayerServiceRuntimeStatus.cancelled);
      expect((commits, waits), (0, 0));
      expect(initial.party.members.single.currentHp, 0);
      expect(controller.worldServiceSnapshot, isNull);
      await controller.dispose();
    },
  );

  test('guided confirmation completes durable heal once and clears display before closing', () async {
    var state = _state(2);
    final initial = state;
    var commits = 0;
    var waits = 0;
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      healingDisplayMapReader: (_) => _map(),
      commitAndSave: (next) async {
        commits++;
        state = next;
      },
      setInputLocked: (_) {},
      waitForHealingDisplay: (_) async {
        waits++;
        expect(state, initial);
      },
      loadRecoveryCaps: (value) async => _caps(value),
    );
    final operation = controller.openHealCenter(request: _confirmed);
    await Future<void>.delayed(Duration.zero);
    final confirm = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
      ),
    );
    expect(confirm.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(
      controller.worldServiceSnapshot!.stage,
      RuntimeWorldServiceStage.completed,
    );
    expect(_content(controller)!.display, isNull);
    expect(_content(controller)!.wasHealed, isTrue);
    expect(
      _content(controller)!.members.every((member) => member.currentHp == 20),
      isTrue,
    );
    expect((commits, waits), (1, 1));
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: controller.worldServiceSnapshot!.revision,
      ),
    );
    expect((await operation).status, PlayerServiceRuntimeStatus.completed);
    expect(controller.worldServiceSnapshot, isNull);
    await controller.dispose();
  });

  test('presentation failure never reaches the save transaction', () async {
    final initial = _state(2);
    var commits = 0;
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => initial,
      healingDisplayMapReader: (_) => _map(),
      commitAndSave: (_) async {
        commits++;
      },
      setInputLocked: (_) {},
      waitForHealingDisplay: (_) async {
        throw StateError('presentation failed');
      },
      loadRecoveryCaps: (value) async => _caps(value),
    );
    expect(
      (await controller.openHealCenter(request: _direct)).status,
      PlayerServiceRuntimeStatus.failed,
    );
    expect(commits, 0);
    expect(controller.worldServiceSnapshot, isNull);
    await controller.dispose();
  });

  test(
    'save failure extinguishes display and never publishes healed party',
    () async {
      final initial = _state(3);
      var state = initial;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        healingDisplayMapReader: (_) => _map(),
        commitAndSave: (_) async {
          throw StateError('save rejected');
        },
        setInputLocked: (_) {},
        waitForHealingDisplay: (_) async {},
        loadRecoveryCaps: (value) async => _caps(value),
      );
      expect(
        (await controller.openHealCenter(request: _direct)).status,
        PlayerServiceRuntimeStatus.failed,
      );
      expect(state, initial);
      expect(controller.worldServiceSnapshot, isNull);
      await controller.dispose();
    },
  );

  test('dispose during applying interrupts presentation without a later commit or display resurrection', () async {
    final initial = _state(6);
    final wait = Completer<void>();
    final entered = Completer<void>();
    var commits = 0;
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => initial,
      healingDisplayMapReader: (_) => _map(),
      commitAndSave: (_) async {
        commits++;
      },
      setInputLocked: (_) {},
      waitForHealingDisplay: (_) {
        entered.complete();
        return wait.future;
      },
      loadRecoveryCaps: (value) async => _caps(value),
    );
    final operation = controller.openHealCenter(request: _direct);
    await entered.future;
    expect(_content(controller)!.display!.memberCount, 6);
    await controller.dispose();
    expect((await operation).status, PlayerServiceRuntimeStatus.cancelled);
    expect(commits, 0);
    expect(controller.worldServiceSnapshot, isNull);
    wait.complete();
    await Future<void>.delayed(Duration.zero);
    expect(controller.worldServiceSnapshot, isNull);
    expect(commits, 0);
  });

  test(
    'dispose during recovery-cap loading cannot start a heal afterwards',
    () async {
      final initial = _state();
      final caps = Completer<RuntimePlayerServiceRecoveryCaps>();
      var commits = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => initial,
        healingDisplayMapReader: (_) => _map(),
        commitAndSave: (_) async {
          commits++;
        },
        setInputLocked: (_) {},
        loadRecoveryCaps: (_) => caps.future,
      );
      final operation = controller.openHealCenter(request: _direct);
      await controller.dispose();
      caps.complete(_caps(initial));
      expect((await operation).status, PlayerServiceRuntimeStatus.cancelled);
      expect(controller.worldServiceSnapshot, isNull);
      expect(commits, 0);
    },
  );

  test(
    'a changed map or party during presentation cancels before commit',
    () async {
      var state = _state();
      final wait = Completer<void>();
      final entered = Completer<void>();
      var commits = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        healingDisplayMapReader: (_) => _map(),
        commitAndSave: (_) async {
          commits++;
        },
        setInputLocked: (_) {},
        waitForHealingDisplay: (_) {
          entered.complete();
          return wait.future;
        },
        loadRecoveryCaps: (value) async => _caps(value),
      );
      final operation = controller.openHealCenter(request: _direct);
      await entered.future;
      state = state.copyWith(currentMapId: 'outside');
      wait.complete();
      expect((await operation).status, PlayerServiceRuntimeStatus.cancelled);
      expect(commits, 0);
      expect(controller.worldServiceSnapshot, isNull);
      await controller.dispose();
    },
  );

  test(
    'a changed display anchor during applying cancels before commit',
    () async {
      final initial = _state();
      var map = _map();
      final wait = Completer<void>();
      final entered = Completer<void>();
      var commits = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => initial,
        healingDisplayMapReader: (_) => map,
        commitAndSave: (_) async {
          commits++;
        },
        setInputLocked: (_) {},
        waitForHealingDisplay: (_) {
          entered.complete();
          return wait.future;
        },
        loadRecoveryCaps: (value) async => _caps(value),
      );
      final operation = controller.openHealCenter(request: _direct);
      await entered.future;
      map = map.copyWith(
        entities: [
          map.entities.single.copyWith(pos: const GridPos(x: 8, y: 4)),
        ],
      );
      wait.complete();
      expect((await operation).status, PlayerServiceRuntimeStatus.cancelled);
      expect(commits, 0);
      expect(controller.worldServiceSnapshot, isNull);
      await controller.dispose();
    },
  );

  test('unknown display and missing native resolver are refused before presentation', () async {
    for (final reader in <PlayerServiceHealingDisplayMapReader?>[
      null,
      (_) => _map().copyWith(entities: []),
      (_) => _map().copyWith(id: 'wrong-map'),
    ]) {
      final initial = _state();
      var calls = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => initial,
        healingDisplayMapReader: reader,
        commitAndSave: (_) async {
          calls++;
        },
        setInputLocked: (_) {
          calls++;
        },
        waitForHealingDisplay: (_) async {
          calls++;
        },
        loadRecoveryCaps: (value) async => _caps(value),
      );
      expect(
        (await controller.openHealCenter(request: _direct)).status,
        PlayerServiceRuntimeStatus.unavailable,
      );
      expect(calls, 0);
      expect(controller.worldServiceSnapshot, isNull);
      await controller.dispose();
    }
  });

  test('empty party never produces a phantom ball', () async {
    var state = _state(0);
    var waits = 0;
    final displays = <RuntimeHealingDisplaySnapshot>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      healingDisplayMapReader: (_) => _map(),
      commitAndSave: (next) async {
        state = next;
      },
      setInputLocked: (_) {},
      waitForHealingDisplay: (_) async {
        waits++;
      },
      loadRecoveryCaps: (value) async => _caps(value),
    );
    final subscription = controller.worldServiceSnapshots.listen((snapshot) {
      final display =
          (snapshot?.content as RuntimeHealServiceContent?)?.display;
      if (display != null) displays.add(display);
    });
    await controller.openHealCenter(request: _direct);
    expect((waits, displays.length), (0, 0));
    await subscription.cancel();
    await controller.dispose();
  });

  test('Scene openHeal passes its exact display reference to the native world service', () async {
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      openWorldService: (request) async {
        expect(request, isA<OpenHealService>());
        final heal = request as OpenHealService;
        expect(heal.displayEntityId, 'healing-balls');
        expect(heal.requiresConfirmation, isFalse);
        return 'completed';
      },
    );
    final result = await executor.execute(
      SceneRuntimePlanIntent.executeInteractiveCommand(
        command: SceneInteractiveCommand.openHeal(
          requiresConfirmation: false,
          displayEntityId: 'healing-balls',
        ),
      ),
    );
    expect(result, 'completed');
  });
}

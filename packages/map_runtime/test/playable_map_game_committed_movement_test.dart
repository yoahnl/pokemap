import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Repousse ABA prompt: old Yes cannot renew an equal-valued new expiration',
    () async {
      final repository = _RepelSaveRepository();
      final game = _MovementGame(
        bundle: await _repelBundle(),
        saveRepository: repository,
        saveData: saveDataFromGameState(
          GameState(
            saveId: 'repel',
            currentMapId: 'route',
            repelState: RepelState.active(itemId: 'repel', steps: 1).advance(1),
            bag: const Bag(entries: [BagEntry(itemId: 'repel', quantity: 2)]),
          ),
        ),
      );
      await _load(game);
      game.setDialogueTextSpeed(RuntimeDialogueTextSpeed.instant);
      await _pumpUntil(
        game,
        () => game.dialoguePresentationListenable.value != null,
      );
      await _repelChoices(game);
      final expected = game.gameStateSnapshot;
      final replacement = GameState.fromJson(expected.toJson());
      expect(replacement, expected);
      expect(identical(replacement.repelState, expected.repelState), isFalse);
      final replacementCommit = game.commitAndSavePlayerServiceState(
        replacement,
        expectedState: expected,
      );
      final snapshot = game.dialoguePresentationListenable.value!;
      expect(
        game.dispatchDialoguePresentationCommand(
          DialogueSelectChoiceCommand(
            snapshotRevision: snapshot.revision,
            choiceIndex: 0,
          ),
        ),
        isTrue,
      );
      await replacementCommit;
      await _pumpUntil(
        game,
        () =>
            game.dialoguePresentationListenable.value == null &&
            game.inputAuthoritySnapshot.acceptsOverworldInput,
      );
      expect(game.gameStateSnapshot.repelState.remainingSteps, 0);
      expect(game.gameStateSnapshot.bag.entries.single.quantity, 2);
      expect(
        identical(game.gameStateSnapshot.repelState, replacement.repelState),
        isTrue,
      );
      expect(repository.saved!.repelState.remainingSteps, 0);
      expect(repository.saved!.bag.entries.single.quantity, 2);
      expect(repository.attempts, 1);
      expect(
        game.runtimeNotificationListenable.value?.text,
        isNot(contains('de nouveau active')),
      );
    },
  );

  test('Repousse ABA: an equal-valued replacement invalidates an old renewal confirmation', () async {
    final repository = _RepelSaveRepository();
    final game = _MovementGame(
      bundle: _bundle(),
      saveRepository: repository,
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'repel',
          currentMapId: 'route',
          repelState: RepelState.active(itemId: 'repel', steps: 1).advance(1),
          bag: const Bag(entries: [BagEntry(itemId: 'repel', quantity: 2)]),
        ),
      ),
    );
    await _load(game);
    expect(await game.saveGame(), isTrue);
    final expected = game.gameStateSnapshot;
    final replacement = GameState.fromJson(expected.toJson());
    await game.commitAndSavePlayerServiceState(replacement);
    expect(game.gameStateSnapshot, expected);
    expect(
      identical(game.gameStateSnapshot.repelState, expected.repelState),
      isFalse,
    );
    final renewed = expected.copyWith(
      repelState: RepelState.active(itemId: 'repel', steps: 7),
      bag: const Bag(entries: [BagEntry(itemId: 'repel', quantity: 1)]),
    );
    await expectLater(
      game.commitAndSavePlayerServiceState(renewed, expectedState: expected),
      throwsStateError,
    );
    expect(game.gameStateSnapshot.repelState.expirationPending, isTrue);
    expect(game.gameStateSnapshot.bag.entries.single.quantity, 2);
    expect(
      identical(game.gameStateSnapshot.repelState, replacement.repelState),
      isTrue,
    );
    expect(repository.saved!.repelState.remainingSteps, 0);
    expect(repository.saved!.bag.entries.single.quantity, 2);
    expect(repository.attempts, 2);
  });

  test('Repousse confirmation accepts a copied GameState retaining its expiration identity', () async {
    final repository = _RepelSaveRepository();
    final game = _MovementGame(
      bundle: _bundle(),
      saveRepository: repository,
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'repel',
          currentMapId: 'route',
          repelState: RepelState.active(itemId: 'repel', steps: 1).advance(1),
          bag: const Bag(entries: [BagEntry(itemId: 'repel', quantity: 2)]),
        ),
      ),
    );
    await _load(game);
    expect(await game.saveGame(), isTrue);
    final expected = game.gameStateSnapshot;
    final copied = expected.copyWith();
    expect(identical(copied, expected), isFalse);
    expect(identical(copied.repelState, expected.repelState), isTrue);
    await game.commitAndSavePlayerServiceState(copied);
    final renewed = expected.copyWith(
      repelState: RepelState.active(itemId: 'repel', steps: 7),
      bag: const Bag(entries: [BagEntry(itemId: 'repel', quantity: 1)]),
    );
    await game.commitAndSavePlayerServiceState(
      renewed,
      expectedState: expected,
    );
    expect(game.gameStateSnapshot.repelState.remainingSteps, 7);
    expect(game.gameStateSnapshot.bag.entries.single.quantity, 1);
    expect(repository.saved!.repelState.remainingSteps, 7);
    expect(repository.attempts, 3);
  });

  test('Repousse consumes committed movement only and expires once at safe control', () async {
    final game = _MovementGame(
      bundle: _bundle(),
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'repel',
          currentMapId: 'route',
          repelState: RepelState.active(itemId: 'repel', steps: 2),
        ),
      ),
    );
    await _load(game);
    await _move(game, RuntimeInputControl.left);
    expect(game.gameStateSnapshot.repelState.remainingSteps, 2);
    await _move(game, RuntimeInputControl.right);
    expect(game.gameStateSnapshot.repelState.remainingSteps, 1);
    for (var tick = 0; tick < 5; tick++) { game.update(.016); }
    expect(game.gameStateSnapshot.repelState.remainingSteps, 1);
    await _move(game, RuntimeInputControl.right);
    expect(game.gameStateSnapshot.repelState.remainingSteps, 0);
    await _pumpUntil(
      game,
      () => game.dialoguePresentationListenable.value != null,
    );
    expect(game.dialoguePresentationListenable.value, isNotNull);
    expect(game.gameStateSnapshot.repelState.expirationPending, isTrue);
  });

  test('Repousse protects its final step then permits the next lower-level candidate', () async {
    final bundle = _bundle();
    final game = _MovementGame(
      bundle: bundle.copyWith(
        manifest: bundle.manifest.copyWith(
          encounterTables: const [
            ProjectEncounterTable(
              id: 'grass',
              name: 'Grass',
              encounterKind: EncounterKind.walk,
              chancePerStep: 1,
              entries: [
                ProjectEncounterEntry(
                  speciesId: 'pikachu',
                  minLevel: 2,
                  maxLevel: 2,
                  weight: 1,
                ),
              ],
            ),
          ],
        ),
        map: bundle.map.copyWith(
          gameplayZones: const [
            MapGameplayZone(
              id: 'grass',
              name: 'Grass',
              kind: GameplayZoneKind.encounter,
              area: MapRect(
                pos: GridPos(x: 0, y: 0),
                size: GridSize(width: 8, height: 8),
              ),
              encounter: EncounterZonePayload(
                encounterTableId: 'grass',
                encounterKind: EncounterKind.walk,
              ),
            ),
          ],
        ),
      ),
      saveRepository: _RepelSaveRepository(),
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'repel',
          currentMapId: 'route',
          repelState: RepelState.active(itemId: 'repel', steps: 1),
          party: const PlayerParty(
            members: [
              PlayerPokemon(
                speciesId: 'pikachu',
                natureId: 'hardy',
                abilityId: 'static',
                level: 30,
                currentHp: 20,
              ),
            ],
          ),
        ),
      ),
    );
    await _load(game);
    game.setDialogueTextSpeed(RuntimeDialogueTextSpeed.instant);
    await _move(game, RuntimeInputControl.right);
    expect(game.debugPendingBattleRequest, isNull);
    expect(game.gameStateSnapshot.repelState.remainingSteps, 0);
    await _pumpUntil(
      game,
      () => game.dialoguePresentationListenable.value != null,
    );
    final snapshot = game.dialoguePresentationListenable.value!;
    game.dispatchDialoguePresentationCommand(
      DialogueAdvanceCommand(snapshotRevision: snapshot.revision),
    );
    await _pumpUntil(
      game,
      () =>
          game.dialoguePresentationListenable.value == null &&
          game.inputAuthoritySnapshot.acceptsOverworldInput,
    );
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    );
    game.update(.016);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    expect(game.debugPendingBattleRequest, isNotNull);
  });

  test('Repousse counts Surf and forced commits once and leaves idle frames untouched', () async {
    final game = _MovementGame(
      bundle: _bundle(),
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'repel',
          currentMapId: 'route',
          repelState: RepelState.active(itemId: 'repel', steps: 6),
        ),
      ),
    );
    await _load(game);
    game.debugSetPlayerStateForTest(
      position: const GridPos(x: 0, y: 0),
      facing: Direction.east,
      movementMode: MovementMode.surf,
    );
    expect(game.gameStateSnapshot.repelState.remainingSteps, 6);
    await _move(game, RuntimeInputControl.right);
    expect(game.gameStateSnapshot.repelState.remainingSteps, 5);
    bool? moved;
    final movement = game
        .movePlayerByForcedStep(
          direction: EntityFacing.east,
          expectedMapActivationId:
              game.overworldInteractionSnapshot.mapActivationId,
        )
        .then((value) => moved = value);
    await _pumpUntil(game, () => moved != null);
    await movement;
    expect(moved, isTrue);
    expect(game.gameStateSnapshot.repelState.remainingSteps, 4);
    for (var tick = 0; tick < 20; tick++) { game.update(.016); }
    expect(game.gameStateSnapshot.repelState.remainingSteps, 4);
  });

  test('Repousse expiration takes safe control before another held movement begins', () async {
    final game = _MovementGame(bundle: _bundle(), saveRepository: _RepelSaveRepository(),
      saveData: saveDataFromGameState(GameState(saveId: 'repel', currentMapId: 'route', repelState: RepelState.active(itemId: 'repel', steps: 1))));
    await _load(game);
    game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.right));
    await _pumpUntil(game, () => game.dialoguePresentationListenable.value != null || game.debugPlayerGridPosition.x > 1);
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
    expect(game.dialoguePresentationListenable.value, isNotNull);
    game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  test('pending Repousse expiration waits until a pause modal releases control' , () async {
    late final _MovementGame game;
    game = _MovementGame(bundle: _bundle(), saveRepository: _RepelSaveRepository(),
      saveData: saveDataFromGameState(GameState(saveId: 'repel', currentMapId: 'route', repelState: RepelState.active(itemId: 'repel', steps: 1))),
      onCommittedMovement: (_) => game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: true));
    await _load(game);
    await _move(game, RuntimeInputControl.right);
    expect(game.gameStateSnapshot.repelState.expirationPending, isTrue);
    for (var frame = 0; frame < 20; frame++) { game.update(.016); }
    expect(game.dialoguePresentationListenable.value, isNull);
    game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: false);
    await _pumpUntil(game, () => game.dialoguePresentationListenable.value != null);
  });

  test('an expired pending Repousse cold restores without activating or consuming again', () async {
    final game = _MovementGame(
      bundle: await _repelBundle(),
      saveRepository: _RepelSaveRepository(),
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'repel',
          currentMapId: 'route',
          repelState: RepelState.active(itemId: 'repel', steps: 1).advance(1),
          bag: const Bag(entries: [BagEntry(itemId: 'repel', quantity: 2)]),
        ),
      ),
    );
    await _load(game);
    await _pumpUntil(
      game,
      () => game.dialoguePresentationListenable.value != null,
    );
    expect(game.gameStateSnapshot.repelState.remainingSteps, 0);
    expect(game.gameStateSnapshot.repelState.expirationPending, isTrue);
    expect(game.gameStateSnapshot.bag.entries.single.quantity, 2);
  });

  test(
    'a stale renewal transaction cannot overwrite a newer saved state',
    () async {
      final repository = _RepelSaveRepository();
      final game = _MovementGame(
        bundle: _bundle(),
        saveRepository: repository,
        saveData: saveDataFromGameState(
          const GameState(saveId: 'repel', currentMapId: 'route'),
        ),
      );
      await _load(game);
      expect(await game.saveGame(), isTrue);
      final expected = game.gameStateSnapshot;
      final renewed = expected.copyWith(
        repelState: RepelState.active(itemId: 'repel', steps: 7),
      );
      final stale = expected.copyWith(
        repelState: RepelState.active(itemId: 'repel', steps: 99),
      );
      final accepted = game.commitAndSavePlayerServiceState(
        renewed,
        expectedState: expected,
      );
      final refused = game.commitAndSavePlayerServiceState(
        stale,
        expectedState: expected,
      );
      await expectLater(refused, throwsStateError);
      await accepted;
      expect(game.gameStateSnapshot.repelState.remainingSteps, 7);
      expect(repository.saved!.repelState.remainingSteps, 7);
    },
  );

  for (final renewal in ['yes', 'no', 'cancel', 'missing', 'saveFailure']) {
    test(
      'Repousse expiry $renewal has one saved outcome and no duplicate consumption',
      () async {
        final bundle = await _repelBundle();
        final repository = _RepelSaveRepository(fail: renewal == 'saveFailure');
        final game = _MovementGame(
          bundle: bundle,
          saveRepository: repository,
          saveData: saveDataFromGameState(
            GameState(
              saveId: 'repel',
              currentMapId: 'route',
              repelState: RepelState.active(itemId: 'repel', steps: 1),
              bag: const Bag(entries: [BagEntry(itemId: 'repel', quantity: 2)]),
            ),
          ),
        );
        await _load(game);
        game.setDialogueTextSpeed(RuntimeDialogueTextSpeed.instant);
        await _move(game, RuntimeInputControl.right);
        await _pumpUntil(
          game,
          () => game.dialoguePresentationListenable.value != null,
        );
        await _repelChoices(game);
        if (renewal == 'missing') {
          await game.commitAndSavePlayerServiceState(
            game.gameStateSnapshot.copyWith(bag: const Bag()),
          );
        }
        if (renewal == 'cancel') {
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.secondary),
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.secondary),
          );
        } else {
          final snapshot = game.dialoguePresentationListenable.value!;
          final index = renewal == 'no' ? 1 : 0;
          final command = DialogueSelectChoiceCommand(
            snapshotRevision: snapshot.revision,
            choiceIndex: index,
          );
          expect(game.dispatchDialoguePresentationCommand(command), isTrue);
          expect(game.dispatchDialoguePresentationCommand(command), isFalse);
        }
        await _pumpUntil(
          game,
          () =>
              game.dialoguePresentationListenable.value == null &&
              game.inputAuthoritySnapshot.context ==
                  RuntimeInputContext.overworld,
        );
        final state = game.gameStateSnapshot;
        if (renewal == 'saveFailure') {
          expect(game.runtimeNotificationListenable.value!.text, contains('n’a pas pu être sauvegardée'));
          expect(state.repelState.expirationPending, isTrue);
        }
        expect(state.repelState.remainingSteps, renewal == 'yes' ? 3 : 0);
        if (renewal == 'missing') {
          expect(state.bag.entries, isEmpty);
        } else {
          expect(state.bag.entries.single.quantity, renewal == 'yes' ? 1 : 2);
        }
        expect(state.playerPosition, const GridPos(x: 1, y: 0));
        for (var tick = 0; tick < 20; tick++) {
          game.update(.016);
          await Future<void>.delayed(Duration.zero);
        }
        expect(game.dialoguePresentationListenable.value, isNull);
        expect(repository.attempts, renewal == 'missing' ? 2 : 1);
        if (renewal != 'saveFailure') {
          expect(repository.saved!.repelState, state.repelState);
          expect(repository.saved!.bag, state.bag);
        }
      },
    );
  }

  test('Repousse expiration waits for external modal authority and survives cold restore', () async {
    final bundle = await _repelBundle();
    final repository = _RepelSaveRepository();
    final game = _MovementGame(
      bundle: bundle,
      saveRepository: repository,
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'repel',
          currentMapId: 'route',
          repelState: RepelState.active(itemId: 'repel', steps: 2),
        ),
      ),
    );
    await _load(game);
    await _move(game, RuntimeInputControl.right);
    expect(await game.saveGame(), isTrue);
    final saved = repository.saved!;
    expect(saved.repelState.remainingSteps, 1);
    final restored = _MovementGame(
      bundle: bundle,
      saveRepository: repository,
      saveData: saveDataFromGameState(saved),
    );
    await _load(restored);
    expect(restored.gameStateSnapshot.repelState.remainingSteps, 1);
    restored.setExternalInputLock(
      RuntimeExternalInputLock.pauseMenu,
      locked: true,
    );
    for (var tick = 0; tick < 20; tick++) { restored.update(.016); }
    expect(restored.gameStateSnapshot.repelState.remainingSteps, 1);
    expect(restored.dialoguePresentationListenable.value, isNull);
    restored.setExternalInputLock(
      RuntimeExternalInputLock.pauseMenu,
      locked: false,
    );
    await _move(restored, RuntimeInputControl.right);
    await _pumpUntil(
      restored,
      () => restored.dialoguePresentationListenable.value != null,
    );
    expect(restored.gameStateSnapshot.repelState.remainingSteps, 0);
  });

  test(
    'normal input publishes one committed cell after world commit',
    () async {
      final game = _MovementGame(bundle: _bundle());
      await _load(game);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 0));
      await _move(game, RuntimeInputControl.right);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      final movement = game.lastCommittedMovement;
      expect(movement, isNotNull);
      expect(movement!.movement.kind, CommittedMovementKind.walk);
      expect(movement.movement.fromCell, const GridPos(x: 0, y: 0));
      expect(movement.movement.toCell, const GridPos(x: 1, y: 0));
    },
  );

  test(
    'callback observes canonical position and one identity per traversal',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      late final _MovementGame game;
      game = _MovementGame(
        bundle: _bundle(),
        onCommittedMovement: (movement) {
          expect(
            game.gameStateSnapshot.playerPosition,
            movement.movement.toCell,
          );
          expect(game.lastCommittedMovement, same(movement));
          movements.add(movement);
        },
      );
      await _load(game);
      expect(game.lastCommittedMovement, isNull);
      expect(movements, isEmpty);
      await _move(game, RuntimeInputControl.right);
      await _move(game, RuntimeInputControl.left);
      await _move(game, RuntimeInputControl.right);
      expect(movements, hasLength(3));
      expect(movements.map((event) => event.revision), [1, 2, 3]);
      expect(movements.map((event) => event.operationId).toSet(), hasLength(3));
      expect(movements.map((event) => event.mapId).toSet(), {'route'});
      expect(
        movements.map((event) => event.mapActivationId).toSet(),
        hasLength(1),
      );
      expect(
        movements.map(
          (event) => const CommittedMovementStepPolicy(
            forcedMovement: ForcedMovementStepPolicy.exclude,
          ).unitsFor(event.movement),
        ),
        [1, 1, 1],
      );
      for (var tick = 0; tick < 20; tick++) {
        game.update(.016);
      }
      expect(movements, hasLength(3));
    },
  );

  test(
    'normal commit rejects reentrant and interpolating forced steps',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      bool? reentrantResult;
      late final _MovementGame game;
      game = _MovementGame(
        bundle: _bundle(),
        onCommittedMovement: (movement) {
          movements.add(movement);
          if (movement.movement.kind == CommittedMovementKind.walk) {
            game
                .movePlayerByForcedStep(
                  direction: EntityFacing.south,
                  expectedMapActivationId:
                      game.overworldInteractionSnapshot.mapActivationId,
                  durationMs: 100,
                )
                .then((value) => reentrantResult = value);
          }
        },
      );
      await _load(game);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      );
      game.update(.016);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      expect(game.debugIsPlayerStepping, isTrue);
      expect(
        await game.movePlayerByForcedStep(
          direction: EntityFacing.south,
          expectedMapActivationId:
              game.overworldInteractionSnapshot.mapActivationId,
          durationMs: 100,
        ),
        isFalse,
      );
      await _pumpUntil(
        game,
        () => !game.debugIsPlayerStepping && reentrantResult != null,
      );
      expect(reentrantResult, isFalse);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      expect(
        game.debugPlayerWorldTopLeft,
        game.debugExpectedPlayerWorldTopLeft,
      );
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 0));
      expect(movements, hasLength(1));
      expect(movements.single.movement.kind, CommittedMovementKind.walk);
      expect(game.lastCommittedMovement!.revision, 1);
    },
  );

  for (final forced in [false, true]) {
    test(
      'a failing sink preserves a committed ${forced ? 'forced' : 'normal'} step',
      () async {
        var calls = 0;
        final previousDebugPrint = debugPrint;
        final sinkErrors = <String>[];
        debugPrint = (message, {wrapWidth}) {
          if (message?.contains('committed movement sink failed') == true) {
            sinkErrors.add(message!);
          }
          previousDebugPrint(message, wrapWidth: wrapWidth);
        };
        addTearDown(() => debugPrint = previousDebugPrint);
        final game = _MovementGame(
          bundle: _bundle(),
          onCommittedMovement: (_) {
            calls++;
            throw StateError('consumer failed');
          },
        );
        await _load(game);
        for (var step = 0; step < 2; step++) {
          if (forced) {
            bool? moved;
            final execution = game
                .movePlayerByForcedStep(
                  direction: EntityFacing.east,
                  expectedMapActivationId:
                      game.overworldInteractionSnapshot.mapActivationId,
                  durationMs: 100,
                )
                .then((value) => moved = value);
            await _pumpUntil(game, () => moved != null);
            await execution;
            expect(moved, isTrue);
          } else {
            await _move(game, RuntimeInputControl.right);
          }
          expect(
            game.gameStateSnapshot.playerPosition,
            GridPos(x: step + 1, y: 0),
          );
          expect(game.debugIsPlayerStepping, isFalse);
          expect(game.lastCommittedMovement!.revision, step + 1);
          expect(
            game.lastCommittedMovement!.movement.toCell,
            GridPos(x: step + 1, y: 0),
          );
        }
        expect(calls, 2);
        expect(sinkErrors, hasLength(1));
        expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
      },
    );
  }

  test('collision and input locks produce no committed movement', () async {
    final movements = <RuntimeCommittedMovement>[];
    final game = _MovementGame(
      bundle: _bundle(),
      onCommittedMovement: movements.add,
    );
    await _load(game);
    await _move(game, RuntimeInputControl.left);
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 0));
    expect(movements, isEmpty);
    game.setExternalInputLock(RuntimeExternalInputLock.lifecycle, locked: true);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    );
    game.update(.3);
    game.setExternalInputLock(
      RuntimeExternalInputLock.lifecycle,
      locked: false,
    );
    game.update(.3);
    expect(movements, isEmpty);
    expect(game.lastCommittedMovement, isNull);
  });

  test('keyboard movement uses the committed producer', () async {
    final movements = <RuntimeCommittedMovement>[];
    final game = _MovementGame(
      bundle: _bundle(),
      onCommittedMovement: movements.add,
    );
    await _load(game);
    game.onKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      ),
      {LogicalKeyboardKey.arrowRight},
    );
    game.update(.016);
    game.onKeyEvent(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration(milliseconds: 16),
      ),
      {},
    );
    await _pumpUntil(game, () => !game.debugIsPlayerStepping);
    expect(movements, hasLength(1));
    expect(movements.single.movement.toCell, const GridPos(x: 1, y: 0));
  });

  test(
    'water refusal emits nothing and a Surf step emits one Surf cell',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final bundle = _bundle();
      final game = _MovementGame(
        bundle: bundle.copyWith(
          map: bundle.map.copyWith(
            gameplayZones: const [
              MapGameplayZone(
                id: 'water',
                name: 'Water',
                kind: GameplayZoneKind.movement,
                area: MapRect(
                  pos: GridPos(x: 1, y: 0),
                  size: GridSize(width: 2, height: 1),
                ),
                movement: MovementZonePayload(requiredMode: MovementMode.surf),
              ),
            ],
          ),
        ),
        onCommittedMovement: movements.add,
      );
      await _load(game);
      await _move(game, RuntimeInputControl.right);
      expect(movements, isEmpty);
      for (
        var attempt = 0;
        attempt < 6 && game.debugFlowPhaseName == 'dialogue';
        attempt++
      ) {
        await _move(game, RuntimeInputControl.primary);
      }
      expect(game.debugFlowPhaseName, 'overworld');
      game.setPlayerMovementMode(MovementMode.surf);
      await _move(game, RuntimeInputControl.right);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      expect(movements, hasLength(1));
      expect(movements.single.movement.kind, CommittedMovementKind.surf);
    },
  );

  test(
    'warp pad traversal counts once and arrival creates no second cell',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final bundle = _bundle();
      final target = bundle.copyWith(map: bundle.map.copyWith(id: 'target'));
      final game = _MovementGame(
        bundle: bundle.copyWith(
          map: bundle.map.copyWith(
            warps: const [
              MapWarp(
                id: 'exit',
                pos: GridPos(x: 1, y: 0),
                targetMapId: 'target',
                targetPos: GridPos(x: 3, y: 3),
              ),
            ],
          ),
        ),
        runtimeMapBundleLoader: ({
          required projectFilePath,
          required mapId,
        }) async => target,
        saveData: saveDataFromGameState(GameState(saveId: 'repel', currentMapId: 'route', repelState: RepelState.active(itemId: 'repel', steps: 6))),
      onCommittedMovement: movements.add,
      );
      await _load(game);
      await _move(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'target' &&
            !game.debugHasPendingMapTransition,
      );
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 3, y: 3));
      expect(movements, hasLength(1));
      expect(game.gameStateSnapshot.repelState.remainingSteps, 5);
      expect(movements.single.mapId, 'route');
      expect(movements.single.movement.kind, CommittedMovementKind.walk);
      expect(movements.single.movement.toCell, const GridPos(x: 1, y: 0));
    },
  );

  test('connection changes maps without inventing a traversal', () async {
    final movements = <RuntimeCommittedMovement>[];
    final bundle = _bundle();
    final target = bundle.copyWith(map: bundle.map.copyWith(id: 'target'));
    final game = _MovementGame(
      bundle: bundle.copyWith(
        map: bundle.map.copyWith(
          connections: const [
            MapConnection(
              direction: MapConnectionDirection.west,
              targetMapId: 'target',
              offset: 0,
            ),
          ],
        ),
      ),
      runtimeMapBundleLoader: ({
        required projectFilePath,
        required mapId,
      }) async => target,
      saveData: saveDataFromGameState(GameState(saveId: 'repel', currentMapId: 'route', repelState: RepelState.active(itemId: 'repel', steps: 6))),
      onCommittedMovement: movements.add,
    );
    await _load(game);
    await _move(game, RuntimeInputControl.left);
    await _pumpUntil(
      game,
      () => game.gameStateSnapshot.currentMapId == 'target',
    );
    expect(game.gameStateSnapshot.repelState.remainingSteps, 6);
    expect(movements, isEmpty);
    expect(game.lastCommittedMovement, isNull);
  });

  test(
    'forced route emits only after each validated physical step completes',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final game = _MovementGame(
        bundle: _bundle(),
        onCommittedMovement: movements.add,
      );
      await _load(game);
      String? result;
      final execution = () async {
        final first = await game.movePlayerByForcedStep(
          direction: EntityFacing.east,
          expectedMapActivationId:
              game.overworldInteractionSnapshot.mapActivationId,
          durationMs: 100,
        );
        final second = await game.movePlayerByForcedStep(
          direction: EntityFacing.south,
          expectedMapActivationId:
              game.overworldInteractionSnapshot.mapActivationId,
          durationMs: 100,
        );
        result = first && second ? 'completed' : 'blocked';
      }();
      await Future<void>.delayed(Duration.zero);
      expect(movements, isEmpty);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 0));
      expect(await game.saveGame(), isFalse);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      );
      game.update(.016);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      );
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 0));
      await _pumpUntil(game, () => result != null);
      await execution;
      expect(result, 'completed');
      expect(movements, hasLength(2));
      expect(movements.map((event) => event.movement.kind), [
        CommittedMovementKind.forced,
        CommittedMovementKind.forced,
      ]);
      expect(movements.map((event) => event.movement.toCell), [
        const GridPos(x: 1, y: 0),
        const GridPos(x: 1, y: 1),
      ]);
      expect(movements.map((event) => event.operationId).toSet(), hasLength(2));
    },
  );

  test('blocked forced route produces no movement', () async {
    final movements = <RuntimeCommittedMovement>[];
    final game = _MovementGame(
      bundle: _bundle(),
      onCommittedMovement: movements.add,
    );
    await _load(game);
    final result = await game.movePlayerByForcedStep(
      direction: EntityFacing.west,
      expectedMapActivationId:
          game.overworldInteractionSnapshot.mapActivationId,
      durationMs: 100,
    );
    expect(result, isFalse);
    expect(movements, isEmpty);
  });

  test(
    'forced step refuses stale activation, invalid duration and locked input',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final game = _MovementGame(
        bundle: _bundle(),
        onCommittedMovement: movements.add,
      );
      await _load(game);
      final activationId = game.overworldInteractionSnapshot.mapActivationId;
      expect(
        await game.movePlayerByForcedStep(
          direction: EntityFacing.east,
          expectedMapActivationId: 'stale',
        ),
        isFalse,
      );
      for (final duration in [0, 60001]) {
        expect(
          await game.movePlayerByForcedStep(
            direction: EntityFacing.east,
            expectedMapActivationId: activationId,
            durationMs: duration,
          ),
          isFalse,
        );
      }
      game.setExternalInputLock(
        RuntimeExternalInputLock.lifecycle,
        locked: true,
      );
      expect(
        await game.movePlayerByForcedStep(
          direction: EntityFacing.east,
          expectedMapActivationId: activationId,
        ),
        isFalse,
      );
      expect(movements, isEmpty);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 0));
    },
  );

  test('restored position produces no movement on load', () async {
    final movements = <RuntimeCommittedMovement>[];
    final game = _MovementGame(
      bundle: _bundle(),
      saveData: saveDataFromGameState(
        const GameState(
          saveId: 'restored',
          currentMapId: 'route',
          playerPosition: GridPos(x: 4, y: 4),
        ),
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
      onCommittedMovement: movements.add,
    );
    await _load(game);
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 4, y: 4));
    expect(movements, isEmpty);
    expect(game.lastCommittedMovement, isNull);
  });

  test(
    'interrupted forced route never publishes its proposed destination',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final game = _MovementGame(
        bundle: _bundle(),
        onCommittedMovement: movements.add,
      );
      await _load(game);
      final execution = game.movePlayerByForcedStep(
        direction: EntityFacing.east,
        expectedMapActivationId:
            game.overworldInteractionSnapshot.mapActivationId,
        durationMs: 500,
      );
      await Future<void>.delayed(Duration.zero);
      expect(game.debugIsPlayerStepping, isTrue);
      game.onRemove();
      expect(await execution, isFalse);
      expect(movements, isEmpty);
    },
  );

  test(
    'compensated narrative route cannot publish an external commit',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final bundle = _bundle();
      final scene = _compensatedScene();
      var movedBeforeRollback = false;
      late final _MovementGame game;
      game = _MovementGame(
        bundle: bundle.copyWith(
          manifest: bundle.manifest.copyWith(
            eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              records: const [],
              legacyClaims: const [],
            ),
            scenes: [scene],
            dialogues: const [
              ProjectDialogueEntry(
                id: 'failure',
                name: 'Failure',
                relativePath: 'dialogues/failure.yarn',
              ),
            ],
          ),
        ),
        dialogueSessionLoader: (_) async {
          movedBeforeRollback =
              game.debugPlayerGridPosition == const GridPos(x: 1, y: 0);
          expect(movements, isEmpty);
          expect(game.gameStateSnapshot.repelState.remainingSteps, 6);
          expect(game.playerServiceGameStateSnapshot.repelState.remainingSteps, 5);
          throw StateError('failed dialogue');
        },
        saveData: saveDataFromGameState(GameState(saveId: 'repel', currentMapId: 'route', repelState: RepelState.active(itemId: 'repel', steps: 6))),
        onCommittedMovement: movements.add,
      );
      await _load(game);
      NarrativeSceneExecutionResult? result;
      final execution = game
          .debugExecuteNarrativeSceneForTest(
            NarrativeSceneExecutionRequest(
              eventId: 'event',
              sceneId: scene.id,
              executionId: 'compensated-route',
              gameState: game.gameStateSnapshot,
            ),
          )
          .then((value) => result = value);
      await _pumpUntil(game, () => result != null);
      await execution;
      expect(
        movedBeforeRollback,
        isTrue,
        reason: result is NarrativeSceneExecutionFailed
            ? '${(result as NarrativeSceneExecutionFailed).failure}'
            : '$result',
      );
      expect(result, isNot(isA<NarrativeSceneExecutionCompleted>()));
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 0));
      expect(movements, isEmpty);
      expect(game.gameStateSnapshot.repelState.remainingSteps, 6);
      expect(game.lastCommittedMovement, isNull);
    },
  );
}

class _MovementGame extends PlayableMapGame {
  _MovementGame({
    required super.bundle,
    super.onCommittedMovement,
    super.runtimeMapBundleLoader,
    super.saveData,
    super.saveRepository,
    super.dialogueSessionLoader,
    super.initialMapActivationReason,
  }) : super(
         runtimePlayerPokemonProgressionCatalogLoader:
             ({
               required gameState,
               required projectRootDirectory,
               required pokemonConfig,
             }) async => const RuntimePlayerPokemonProgressionCatalogs(
               speciesById: {
                 'pikachu': PlayerPokemonHydrationSpecies(
                   id: 'pikachu',
                   baseStats: PokemonBaseStats(
                     hp: 35,
                     attack: 55,
                     defense: 40,
                     specialAttack: 50,
                     specialDefense: 50,
                     speed: 90,
                   ),
                   primaryAbilityId: 'static',
                   abilityIds: ['static'],
                   growthRateId: 'medium_fast',
                 ),
               },
               maxPpByMoveId: {},
             ),
         projectFilePath: '/tmp/committed-movement/project.json');

  @override
  bool get isLoaded => true;
}

SceneAsset _compensatedScene() => SceneAsset(
  id: 'compensated',
  name: 'Compensated',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'route',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload(
          interactiveCommand: SceneInteractiveCommand.actorRoute(
            target: SceneActorTarget.player(mapId: 'route'),
            steps: [
              SceneActorRouteStep.move(
                direction: EntityFacing.east,
                durationMs: 100,
              ),
            ],
          ),
        ),
      ),
      SceneNode(
        id: 'failure',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(dialogueId: 'failure'),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start-route',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'route',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'route-failure',
        fromNodeId: 'route',
        fromPortId: 'completed',
        toNodeId: 'failure',
        kind: SceneEdgeKind.actionCompleted,
      ),
      SceneEdge(
        id: 'route-blocked',
        fromNodeId: 'route',
        fromPortId: 'blocked',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
      SceneEdge(
        id: 'failure-end',
        fromNodeId: 'failure',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

Future<void> _repelChoices(PlayableMapGame game) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    final snapshot = game.dialoguePresentationListenable.value!;
    if (snapshot.mode == DialoguePresentationMode.choices) return;
    game.dispatchDialoguePresentationCommand(
      DialogueAdvanceCommand(snapshotRevision: snapshot.revision),
    );
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Repousse renewal choices were not presented.');
}

Future<RuntimeMapBundle> _repelBundle() async {
  final root = await Directory.systemTemp.createTemp('repel-runtime-');
  addTearDown(() => root.delete(recursive: true));
  await File('${root.path}/items.json').writeAsString(
    jsonEncode(
      const ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'repel',
            displayName: 'Repousse',
            pocketId: 'items',
            uses: [
              ProjectItemUseDefinition(
                contexts: {ProjectItemUseContext.overworld},
                target: ProjectItemTargetKind.world,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.repel(steps: 3),
              ),
            ],
          ),
        ],
      ).toJson(),
    ),
  );
  final bundle = _bundle();
  return bundle.copyWith(
    projectRootDirectory: root.path,
    manifest: bundle.manifest.copyWith(
      pokemon: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {'items': 'items.json'},
      ),
    ),
  );
}

class _RepelSaveRepository implements GameSaveRepository {
  _RepelSaveRepository({this.fail = false});
  final bool fail;
  int attempts = 0;
  GameState? saved;
  @override
  Future<void> save(GameState state) async {
    attempts++;
    if (fail) throw const GameSaveException('disk full');
    saved = gameStateFromStrictSaveJson(strictGameStateSaveJson(state));
  }

  @override
  Future<GameState?> load() async => saved;
  @override
  Future<bool> exists() async => saved != null;
  @override
  Future<void> delete() async => saved = null;
}

RuntimeMapBundle _bundle() => RuntimeMapBundle(
  manifest: const ProjectManifest(
    name: 'Movement',
    maps: [
      ProjectMapEntry(
        id: 'route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
    ],
    tilesets: [],
  ),
  map: const MapData(
    id: 'route',
    name: 'Route',
    size: GridSize(width: 8, height: 8),
    layers: [MapLayer.object(id: 'objects', name: 'Objects')],
  ),
  projectRootDirectory: '/tmp/committed-movement',
  tilesetAbsolutePathsById: const {},
);

Future<void> _load(_MovementGame game) async {
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  addTearDown(game.onRemove);
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

Future<void> _move(PlayableMapGame game, RuntimeInputControl control) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(.016);
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  await _pumpUntil(
    game,
    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
  );
}

Future<void> _pumpUntil(PlayableMapGame game, bool Function() done) async {
  for (var i = 0; i < 300; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('The movement did not settle.');
}

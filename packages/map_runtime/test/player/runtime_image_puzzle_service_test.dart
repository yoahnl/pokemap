import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_gameplay/map_gameplay.dart';

final definition = ImagePuzzleDefinition(
  puzzleId: 'mosaic',
  imageResourceId: 'image',
  rows: 1,
  columns: 2,
  initialPieces: [
    const ImagePuzzlePiece(pieceId: 0, slot: 2),
    const ImagePuzzlePiece(pieceId: 1, slot: 1),
  ],
);

void main() {
  test('puzzle without explicit durable callback fails closed', () async {
    final fixture = _Fixture(durable: false);
    addTearDown(fixture.controller.dispose);
    expect(
      (await fixture.open()).status,
      PlayerServiceRuntimeStatus.unavailable,
    );
    expect(fixture.writes, 0);
    expect(fixture.locks, isEmpty);
  });
  test(
    'dispose during image loading releases the interaction before late decode',
    () async {
      final bitmap = Completer<RuntimeImagePuzzleBitmap>();
      final fixture = _Fixture(bitmapGate: bitmap.future);
      final opening = fixture.open();
      await Future<void>.delayed(Duration.zero);
      await fixture.controller.dispose();
      expect(
        (await opening.timeout(const Duration(seconds: 1))).status,
        PlayerServiceRuntimeStatus.cancelled,
      );
      expect(fixture.locks, [true, false]);
      bitmap.complete(
        RuntimeImagePuzzleBitmap(
          bytes: Uint8List.fromList([1]),
          width: 2,
          height: 1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(fixture.writes, 0);
    },
  );
  test(
    'initial persistence failure permits reopening without partial progress',
    () async {
      final fixture = _Fixture()..failSave = true;
      addTearDown(fixture.controller.dispose);
      expect((await fixture.open()).status, PlayerServiceRuntimeStatus.failed);
      expect(fixture.state.imagePuzzleState, const ImagePuzzleState.empty());
      expect(fixture.controller.worldServiceSnapshot, isNull);
      expect(fixture.locks, [true, false]);
      fixture.failSave = false;
      final retry = fixture.open();
      await fixture.active();
      await fixture.send(RuntimeWorldServiceAction.reset);
      expect(fixture.writes, 2);
      await fixture.send(RuntimeWorldServiceAction.cancel);
      expect((await retry).imagePuzzleOutcome, ImagePuzzleOutcome.quit);
    },
  );
  test(
    'initial layout and each move persist before verified solved result',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.controller.dispose);
      final opening = fixture.open();
      await fixture.active();
      expect(fixture.writes, 1);
      expect(
        (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
        RuntimeWorldServiceCommandStatus.unavailable,
      );
      final before = fixture.controller.worldServiceSnapshot!;
      final moving = fixture.send(
        RuntimeWorldServiceAction.move,
        piece: '0',
        slot: '0',
      );
      await moving;
      expect(fixture.writes, 2);
      expect(
        (await fixture.controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.cancel,
            snapshotRevision: before.revision,
          ),
        )).status,
        RuntimeWorldServiceCommandStatus.stale,
      );
      await fixture.send(RuntimeWorldServiceAction.confirm);
      final result = await opening;
      expect(result.imagePuzzleOutcome, ImagePuzzleOutcome.solved);
      expect(fixture.writes, 3);
      expect(fixture.locks, [true, false]);
    },
  );
  test(
    'failed move retains saved arrangement and can retry then quit and resume',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.controller.dispose);
      final opening = fixture.open();
      await fixture.active();
      final initial = fixture.state;
      fixture.failSave = true;
      expect(
        (await fixture.send(
          RuntimeWorldServiceAction.move,
          piece: '0',
          slot: '0',
        )).status,
        RuntimeWorldServiceCommandStatus.failed,
      );
      expect(fixture.state, initial);
      fixture.failSave = false;
      await fixture.send(RuntimeWorldServiceAction.rotate, piece: '0');
      await fixture.send(RuntimeWorldServiceAction.cancel);
      expect((await opening).imagePuzzleOutcome, ImagePuzzleOutcome.quit);
      final saved = fixture.state.imagePuzzleState;
      final second = fixture.open();
      await fixture.active();
      expect(
        (fixture.controller.worldServiceSnapshot!.content
                as RuntimeImagePuzzleServiceContent)
            .progress,
        saved.puzzlesById['mosaic'],
      );
      final wire = RuntimeCompanionPresentationCodec.encodeWorldService(
        fixture.controller.worldServiceSnapshot!,
      );
      final decoded = RuntimeCompanionPresentationCodec.decodeWorldService(
        jsonDecode(jsonEncode(wire)) as Map<String, dynamic>,
      );
      expect(
        (decoded.content as RuntimeImagePuzzleServiceContent).progress,
        saved.puzzlesById['mosaic'],
      );
      await fixture.send(RuntimeWorldServiceAction.cancel);
      await second;
    },
  );
  for (final action in [
    RuntimeWorldServiceAction.cancel,
    RuntimeWorldServiceAction.close,
  ]) {
    test(
      'concurrent puzzle changes allow $action without rewriting stale state and reopen current progress',
      () async {
        final fixture = _Fixture();
        addTearDown(fixture.controller.dispose);
        final opening = fixture.open();
        await fixture.active();
        final savedBytes = jsonEncode(fixture.persistedState!.toJson());
        final externallyChanged = const ImagePuzzleOperations()
            .rotate(fixture.state, definition: definition, pieceId: 0)
            .state
            .copyWith(
              trainerProfile: const TrainerProfile(name: 'Leaf', money: 77),
            );
        fixture.state = externallyChanged;
        expect(
          (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
          RuntimeWorldServiceCommandStatus.stale,
        );
        final closingRevision =
            fixture.controller.worldServiceSnapshot!.revision;
        expect(
          (await fixture.send(action)).status,
          RuntimeWorldServiceCommandStatus.accepted,
        );
        final result = await opening.timeout(const Duration(seconds: 1));
        expect(result.imagePuzzleOutcome, ImagePuzzleOutcome.quit);
        expect(result.gameState, externallyChanged);
        expect(fixture.state, externallyChanged);
        expect(fixture.controller.worldServiceSnapshot, isNull);
        expect(fixture.locks, [true, false]);
        expect(fixture.writes, 1);
        expect(jsonEncode(fixture.persistedState!.toJson()), savedBytes);
        expect(
          (await fixture.controller.dispatchWorldService(
            RuntimeWorldServiceCommand(
              action: action,
              snapshotRevision: closingRevision,
            ),
          )).status,
          isNot(RuntimeWorldServiceCommandStatus.accepted),
        );
        expect(fixture.writes, 1);
        final reopened = fixture.open();
        await fixture.active();
        expect(
          (fixture.controller.worldServiceSnapshot!.content
                  as RuntimeImagePuzzleServiceContent)
              .progress,
          externallyChanged.imagePuzzleState.puzzlesById['mosaic'],
        );
        expect(fixture.writes, 1);
        expect(jsonEncode(fixture.persistedState!.toJson()), savedBytes);
        await fixture.send(RuntimeWorldServiceAction.cancel);
        expect((await reopened).imagePuzzleOutcome, ImagePuzzleOutcome.quit);
        expect(fixture.state, externallyChanged);
        expect(fixture.persistedState, externallyChanged);
      },
    );
  }
  test('dispose after a failed solved checkpoint returns quit instead of rewarding', () async {
    final fixture = _Fixture();
    final opening = fixture.open();
    await fixture.active();
    await fixture.send(RuntimeWorldServiceAction.move, piece: '0', slot: '0');
    fixture.failSave = true;
    expect(
      (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    await fixture.controller.dispose();
    expect((await opening).imagePuzzleOutcome, ImagePuzzleOutcome.quit);
  });
  test(
    'dispose waits for inflight persistence and never reports solved on a move',
    () async {
      final fixture = _Fixture();
      final opening = fixture.open();
      await fixture.active();
      final gate = Completer<void>();
      fixture.saveGate = gate.future;
      final move = fixture.send(
        RuntimeWorldServiceAction.move,
        piece: '0',
        slot: '0',
      );
      await Future<void>.delayed(Duration.zero);
      final dispose = fixture.controller.dispose();
      expect(
        (await fixture.send(RuntimeWorldServiceAction.cancel)).status,
        isNot(RuntimeWorldServiceCommandStatus.accepted),
      );
      gate.complete();
      await move;
      await dispose;
      expect((await opening).imagePuzzleOutcome, ImagePuzzleOutcome.quit);
      expect(
        fixture.state.imagePuzzleState.puzzlesById['mosaic']!.isSolved,
        isTrue,
      );
    },
  );
}

class _Fixture {
  _Fixture({this.durable = true, this.bitmapGate});
  final bool durable;
  final Future<RuntimeImagePuzzleBitmap>? bitmapGate;
  GameState state = const GameState(saveId: 'puzzle');
  GameState? persistedState;
  var writes = 0;
  var failSave = false;
  Future<void>? saveGate;
  final locks = <bool>[];
  late final controller = PlayerServiceRuntimeController.contextual(
    currentGameState: () => state,
    commitAndSave: (_) async =>
        throw StateError('Puzzle requires durable save'),
    commitImagePuzzleAndSave: !durable
        ? null
        : (next) async {
            await saveGate;
            if (failSave) throw StateError('disk');
            state = next;
            persistedState = next;
            writes++;
          },
    loadImagePuzzleBitmap: (_) async =>
        bitmapGate ??
        RuntimeImagePuzzleBitmap(
          bytes: Uint8List.fromList([1, 2]),
          width: 2,
          height: 1,
        ),
    setInputLocked: locks.add,
    loadRecoveryCaps: (_) async =>
        const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
  );
  Future<PlayerServiceRuntimeResult> open() => controller.openImagePuzzle(
    request: OpenImagePuzzleService(
      interactionId: 'puzzle',
      definition: definition,
    ),
  );
  Future<void> active() async {
    for (var i = 0; i < 40 && controller.worldServiceSnapshot == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(controller.worldServiceSnapshot, isNotNull);
  }

  Future<RuntimeWorldServiceCommandResult> send(
    RuntimeWorldServiceAction action, {
    String? piece,
    String? slot,
  }) => controller.dispatchWorldService(
    RuntimeWorldServiceCommand(
      action: action,
      snapshotRevision: controller.worldServiceSnapshot!.revision,
      targetId: piece,
      secondaryTargetId: slot,
    ),
  );
}

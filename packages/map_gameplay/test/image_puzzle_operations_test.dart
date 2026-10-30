import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

ImagePuzzleDefinition definition(
        {String image = 'images.puzzle',
        bool reset = true,
        List<int> rotations = const [0, 1, 2, 3]}) =>
    ImagePuzzleDefinition(
        puzzleId: 'puzzle',
        imageResourceId: image,
        rows: 2,
        columns: 2,
        trayCapacity: 2,
        allowReset: reset,
        allowedQuarterTurns: rotations);
void main() {
  const operations = ImagePuzzleOperations();
  const initial = GameState(saveId: 'puzzle-save', metadata: {'keep': 'value'});
  test('deterministic initialization always unsolved with every unique piece',
      () {
    for (var seed = 0; seed < 100; seed++) {
      final config = definition();
      final result = operations.open(initial, definition: config, seed: seed);
      final progress = result.state.imagePuzzleState.puzzlesById['puzzle']!;
      expect(result.failure, isNull);
      expect(
          progress,
          operations
              .open(initial, definition: config, seed: seed)
              .state
              .imagePuzzleState
              .puzzlesById['puzzle']);
      expect(progress.isSolved, isFalse);
      expect(progress.pieces.map((p) => p.pieceId).toSet(), {0, 1, 2, 3});
      expect(progress.pieces.map((p) => p.slot).toSet().length, 4);
      expect(result.state.metadata, initial.metadata);
    }
  });
  test('move, rotate, quit, save and reopen retain progress', () {
    final config = definition();
    var state = operations.open(initial, definition: config, seed: 3).state;
    final before = state.imagePuzzleState.puzzlesById['puzzle']!;
    final empty = List.generate(6, (i) => i)
        .firstWhere((slot) => before.pieces.every((p) => p.slot != slot));
    state = operations
        .move(state, definition: config, pieceId: 0, targetSlot: empty)
        .state;
    expect(state.imagePuzzleState.puzzlesById['puzzle']!.pieces[0].slot, empty);
    final angle =
        state.imagePuzzleState.puzzlesById['puzzle']!.pieces[0].quarterTurns;
    state = operations.rotate(state, definition: config, pieceId: 0).state;
    expect(state.imagePuzzleState.puzzlesById['puzzle']!.pieces[0].quarterTurns,
        (angle + 1) % 4);
    final quit = operations.quit(state, definition: config);
    expect(quit.outcome, ImagePuzzleOutcome.quit);
    expect(identical(quit.state, state), isTrue);
    final restored =
        gameStateFromStrictSaveJson(strictGameStateSaveJson(state));
    expect(
        operations
            .open(restored, definition: config, seed: 99)
            .state
            .imagePuzzleState,
        state.imagePuzzleState);
  });
  test('completion checks real piece arrangement and orientation', () {
    final config = definition();
    GameState withPieces(List<ImagePuzzlePiece> pieces) => initial.copyWith(
            imagePuzzleState: ImagePuzzleState(puzzlesById: {
          'puzzle': ImagePuzzleProgress(definition: config, pieces: pieces)
        }));
    final solved = withPieces(
        [for (var i = 0; i < 4; i++) ImagePuzzlePiece(pieceId: i, slot: i)]);
    expect(operations.complete(solved, definition: config).outcome,
        ImagePuzzleOutcome.solved);
    for (final pieces in [
      [
        ImagePuzzlePiece(pieceId: 0, slot: 1),
        ImagePuzzlePiece(pieceId: 1, slot: 0),
        ImagePuzzlePiece(pieceId: 2, slot: 2),
        ImagePuzzlePiece(pieceId: 3, slot: 3)
      ],
      [
        for (var i = 0; i < 4; i++)
          ImagePuzzlePiece(pieceId: i, slot: i, quarterTurns: i == 0 ? 1 : 0)
      ],
      [
        for (var i = 0; i < 4; i++)
          ImagePuzzlePiece(pieceId: i, slot: i == 0 ? 4 : i)
      ],
    ]) {
      final state = withPieces(pieces);
      final result = operations.complete(state, definition: config);
      expect(result.failure, ImagePuzzleFailure.unsolved);
      expect(result.outcome, isNull);
      expect(identical(result.state, state), isTrue);
    }
  });
  test('invalid commands and config changes preserve original state', () {
    final config = definition();
    final state = operations.open(initial, definition: config, seed: 0).state;
    final occupied =
        state.imagePuzzleState.puzzlesById['puzzle']!.pieces[1].slot;
    for (final result in [
      operations.move(state,
          definition: config, pieceId: 0, targetSlot: occupied),
      operations.move(state, definition: config, pieceId: 0, targetSlot: -1),
      operations.move(state, definition: config, pieceId: 0, targetSlot: 6),
      operations.move(state, definition: config, pieceId: 4, targetSlot: 0),
      operations.rotate(state, definition: config, pieceId: -1),
      operations.open(state,
          definition: definition(image: 'images.changed'), seed: 0),
      operations.reset(state,
          definition: definition(image: 'images.changed'), seed: 0),
    ]) {
      expect(result.failure, isNotNull);
      expect(identical(result.state, state), isTrue);
    }
    expect(operations.complete(initial, definition: config).failure,
        ImagePuzzleFailure.notStarted);
  });
  test('rotation cycles allowed angles and reset obeys config', () {
    final config = definition(rotations: [0, 2]);
    var state = operations.open(initial, definition: config, seed: 7).state;
    final angle =
        state.imagePuzzleState.puzzlesById['puzzle']!.pieces[0].quarterTurns;
    state = operations.rotate(state, definition: config, pieceId: 0).state;
    expect(state.imagePuzzleState.puzzlesById['puzzle']!.pieces[0].quarterTurns,
        (angle + 2) % 4);
    expect(
        operations
            .reset(state, definition: config, seed: 7)
            .state
            .imagePuzzleState,
        operations
            .open(initial, definition: config, seed: 7)
            .state
            .imagePuzzleState);
    final disabled = definition(reset: false);
    final disabledState =
        operations.open(initial, definition: disabled, seed: 7).state;
    expect(
        operations.reset(disabledState, definition: disabled, seed: 7).failure,
        ImagePuzzleFailure.resetDisabled);
  });
  test('fixed pieces and explicit initial arrangement survive reset', () {
    final config = ImagePuzzleDefinition(
        puzzleId: 'puzzle',
        imageResourceId: 'images.puzzle',
        rows: 2,
        columns: 2,
        trayCapacity: 2,
        fixedPieceIds: [
          0,
          1,
          2
        ],
        initialPieces: [
          ImagePuzzlePiece(pieceId: 0, slot: 0),
          ImagePuzzlePiece(pieceId: 1, slot: 1),
          ImagePuzzlePiece(pieceId: 2, slot: 2),
          ImagePuzzlePiece(pieceId: 3, slot: 4, quarterTurns: 1)
        ]);
    final state = operations.open(initial, definition: config, seed: 7).state;
    expect(state.imagePuzzleState.puzzlesById['puzzle']!.pieces[3].slot, 4);
    expect(
        operations
            .move(state, definition: config, pieceId: 0, targetSlot: 5)
            .failure,
        ImagePuzzleFailure.fixedPiece);
    expect(operations.rotate(state, definition: config, pieceId: 0).failure,
        ImagePuzzleFailure.fixedPiece);
    expect(
        operations
            .reset(state, definition: config, seed: 9)
            .state
            .imagePuzzleState,
        state.imagePuzzleState);
  });
  test('other puzzles, flags, party and bag survive operations', () {
    final config = definition();
    final other = ImagePuzzleDefinition(
        puzzleId: 'other',
        imageResourceId: 'images.other',
        rows: 1,
        columns: 2);
    var state = operations
        .open(
            initial.copyWith(
                storyFlags: StoryFlags(activeFlags: {'kept'}),
                bag: Bag(entries: [BagEntry(itemId: 'item', quantity: 3)])),
            definition: config,
            seed: 0)
        .state;
    state = operations.open(state, definition: other, seed: 1).state;
    final result = operations.rotate(state, definition: config, pieceId: 0);
    expect(
        identical(result.state.imagePuzzleState.puzzlesById['other'],
            state.imagePuzzleState.puzzlesById['other']),
        isTrue);
    expect(result.state.storyFlags, state.storyFlags);
    expect(result.state.party, state.party);
    expect(result.state.bag, state.bag);
  });
  test('no-tray puzzles require explicit swaps and remain solvable', () {
    expect(
        () => ImagePuzzleDefinition(
            puzzleId: 'impossible',
            imageResourceId: 'images.puzzle',
            rows: 2,
            columns: 2,
            trayCapacity: 0),
        throwsFormatException);
    final config = ImagePuzzleDefinition(
        puzzleId: 'puzzle',
        imageResourceId: 'images.puzzle',
        rows: 2,
        columns: 2,
        trayCapacity: 0,
        allowSwap: true,
        allowedQuarterTurns: [0]);
    var state = operations.open(initial, definition: config, seed: 0).state;
    expect(state.imagePuzzleState.puzzlesById['puzzle']!.isSolved, isFalse);
    for (var id = 0; id < 4; id++) {
      state = operations
          .move(state, definition: config, pieceId: id, targetSlot: id)
          .state;
    }
    expect(operations.complete(state, definition: config).outcome,
        ImagePuzzleOutcome.solved);
  });
  test('all permitted small definitions initialize unsolved and are solvable',
      () {
    for (final angles in [
      [0],
      [0, 2],
      [0, 1, 2, 3]
    ]) {
      for (final count in [1, 2, 3, 4, 16]) {
        final config = ImagePuzzleDefinition(
            puzzleId: 'puzzle',
            imageResourceId: 'images.puzzle',
            rows: count == 16 ? 4 : 1,
            columns: count == 16 ? 4 : count,
            trayCapacity: 1,
            allowedQuarterTurns: angles);
        for (var seed = 0; seed < 20; seed++) {
          var state =
              operations.open(initial, definition: config, seed: seed).state;
          expect(
              state.imagePuzzleState.puzzlesById['puzzle']!.isSolved, isFalse);
          for (var id = 0; id < count; id++) {
            final progress = state.imagePuzzleState.puzzlesById['puzzle']!;
            final occupied = progress.pieces
                .where((piece) => piece.slot == id && piece.pieceId != id)
                .firstOrNull;
            if (occupied != null) {
              final empty = List.generate(config.slotCount, (i) => i)
                  .firstWhere((slot) =>
                      progress.pieces.every((piece) => piece.slot != slot));
              state = operations
                  .move(state,
                      definition: config,
                      pieceId: occupied.pieceId,
                      targetSlot: empty)
                  .state;
            }
            state = operations
                .move(state, definition: config, pieceId: id, targetSlot: id)
                .state;
            while (state.imagePuzzleState.puzzlesById['puzzle']!.pieces[id]
                    .quarterTurns !=
                0) {
              state = operations
                  .rotate(state, definition: config, pieceId: id)
                  .state;
            }
          }
          expect(operations.complete(state, definition: config).outcome,
              ImagePuzzleOutcome.solved);
        }
      }
    }
  });
  test(
      'swap cannot displace fixed pieces and invalid seeds do not create state',
      () {
    final config = ImagePuzzleDefinition(
        puzzleId: 'puzzle',
        imageResourceId: 'images.puzzle',
        rows: 1,
        columns: 2,
        trayCapacity: 1,
        allowSwap: true,
        fixedPieceIds: [0]);
    final state = operations.open(initial, definition: config, seed: 1).state;
    final failed =
        operations.move(state, definition: config, pieceId: 1, targetSlot: 0);
    expect(failed.failure, ImagePuzzleFailure.fixedPiece);
    expect(identical(failed.state, state), isTrue);
    for (final seed in [-1, 4294967296]) {
      final result = operations.open(initial, definition: config, seed: seed);
      expect(result.failure, ImagePuzzleFailure.invalidSeed);
      expect(identical(result.state, initial), isTrue);
    }
    final noRotation = definition(rotations: [0]);
    final noRotationState =
        operations.open(initial, definition: noRotation, seed: 0).state;
    expect(
        operations
            .rotate(noRotationState, definition: noRotation, pieceId: 0)
            .failure,
        ImagePuzzleFailure.rotationDisabled);
  });
}

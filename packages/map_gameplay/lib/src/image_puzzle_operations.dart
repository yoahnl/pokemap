import 'package:map_core/map_core.dart';

enum ImagePuzzleOutcome { solved, quit }

enum ImagePuzzleFailure {
  notStarted,
  definitionChanged,
  invalidSeed,
  invalidPiece,
  invalidSlot,
  occupiedSlot,
  fixedPiece,
  rotationDisabled,
  resetDisabled,
  unsolved,
}

final class ImagePuzzleOperationResult {
  const ImagePuzzleOperationResult(
      {required this.state, this.failure, this.outcome});

  final GameState state;
  final ImagePuzzleFailure? failure;
  final ImagePuzzleOutcome? outcome;
  bool get succeeded => failure == null;
}

final class ImagePuzzleOperations {
  const ImagePuzzleOperations();

  ImagePuzzleOperationResult open(
    GameState state, {
    required ImagePuzzleDefinition definition,
    required int seed,
  }) {
    final progress = state.imagePuzzleState.puzzlesById[definition.puzzleId];
    if (progress != null) {
      return ImagePuzzleOperationResult(
          state: state,
          failure: progress.definition.fingerprint == definition.fingerprint
              ? null
              : ImagePuzzleFailure.definitionChanged);
    }
    if (!_validSeed(seed)) {
      return _failure(state, ImagePuzzleFailure.invalidSeed);
    }
    return _replace(state, _initialize(definition, seed));
  }

  ImagePuzzleOperationResult move(
    GameState state, {
    required ImagePuzzleDefinition definition,
    required int pieceId,
    required int targetSlot,
  }) {
    final failure = _check(state, definition, pieceId: pieceId);
    if (failure != null) {
      return _failure(state, failure);
    }
    if (targetSlot < 0 || targetSlot >= definition.slotCount) {
      return _failure(state, ImagePuzzleFailure.invalidSlot);
    }
    final progress = state.imagePuzzleState.puzzlesById[definition.puzzleId]!;
    final current = progress.pieces[pieceId];
    if (current.slot == targetSlot) {
      return ImagePuzzleOperationResult(state: state);
    }
    final displaced =
        progress.pieces.where((piece) => piece.slot == targetSlot).firstOrNull;
    if (displaced != null &&
        definition.fixedPieceIds.contains(displaced.pieceId)) {
      return _failure(state, ImagePuzzleFailure.fixedPiece);
    }
    if (displaced != null && !definition.allowSwap) {
      return _failure(state, ImagePuzzleFailure.occupiedSlot);
    }
    return _replace(
        state,
        ImagePuzzleProgress(definition: progress.definition, pieces: [
          for (final piece in progress.pieces)
            piece.pieceId == pieceId
                ? ImagePuzzlePiece(
                    pieceId: pieceId,
                    slot: targetSlot,
                    quarterTurns: piece.quarterTurns)
                : piece.pieceId == displaced?.pieceId
                    ? ImagePuzzlePiece(
                        pieceId: piece.pieceId,
                        slot: current.slot,
                        quarterTurns: piece.quarterTurns)
                    : piece,
        ]));
  }

  ImagePuzzleOperationResult rotate(
    GameState state, {
    required ImagePuzzleDefinition definition,
    required int pieceId,
  }) {
    final failure = _check(state, definition, pieceId: pieceId);
    if (failure != null) {
      return _failure(state, failure);
    }
    if (definition.allowedQuarterTurns.length == 1) {
      return _failure(state, ImagePuzzleFailure.rotationDisabled);
    }
    final progress = state.imagePuzzleState.puzzlesById[definition.puzzleId]!;
    final current = progress.pieces[pieceId];
    final angleIndex =
        definition.allowedQuarterTurns.indexOf(current.quarterTurns);
    final nextAngle = definition.allowedQuarterTurns[
        (angleIndex + 1) % definition.allowedQuarterTurns.length];
    return _replace(
        state,
        ImagePuzzleProgress(definition: progress.definition, pieces: [
          for (final piece in progress.pieces)
            piece.pieceId == pieceId
                ? ImagePuzzlePiece(
                    pieceId: pieceId, slot: piece.slot, quarterTurns: nextAngle)
                : piece,
        ]));
  }

  ImagePuzzleOperationResult reset(
    GameState state, {
    required ImagePuzzleDefinition definition,
    required int seed,
  }) {
    final failure = _check(state, definition);
    if (failure != null) {
      return _failure(state, failure);
    }
    if (!definition.allowReset) {
      return _failure(state, ImagePuzzleFailure.resetDisabled);
    }
    if (!_validSeed(seed)) {
      return _failure(state, ImagePuzzleFailure.invalidSeed);
    }
    return _replace(state, _initialize(definition, seed));
  }

  ImagePuzzleOperationResult complete(
    GameState state, {
    required ImagePuzzleDefinition definition,
  }) {
    final failure = _check(state, definition);
    if (failure != null) {
      return _failure(state, failure);
    }
    if (!state.imagePuzzleState.puzzlesById[definition.puzzleId]!.isSolved) {
      return _failure(state, ImagePuzzleFailure.unsolved);
    }
    return ImagePuzzleOperationResult(
        state: state, outcome: ImagePuzzleOutcome.solved);
  }

  ImagePuzzleOperationResult quit(
    GameState state, {
    required ImagePuzzleDefinition definition,
  }) {
    final failure = _check(state, definition);
    if (failure != null) {
      return _failure(state, failure);
    }
    return ImagePuzzleOperationResult(
        state: state, outcome: ImagePuzzleOutcome.quit);
  }

  ImagePuzzleFailure? _check(GameState state, ImagePuzzleDefinition definition,
      {int? pieceId}) {
    final progress = state.imagePuzzleState.puzzlesById[definition.puzzleId];
    if (progress == null) {
      return ImagePuzzleFailure.notStarted;
    }
    if (progress.definition.fingerprint != definition.fingerprint) {
      return ImagePuzzleFailure.definitionChanged;
    }
    if (pieceId != null) {
      if (pieceId < 0 || pieceId >= definition.pieceCount) {
        return ImagePuzzleFailure.invalidPiece;
      }
      if (definition.fixedPieceIds.contains(pieceId)) {
        return ImagePuzzleFailure.fixedPiece;
      }
    }
    return null;
  }

  ImagePuzzleOperationResult _failure(
          GameState state, ImagePuzzleFailure failure) =>
      ImagePuzzleOperationResult(state: state, failure: failure);

  ImagePuzzleOperationResult _replace(
          GameState state, ImagePuzzleProgress progress) =>
      ImagePuzzleOperationResult(
          state: state.copyWith(
              imagePuzzleState: state.imagePuzzleState.withProgress(progress)));

  bool _validSeed(int seed) => seed >= 0 && seed <= 0xffffffff;

  ImagePuzzleProgress _initialize(ImagePuzzleDefinition definition, int seed) {
    final authored = definition.initialPieces;
    if (authored != null) {
      return ImagePuzzleProgress(definition: definition, pieces: authored);
    }
    var randomState = seed;
    int next(int bound) {
      randomState = (randomState * 1664525 + 1013904223) & 0xffffffff;
      return randomState % bound;
    }

    final slots = [
      for (var slot = 0; slot < definition.slotCount; slot++)
        if (!definition.fixedPieceIds.contains(slot)) slot
    ];
    for (var index = slots.length - 1; index > 0; index--) {
      final other = next(index + 1);
      final held = slots[index];
      slots[index] = slots[other];
      slots[other] = held;
    }
    var slotIndex = 0;
    final pieces = [
      for (var id = 0; id < definition.pieceCount; id++)
        definition.fixedPieceIds.contains(id)
            ? ImagePuzzlePiece(pieceId: id, slot: id)
            : ImagePuzzlePiece(
                pieceId: id,
                slot: slots[slotIndex++],
                quarterTurns: definition.allowedQuarterTurns[
                    next(definition.allowedQuarterTurns.length)])
    ];
    var progress = ImagePuzzleProgress(definition: definition, pieces: pieces);
    if (!progress.isSolved) {
      return progress;
    }
    final movable = pieces.firstWhere(
        (piece) => !definition.fixedPieceIds.contains(piece.pieceId));
    if (definition.allowedQuarterTurns.length > 1) {
      pieces[movable.pieceId] = ImagePuzzlePiece(
          pieceId: movable.pieceId,
          slot: movable.slot,
          quarterTurns: definition.allowedQuarterTurns[1]);
    } else {
      final otherSlot = slots.firstWhere((slot) => slot != movable.slot);
      final displaced =
          pieces.where((piece) => piece.slot == otherSlot).firstOrNull;
      pieces[movable.pieceId] =
          ImagePuzzlePiece(pieceId: movable.pieceId, slot: otherSlot);
      if (displaced != null) {
        pieces[displaced.pieceId] =
            ImagePuzzlePiece(pieceId: displaced.pieceId, slot: movable.slot);
      }
    }
    progress = ImagePuzzleProgress(definition: definition, pieces: pieces);
    return progress;
  }
}

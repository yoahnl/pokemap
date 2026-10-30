part of 'player_service_runtime_controller.dart';

extension RuntimeImagePuzzleService on PlayerServiceRuntimeController {
  Future<PlayerServiceRuntimeResult> openImagePuzzle({
    required OpenImagePuzzleService request,
  }) async {
    if (_disposed) {
      return PlayerServiceRuntimeResult.failed(
        StateError('Player service disposed.'),
      );
    }
    if (_commitImagePuzzleAndSave == null) {
      return const PlayerServiceRuntimeResult.unavailable(
        'Ce puzzle nécessite une sauvegarde durable fournie par le Player.',
      );
    }
    if (_active || _pauseBagMutationBusy) {
      return const PlayerServiceRuntimeResult.busy();
    }
    final initial = _currentGameState();
    final denied = _worldRequestUnavailableReason(request, initial);
    if (denied != null) return PlayerServiceRuntimeResult.unavailable(denied);
    final session = _RuntimeImagePuzzleSession(request, initial);
    _imagePuzzleSession = session;
    _active = true;
    try {
      _setInputLocked(true);
      Future<RuntimeImagePuzzleBitmap> load() async {
        final loader = _loadImagePuzzleBitmap;
        if (loader != null) return loader(request.definition.imageResourceId);
        final root = _projectRootDirectory;
        if (root == null) {
          throw StateError('La médiathèque du projet est indisponible.');
        }
        final bitmap = await WorldPresentationImageLoader(root)
            .loadBitmap(request.definition.imageResourceId);
        return RuntimeImagePuzzleBitmap(
          bytes: bitmap.$1,
          width: bitmap.$2,
          height: bitmap.$3,
        );
      }

      session.bitmap = await Future.any<RuntimeImagePuzzleBitmap?>([
        load(),
        session.result.future.then((_) => null),
      ]);
      if (!_puzzleContinues(session)) return await session.result.future;
      if (session.bitmap!.width < request.definition.columns ||
          session.bitmap!.height < request.definition.rows) {
        throw StateError(
          'L’image doit avoir au moins un pixel par case du puzzle.',
        );
      }
      final current = _currentGameState();
      if (!sameImagePuzzleCheckpointFields(current, initial)) {
        throw StateError(
          'Le puzzle a changé pendant son ouverture. Rouvrez-le.',
        );
      }
      final opened = const ImagePuzzleOperations().open(
        current,
        definition: request.definition,
        seed: _puzzleSeed(),
      );
      if (!opened.succeeded) {
        throw StateError(
          'La définition de ce puzzle a changé. Restaurez sa configuration d’origine.',
        );
      }
      session.hasDurableState =
          opened.state.imagePuzzleState == current.imagePuzzleState;
      session.observedState = opened.state;
      if (opened.state.imagePuzzleState != current.imagePuzzleState) {
        session.observedState = current;
        await _persistPuzzle(session, opened.state);
      }
      if (_puzzleContinues(session)) _publishPuzzle(session);
      return await session.result.future;
    } catch (error) {
      return PlayerServiceRuntimeResult.failed(error);
    } finally {
      if (identical(_imagePuzzleSession, session)) {
        _imagePuzzleSession = null;
        _publishWorldService(null);
      }
      _setInputLocked(false);
      _active = false;
    }
  }

  int _puzzleSeed() => _civilNow().microsecondsSinceEpoch & 0xffffffff;

  bool _puzzleContinues(_RuntimeImagePuzzleSession session) =>
      !_disposed &&
      identical(_imagePuzzleSession, session) &&
      !session.result.isCompleted;

  void _publishPuzzle(
    _RuntimeImagePuzzleSession session, {
    bool applying = false,
  }) {
    if (!_puzzleContinues(session)) return;
    final progress = session
        .observedState
        .imagePuzzleState
        .puzzlesById[session.request.definition.puzzleId];
    if (progress == null || session.bitmap == null) return;
    _imagePuzzleRevision =
        ((_worldServiceSnapshot?.revision ?? -1) > _imagePuzzleRevision
            ? _worldServiceSnapshot!.revision
            : _imagePuzzleRevision) +
        1;
    _publishWorldService(
      RuntimeWorldServiceSnapshot(
        revision: _imagePuzzleRevision,
        request: session.request,
        stage: applying
            ? RuntimeWorldServiceStage.applying
            : RuntimeWorldServiceStage.active,
        content: RuntimeImagePuzzleServiceContent(
          progress: progress,
          bitmap: session.bitmap!,
          selectedPieceId: session.selectedPieceId,
          message: session.message,
        ),
        actions: applying
            ? const []
            : [
                for (final action in [
                  RuntimeWorldServiceAction.select,
                  RuntimeWorldServiceAction.move,
                  RuntimeWorldServiceAction.confirm,
                  RuntimeWorldServiceAction.cancel,
                  RuntimeWorldServiceAction.close,
                  if (progress.definition.allowedQuarterTurns.length > 1)
                    RuntimeWorldServiceAction.rotate,
                  if (progress.definition.allowReset)
                    RuntimeWorldServiceAction.reset,
                ])
                  RuntimeWorldServiceActionAvailability.enabled(action),
              ],
      ),
    );
  }

  Future<void> _persistPuzzle(
    _RuntimeImagePuzzleSession session,
    GameState next, {
    ImagePuzzleOutcome? outcome,
  }) async {
    session.pendingState = next;
    session.pendingOutcome = outcome;
    _publishPuzzle(session, applying: true);
    final pending = Future<void>.sync(() => _commitImagePuzzleAndSave!(next));
    session.pendingCommit = pending;
    try {
      await pending;
      session.observedState = next;
      session.hasDurableState = true;
    } finally {
      session.pendingCommit = null;
    }
  }

  Future<RuntimeWorldServiceCommandResult> _dispatchImagePuzzle(
    _RuntimeImagePuzzleSession session,
    RuntimeWorldServiceCommand command,
  ) async {
    const accepted = RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
    if (!_puzzleContinues(session) || session.pendingCommit != null) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
      );
    }
    final current = _currentGameState();
    if (!sameImagePuzzleCheckpointFields(current, session.observedState)) {
      if (command.action == RuntimeWorldServiceAction.cancel ||
          command.action == RuntimeWorldServiceAction.close) {
        session.result.complete(
          PlayerServiceRuntimeResult.imagePuzzle(
            current,
            ImagePuzzleOutcome.quit,
          ),
        );
        return accepted;
      }
      session.message =
          'Le puzzle a changé. Fermez cette interaction et rouvrez-la.';
      _publishPuzzle(session);
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: session.message,
      );
    }
    final definition = session.request.definition;
    final id = int.tryParse(command.targetId ?? '') ?? session.selectedPieceId;
    if (command.action == RuntimeWorldServiceAction.select) {
      if (id == null ||
          id < 0 ||
          id >= definition.pieceCount ||
          definition.fixedPieceIds.contains(id)) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
        );
      }
      session.selectedPieceId = id;
      session.message = null;
      _publishPuzzle(session);
      return accepted;
    }
    const operations = ImagePuzzleOperations();
    final result = switch (command.action) {
      RuntimeWorldServiceAction.move => operations.move(
        current,
        definition: definition,
        pieceId: id ?? -1,
        targetSlot: int.tryParse(command.secondaryTargetId ?? '') ?? -1,
      ),
      RuntimeWorldServiceAction.rotate => operations.rotate(
        current,
        definition: definition,
        pieceId: id ?? -1,
      ),
      RuntimeWorldServiceAction.reset => operations.reset(
        current,
        definition: definition,
        seed: _puzzleSeed(),
      ),
      RuntimeWorldServiceAction.confirm => operations.complete(
        current,
        definition: definition,
      ),
      RuntimeWorldServiceAction.cancel || RuntimeWorldServiceAction.close =>
        operations.quit(current, definition: definition),
      _ => null,
    };
    if (result == null || !result.succeeded) {
      session.message = switch (result?.failure) {
        ImagePuzzleFailure.unsolved => 'L’image n’est pas encore reconstituée. Vérifiez la place et l’orientation des pièces.',
        ImagePuzzleFailure.occupiedSlot =>
          'Déplacez cette pièce vers une case libre ou la réserve.',
        ImagePuzzleFailure.fixedPiece => 'Cette pièce est fixe.',
        _ => 'Cette action n’est pas disponible pour ce puzzle.',
      };
      _publishPuzzle(session);
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: session.message,
      );
    }
    try {
      await _persistPuzzle(session, result.state, outcome: result.outcome);
      session.message = null;
      if (result.outcome case final outcome?) {
        if (!session.result.isCompleted) {
          session.result.complete(
            PlayerServiceRuntimeResult.imagePuzzle(result.state, outcome),
          );
        }
      } else if (_puzzleContinues(session)) {
        if (command.action == RuntimeWorldServiceAction.reset) {
          session.selectedPieceId = null;
        }
        _publishPuzzle(session);
      }
      return accepted;
    } catch (error) {
      session.message = 'La sauvegarde a échoué. Votre dernière disposition sauvegardée est conservée. Réessayez ou quittez.';
      if (_puzzleContinues(session)) _publishPuzzle(session);
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: session.message,
      );
    }
  }

  Future<void> _disposeImagePuzzle() async {
    final session = _imagePuzzleSession;
    if (session == null || session.result.isCompleted) return;
    final pending = session.pendingCommit;
    try {
      if (pending != null) await pending;
      if (!session.result.isCompleted) {
        final state = pending == null
            ? session.observedState
            : session.pendingState!;
        session.result.complete(
          session.hasDurableState || pending != null
              ? PlayerServiceRuntimeResult.imagePuzzle(
                  state,
                  pending == null
                      ? ImagePuzzleOutcome.quit
                      : session.pendingOutcome ?? ImagePuzzleOutcome.quit,
                )
              : const PlayerServiceRuntimeResult.cancelled(),
        );
      }
    } catch (error) {
      if (!session.result.isCompleted) {
        session.result.complete(PlayerServiceRuntimeResult.failed(error));
      }
    }
  }
}

final class _RuntimeImagePuzzleSession {
  _RuntimeImagePuzzleSession(this.request, this.observedState);
  final OpenImagePuzzleService request;
  final result = Completer<PlayerServiceRuntimeResult>();
  GameState observedState;
  RuntimeImagePuzzleBitmap? bitmap;
  int? selectedPieceId;
  String? message;
  bool hasDurableState = false;
  Future<void>? pendingCommit;
  GameState? pendingState;
  ImagePuzzleOutcome? pendingOutcome;
}

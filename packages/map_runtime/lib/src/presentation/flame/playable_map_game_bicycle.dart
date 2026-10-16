part of 'playable_map_game.dart';

extension _PlayableMapBicycle on PlayableMapGame {
  double get _playerStepSeconds =>
      _world.player.movementMode == MovementMode.bicycle
      ? PlayerComponent.kBicycleStepSeconds
      : _sprintPressed
      ? PlayerComponent.kRunStepSeconds
      : PlayerComponent.kDefaultStepSeconds;

  CharacterAnimationState get _playerStepAnimation =>
      _world.player.movementMode == MovementMode.bicycle
      ? CharacterAnimationState.bicycle
      : _sprintPressed
      ? CharacterAnimationState.run
      : CharacterAnimationState.walk;

  Future<bool> _usePlayerBicycle(
    ProjectItemDefinition item,
    GameState expectedState,
  ) async {
    if (_isRemoved ||
        !isLoaded ||
        _bicycleToggleInFlight ||
        _player.isStepping ||
        _activeNarrativeSceneWorkingSession != null ||
        _hasCheckpointUnsafeRuntimeWorkForSave ||
        playerServiceGameStateSnapshot != expectedState ||
        evaluateBicycleToggle(
              map: _bundle.map,
              state: expectedState,
              item: item,
              hasAnimations: _player.hasBicycleAnimations,
            ) !=
            null) {
      return false;
    }
    final lock = _inputLocks.acquire(
      owner: RuntimeInputLockOwner.playerService,
      surface: RuntimeInputSurface.blocked,
    );
    _bicycleToggleInFlight = true;
    _clearPressedMovementControls();
    _sprintPressed = false;
    try {
      await commitAndSavePlayerServiceState(
        expectedState.copyWith(
          playerMovementMode:
              expectedState.playerMovementMode == MovementMode.bicycle
              ? MovementMode.walk
              : MovementMode.bicycle,
        ),
        expectedState: expectedState,
      );
      return !_isRemoved;
    } on Object catch (error) {
      debugPrint('[bicycle] toggle failed: $error');
      return false;
    } finally {
      _bicycleToggleInFlight = false;
      _inputLocks.release(
        owner: RuntimeInputLockOwner.playerService,
        token: lock,
      );
      _publishInputAuthoritySnapshot();
    }
  }
}

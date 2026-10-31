part of 'player_service_runtime_controller.dart';

extension RuntimePeriodicRewardService on PlayerServiceRuntimeController {
  Future<String> claimPeriodicReward({
    required PeriodicItemRewardDefinition definition,
  }) async {
    final persist = _commitPeriodicRewardAndSave;
    if (_disposed || persist == null || _active || _pauseBagMutationBusy) {
      return 'blocked';
    }
    _active = true;
    var locked = false;
    try {
      _setInputLocked(true);
      locked = true;
      final initial = _currentGameState();
      final catalog = await _resolveItemCatalog();
      if (_disposed || _currentGameState() != initial) return 'blocked';
      final observed = observeGameplayCalendar(
        initial,
        localDay: runtimeCivilDay(_civilNow()),
      );
      final claimed = const PeriodicRewardOperations().claim(
        observed,
        definition: definition,
        expectedRewardRevision:
            observed.periodicRewardState
                .claimFor(definition.rewardId)
                ?.revision ??
            0,
        expectedCalendar: observed.gameplayCalendarState,
        itemCatalog: catalog,
        bagCapacity: bagCapacity,
      );
      if (!claimed.isSuccess) {
        return switch (claimed.failure!) {
          PeriodicRewardFailure.alreadyClaimed => 'alreadyClaimed',
          PeriodicRewardFailure.bagFull => 'bagFull',
          _ => 'blocked',
        };
      }
      final committing = Future<void>.sync(() => persist(claimed.state));
      _periodicRewardCommit = committing;
      await committing;
      return 'received';
    } catch (_) {
      return 'blocked';
    } finally {
      _periodicRewardCommit = null;
      if (locked) _setInputLocked(false);
      _active = false;
    }
  }
}

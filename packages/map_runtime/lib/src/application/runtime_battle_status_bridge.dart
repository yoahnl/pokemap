import 'package:map_battle/map_battle.dart';

/// Converts the persisted major-status ids used by player saves at the
/// runtime boundary without dropping a status unsupported by one backend.
final class RuntimeBattleStatusBridge {
  const RuntimeBattleStatusBridge();

  BattleMajorStatusState? toLegacyBattleStatus(String statusId) {
    return switch (statusId.trim()) {
      '' => null,
      'par' => const BattleMajorStatusState.par(),
      'brn' => const BattleMajorStatusState.brn(),
      'psn' => const BattleMajorStatusState.psn(),
      'tox' => const BattleMajorStatusState.tox(),
      'slp' => const BattleMajorStatusState.slp(),
      'frz' => const BattleMajorStatusState.frz(),
      final unknown => throw StateError(
          'Unsupported persisted Pokemon major status: "$unknown".',
        ),
    };
  }

  PsdkBattleMajorStatus? toPsdkBattleStatus(String statusId) {
    return switch (statusId.trim()) {
      '' => null,
      'par' => PsdkBattleMajorStatus.paralysis,
      'brn' => PsdkBattleMajorStatus.burn,
      'psn' => PsdkBattleMajorStatus.poison,
      'tox' => PsdkBattleMajorStatus.toxic,
      'slp' => PsdkBattleMajorStatus.sleep,
      'frz' => PsdkBattleMajorStatus.freeze,
      final unknown => throw StateError(
          'Unsupported persisted Pokemon major status: "$unknown".',
        ),
    };
  }

  String fromLegacyBattleStatus(BattleMajorStatusState? status) {
    return switch (status?.id) {
      null => '',
      BattleMajorStatusId.par => 'par',
      BattleMajorStatusId.brn => 'brn',
      BattleMajorStatusId.psn => 'psn',
      BattleMajorStatusId.tox => 'tox',
      BattleMajorStatusId.slp => 'slp',
      BattleMajorStatusId.frz => 'frz',
    };
  }

  String fromPsdkBattleStatus(PsdkBattleMajorStatus? status) {
    return switch (status) {
      null => '',
      PsdkBattleMajorStatus.paralysis => 'par',
      PsdkBattleMajorStatus.burn => 'brn',
      PsdkBattleMajorStatus.poison => 'psn',
      PsdkBattleMajorStatus.toxic => 'tox',
      PsdkBattleMajorStatus.sleep => 'slp',
      PsdkBattleMajorStatus.freeze => 'frz',
    };
  }

  BattleMajorStatusState? legacyFromPsdkBattleStatus(
    PsdkBattleMajorStatus? status,
  ) {
    return toLegacyBattleStatus(fromPsdkBattleStatus(status));
  }
}

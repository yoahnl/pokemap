import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_battle_status_bridge.dart';

void main() {
  const bridge = RuntimeBattleStatusBridge();

  test('maps every persisted major status to and from both battle backends',
      () {
    final cases = <String, (BattleMajorStatusId, PsdkBattleMajorStatus)>{
      'par': (BattleMajorStatusId.par, PsdkBattleMajorStatus.paralysis),
      'brn': (BattleMajorStatusId.brn, PsdkBattleMajorStatus.burn),
      'psn': (BattleMajorStatusId.psn, PsdkBattleMajorStatus.poison),
      'tox': (BattleMajorStatusId.tox, PsdkBattleMajorStatus.toxic),
      'slp': (BattleMajorStatusId.slp, PsdkBattleMajorStatus.sleep),
      'frz': (BattleMajorStatusId.frz, PsdkBattleMajorStatus.freeze),
    };

    for (final entry in cases.entries) {
      final legacyStatus = bridge.toLegacyBattleStatus(entry.key);
      expect(legacyStatus?.id, entry.value.$1, reason: entry.key);
      expect(bridge.fromLegacyBattleStatus(legacyStatus), entry.key);

      final psdkStatus = bridge.toPsdkBattleStatus(entry.key);
      expect(psdkStatus, entry.value.$2, reason: entry.key);
      expect(bridge.fromPsdkBattleStatus(psdkStatus), entry.key);
    }
  });

  test('maps an empty save status to no battle status and back', () {
    expect(bridge.toLegacyBattleStatus(''), isNull);
    expect(bridge.toPsdkBattleStatus(''), isNull);
    expect(bridge.fromLegacyBattleStatus(null), isEmpty);
    expect(bridge.fromPsdkBattleStatus(null), isEmpty);
  });

  test('rejects an unknown persisted status instead of dropping it', () {
    expect(
      () => bridge.toLegacyBattleStatus('confused'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => bridge.toPsdkBattleStatus('confused'),
      throwsA(isA<StateError>()),
    );
  });
}

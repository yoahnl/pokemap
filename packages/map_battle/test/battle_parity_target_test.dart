import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleParityTarget canonical V1', () {
    test('pins every authored battle-rules axis to an explicit target', () {
      const target = BattleParityTarget.canonicalV1;

      expect(target.version, 1);
      expect(target.profileId, 'pokemap-mainline-hybrid-v1');
      expect(target.axes, hasLength(BattleParityAxis.values.length));
      expect(
        target.axis(BattleParityAxis.damage).ruleId,
        'mainline-gen9-damage',
      );
      expect(
        target.axis(BattleParityAxis.speedTies),
        isA<BattleParityAxisTarget>()
            .having(
              (axis) => axis.ruleId,
              'ruleId',
              'mainline-gen9-seeded-random',
            )
            .having(
              (axis) => axis.alignment,
              'alignment',
              BattleParityAlignment.partial,
            ),
      );
      expect(
        target.axis(BattleParityAxis.experience).alignment,
        BattleParityAlignment.intentionalVariant,
      );
      expect(
        target.axis(BattleParityAxis.capture).alignment,
        BattleParityAlignment.intentionalVariant,
      );
    });

    test('does not promote PSDK counters as player parity evidence', () {
      const target = BattleParityTarget.canonicalV1;

      expect(target.counterPolicy.provesPlayerParity, isFalse);
      expect(
        target.counterPolicy.requiredCompanionProofs,
        <String>['runtimeBridge', 'playerSurface', 'goldenE2E'],
      );

      final json = target.toJson();
      expect(json['version'], 1);
      expect(json['profileId'], 'pokemap-mainline-hybrid-v1');
      expect(json['axes'], hasLength(6));
      expect(
        json['counterPolicy'],
        containsPair('provesPlayerParity', false),
      );
    });

    test('rejects an axis lookup missing from a custom target', () {
      const target = BattleParityTarget(
        version: 1,
        profileId: 'fixture',
        axes: <BattleParityAxisTarget>[],
        counterPolicy: BattleParityCounterPolicy(
          scope: 'fixture',
          provesPlayerParity: false,
          requiredCompanionProofs: <String>[],
        ),
      );

      expect(
        () => target.axis(BattleParityAxis.damage),
        throwsA(isA<StateError>()),
      );
    });
  });
}

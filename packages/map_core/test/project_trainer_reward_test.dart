import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTrainerEntry rewards', () {
    test('legacy JSON defaults to a neutral reward contract', () {
      final trainer = ProjectTrainerEntry.fromJson(const <String, dynamic>{
        'id': 'legacy_trainer',
        'name': 'Legacy Trainer',
        'trainerClass': 'Trainer',
      });

      expect(trainer.moneyReward, 0);
      expect(trainer.rewardItemGrants, isEmpty);
      expect(trainer.rewardFlagIds, isEmpty);
      expect(trainer.rewardBadgeId, isNull);
      expect(trainer.rewardFieldAbilityUnlock, isNull);
      expect(trainer.toJson(), isNot(contains('rewardBadgeId')));
      expect(
        trainer.toJson(),
        isNot(contains('rewardFieldAbilityUnlock')),
      );
    });

    test('typed rewards survive JSON round-trip', () {
      const trainer = ProjectTrainerEntry(
        id: 'rival',
        name: 'Lysa',
        trainerClass: 'Rival',
        moneyReward: 320,
        rewardItemGrants: <ProjectTrainerItemGrant>[
          ProjectTrainerItemGrant(itemId: 'potion', quantity: 2),
        ],
        rewardFlagIds: <String>['rival_defeated'],
        rewardBadgeId: 'tide_badge',
        rewardFieldAbilityUnlock: FieldAbility.surf,
      );

      final restored = ProjectTrainerEntry.fromJson(trainer.toJson());

      expect(restored, trainer);
      expect(restored.rewardBadgeId, 'tide_badge');
      expect(restored.rewardFieldAbilityUnlock, FieldAbility.surf);
    });

    test('rejects fractional money and item quantities instead of truncating',
        () {
      expect(
        () => ProjectTrainerEntry.fromJson(const <String, dynamic>{
          'id': 'fractional_money',
          'name': 'Fractional',
          'trainerClass': 'Trainer',
          'moneyReward': 320.75,
        }),
        throwsFormatException,
      );
      expect(
        () => ProjectTrainerItemGrant.fromJson(const <String, dynamic>{
          'itemId': 'potion',
          'quantity': 1.9,
        }),
        throwsFormatException,
      );
    });

    test('accepts exact integer reward values', () {
      final trainer = ProjectTrainerEntry.fromJson(const <String, dynamic>{
        'id': 'integer_reward',
        'name': 'Integer',
        'trainerClass': 'Trainer',
        'moneyReward': 320,
        'rewardItemGrants': <Map<String, dynamic>>[
          <String, dynamic>{'itemId': 'potion', 'quantity': 2},
        ],
      });

      expect(trainer.moneyReward, 320);
      expect(trainer.rewardItemGrants.single.quantity, 2);
    });

    test('rejects explicit null while preserving absent legacy defaults', () {
      expect(
        () => ProjectTrainerEntry.fromJson(const <String, dynamic>{
          'id': 'null_money',
          'name': 'Null Money',
          'trainerClass': 'Trainer',
          'moneyReward': null,
        }),
        throwsFormatException,
      );
      expect(
        () => ProjectTrainerItemGrant.fromJson(const <String, dynamic>{
          'itemId': 'potion',
          'quantity': null,
        }),
        throwsFormatException,
      );

      final legacyTrainer = ProjectTrainerEntry.fromJson(
        const <String, dynamic>{
          'id': 'missing_money',
          'name': 'Missing Money',
          'trainerClass': 'Trainer',
        },
      );
      final legacyItem = ProjectTrainerItemGrant.fromJson(
        const <String, dynamic>{'itemId': 'potion'},
      );
      expect(legacyTrainer.moneyReward, 0);
      expect(legacyItem.quantity, 1);
    });
  });
}

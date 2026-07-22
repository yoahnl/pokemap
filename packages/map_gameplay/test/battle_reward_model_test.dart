import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('BattleReward', () {
    test('keeps typed rewards immutable and normalizes idempotent flags', () {
      final reward = BattleReward(
        sourceKind: BattleRewardSourceKind.wild,
        experienceGrants: const <BattleExperienceGrant>[
          BattleExperienceGrant(partySlot: 2, experience: 64),
          BattleExperienceGrant(partySlot: 0, experience: 32),
        ],
        money: 120,
        itemGrants: const <BattleRewardItemGrant>[
          BattleRewardItemGrant(itemId: ' potion ', quantity: 2),
        ],
        flagIds: const <String>[' rival_defeated ', 'rival_defeated'],
        badgeId: ' tide_badge ',
        fieldAbilityUnlock: FieldAbility.surf,
      );

      expect(
        reward.experienceGrants,
        const <BattleExperienceGrant>[
          BattleExperienceGrant(partySlot: 0, experience: 32),
          BattleExperienceGrant(partySlot: 2, experience: 64),
        ],
      );
      expect(
        reward.itemGrants,
        const <BattleRewardItemGrant>[
          BattleRewardItemGrant(itemId: 'potion', quantity: 2),
        ],
      );
      expect(reward.flagIds, const <String>['rival_defeated']);
      expect(reward.badgeId, 'tide_badge');
      expect(reward.fieldAbilityUnlock, FieldAbility.surf);
      expect(reward.sourceKind, BattleRewardSourceKind.wild);
      expect(reward.trainerId, isNull);
      expect(() => reward.flagIds.add('mutable'), throwsUnsupportedError);
    });

    test('trainer without rewards is neutral', () {
      final reward = BattleReward(
        sourceKind: BattleRewardSourceKind.trainer,
        trainerId: ' rival ',
      );

      expect(reward.sourceKind, BattleRewardSourceKind.trainer);
      expect(reward.trainerId, 'rival');
      expect(reward.experienceGrants, isEmpty);
      expect(reward.money, 0);
      expect(reward.itemGrants, isEmpty);
      expect(reward.flagIds, isEmpty);
      expect(reward.badgeId, isNull);
      expect(reward.fieldAbilityUnlock, isNull);
      expect(reward.isEmpty, isTrue);
    });

    test('rejects duplicate slots and structurally invalid grants', () {
      expect(
        () => BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          experienceGrants: const <BattleExperienceGrant>[
            BattleExperienceGrant(partySlot: 1, experience: 10),
            BattleExperienceGrant(partySlot: 1, experience: 20),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => const BattleExperienceGrant(partySlot: -1, experience: 10)
            .validated(),
        throwsArgumentError,
      );
      expect(
        () => const BattleExperienceGrant(partySlot: 0, experience: -1)
            .validated(),
        throwsArgumentError,
      );
      expect(
        () => const BattleRewardItemGrant(itemId: '', quantity: 1).validated(),
        throwsArgumentError,
      );
      expect(
        () => const BattleRewardItemGrant(itemId: 'potion', quantity: 0)
            .validated(),
        throwsArgumentError,
      );
      expect(
        () => BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          money: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          flagIds: const <String>[''],
        ),
        throwsArgumentError,
      );
      expect(
        () => BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          badgeId: '  ',
        ),
        throwsArgumentError,
      );
      expect(
        () => BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          itemGrants: const <BattleRewardItemGrant>[
            BattleRewardItemGrant(itemId: 'potion', quantity: 1),
            BattleRewardItemGrant(itemId: ' potion ', quantity: 2),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('enforces an explicit and coherent battle source identity', () {
      expect(
        () => BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          trainerId: 'rival',
        ),
        throwsArgumentError,
      );
      expect(
        () => BattleReward(sourceKind: BattleRewardSourceKind.trainer),
        throwsArgumentError,
      );
      expect(
        () => BattleReward(
          sourceKind: BattleRewardSourceKind.trainer,
          trainerId: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('uses structural equality and hash codes for reward snapshots', () {
      BattleReward buildReward({int money = 120}) => BattleReward(
            sourceKind: BattleRewardSourceKind.trainer,
            trainerId: 'rival',
            experienceGrants: const <BattleExperienceGrant>[
              BattleExperienceGrant(partySlot: 0, experience: 64),
            ],
            money: money,
            itemGrants: const <BattleRewardItemGrant>[
              BattleRewardItemGrant(itemId: 'potion', quantity: 2),
            ],
            flagIds: const <String>['rival_defeated'],
            badgeId: 'tide_badge',
            fieldAbilityUnlock: FieldAbility.surf,
          );

      final first = buildReward();
      final sameContent = buildReward();
      final differentMoney = buildReward(money: 121);

      expect(first, sameContent);
      expect(first.hashCode, sameContent.hashCode);
      expect(<BattleReward>{first, sameContent}, hasLength(1));
      expect(differentMoney, isNot(first));
    });

    test('canonicalizes item grants before equality and hashing', () {
      BattleReward build(Iterable<BattleRewardItemGrant> itemGrants) =>
          BattleReward(
            sourceKind: BattleRewardSourceKind.wild,
            itemGrants: itemGrants,
          );

      final forward = build(const <BattleRewardItemGrant>[
        BattleRewardItemGrant(itemId: 'poke_ball', quantity: 1),
        BattleRewardItemGrant(itemId: 'potion', quantity: 2),
      ]);
      final reversed = build(const <BattleRewardItemGrant>[
        BattleRewardItemGrant(itemId: 'potion', quantity: 2),
        BattleRewardItemGrant(itemId: 'poke_ball', quantity: 1),
      ]);

      expect(forward.itemGrants.map((grant) => grant.itemId), [
        'poke_ball',
        'potion',
      ]);
      expect(forward, reversed);
      expect(forward.hashCode, reversed.hashCode);
    });
  });
}

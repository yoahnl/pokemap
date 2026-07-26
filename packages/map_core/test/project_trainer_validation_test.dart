import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTrainerEntry validation', () {
    test('rejects battleDifficulty values outside the authored 1..10 range',
        () {
      final manifest = ProjectManifest(
        name: 'trainer_validation_test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'rookie',
            name: 'Rookie',
            trainerClass: 'Trainer',
            battleDifficulty: 11,
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.toString(),
            'message',
            contains('battleDifficulty'),
          ),
        ),
      );
    });

    test('rejects trainer battle background paths that escape the project', () {
      final manifest = ProjectManifest(
        name: 'trainer_validation_test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'rookie',
            name: 'Rookie',
            trainerClass: 'Trainer',
            battleBackgroundRelativePath: '../outside.png',
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.toString(),
            'message',
            contains('battleBackgroundRelativePath'),
          ),
        ),
      );
    });

    final invalidRewards = <String, ProjectTrainerEntry>{
      'negative moneyReward': const ProjectTrainerEntry(
        id: 'rookie',
        name: 'Rookie',
        trainerClass: 'Trainer',
        moneyReward: -1,
      ),
      'non-positive item quantity': const ProjectTrainerEntry(
        id: 'rookie',
        name: 'Rookie',
        trainerClass: 'Trainer',
        rewardItemGrants: <ProjectTrainerItemGrant>[
          ProjectTrainerItemGrant(itemId: 'potion', quantity: 0),
        ],
      ),
      'empty item id': const ProjectTrainerEntry(
        id: 'rookie',
        name: 'Rookie',
        trainerClass: 'Trainer',
        rewardItemGrants: <ProjectTrainerItemGrant>[
          ProjectTrainerItemGrant(itemId: '  ', quantity: 1),
        ],
      ),
      'duplicate item ids': const ProjectTrainerEntry(
        id: 'rookie',
        name: 'Rookie',
        trainerClass: 'Trainer',
        rewardItemGrants: <ProjectTrainerItemGrant>[
          ProjectTrainerItemGrant(itemId: 'potion', quantity: 1),
          ProjectTrainerItemGrant(itemId: ' potion ', quantity: 2),
        ],
      ),
      'duplicate flag ids': const ProjectTrainerEntry(
        id: 'rookie',
        name: 'Rookie',
        trainerClass: 'Trainer',
        rewardFlagIds: <String>['victory', ' victory '],
      ),
      'empty flag id': const ProjectTrainerEntry(
        id: 'rookie',
        name: 'Rookie',
        trainerClass: 'Trainer',
        rewardFlagIds: <String>[''],
      ),
      'empty badge id': const ProjectTrainerEntry(
        id: 'rookie',
        name: 'Rookie',
        trainerClass: 'Trainer',
        rewardBadgeId: ' ',
      ),
    };
    for (final invalidReward in invalidRewards.entries) {
      test('rejects ${invalidReward.key}', () {
        final manifest = ProjectManifest(
          name: 'trainer_reward_validation_test',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          trainers: <ProjectTrainerEntry>[invalidReward.value],
          surfaceCatalog: ProjectSurfaceCatalog(),
        );

        expect(
          () => ProjectValidator.validate(manifest),
          throwsA(isA<ValidationException>()),
        );
      });
    }

    test('rejects a reward badge that is absent from the project manifest', () {
      final manifest = ProjectManifest(
        name: 'trainer_reward_badge_validation_test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
            rewardBadgeId: 'tide_badge',
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.toString(),
            'message',
            contains('rewardBadgeId'),
          ),
        ),
      );
    });
  });
}

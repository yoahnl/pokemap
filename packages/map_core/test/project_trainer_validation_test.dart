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
  });
}

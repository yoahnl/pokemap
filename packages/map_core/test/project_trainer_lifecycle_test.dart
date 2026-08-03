import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTrainerEntry lifecycle', () {
    test('legacy JSON keeps one-shot trainer defaults without new keys', () {
      final trainer = ProjectTrainerEntry.fromJson(const <String, dynamic>{
        'id': 'legacy',
        'name': 'Legacy',
        'trainerClass': 'Trainer',
      });

      expect(trainer.templateKind, isNull);
      expect(trainer.rematchPolicy, isNull);
      expect(trainer.preBattleDialogueId, isNull);
      expect(trainer.victoryDialogueId, isNull);
      expect(trainer.defeatDialogueId, isNull);
      expect(trainer.toJson(), isNot(contains('templateKind')));
      expect(trainer.toJson(), isNot(contains('rematchPolicy')));
      expect(trainer.toJson(), isNot(contains('preBattleDialogueId')));
      expect(trainer.toJson(), isNot(contains('victoryDialogueId')));
      expect(trainer.toJson(), isNot(contains('defeatDialogueId')));
    });

    test('typed lifecycle survives JSON round-trip', () {
      const trainer = ProjectTrainerEntry(
        id: 'rival',
        name: 'Lysa',
        trainerClass: 'Rival',
        templateKind: ProjectTrainerTemplateKind.rival,
        rematchPolicy: ProjectTrainerRematchPolicy.allowed,
        preBattleDialogueId: 'lysa_before',
        victoryDialogueId: 'lysa_victory',
        defeatDialogueId: 'lysa_defeat',
        rewardFlagIds: <String>['story:lysa_follow_up'],
      );

      expect(ProjectTrainerEntry.fromJson(trainer.toJson()), trainer);
    });

    test('rejects unknown lifecycle dialogue references', () {
      final manifest = _project(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
            preBattleDialogueId: 'missing_dialogue',
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.toString(),
            'message',
            contains('preBattleDialogueId'),
          ),
        ),
      );
    });

    test('gym template requires a badge and victory dialogue', () {
      final manifest = _project(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
            templateKind: ProjectTrainerTemplateKind.gymLeader,
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rival template requires follow-up flags and victory dialogue', () {
      final manifest = _project(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'lysa',
            name: 'Lysa',
            trainerClass: 'Rival',
            templateKind: ProjectTrainerTemplateKind.rival,
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectManifest _project({
  required List<ProjectTrainerEntry> trainers,
}) {
  return ProjectManifest(
    name: 'trainer_lifecycle_test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'lysa_before',
        name: 'Lysa before',
        relativePath: 'dialogues/lysa_before.yarn',
      ),
      ProjectDialogueEntry(
        id: 'lysa_victory',
        name: 'Lysa victory',
        relativePath: 'dialogues/lysa_victory.yarn',
      ),
      ProjectDialogueEntry(
        id: 'lysa_defeat',
        name: 'Lysa defeat',
        relativePath: 'dialogues/lysa_defeat.yarn',
      ),
    ],
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/trainer_field_update.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/trainer_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  late _FakeProjectRepository repository;
  const workspace = _FakeWorkspace();

  setUp(() {
    repository = _FakeProjectRepository();
  });

  group('trainer use cases', () {
    test(
      'create trainer keeps battleDifficulty null when no explicit value is authored',
      () async {
        final useCase = CreateTrainerUseCase(repository);

        final updated = await useCase.execute(
          workspace,
          _project(),
          name: '  Brock  ',
          trainerClass: '  Gym Leader  ',
        );

        final trainer = updated.trainers.single;
        expect(trainer.id, 'brock');
        expect(trainer.battleDifficulty, isNull);
      },
    );

    test('create trainer trims optional refs and normalizes tags', () async {
      final useCase = CreateTrainerUseCase(repository);

      final updated = await useCase.execute(
        workspace,
        _project(),
        name: '  Misty  ',
        trainerClass: '  Gym Leader  ',
        battleDifficulty: 7,
        battleBackgroundRelativePath: r' assets\battle_backgrounds\misty.png ',
        battleSpriteRelativePath: r' assets\trainers\misty_battle.png ',
        battleTransitionId: ' hgss_trainer ',
        battleMusicPath: ' battle_theme ',
        victoryMusicPath: ' victory_theme ',
        tags: <String>[' rival ', ' ', ' gym '],
      );

      final trainer = updated.trainers.single;
      expect(trainer.id, 'misty');
      expect(trainer.name, 'Misty');
      expect(trainer.trainerClass, 'Gym Leader');
      expect(trainer.battleDifficulty, 7);
      expect(
        trainer.battleBackgroundRelativePath,
        'assets/battle_backgrounds/misty.png',
      );
      expect(
        trainer.battleSpriteRelativePath,
        'assets/trainers/misty_battle.png',
        reason:
            'BETA-BAT-017 : le sprite du dresseur vaincu suit le même '
            'contrat de chemin relatif normalisé que le fond',
      );
      expect(
        trainer.battleTransitionId,
        'hgss_trainer',
        reason:
            'BETA-BAT-019 : la transition authorée du dresseur est '
            'normalisée et persistée',
      );
      expect(trainer.battleMusicPath, 'battle_theme');
      expect(trainer.victoryMusicPath, 'victory_theme');
      expect(trainer.tags, <String>['rival', 'gym']);
      expect(repository.savedProjects.single.trainers.single.name, 'Misty');
    });

    test(
      'create and update trainer author complete normalized rewards',
      () async {
        final createUseCase = CreateTrainerUseCase(repository);
        final updateUseCase = UpdateTrainerUseCase(repository);

        final created = await createUseCase.execute(
          workspace,
          _project(
            badges: const <BadgeDefinition>[
              BadgeDefinition(id: 'tide_badge', label: 'Badge Marée'),
            ],
          ),
          name: '  Misty  ',
          trainerClass: '  Gym Leader  ',
          moneyReward: 640,
          rewardItemGrants: const <ProjectTrainerItemGrant>[
            ProjectTrainerItemGrant(itemId: ' potion ', quantity: 2),
          ],
          rewardFlagIds: const <String>[' story:misty_won ', ' '],
          rewardBadgeId: ' tide_badge ',
          rewardFieldAbilityUnlock: FieldAbility.surf,
        );

        final trainer = created.trainers.single;
        expect(trainer.moneyReward, 640);
        expect(trainer.rewardItemGrants, const <ProjectTrainerItemGrant>[
          ProjectTrainerItemGrant(itemId: 'potion', quantity: 2),
        ]);
        expect(trainer.rewardFlagIds, const <String>['story:misty_won']);
        expect(trainer.rewardBadgeId, 'tide_badge');
        expect(trainer.rewardFieldAbilityUnlock, FieldAbility.surf);

        final cleared = await updateUseCase.execute(
          workspace,
          created,
          trainerId: trainer.id,
          moneyReward: 0,
          rewardItemGrants: const <ProjectTrainerItemGrant>[],
          rewardFlagIds: const <String>[],
          rewardBadgeId: const TrainerFieldUpdate<String>.set(null),
          rewardFieldAbilityUnlock: const TrainerFieldUpdate<FieldAbility>.set(
            null,
          ),
        );

        final clearedTrainer = cleared.trainers.single;
        expect(clearedTrainer.moneyReward, 0);
        expect(clearedTrainer.rewardItemGrants, isEmpty);
        expect(clearedTrainer.rewardFlagIds, isEmpty);
        expect(clearedTrainer.rewardBadgeId, isNull);
        expect(clearedTrainer.rewardFieldAbilityUnlock, isNull);
      },
    );

    test(
      'create and update trainer author lifecycle templates without raw ids',
      () async {
        final createUseCase = CreateTrainerUseCase(repository);
        final updateUseCase = UpdateTrainerUseCase(repository);
        final project = _project(
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'rival_before',
              name: 'Rival · avant combat',
              relativePath: 'dialogues/rival_before.yarn',
            ),
            ProjectDialogueEntry(
              id: 'rival_victory',
              name: 'Rival · victoire',
              relativePath: 'dialogues/rival_victory.yarn',
            ),
            ProjectDialogueEntry(
              id: 'rival_defeat',
              name: 'Rival · défaite joueur',
              relativePath: 'dialogues/rival_defeat.yarn',
            ),
          ],
        );

        final created = await createUseCase.execute(
          workspace,
          project,
          name: '  Lysa  ',
          trainerClass: '  Rival  ',
          templateKind: ProjectTrainerTemplateKind.rival,
          rematchPolicy: ProjectTrainerRematchPolicy.allowed,
          preBattleDialogueId: ' rival_before ',
          victoryDialogueId: ' rival_victory ',
          defeatDialogueId: ' rival_defeat ',
          rewardFlagIds: const <String>[' story:lysa_follow_up '],
        );

        final trainer = created.trainers.single;
        expect(trainer.templateKind, ProjectTrainerTemplateKind.rival);
        expect(trainer.rematchPolicy, ProjectTrainerRematchPolicy.allowed);
        expect(trainer.preBattleDialogueId, 'rival_before');
        expect(trainer.victoryDialogueId, 'rival_victory');
        expect(trainer.defeatDialogueId, 'rival_defeat');

        final cleared = await updateUseCase.execute(
          workspace,
          created,
          trainerId: trainer.id,
          templateKind:
              const TrainerFieldUpdate<ProjectTrainerTemplateKind>.set(null),
          rematchPolicy:
              const TrainerFieldUpdate<ProjectTrainerRematchPolicy>.set(null),
          preBattleDialogueId: const TrainerFieldUpdate<String>.set(null),
          victoryDialogueId: const TrainerFieldUpdate<String>.set(''),
          defeatDialogueId: const TrainerFieldUpdate<String>.set(null),
          rewardFlagIds: const <String>[],
        );

        final clearedTrainer = cleared.trainers.single;
        expect(clearedTrainer.templateKind, isNull);
        expect(clearedTrainer.rematchPolicy, isNull);
        expect(clearedTrainer.preBattleDialogueId, isNull);
        expect(clearedTrainer.victoryDialogueId, isNull);
        expect(clearedTrainer.defeatDialogueId, isNull);
      },
    );

    test(
      'update trainer can author and clear difficulty/background fields',
      () async {
        final useCase = UpdateTrainerUseCase(repository);

        final updated = await useCase.execute(
          workspace,
          _project(
            elements: const <ProjectElementEntry>[
              ProjectElementEntry(
                id: 'misty_portrait',
                name: 'Misty Portrait',
                tilesetId: 'tileset_1',
                categoryId: 'portraits',
                frames: <TilesetVisualFrame>[
                  TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                ],
              ),
            ],
            characters: const <ProjectCharacterEntry>[
              ProjectCharacterEntry(
                id: 'misty_character',
                name: 'Misty Character',
                tilesetId: 'tileset_1',
              ),
            ],
            trainers: const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: 'misty',
                name: 'Misty',
                trainerClass: 'Gym Leader',
              ),
            ],
          ),
          trainerId: 'misty',
          battleDifficulty: const TrainerFieldUpdate<int>.set(9),
          battleBackgroundRelativePath: const TrainerFieldUpdate<String>.set(
            'assets/battle_backgrounds/misty_evening.png',
          ),
          battleSpriteRelativePath: const TrainerFieldUpdate<String>.set(
            'assets/trainers/misty_battle.png',
          ),
          battleTransitionId: const TrainerFieldUpdate<String>.set(
            'dpp_trainer',
          ),
        );

        final authoredTrainer = updated.trainers.single;
        expect(authoredTrainer.battleDifficulty, 9);
        expect(
          authoredTrainer.battleBackgroundRelativePath,
          'assets/battle_backgrounds/misty_evening.png',
        );
        expect(
          authoredTrainer.battleSpriteRelativePath,
          'assets/trainers/misty_battle.png',
        );
        expect(authoredTrainer.battleTransitionId, 'dpp_trainer');

        final cleared = await useCase.execute(
          workspace,
          updated,
          trainerId: 'misty',
          battleDifficulty: const TrainerFieldUpdate<int>.set(null),
          battleBackgroundRelativePath: const TrainerFieldUpdate<String>.set(
            '',
          ),
          battleSpriteRelativePath: const TrainerFieldUpdate<String>.set(''),
          battleTransitionId: const TrainerFieldUpdate<String>.set(''),
        );

        final clearedTrainer = cleared.trainers.single;
        expect(clearedTrainer.battleDifficulty, isNull);
        expect(clearedTrainer.battleBackgroundRelativePath, isNull);
        expect(clearedTrainer.battleSpriteRelativePath, isNull);
        expect(clearedTrainer.battleTransitionId, isNull);
      },
    );

    test(
      'update trainer keeps unrelated optional trainer fields stable',
      () async {
        final useCase = UpdateTrainerUseCase(repository);

        final updated = await useCase.execute(
          workspace,
          _project(
            elements: const <ProjectElementEntry>[
              ProjectElementEntry(
                id: 'misty_portrait',
                name: 'Misty Portrait',
                tilesetId: 'tileset_1',
                categoryId: 'portraits',
                frames: <TilesetVisualFrame>[
                  TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                ],
              ),
            ],
            characters: const <ProjectCharacterEntry>[
              ProjectCharacterEntry(
                id: 'misty_character',
                name: 'Misty Character',
                tilesetId: 'tileset_1',
              ),
            ],
            trainers: const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: 'misty',
                name: 'Misty',
                trainerClass: 'Gym Leader',
                battleDifficulty: 8,
                battleBackgroundRelativePath:
                    'assets/battle_backgrounds/misty.png',
                characterId: 'misty_character',
                portraitElementId: 'misty_portrait',
                battleMusicPath: 'misty_theme',
                victoryMusicPath: 'misty_victory',
              ),
            ],
          ),
          trainerId: 'misty',
          name: 'Misty Updated',
        );

        final trainer = updated.trainers.single;
        expect(trainer.name, 'Misty Updated');
        expect(trainer.battleDifficulty, 8);
        expect(
          trainer.battleBackgroundRelativePath,
          'assets/battle_backgrounds/misty.png',
        );
        expect(trainer.characterId, 'misty_character');
        expect(trainer.portraitElementId, 'misty_portrait');
        expect(trainer.battleMusicPath, 'misty_theme');
        expect(trainer.victoryMusicPath, 'misty_victory');
      },
    );

    test(
      'add/update trainer pokemon keeps data normalized and stable',
      () async {
        final addUseCase = AddTrainerPokemonUseCase(repository);
        final updateUseCase = UpdateTrainerPokemonUseCase(repository);

        final projectWithPokemon = await addUseCase.execute(
          workspace,
          _project(
            trainers: const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: 'misty',
                name: 'Misty',
                trainerClass: 'Gym Leader',
              ),
            ],
          ),
          trainerId: 'misty',
          speciesId: '  staryu  ',
          level: 18,
          moves: const <String>[' water_gun ', '', ' rapid_spin '],
          heldItemId: ' mystic_water ',
          formId: ' base ',
          gender: ' female ',
          shiny: true,
        );

        final addedPokemon = projectWithPokemon.trainers.single.team.single;
        expect(addedPokemon.speciesId, 'staryu');
        expect(addedPokemon.moves, <String>['water_gun', 'rapid_spin']);
        expect(addedPokemon.heldItemId, 'mystic_water');
        expect(addedPokemon.formId, 'base');
        expect(addedPokemon.gender, 'female');
        expect(addedPokemon.shiny, isTrue);

        final updatedProject = await updateUseCase.execute(
          workspace,
          projectWithPokemon,
          trainerId: 'misty',
          pokemonIndex: 0,
          speciesId: ' starmie ',
          level: 21,
          moves: const <String>[' psybeam ', ' recover '],
          heldItemId: const TrainerFieldUpdate<String>.set(''),
          formId: const TrainerFieldUpdate<String>.set(''),
          gender: const TrainerFieldUpdate<String>.set(''),
          shiny: false,
        );

        final updatedPokemon = updatedProject.trainers.single.team.single;
        expect(updatedPokemon.speciesId, 'starmie');
        expect(updatedPokemon.level, 21);
        expect(updatedPokemon.moves, <String>['psybeam', 'recover']);
        expect(updatedPokemon.heldItemId, isNull);
        expect(updatedPokemon.formId, isNull);
        expect(updatedPokemon.gender, isNull);
        expect(updatedPokemon.shiny, isFalse);
      },
    );

    test(
      'update trainer pokemon keeps optional refs stable when omitted',
      () async {
        final updateUseCase = UpdateTrainerPokemonUseCase(repository);

        final updatedProject = await updateUseCase.execute(
          workspace,
          _project(
            trainers: const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: 'misty',
                name: 'Misty',
                trainerClass: 'Gym Leader',
                team: <ProjectTrainerPokemonEntry>[
                  ProjectTrainerPokemonEntry(
                    speciesId: 'staryu',
                    level: 18,
                    moves: <String>['water_gun'],
                    heldItemId: 'mystic_water',
                    formId: 'base',
                    gender: 'female',
                  ),
                ],
              ),
            ],
          ),
          trainerId: 'misty',
          pokemonIndex: 0,
          level: 21,
        );

        final updatedPokemon = updatedProject.trainers.single.team.single;
        expect(updatedPokemon.level, 21);
        expect(updatedPokemon.heldItemId, 'mystic_water');
        expect(updatedPokemon.formId, 'base');
        expect(updatedPokemon.gender, 'female');
      },
    );

    test('rejects an empty species id before save', () async {
      final addUseCase = AddTrainerPokemonUseCase(repository);

      expect(
        () => addUseCase.execute(
          workspace,
          _project(
            trainers: const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: 'misty',
                name: 'Misty',
                trainerClass: 'Gym Leader',
              ),
            ],
          ),
          trainerId: 'misty',
          speciesId: '   ',
          level: 12,
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });
}

ProjectManifest _project({
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
  List<BadgeDefinition> badges = const <BadgeDefinition>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tileset_1',
      name: 'Tileset 1',
      relativePath: 'tilesets/tileset_1.png',
    ),
  ],
}) {
  return ProjectManifest(
    name: 'trainer_use_case_test',
    maps: const <ProjectMapEntry>[],
    tilesets: tilesets,
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'portraits', name: 'Portraits'),
    ],
    elements: elements,
    characters: characters,
    badges: badges,
    dialogues: dialogues,
    trainers: trainers,
  );
}

class _FakeProjectRepository implements ProjectRepository {
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedProjects.add(project);
  }
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

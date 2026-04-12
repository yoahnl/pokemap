import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
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
    test('create trainer trims optional refs and normalizes tags', () async {
      final useCase = CreateTrainerUseCase(repository);

      final updated = await useCase.execute(
        workspace,
        _project(),
        name: '  Misty  ',
        trainerClass: '  Gym Leader  ',
        battleThemeId: ' battle_theme ',
        victoryThemeId: ' victory_theme ',
        tags: <String>[' rival ', ' ', ' gym '],
      );

      final trainer = updated.trainers.single;
      expect(trainer.id, 'misty');
      expect(trainer.name, 'Misty');
      expect(trainer.trainerClass, 'Gym Leader');
      expect(trainer.battleThemeId, 'battle_theme');
      expect(trainer.victoryThemeId, 'victory_theme');
      expect(trainer.tags, <String>['rival', 'gym']);
      expect(repository.savedProjects.single.trainers.single.name, 'Misty');
    });

    test('add/update trainer pokemon keeps data normalized and stable',
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
        heldItemId: '',
        formId: '',
        gender: '',
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
    });

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
}) {
  return ProjectManifest(
    name: 'trainer_use_case_test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
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

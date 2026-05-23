import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier trainer partial updates', () {
    late _FakeProjectRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeProjectRepository();
      container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test(
        'updateTrainer leaves unrelated optional trainer fields untouched when only the name changes',
        () async {
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/tmp/project',
        project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
          name: 'trainer_partial_update_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'tileset_1',
              name: 'Tileset 1',
              relativePath: 'tilesets/tileset_1.png',
            ),
          ],
          elementCategories: <ProjectElementCategory>[
            ProjectElementCategory(
              id: 'portraits',
              name: 'Portraits',
            ),
          ],
          elements: <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'portrait_1',
              name: 'Portrait',
              tilesetId: 'tileset_1',
              categoryId: 'portraits',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              ],
            ),
          ],
          characters: <ProjectCharacterEntry>[
            ProjectCharacterEntry(
              id: 'character_1',
              name: 'Hero',
              tilesetId: 'tileset_1',
            ),
          ],
          trainers: <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'mira',
              name: 'Mira',
              trainerClass: 'Rookie',
              battleDifficulty: 8,
              battleBackgroundRelativePath:
                  'assets/battle_backgrounds/mira.png',
              characterId: 'character_1',
              portraitElementId: 'portrait_1',
              battleThemeId: 'battle_mira',
              victoryThemeId: 'victory_mira',
            ),
          ],
        ),
      );

      final success = await notifier.updateTrainer(
        trainerId: 'mira',
        name: 'New Mira',
      );

      expect(success, isTrue);
      final updatedTrainer = notifier.state.project!.trainers.single;
      expect(updatedTrainer.name, 'New Mira');
      expect(updatedTrainer.battleDifficulty, 8);
      expect(
        updatedTrainer.battleBackgroundRelativePath,
        'assets/battle_backgrounds/mira.png',
      );
      expect(updatedTrainer.characterId, 'character_1');
      expect(updatedTrainer.portraitElementId, 'portrait_1');
      expect(updatedTrainer.battleThemeId, 'battle_mira');
      expect(updatedTrainer.victoryThemeId, 'victory_mira');
    });

    test(
        'updateTrainerPokemon leaves held item, form and gender untouched when only the level changes',
        () async {
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/tmp/project',
        project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
          name: 'trainer_pokemon_partial_update_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          trainers: <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'mira',
              name: 'Mira',
              trainerClass: 'Rookie',
              team: <ProjectTrainerPokemonEntry>[
                ProjectTrainerPokemonEntry(
                  speciesId: 'sparkitten',
                  level: 6,
                  moves: <String>['scratch'],
                  heldItemId: 'oran_berry',
                  formId: 'base',
                  gender: 'female',
                ),
              ],
            ),
          ],
        ),
      );

      final success = await notifier.updateTrainerPokemon(
        trainerId: 'mira',
        pokemonIndex: 0,
        level: 9,
      );

      expect(success, isTrue);
      final updatedPokemon = notifier.state.project!.trainers.single.team.single;
      expect(updatedPokemon.level, 9);
      expect(updatedPokemon.heldItemId, 'oran_berry');
      expect(updatedPokemon.formId, 'base');
      expect(updatedPokemon.gender, 'female');
    });
  });
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

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory();

  @override
  ProjectWorkspace create(String projectRoot) {
    return _FakeWorkspace(projectRoot);
  }
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace(this.projectRoot);

  @override
  final String projectRoot;

  @override
  String get projectManifestPath => '$projectRoot/project.json';

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
  String getMapPath(String mapId) => '$projectRoot/$mapId.json';

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
  String resolveMapPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

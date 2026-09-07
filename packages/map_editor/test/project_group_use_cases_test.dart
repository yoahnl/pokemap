import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_group_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  test(
    'editor creates, moves, renames and deletes nested map folders',
    () async {
      final repo = _Repository();
      final workspace = _Workspace();
      var project = const ProjectManifest(
        name: 'Folders',
        tilesets: [],
        maps: [
          ProjectMapEntry(
            id: 'town',
            name: 'Town',
            relativePath: 'maps/town.json',
          ),
        ],
        groups: [
          ProjectMapGroup(
            id: 'region',
            name: 'Region',
            type: MapGroupType.village,
          ),
        ],
      );
      final originalMap = project.maps.single;
      project = await CreateGroupUseCase(repo).execute(
        workspace,
        project,
        'Interiors',
        MapGroupType.facility,
        parentId: 'region',
      );
      final child = project.groups.last.id;
      project = await MoveMapToGroupUseCase(
        repo,
      ).execute(workspace, project, 'town', child);
      expect(repo.saved!.maps.single.groupId, child);
      project = await RenameGroupUseCase(
        repo,
      ).execute(workspace, project, child, 'Maisons');
      expect(repo.saved!.groups.last.name, 'Maisons');
      project = await DeleteGroupUseCase(
        repo,
      ).execute(workspace, project, 'region');
      expect(project.groups.single.parentGroupId, isNull);
      expect(project.maps.single.groupId, child);
      project = await DeleteGroupUseCase(
        repo,
      ).execute(workspace, project, child);
      expect(project.groups, isEmpty);
      expect(project.maps.single, originalMap);
      expect(repo.saved, project);
    },
  );

  test('editor rejects an invalid destination without saving', () async {
    final repo = _Repository();
    const project = ProjectManifest(
      name: 'Folders',
      tilesets: [],
      maps: [
        ProjectMapEntry(
          id: 'town',
          name: 'Town',
          relativePath: 'maps/town.json',
        ),
      ],
    );
    await expectLater(
      MoveMapToGroupUseCase(
        repo,
      ).execute(_Workspace(), project, 'town', 'missing'),
      throwsA(isA<Exception>()),
    );
    expect(repo.saved, isNull);
  });
}

class _Repository implements ProjectRepository {
  ProjectManifest? saved;

  @override
  Future<ProjectManifest> loadProject(String path) async => saved!;

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saved = project;
  }
}

class _Workspace implements ProjectWorkspace {
  @override
  String get projectManifestPath => '/fixture/project.json';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

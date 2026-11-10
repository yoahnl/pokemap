import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'nested map collection preserves folders and opens an ungrouped map',
    () async {
      const entries = [
        ProjectMapEntry(
          id: 'a',
          name: 'Gare',
          relativePath: 'a.json',
          groupId: 'outside',
        ),
        ProjectMapEntry(
          id: 'b',
          name: 'Route',
          relativePath: 'b.json',
          groupId: 'outside',
        ),
        ProjectMapEntry(
          id: 'c',
          name: 'Boutique',
          relativePath: 'c.json',
          groupId: 'inside',
        ),
        ProjectMapEntry(
          id: 'd',
          name: 'Café',
          relativePath: 'd.json',
          groupId: 'inside',
        ),
        ProjectMapEntry(
          id: 'e',
          name: 'Maison',
          relativePath: 'e.json',
          groupId: 'inside',
        ),
        ProjectMapEntry(id: 'f', name: 'Divers', relativePath: 'f.json'),
        ProjectMapEntry(
          id: 'g',
          name: 'Place',
          relativePath: 'g.json',
          groupId: 'region',
        ),
      ];
      const groups = [
        ProjectMapGroup(
          id: 'region',
          name: 'Hanazuki',
          type: MapGroupType.village,
        ),
        ProjectMapGroup(
          id: 'outside',
          name: 'Extérieurs',
          type: MapGroupType.route,
          parentGroupId: 'region',
        ),
        ProjectMapGroup(
          id: 'inside',
          name: 'Intérieurs',
          type: MapGroupType.facility,
          parentGroupId: 'region',
        ),
      ];
      final collection = MapLibraryTree(maps: entries, groups: groups);
      expect(collection.rows.where((row) => row.map != null), hasLength(7));
      expect(
        collection.rows.where((row) => row.isFolder).map((row) => row.label),
        ['Hanazuki', 'Extérieurs', 'Intérieurs', 'Sans dossier'],
      );
      final parent = collection.rows.firstWhere((row) => row.map?.id == 'g');
      final folder = collection.rows.firstWhere(
        (row) => row.group?.id == 'region',
      );
      expect(parent.depth, greaterThan(folder.depth));
      expect(mapLibraryFolderLabels(groups)['inside'], 'Hanazuki / Intérieurs');
      final project = workspaceProject.copyWith(
        name: 'Le Train',
        maps: entries,
        groups: groups,
      );
      final port = _Maps(project);
      final controller = MapWorkspaceController(workspaceSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final ungrouped = collection.rows
          .singleWhere((row) => row.map?.id == 'f')
          .map!;
      await controller.activate(ungrouped);
      expect(controller.active!.current.id, 'f');
      expect(controller.error, isNull);
      expect(port.writes, 0);
    },
  );
}

class _Maps extends WorkspaceMemoryPort {
  _Maps(this.project);
  final ProjectManifest project;
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async => project;
}

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const groups = [
    ProjectMapGroup(id: 'region', name: 'Région', type: MapGroupType.special),
    ProjectMapGroup(
      id: 'village',
      name: 'Village',
      type: MapGroupType.village,
      parentGroupId: 'region',
    ),
  ];
  const maps = [
    ProjectMapEntry(id: 'a', name: 'Clairière', relativePath: 'a.json'),
    ProjectMapEntry(
      id: 'b',
      name: 'Maison',
      relativePath: 'b.json',
      groupId: 'village',
    ),
  ];

  test('real folders, descendants and root maps remain distinct', () {
    final tree = MapLibraryTree(groups: groups, maps: maps);
    expect(tree.countFor('region'), 1);
    expect(tree.countFor('village'), 1);
    expect(tree.countFor(null), 1);
    expect(tree.rows.map((row) => (row.group?.id, row.map?.id, row.depth)), [
      ('region', null, 0),
      ('village', null, 1),
      (null, 'b', 2),
      (null, null, 0),
      (null, 'a', 1),
    ]);
  });

  test('search keeps the real ancestor chain without renaming maps', () {
    final tree = MapLibraryTree(groups: groups, maps: maps, query: 'MAISON');
    expect(tree.rows.map((row) => row.label), ['Région', 'Village', 'Maison']);
    expect(tree.rows.last.map?.id, 'b');
  });

  test('unclassified map collection starts entirely without folders', () {
    final tree = MapLibraryTree(groups: const [], maps: maps);
    expect(tree.rows.first.label, 'Sans dossier');
    expect(tree.countFor(null), 2);
  });
  test('parent choices exclude the folder and all descendants in arbitrary catalogue order', () {
    const project = ProjectManifest(
      name: 'Folders',
      maps: [],
      tilesets: [],
      groups: [
        ProjectMapGroup(
          id: 'grandchild',
          type: MapGroupType.special,
          name: 'Petit',
          parentGroupId: 'child',
        ),
        ProjectMapGroup(
          id: 'child',
          name: 'Enfant',
          type: MapGroupType.special,
          parentGroupId: 'root',
        ),
        ProjectMapGroup(id: 'other', name: 'Autre', type: MapGroupType.special),
        ProjectMapGroup(id: 'root', name: 'Racine', type: MapGroupType.special),
      ],
    );
    final commands = WorkspaceMapLibraryCommands(
      project: () => project,
      submit: ({groups, required assignments}) async => null,
    );
    expect(commands.parentCandidates('root').map((group) => group.id), [
      'other',
    ]);
    expect(commands.parentCandidates('child').map((group) => group.id), [
      'other',
      'root',
    ]);
    expect(commands.parentCandidates('missing').map((group) => group.id), [
      'grandchild',
      'child',
      'other',
      'root',
    ]);
  });
}

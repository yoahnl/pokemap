import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildDialogueLibraryTree', () {
    test('nests folders and assigns dialogues to correct parents', () {
      const fRoot = ProjectDialogueFolder(id: 'root', name: 'Root');
      const fChild = ProjectDialogueFolder(
        id: 'child',
        name: 'Child',
        parentFolderId: 'root',
      );
      final dInChild = ProjectDialogueEntry(
        id: 'd1',
        name: 'InChild',
        relativePath: 'dialogues/d1.yarn',
        folderId: 'child',
      );
      final dRoot = ProjectDialogueEntry(
        id: 'd0',
        name: 'AtManifestRoot',
        relativePath: 'dialogues/d0.yarn',
      );

      final manifest = ProjectManifest(
        name: 't',
        maps: const [],
        tilesets: const [],
        dialogueFolders: [fRoot, fChild],
        dialogues: [dInChild, dRoot],
      );

      final tree = buildDialogueLibraryTree(manifest);
      expect(tree.rootFolders, hasLength(1));
      expect(tree.rootFolders.single.folder.id, 'root');
      expect(tree.rootFolders.single.childFolders, hasLength(1));
      expect(tree.rootFolders.single.childFolders.single.folder.id, 'child');
      expect(
        tree.rootFolders.single.childFolders.single.dialogues.single.id,
        'd1',
      );
      expect(tree.rootDialogues.single.id, 'd0');
    });

    test('flattenDialogueFoldersForPicker preserves depth order', () {
      final manifest = ProjectManifest(
        name: 't',
        maps: const [],
        tilesets: const [],
        dialogueFolders: [
          const ProjectDialogueFolder(id: 'a', name: 'A'),
          const ProjectDialogueFolder(
            id: 'b',
            name: 'B',
            parentFolderId: 'a',
          ),
        ],
        dialogues: const [],
      );
      final flat = flattenDialogueFoldersForPicker(manifest);
      expect(flat.map((e) => e.id).toList(), ['a', 'b']);
      expect(flat.last.label, contains('A'));
      expect(flat.last.label, contains('B'));
    });
  });
}

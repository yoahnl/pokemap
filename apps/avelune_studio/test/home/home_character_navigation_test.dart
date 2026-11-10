import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

const _guide = ProjectCharacterEntry(
  id: 'guide',
  name: 'Chef de gare',
  tilesetId: 'atlas',
);

void main() {
  test(
    'character placement keeps active draft and other map content undoable',
    () async {
      final port = _Maps();
      final controller = MapWorkspaceController(workspaceSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Travail conservé'));
      final before = document.current;
      final reads = port.reads;
      await controller.activate(controller.project!.maps.first);
      expect(controller.active, same(document));
      expect(document.current, same(before));
      expect(document.canUndo, isTrue);
      final commands = CharacterEditingCommands(document, controller.project!);
      commands.place(_guide, const GridPos(x: 3, y: 3));
      expect(document.current.entities.single.npc!.characterId, _guide.id);
      expect(document.current.placedElements, before.placedElements);
      controller.restore(redo: false);
      expect(document.current, before);
      expect(port.reads, reads);
      expect(port.writes, 0);
      expect(port.catalogs, 1);
    },
  );
}

class _Maps extends WorkspaceMemoryPort {
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    catalogs++;
    return workspaceProject.copyWith(characters: [_guide]);
  }
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

import '../support/neutral_map_host_fixture.dart';
import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  testWidgets(
    'native character placement preserves the document before input and records instance edits',
    (tester) async {
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await controller.initialize();
      controller.project = controller.project!.copyWith(characters: [guide]);
      addTearDown(controller.dispose);
      final host = await NeutralMapHostFixture.fromController(
        tester,
        controller,
      );
      final document = controller.active!;
      final before = document.current;
      expect(document.dirty, isFalse);
      host.nativeView.character = guide;
      host.nativeView.prepareCharacterPlacement();
      expect(document.current, same(before));
      expect(document.dirty, isFalse);
      await host.tapCell(6, 6);
      final entity = document.current.entities.single;
      expect(entity.npc!.characterId, guide.id);
      expect(entity.pos, const GridPos(x: 6, y: 6));
      expect(document.dirty, isTrue);
      expect(document.canUndo, isTrue);
      CharacterEditingCommands(
        document,
        controller.project!,
      ).update(entity.id, name: 'Chef compact');
      expect(document.current.entities.single.npc!.displayName, 'Chef compact');
      expect(document.dirty, isTrue);
      expect(tester.takeException(), isNull);
      await host.dispose();
    },
  );

  test('keyboard deletion guards pending stories and duplication keeps independent instances', () async {
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    await controller.initialize();
    controller.project = controller.project!.copyWith(characters: [guide]);
    addTearDown(controller.dispose);
    final commands = CharacterEditingCommands(
      controller.active!,
      controller.project!,
    );
    final entity = commands.place(guide, const GridPos(x: 3, y: 4));
    final view = MapEditingViewportSession()
      ..select(controller.active!, MapSelectionFamily.character, entity.id);
    addTearDown(view.dispose);
    controller.historyGuard = (_, _) => 'Interaction non enregistrée';
    var saves = 0;
    final bindings = mapEditingShortcuts(
      controller,
      view,
      (action) => action(),
      onSave: () => saves++,
    );
    bindings.entries
        .firstWhere(
          (entry) =>
              entry.key.triggers?.contains(LogicalKeyboardKey.delete) == true,
        )
        .value();
    expect(controller.active!.current.entities, hasLength(1));
    expect(controller.active!.error, 'Interaction non enregistrée');
    bindings.entries
        .firstWhere(
          (entry) =>
              entry.key.triggers?.contains(LogicalKeyboardKey.keyD) == true,
        )
        .value();
    expect(controller.active!.current.entities, hasLength(2));
    expect(
      view.selectedFor(
        controller.active!.current.id,
        MapSelectionFamily.character,
      ),
      isNot(entity.id),
    );
    controller.historyGuard = null;
    bindings.entries
        .firstWhere(
          (entry) =>
              entry.key.triggers?.contains(LogicalKeyboardKey.delete) == true,
        )
        .value();
    expect(controller.active!.current.entities.single.id, entity.id);
    bindings.entries
        .firstWhere(
          (entry) =>
              entry.key.triggers?.contains(LogicalKeyboardKey.keyS) == true,
        )
        .value();
    expect(saves, 1);
  });
}

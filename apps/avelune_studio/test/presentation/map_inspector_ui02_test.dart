import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('local stack selection respects order limits and preserves positions across undo', () {
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r0', mapId: 'a'),
    );
    final commands = MapEditingCommands(document, workspaceProject);
    for (var i = 0; i < 3; i++) {
      commands.place(workspaceElement, const GridPos(x: 3, y: 3));
    }
    final frontId = document.selectedId;
    final backId = commands.stack(const GridPos(x: 3, y: 3)).last.id;
    final positions = {
      for (final item in document.current.placedElements) item.id: item.pos,
    };
    expect(commands.canReorder(forward: true), isFalse);
    document.selectedId = backId;
    expect(document.selectedId, isNot(frontId));
    expect(commands.canReorder(forward: true), isTrue);
    commands.reorder(forward: true);
    expect(commands.stack(const GridPos(x: 3, y: 3))[1].id, backId);
    expect({
      for (final item in document.current.placedElements) item.id: item.pos,
    }, positions);
    document.restore(redo: false);
    expect(commands.stack(const GridPos(x: 3, y: 3))[2].id, backId);
    document.restore(redo: true);
    expect(commands.stack(const GridPos(x: 3, y: 3))[1].id, backId);
  });
}

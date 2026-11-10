import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController controller;
  late MapWorkspaceEditingState view;
  late MapEditingInputSession input;

  setUp(() async {
    final port = WorkspaceMemoryPort();
    port.saved['a'] = workspaceMap('a').copyWith(
      entities: const [
        MapEntity(
          id: 'sign',
          name: 'Panneau',
          kind: MapEntityKind.sign,
          pos: GridPos(x: 4, y: 4),
          sign: MapEntitySignData(title: 'Quai'),
        ),
      ],
    );
    controller = MapWorkspaceController(workspaceSession, port);
    await controller.initialize();
    view = MapWorkspaceEditingState();
    input = MapEditingInputSession(controller: controller, view: () => view);
    addTearDown(input.dispose);
    addTearDown(controller.dispose);
  });

  EditableMapDocument replaceDocument() {
    final replacement = EditableMapDocument(
      MapWorkspaceDocument(
        map: controller.active!.current,
        mapId: 'a',
        revision: 'reopened',
      ),
    );
    controller.documents['a'] = replacement;
    controller.active = replacement;
    return replacement;
  }

  test('delete affects the document that opened the menu', () {
    final document = controller.active!;
    input.open(const GridPos(x: 4, y: 4));
    expect(input.contextOpen, isTrue);
    input.run(MapContextCommand.delete);
    expect(document.current.entities, isEmpty);
    expect(document.undoCount, 1);
    expect(input.contextOpen, isFalse);
  });

  test('a replacement document with the same IDs rejects a stale command', () {
    final original = controller.active!;
    input.open(const GridPos(x: 4, y: 4));
    final replacement = replaceDocument();
    final before = replacement.current;
    input.run(MapContextCommand.delete);
    expect(input.contextOpen, isFalse);
    expect(replacement.current, same(before));
    expect(replacement.undoCount, 0);
    expect(original.current.entities, hasLength(1));
  });

  test('a stale menu cannot select on a replacement document', () {
    input.open(const GridPos(x: 4, y: 4));
    final selected = input.targets.single;
    final replacement = replaceDocument();
    input.select(selected);
    expect(input.contextOpen, isFalse);
    expect(replacement.selectedId, isNull);
  });

  test('reconcile closes a menu after the document is replaced', () {
    input.open(const GridPos(x: 4, y: 4));
    replaceDocument();
    input.reconcile();
    expect(input.contextOpen, isFalse);
  });
}

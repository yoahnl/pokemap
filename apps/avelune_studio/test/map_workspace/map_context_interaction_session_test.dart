import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_interaction_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  EditableMapDocument document(String revision) => EditableMapDocument(
    MapWorkspaceDocument(
      map: workspaceMap('a').copyWith(
        entities: const [
          MapEntity(
            id: 'sign',
            name: 'Panneau',
            kind: MapEntityKind.sign,
            pos: GridPos(x: 4, y: 4),
            sign: MapEntitySignData(title: 'Quai'),
          ),
        ],
      ),
      revision: revision,
      mapId: 'a',
    ),
  );

  test('context deletion acts on its current document owner', () {
    final active = document('initial');
    final view = MapWorkspaceEditingState();
    final session = MapContextInteractionSession(
      contextAt: (cell) => MapContextActionContext(
        document: active,
        project: workspaceProject,
        position: cell,
      ),
      view: () => view,
      navigation: (_) => const MapContextNavigation(),
    );
    addTearDown(session.dispose);
    expect(session.open(const GridPos(x: 4, y: 4), Offset.zero), isTrue);
    expect(session.run(MapContextCommand.delete), isTrue);
    expect(active.current.entities, isEmpty);
    expect(active.undoCount, 1);
  });

  test('a new document with matching map and target IDs cannot receive an old request', () {
    final original = document('initial');
    var active = original;
    final view = MapWorkspaceEditingState();
    final session = MapContextInteractionSession(
      contextAt: (cell) => MapContextActionContext(
        document: active,
        project: workspaceProject,
        position: cell,
      ),
      view: () => view,
      navigation: (_) => const MapContextNavigation(),
    );
    addTearDown(session.dispose);
    expect(session.open(const GridPos(x: 4, y: 4), Offset.zero), isTrue);
    active = document('reopened');
    final before = active.current;
    expect(session.run(MapContextCommand.delete), isFalse);
    expect(session.request, isNull);
    expect(active.current, same(before));
    expect(active.undoCount, 0);
    expect(original.current.entities, hasLength(1));
  });
}

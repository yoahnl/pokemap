import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'catalogue search selects the actual decor brush without editing the map',
    () async {
      final project = workspaceProject.copyWith(
        elements: [
          for (var i = 0; i < 500; i++)
            workspaceElement.copyWith(id: 'tree-$i', name: 'Arbre $i'),
        ],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r', mapId: 'a'),
      );
      final workspace =
          MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
            ..project = project
            ..active = document;
      addTearDown(workspace.dispose);
      final view = MapWorkspaceEditingState();
      view.resourceFilters.query = 'Arbre 499';
      final visible = view.paletteResourcesFor(project, 'a', 'Décors');
      expect(visible.map((item) => item.id), ['tree-499']);
      final before = document.current;
      expect(
        await useMapResource(
          workspace: workspace,
          item: visible.single,
          view: () => view,
          isActive: () => true,
          chooseMap: (_) async => null,
          chooseTile: (_) async => null,
        ),
        isTrue,
      );
      expect(view.brush!.id, 'tree-499');
      expect(view.tool, StudioMapTool.place);
      expect(document.current, same(before));
      expect(document.dirty, isFalse);
    },
  );

}

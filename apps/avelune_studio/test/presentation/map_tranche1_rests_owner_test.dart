import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';


import '../support/map_selection_e_shell_owner_fixture.dart';
import '../support/spatial_border_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {

  testWidgets(
    'Shift-click on the map adds and removes decors from the selection',
    (tester) async {
      final h = MapSelectionEShellOwnerFixture.of(workspaceProject);
      addTearDown(h.dispose);
      final commands = MapEditingCommands(h.document, h.project);
      final first = commands.place(
        workspaceElement,
        const GridPos(x: 1, y: 1),
      )!;
      final second = commands.place(
        workspaceElement,
        const GridPos(x: 4, y: 4),
      )!;
      await h.pump(tester);
      await h.use(tester, StudioMapTool.select);
      await h.tapCell(tester, 1, 1);
      expect(h.view.selectedDecorIds(h.document.current.id), {first});
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await h.tapCell(tester, 4, 4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(h.view.selectedDecorIds(h.document.current.id), {first, second});
      final before = h.document.current;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await h.tapCell(tester, 4, 4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(h.view.selectedDecorIds(h.document.current.id), {first});
      expect(h.document.current, same(before));
    },
  );

  test('border pieces stay in the library but leave the decor palette', () {
    final base = spatialBorderProject();
    final project = base.copyWith(
      models3d: [
        ...base.models3d,
        ProjectModel3dEntry(
          id: 'lamp',
          name: 'Lampadaire',
          sourceAssetId: 'lamp-source',
          relativePath: 'assets/models3d/lamp.glb',
          inspection: base.models3d.single.inspection,
        ),
      ],
    );
    final palette = MapWorkspaceEditingState()
        .paletteResourcesFor(project, spatialBorderMap().id, 'Décors')
        .map((item) => item.id)
        .toSet();
    expect(palette, contains('lamp'));
    expect(palette, isNot(contains('oak')));
    expect(
      resourceCatalog(project).map((item) => item.id),
      containsAll(['oak', 'lamp']),
    );
  });
}

import 'package:avelune_studio/features/map_workspace/application/map_palette_intent.dart';
import 'package:avelune_studio/features/map_workspace/application/map_palette_queries.dart';
import 'package:avelune_studio/features/map_workspace/application/map_tool_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_owner_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  for (final label in ['Terrains', 'Passages']) {
    test('$label requests the resource picker when it is hidden', () {
      final view = MapWorkspaceEditingState();
      final queries = MapPaletteQueries(view.resourceFilters);
      var reveals = 0;
      final runner = MapToolCommandRunner(
        view: view,
        paletteTab: () => queries.intent,
        selectPalette: queries.select,
        spatial: false,
        paletteVisible: false,
        onChanged: () {},
        onMoreTools: () => reveals++,
        onResources: () {},
      );
      runner.runFamily(label);
      expect(queries.intent, label);
      expect(reveals, 1);
    });
  }

  test('character placement requests its hidden resource picker', () {
    final view = MapWorkspaceEditingState();
    final queries = MapPaletteQueries(view.resourceFilters);
    var reveals = 0;
    final runner = MapToolCommandRunner(
      view: view,
      paletteTab: () => queries.intent,
      selectPalette: queries.select,
      spatial: false,
      paletteVisible: false,
      onChanged: () {},
      onMoreTools: () => reveals++,
      onResources: () {},
    );
    runner.runExtra('Placer un personnage');
    expect(queries.intent, 'Personnages');
    expect(view.tool, StudioMapTool.select);
    expect(view.character, isNull);
    expect(reveals, 1);
  });

  testWidgets(
    'decor intention arms the selected asset and native placement consumes it',
    (tester) async {
      final h = MapSelectionOwnerHarness.of(workspaceProject);
      addTearDown(h.dispose);
      final queries = MapPaletteQueries(h.view.resourceFilters);
      var reveals = 0;
      h.view.brush = workspaceElement;
      final runner = MapToolCommandRunner(
        view: h.view,
        paletteTab: () => queries.intent,
        selectPalette: queries.select,
        spatial: false,
        paletteVisible: false,
        onChanged: () {},
        onMoreTools: () => reveals++,
        onResources: () {},
      );
      runner.runFamily('Décors');
      expect(h.view.tool, StudioMapTool.place);
      expect(reveals, 1);
      await h.pump(tester);
      final count = h.document.current.placedElements.length;
      await h.tapCell(tester, 4, 4);
      expect(h.document.current.placedElements.length, count + 1);
      expect(
        h.document.current.placedElements.last.elementId,
        workspaceElement.id,
      );
      expect(
        h.document.current.placedElements.last.pos,
        const GridPos(x: 4, y: 4),
      );
    },
  );

  test('choosing an eraser changes the active tool and derived intention', () {
    final view = MapWorkspaceEditingState();
    final queries = MapPaletteQueries(view.resourceFilters);
    final runner = MapToolCommandRunner(
      view: view,
      paletteTab: () => queries.intent,
      selectPalette: queries.select,
      spatial: false,
      paletteVisible: true,
      onChanged: () {},
      onMoreTools: () {},
      onResources: () {},
    );
    runner.runExtra('Gomme de tuiles');
    expect(view.tool, StudioMapTool.erase);
    expect(mapPaletteIntent(view).action, 'Gomme de tuiles');
  });
}

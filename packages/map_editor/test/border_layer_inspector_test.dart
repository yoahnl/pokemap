import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  testWidgets('MapInspector presents Border as a dedicated active layer',
      (tester) async {
    final project = buildShellChromeProject(name: 'Border Inspector');
    const map = MapData(
      id: 'map',
      name: 'Border Map',
      version: ProjectVersion.v2,
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.border(id: 'border', name: 'Côte'),
      ],
    );

    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_inspector_project',
        project: project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeLayerId: 'border',
      ),
    );

    expect(find.text('Actif : Calque de bordure'), findsOneWidget);
    expect(find.text('Calque de bordure actif'), findsOneWidget);
    expect(find.textContaining('Calque de collision actif'), findsNothing);
    expect(find.textContaining('Calque de surface actif'), findsNothing);
  });
}

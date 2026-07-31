import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
      'EditorCanvasHost exposes Smart Tiles Studio without an active map',
      (tester) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/smart-tiles-project',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.smartTilesStudio,
        activeMap: null,
      ),
    );

    expect(find.byType(SmartTilesStudioPanel), findsOneWidget);
    expect(find.byType(MapCanvas), findsNothing);
    expect(find.byType(MapInspectorPanel), findsNothing);
  });

  testWidgets('Project Explorer opens the unified Smart Tiles Studio',
      (tester) async {
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/smart-tiles-project',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: null,
      ),
      surfaceSize: const Size(1600, 1000),
    );

    final card =
        find.byKey(const ValueKey<String>('smart-tiles-studio-module-card'));
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.smartTilesStudio,
    );
    expect(find.byType(SmartTilesStudioPanel), findsOneWidget);
    expect(find.byType(MapInspectorPanel), findsNothing);
  });
}

ProjectManifest _project() => const ProjectManifest(
      name: 'smart-tiles-project',
      version: ProjectVersion.v4,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    );

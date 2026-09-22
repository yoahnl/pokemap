import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_column.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  for (final size in [const Size(1536, 1024), const Size(1024, 640)]) {
    testWidgets('the warp palette and inspector hold the charter at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadDesktopCaptureFonts);

      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'base',
          mapId: 'a',
        ),
      );
      final commands = WarpEditingCommands(document, workspaceProject);
      final warp = commands.place(
        workspaceEntries.firstWhere((entry) => entry.id == 'b'),
        const GridPos(x: 3, y: 4),
      );
      commands.retarget(warp.id, targetPos: const GridPos(x: 6, y: 2));

      final view = MapWorkspaceViewState()
        ..paletteTab = 'Passages'
        ..tool = StudioMapTool.warp
        ..warpDestination = workspaceEntries.last
        ..selectedWarpId = warp.id;
      addTearDown(view.dispose);
      final search = TextEditingController();
      addTearDown(search.dispose);
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(size.width == 1024 ? 1.5 : 1),
            ),
            child: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MapWorkspacePaletteColumn(
                      width: 240,
                      project: workspaceProject,
                      document: document,
                      visuals: WorkspaceTestVisuals(),
                      view: view,
                      search: search,
                      storyAvailable: true,
                      onToolChanged: () {},
                      onRefresh: () {},
                      onResources: () {},
                    ),
                    const Spacer(),
                    MapSelectionInspector(
                      document: document,
                      project: workspaceProject,
                      visuals: WorkspaceTestVisuals(),
                      view: view,
                      onChanged: () {},
                      onOpenElement: (_) {},
                      onEditElement: (_) {},
                      onOpenMap: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Passages'), findsWidgets);
      expect(find.text('Jardin'), findsWidgets);
      expect(find.text('Passage'), findsOneWidget);
      expect(find.byKey(const ValueKey('warp-target-x')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('warp-destination-problem')),
        findsNothing,
        reason: 'a destination that exists raises no alarm',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'no overflow at this size and text scale',
      );
      await captureM3Widget(
        tester,
        key,
        'asmap001-passages-${size.width.toInt()}',
      );
    });
  }
}

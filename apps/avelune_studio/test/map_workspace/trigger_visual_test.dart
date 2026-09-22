import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('the story zone inspector holds the charter', (tester) async {
    const size = Size(1024, 640);
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
    TriggerEditingCommands(document, workspaceProject).add(
      const MapTrigger(
        id: 'quai',
        name: 'Quai numéro 3',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 2, y: 3),
          size: GridSize(width: 5, height: 4),
        ),
      ),
    );

    final view = MapWorkspaceViewState()..tool = StudioMapTool.zone;
    view.select(document, MapSelectionFamily.trigger, 'quai');
    addTearDown(view.dispose);
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MediaQuery(
          data: const MediaQueryData(size: size),
          child: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: Align(
                alignment: Alignment.centerRight,
                child: MapSelectionInspector(
                  document: document,
                  project: workspaceProject,
                  visuals: WorkspaceTestVisuals(),
                  view: view,
                  onChanged: () {},
                  onOpenElement: (_) {},
                  onEditElement: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zone d’histoire'), findsOneWidget);
    expect(find.byKey(const ValueKey('trigger-usage')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow');
    await captureM3Widget(tester, key, 'asmap001-story-zone');
  });
}

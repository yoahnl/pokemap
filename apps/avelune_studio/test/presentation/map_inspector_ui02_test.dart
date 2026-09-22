import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r0', mapId: 'a'),
    );
  });

  Future<void> showInspector(
    WidgetTester tester, {
    StudioMapTool tool = StudioMapTool.select,
  }) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, update) => MapWorkspaceInspector(
              project: workspaceProject,
              document: document,
              visuals: WorkspaceTestVisuals(),
              view: view,
              tool: tool,
              onChanged: () => update(() {}),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'empty inspector reports real map and active tool without selection',
    (tester) async {
      await showInspector(tester, tool: StudioMapTool.paint);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('20 × 16 cases'), findsOneWidget);
      expect(
        find.text('Choisissez une tuile, puis peignez sur la carte.'),
        findsOneWidget,
      );
      expect(document.selectedId, isNull);
      expect(find.text('Passer devant'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local stack selects a hidden instance and respects order command limits',
    (tester) async {
      final commands = MapEditingCommands(document, workspaceProject);
      for (var i = 0; i < 3; i++) {
        commands.place(workspaceElement, const GridPos(x: 3, y: 3));
      }
      final frontId = document.selectedId;
      final initialPositions = {
        for (final item in document.current.placedElements) item.id: item.pos,
      };
      await showInspector(tester);
      StudioButton forward() => tester.widget<StudioButton>(
        find.byKey(const ValueKey('Passer devant')),
      );
      expect(forward().onPressed, isNull);
      await tester.tap(find.text('Position 3 / 3'));
      await tester.pump();
      expect(document.selectedId, isNot(frontId));
      expect(forward().onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('Passer devant')));
      await tester.pump();
      expect(
        commands.stack(const GridPos(x: 3, y: 3))[1].id,
        document.selectedId,
      );
      expect({
        for (final item in document.current.placedElements) item.id: item.pos,
      }, initialPositions);
      document.restore(redo: false);
      expect(
        commands.stack(const GridPos(x: 3, y: 3))[2].id,
        document.selectedId,
      );
      document.restore(redo: true);
      expect(
        commands.stack(const GridPos(x: 3, y: 3))[1].id,
        document.selectedId,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

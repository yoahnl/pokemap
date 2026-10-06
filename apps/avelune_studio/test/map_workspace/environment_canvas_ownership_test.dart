import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final change in ['zone', 'tool']) {
    testWidgets('changing $change during a stroke cancels its publication', (
      tester,
    ) async {
      final preset = EnvironmentPreset(
        id: 'garden',
        name: 'Jardin',
        templateId: 'manual',
        sortOrder: 0,
        palette: [EnvironmentPaletteItem(elementId: 'tree', weight: 1)],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          variation: 0,
          edgeDensity: 1,
          minSpacingCells: 0,
        ),
      );
      final project = workspaceProject.copyWith(environmentPresets: [preset]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          mapId: 'a',
          revision: 'r0',
        ),
      );
      final commands = EnvironmentEditingCommands(document, project);
      final first = commands.create(preset);
      final second = commands.create(preset);
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.environment
        ..environment = first;
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MapWorkspaceCanvas(
                document: document,
                project: project,
                visuals: WorkspaceTestVisuals(),
                view: view,
                onChanged: () => setState(() {}),
                gestureGeneration: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Offset cell(int x, int y) => tester
          .renderObject<RenderBox>(find.byKey(const ValueKey('map-canvas')))
          .localToGlobal(Offset(x * 32 + 16, y * 32 + 16));
      final before = document.current;
      final history = document.undoCount;
      final stroke = await tester.startGesture(cell(2, 2));
      await stroke.moveTo(cell(4, 2));
      if (change == 'zone') {
        view.environment = second;
      } else {
        first.tool = EnvironmentPaintTool.rectangle;
      }
      await stroke.up();
      await tester.pump();
      expect(document.current, before);
      expect(document.undoCount, history);
      expect(commands.area(first)!.mask.activeCellCount, 0);
      expect(commands.area(second)!.mask.activeCellCount, 0);
      expect(tester.takeException(), isNull);
    });
  }
}

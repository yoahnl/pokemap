import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../characters/character_editing_test.dart' show guide;

ProjectMapEntry get garden =>
    workspaceEntries.firstWhere((entry) => entry.id == 'b');

void main() {
  late EditableMapDocument document;
  late ProjectManifest project;
  late MapWorkspaceViewState view;

  Future<StateSetter> host(WidgetTester tester) async {
    late StateSetter redraw;
    var generation = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              redraw = setState;
              return MapWorkspaceCanvas(
                document: document,
                project: project,
                visuals: WorkspaceTestVisuals(),
                view: view,
                onChanged: () => setState(() {}),
                gestureGeneration: generation,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return redraw;
  }

  Offset cell(WidgetTester tester, int x, int y) => tester
      .renderObject<RenderBox>(find.byKey(const ValueKey('map-canvas')))
      .localToGlobal(Offset(x * 32 + 16, y * 32 + 16));

  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    project = workspaceProject.copyWith(characters: [guide]);
    view = MapWorkspaceViewState();
  });
  tearDown(() => view.dispose());

  testWidgets('choosing a destination then clicking places the warp', (
    tester,
  ) async {
    view
      ..warpDestination = garden
      ..tool = StudioMapTool.warp;
    await host(tester);

    await tester.tapAt(cell(tester, 3, 4));
    await tester.pump();

    final warp = document.current.warps.single;
    expect(warp.pos, const GridPos(x: 3, y: 4));
    expect(warp.targetMapId, 'b');
    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.warp),
      warp.id,
    );
    expect(document.undoCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a warp keeps its identity through zoom and pan', (tester) async {
    final commands = WarpEditingCommands(document, project);
    final warp = commands.place(garden, const GridPos(x: 7, y: 5));
    final other = commands.place(garden, const GridPos(x: 2, y: 2));
    view.tool = StudioMapTool.select;
    final redraw = await host(tester);

    redraw(
      () => view.transform.value = Matrix4.identity()
        ..translateByDouble(-40, -25, 0, 1)
        ..scaleByDouble(1.75, 1.75, 1, 1),
    );
    await tester.pumpAndSettle();

    // Computed from the viewport and the transform in force, never from the
    // canvas box under test: a wrong scale cannot cancel itself out here.
    Offset transformed(int x, int y) =>
        tester
            .renderObject<RenderBox>(find.byKey(const ValueKey('map-viewport')))
            .localToGlobal(Offset.zero) +
        MatrixUtils.transformPoint(
          view.transform.value,
          Offset(x * 32 + 16, y * 32 + 16),
        );
    expect(
      transformed(7, 5),
      within(distance: 0.01, from: cell(tester, 7, 5)),
      reason: 'the canvas really renders under the transform in force',
    );

    await tester.tapAt(transformed(7, 5));
    await tester.pump();
    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.warp),
      warp.id,
      reason: 'the click lands on the warp the author sees, not on a neighbour',
    );

    await tester.tapAt(transformed(2, 2));
    await tester.pump();
    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.warp),
      other.id,
    );
    expect(
      document.current.warps.map((entry) => entry.pos),
      [const GridPos(x: 7, y: 5), const GridPos(x: 2, y: 2)],
      reason: 'selecting never moves anything',
    );
    expect(document.undoCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging moves the warp and the move is undoable', (
    tester,
  ) async {
    final warp = WarpEditingCommands(
      document,
      project,
    ).place(garden, const GridPos(x: 4, y: 4));
    view.tool = StudioMapTool.select;
    view.select(document, MapSelectionFamily.warp, warp.id);
    await host(tester);

    final gesture = await tester.startGesture(cell(tester, 4, 4));
    await gesture.moveTo(cell(tester, 6, 7));
    expect(
      document.current.warps.single.pos,
      const GridPos(x: 4, y: 4),
      reason: 'nothing is written while the finger is still down',
    );
    await gesture.up();
    await tester.pump();

    expect(document.current.warps.single.pos, const GridPos(x: 6, y: 7));
    expect(document.undoCount, 2);
    document.restore(redo: false);
    expect(document.current.warps.single.pos, const GridPos(x: 4, y: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a character on the same cell keeps the selection', (
    tester,
  ) async {
    final npc = CharacterEditingCommands(
      document,
      project,
    ).place(guide, const GridPos(x: 5, y: 5));
    final warp = WarpEditingCommands(
      document,
      project,
    ).place(garden, const GridPos(x: 5, y: 5));
    view.tool = StudioMapTool.select;
    await host(tester);

    await tester.tapAt(cell(tester, 5, 5));
    await tester.pump();

    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.character),
      npc.id,
      reason: 'an entity stays more specific than the warp under it',
    );
    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.warp),
      isNull,
    );
    expect(document.current.warps.single.id, warp.id);
    expect(tester.takeException(), isNull);
  });
}

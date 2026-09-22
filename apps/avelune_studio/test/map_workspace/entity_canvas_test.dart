import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../characters/character_editing_test.dart' show guide;

void main() {
  late EditableMapDocument document;
  late ProjectManifest project;
  late MapWorkspaceViewState view;

  Future<void> host(WidgetTester tester) async {
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

  testWidgets('the player start is placed and selected in one click', (
    tester,
  ) async {
    view.tool = StudioMapTool.spawn;
    await host(tester);

    await tester.tapAt(cell(tester, 6, 2));
    await tester.pump();

    final spawn = document.current.entities.single;
    expect(spawn.kind, MapEntityKind.spawn);
    expect(spawn.pos, const GridPos(x: 6, y: 2));
    expect(view.selectedPlacementId, spawn.id);
    expect(
      view.selectedEntityId,
      isNull,
      reason: 'a marker never poses as a character',
    );
    expect(document.undoCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a marker is selected then dragged to another cell', (
    tester,
  ) async {
    final commands = MapEntityEditingCommands(document, project);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    view.tool = StudioMapTool.select;
    await host(tester);

    await tester.tapAt(cell(tester, 4, 4));
    await tester.pump();
    expect(view.selectedPlacementId, sign.id);

    final gesture = await tester.startGesture(cell(tester, 4, 4));
    await gesture.moveTo(cell(tester, 8, 5));
    expect(document.current.entities.single.pos, const GridPos(x: 4, y: 4));
    await gesture.up();
    await tester.pump();

    expect(document.current.entities.single.pos, const GridPos(x: 8, y: 5));
    document.restore(redo: false);
    expect(document.current.entities.single.pos, const GridPos(x: 4, y: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a character still wins the selection over a marker', (
    tester,
  ) async {
    final npc = CharacterEditingCommands(
      document,
      project,
    ).place(guide, const GridPos(x: 5, y: 5));
    MapEntityEditingCommands(
      document,
      project,
    ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
    view.tool = StudioMapTool.select;
    await host(tester);

    await tester.tapAt(cell(tester, 5, 5));
    await tester.pump();

    expect(view.selectedEntityId, npc.id);
    expect(view.selectedPlacementId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('placing a marker leaves decors and characters alone', (
    tester,
  ) async {
    final npc = CharacterEditingCommands(
      document,
      project,
    ).place(guide, const GridPos(x: 1, y: 1));
    final before = document.current.entities;
    view.tool = StudioMapTool.spawn;
    await host(tester);

    await tester.tapAt(cell(tester, 9, 9));
    await tester.pump();

    expect(document.current.entities, hasLength(before.length + 1));
    expect(
      document.current.entities.firstWhere((e) => e.id == npc.id),
      before.single,
      reason: 'the character is untouched, not rewritten',
    );
    expect(tester.takeException(), isNull);
  });
}

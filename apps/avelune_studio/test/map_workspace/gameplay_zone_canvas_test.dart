import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late MapWorkspaceViewState view;
  late List<MapRect> storyZones;

  Future<void> host(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MapWorkspaceCanvas(
              document: document,
              project: workspaceProject,
              visuals: WorkspaceTestVisuals(),
              view: view,
              onChanged: () => setState(() {}),
              gestureGeneration: 0,
              onZoneDrawn: storyZones.add,
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
    view = MapWorkspaceViewState();
    storyZones = [];
  });
  tearDown(() => view.dispose());

  testWidgets('drawing a rectangle creates the gameplay zone', (tester) async {
    view
      ..tool = StudioMapTool.gameplayZone
      ..zoneKind = GameplayZoneKind.hazard;
    await host(tester);

    final draw = await tester.startGesture(cell(tester, 2, 3));
    await draw.moveTo(cell(tester, 5, 6));
    await draw.up();
    await tester.pump();

    final zone = document.current.gameplayZones.single;
    expect(
      zone.area,
      const MapRect(
        pos: GridPos(x: 2, y: 3),
        size: GridSize(width: 4, height: 4),
      ),
    );
    expect(zone.kind, GameplayZoneKind.hazard);
    expect(zone.hazard, isNotNull);
    expect(view.selectedZoneId, zone.id);
    expect(
      storyZones,
      isEmpty,
      reason: 'a gameplay zone never reaches the story path',
    );
    expect(document.undoCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the story zone tool keeps its own behaviour', (tester) async {
    view.tool = StudioMapTool.zone;
    await host(tester);

    final draw = await tester.startGesture(cell(tester, 1, 1));
    await draw.moveTo(cell(tester, 3, 2));
    await draw.up();
    await tester.pump();

    expect(
      storyZones.single,
      const MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 3, height: 2),
      ),
    );
    expect(
      document.current.gameplayZones,
      isEmpty,
      reason: 'the two zone tools never write in the same collection',
    );
  });

  testWidgets('drawing a zone leaves tiles and other families alone', (
    tester,
  ) async {
    final layers = document.current.layers;
    view
      ..tool = StudioMapTool.gameplayZone
      ..zoneKind = GameplayZoneKind.encounter;
    await host(tester);

    final draw = await tester.startGesture(cell(tester, 6, 6));
    await draw.moveTo(cell(tester, 7, 7));
    await draw.up();
    await tester.pump();

    expect(document.current.layers, layers);
    expect(document.current.entities, isEmpty);
    expect(document.current.triggers, isEmpty);
    document.restore(redo: false);
    expect(document.current.gameplayZones, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a zone is found again by clicking it with the zone tool', (
    tester,
  ) async {
    final zone = GameplayZoneEditingCommands(document, workspaceProject).place(
      GameplayZoneKind.encounter,
      const MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 4, height: 4),
      ),
    );
    view.tool = StudioMapTool.gameplayZone;
    await host(tester);
    final steps = document.undoCount;

    await tester.tapAt(cell(tester, 3, 3));
    await tester.pump();

    expect(
      view.selectedZoneId,
      zone.id,
      reason: 'the author can come back to a zone to change it',
    );
    expect(
      document.current.gameplayZones,
      hasLength(1),
      reason: 'clicking an existing zone never stacks a one-cell zone on it',
    );
    expect(document.undoCount, steps);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a zone tool click on empty ground still creates one', (
    tester,
  ) async {
    view
      ..tool = StudioMapTool.gameplayZone
      ..zoneKind = GameplayZoneKind.movement;
    await host(tester);

    await tester.tapAt(cell(tester, 8, 8));
    await tester.pump();

    final zone = document.current.gameplayZones.single;
    expect(
      zone.area,
      const MapRect(
        pos: GridPos(x: 8, y: 8),
        size: GridSize(width: 1, height: 1),
      ),
    );
    expect(view.selectedZoneId, zone.id);
  });

  testWidgets('an existing zone does not steal the decor selection', (
    tester,
  ) async {
    GameplayZoneEditingCommands(document, workspaceProject).place(
      GameplayZoneKind.encounter,
      const MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 4, height: 4),
      ),
    );
    view.tool = StudioMapTool.select;
    await host(tester);

    await tester.tapAt(cell(tester, 3, 3));
    await tester.pump();

    expect(
      view.selectedZoneId,
      isNull,
      reason: 'in select mode a zone never captures the decor selection',
    );
    expect(document.current.gameplayZones, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}

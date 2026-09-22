import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_character_gesture.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  test(
    'selection distinguishes covered character and decor without moving either',
    () {
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'base',
          mapId: 'a',
        ),
      );
      final project = workspaceProject.copyWith(characters: [guide]);
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      final characters = CharacterEditingCommands(document, project);
      final instance = characters.place(guide, const GridPos(x: 5, y: 5));
      final decors = MapEditingCommands(document, project);
      decors.place(workspaceElement, const GridPos(x: 2, y: 2));
      expect(
        MapCharacterGesture.start(
          document: document,
          project: project,
          view: view,
          origin: instance.pos,
        ),
        isNotNull,
      );
      expect(view.selectedFor(document.current.id, MapSelectionFamily.character), instance.id);
      decors.place(workspaceElement, instance.pos);
      final covering = document.selectedId;
      view.select(document, MapSelectionFamily.decor, covering!);
      expect(
        MapCharacterGesture.start(
          document: document,
          project: project,
          view: view,
          origin: instance.pos,
        ),
        isNull,
      );
      expect(document.selectedId, covering);
      expect(characters.at(instance.pos).single.id, instance.id);
      final before = document.current;
      view.select(document, MapSelectionFamily.character, instance.id);
      final gesture = MapCharacterGesture.start(
        document: document,
        project: project,
        view: view,
        origin: instance.pos,
      );
      expect(gesture!.entity!.id, instance.id);
      expect(document.current, before);
    },
  );
  testWidgets(
    'canvas places, drags once, cancels and draws a bounded story zone',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'base',
          mapId: 'a',
        ),
      );
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.character
        ..character = guide;
      addTearDown(view.dispose);
      var generation = 0;
      MapRect? zone;
      late StateSetter redraw;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                redraw = setState;
                return MapWorkspaceCanvas(
                  document: document,
                  project: workspaceProject.copyWith(characters: [guide]),
                  visuals: WorkspaceTestVisuals(),
                  view: view,
                  onChanged: () => setState(() {}),
                  gestureGeneration: generation,
                  onZoneDrawn: (value) => zone = value,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Offset cell(int x, int y) => tester
          .renderObject<RenderBox>(find.byKey(const ValueKey('map-canvas')))
          .localToGlobal(Offset(x * 32 + 16, y * 32 + 16));
      await tester.tapAt(cell(3, 4));
      await tester.pump();
      final npc = document.current.entities.single;
      expect(npc.npc!.characterId, guide.id);
      expect(document.undoCount, 1);
      redraw(() => view.tool = StudioMapTool.select);
      await tester.pump();
      final gesture = await tester.startGesture(cell(3, 4));
      await gesture.moveTo(cell(4, 4));
      await gesture.moveTo(cell(6, 6));
      expect(document.current.entities.single.pos, npc.pos);
      await gesture.up();
      await tester.pump();
      expect(document.current.entities.single.pos, const GridPos(x: 6, y: 6));
      expect(document.undoCount, 2);
      final cancel = await tester.startGesture(cell(6, 6));
      await cancel.moveTo(cell(9, 7));
      redraw(() => generation++);
      await tester.pump();
      await cancel.up();
      expect(document.undoCount, 2);
      expect(document.current.entities.single.pos, const GridPos(x: 6, y: 6));
      document.restore(redo: false);
      expect(document.current.entities.single.pos, npc.pos);
      document.restore(redo: true);
      redraw(() => view.tool = StudioMapTool.zone);
      await tester.pump();
      final draw = await tester.startGesture(cell(7, 8));
      await draw.moveTo(cell(4, 6));
      await draw.up();
      expect(
        zone,
        const MapRect(
          pos: GridPos(x: 4, y: 6),
          size: GridSize(width: 4, height: 3),
        ),
      );
      expect(document.undoCount, 2);
      expect(tester.takeException(), isNull);
    },
  );
}

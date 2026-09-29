import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_stroke.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('collision strokes paint and erase exact cells in one undo step', () {
    final initial = workspaceMap('a');
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: initial, revision: 'r0', mapId: 'a'),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.collisionPaint;
    addTearDown(view.dispose);
    final commands = MapEditingCommands(document, workspaceProject);
    final stroke = MapCanvasStroke.start(
      map: document.current,
      project: workspaceProject,
      view: view,
      commands: commands,
      origin: const GridPos(x: 2, y: 2),
    )!;
    stroke.paint(const GridPos(x: 4, y: 2));
    document.commit(stroke.commit());
    final layer = document.current.layers.whereType<CollisionLayer>().single;
    final width = document.current.size.width;
    expect(layer.collisions[2 * width + 2], isTrue);
    expect(layer.collisions[2 * width + 3], isTrue);
    expect(layer.collisions[2 * width + 4], isTrue);
    expect(layer.collisions[3 * width + 3], isFalse);
    expect(document.undoCount, 1);

    view.tool = StudioMapTool.collisionErase;
    final eraser = MapCanvasStroke.start(
      map: document.current,
      project: workspaceProject,
      view: view,
      commands: commands,
      origin: const GridPos(x: 3, y: 2),
    )!;
    document.commit(eraser.commit());
    final erased = document.current.layers.whereType<CollisionLayer>().single;
    expect(erased.collisions[2 * width + 2], isTrue);
    expect(erased.collisions[2 * width + 3], isFalse);
    expect(erased.collisions[2 * width + 4], isTrue);
    expect(document.undoCount, 2);
    final reopened = MapData.fromJson(document.current.toJson());
    expect(
      reopened.layers.whereType<CollisionLayer>().single.collisions,
      erased.collisions,
    );
  });

  test(
    'ground eraser targets the occupied terrain, not the selected brush',
    () {
      final cells = List<int>.filled(320, 0)..[2 * 20 + 2] = 1;
      final map = workspaceMap('a').copyWith(
        layers: [
          ...workspaceMap('a').layers,
          MapLayer.smartTile(
            id: 'terrain-a',
            name: 'Terrain',
            presetId: 'other-preset',
            usage: SmartTileUsage.terrain,
            materialPalette: const ['', 'grass'],
            field: SmartTileField.cell(semanticCells: cells),
          ),
        ],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'r0', mapId: 'a'),
      );
      final view = MapWorkspaceViewState()..tool = StudioMapTool.erase;
      addTearDown(view.dispose);
      final stroke = MapCanvasStroke.start(
        map: map,
        project: workspaceProject,
        view: view,
        commands: MapEditingCommands(document, workspaceProject),
        origin: const GridPos(x: 2, y: 2),
      )!;
      final layer = stroke.preview.layers.whereType<SmartTileLayer>().single;
      expect(
        smartTileMaterialIdAt(layer, mapSize: map.size, x: 2, y: 2),
        isNull,
      );
    },
  );

  test('erasing an empty cell does not create a tile layer', () {
    final map = workspaceMap('a').copyWith(layers: []);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'r0', mapId: 'a'),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    expect(
      MapCanvasStroke.start(
        map: map,
        project: workspaceProject,
        view: view,
        commands: MapEditingCommands(document, workspaceProject),
        origin: const GridPos(x: 2, y: 2),
      ),
      isNull,
    );
    expect(document.dirty, isFalse);
  });
}

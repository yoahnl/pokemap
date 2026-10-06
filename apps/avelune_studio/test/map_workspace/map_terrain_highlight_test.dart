import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/terrains/application/terrain_brush.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_stroke.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_terrain_highlight.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

void main() {
  late ProjectManifest project;
  late ProjectSmartTilePreset preset;
  late MapWorkspaceViewState view;
  late MapData source;
  setUp(() {
    final draft = terrainDraft();
    assignAll(draft);
    project = publishFixture(draft);
    preset = project.smartTileCatalog.presets.single;
    view = MapWorkspaceViewState()
      ..terrain = preset
      ..tool = StudioMapTool.terrain;
    source = applyTerrainStroke(
      map: workspaceMap('a'),
      manifest: project,
      preset: preset,
      cells: [
        for (var y = 2; y <= 4; y++)
          for (var x = 2; x <= 4; x++)
            if (x != 3 || y != 3) GridPos(x: x, y: y),
        const GridPos(x: 8, y: 8),
      ],
    );
  });
  tearDown(() => view.dispose());

  test('highlight follows painted cells, holes and disconnected islands', () {
    final highlight = MapTerrainHighlight.resolve(source, view)!;
    expect(highlight.contains(2, 2), isTrue);
    expect(highlight.contains(3, 3), isFalse);
    expect(highlight.contains(6, 6), isFalse);
    expect(highlight.contains(8, 8), isTrue);
    expect(highlight.contains(-1, 0), isFalse);
    expect(highlight.contains(20, 0), isFalse);
  });

  test(
    'an invisible layer is excluded and the existing paint target is retained',
    () {
      final layer = source.layers.whereType<SmartTileLayer>().single;
      final hidden = layer.copyWith(id: 'hidden', isVisible: false);
      final duplicate = layer.copyWith(id: 'second');
      final map = source.copyWith(
        layers: [hidden, ...source.layers, duplicate],
      );
      expect(MapTerrainHighlight.resolve(map, view)!.layer.id, layer.id);
      expect(
        MapTerrainHighlight.resolve(source.copyWith(layers: [hidden]), view),
        isNull,
      );
    },
  );

  test(
    'paint and erase use the transient exact stroke before the single commit',
    () {
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, revision: 'r0', mapId: 'a'),
      );
      final commands = MapEditingCommands(document, project);
      final stroke = MapCanvasStroke.start(
        map: source,
        project: project,
        view: view,
        commands: commands,
        origin: const GridPos(x: 10, y: 6),
      )!;
      stroke.paint(const GridPos(x: 13, y: 6));
      final preview = MapTerrainHighlight.resolve(
        source,
        view,
        stroke: stroke,
      )!;
      for (var x = 10; x <= 13; x++) {
        expect(preview.contains(x, 6), isTrue);
        expect(preview.changeAt(x, 6), 1);
      }
      expect(preview.changeAt(2, 2), 0);
      expect(document.current, same(source));
      expect(document.undoCount, 0);
      document.commit(stroke.commit());
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(
        MapTerrainHighlight.resolve(document.current, view)!.contains(10, 6),
        isFalse,
      );
      document.restore(redo: true);
      expect(
        MapTerrainHighlight.resolve(document.current, view)!.contains(10, 6),
        isTrue,
      );
      view.tool = StudioMapTool.erase;
      final erase = MapCanvasStroke.start(
        map: document.current,
        project: project,
        view: view,
        commands: commands,
        origin: const GridPos(x: 8, y: 8),
      )!;
      final erasing = MapTerrainHighlight.resolve(
        document.current,
        view,
        stroke: erase,
      )!;
      expect(erasing.contains(8, 8), isFalse);
      expect(erasing.changeAt(8, 8), -1);
      expect(
        MapTerrainHighlight.resolve(document.current, view)!.contains(8, 8),
        isTrue,
      );
      expect(document.undoCount, 1);
    },
  );

  test('tool, preset and view changes do not leak highlight across maps', () {
    final second = MapWorkspaceViewState()
      ..terrain = preset
      ..tool = StudioMapTool.terrain;
    addTearDown(second.dispose);
    view.highlightTerrain = false;
    expect(MapTerrainHighlight.resolve(source, view), isNull);
    expect(MapTerrainHighlight.resolve(source, second), isNotNull);
    expect(MapTerrainHighlight.resolve(workspaceMap('b'), second), isNull);
    second.tool = StudioMapTool.select;
    expect(MapTerrainHighlight.resolve(source, second), isNull);
    view.highlightTerrain = true;
    view.terrain = preset.copyWith(id: 'removed');
    expect(MapTerrainHighlight.resolve(source, view), isNull);
    expect(
      source.layers.whereType<SmartTileLayer>().single.presetId,
      preset.id,
    );
  });
}

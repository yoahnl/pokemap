import 'dart:convert';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_choices.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('drawn rectangle configures entry path exit, direction, Surf and Undo without JSON', () {
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'initial',
        mapId: 'a',
      ),
    );
    final commands = GameplayZoneEditingCommands(document, workspaceProject);
    final zone = commands.place(
      GameplayZoneKind.fieldAction,
      const MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 2, height: 4),
      ),
    );
    commands.configureWaterfall(
      zone.id,
      direction: MapConnectionDirection.north,
      requiresSurf: false,
    );
    final edited = document.current;
    final route = edited.gameplayZones.single.fieldAction!.waterfall!;
    expect(route.entry, const GridPos(x: 0, y: 3));
    expect(route.path, const [GridPos(x: 0, y: 2), GridPos(x: 0, y: 1)]);
    expect(route.exit, const GridPos(x: 0, y: 0));
    expect(route.requiresSurf, isFalse);
    expect(
      MapData.fromJson(
        jsonDecode(jsonEncode(edited.toJson())) as Map<String, dynamic>,
      ),
      edited,
    );
    document.restore(redo: false);
    expect(
      document.current.gameplayZones.single.fieldAction!.darkness,
      isNotNull,
    );
    document.restore(redo: true);
    expect(document.current, edited);
    expect(
      () => commands.configureWaterfall(
        zone.id,
        direction: MapConnectionDirection.east,
      ),
      throwsA(isA<Exception>()),
    );
    expect(document.current, edited);
  });
  testWidgets(
    'canvas paints the Cascade entry, path and exit over the drawn rectangle',
    (tester) async {
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'initial',
          mapId: 'a',
        ),
      );
      final commands = GameplayZoneEditingCommands(document, workspaceProject);
      final zone = commands.place(
        GameplayZoneKind.fieldAction,
        const MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 4),
        ),
      );
      final before = document.current;
      commands.configureWaterfall(
        zone.id,
        direction: MapConnectionDirection.north,
      );
      Future<List<int>> pixels(MapData map) async {
        final recorder = ui.PictureRecorder();
        MapEditingOverlay(
          map: map,
          project: workspaceProject,
          selected: null,
          cellWidth: 32,
          cellHeight: 32,
          grid: false,
          color: ThemeData().colorScheme.primary,
        ).paint(Canvas(recorder), const Size(256, 256));
        final picture = recorder.endRecording();
        final image = await picture.toImage(256, 256);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        return data;
      }

      await tester.runAsync(() async {
        expect(await pixels(document.current), isNot(await pixels(before)));
      });
    },
  );
  test(
    'traversal choices expose valid entry and exit indices for its direction',
    () {
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'initial',
          mapId: 'a',
        ),
      );
      final commands = GameplayZoneEditingCommands(document, workspaceProject);
      final zone = commands.place(
        GameplayZoneKind.fieldAction,
        const MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 4),
        ),
      );
      commands.configureWaterfall(
        zone.id,
        direction: MapConnectionDirection.north,
      );
      var choices = MapFieldTraversalChoices(commands.selected(zone.id)!);
      expect(choices.vertical, isTrue);
      expect(choices.forward, isFalse);
      expect(choices.start, 3);
      expect(choices.end, 0);
      expect(choices.entryIndices, [2, 3]);
      expect(choices.exitIndices, [0, 1]);
      commands.configureWaterfall(
        zone.id,
        direction: MapConnectionDirection.south,
      );
      choices = MapFieldTraversalChoices(commands.selected(zone.id)!);
      expect(choices.forward, isTrue);
      expect(choices.entryIndices, [0, 1]);
      expect(choices.exitIndices, [2, 3]);
      expect(
        commands.selected(zone.id)!.fieldAction!.waterfall!.requiresSurf,
        isTrue,
      );
    },
  );
}

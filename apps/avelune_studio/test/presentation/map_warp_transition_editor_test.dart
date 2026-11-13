import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show MapWarpTransitionPreview, MapWarpTransitionOverlay;

void main() {

  testWidgets(
    'shared runtime preview animates and replays without map mutation',
    (tester) async {
      final document = _document(_map());
      final before = document.current;
      var replay = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, refresh) => Column(
              children: [
                Expanded(
                  child: MapWarpTransitionPreview(
                    key: ValueKey(replay),
                    transition: const MapWarpTransition(
                      type: MapWarpTransitionType.hgss,
                      durationSeconds: .4,
                    ),
                    child: const SizedBox(),
                  ),
                ),
                TextButton(
                  onPressed: () => refresh(() => replay++),
                  child: const Text('Rejouer'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final overlay = tester.widget<MapWarpTransitionOverlay>(
        find.byType(MapWarpTransitionOverlay),
      );
      expect(overlay.coverage, greaterThan(0));
      expect(overlay.coverage, lessThan(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rejouer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<MapWarpTransitionOverlay>(
              find.byType(MapWarpTransitionOverlay),
            )
            .coverage,
        greaterThan(0),
      );
      await tester.pumpWidget(const SizedBox());
      expect(document.current, before);
      expect(document.undoCount, 0);
    },
  );
}

EditableMapDocument _document(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
);

MapData _map() => MapData(
  id: 'outside',
  name: 'Village',
  size: const GridSize(width: 8, height: 8),
  warps: const [
    MapWarp(
      id: 'house',
      pos: GridPos(x: 3, y: 3),
      targetMapId: 'room',
      targetPos: GridPos(x: 2, y: 2),
    ),
    MapWarp(
      id: 'stairs',
      pos: GridPos(x: 5, y: 3),
      targetMapId: 'room',
      targetPos: GridPos(x: 4, y: 4),
      transition: MapWarpTransition(
        type: MapWarpTransitionType.none,
        durationSeconds: .1,
      ),
    ),
  ],
);

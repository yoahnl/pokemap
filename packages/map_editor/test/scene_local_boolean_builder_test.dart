import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';

void main() {
  testWidgets('local memory picks a real owner on the selected 2D map', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SceneActionBuilder(
              initialCommandId: NarrativeCommandIds.setMapEventInstanceBoolean,
              initialParameters: const {
                'mapId': 'room',
                'eventId': 'owner',
                'key': 'opened',
                'value': 'true',
              },
              project: const ProjectManifest(
                name: 'Local memory',
                maps: [],
                tilesets: [],
              ),
              pickerOptions: const {
                NarrativeCommandParameterKind.map: [
                  SceneActionPickerOption(id: 'room', label: 'Room'),
                ],
              },
              loadWarpMap: (id) async => MapData(
                id: id,
                name: 'Room',
                size: const GridSize(width: 4, height: 4),
                entities: const [
                  MapEntity(
                    id: 'owner',
                    name: 'Guide',
                    kind: MapEntityKind.custom,
                    pos: GridPos(x: 1, y: 1),
                  ),
                ],
              ),
              onSubmit: (value) => submitted = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Guide'), findsOneWidget);
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      (submitted as SceneActionPayload).consequence,
      SceneConsequence.setMapEventInstanceBoolean(
        mapId: 'room',
        eventId: 'owner',
        key: 'opened',
        value: true,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

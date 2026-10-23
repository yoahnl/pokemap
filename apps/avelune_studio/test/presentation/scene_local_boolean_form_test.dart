import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'local memory picks a real map owner and blocks removed references',
    (tester) async {
      final applied = <SceneNodePayload>[];
      var exists = true;
      final current = SceneActionPayload.consequence(
        SceneConsequence.setMapEventInstanceBoolean(
          mapId: 'room',
          eventId: 'owner',
          key: 'opened',
          value: true,
        ),
      );
      const project = ProjectManifest(
        name: 'Local memory',
        tilesets: [],
        maps: [
          ProjectMapEntry(
            id: 'room',
            name: 'Room',
            relativePath: 'maps/room.json',
          ),
        ],
      );
      Future<MapData> load(String id) async => MapData(
        id: id,
        name: 'Room',
        size: const GridSize(width: 5, height: 5),
        entities: [
          if (exists)
            const MapEntity(
              id: 'owner',
              name: 'Guide',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 1, y: 1),
            ),
        ],
      );
      Future<void> mount(Key key) => tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionForm(
                key: key,
                project: project,
                current: current,
                loadMap: load,
                onApply: applied.add,
              ),
            ),
          ),
        ),
      );
      await mount(const ValueKey('present'));
      await tester.pumpAndSettle();
      expect(find.text('Guide'), findsOneWidget);
      final owner = tester
          .widgetList<StudioSelect>(find.byType(StudioSelect))
          .singleWhere((select) => select.label == 'Propriétaire logique');
      expect(owner.options.keys, ['owner']);
      await tester.ensureVisible(find.text('Appliquer l’action'));
      await tester.tap(find.text('Appliquer l’action'));
      expect(
        (applied.single as SceneActionPayload).consequence,
        current.consequence,
      );
      exists = false;
      await mount(const ValueKey('removed'));
      await tester.pumpAndSettle();
      final button = tester.widget<StudioButton>(
        find.byType(StudioButton).last,
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

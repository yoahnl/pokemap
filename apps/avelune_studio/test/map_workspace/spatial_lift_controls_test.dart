import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_lift_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'create edit reject and undo a vertical platform through guided controls',
    (tester) async {
      final deck = SpatialModelInstance(
        id: 'deck',
        modelId: 'model',
        position: Model3dVector3(x: 2, y: 0, z: 2),
      );
      final map = MapData(
        id: 'room',
        version: ProjectVersion.v9,
        name: 'Room',
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(width: 8, depth: 8, instances: [deck]),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'initial', mapId: map.id),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpatialLiftControls(
                document: document,
                instance: deck,
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      Future<void> press(String label) async {
        final button = find.text(label);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
      }

      await press('Créer la plateforme');
      expect(document.current.spatialScene!.lifts.single.instanceId, 'deck');
      expect(
        document.current.spatialScene!.instances,
        map.spatialScene!.instances,
      );
      final field = find.byWidgetPredicate(
        (w) => w is StudioDraftField && w.label == 'Hauteur haute',
      );
      await tester.ensureVisible(field);
      await tester.enterText(
        find.descendant(of: field, matching: find.byType(TextField)),
        '3,25',
      );
      await press('Appliquer les réglages');
      expect(document.current.spatialScene!.lifts.single.upperHeight, 3.25);
      final before = document.current;
      await tester.ensureVisible(field);
      await tester.enterText(
        find.descendant(of: field, matching: find.byType(TextField)),
        '-1',
      );
      await press('Appliquer les réglages');
      expect(document.current, same(before));
      await press('Retirer le mécanisme');
      expect(document.current.spatialScene!.lifts, isEmpty);
      document.restore(redo: false);
      expect(document.current.spatialScene!.lifts.single.upperHeight, 3.25);
      expect(tester.takeException(), isNull);
    },
  );
}

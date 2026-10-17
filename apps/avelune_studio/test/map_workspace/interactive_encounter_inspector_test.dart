import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_marker_inspector.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final trigger in InteractiveEncounterTrigger.values) {
    testWidgets('Studio guides ${trigger.name} table and reuse with undo', (
      tester,
    ) async {
      final entity = MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 2, y: 2),
        editorVisual: const MapEntityEditorVisual(elementId: 'tree'),
        fieldObstacle: trigger == InteractiveEncounterTrigger.afterRockSmash
            ? const MapEntityFieldObstacleData(
                kind: FieldObstacleKind.rockSmashRock,
              )
            : null,
      );
      final map = workspaceMap('a').copyWith(entities: [entity]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'base', mapId: 'a'),
      );
      final project = workspaceProject.copyWith(
        encounterTables: [
          ProjectEncounterTable(
            id: 'objects',
            name: 'Rencontres des objets',
            encounterKind: trigger == InteractiveEncounterTrigger.headbutt
                ? EncounterKind.headbutt
                : EncounterKind.special,
            entries: const [
              ProjectEncounterEntry(
                speciesId: 'test',
                minLevel: 2,
                maxLevel: 2,
              ),
            ],
          ),
        ],
      );
      VoidCallback redraw = () {};
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                redraw = () => setState(() {});
                return SingleChildScrollView(
                  child: SizedBox(
                    width: 350,
                    child: MapMarkerInspector(
                      document: document,
                      project: project,
                      entity: document.current.entities.single,
                      onChanged: redraw,
                      onDeleted: () {},
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      final toggle = find.byKey(const ValueKey('interactive-encounter-enable'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        document.current.entities.single.interactiveEncounter?.trigger,
        trigger,
      );
      final once = find.byKey(const ValueKey('interactive-encounter-once'));
      await tester.ensureVisible(once);
      await tester.tap(once);
      await tester.pumpAndSettle();
      expect(
        document.current.entities.single.interactiveEncounter?.reusePolicy,
        InteractiveEncounterReusePolicy.oncePerMapInstance,
      );
      expect(tester.widget<StudioChoice>(once).selected, isTrue);
      document.restore(redo: false);
      redraw();
      await tester.pumpAndSettle();
      expect(
        document.current.entities.single.interactiveEncounter?.reusePolicy,
        InteractiveEncounterReusePolicy.repeatable,
      );
      document.restore(redo: false);
      redraw();
      await tester.pumpAndSettle();
      expect(document.current, map);
      expect(tester.takeException(), isNull);
    });
  }
}

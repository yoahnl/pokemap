import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const area = MapRect(
  pos: GridPos(x: 2, y: 2),
  size: GridSize(width: 4, height: 3),
);

MapTrigger trigger(String id) => MapTrigger(
  id: id,
  name: 'Zone d’histoire',
  type: TriggerType.event,
  area: area,
);

void main() {
  late EditableMapDocument document;
  late TriggerEditingCommands commands;
  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    commands = TriggerEditingCommands(document, workspaceProject);
  });

  test('a story zone goes through the shared validation now', () {
    commands.add(trigger('quai'));
    expect(document.current.triggers.single.id, 'quai');
    expect(
      () => commands.add(trigger('quai')),
      throwsA(isA<ValidationException>()),
      reason: 'map_core refuses a duplicate id instead of stacking it',
    );
    expect(
      () => commands.add(
        MapTrigger(
          id: 'dehors',
          type: TriggerType.event,
          area: const MapRect(
            pos: GridPos(x: 40, y: 40),
            size: GridSize(width: 2, height: 2),
          ),
        ),
      ),
      throwsA(isA<ValidationException>()),
      reason: 'a zone outside the map never reaches the document',
    );
    expect(document.current.triggers, hasLength(1));
  });

  test('a story zone is renamed, moved, resized and removed', () {
    commands.add(trigger('quai'));
    commands.rename('quai', 'Quai numéro 3');
    commands.move('quai', const GridPos(x: 8, y: 6));
    commands.resize('quai', const GridSize(width: 2, height: 2));

    final updated = commands.selected('quai')!;
    expect(updated.name, 'Quai numéro 3');
    expect(updated.area.pos, const GridPos(x: 8, y: 6));
    expect(updated.area.size, const GridSize(width: 2, height: 2));

    expect(commands.deletionProblem('quai'), isNull);
    commands.delete('quai');
    expect(document.current.triggers, isEmpty);

    document.restore(redo: false);
    expect(commands.selected('quai')!.name, 'Quai numéro 3');
  });

  test('a zone the story uses refuses to be deleted', () {
    commands.add(trigger('quai'));
    final linked = TriggerEditingCommands(
      document,
      workspaceProject.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: 'evt_0192bc3d-4e5f-7a1b-8c2d-3e4f5a6b7c8d',
                name: 'Rencontre du quai',
                source: NarrativeEventSourceRef.triggerEnter('a', 'quai'),
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      ),
    );

    expect(
      linked.deletionProblem('quai'),
      contains('interaction de l’histoire'),
      reason: 'the author is told what holds the zone, not left guessing',
    );
    expect(() => linked.delete('quai'), throwsStateError);
    expect(
      document.current.triggers,
      hasLength(1),
      reason: 'a refused deletion never reaches the document',
    );
    expect(
      commands.deletionProblem('quai'),
      isNull,
      reason: 'without that record the same zone is free to go',
    );
  });

  test('the zone under a point is the one reported', () {
    commands.add(trigger('quai'));
    expect(commands.at(const GridPos(x: 3, y: 3)).single.id, 'quai');
    expect(commands.at(const GridPos(x: 9, y: 9)), isEmpty);
  });

  testWidgets('clicking with the story tool finds the zone again', (
    tester,
  ) async {
    commands.add(trigger('quai'));
    final view = MapWorkspaceViewState()..tool = StudioMapTool.zone;
    addTearDown(view.dispose);
    final drawn = <MapRect>[];

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
              onZoneDrawn: drawn.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );

    await tester.tapAt(
      box.localToGlobal(const Offset(3 * 32 + 16, 3 * 32 + 16)),
    );
    await tester.pump();
    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.trigger),
      'quai',
      reason: 'the author comes back to an existing story zone',
    );
    expect(
      drawn,
      isEmpty,
      reason: 'clicking an existing zone never opens a new interaction',
    );

    await tester.tapAt(
      box.localToGlobal(const Offset(9 * 32 + 16, 9 * 32 + 16)),
    );
    await tester.pump();
    expect(
      drawn.single,
      const MapRect(
        pos: GridPos(x: 9, y: 9),
        size: GridSize(width: 1, height: 1),
      ),
      reason: 'on empty ground the story path still opens',
    );
    expect(tester.takeException(), isNull);
  });
}

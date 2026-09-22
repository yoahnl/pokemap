import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/draft_reference_fixture.dart';
import '../support/ui12_world_harness.dart';

void main() {
  late Ui12WorldHarness h;
  setUp(() async => h = await Ui12WorldHarness.create());
  tearDown(() async {
    h.world.dispose();
    h.maps.dispose();
    if (h.directory.existsSync()) {
      await h.directory.delete(recursive: true);
    }
  });

  test('a story zone used by an unsaved event refuses to be deleted', () async {
    await h.maps.activate(
      h.maps.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
    );
    final document = h.maps.active!;
    final triggers = TriggerEditingCommands(document, h.maps.project!);
    triggers.add(
      const MapTrigger(
        id: 'quai',
        name: 'Quai',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 4, y: 4),
          size: GridSize(width: 3, height: 3),
        ),
      ),
    );
    final events = EventWorkspaceController(
      h.world.narrative,
      LocalEventAdapter(session: h.session, mapAdapter: h.adapter),
      changed: () {},
    );
    addTearDown(events.dispose);
    await events.prepare();
    final index = MapDraftReferenceIndex(() => sourcesOf(h, events: events));
    final guarded = TriggerEditingCommands(
      document,
      h.maps.project!,
      draftGuard: index.guard,
    );
    expect(guarded.deletionProblem('quai'), isNull);

    expect(
      events.create(
        'Entrée sur le quai',
        source: NarrativeEventSourceRef.triggerEnter('jardin', 'quai'),
      ),
      isNotNull,
      reason: events.error,
    );

    expect(
      guarded.deletionProblem('quai'),
      contains('brouillon'),
      reason: 'a trigger source is a reference of its own',
    );
    expect(() => guarded.delete('quai'), throwsStateError);
    expect(guarded.selected('quai'), isNotNull);
  });

  test(
    'a character targeted by an unsaved rule refuses to be deleted',
    () async {
      await h.maps.activate(
        h.maps.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
      );
      final document = h.maps.active!;
      final characters = CharacterEditingCommands(document, h.maps.project!);
      final npc = characters.place(
        const ProjectCharacterEntry(
          id: 'guide',
          name: 'Chef de gare',
          tilesetId: 'atelier',
        ),
        const GridPos(x: 6, y: 6),
      );
      final index = MapDraftReferenceIndex(() => sourcesOf(h));
      final guarded = CharacterEditingCommands(
        document,
        h.maps.project!,
        draftGuard: index.guard,
      );
      expect(guarded.deletionProblem(npc.id), isNull);

      final ruleId = h.world.createRule();
      h.world.editRule(
        ruleId,
        (draft) => draft.target = WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'jardin',
          entityId: npc.id,
        ),
      );

      expect(guarded.deletionProblem(npc.id), contains('brouillon'));
      expect(() => guarded.delete(npc.id), throwsStateError);
      expect(guarded.selected(npc.id), isNotNull);
    },
  );
}

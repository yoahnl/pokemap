import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/ui12_world_harness.dart';

MapDraftReferenceSources sourcesOf(
  Ui12WorldHarness h, {
  EventWorkspaceController? events,
}) => MapDraftReferenceSources(
  eventDrafts: [
    if (events != null)
      for (final id in events.dirtyIds)
        ?events.record(id),
  ],
  ruleTargets: [
    for (final draft in h.world.pendingRules.values)
      if (draft.target?.entityId case final entityId?)
        (mapId: draft.target!.mapId, entityId: entityId),
  ],
);

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

  Future<MapEntity> signOn(String mapId) async {
    await h.maps.activate(
      h.maps.project!.maps.firstWhere((entry) => entry.id == mapId),
    );
    return MapEntityEditingCommands(
      h.maps.active!,
      h.maps.project!,
    ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
  }

  test('an unsaved world rule draft protects the entity it targets', () async {
    final sign = await signOn('jardin');
    final document = h.maps.active!;
    final index = MapDraftReferenceIndex(() => sourcesOf(h));
    final commands = MapEntityEditingCommands(
      document,
      h.maps.project!,
      draftGuard: index.guard,
    );
    expect(commands.deletionProblem(sign.id), isNull);

    final ruleId = h.world.createRule();
    h.world.editRule(
      ruleId,
      (draft) => draft.target = WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: 'jardin',
        entityId: sign.id,
      ),
    );
    expect(
      h.world.pendingRules[ruleId]?.complete,
      isNull,
      reason: 'the draft stays incomplete: this is the case that used to slip',
    );

    final steps = document.undoCount;
    expect(commands.deletionProblem(sign.id), contains('brouillon'));
    expect(() => commands.delete(sign.id), throwsStateError);
    expect(commands.selected(sign.id), isNotNull);
    expect(document.undoCount, steps);
    expect(
      h.world.pendingRules[ruleId],
      isNotNull,
      reason: 'the refused deletion abandons no draft',
    );
  });

  test('an unsaved event draft protects the entity it targets', () async {
    final sign = await signOn('jardin');
    final document = h.maps.active!;
    final events = EventWorkspaceController(
      h.world.narrative,
      LocalEventAdapter(session: h.session, mapAdapter: h.adapter),
      changed: () {},
    );
    addTearDown(events.dispose);
    await events.prepare();
    final index = MapDraftReferenceIndex(() => sourcesOf(h, events: events));
    final commands = MapEntityEditingCommands(
      document,
      h.maps.project!,
      draftGuard: index.guard,
    );
    expect(commands.deletionProblem(sign.id), isNull);

    final created = events.create(
      'Lecture du panneau',
      source: NarrativeEventSourceRef.entityInteract('jardin', sign.id),
    );
    expect(created, isNotNull, reason: events.error);
    expect(events.dirtyIds, contains(created!.id));

    expect(commands.deletionProblem(sign.id), contains('brouillon'));
    expect(() => commands.delete(sign.id), throwsStateError);
    expect(commands.selected(sign.id), isNotNull);
  });

  test(
    'a draft targeting a twin id on another map blocks nothing here',
    () async {
      final sign = await signOn('jardin');
      final document = h.maps.active!;
      final index = MapDraftReferenceIndex(() => sourcesOf(h));
      final commands = MapEntityEditingCommands(
        document,
        h.maps.project!,
        draftGuard: index.guard,
      );

      final ruleId = h.world.createRule();
      h.world.editRule(
        ruleId,
        (draft) => draft.target = WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'clairiere',
          entityId: sign.id,
        ),
      );

      expect(
        commands.deletionProblem(sign.id),
        isNull,
        reason: 'the draft points at another map, not at this entity',
      );
      commands.delete(sign.id);
      expect(commands.selected(sign.id), isNull);
      document.restore(redo: false);
      expect(commands.selected(sign.id), isNotNull);
    },
  );

  test('a dependency added after the first read is honoured', () async {
    final sign = await signOn('jardin');
    final document = h.maps.active!;
    final index = MapDraftReferenceIndex(() => sourcesOf(h));
    final commands = MapEntityEditingCommands(
      document,
      h.maps.project!,
      draftGuard: index.guard,
    );
    expect(commands.deletionProblem(sign.id), isNull);

    final ruleId = h.world.createRule();
    h.world.editRule(
      ruleId,
      (draft) => draft.target = WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: 'jardin',
        entityId: sign.id,
      ),
    );

    expect(
      commands.deletionProblem(sign.id),
      isNotNull,
      reason: 'the index refreshes when the drafts change, not once at open',
    );
  });

  test('removing the draft frees the entity again', () async {
    final sign = await signOn('jardin');
    final document = h.maps.active!;
    final index = MapDraftReferenceIndex(() => sourcesOf(h));
    final commands = MapEntityEditingCommands(
      document,
      h.maps.project!,
      draftGuard: index.guard,
    );
    final ruleId = h.world.createRule();
    h.world.editRule(
      ruleId,
      (draft) => draft.target = WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: 'jardin',
        entityId: sign.id,
      ),
    );
    expect(commands.deletionProblem(sign.id), isNotNull);

    h.world.pendingRules.remove(ruleId);
    expect(commands.deletionProblem(sign.id), isNull);
    commands.delete(sign.id);
    expect(commands.selected(sign.id), isNull);
  });
}

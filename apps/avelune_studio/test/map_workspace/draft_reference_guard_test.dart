import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/draft_reference_fixture.dart';

void main() {
  late DraftReferenceProject h;
  setUp(() async => h = await DraftReferenceProject.create());
  tearDown(() => h.dispose());

  test('an unsaved world rule draft protects the entity it targets', () async {
    final sign = await h.signOn('jardin');
    final document = h.maps.active!;
    final index = MapDraftReferenceIndex(h.sources);
    final commands = MapEntityEditingCommands(
      document,
      h.maps.project!,
      draftGuard: index.guard,
    );
    expect(commands.deletionProblem(sign.id), isNull);

    h.targetEntity('jardin', sign.id);

    final steps = document.undoCount;
    expect(commands.deletionProblem(sign.id), contains('brouillon'));
    expect(() => commands.delete(sign.id), throwsStateError);
    expect(commands.selected(sign.id), isNotNull);
    expect(document.undoCount, steps);
    expect(h.ruleTargets, hasLength(1));
  });

  test(
    'a draft targeting a twin id on another map blocks nothing here',
    () async {
      final sign = await h.signOn('jardin');
      final document = h.maps.active!;
      final index = MapDraftReferenceIndex(h.sources);
      final commands = MapEntityEditingCommands(
        document,
        h.maps.project!,
        draftGuard: index.guard,
      );

      h.targetEntity('clairiere', sign.id);

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
    final sign = await h.signOn('jardin');
    final document = h.maps.active!;
    final index = MapDraftReferenceIndex(h.sources);
    final commands = MapEntityEditingCommands(
      document,
      h.maps.project!,
      draftGuard: index.guard,
    );
    expect(commands.deletionProblem(sign.id), isNull);

    h.targetEntity('jardin', sign.id);

    expect(
      commands.deletionProblem(sign.id),
      isNotNull,
      reason: 'the index refreshes when the drafts change, not once at open',
    );
  });

  test('removing the draft frees the entity again', () async {
    final sign = await h.signOn('jardin');
    final document = h.maps.active!;
    final index = MapDraftReferenceIndex(h.sources);
    final commands = MapEntityEditingCommands(
      document,
      h.maps.project!,
      draftGuard: index.guard,
    );
    h.targetEntity('jardin', sign.id);
    expect(commands.deletionProblem(sign.id), isNotNull);

    h.ruleTargets.clear();
    expect(commands.deletionProblem(sign.id), isNull);
    commands.delete(sign.id);
    expect(commands.selected(sign.id), isNull);
  });

  test('a configured record is read from its definition, not its draft', () {
    // The business state says configured; the working version is still
    // unsaved. Its source then lives in the definition.
    final configured = NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_0192bc3d-4e5f-7a1b-8c2d-3e4f5a6b7c8d',
        name: 'Lecture',
        source: NarrativeEventSourceRef.entityInteract('jardin', 'panneau'),
        conditions: const [],
        conditionExpression: NarrativeEventConditionExpression.all(const []),
        sceneId: 'scene',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    );
    expect(configured.draftOrNull, isNull);
    expect(recordSource(configured), isNotNull);

    final index = MapDraftReferenceIndex(
      () => MapDraftReferenceSources(eventDrafts: [configured]),
    );
    expect(
      index.problemFor(mapId: 'jardin', entityId: 'panneau'),
      contains('brouillon'),
      reason: 'the guard follows the source wherever the shape keeps it',
    );
    expect(index.problemFor(mapId: 'clairiere', entityId: 'panneau'), isNull);
  });
}

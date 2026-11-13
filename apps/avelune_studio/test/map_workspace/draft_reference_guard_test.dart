import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

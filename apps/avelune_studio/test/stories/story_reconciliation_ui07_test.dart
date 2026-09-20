import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/story_backend_fixture.dart';

void main() {
  test(
    'explicit reload reconciles target and preserves every unrelated dirty draft',
    () async {
      final a = backendStory('a'), b = backendStory('b');
      final f = await StoryBackendFixture.create(stories: [a, b]);
      addTearDown(f.dispose);
      final c = f.attach()..open(a.id);
      final localA = a.copyWith(title: 'A local'),
          localB = b.copyWith(title: 'B local');
      c.mutate((p) => p.copyWith(storylines: [localA, localB]));
      f.narrative.addFact('État non enregistré');
      final pendingFact = f.narrative.facts.single;
      final external = a.copyWith(title: 'A externe');
      await f.port.publishStory(id: a.id, base: a, current: external);
      expect(await c.reload(a.id, expectedStory: localA), true);
      expect(c.active, external);
      expect(c.stories, [external, localB]);
      expect(f.narrative.pendingStories, {b.id: localB});
      expect(f.narrative.pendingFacts, {pendingFact.id: pendingFact});
      expect(c.error, isNull);
      expect(c.canUndo, false);
      expect(await c.saveAll(), true);
      expect((await f.readFresh()).storylines, [external, localB]);
      expect((await f.readFresh()).facts, [pendingFact]);
    },
  );

  test(
    'reload cannot discard changes newer than the confirmed snapshot',
    () async {
      final initial = backendStory('a');
      final f = await StoryBackendFixture.create(stories: [initial]);
      addTearDown(f.dispose);
      final c = f.attach()..open(initial.id);
      final first = initial.copyWith(title: 'Confirmé');
      c.apply(
        updateStoryline(c.project, storylineId: initial.id, storyline: first),
      );
      final latest = initial.copyWith(title: 'Plus récent');
      c.apply(
        updateStoryline(c.project, storylineId: initial.id, storyline: latest),
      );
      expect(await c.reload(initial.id, expectedStory: first), false);
      expect(c.active, latest);
      expect(c.dirty, true);
      expect(c.error, contains('conservé'));
    },
  );

  test(
    'multi-owner deletion publishes consumers before referenced stories',
    () async {
      final a = backendStory('a');
      final b = backendStory('b').copyWith(
        relationships: [
          StorylineRelationship(
            id: 'requires_a',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'b',
            targetStorylineId: 'a',
          ),
        ],
      );
      final f = await StoryBackendFixture.create(stories: [a, b]);
      addTearDown(f.dispose);
      final c = f.attach();
      c.mutate((project) {
        final removeConsumer = deleteStoryline(project, storylineId: b.id);
        expect(removeConsumer.isApplied, true);
        final removeTarget = deleteStoryline(
          removeConsumer.after,
          storylineId: a.id,
        );
        expect(removeTarget.isApplied, true);
        return removeTarget.after;
      });
      expect(f.narrative.pendingStoryDeletions.toList(), [a.id, b.id]);
      expect(await c.saveAll(), true, reason: c.error);
      expect((await f.readFresh()).storylines, isEmpty);
      c.restore(redo: false);
      expect(c.stories, [a, b]);
      expect(await c.saveAll(), true, reason: c.error);
      expect((await f.readFresh()).storylines, [a, b]);
    },
  );
}

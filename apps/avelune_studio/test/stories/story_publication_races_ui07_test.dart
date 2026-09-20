import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/delayed_story_port.dart';
import '../support/story_backend_fixture.dart';

void main() {
  for (final revertToBase in [false, true]) {
    test(
      'edit during publication stays dirty, revertToBase=$revertToBase',
      () async {
        final base = backendStory('trip');
        final f = await StoryBackendFixture.create(stories: [base]);
        addTearDown(f.dispose);
        final delayed = DelayedStoryPort(f.port);
        final c = f.attach(overridePort: delayed)..open(base.id);
        final snapshot = base.copyWith(title: 'À enregistrer');
        c.apply(
          updateStoryline(c.project, storylineId: base.id, storyline: snapshot),
        );
        final saving = c.saveAll();
        await delayed.entered.future.timeout(const Duration(seconds: 5));
        final latest = revertToBase
            ? base
            : base.copyWith(title: 'Pendant écriture');
        c.apply(
          updateStoryline(c.project, storylineId: base.id, storyline: latest),
        );
        delayed.release.complete();
        expect(await saving.timeout(const Duration(seconds: 5)), false);
        expect(c.active, latest);
        expect(c.dirty, true);
        expect((await f.readFresh()).storylines.single, snapshot);
        expect(await c.saveAll(), true);
        expect((await f.readFresh()).storylines.single, latest);
      },
    );
  }

  test(
    'late response after close does not replace the workspace catalog',
    () async {
      final base = backendStory('trip');
      final f = await StoryBackendFixture.create(stories: [base]);
      addTearDown(f.dispose);
      final delayed = DelayedStoryPort(f.port);
      final c = f.attach(overridePort: delayed)..open(base.id);
      c.apply(
        updateStoryline(
          c.project,
          storylineId: base.id,
          storyline: base.copyWith(title: 'Édité'),
        ),
      );
      final saving = c.saveAll();
      await delayed.entered.future.timeout(const Duration(seconds: 5));
      c.dispose();
      delayed.release.complete();
      expect(await saving.timeout(const Duration(seconds: 5)), false);
      expect(f.workspace.project!.storylines.single, base);
      expect(f.narrative.pendingStories[base.id]!.title, 'Édité');
    },
  );

  test(
    'partial multi-owner failure reports written scope and keeps remaining draft',
    () async {
      final a = backendStory('a'), b = backendStory('b');
      final f = await StoryBackendFixture.create(stories: [a, b]);
      addTearDown(f.dispose);
      final delayed = DelayedStoryPort(f.port, failOnStory: 'b');
      final c = f.attach(overridePort: delayed);
      c.mutate(
        (project) => project.copyWith(
          storylines: [
            a.copyWith(title: 'A modifié'),
            b.copyWith(title: 'B modifié'),
          ],
        ),
      );
      final saving = c.saveAll();
      await delayed.entered.future.timeout(const Duration(seconds: 5));
      delayed.release.complete();
      expect(await saving.timeout(const Duration(seconds: 5)), false);
      expect(c.error, contains('1 document(s) déjà enregistré(s)'));
      expect(f.narrative.pendingStories.keys, ['b']);
      final disk = await f.readFresh();
      expect(disk.storylines.first.title, 'A modifié');
      expect(disk.storylines.last, b);
      c.restore(redo: false);
      expect(c.stories, [a, b]);
      expect(f.narrative.pendingStories.keys, ['a']);
    },
  );
}

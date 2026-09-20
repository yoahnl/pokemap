import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/delayed_map_save_port.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  for (final mutation in ['story', 'fact', 'delete']) {
    testWidgets(
      'runtime rejects $mutation changed during subsequent map publication',
      (tester) async {
        final fixture = (await tester.runAsync(Ui06SceneFixture.create))!;
        addTearDown(fixture.dispose);
        final delayed = (await tester.runAsync(
          () async => DelayedMapSavePort(fixture.maps),
        ))!;
        final maps = MapWorkspaceController(fixture.session, delayed);
        addTearDown(maps.dispose);
        await tester.runAsync(maps.initialize);
        final narrative = NarrativeWorkspaceController(
          maps,
          LocalNarrativeAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ),
          () {},
          (_, _) async {},
        );
        addTearDown(narrative.dispose);
        final stories = StoryWorkspaceController(
          narrative,
          LocalStoryAdapter(session: fixture.session, mapAdapter: fixture.maps),
          changed: () {},
        );
        addTearDown(stories.dispose);
        final story = stories.create('Histoire à tester')!;
        maps.active!.commit(
          maps.active!.current.copyWith(name: 'Carte modifiée'),
        );
        late WorkspaceActions actions;
        var launches = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                actions = WorkspaceActions(
                  controller: maps,
                  context: () => context,
                  mounted: () => true,
                  changed: () {},
                  resources: () => null,
                  narrative: () => narrative,
                  runtimeBuilder: (_, _, _) {
                    launches++;
                    return const SizedBox();
                  },
                );
                return const Scaffold(body: Text('Éditeur'));
              },
            ),
          ),
        );
        await tester.runAsync(() async {
          final running = actions.test();
          try {
            await Future.any([
              delayed.entered.future,
              running.then((_) {
                if (!delayed.entered.isCompleted) {
                  throw StateError('${narrative.error}');
                }
              }),
            ]).timeout(const Duration(seconds: 5));
            expect(stories.dirty, false);
            switch (mutation) {
              case 'story':
                stories.apply(
                  updateStoryline(
                    stories.project,
                    storylineId: story.id,
                    storyline: story.copyWith(
                      title: 'Modifiée pendant attente',
                    ),
                  ),
                );
              case 'fact':
                narrative.addFact('Nouvel état tardif');
              case 'delete':
                stories.apply(
                  deleteStoryline(stories.project, storylineId: story.id),
                );
            }
          } finally {
            if (!delayed.release.isCompleted) delayed.release.complete();
          }
          await running.timeout(const Duration(seconds: 5));
        });
        await tester.pump();
        expect(launches, 0);
        expect(stories.dirty, true);
        expect(narrative.publicationError, contains('histoires ou états'));
        expect(maps.active!.dirty, false);
        final disk = (await tester.runAsync(
          () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
        ))!;
        expect(disk.storylines.single, story);
        expect(disk.facts, fixture.manifest.facts);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

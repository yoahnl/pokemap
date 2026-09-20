import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/story_backend_fixture.dart';

void main() {
  test(
    'UI05 and UI07 share drafts, facts and publication without any map',
    () async {
      final f = await StoryBackendFixture.create();
      addTearDown(f.dispose);
      final controller = f.attach();
      f.narrative.addStory('Départ', ['Billet', 'Embarquer']);
      f.narrative.addFact('Billet obtenu');
      final draft = f.narrative.stories.single;
      expect(controller.open(draft.id), true);
      expect(controller.active, same(draft));
      final updated = draft.copyWith(title: 'Départ du train');
      expect(
        controller.apply(
          updateStoryline(
            controller.project,
            storylineId: draft.id,
            storyline: updated,
          ),
        ),
        true,
      );
      expect(f.narrative.stories.single, same(updated));
      final other = controller.create(
        'Bagage oublié',
        type: StorylineType.sideQuest,
      )!;
      final fact = f.narrative.facts.single;
      expect(controller.project.facts, [fact]);
      expect((await f.readFresh()).facts, isEmpty);
      expect(await f.narrative.save(), true, reason: f.narrative.error);
      final reopened = await f.readFresh();
      expect(reopened.maps, isEmpty);
      expect(reopened.storylines, [updated, other]);
      expect(reopened.facts, [fact]);
      expect(controller.dirty, false);
      expect(f.narrative.dirty, false);
      expect(controller.project, same(controller.project));
    },
  );

  test(
    'secondary owner is edited, undone and saved from primary context',
    () async {
      final main = backendStory('main'), side = backendStory('side');
      final f = await StoryBackendFixture.create(stories: [main, side]);
      addTearDown(f.dispose);
      final c = f.attach()..open(main.id);
      expect(
        c.connect(
          StorylineProgressionConnectRequest.relationship(
            relationshipId: 'requires_main',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: side.id,
            targetStorylineId: main.id,
          ),
        ),
        true,
      );
      expect(f.narrative.pendingStories.keys, [side.id]);
      final linked = c.stories.last;
      final before = f.workspace.project!;
      final otherScene = createSceneDraftInProject(
        before,
        name: 'Scène voisine',
      ).createdScene;
      final sceneReceipt = await LocalSceneAdapter(
        session: f.workspace.session,
        mapAdapter: f.maps,
      ).publishScene(base: null, current: otherScene);
      f.workspace.acceptResources(
        sceneReceipt.catalog.before,
        sceneReceipt.catalog.manifest,
      );
      c.restore(redo: false);
      expect(c.stories, [main, side]);
      expect(c.project.scenes, [otherScene]);
      c.restore(redo: true);
      expect(c.stories.last, linked);
      expect(c.project.scenes, [otherScene]);
      final projection = buildStorylineProgressionProjection(
        project: c.project,
        storylineId: main.id,
      );
      final relation = projection.edges.singleWhere(
        (e) => e.source.relationshipId == 'requires_main',
      );
      expect(c.disconnect(relation.id), true);
      expect(f.narrative.pendingStories, isEmpty);
      c.restore(redo: false);
      expect(f.narrative.pendingStories[side.id], linked);
      expect(await c.saveAll(), true);
      final reopened = await f.readFresh();
      expect(reopened.storylines, [main, linked]);
      expect(reopened.scenes, [otherScene]);
    },
  );

  test(
    'rejected duplicate and reciprocal cycle add no history entry',
    () async {
      final f = await StoryBackendFixture.create(
        stories: [backendStory('a'), backendStory('b')],
      );
      addTearDown(f.dispose);
      final c = f.attach()..open('a');
      final request = StorylineProgressionConnectRequest.relationship(
        relationshipId: 'r',
        kind: StorylineRelationshipKind.requires,
        sourceStorylineId: 'b',
        targetStorylineId: 'a',
      );
      expect(c.connect(request), true);
      final snapshot = c.stories;
      expect(c.connect(request), false);
      expect(
        c.connect(
          StorylineProgressionConnectRequest.relationship(
            relationshipId: 'r2',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'a',
            targetStorylineId: 'b',
          ),
        ),
        false,
      );
      expect(c.stories, snapshot);
      c.restore(redo: false);
      expect(c.canUndo, false);
      expect(c.stories.every((s) => s.relationships.isEmpty), true);
    },
  );

  test(
    'clean refresh invalidates stale history; dirty base survives catalog change',
    () async {
      final base = backendStory('a');
      final f = await StoryBackendFixture.create(stories: [base]);
      addTearDown(f.dispose);
      final c = f.attach()..open('a');
      c.apply(
        updateStoryline(
          c.project,
          storylineId: 'a',
          storyline: base.copyWith(title: 'Publié'),
        ),
      );
      expect(await c.saveAll(), true);
      expect(c.canUndo, true);
      final refreshed = base.copyWith(title: 'Édition extérieure');
      final before = f.workspace.project!;
      f.workspace.acceptResources(
        before,
        before.copyWith(storylines: [refreshed]),
      );
      expect(c.active, refreshed);
      expect(c.canUndo, false);
      c.apply(
        updateStoryline(
          c.project,
          storylineId: 'a',
          storyline: refreshed.copyWith(title: 'Local'),
        ),
      );
      final canonical = f.workspace.project!;
      f.workspace.acceptResources(
        canonical,
        canonical.copyWith(storylines: [base]),
      );
      expect(c.active!.title, 'Local');
      expect(c.error, contains('brouillon'));
      expect(c.dirty, true);
    },
  );
  test(
    'history is bounded and repeated consultation uses the same projection source',
    () async {
      final initial = backendStory('trip');
      final f = await StoryBackendFixture.create(stories: [initial]);
      addTearDown(f.dispose);
      final c = f.attach()..open(initial.id);
      final source = c.project;
      for (var i = 0; i < 100; i++) {
        expect(c.project, same(source));
        c.open(initial.id);
      }
      for (var i = 1; i <= 100; i++) {
        c.apply(
          updateStoryline(
            c.project,
            storylineId: initial.id,
            storyline: c.active!.copyWith(title: 'Version $i'),
          ),
        );
      }
      var undo = 0;
      while (c.canUndo) {
        c.restore(redo: false);
        undo++;
      }
      expect(undo, 80);
      expect(c.active!.title, 'Version 20');
      expect((await f.readFresh()).storylines, [initial]);
    },
  );

  test(
    'first declared outcome connection is one reversible aggregate delta',
    () async {
      final initial = backendStory('trip');
      final story = initial.copyWith(
        sceneLinks: [
          StorylineSceneLink(
            id: 'link',
            chapterId: 'trip_chapter',
            label: 'Rencontre',
            order: 0,
            state: StorylineSceneLinkState.linkedScenario,
            role: StorylineSceneLinkRole.primary,
            sceneRef: StorylineSceneRef(
              kind: StorylineSceneRefKind.scenario,
              targetId: 'legacy',
            ),
            expectedOutcomeIds: ['ready'],
          ),
        ],
      );
      final f = await StoryBackendFixture.create(
        stories: [story],
        scenarios: [
          const ScenarioAsset(
            id: 'legacy',
            name: 'Rencontre',
            entryNodeId: 'start',
            declaredOutcomes: ['ready'],
          ),
        ],
      );
      addTearDown(f.dispose);
      final c = f.attach()..open(story.id);
      expect(
        c.connect(
          StorylineProgressionConnectRequest.outcomeEffect(
            storylineId: story.id,
            sceneLinkId: 'link',
            outcomeLinkId: 'outcome-ready',
            outcomeId: 'ready',
            effectType: StorylineEffectType.activateStep,
            targetStepId: 'trip_step',
          ),
        ),
        true,
      );
      expect(
        c.active!.sceneLinks.single.outcomeLinks.single.effects.single.type,
        StorylineEffectType.activateStep,
      );
      c.restore(redo: false);
      expect(c.active!.toJson(), story.toJson());
      expect(c.canUndo, false);
      expect(c.dirty, false);
      c.restore(redo: true);
      expect(c.active!.sceneLinks.single.outcomeLinks.single.effects.length, 1);
    },
  );
}

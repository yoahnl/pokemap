import 'dart:async';

import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_builder_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_story/map_story.dart';

import '../support/event_backend_fixture.dart';
import '../support/ui08_event_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/story_backend_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'story and step routes retain canonical identities without publication',
    () async {
      final fixture = await StoryBackendFixture.create(
        stories: [backendStory('main'), backendStory('side')],
      );
      addTearDown(fixture.dispose);
      final stories = fixture.attach();
      stories.open('side');
      final before = await fixture.readFresh();
      final navigation = WorkspaceNavigationSession(
        controller: fixture.workspace,
        isActive: () => true,
        changed: () {},
        stories: () => stories,
      );
      expect(navigation.openProgression(preferredStoryId: 'main'), isTrue);
      expect(stories.activeId, 'main');
      expect(navigation.space, WorkspaceSpace.progression);
      expect(navigation.openProgressionStep('main', 'main_step'), isTrue);
      expect(navigation.progressionNodes['main']!.stepId, 'main_step');
      expect(navigation.progressionOrigin, WorkspaceReturn.story);
      expect(navigation.openProgressionStep('removed', 'main_step'), isFalse);
      expect(stories.activeId, 'main');
      expect(await fixture.readFresh(), before);
    },
  );

  test('an entity interaction opens its exact scene and preserves the map return owner', () async {
    final fixture = await EventBackendFixture.create();
    addTearDown(fixture.dispose);
    await _addNpc(fixture);
    final events = fixture.attach();
    expect(await events.prepare(), isTrue);
    final map = fixture.workspace.active!.current;
    final entity = map.entities.firstWhere(
      (entity) => entity.kind == MapEntityKind.npc,
    );
    final record = events.create(
      'Interaction',
      source: NarrativeEventSourceRef.entityInteract(map.id, entity.id),
    )!;
    expect(
      events.setScene(record.id, fixture.source.scene.id),
      isTrue,
      reason: events.error,
    );
    final scenes = SceneWorkspaceController(
      fixture.workspace,
      LocalSceneAdapter(
        session: fixture.source.session,
        mapAdapter: fixture.source.maps,
      ),
      narrative: fixture.narrative,
      changed: () {},
    );
    addTearDown(scenes.dispose);
    final navigation = WorkspaceNavigationSession(
      controller: fixture.workspace,
      isActive: () => true,
      changed: () {},
      events: () => events,
      narrative: () => fixture.narrative,
      scenes: () => scenes,
    );
    final before = await fixture.source.maps.loadProject(
      fixture.source.session,
    );
    expect(
      await navigation.openInteractionScene(
        entity,
        choose: (_) async => throw StateError('Single scene needs no chooser'),
      ),
      isNull,
    );
    expect(scenes.active!.current.id, fixture.source.scene.id);
    expect(
      navigation.sceneNodes[fixture.source.scene.id],
      fixture.source.scene.graph.startNodeId,
    );
    expect(navigation.sceneOrigin.space, WorkspaceSpace.map);
    expect(navigation.sceneOrigin.documentId, map.id);
    expect(navigation.sceneOrigin.elementId, entity.id);
    expect(
      await fixture.source.maps.loadProject(fixture.source.session),
      before,
    );
    expect(
      await navigation.openInteractionScene(
        entity.copyWith(id: 'missing'),
        choose: (_) async => null,
      ),
      contains('Aucune interaction'),
    );
  });

  test(
    'a late interaction scene choice cannot replace a newer route',
    () async {
      final fixture = await EventBackendFixture.create();
      addTearDown(fixture.dispose);
      await _addNpc(fixture);
      final events = fixture.attach();
      await events.prepare();
      final map = fixture.workspace.active!.current;
      final entity = map.entities.firstWhere(
        (entity) => entity.kind == MapEntityKind.npc,
      );
      for (final name in ['Premier', 'Second']) {
        final record = events.create(
          name,
          source: NarrativeEventSourceRef.entityInteract(map.id, entity.id),
        )!;
        expect(events.setScene(record.id, fixture.source.scene.id), isTrue);
      }
      final navigation = WorkspaceNavigationSession(
        controller: fixture.workspace,
        isActive: () => true,
        changed: () {},
        events: () => events,
        narrative: () => fixture.narrative,
      );
      final choice = Completer<SceneAsset?>();
      final started = Completer<void>();
      final pending = navigation.openInteractionScene(
        entity,
        choose: (choices) {
          expect(choices, hasLength(2));
          started.complete();
          return choice.future;
        },
      );
      await started.future;
      await navigation.openEvents(null);
      choice.complete(fixture.source.scene);
      expect(await pending, isNull);
      expect(navigation.space, WorkspaceSpace.events);
      expect(navigation.sceneNodes, isEmpty);
    },
  );
  test('overview map return disarms placement erase and pending movement without rewriting the map or viewport', () async {
    final fixture = await EventBackendFixture.create();
    addTearDown(fixture.dispose);
    final document = fixture.workspace.active!;
    final before = document.current;
    final undo = document.undoCount;
    final recorded = await fixture.readFresh();
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final transform = view.transform.value.clone();
    var cancelled = 0;
    final navigation = WorkspaceNavigationSession(
      controller: fixture.workspace,
      isActive: () => true,
      changed: () {},
      mapView: () => view,
    );
    for (final tool in [StudioMapTool.place, StudioMapTool.erase]) {
      navigation.show(WorkspaceSpace.story);
      view.tool = tool;
      view.armMove(
        MapSelectionTarget(
          mapId: before.id,
          family: MapSelectionFamily.decor,
          id: 'pending',
        ),
        'Déplacer le décor',
      );
      expect(
        await navigation.openNarrativeMap(
          before.id,
          cancelGestures: () => cancelled++,
        ),
        isNull,
      );
      expect(navigation.space, WorkspaceSpace.map);
      expect(view.tool, StudioMapTool.select);
      expect(view.pendingMove, isNull);
      expect(document.current, same(before));
      expect(document.undoCount, undo);
      expect(view.transform.value, transform);
    }
    expect(cancelled, 2);
    expect(await fixture.readFresh(), recorded);
  });
  test('event scene and dialogue consultation return to their exact owners without copying or publishing', () async {
    final fixture = await createUi08Fixture();
    addTearDown(fixture.dispose);
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final events = EventWorkspaceController(
      narrative,
      LocalEventAdapter(session: fixture.session, mapAdapter: fixture.maps),
      changed: () {},
    );
    addTearDown(events.dispose);
    expect(await events.prepare(), isTrue, reason: events.error);
    final scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
      narrative: narrative,
      changed: () {},
    );
    addTearDown(scenes.dispose);
    final dialogues = DialogueWorkspaceController(
      narrative,
      LocalDialogueAdapter(session: fixture.session, mapAdapter: fixture.maps),
      changed: () {},
    );
    addTearDown(dialogues.dispose);
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final document = maps.active!;
    final entity = document.current.entities.singleWhere(
      (entity) => entity.id == 'chief',
    );
    view.select(document, MapSelectionFamily.character, entity.id);
    final navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      events: () => events,
      scenes: () => scenes,
      dialogues: () => dialogues,
      narrative: () => narrative,
      mapView: () => view,
    );
    final before = await fixture.readFresh();
    expect(
      await navigation.openInteractionScene(
        entity,
        choose: (_) async => throw StateError('Unexpected chooser'),
      ),
      isNull,
    );
    expect(scenes.active!.current.id, Ui06SceneFixture.sceneId);
    expect(navigation.sceneNodes[Ui06SceneFixture.sceneId], 'start');
    expect(navigation.sceneOrigin.space, WorkspaceSpace.map);
    navigation.show(navigation.sceneOrigin.space);
    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.character),
      entity.id,
    );
    await navigation.openEvents(Ui06SceneFixture.eventId);
    final eventId = events.activeId;
    final dialogueIds = dialogues.entries.map((entry) => entry.id).toList();
    final sceneId = events.active!.definitionOrNull!.sceneId;
    expect(await navigation.openScene(sceneId), isNull);
    expect(navigation.sceneOrigin.space, WorkspaceSpace.events);
    final scene = scenes.active!.current;
    final state = SceneBuilderEditingState();
    String? walk(String branch) {
      state.choices.clear();
      for (var step = 0; step < 12; step++) {
        state.calculate(scene);
        final result = state.preview!;
        final awaiting = result.awaitingNodeId;
        if (result.status != SceneDryRunPreviewStatus.awaitingInput ||
            awaiting == null) {
          return result.sceneOutcomeId;
        }
        state.choices[awaiting] = awaiting == 'pass'
            ? branch
            : result.acceptedOutputPortIds.first;
      }
      return null;
    }

    expect(walk('false'), 'attente');
    expect(walk('true'), 'embarquement');
    expect(state.previewError, isNull);
    navigation.show(navigation.sceneOrigin.space);
    expect(events.activeId, eventId);
    expect(
      await navigation.openDialogue(
        'station_welcome',
        WorkspaceSpace.events,
        startNode: 'Start',
      ),
      isNull,
    );
    expect(dialogues.activeId, 'station_welcome');
    expect(dialogues.active!.startNode, 'Start');
    expect(dialogues.entries.map((entry) => entry.id), dialogueIds);
    navigation.returnFromDialogue();
    expect(navigation.space, WorkspaceSpace.events);
    expect(events.activeId, eventId);
    navigation.show(navigation.eventOrigin);
    expect(navigation.space, WorkspaceSpace.map);
    expect(maps.active, same(document));
    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.character),
      entity.id,
    );
    expect(scenes.dirty, isFalse);
    expect(dialogues.dirty, isFalse);
    expect(events.dirty, isFalse);
    expect(await fixture.readFresh(), before);
  });
}

Future<void> _addNpc(EventBackendFixture fixture) async {
  final document = fixture.workspace.active!;
  document.commit(
    document.current.copyWith(
      entities: [
        ...document.current.entities,
        const MapEntity(
          id: 'chief',
          name: 'Chef de gare',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 4, y: 5),
          npc: MapEntityNpcData(),
        ),
      ],
    ),
  );
  expect(
    await fixture.workspace.save(document),
    isTrue,
    reason: document.error,
  );
}

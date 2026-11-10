import 'dart:io';

import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/story_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final origin in [WorkspaceSpace.events, WorkspaceSpace.progression]) {
    test(
      'nested $origin scene cinematic dialogue returns to exact dirty owners without publishing',
      () async {
        final fixture = await _Routes.create();
        addTearDown(fixture.dispose);
        final beforeDisk = await fixture.disk();
        if (origin == WorkspaceSpace.events) {
          await fixture.navigation.openEvents(Ui06SceneFixture.eventId);
        } else {
          expect(
            fixture.navigation.openProgression(preferredStoryId: 'story'),
            isTrue,
          );
        }
        expect(
          await fixture.navigation.openScene(
            Ui06SceneFixture.sceneId,
            nodeId: 'cinematic',
          ),
          isNull,
        );
        final edit = fixture.scenes.active!;
        expect(edit.rename('Brouillon scène conservé'), isTrue);
        final sceneDraft = edit.current;
        final payload =
            sceneDraft.graph.nodes
                    .singleWhere((node) => node.id == 'cinematic')
                    .payload
                as SceneCinematicPayload;
        await fixture.navigation.openSceneCinematic(payload);
        expect(fixture.cinematics.activeId, payload.cinematicId);
        expect(fixture.navigation.cinematicOrigin, WorkspaceSpace.scene);
        final dialogueId = fixture.maps.project!.dialogues.first.id;
        expect(
          fixture.cinematics.addCommand(
            CinematicTimelineStepKind.dialogueLine,
            dialogueId: dialogueId,
          ),
          isNotNull,
        );
        final cinematicDraft = fixture.cinematics.active!.asset;
        expect(
          await fixture.navigation.openDialogue(
            dialogueId,
            WorkspaceSpace.cinematic,
          ),
          isNull,
        );
        expect(fixture.dialogues.activeId, dialogueId);
        fixture.navigation.returnFromDialogue();
        expect(fixture.navigation.space, WorkspaceSpace.cinematic);
        expect(fixture.cinematics.active!.asset, cinematicDraft);
        expect(fixture.cinematics.dirty, isTrue);
        fixture.navigation.show(fixture.navigation.cinematicOrigin);
        expect(fixture.navigation.space, WorkspaceSpace.scene);
        expect(fixture.scenes.active, same(edit));
        expect(edit.current, same(sceneDraft));
        expect(edit.dirty, isTrue);
        expect(fixture.navigation.sceneNodes[edit.current.id], 'cinematic');
        fixture.navigation.show(fixture.navigation.sceneOrigin.space);
        expect(fixture.navigation.space, origin);
        if (origin == WorkspaceSpace.events) {
          expect(fixture.events.activeId, Ui06SceneFixture.eventId);
        } else {
          expect(fixture.stories.activeId, 'story');
        }
        expect(await fixture.disk(), beforeDisk);
      },
    );
  }

  test('returning from the triggering scene preserves the cinematic original story return', () async {
    final fixture = await _Routes.create();
    addTearDown(fixture.dispose);
    final before = await fixture.disk();
    expect(await fixture.cinematics.open(Ui06SceneFixture.cinematicId), isTrue);
    fixture.navigation.cinematicOrigin = WorkspaceSpace.story;
    fixture.navigation.show(WorkspaceSpace.cinematic);
    expect(
      await fixture.navigation.openScene(
        Ui06SceneFixture.sceneId,
        nodeId: 'cinematic',
      ),
      isNull,
    );
    expect(fixture.navigation.sceneOrigin.space, WorkspaceSpace.cinematic);
    expect(
      fixture.navigation.sceneOrigin.documentId,
      Ui06SceneFixture.cinematicId,
    );
    await fixture.navigation.openSceneCinematic(
      SceneCinematicPayload(cinematicId: Ui06SceneFixture.cinematicId),
    );
    expect(fixture.navigation.space, WorkspaceSpace.cinematic);
    expect(fixture.navigation.cinematicOrigin, WorkspaceSpace.story);
    fixture.navigation.show(fixture.navigation.cinematicOrigin);
    expect(fixture.navigation.space, WorkspaceSpace.story);
    expect(fixture.scenes.dirty, isFalse);
    expect(fixture.cinematics.dirty, isFalse);
    expect(await fixture.disk(), before);
  });

  test('cinematic map location preserves a dirty map and rejects a superseded route', () async {
    final fixture = await _Routes.create();
    addTearDown(fixture.dispose);
    final before = await fixture.disk();
    final document = fixture.maps.active!;
    document.commit(document.current.copyWith(name: 'Carte en préparation'));
    final draft = document.current;
    final undo = document.undoCount;
    fixture.view.tool = StudioMapTool.erase;
    fixture.navigation.show(WorkspaceSpace.cinematic);
    var returns = 0;
    expect(
      await fixture.navigation.locateCinematic(
        draft.id,
        mapReturn: () => returns++,
      ),
      isNull,
    );
    expect(fixture.navigation.space, WorkspaceSpace.map);
    expect(fixture.view.tool, StudioMapTool.select);
    expect(fixture.maps.active, same(document));
    expect(document.current, same(draft));
    expect(document.undoCount, undo);
    expect(document.dirty, isTrue);
    expect(returns, 1);
    fixture.navigation.show(WorkspaceSpace.cinematic);
    final pending = fixture.navigation.locateCinematic(
      draft.id,
      mapReturn: () => returns++,
    );
    fixture.navigation.show(WorkspaceSpace.story);
    expect(await pending, isNull);
    expect(fixture.navigation.space, WorkspaceSpace.story);
    expect(returns, 1);
    expect(
      await fixture.navigation.locateCinematic('missing'),
      contains('absente ou ambiguë'),
    );
    expect(await fixture.disk(), before);
  });
}

class _Routes {
  _Routes(this.source, this.maps) {
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
      () {},
      (_, _) async {},
    );
    events = EventWorkspaceController(
      narrative,
      LocalEventAdapter(session: source.session, mapAdapter: source.maps),
      changed: () {},
    );
    scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: source.session, mapAdapter: source.maps),
      narrative: narrative,
      changed: () {},
    );
    stories = StoryWorkspaceController(
      narrative,
      LocalStoryAdapter(session: source.session, mapAdapter: source.maps),
      changed: () {},
    );
    cinematics = CinematicWorkspaceController(
      narrative,
      LocalCinematicAdapter(session: source.session, mapAdapter: source.maps),
      changed: () {},
      sceneDrafts: () => scenes.scenes,
    );
    dialogues = DialogueWorkspaceController(
      narrative,
      LocalDialogueAdapter(session: source.session, mapAdapter: source.maps),
      changed: () {},
      sceneDrafts: () => scenes.scenes,
    );
    navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      events: () => events,
      scenes: () => scenes,
      stories: () => stories,
      cinematics: () => cinematics,
      dialogues: () => dialogues,
      narrative: () => narrative,
      mapView: () => view,
    );
  }
  final Ui06SceneFixture source;
  final MapWorkspaceController maps;
  final view = MapEditingViewportSession();
  late final NarrativeWorkspaceController narrative;
  late final EventWorkspaceController events;
  late final SceneWorkspaceController scenes;
  late final StoryWorkspaceController stories;
  late final CinematicWorkspaceController cinematics;
  late final DialogueWorkspaceController dialogues;
  late final WorkspaceNavigationSession navigation;
  static Future<_Routes> create() async {
    final source = await Ui06SceneFixture.create(
      withCinematic: true,
      seedProject: (project) =>
          project.copyWith(storylines: [backendStory('story')]),
    );
    final maps = MapWorkspaceController(source.session, source.maps);
    await maps.initialize();
    final fixture = _Routes(source, maps);
    expect(
      await fixture.events.prepare(),
      isTrue,
      reason: fixture.events.error,
    );
    return fixture;
  }

  Future<Map<String, List<int>>> disk() async => {
    for (final file
        in await source.directory
            .list(recursive: true)
            .where(
              (entry) => entry is File && !entry.path.contains('/.pokemap/'),
            )
            .cast<File>()
            .toList())
      file.path.substring(source.directory.path.length): await file
          .readAsBytes(),
  };
  Future<void> dispose() async {
    dialogues.dispose();
    cinematics.dispose();
    stories.dispose();
    scenes.dispose();
    events.dispose();
    narrative.dispose();
    view.dispose();
    maps.dispose();
    await source.dispose();
  }
}

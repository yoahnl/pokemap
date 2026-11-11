import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'support/ui06_scene_fixture.dart';
import 'support/ui08_event_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('nested event scene dialogue routes preserve the exact dirty owner without publication', () async {
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
    final navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      events: () => events,
      scenes: () => scenes,
      dialogues: () => dialogues,
      narrative: () => narrative,
    );
    final recorded = await fixture.readFresh();
    await navigation.openEvents(Ui06SceneFixture.eventId);
    final selectedEvent = events.activeId;
    final event = events.active!;
    expect(await navigation.openScene(event.definitionOrNull!.sceneId), isNull);
    final session = scenes.active!;
    expect(session.rename('Brouillon scène conservé'), isTrue);
    final before = session.current;
    final history = session.undoCount;
    final node = before.graph.nodes.firstWhere(
      (node) => node.payload is SceneYarnDialoguePayload,
    );
    navigation.selectSceneNode(before, node.id);
    final payload = node.payload as SceneYarnDialoguePayload;
    expect(
      await navigation.openDialogue(
        payload.dialogueId,
        WorkspaceSpace.scene,
        startNode: payload.yarnNodeName,
      ),
      isNull,
    );
    expect(dialogues.activeId, payload.dialogueId);
    navigation.returnFromDialogue();
    expect(navigation.space, WorkspaceSpace.scene);
    expect(scenes.active, same(session));
    expect(session.current, same(before));
    expect(session.undoCount, history);
    expect(session.dirty, isTrue);
    expect(navigation.sceneNodes[before.id], node.id);
    navigation.show(navigation.sceneOrigin.space);
    expect(navigation.space, WorkspaceSpace.events);
    expect(events.activeId, selectedEvent);
    expect(events.active, same(event));
    expect(dialogues.dirty, isFalse);
    expect(events.dirty, isFalse);
    expect(await fixture.readFresh(), recorded);
  });
}

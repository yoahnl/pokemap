import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_scene_focus_draft.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_behaviour_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pokemon/pokemon_scoped_save_counting_reader.dart';
import 'scene_focus_catalog_fixture.dart';

Future<void> _until(bool Function() done) async {
  for (var attempt = 0; attempt < 400 && !done(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue);
}

void main() {
  test(
    'a scene opens from sceneDocument alone, without decoding a map',
    () async {
      final session = await openSceneFocusCatalog();
      final reader = CountingReader();

      final document = await LocalNarrativeIndexAdapter(
        session,
        reader: reader,
      ).sceneDocument('gate');

      expect(document.scene, focusGate);
      expect(document.mapReads, 0);
      expect(document.dialogues.single.entry.id, 'dialogue_hello');
      expect(document.dialogues.single.source, contains('Bonjour'));
      expect(document.dialogues.single.revision, isNotNull);
      expect(document.events.map((event) => event.id).toSet(), {
        focusTownEvent,
        focusCaveEvent,
      });
      expect(document.maps.keys.toSet(), {'town', 'cave'});
      expect(document.maps['cave']!.elements.single.name, 'Mineur');
      expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
      expect(reader.definitions.toSet(), {'gate', 'dialogue_hello'});
      expect(reader.unitKeys.where((key) => key.contains('unused')), isEmpty);
      expect(
        reader.unitKeys.where((key) => key.contains('"mapDirectory"')),
        hasLength(2),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('the scene view tells who launches it, what it changes, and detaches a '
      'copy for one behaviour through the draft', () async {
    final session = await openSceneFocusCatalog(unrelated: 20);
    final adapter = LocalMapWorkspaceAdapter();
    final maps = MapWorkspaceController(session, adapter);
    addTearDown(maps.dispose);
    await maps.initialize();
    await maps.activate(
      maps.project!.maps.firstWhere((entry) => entry.id == 'town'),
    );
    final story = MapBuilderStoryBinding(
      maps: maps,
      changed: () {},
      view: () => null,
      gateway: (draft, saved) => StoryPublicationGateway(
        draft: draft,
        facts: LocalWorldAdapter(session: session, mapAdapter: adapter),
        stories: LocalStoryAdapter(session: session, mapAdapter: adapter),
        scenes: LocalSceneAdapter(session: session, mapAdapter: adapter),
        events: LocalEventAdapter(session: session, mapAdapter: adapter),
        savedDialogues: saved,
      ),
    );
    await story.prepare();
    final reader = CountingReader();
    final port = LocalNarrativeIndexAdapter(session, reader: reader);
    SceneFocusController focus(String sceneId, String behaviourId) =>
        SceneFocusController(
          port: port,
          draft: MapBuilderSceneFocusDraft(story, isEditable: () => true),
          source: () => MapBuilderStoryBehaviourSource(story),
          sceneId: sceneId,
          behaviourId: behaviourId,
          changed: () {},
        );
    final gate = focus('gate', focusCaveEvent);

    await gate.open();
    await _until(() => gate.facts.ready);

    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    expect(gate.launchers.map((record) => record.id).toSet(), {
      focusTownEvent,
      focusCaveEvent,
    });
    expect((gate.shared, gate.canDetach), (true, true));
    expect(gate.changedFactIds, ['fact_door']);
    expect(gate.factName('fact_door'), 'Porte ouverte');
    final cave = gate.launchers.firstWhere(
      (record) => record.id == focusCaveEvent,
    );
    expect(gate.place(cave).mapName, 'Grotte');
    expect(gate.place(cave).elementName, 'Mineur');

    gate.togglePreview();
    expect(gate.path!.nodeIds, ['start', 'hello', 'check']);
    expect(gate.path!.exits.map((exit) => exit.portId), ['true', 'false']);
    gate.choose('check', 'true');
    expect(gate.path!.nodeIds, ['start', 'hello', 'check', 'open', 'end']);
    expect(gate.path!.ended, isTrue);

    final copyId = gate.detach('Porte du bourg (copie)');
    expect(copyId, isNotNull, reason: story.error);
    expect(gate.launchers.map((record) => record.id), [focusTownEvent]);
    expect(gate.shared, isFalse);

    final copy = focus(copyId!, focusCaveEvent);
    reader.clear();
    await copy.open();
    expect(reader.unitKeys, isEmpty);
    expect(copy.scene!.name, 'Porte du bourg (copie)');
    expect(copy.scene!.graph, focusGate.graph);
    expect(copy.launchers.map((record) => record.id), [focusCaveEvent]);

    expect(await story.save(), isTrue, reason: story.error);
    final saved = await port.sceneDocument(copyId);
    expect(saved.scene.name, 'Porte du bourg (copie)');
    expect(saved.events.single.id, focusCaveEvent);
    expect((await port.sceneDocument('gate')).events.single.id, focusTownEvent);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

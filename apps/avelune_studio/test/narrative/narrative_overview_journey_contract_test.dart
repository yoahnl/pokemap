import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_projection.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_selection.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/ui05_story_backend_fixture.dart';
import '../support/narrative_artwork_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('overview homonyms and filters consult metadata without reading dialogues or opening maps', () async {
    final source = await createUi05StoryBackend();
    addTearDown(() => source.directory.delete(recursive: true));
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final port = _CountingPort(
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
    );
    final narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final before = await _disk(source.directory);
    final overview = buildNarrativeOverview(narrative);
    expect(overview.stories, hasLength(2));
    expect(overview.stepsById, contains('unlinked'));
    expect(overview.stepLinks['unlinked'] ?? [], isEmpty);
    final selection = NarrativeOverviewSelection()
      ..tab = NarrativeOverviewTab.interactions
      ..query = 'Mame';
    expect(
      selection
          .visibleInteractions(overview)
          .map((interaction) => interaction.id),
      unorderedEquals([
        for (final number in [1, 7, 100]) ui05StoryEventId(number),
      ]),
    );
    selection.mapId = 'clairiere';
    expect(
      selection
          .visibleInteractions(overview)
          .map((interaction) => interaction.id),
      [ui05StoryEventId(100)],
    );
    selection.mapId = null;
    expect(selection.visibleInteractions(overview), hasLength(3));
    selection.select(interaction: ui05StoryEventId(1));
    selection.reconcileSelection(overview);
    expect(selection.interactionId, ui05StoryEventId(1));
    final advanced = overview.interactionsById[ui05StoryEventId(101)]!;
    expect(advanced.advanced, isTrue);
    expect(advanced.canEdit, isFalse);
    expect(narrative.sessions, isEmpty);
    expect(maps.documents, hasLength(1));
    expect(port.reads, 0);
    expect(port.writes, 0);
    expect(await _disk(source.directory), before);
  });

  test('exact homonymous interaction routes retain local dialogue map history and search then locate the source', () async {
    final source = await createUi05StoryBackend();
    addTearDown(() => source.directory.delete(recursive: true));
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final port = _CountingPort(
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
    );
    final narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final before = await _disk(source.directory);
    final dirtyId = ui05StoryEventId(2);
    expect(
      await narrative.openRecord(
        narrative.project.eventRegistry!.records.singleWhere(
          (record) => record.id == dirtyId,
        ),
      ),
      isTrue,
    );
    final edit = narrative.active!;
    edit.change(
      interaction: edit.current.interaction.revise(
        name: 'Voyageuse · texte en préparation',
      ),
    );
    edit.document.commit(
      edit.document.current.copyWith(name: 'Jardin · travail non enregistré'),
    );
    final draft = edit.current;
    final document = edit.document;
    final dirtyMap = document.current;
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final transform = view.transform.value.clone();
    final selection = NarrativeOverviewSelection()..query = 'Mame';
    final navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      narrative: () => narrative,
      mapView: () => view,
    );
    for (final number in [1, 7, 100]) {
      navigation.show(WorkspaceSpace.story);
      expect(
        await navigation.openStoryInteraction(ui05StoryEventId(number)),
        isNull,
      );
      expect(navigation.space, WorkspaceSpace.interaction);
      expect(
        narrative.active!.current.interaction.id,
        ui05StoryEventId(number),
      );
      expect(
        narrative.active!.document.current.id,
        number == 100 ? 'clairiere' : 'jardin',
      );
      navigation.show(WorkspaceSpace.story);
      expect(selection.query, 'Mame');
      expect(edit.current, same(draft));
      expect(document.current, same(dirtyMap));
      expect(view.transform.value, transform);
    }
    expect(
      await navigation.locateStoryInteraction(ui05StoryEventId(1)),
      isNull,
    );
    expect(navigation.space, WorkspaceSpace.map);
    expect(maps.active, same(document));
    expect(
      view.selectedFor(document.current.id, MapSelectionFamily.character),
      'chief',
    );
    expect(view.tool, StudioMapTool.select);
    expect(document.current, same(dirtyMap));
    expect(document.canUndo, isTrue);
    final sessions = Map.of(narrative.sessions);
    final reads = port.reads;
    selection
      ..query = 'Voyageuse'
      ..tab = NarrativeOverviewTab.interactions;
    final overview = buildNarrativeOverview(narrative);
    expect(
      selection
          .visibleInteractions(overview)
          .any((interaction) => interaction.id == dirtyId && interaction.dirty),
      isTrue,
    );
    selection.query = 'signal';
    expect(selection.visibleInteractions(overview).single.canEdit, isFalse);
    selection.query = 'aucune correspondance';
    selection.reconcileSelection(overview);
    expect(edit.current, same(draft));
    expect(document.current, same(dirtyMap));
    expect(narrative.sessions, sessions);
    expect(port.reads, reads);
    expect(port.writes, 0);
    expect(await _disk(source.directory), before);
  });

  test('story overview routes exact stories and steps and explicit quest creation remains an unpublished draft', () async {
    final source = await createUi05StoryBackend();
    addTearDown(() => source.directory.delete(recursive: true));
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final port = _CountingPort(
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
    );
    final narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final stories = StoryWorkspaceController(
      narrative,
      LocalStoryAdapter(session: source.session, mapAdapter: source.maps),
      changed: () {},
    );
    addTearDown(stories.dispose);
    final before = await _disk(source.directory);
    final navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      stories: () => stories,
    );
    for (final id in ['garden-traces', 'departure']) {
      expect(navigation.openProgression(preferredStoryId: id), isTrue);
      expect(stories.activeId, id);
      expect(stories.dirty, isFalse);
      navigation.show(WorkspaceSpace.story);
    }
    expect(navigation.openProgressionStep('departure', 'unlinked'), isTrue);
    expect(navigation.progressionNodes['departure']!.id, 'step:unlinked');
    expect(await _disk(source.directory), before);
    final quest = stories.create(
      'Retrouver le chat',
      type: StorylineType.sideQuest,
    )!;
    expect(quest.title, 'Retrouver le chat');
    expect(quest.type, StorylineType.sideQuest);
    expect(stories.stories, hasLength(3));
    expect(stories.dirty, isTrue);
    expect(port.reads, 0);
    expect(port.writes, 0);
    expect(await _disk(source.directory), before);
  });
  test('native artwork reader retains exact hero story and scene assets without writing', () async {
    final source = await createUi05StoryBackend();
    addTearDown(() => source.directory.delete(recursive: true));
    final project = await source.maps.loadProject(source.session);
    final files = await seedNarrativeArtworkFixture(
      source.session.directoryPath,
      project.scenes,
    );
    final before = await _disk(source.directory);
    final port = LocalNarrativeAdapter(
      session: source.session,
      mapAdapter: source.maps,
    );
    expect(
      await port.readArtwork(NarrativeArtworkKind.hero),
      files['hero.png'],
    );
    expect(
      await port.readArtwork(NarrativeArtworkKind.story, id: 'departure'),
      files['stories/departure.png'],
    );
    for (final scene in project.scenes.take(4)) {
      expect(
        await port.readArtwork(NarrativeArtworkKind.scene, id: scene.id),
        files['scenes/${scene.id}.png'],
      );
    }
    expect(
      await port.readArtwork(NarrativeArtworkKind.scene, id: 'missing'),
      isNull,
    );
    expect(await _disk(source.directory), before);
  });
  test('global overview search preserves kind grouping stable step order exact routes and the three Clairière results', () async {
    final source = await createUi05StoryBackend();
    addTearDown(() => source.directory.delete(recursive: true));
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final port = _CountingPort(
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
    );
    final narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final overview = buildNarrativeOverview(narrative);
    final before = await _disk(source.directory);
    List<NarrativeOverviewSearchMatch> find(String query) =>
        searchNarrativeOverview(
          overview: overview,
          project: maps.project!,
          scenes: maps.project!.scenes,
          dialogues: maps.project!.dialogues,
          events: maps.project!.eventRegistry!.records,
          query: query,
        );
    final results = find('Clairière');
    expect(results, hasLength(3));
    expect(results.map((result) => result.kind), [
      'Étape',
      'Interaction',
      'Carte',
    ]);
    expect(results.first.storyId, 'garden-traces');
    expect(results.first.stepId, 'garden-cross');
    expect(results.last.id, 'clairiere');
    expect(find('aucun document pareil'), isEmpty);
    final all = find('');
    final firstKind = {
      for (final kind in [
        'Histoire',
        'Étape',
        'Scène',
        'Dialogue',
        'Événement',
        'Interaction',
        'Carte',
      ])
        kind: all.indexWhere((result) => result.kind == kind),
    };
    expect(
      firstKind.values.toList(),
      orderedEquals([...firstKind.values]..sort()),
    );
    expect(
      all
          .where(
            (result) => result.kind == 'Étape' && result.storyId == 'departure',
          )
          .map((result) => result.stepId),
      ['prepare', 'help', 'finish', 'unlinked'],
    );
    expect(
      orderedNarrativeOverview([
        (id: 'z', order: 0),
        (id: 'a', order: 0),
      ], (item) => item.order).map((item) => item.id),
      ['z', 'a'],
    );
    expect(port.reads, 0);
    expect(port.writes, 0);
    expect(narrative.sessions, isEmpty);
    expect(await _disk(source.directory), before);
  });
}

Future<Map<String, List<int>>> _disk(Directory directory) async => {
  for (final file
      in await directory
          .list(recursive: true)
          .where((entry) => entry is File && !entry.path.contains('/.pokemap/'))
          .cast<File>()
          .toList())
    file.path.substring(directory.path.length): await file.readAsBytes(),
};

class _CountingPort implements NarrativePort {
  _CountingPort(this.delegate);
  final NarrativePort delegate;
  int reads = 0, writes = 0;
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) {
    reads++;
    return delegate.readDialogue(entry);
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) {
    writes++;
    return delegate.publish(publication);
  }
}

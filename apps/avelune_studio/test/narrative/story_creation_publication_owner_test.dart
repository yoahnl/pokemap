import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m3_story_fixture.dart';
import '../support/ui05_story_backend_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UI05 rejected creation is inert and explicit save survives fresh reopen', () async {
    final fixture = await createUi05StoryBackend();
    addTearDown(() => fixture.directory.delete(recursive: true));
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    expect(workspace.active, isNotNull);
    final port = _CountingNarrativePort(
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
    );
    final narrative = NarrativeWorkspaceController(
      workspace,
      port,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final before = await _disk(fixture);
    final originalStories = {
      for (final story in narrative.stories) story.id: story.toJson(),
    };
    final originalFacts = {
      for (final fact in narrative.facts) fact.id: fact.toJson(),
    };
    final originalEvents = narrative.project.eventRegistry!.toJson();

    narrative.addStory('   ', ['Étape abandonnée']);
    narrative.addStory('Histoire abandonnée', ['  ', '']);
    narrative.addFact('   ');
    expect(narrative.pendingStories, isEmpty);
    expect(narrative.pendingFacts, isEmpty);
    expect(narrative.sessions, isEmpty);
    expect(await _disk(fixture), before);

    narrative.addStory('La visite du quai', [
      'Retrouver la voyageuse',
      ' Observer les signaux ',
      '',
    ]);
    narrative.addFact('Signal aperçu');
    final createdStory = narrative.pendingStories.values.single;
    final createdFact = narrative.pendingFacts.values.single;
    expect(createdStory.toJson().toString(), contains('Observer les signaux'));
    final document = workspace.active!;
    document.commit(
      document.current.copyWith(name: 'Carte modifiée avec l’histoire'),
    );
    final dirtyMap = document.current;
    expect(port.publications, 0);
    expect(await _disk(fixture), before);

    expect(await narrative.saveAll(), isTrue, reason: narrative.error);
    expect(narrative.publicationError, isNull);
    expect(narrative.pendingStories, isEmpty);
    expect(narrative.pendingFacts, isEmpty);
    expect(document.dirty, isFalse);
    expect(port.publications, 1);
    expect(port.dialogueReads, 0);

    final reopened = LocalMapWorkspaceAdapter();
    final manifest = await reopened.loadProject(fixture.session);
    expect(
      manifest.storylines
          .singleWhere((story) => story.id == createdStory.id)
          .toJson(),
      createdStory.toJson(),
    );
    expect(
      manifest.facts.singleWhere((fact) => fact.id == createdFact.id).toJson(),
      createdFact.toJson(),
    );
    for (final entry in originalStories.entries) {
      expect(
        manifest.storylines.singleWhere((story) => story.id == entry.key).toJson(),
        entry.value,
      );
    }
    for (final entry in originalFacts.entries) {
      expect(
        manifest.facts.singleWhere((fact) => fact.id == entry.key).toJson(),
        entry.value,
      );
    }
    expect(manifest.eventRegistry!.toJson(), originalEvents);
    final map = await reopened.loadMap(
      fixture.session,
      manifest.maps.firstWhere((map) => map.id == document.current.id),
    );
    expect(map.map, dirtyMap);
  }, timeout: _slow);
}

Future<Map<String, List<int>>> _disk(M3StoryFixture fixture) async => {
  for (final file
      in await fixture.directory
          .list(recursive: true)
          .where((file) => file is File && !file.path.contains('/.pokemap/'))
          .cast<File>()
          .toList())
    file.path.substring(fixture.directory.path.length): await file.readAsBytes(),
};

class _CountingNarrativePort implements NarrativePort {
  _CountingNarrativePort(this.delegate);
  final NarrativePort delegate;
  int dialogueReads = 0, publications = 0;

  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) {
    dialogueReads++;
    return delegate.readDialogue(entry);
  }

  @override
  Future<NarrativePublicationReceipt> publish(NarrativePublication publication) {
    publications++;
    return delegate.publish(publication);
  }
}

const _slow = Timeout(Duration(minutes: 3));

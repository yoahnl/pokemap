import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_cache.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'narrative/dialogue_draft_codec_test.dart' show dialogueFixture;
import 'support/map_workspace_fixture.dart';

String _id(int i) =>
    'evt_00000000-0000-7000-8000-${i.toString().padLeft(12, '0')}';

void main() {
  late WorkspaceMemoryPort mapsPort;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController controller;
  late _NoIoPort port;
  late NarrativeOverviewCache cache;
  setUp(() async {
    mapsPort = WorkspaceMemoryPort();
    maps = MapWorkspaceController(workspaceSession, mapsPort);
    await maps.initialize();
    port = _NoIoPort();
    controller = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    cache = NarrativeOverviewCache();
  });
  tearDown(() => maps.dispose());

  void records(
    List<NarrativeEventRecord> records, {
    List<SceneAsset> scenes = const [],
  }) {
    maps.project = maps.project!.copyWith(
      scenes: scenes,
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: records,
        legacyClaims: [],
      ),
    );
  }

  test(
    '1000 interactions remain distinct with no reads, writes or sessions',
    () {
      records([
        for (var i = 0; i < 1000; i++)
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: _id(i),
              name: 'Même titre',
              source: NarrativeEventSourceRef.mapEnter(i.isEven ? 'a' : 'b'),
              conditions: [],
              priority: 0,
              order: i,
            ),
          ),
      ]);
      final reads = mapsPort.reads;
      final before = maps.project;
      final first = cache.read(controller);
      expect(first.interactions, hasLength(1000));
      expect(first.interactionsById, hasLength(1000));
      expect(
        first.interactions.map((i) => i.identity).toSet(),
        hasLength(1000),
      );
      expect(first.interactions.first.mapLabel, 'Clairière');
      expect(first.interactions[1].mapLabel, 'Jardin');
      expect(first.interactions.any((i) => i.advanced || i.canEdit), isFalse);
      for (var i = 0; i < 30; i++) {
        controller.search = 'Recherche $i';
        expect(cache.read(controller), same(first));
      }
      expect(cache.buildCount, 1);
      expect(mapsPort.reads, reads);
      expect(mapsPort.writes, 0);
      expect(port.reads, 0);
      expect(port.writes, 0);
      expect(controller.sessions, isEmpty);
      expect(maps.project, same(before));
    },
  );

  test(
    'local sessions replace persisted rows and invalidate names and explicit links',
    () {
      final draft = NarrativeInteractionDraft(
        id: _id(1),
        name: 'Même titre',
        mapId: 'a',
        source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
        dialogueId: 'station',
        steps: [
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.completeStep,
            targetId: 'arrival',
          ),
        ],
      );
      final projection = draft.project();
      records([projection.event], scenes: [projection.scene]);
      maps.project = maps.project!.copyWith(
        dialogues: [dialogueFixture().entry],
      );
      final story = createStudioStoryline(
        id: 'trip',
        title: 'Voyage',
        steps: {'arrival': 'Arrivée', 'unlinked': 'Sans lien'},
      );
      maps.project = maps.project!.copyWith(
        storylines: [story.copyWith(title: 'Ancien titre')],
        facts: [NarrativeFactDefinition(id: 'helped', label: 'Ancien état')],
      );
      controller.pendingStories[story.id] = story;
      final edit = InteractionEditSession(
        document: maps.active!,
        dialogue: dialogueFixture(),
        interaction: draft,
      );
      controller.sessions[draft.id] = edit;
      final first = cache.read(controller);
      expect(first.interactions.single.advanced, isFalse);
      expect(first.stories.single.title, 'Voyage');
      expect(first.stories.single.chapters.single.steps.map((s) => s.id), [
        'arrival',
        'unlinked',
      ]);
      expect(first.stepLinks['arrival']!.single.id, draft.id);
      expect(first.stepLinks['unlinked'], isNull);
      edit.change(
        interaction: draft.revise(
          name: 'Nom local',
          steps: [
            const NarrativeSequenceStep(
              kind: NarrativeSequenceKind.setFact,
              targetId: 'helped',
            ),
          ],
        ),
      );
      controller.pendingFacts['helped'] = NarrativeFactDefinition(
        id: 'helped',
        label: 'Aide promise',
      );
      final second = cache.read(controller);
      expect(second, isNot(same(first)));
      expect(second.interactions, hasLength(1));
      expect(second.interactions.single.name, 'Nom local');
      expect(second.interactions.single.dirty, isTrue);
      expect(second.facts.single.label, 'Aide promise');
      expect(second.stepLinks['arrival'], isNull);
      expect(second.factLinks['helped']!.single.id, draft.id);
      expect(
        second.interactions.single.consequences,
        contains('Aide promise devient vrai'),
      );
      expect(
        second.interactions.single.references.where((r) => r.missing),
        isEmpty,
      );
      expect(second.dirtyCount, 3);
      edit.acceptSave(edit.current);
      expect(cache.read(controller).interactions.single.dirty, isFalse);
    },
  );

  test('open document source names win while unloaded maps stay partial', () {
    records([
      for (var i = 0; i < 3; i++)
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _id(i),
            name: 'Homonyme',
            source: NarrativeEventSourceRef.entityInteract(
              i == 0 ? 'a' : 'b',
              'person-$i',
            ),
            conditions: [],
            priority: 0,
            order: i,
          ),
        ),
    ]);
    final first = cache.read(controller);
    expect(first.interactions[1].sourceLabel, contains('détails à charger'));
    expect(first.interactions[1].missingReferences, isEmpty);
    final document = maps.active!;
    document.commit(
      document.current.copyWith(
        entities: [
          const MapEntity(
            id: 'person-0',
            name: 'Nom modifié en mémoire',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 3),
          ),
        ],
      ),
    );
    final current = cache.read(controller);
    expect(
      current.interactions.first.sourceLabel,
      contains('Nom modifié en mémoire'),
    );
    expect(
      current.interactions.first.searchText,
      contains('nom modifié en mémoire'),
    );
    expect(current.interactions.first.mapLabel, 'Clairière');
    expect(current.interactions.first.missingReferences, isEmpty);
    expect(document.dirty, isTrue);
    expect(port.reads, 0);
  });

  test(
    'advanced records retain safe references without invented execution or links',
    () {
      final event = NarrativeInteractionDraft(
        id: _id(1),
        name: 'Avancée',
        mapId: 'b',
        source: NarrativeEventSourceRef.mapEnter('b'),
        dialogueId: 'missing-dialogue',
        conditions: [NarrativeEventCondition.fact('missing-fact', true)],
        steps: [
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.completeStep,
            targetId: 'linked',
          ),
        ],
      ).project();
      final scene = SceneAsset(
        id: event.scene.id,
        name: 'Métadonnée avancée conservée',
        graph: event.scene.graph,
      );
      records([event.event], scenes: [scene]);
      controller.pendingStories['trip'] = createStudioStoryline(
        id: 'trip',
        title: 'Histoire',
        steps: {'linked': 'Lien explicite', 'alone': 'Sans lien'},
      );
      final view = cache.read(controller);
      final item = view.interactions.single;
      expect(item.advanced, isTrue);
      expect(item.canEdit, isFalse);
      expect(item.consequences, ['Analyse détaillée indisponible']);
      expect(
        item.references.any(
          (r) => r.kind == NarrativeOverviewReferenceKind.scene && !r.missing,
        ),
        isTrue,
      );
      expect(item.missingReferences, hasLength(2));
      expect(view.stepLinks['linked']!.single, same(item));
      expect(view.stepLinks['alone'], isNull);
      expect(view.factLinks['missing-fact']!.single, same(item));
      expect(controller.sessions, isEmpty);
      expect(maps.project!.scenes.single, same(scene));
    },
  );
}

class _NoIoPort implements NarrativePort {
  int reads = 0, writes = 0;
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) {
    reads++;
    throw StateError('La consultation ne doit pas lire de dialogue.');
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) {
    writes++;
    throw StateError('La consultation ne doit pas écrire.');
  }
}

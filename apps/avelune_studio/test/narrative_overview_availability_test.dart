import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_cache.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'narrative/dialogue_draft_codec_test.dart' show dialogueFixture;
import 'support/map_workspace_fixture.dart';

void main() {
  test(
    'missing narrative structure is unavailable rather than advanced',
    () async {
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await maps.initialize();
      addTearDown(maps.dispose);
      final controller = NarrativeWorkspaceController(
        maps,
        _NoIoPort(),
        () {},
        (_, _) async {},
      );
      final event = NarrativeInteractionDraft(
        id: 'evt_00000000-0000-7000-8000-000000000001',
        name: 'Conversation',
        mapId: 'a',
        source: NarrativeEventSourceRef.mapEnter('a'),
        dialogueId: dialogueFixture().entry.id,
        steps: [
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.wait,
            milliseconds: 100,
          ),
        ],
      ).project();
      maps.project = maps.project!.copyWith(
        dialogues: [dialogueFixture().entry],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: [event.event],
          legacyClaims: [],
        ),
      );
      final cache = NarrativeOverviewCache();
      var item = cache.read(controller).interactions.single;
      expect(item.advanced, isFalse);
      expect(item.canEdit, isFalse);
      expect(item.draft, isNull);
      expect(item.missingReferences, hasLength(1));
      expect(item.consequences, ['Structure narrative indisponible']);

      maps.project = maps.project!.copyWith(scenes: [event.scene]);
      item = cache.read(controller).interactions.single;
      expect(item.advanced, isFalse);
      expect(item.canEdit, isFalse);
      expect(
        item.references.where((r) => r.missing).single.id,
        event.cinematics.single.id,
      );

      maps.project = maps.project!.copyWith(cinematics: event.cinematics);
      item = cache.read(controller).interactions.single;
      expect(item.advanced, isFalse);
      expect(item.canEdit, isTrue);
      expect(item.missingReferences, isEmpty);

      maps.project = maps.project!.copyWith(dialogues: []);
      item = cache.read(controller).interactions.single;
      expect(item.advanced, isFalse);
      expect(item.canEdit, isFalse);
      expect(item.draft, isNotNull);
      expect(controller.sessions, isEmpty);
    },
  );
}

class _NoIoPort implements NarrativePort {
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw StateError('Aucune lecture pendant la consultation.');
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => throw StateError('Aucune publication pendant la consultation.');
}

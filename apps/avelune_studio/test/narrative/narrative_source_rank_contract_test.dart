import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'dialogue_draft_codec_test.dart' show dialogueFixture;

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController controller;
  late InteractionEditSession edit;
  late WorkspaceMemoryPort mapPort;
  late _Port narrativePort;
  setUp(() async {
    mapPort = WorkspaceMemoryPort();
    narrativePort = _Port();
    maps = MapWorkspaceController(workspaceSession, mapPort);
    await maps.initialize();
    controller = NarrativeWorkspaceController(
      maps,
      narrativePort,
      () {},
      (_, _) async {},
    );
    edit = InteractionEditSession(
      document: maps.active!,
      dialogue: dialogueFixture(),
      interaction: NarrativeInteractionDraft(
        id: 'evt_00000000-0000-7000-8000-000000000001',
        name: 'Le chef de gare',
        mapId: 'a',
        source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
        dialogueId: 'station',
        steps: [
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.completeStep,
            targetId: 'arrival',
          ),
        ],
      ),
    );
    controller.sessions[edit.current.interaction.id] = edit;
    controller.active = edit;
  });
  tearDown(() {
    maps.dispose();
  });

  test(
    'new source variant ranks above existing conditional and fallback drafts',
    () async {
      edit.change(interaction: edit.current.interaction.revise(priority: 4));
      await controller.openSource(
        maps.active!,
        edit.current.interaction.source,
        'Après l’aide',
      );
      expect(controller.active!.current.interaction.priority, 5);
      expect(controller.active!.current.interaction.order, 1);
      expect(controller.sessions, hasLength(2));
    },
  );
}

class _Port implements NarrativePort {
  int reads = 0, writes = 0;
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) {
    reads++;
    throw UnimplementedError();
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) {
    writes++;
    throw UnimplementedError();
  }
}

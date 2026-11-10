import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import '../support/m3_story_fixture.dart';

void main() {
  testWidgets(
    'C1 dirty simplified dialogue wins over old clean full snapshot without publication',
    (tester) async {
      late M3StoryFixture fixture;
      late MapWorkspaceController maps;
      late NarrativeWorkspaceController narrative;
      late DialogueWorkspaceController dialogues;
      await tester.runAsync(() async {
        fixture = await M3StoryFixture.create();
        maps = MapWorkspaceController(fixture.session, fixture.maps);
        await maps.initialize();
        narrative = NarrativeWorkspaceController(
          maps,
          LocalNarrativeAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ),
          () {},
          (_, _) async {},
        );
        dialogues = DialogueWorkspaceController(
          narrative,
          LocalDialogueAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ),
          changed: () {},
        );
        await narrative.openRecord(
          narrative.project.eventRegistry!.records.last,
        );
        await dialogues.open(narrative.active!.current.dialogue.entry.id);
      });
      addTearDown(() async {
        dialogues.dispose();
        narrative.dispose();
        maps.dispose();
        await tester.runAsync(() => fixture.directory.delete(recursive: true));
      });
      final simple = narrative.active!;
      final sourceFile = File.fromUri(
        fixture.directory.uri.resolve(
          simple.current.dialogue.entry.relativePath,
        ),
      );
      final sourceBytes = await tester.runAsync(sourceFile.readAsBytes);
      simple.change(
        dialogue: simple.current.dialogue.copyWith(
          branches: [
            simple.current.dialogue.branches.first.copyWith(
              lines: const [DialogueLineDraft(text: 'Brouillon récent C1')],
            ),
            ...simple.current.dialogue.branches.skip(1),
          ],
        ),
      );
      expect(simple.dirty, true);
      final linked = SceneLinkedDocuments()..dialogues = dialogues;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: linked.dialoguePreview(
              SceneYarnDialoguePayload(
                dialogueId: simple.current.dialogue.entry.id,
              ),
              narrative.project,
              narrative,
              detailed: true,
            ),
          ),
        ),
      );
      expect(find.text('Brouillon récent C1'), findsOneWidget);
      expect(await tester.runAsync(sourceFile.readAsBytes), sourceBytes);
    },
  );


}

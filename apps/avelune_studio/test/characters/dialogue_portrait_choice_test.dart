import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/presentation/features/narrative/dialogue_portrait_choice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../narrative/dialogue_draft_codec_test.dart' show dialogueFixture;

void main() {
  testWidgets(
    'portrait names select canonical state without rewriting the line or speaker',
    (tester) async {
      const project = ProjectManifest(
        name: 'Portraits',
        maps: [],
        tilesets: [],
        characterStudioCatalog: ProjectCharacterStudioCatalog(
          portraitStates: [
            CharacterPortraitStateDefinition(
              id: 'neutral',
              displayName: 'Calme',
            ),
            CharacterPortraitStateDefinition(
              id: 'happy',
              displayName: 'Sourire',
            ),
          ],
        ),
        characters: [
          ProjectCharacterEntry(
            id: 'chief',
            name: 'Chef',
            tilesetId: 'sprite',
            portraits: [
              CharacterPortraitVariant(
                portraitStateId: 'neutral',
                assetId: 'neutral-image',
              ),
              CharacterPortraitVariant(
                portraitStateId: 'happy',
                assetId: 'happy-image',
              ),
            ],
          ),
        ],
      );
      var line = const DialogueLineDraft(
        text: 'Bon voyage !',
        speakerId: 'chief',
        portraitStateId: 'neutral',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => DialoguePortraitChoice(
                project: project,
                line: line,
                onChanged: (next) => setState(() => line = next),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sourire').last);
      await tester.pumpAndSettle();
      expect(line.portraitStateId, 'happy');
      expect(line.speakerId, 'chief');
      expect(line.text, 'Bon voyage !');
      final draft = dialogueFixture();
      const codec = DialogueDraftCodec();
      final source = codec.encode(
        draft.copyWith(
          branches: [
            draft.branches.first.copyWith(lines: [line]),
            ...draft.branches.skip(1),
          ],
        ),
      );
      expect(source.source, contains('<<portrait chief happy>>'));
      final decoded = codec.decode(source)!;
      expect(decoded.branches.first.lines.single.portraitStateId, 'happy');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sans portrait').last);
      await tester.pumpAndSettle();
      expect(line.portraitStateId, isNull);
      expect(line.speakerId, 'chief');
      expect(tester.takeException(), isNull);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_preview_state.dart';

void main() {
  const entry = ProjectDialogueEntry(
    id: 'portraits',
    name: 'Portraits',
    relativePath: 'dialogues/portraits.yarn',
  );
  test(
    'canonical portrait speaker and clearing apply to the actual line without leaking previous portrait',
    () {
      const source =
          'title: Start\n---\n<<portrait chef happy>>\nBonjour\nSans portrait\n<<speaker chef>>\nJe parle\nAnonyme\n===\n';
      final compiled = const DialogueAuthoringCompiler().compile(
        entry: entry,
        source: source,
      );
      expect(compiled.canPublish, true);
      final preview = DialoguePreviewState(compiled);
      expect(preview.line!.characterId, 'chef');
      expect(preview.line!.portraitStateId, 'happy');
      preview.advance();
      expect(preview.line!.text, 'Sans portrait');
      expect(preview.line!.characterId, isNull);
      expect(preview.line!.portraitStateId, isNull);
      preview.advance();
      expect(preview.line!.characterId, 'chef');
      expect(preview.line!.portraitStateId, isNull);
      preview.advance();
      expect(preview.line!.characterId, isNull);
      preview.advance();
      expect(preview.ended, true);
      expect(preview.outcomes, isEmpty);
    },
  );
  test('canonical preview never automatically selects the first response', () {
    const source =
        'title: Start\n---\nBonjour\n-> Première\n  Première suite\n-> Seconde\n  Seconde suite\n===\n';
    final preview = DialoguePreviewState(
      const DialogueAuthoringCompiler().compile(entry: entry, source: source),
    );
    preview.advance();
    expect(preview.choices.length, 2);
    preview.advance();
    expect(preview.choices.length, 2);
    expect(preview.ended, false);
    preview.choose(1);
    expect(preview.line!.text, 'Seconde suite');
    expect(preview.transcript, ['Bonjour', 'Seconde suite']);
  });
}

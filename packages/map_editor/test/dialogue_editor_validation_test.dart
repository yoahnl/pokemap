import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_model.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_validation.dart';

void main() {
  group('Dialogue validation', () {
    test('flags empty replica body', () {
      final doc = DialogueEditorDocument(
        nodes: [
          DialogueEditorNode(
            id: 'n1',
            title: 'Start',
            steps: [
              DeStartStep(id: 's0'),
              DeLineStep(id: 's1', speaker: 'hero', body: '   '),
            ],
          ),
        ],
      );
      final issues = validateDialogueDocument(doc);
      expect(
        issues.any(
          (i) =>
              i.message.contains('Réplique vide') &&
              i.severity == DialogueValidationSeverity.error,
        ),
        isTrue,
      );
    });

    test('flags jump to unknown node', () {
      final doc = DialogueEditorDocument(
        nodes: [
          DialogueEditorNode(
            id: 'n1',
            title: 'Start',
            steps: [
              DeStartStep(id: 's0'),
              DeJumpStep(id: 's1', targetTitle: 'Nope'),
            ],
          ),
        ],
      );
      final issues = validateDialogueDocument(doc);
      expect(
        issues.any((i) => i.message.contains('inconnu')),
        isTrue,
      );
    });
  });
}

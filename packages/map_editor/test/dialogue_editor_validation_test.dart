import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_model.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_validation.dart';

void main() {
  test('generated dialogue outcome ids reserve completed', () {
    expect(availableDialogueOutcomeId('Completed', const []), 'completed_2');
    expect(
      availableDialogueOutcomeId('Completed', const ['completed_2']),
      'completed_3',
    );
    expect(
      availableDialogueOutcomeId('Rassurer la foule', const []),
      'rassurer_la_foule',
    );
  });

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

    test('flags duplicate and undeclared choice outcomes', () {
      final doc = DialogueEditorDocument(
        nodes: [
          DialogueEditorNode(
            id: 'n1',
            title: 'Start',
            steps: [
              DeChoiceStep(
                id: 'choice',
                branches: [
                  DeChoiceBranch(
                    id: 'branch_a',
                    label: 'Accepter',
                    outcomeId: 'accepted',
                    steps: [
                      DeLineStep(
                        id: 'line_a',
                        speaker: 'hero',
                        body: 'Oui.',
                      ),
                    ],
                  ),
                  DeChoiceBranch(
                    id: 'branch_b',
                    label: 'Refuser',
                    outcomeId: 'accepted',
                    steps: [
                      DeLineStep(
                        id: 'line_b',
                        speaker: 'hero',
                        body: 'Non.',
                      ),
                    ],
                  ),
                  DeChoiceBranch(
                    id: 'branch_c',
                    label: 'Attendre',
                    outcomeId: 'unknown',
                    steps: [
                      DeLineStep(
                        id: 'line_c',
                        speaker: 'hero',
                        body: 'Plus tard.',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final issues = validateDialogueDocument(
        doc,
        declaredOutcomeIds: const ['accepted', 'refused'],
      );

      expect(
        issues.any((issue) => issue.message.contains('dupliqué')),
        isTrue,
      );
      expect(
        issues.any(
          (issue) =>
              issue.message.contains('non déclaré') &&
              issue.message.contains('unknown'),
        ),
        isTrue,
      );
    });

    test('keeps legacy choices without outcomes non-blocking', () {
      final doc = DialogueEditorDocument(
        nodes: [
          DialogueEditorNode(
            id: 'n1',
            title: 'Start',
            steps: [
              DeChoiceStep(
                id: 'choice',
                branches: [
                  DeChoiceBranch(
                    id: 'branch',
                    label: 'Continuer',
                    steps: [
                      DeLineStep(
                        id: 'line',
                        speaker: 'hero',
                        body: 'Allons-y.',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final issues = validateDialogueDocument(doc);

      expect(
        issues.where(
          (issue) => issue.severity == DialogueValidationSeverity.error,
        ),
        isEmpty,
      );
    });

    test('rejects an authored outcome when the public registry is empty', () {
      final doc = DialogueEditorDocument(
        nodes: [
          DialogueEditorNode(
            id: 'n1',
            title: 'Start',
            steps: [
              DeChoiceStep(
                id: 'choice',
                branches: [
                  DeChoiceBranch(
                    id: 'branch',
                    label: 'Continuer',
                    outcomeId: 'ghost',
                    steps: [
                      DeLineStep(
                        id: 'line',
                        speaker: 'hero',
                        body: 'Allons-y.',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final issues = validateDialogueDocument(doc);

      expect(
        issues.any(
          (issue) =>
              issue.severity == DialogueValidationSeverity.error &&
              issue.message.contains('sans registre public'),
        ),
        isTrue,
      );
    });

    test('reports declared outcomes that no choice can produce', () {
      final doc = DialogueEditorDocument(
        nodes: [
          DialogueEditorNode(
            id: 'n1',
            title: 'Start',
            steps: [
              DeLineStep(id: 'line', speaker: 'guide', body: 'Bonjour.'),
            ],
          ),
        ],
      );

      final issues = validateDialogueDocument(
        doc,
        declaredOutcomeIds: const ['unused'],
      );

      expect(
        issues.any(
          (issue) =>
              issue.severity == DialogueValidationSeverity.warning &&
              issue.message.contains('jamais utilisé') &&
              issue.message.contains('unused'),
        ),
        isTrue,
      );
    });
  });
}

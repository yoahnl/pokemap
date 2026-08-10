import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_model.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_validation.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_preview_runner.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_yarn_codec.dart';

void main() {
  test('legacy Yarn without portrait metadata remains byte stable', () {
    const source = 'title: Start\n---\nGuide: Bonjour.\n===\n';

    final document = parseYarnToDocument(source);
    final line = document.nodes.single.steps.whereType<DeLineStep>().single;

    expect(line.characterId, isNull);
    expect(line.portraitStateId, isNull);
    expect(emitDocumentToYarn(document), source);
  });

  test('portrait directives round trip on root and choice lines', () {
    const source = '''title: Start
---
<<portrait elia neutral>>
Élia: Bonjour.
-> Regarder
  <<portrait elia surprised>>
  Élia: Quoi ?!
===
''';

    final document = parseYarnToDocument(source);
    final rootLine = document.nodes.single.steps.whereType<DeLineStep>().single;
    final choice = document.nodes.single.steps.whereType<DeChoiceStep>().single;
    final branchLine = choice.branches.single.steps
        .whereType<DeLineStep>()
        .single;

    expect(
      (rootLine.characterId, rootLine.portraitStateId),
      ('elia', 'neutral'),
    );
    expect(
      (branchLine.characterId, branchLine.portraitStateId),
      ('elia', 'surprised'),
    );
    expect(document.nodes.single.steps.whereType<DeCommandStep>(), isEmpty);
    expect(choice.branches.single.steps.whereType<DeCommandStep>(), isEmpty);
    expect(emitDocumentToYarn(document), source);

    final preview = DialoguePreviewSession(document);
    final previewLine = preview.transcript
        .whereType<DialoguePreviewLine>()
        .first;
    expect(
      (previewLine.characterId, previewLine.portraitStateId),
      ('elia', 'neutral'),
    );

    final duplicated = document.duplicateNode(document.nodes.single.id);
    final duplicatedLines = duplicated.nodes.last.steps
        .whereType<DeLineStep>()
        .toList();
    expect(
      (
        duplicatedLines.single.characterId,
        duplicatedLines.single.portraitStateId,
      ),
      ('elia', 'neutral'),
    );

    branchLine.body = 'Attention !';
    expect(
      emitDocumentToYarn(document),
      contains('  <<portrait elia surprised>>\n  Élia: Attention !'),
    );
  });

  test('partial portrait metadata is rejected before save', () {
    final document = DialogueEditorDocument(
      nodes: <DialogueEditorNode>[
        DialogueEditorNode(
          id: 'node',
          title: 'Start',
          steps: <DialogueEditorStep>[
            DeLineStep(
              id: 'line',
              speaker: 'Élia',
              body: 'Bonjour.',
              characterId: 'elia',
            ),
          ],
        ),
      ],
    );

    expect(
      validateDialogueDocument(document).any(
        (issue) =>
            issue.severity == DialogueValidationSeverity.error &&
            issue.message.contains('portrait'),
      ),
      isTrue,
    );
  });

  test('project validation reports unknown and unassigned portrait refs', () {
    final project = ProjectManifest(
      name: 'Portrait validation',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      characterStudioCatalog: const ProjectCharacterStudioCatalog(
        portraitStates: <CharacterPortraitStateDefinition>[
          CharacterPortraitStateDefinition(
            id: 'surprised',
            displayName: 'Surprise',
          ),
        ],
      ),
      characters: const <ProjectCharacterEntry>[
        ProjectCharacterEntry(id: 'elia', name: 'Élia', tilesetId: 'elia'),
      ],
    );
    final document = DialogueEditorDocument(
      nodes: <DialogueEditorNode>[
        DialogueEditorNode(
          id: 'node',
          title: 'Start',
          steps: <DialogueEditorStep>[
            DeLineStep(
              id: 'missing-portrait',
              speaker: 'Élia',
              body: 'Bonjour.',
              characterId: 'elia',
              portraitStateId: 'surprised',
            ),
            DeLineStep(
              id: 'unknown-character',
              speaker: 'Fantôme',
              body: 'Boo.',
              characterId: 'ghost',
              portraitStateId: 'surprised',
            ),
          ],
        ),
      ],
    );

    final issues = validateDialogueDocument(document, project: project);

    expect(
      issues.any(
        (issue) =>
            issue.severity == DialogueValidationSeverity.warning &&
            issue.message.contains('ne possède pas encore'),
      ),
      isTrue,
    );
    expect(
      issues.any(
        (issue) =>
            issue.severity == DialogueValidationSeverity.error &&
            issue.message.contains('personnage inconnu'),
      ),
      isTrue,
    );
  });
}

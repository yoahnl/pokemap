import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'typed dialogue references cover lines, nested choices and exact Fact identities',
    () {
      final doc = const YarnDialogueCompiler().compile('''
title: Start
---
Score {{ fact.score }}
-> {{ fact.name }}
    {{ fact.enabled }}
===
''');
      final project = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
            id: 'score',
            label: 'Score',
            initialValue: NarrativeValue.integer(0),
          ),
          NarrativeFactDefinition(
            id: 'name',
            label: 'Name',
            initialValue: const NarrativeValue.string('Tom'),
          ),
          NarrativeFactDefinition(id: 'enabled', label: 'Enabled'),
        ],
      );
      expect(dialogueDocumentFactIds(doc), {'score', 'name', 'enabled'});
      validateDialogueFactReferences(project: project, document: doc);
      expect(
        () => validateDialogueFactReferences(
          project: project.copyWith(facts: []),
          document: doc,
        ),
        throwsFormatException,
      );
      expect(dialogueFactPlaceholder('score'), '{{ fact.score }}');
    },
  );

  test(
    'malformed Fact substitutions and placeholders crossing styles fail closed',
    () {
      final document = RuntimeDialogueDocument(nodes: [RuntimeDialogueNode(title: 'Start', steps: [
        RuntimeDialogueLine('{{ fact.score }}', feedback: DialogueLineFeedback(segments: [
          DialogueTextSegment('{{ fact.'), DialogueTextSegment('score }}')]))])]);
      expect(() => validateDialogueFactReferences(project: const ProjectManifest(name: 'Test', maps: [], tilesets: []), document: document), throwsFormatException);
      expect(() => dialogueTextFactIds('{{ fact. }}'), throwsFormatException);
      expect(
        () => validateDialogueFactFeedback(
          DialogueLineFeedback(
            segments: [
              DialogueTextSegment('{{ fact.'),
              DialogueTextSegment('score }}'),
            ],
          ),
        ),
        throwsFormatException,
      );
      validateDialogueFactFeedback(
        DialogueLineFeedback(
          segments: [DialogueTextSegment('{{ fact.score }}')],
        ),
      );
    },
  );
}

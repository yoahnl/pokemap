import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/use_cases/project_dialogue_use_cases.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_model.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_yarn_codec.dart';

void main() {
  group('Dialogue Yarn codec', () {
    test('parse minimal project stub yields at least one node and start marker',
        () {
      final yarn = minimalYarnStub('Reveil');
      final doc = parseYarnToDocument(yarn);
      expect(doc.nodes, isNotEmpty);
      expect(doc.nodes.first.title, 'Reveil');
      expect(doc.nodes.first.steps.first, isA<DeStartStep>());
    });

    test('emit then parse preserves line and jump semantics', () {
      const yarn = '''
title: A
---
hero: Hello
<<jump B>>
===
title: B
---
prof: Welcome
===
''';
      final doc = parseYarnToDocument(yarn);
      final round = parseYarnToDocument(emitDocumentToYarn(doc));
      expect(round.nodes.length, 2);
      expect(round.nodes[0].title, 'A');
      expect(round.nodes[1].title, 'B');
      final aSteps =
          round.nodes[0].steps.where((s) => s is! DeStartStep).toList();
      expect(aSteps.whereType<DeLineStep>().length, 1);
      expect(aSteps.whereType<DeJumpStep>().single.targetTitle, 'B');
    });

    test('non-jump <<>> lines are preserved in round-trip', () {
      const yarn = '''
title: X
---
<<set \$x to 1>>
<<if \$y>>
hero: ok
===
''';
      final doc = parseYarnToDocument(yarn);
      final out = emitDocumentToYarn(doc);
      expect(out.contains('<<set'), isTrue);
      expect(out.contains('<<if'), isTrue);
    });

    test('choice outcome ids round-trip independently from visible labels', () {
      const yarn = '''
title: Start
---
Guide: Que décides-tu ?
-> Rendre l'objet
  <<outcome return_item>>
  Joueur: Je vais le rendre.
  <<jump Returned>>
-> Le garder
  <<outcome keep_item>>
  Joueur: Je le garde.
===
title: Returned
---
Guide: Merci.
===
''';

      final document = parseYarnToDocument(yarn);
      final choice =
          document.nodes.first.steps.whereType<DeChoiceStep>().single;

      expect(
        choice.branches.map((branch) => branch.outcomeId),
        ['return_item', 'keep_item'],
      );
      expect(choice.branches.first.label, "Rendre l'objet");
      expect(
        choice.branches.first.steps.whereType<DeCommandStep>(),
        isEmpty,
      );

      final emitted = emitDocumentToYarn(document);
      expect(emitted, contains('  <<outcome return_item>>'));
      expect(emitted, contains('  <<outcome keep_item>>'));

      final roundTrip = parseYarnToDocument(emitted);
      final roundTripChoice =
          roundTrip.nodes.first.steps.whereType<DeChoiceStep>().single;
      expect(
        roundTripChoice.branches.map((branch) => branch.outcomeId),
        ['return_item', 'keep_item'],
      );
      expect(
        roundTrip
            .documentOutcomes()
            .map((outcome) => (outcome.id, outcome.label)),
        [
          ('return_item', "Rendre l'objet"),
          ('keep_item', 'Le garder'),
        ],
      );
    });

    test('rich headers unicode and formatting round-trip byte for byte', () {
      const yarn = 'title: Phare\n'
          'tags: selbrume quête secondaire\n'
          'color: mist-blue\n'
          '---\n'
          'Maël:  Écoute la brume.  \n'
          '\n'
          '<<extension inconnue:été>>\n'
          '===\n';

      final document = parseYarnToDocument(yarn);

      expect(document.nodes.single.headers, [
        const DialogueEditorNodeHeader(
          name: 'tags',
          value: 'selbrume quête secondaire',
        ),
        const DialogueEditorNodeHeader(name: 'color', value: 'mist-blue'),
      ]);
      expect(emitDocumentToYarn(document), yarn);
    });

    test('edited rich document preserves extensions in canonical output', () {
      const yarn = 'title: Start\n'
          'tags: selbrume lore\n'
          'custom-extension: valeur\n'
          '---\n'
          'Guide: Bonjour  \n'
          '\n'
          '<<unknown data>>\n'
          '===\n';
      final parsed = parseYarnToDocument(yarn);

      final renamed = parsed.renameNode(parsed.nodes.single.id, 'Accueil');
      final emitted = emitDocumentToYarn(renamed);

      expect(emitted, contains('title: Accueil'));
      expect(emitted, contains('tags: selbrume lore'));
      expect(emitted, contains('custom-extension: valeur'));
      expect(emitted, contains('<<unknown data>>'));
    });

    test('manifest entry title selects entry without reordering Yarn nodes',
        () {
      const yarn = 'title: First\n---\n===\n'
          'title: Second\n---\n===\n';

      final document = parseYarnToDocument(
        yarn,
        entryNodeTitle: 'Second',
      );

      expect(document.nodes.first.title, 'First');
      expect(
        document.nodeById(document.effectiveEntryNodeId!)!.title,
        'Second',
      );
      expect(emitDocumentToYarn(document), yarn);
    });
  });
}

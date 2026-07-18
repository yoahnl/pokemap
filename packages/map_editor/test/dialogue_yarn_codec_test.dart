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
    });
  });
}

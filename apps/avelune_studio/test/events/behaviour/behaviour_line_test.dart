import 'dart:convert';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'behaviour_line_fixtures.dart';

void main() {
  group('generated ids', () {
    test('derive scene and dialogue ids from a generated uuid', () {
      final ids = lineIdGenerator().generate();
      expect(ids.sceneId, 'scene_evt_${lineUuids[0]}');
      expect(ids.dialogueId, 'dialogue_evt_${lineUuids[0]}');
      expect(ids.dialoguePath, 'dialogues/evt_${lineUuids[0]}.yarn');
    });

    test('skip a generated id already taken by a scene or a dialogue', () {
      final ids = lineIdGenerator().generate(
        sceneIds: {'scene_evt_${lineUuids[0]}'},
        dialogueIds: {'dialogue_evt_${lineUuids[1]}'},
      );
      expect(ids.sceneId, 'scene_evt_${lineUuids[2]}');
    });

    test('default generator yields distinct uuid ids, not names', () {
      final generator = BehaviourLineIdGenerator();
      final first = generator.generate();
      final second = generator.generate();
      expect(first.sceneId, isNot(second.sceneId));
      expect(
        first.dialogueId,
        matches(RegExp(r'^dialogue_evt_[0-9a-f]{8}-[0-9a-f]{4}-7')),
      );
    });
  });

  group('line draft', () {
    test('produces a scene the recognizer reads back as the same line', () {
      final draft = createdDraft([
        'Bonjour !',
        'Deuxième boîte',
      ], speakerId: 'mom');
      final reading = readLine(
        _storedScene(draft.scene),
        storedDialogue(draft.dialogue),
      );
      expect(reading, isA<BehaviourLine>());
      final line = reading as BehaviourLine;
      expect(line.lines, ['Bonjour !', 'Deuxième boîte']);
      expect(line.speakerId, 'mom');
      expect(line.dialogueId, draft.ids.dialogueId);
      expect(line.sceneId, draft.ids.sceneId);
      expect(line.studioFormat, isTrue);
      expect(draft.dialogue.entry.relativePath, draft.ids.dialoguePath);
      expect(draft.scene.graph.nodes.map((node) => node.kind), [
        SceneNodeKind.start,
        SceneNodeKind.yarnDialogue,
        SceneNodeKind.end,
      ]);
    });

    test('refuses an empty line list, a blank line and a blank name', () {
      final ids = lineIdGenerator().generate();
      expect(
        (createBehaviourLine(
          ids: ids,
          name: 'Talk',
          lines: const [],
        ) as BehaviourLineRefused).reason,
        BehaviourLineRefusal.noLine,
      );
      final blank = createBehaviourLine(
        ids: ids,
        name: 'Talk',
        lines: ['ok', ' \n '],
      ) as BehaviourLineRefused;
      expect(blank.reason, BehaviourLineRefusal.blankLine);
      expect(blank.lineIndex, 1);
      expect(
        (createBehaviourLine(
          ids: ids,
          name: '  ',
          lines: ['ok'],
        ) as BehaviourLineRefused).reason,
        BehaviourLineRefusal.blankName,
      );
    });

    test('refuses a speaker the dialogue format cannot reference', () {
      final refused = createBehaviourLine(
        ids: lineIdGenerator().generate(),
        name: 'Talk',
        lines: ['ok'],
        speakerId: 'two words',
      ) as BehaviourLineRefused;
      expect(refused.reason, BehaviourLineRefusal.rejectedByDialogueFormat);
    });
  });

  group('text safety through the real codec', () {
    const samples = <String>[
      'Il a dit "bonjour" puis \'salut\'',
      '# pas un tag',
      'fin de ligne # tag:valeur',
      '<<jump Start>>',
      '<<outcome won>> et >> puis <<',
      '[b]gras[/b] [wave]',
      '{\$player} {0} }{',
      '-> pas un choix',
      '   espaces autour   ',
      '\ttabulation\t',
      'ligne 1\nligne 2',
      'paragraphe\n\nautre paragraphe',
      '\n\nlignes vides avant',
      'retour\r\nchariot',
      '===',
      '---',
      'title: Faux',
      'avelune: "nom"',
      r'antislash \ et \" et \n littéral',
      'émoji 🎉 accents éàçœ 日本語',
      'drapeau 🇫🇷 famille 👨‍👩‍👧',
      '\u0000 nul et \u001f contrôle',
      'séparateurs \u2028 et \u2029',
      'surrogate seul \uD83D au milieu',
    ];

    for (final sample in samples) {
      test('round-trips ${jsonEncode(sample)}', () {
        final draft = createdDraft([sample, 'suite']);
        final reading = readLine(draft.scene, storedDialogue(draft.dialogue));
        expect(reading, isA<BehaviourLine>());
        expect((reading as BehaviourLine).lines, [sample, 'suite']);
        final runtime = const YarnDialogueCompiler().compile(
          storedDialogue(draft.dialogue).source,
        );
        expect(
          [
            for (final step in runtime.nodes.single.steps)
              (step as RuntimeDialogueLine).text,
          ],
          [sample, 'suite'],
        );
      });
    }
  });

  group('updating a line', () {
    test('rewrites only the dialogue content and keeps every id', () {
      final draft = createdDraft(['Avant'], speakerId: 'mom');
      final line = readLine(
        draft.scene,
        NarrativeDialogueSource(
          entry: draft.dialogue.entry,
          source: draft.dialogue.source,
          revision: 'rev-7',
        ),
      ) as BehaviourLine;
      final rewritten = rewriteBehaviourLine(
        line,
        lines: ['Après', 'encore'],
      ) as BehaviourLineAccepted<NarrativeDialogueSource>;
      expect(rewritten.value.entry.id, draft.ids.dialogueId);
      expect(rewritten.value.entry.relativePath, draft.ids.dialoguePath);
      expect(rewritten.value.revision, 'rev-7');
      final reread = readLine(
        draft.scene,
        storedDialogue(rewritten.value),
      ) as BehaviourLine;
      expect(reread.lines, ['Après', 'encore']);
      expect(reread.speakerId, isNull);
      expect(reread.sceneId, draft.ids.sceneId);
    });

    test('refuses a blank replacement', () {
      final draft = createdDraft(['Avant']);
      final line = readLine(draft.scene, draft.dialogue) as BehaviourLine;
      expect(
        (rewriteBehaviourLine(
          line,
          lines: ['  '],
        ) as BehaviourLineRefused).reason,
        BehaviourLineRefusal.blankLine,
      );
    });
  });
}

SceneAsset _storedScene(SceneAsset scene) => SceneAsset.fromJson(
  jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>,
);

import 'dart:convert';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const _uuids = [
  '01a16b62-614a-741c-be2e-18a338e7bcd6',
  '01a16b62-614a-7302-a9a2-0ab2445543de',
  '01a16b62-614a-7f70-bac5-2ba2474bc103',
];

BehaviourLineIdGenerator _generator([List<String> uuids = _uuids]) {
  var next = 0;
  return BehaviourLineIdGenerator(
    ids: NarrativeEventIdGenerator(rawUuidFactory: () => uuids[next++]),
  );
}

NarrativeEventRecord _owner(String sceneId, {String id = _eventId}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: 'Talk',
        source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        conditions: const [],
        sceneId: sceneId,
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    );

const _eventId = 'evt_01a16b62-614a-7ee8-b422-3d1da534c818';
const _otherEventId = 'evt_01a16b62-614a-7ee8-b422-3d1da534c819';

BehaviourLineDraft _created(List<String> lines, {String? speakerId}) {
  final outcome = createBehaviourLine(
    ids: _generator().generate(),
    name: 'Talk',
    lines: lines,
    speakerId: speakerId,
  );
  expect(outcome, isA<BehaviourLineAccepted<BehaviourLineDraft>>());
  return (outcome as BehaviourLineAccepted<BehaviourLineDraft>).value;
}

BehaviourLineReading _read(
  SceneAsset scene,
  NarrativeDialogueSource? dialogue, {
  List<NarrativeEventRecord>? owners,
}) => readBehaviourLine(
  scene: scene,
  behaviours: owners ?? [_owner(scene.id)],
  dialogue: dialogue,
);

NarrativeDialogueSource _stored(NarrativeDialogueSource source) =>
    NarrativeDialogueSource(
      entry: ProjectDialogueEntry.fromJson(
        jsonDecode(jsonEncode(source.entry.toJson())) as Map<String, dynamic>,
      ),
      source: utf8.decode(utf8.encode(source.source)),
      revision: source.revision,
    );

SceneAsset _storedScene(SceneAsset scene) => SceneAsset.fromJson(
  jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>,
);

SceneAsset _scene(Map<String, dynamic> Function(Map<String, dynamic>) edit) {
  final base = _created(['Hello']).scene.toJson();
  return SceneAsset.fromJson(
    edit(jsonDecode(jsonEncode(base)) as Map<String, dynamic>),
  );
}

NarrativeDialogueSource _foreign(String source, {String id = 'hgss-line'}) =>
    NarrativeDialogueSource(
      entry: ProjectDialogueEntry(
        id: id,
        name: 'Imported',
        relativePath: 'dialogues/imported.yarn',
      ),
      source: source,
      revision: 'rev-1',
    );

SceneAsset _sceneFor(String dialogueId) => behaviourLineScene(
  sceneId: 'hgss-scene',
  name: 'Imported',
  dialogueId: dialogueId,
);

void main() {
  group('generated ids', () {
    test('derive scene and dialogue ids from a generated uuid', () {
      final ids = _generator().generate();
      expect(ids.sceneId, 'scene_evt_${_uuids[0]}');
      expect(ids.dialogueId, 'dialogue_evt_${_uuids[0]}');
      expect(ids.dialoguePath, 'dialogues/evt_${_uuids[0]}.yarn');
    });

    test('skip a generated id already taken by a scene or a dialogue', () {
      final ids = _generator().generate(
        sceneIds: {'scene_evt_${_uuids[0]}'},
        dialogueIds: {'dialogue_evt_${_uuids[1]}'},
      );
      expect(ids.sceneId, 'scene_evt_${_uuids[2]}');
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
      final draft = _created(['Bonjour !', 'Deuxième boîte'], speakerId: 'mom');
      final reading = _read(_storedScene(draft.scene), _stored(draft.dialogue));
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
      final ids = _generator().generate();
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
        ids: _generator().generate(),
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
        final draft = _created([sample, 'suite']);
        final reading = _read(draft.scene, _stored(draft.dialogue));
        expect(reading, isA<BehaviourLine>());
        expect((reading as BehaviourLine).lines, [sample, 'suite']);
        final runtime = const YarnDialogueCompiler().compile(
          _stored(draft.dialogue).source,
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
      final draft = _created(['Avant'], speakerId: 'mom');
      final line = _read(
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
      final reread =
          _read(draft.scene, _stored(rewritten.value)) as BehaviourLine;
      expect(reread.lines, ['Après', 'encore']);
      expect(reread.speakerId, isNull);
      expect(reread.sceneId, draft.ids.sceneId);
    });

    test('refuses a blank replacement', () {
      final draft = _created(['Avant']);
      final line = _read(draft.scene, draft.dialogue) as BehaviourLine;
      expect(
        (rewriteBehaviourLine(
          line,
          lines: ['  '],
        ) as BehaviourLineRefused).reason,
        BehaviourLineRefusal.blankLine,
      );
    });
  });

  group('recognizer', () {
    BehaviourNotLineReason reason(BehaviourLineReading reading) {
      expect(reading, isA<BehaviourNotALine>());
      return (reading as BehaviourNotALine).reason;
    }

    test('rejects a scene owned by zero or two behaviours', () {
      final draft = _created(['Hello']);
      expect(
        reason(_read(draft.scene, draft.dialogue, owners: const [])),
        BehaviourNotLineReason.owners,
      );
      expect(
        reason(
          _read(
            draft.scene,
            draft.dialogue,
            owners: [
              _owner(draft.scene.id),
              _owner(draft.scene.id, id: _otherEventId),
            ],
          ),
        ),
        BehaviourNotLineReason.owners,
      );
    });

    test('rejects a missing or mismatching dialogue', () {
      final draft = _created(['Hello']);
      expect(
        reason(_read(draft.scene, null)),
        BehaviourNotLineReason.dialogueUnavailable,
      );
      expect(
        reason(_read(draft.scene, _foreign('title: Start\n---\nHi\n===\n'))),
        BehaviourNotLineReason.dialogueUnavailable,
      );
    });

    test('rejects a scene with an extra node', () {
      final scene = _scene((json) {
        final graph = json['graph'] as Map<String, dynamic>;
        (graph['nodes'] as List).add({
          'id': 'extra',
          'kind': 'end',
          'payload': {'kind': 'end'},
        });
        return json;
      });
      expect(
        reason(_read(scene, _created(['Hello']).dialogue)),
        BehaviourNotLineReason.sceneShape,
      );
      expect(behaviourLineDialogueId(scene), isNull);
    });

    test('rejects a dialogue node that expects outcomes', () {
      final scene = _scene((json) {
        final nodes = (json['graph'] as Map<String, dynamic>)['nodes'] as List;
        final payload = (nodes[1] as Map<String, dynamic>)['payload'] as Map;
        payload['expectedOutcomes'] = ['won'];
        return json;
      });
      expect(
        reason(_read(scene, _created(['Hello']).dialogue)),
        BehaviourNotLineReason.dialoguePolicies,
      );
    });

    test('rejects a scene whose end emits an outcome', () {
      final scene = _scene((json) {
        final nodes = (json['graph'] as Map<String, dynamic>)['nodes'] as List;
        (nodes[2] as Map<String, dynamic>)['payload'] = {
          'kind': 'end',
          'sceneOutcomeId': 'done',
        };
        return json;
      });
      expect(
        reason(_read(scene, _created(['Hello']).dialogue)),
        BehaviourNotLineReason.sceneOutcome,
      );
    });

    test('rejects choices, jumps, portraits, mixed speakers and commands', () {
      final scene = _sceneFor('hgss-line');
      final cases = <String, BehaviourNotLineReason>{
        'title: Start\n---\nQuestion ?\n-> Oui\n    <<jump Start>>\n===\n':
            BehaviourNotLineReason.choices,
        'title: Start\n---\nA\n<<jump Other>>\n===\ntitle: Other\n---\nB\n===\n':
            BehaviourNotLineReason.dialogueNodes,
        'title: Start\n---\nA\n<<jump Start>>\n===\n':
            BehaviourNotLineReason.jumps,
        'title: Start\n---\n<<portrait mom happy>>\nA\n===\n':
            BehaviourNotLineReason.portraits,
        'title: Start\n---\n<<speaker mom>>\nA\n<<speaker dad>>\nB\n===\n':
            BehaviourNotLineReason.mixedSpeakers,
        'title: Start\n---\nA\n<<wait 1>>\nB\n===\n':
            BehaviourNotLineReason.foreignContent,
        'title: Start\ntags: imported\n---\nA\n===\n':
            BehaviourNotLineReason.foreignContent,
        'title: Start\n---\nA\n': BehaviourNotLineReason.dialogueUnreadable,
        'title: Other\n---\nA\n===\n': BehaviourNotLineReason.dialogueNodes,
      };
      for (final entry in cases.entries) {
        expect(
          reason(_read(scene, _foreign(entry.key))),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('rejects a dialogue declaring outcomes', () {
      final scene = _sceneFor('hgss-line');
      final dialogue = _foreign('title: Start\n---\nA\n===\n');
      final withOutcome = NarrativeDialogueSource(
        entry: dialogue.entry.copyWith(
          declaredOutcomes: const [
            DialogueDeclaredOutcome(id: 'won', label: 'Won'),
          ],
        ),
        source: dialogue.source,
      );
      expect(
        reason(_read(scene, withOutcome)),
        BehaviourNotLineReason.dialogueOutcomes,
      );
    });

    test('reads an imported plain dialogue and rewrites it faithfully', () {
      const source =
          'title: Start\n---\n<<speaker mom>>\nAllez, le Professeur t’attend!  \n'
          '<<speaker mom>>\n"Vas-y" #vite\n===\n';
      final scene = _sceneFor('hgss-line');
      final line = _read(scene, _foreign(source)) as BehaviourLine;
      expect(line.studioFormat, isFalse);
      expect(line.speakerId, 'mom');
      expect(line.lines, ['Allez, le Professeur t’attend!', '"Vas-y" #vite']);
      final rewritten = rewriteBehaviourLine(
        line,
        lines: line.lines,
        speakerId: 'mom',
      ) as BehaviourLineAccepted<NarrativeDialogueSource>;
      expect(
        const YarnDialogueCompiler().compile(rewritten.value.source),
        const YarnDialogueCompiler().compile(source),
      );
      expect(rewritten.value.entry.id, 'hgss-line');
      expect(rewritten.value.revision, 'rev-1');
      final reread = _read(scene, _stored(rewritten.value)) as BehaviourLine;
      expect(reread.studioFormat, isTrue);
      expect(reread.lines, line.lines);
    });
  });

  group('shared dialogue', () {
    test('lists the other scenes that play the same dialogue', () {
      final draft = _created(['Hello']);
      final copy = behaviourLineScene(
        sceneId: 'other-scene',
        name: 'Other',
        dialogueId: draft.ids.dialogueId,
      );
      final unrelated = behaviourLineScene(
        sceneId: 'unrelated',
        name: 'Unrelated',
        dialogueId: 'dialogue_other',
      );
      final sharing = behaviourDialogueSharing(
        sceneId: draft.scene.id,
        dialogueId: draft.ids.dialogueId,
        scenes: [draft.scene, copy, unrelated],
      );
      expect(sharing.shared, isTrue);
      expect(sharing.otherSceneIds, ['other-scene']);
      expect(
        behaviourDialogueSharing(
          sceneId: draft.scene.id,
          dialogueId: draft.ids.dialogueId,
          scenes: [draft.scene, unrelated],
        ).shared,
        isFalse,
      );
    });

    test('detaching gives this scene its own copy under new ids', () {
      final draft = _created(['Hello'], speakerId: 'mom');
      final line = _read(draft.scene, draft.dialogue) as BehaviourLine;
      final ids = _generator(['01a16b62-614a-7000-8000-000000000001'])
          .generate();
      final detached = detachBehaviourLine(
        line: line,
        scene: draft.scene,
        ids: ids,
      );
      expect(detached.scene.id, draft.scene.id);
      expect(behaviourLineDialogueId(detached.scene), ids.dialogueId);
      final beforeJson = draft.scene.toJson();
      final afterJson = detached.scene.toJson();
      final nodes = (afterJson['graph'] as Map)['nodes'] as List;
      ((nodes[1] as Map)['payload'] as Map)['dialogueId'] =
          draft.ids.dialogueId;
      expect(jsonEncode(afterJson), jsonEncode(beforeJson));
      expect(detached.line.dialogue.entry.id, ids.dialogueId);
      expect(detached.line.dialogue.entry.relativePath, ids.dialoguePath);
      expect(detached.line.dialogue.source, draft.dialogue.source);
      expect(detached.line.dialogue.revision, isNull);
      final reread =
          _read(detached.scene, detached.line.dialogue) as BehaviourLine;
      expect(reread.lines, ['Hello']);
      expect(reread.speakerId, 'mom');
      expect(draft.dialogue.entry.id, draft.ids.dialogueId);
    });
  });
}

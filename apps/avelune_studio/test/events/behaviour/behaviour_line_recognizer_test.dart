import 'dart:convert';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'behaviour_line_fixtures.dart';

void main() {
  group('recognizer', () {
    BehaviourNotLineReason reason(BehaviourLineReading reading) {
      expect(reading, isA<BehaviourNotALine>());
      return (reading as BehaviourNotALine).reason;
    }

    test('rejects a scene owned by zero or two behaviours', () {
      final draft = createdDraft(['Hello']);
      expect(
        reason(readLine(draft.scene, draft.dialogue, owners: const [])),
        BehaviourNotLineReason.owners,
      );
      expect(
        reason(
          readLine(
            draft.scene,
            draft.dialogue,
            owners: [
              lineOwner(draft.scene.id),
              lineOwner(draft.scene.id, id: _otherEventId),
            ],
          ),
        ),
        BehaviourNotLineReason.owners,
      );
    });

    test('rejects a missing or mismatching dialogue', () {
      final draft = createdDraft(['Hello']);
      expect(
        reason(readLine(draft.scene, null)),
        BehaviourNotLineReason.dialogueUnavailable,
      );
      expect(
        reason(readLine(draft.scene, _foreign('title: Start\n---\nHi\n===\n'))),
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
        reason(readLine(scene, createdDraft(['Hello']).dialogue)),
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
        reason(readLine(scene, createdDraft(['Hello']).dialogue)),
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
        reason(readLine(scene, createdDraft(['Hello']).dialogue)),
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
          reason(readLine(scene, _foreign(entry.key))),
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
        reason(readLine(scene, withOutcome)),
        BehaviourNotLineReason.dialogueOutcomes,
      );
    });

    test('reads an imported plain dialogue and rewrites it faithfully', () {
      const source =
          'title: Start\n---\n<<speaker mom>>\nAllez, le Professeur t’attend!  \n'
          '<<speaker mom>>\n"Vas-y" #vite\n===\n';
      final scene = _sceneFor('hgss-line');
      final line = readLine(scene, _foreign(source)) as BehaviourLine;
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
      final reread =
          readLine(scene, storedDialogue(rewritten.value)) as BehaviourLine;
      expect(reread.studioFormat, isTrue);
      expect(reread.lines, line.lines);
    });
  });

  group('shared dialogue', () {
    test('lists the other scenes that play the same dialogue', () {
      final draft = createdDraft(['Hello']);
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
      final draft = createdDraft(['Hello'], speakerId: 'mom');
      final line = readLine(draft.scene, draft.dialogue) as BehaviourLine;
      final ids = lineIdGenerator(['01a16b62-614a-7000-8000-000000000001'])
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
          readLine(detached.scene, detached.line.dialogue) as BehaviourLine;
      expect(reread.lines, ['Hello']);
      expect(reread.speakerId, 'mom');
      expect(draft.dialogue.entry.id, draft.ids.dialogueId);
    });
  });
}

const _otherEventId = 'evt_01a16b62-614a-7ee8-b422-3d1da534c819';

SceneAsset _scene(Map<String, dynamic> Function(Map<String, dynamic>) edit) {
  final base = createdDraft(['Hello']).scene.toJson();
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

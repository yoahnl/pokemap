import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _beforeText = 'Tell me, do you like to fish?';
const _afterText = 'Dis-moi, tu aimes la pêche ?';

void main() {
  for (final jsonl in [false, true]) {
    test('whole line edits retain inline cue offsets, JSONL=$jsonl', () async {
      final f = await _Fixture.create(withAudio: true, inlineOffset: 6);
      addTearDown(f.dispose);
      final request = await f.request('dialogue.source_update',
          f.parameters('dialogue.source_update',
              source: f.sourceText.replaceFirst(_beforeText, _afterText),
              edits: [_edit()]));
      if (jsonl) {
        final worker = JsonlWorker(api: f.readApi, mutations: f.api);
        final plan = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': 'plan-inline', 'command': 'plan', 'args': {
              'projectHandle': f.opened.projectHandle.value,
              'request': request.toJson(),
            }}))) as Map<String, dynamic>);
        expect(plan.status, AuthoringResultStatus.success, reason: jsonEncode(plan.toJson()));
        final applied = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': 'apply-inline', 'command': 'apply', 'args': {
              'projectHandle': f.opened.projectHandle.value,
              'planId': plan.data['planId'], 'operationId': 'inline-edit',
            }}))) as Map<String, dynamic>);
        expect(applied.status, AuthoringResultStatus.success, reason: jsonEncode(applied.toJson()));
      } else {
        final plan = await f.api.planMutation(f.opened.projectHandle, request);
        await f.api.apply(f.opened.projectHandle,
            planId: plan.planId, operationId: 'inline-edit');
      }
      final after = await f.loader.load(f.opened.projectHandle);
      expect(after.manifest.scenes.single, _replaceSceneText(f.project.scenes.single));
      final feedback = _payload(after.manifest.scenes.single).linePolicies.single.feedback;
      expect(feedback.audioCue!.revealOffset, 6);
      expect(feedback.audioCue, _payload(f.project.scenes.single).linePolicies.single.feedback.audioCue);
    });
  }
  for (final emptySegments in [false, true]) {
    test('short line refuses inline cue atomically, emptySegments=$emptySegments', () async {
      final f = await _Fixture.create(withAudio: true,
          inlineOffset: 6, withEmptySegments: emptySegments);
      addTearDown(f.dispose);
      final projectBytes = await f.projectFile.readAsBytes();
      await expectLater(f.api.planMutation(f.opened.projectHandle,
          await f.request('dialogue.source_update',
              f.parameters('dialogue.source_update',
                  source: f.sourceText.replaceFirst(_beforeText, 'Court'),
                  edits: [{..._edit(), 'afterText': 'Court'}]))),
          _domain('dialogue.line_text_edits_audio_cue_out_of_bounds'));
      expect(await f.projectFile.readAsBytes(), projectBytes);
      expect(await f.sourceFile.readAsString(), f.sourceText);
    });
  }
  test('the public line text edit codec is exact and rejects malformed scopes',
      () {
    final edit =
        DialogueLineTextEdit.fromJson(Map<String, dynamic>.from(_edit()));
    expect(edit.toJson(), _edit());
    expect(
        DialogueLineTextEdit.fromJson(Map<String, dynamic>.from(edit.toJson())),
        edit);
    for (final raw in [
      {..._edit(), 'nodeName': ' Start'},
      {..._edit(), 'lineIndex': -1},
      {..._edit(), 'lineIndex': 0.0},
      {..._edit(), 'beforeText': _afterText},
      {..._edit(), 'afterText': ''},
      {..._edit(), 'unknown': true},
    ]) {
      expect(() => DialogueLineTextEdit.fromJson(raw), throwsFormatException);
    }
  });

  for (final action in ['dialogue.source_update', 'dialogue.update']) {
    test('$action atomically reconciles every exact converted styled scope',
        () async {
      final f = await _Fixture.create(copies: 2);
      addTearDown(f.dispose);
      final before = await f.loader.load(f.opened.projectHandle);
      final beforeProjectBytes = await f.projectFile.readAsBytes();
      final source = f.sourceText.replaceFirst(_beforeText, _afterText);
      final parameters = f.parameters(action, source: source, edits: [_edit()]);
      final plan = await f.api.planMutation(
          f.opened.projectHandle, await f.request(action, parameters));
      expect(plan.plan.changeSet.changes.map((e) => e.storageKey).toSet(),
          {'project.json', f.entry.relativePath});
      expect(
          plan.plan.changeSet.diff.entries
              .where((e) => e.path.startsWith('/scenes/'))
              .map((e) => e.path)
              .toSet(),
          before.manifest.scenes
              .map((e) =>
                  '/scenes/${e.id}/graph/nodes/node_1/payload/linePolicies')
              .toSet());
      expect(await f.projectFile.readAsBytes(), beforeProjectBytes);
      expect(await f.sourceFile.readAsString(), f.sourceText);
      final applied = await f.api.apply(f.opened.projectHandle,
          planId: plan.planId, operationId: action);
      final after = await f.loader.load(f.opened.projectHandle);
      expect(after.revision, isNot(before.revision));
      expect(await f.sourceFile.readAsString(), source);
      for (var i = 0; i < before.manifest.scenes.length; i++) {
        final original = before.manifest.scenes[i];
        expect(after.manifest.scenes[i], _replaceSceneText(original));
      }
      if (action == 'dialogue.update') {
        expect(after.manifest.dialogues.single.name, 'Pêcheur traduit');
      }
      final receipt = Map<String, Object?>.from(applied['receipt']! as Map);
      await f.api.undo(f.opened.projectHandle,
          entryId: receipt['receiptId']! as String,
          idempotencyKey: 'undo-$action');
      expect(await f.projectFile.readAsBytes(), beforeProjectBytes);
      expect(await f.sourceFile.readAsString(), f.sourceText);
      expect((await f.loader.load(f.opened.projectHandle)).revision,
          before.revision);
    });

    test('$action keeps the exact line feedback guard strict without intent',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.projectFile.readAsBytes();
      await expectLater(
          f.api.planMutation(
              f.opened.projectHandle,
              await f.request(
                  action,
                  f.parameters(action,
                      source:
                          f.sourceText.replaceFirst(_beforeText, _afterText)))),
          _domain('dialogue.scene_line_policy_references_blocking'));
      expect(await f.projectFile.readAsBytes(), before);
      expect(await f.sourceFile.readAsString(), f.sourceText);
    });

    test('JSONL exposes and transports $action explicit line text intent',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final worker = JsonlWorker(api: f.readApi, mutations: f.api);
      Future<AuthoringResult> command(
              String command, Map<String, Object?> args) async =>
          AuthoringResult.fromJson(jsonDecode(await worker.processLine(
                  jsonEncode(
                      {'id': command, 'command': command, 'args': args})))
              as Map<String, dynamic>);
      final described = await command('describe', {});
      expect(jsonEncode(described.toJson()), contains('lineTextEdits'));
      final request = await f.request(
          action,
          f.parameters(action,
              source: f.sourceText.replaceFirst(_beforeText, _afterText),
              edits: [_edit()]));
      final planned = await command('plan', {
        'projectHandle': f.opened.projectHandle.value,
        'request': request.toJson(),
      });
      expect(planned.status, AuthoringResultStatus.success,
          reason: jsonEncode(planned.toJson()));
      final applied = await command('apply', {
        'projectHandle': f.opened.projectHandle.value,
        'planId': planned.data['planId'],
        'operationId': 'jsonl-$action',
      });
      expect(applied.status, AuthoringResultStatus.success,
          reason: jsonEncode(applied.toJson()));
      expect(
          _payload((await f.loader.load(f.opened.projectHandle))
                  .manifest
                  .scenes
                  .single)
              .linePolicies
              .single
              .feedback
              .segments
              .single,
          DialogueTextSegment(_afterText,
              style: _payload(f.project.scenes.single)
                  .linePolicies
                  .single
                  .feedback
                  .segments
                  .whereType<DialogueTextSegment>()
                  .single
                  .style));
    });
  }

  test('uniform text reconciliation retains every timing and sound field',
      () async {
    final f = await _Fixture.create(withAudio: true);
    addTearDown(f.dispose);
    final source = f.sourceText.replaceFirst(_beforeText, _afterText);
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request(
            'dialogue.source_update',
            f.parameters('dialogue.source_update',
                source: source, edits: [_edit()])));
    await f.api.apply(f.opened.projectHandle,
        planId: plan.planId, operationId: 'sound-preserved');
    final after = await f.loader.load(f.opened.projectHandle);
    expect(after.manifest.scenes.single,
        _replaceSceneText(f.project.scenes.single));
    expect(after.manifest.cinematicMediaAssets, f.project.cinematicMediaAssets);
  });

  test('unedited rich feedback stays exact while a uniform line changes',
      () async {
    for (final icon in [false, true]) {
      final f = await _Fixture.create(
          withUneditedRichLine: true, withUneditedIconLine: icon);
      addTearDown(f.dispose);
      final before = _payload(f.project.scenes.single).linePolicies.last;
      final plan = await f.api.planMutation(
          f.opened.projectHandle,
          await f.request(
              'dialogue.source_update',
              f.parameters('dialogue.source_update',
                  source: f.sourceText.replaceFirst(_beforeText, _afterText),
                  edits: [_edit()])));
      await f.api.apply(f.opened.projectHandle,
          planId: plan.planId, operationId: 'rich-unchanged');
      final after = await f.loader.load(f.opened.projectHandle);
      expect(_payload(after.manifest.scenes.single).linePolicies.last, before);
    }
  });

  test('empty duplicate unknown stale and incomplete intents refuse all writes',
      () async {
    for (final edits in <Object?>[
      [],
      [_edit(), _edit()],
      [
        {..._edit(), 'nodeName': 'Absent'}
      ],
      [
        {..._edit(), 'lineIndex': 99}
      ],
      [
        {..._edit(), 'beforeText': 'Ancien texte incorrect'}
      ],
      [
        {..._edit(), 'afterText': 'Autre remplacement'}
      ],
      [
        {..._edit(), 'lineIndex': -1}
      ],
      [
        {..._edit(), 'lineIndex': 0.0}
      ],
      [
        {..._edit(), 'extra': true}
      ],
      [
        {'nodeName': 'Start', 'lineIndex': 0, 'beforeText': _beforeText}
      ],
      'not a list',
      null,
    ]) {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.projectFile.readAsBytes();
      await expectLater(
          f.api.planMutation(
              f.opened.projectHandle,
              await f.request('dialogue.source_update', {
                ...f.parameters('dialogue.source_update',
                    source: f.sourceText.replaceFirst(_beforeText, _afterText)),
                'lineTextEdits': edits,
              })),
          _domain('dialogue.line_text_edits_invalid'));
      expect(await f.projectFile.readAsBytes(), before, reason: '$edits');
      expect(await f.sourceFile.readAsString(), f.sourceText);
    }
  });

  test('bounded edits reject changed choices commands and line topology',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final edited = f.sourceText.replaceFirst(_beforeText, _afterText);
    for (final source in [
      edited.replaceFirst('YES', 'OUI'),
      edited.replaceFirst('choice_0', 'choice_1'),
      edited.replaceFirst('---\n', '---\nInserted\n'),
      edited.replaceFirst('---\n', '---\n<<speaker Changed>>\n'),
      edited.replaceFirst('===', '<<jump Start>>\n==='),
    ]) {
      final before = await f.projectFile.readAsBytes();
      await expectLater(
          f.api.planMutation(
              f.opened.projectHandle,
              await f.request(
                  'dialogue.source_update',
                  f.parameters('dialogue.source_update',
                      source: source, edits: [_edit()]))),
          _domain('dialogue.line_text_edits_structure_changed'));
      expect(await f.projectFile.readAsBytes(), before);
      expect(await f.sourceFile.readAsString(), f.sourceText);
    }
  });

  test('an edited multi-segment line refuses without collapsing the style runs',
      () async {
    final f = await _Fixture.create(withEditedRichLine: true);
    addTearDown(f.dispose);
    final before = await f.projectFile.readAsBytes();
    await expectLater(
        f.api.planMutation(
            f.opened.projectHandle,
            await f.request(
                'dialogue.source_update',
                f.parameters('dialogue.source_update',
                    source: f.sourceText.replaceFirst(_beforeText, _afterText),
                    edits: [_edit()]))),
        _domain('dialogue.line_text_edits_rich_feedback_unsupported'));
    expect(await f.projectFile.readAsBytes(), before);
    expect(await f.sourceFile.readAsString(), f.sourceText);
  });

  test('one rich consumer prevents every linked scene and source from changing',
      () async {
    final f = await _Fixture.create(copies: 2);
    addTearDown(f.dispose);
    final json =
        jsonDecode(jsonEncode(f.project.toJson())) as Map<String, dynamic>;
    final scenes = json['scenes'] as List<dynamic>;
    final graph =
        (scenes.last as Map<String, dynamic>)['graph'] as Map<String, dynamic>;
    final node = (graph['nodes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere((node) => node['id'] == 'node_1');
    final payload = node['payload'] as Map<String, dynamic>;
    final policy = (payload['linePolicies'] as List<dynamic>).single
        as Map<String, dynamic>;
    (policy['feedback'] as Map<String, dynamic>)['segments'] = [
      {'kind': 'text', 'text': 'Tell me, '},
      {'kind': 'text', 'text': 'do you like to fish?'},
    ];
    await f.projectFile.writeAsString(jsonEncode(json));
    final bytes = await f.projectFile.readAsBytes();
    await expectLater(
        f.api.planMutation(
            f.opened.projectHandle,
            await f.request(
                'dialogue.source_update',
                f.parameters('dialogue.source_update',
                    source: f.sourceText.replaceFirst(_beforeText, _afterText),
                    edits: [_edit()]))),
        _domain('dialogue.line_text_edits_rich_feedback_unsupported'));
    expect(await f.projectFile.readAsBytes(), bytes);
    expect(await f.sourceFile.readAsString(), f.sourceText);
  });

  test('a text edit cannot publish against a stale source revision', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final request = await f.request(
        'dialogue.source_update',
        f.parameters('dialogue.source_update',
            source: f.sourceText.replaceFirst(_beforeText, _afterText),
            edits: [_edit()]));
    final external = '${f.sourceText}\n';
    await f.sourceFile.writeAsString(external);
    final before = await f.projectFile.readAsBytes();
    await expectLater(
        f.api.planMutation(f.opened.projectHandle, request),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')));
    expect(await f.projectFile.readAsBytes(), before);
    expect(await f.sourceFile.readAsString(), external);
  });

  test('audio-only empty segments remain independent of the line text',
      () async {
    final f = await _Fixture.create(withAudio: true, withEmptySegments: true);
    addTearDown(f.dispose);
    final beforeBytes = await f.projectFile.readAsBytes();
    final before = _payload(f.project.scenes.single);
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request(
            'dialogue.source_update',
            f.parameters('dialogue.source_update',
                source: f.sourceText.replaceFirst(_beforeText, _afterText),
                edits: [_edit()])));
    expect(plan.plan.changeSet.changes.map((c) => c.storageKey),
        [f.entry.relativePath]);
    await f.api.apply(f.opened.projectHandle,
        planId: plan.planId, operationId: 'audio-only');
    expect(await f.projectFile.readAsBytes(), beforeBytes);
    expect(
        _payload((await f.loader.load(f.opened.projectHandle))
            .manifest
            .scenes
            .single),
        before);
  });

  test(
      'edited icon feedback refuses without removing the icon or other policies',
      () async {
    final f = await _Fixture.create(withEditedIconLine: true);
    addTearDown(f.dispose);
    final bytes = await f.projectFile.readAsBytes();
    await expectLater(
        f.api.planMutation(
            f.opened.projectHandle,
            await f.request(
                'dialogue.source_update',
                f.parameters('dialogue.source_update',
                    source: f.sourceText.replaceFirst(_beforeText, _afterText),
                    edits: [
                      {
                        ..._edit(),
                        'beforeText': '$_beforeText\uFFFC',
                        'afterText': '$_afterText\uFFFC'
                      }
                    ]))),
        _domain('dialogue.line_text_edits_rich_feedback_unsupported'));
    expect(await f.projectFile.readAsBytes(), bytes);
    expect(await f.sourceFile.readAsString(), f.sourceText);
  });

  test('text changes without feedback still require exhaustive exact intents',
      () async {
    final f = await _Fixture.create(
        withUneditedRichLine: true, withoutPolicies: true);
    addTearDown(f.dispose);
    final bytes = await f.projectFile.readAsBytes();
    final source = f.sourceText
        .replaceFirst(_beforeText, _afterText)
        .replaceFirst('Other rich line.', 'Autre ligne.');
    await expectLater(
        f.api.planMutation(
            f.opened.projectHandle,
            await f.request(
                'dialogue.source_update',
                f.parameters('dialogue.source_update',
                    source: source, edits: [_edit()]))),
        _domain('dialogue.line_text_edits_invalid'));
    expect(await f.projectFile.readAsBytes(), bytes);
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request(
            'dialogue.source_update',
            f.parameters('dialogue.source_update', source: source, edits: [
              _edit(),
              {
                'nodeName': 'Start',
                'lineIndex': 1,
                'beforeText': 'Other rich line.',
                'afterText': 'Autre ligne.'
              },
            ])));
    expect(plan.plan.changeSet.changes.map((c) => c.storageKey),
        [f.entry.relativePath]);
    await f.api.apply(f.opened.projectHandle,
        planId: plan.planId, operationId: 'exhaustive-plaintext');
    expect(await f.projectFile.readAsBytes(), bytes);
    expect(await f.sourceFile.readAsString(), source);
  });

  test('two explicit text substitutions retain their declared fixed scopes',
      () async {
    final f = await _Fixture.create(
        withUneditedRichLine: true, withoutPolicies: true);
    addTearDown(f.dispose);
    final source = f.sourceText
        .replaceFirst(_beforeText, 'Other rich line.')
        .replaceFirst('Other rich line.\n===', '$_beforeText\n===');
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request(
            'dialogue.source_update',
            f.parameters('dialogue.source_update', source: source, edits: [
              {..._edit(), 'afterText': 'Other rich line.'},
              {
                'nodeName': 'Start',
                'lineIndex': 1,
                'beforeText': 'Other rich line.',
                'afterText': _beforeText
              },
            ])));
    await f.api.apply(f.opened.projectHandle,
        planId: plan.planId, operationId: 'explicit-substitutions');
    expect(await f.sourceFile.readAsString(), source);
  });

  test('quoted multiline command-looking replacement keeps exact literal text',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    const text = '  <<jump Piège>>\n-> Rien : été, "oui" !  ';
    final encoded = jsonEncode(text);
    final source = f.sourceText
        .replaceFirst(_beforeText, encoded.substring(1, encoded.length - 1));
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request(
            'dialogue.source_update',
            f.parameters('dialogue.source_update', source: source, edits: [
              {..._edit(), 'afterText': text}
            ])));
    await f.api.apply(f.opened.projectHandle,
        planId: plan.planId, operationId: 'literal-replacement');
    final after = await f.loader.load(f.opened.projectHandle);
    expect(
        (_payload(after.manifest.scenes.single)
                .linePolicies
                .single
                .feedback
                .segments
                .single as DialogueTextSegment)
            .text,
        text);
  });

  test('partial promotion recovers all scopes and undo restores both resources',
      () async {
    var crashed = false;
    final f = await _Fixture.create(
        copies: 2,
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    addTearDown(f.dispose);
    final bytes = await f.projectFile.readAsBytes();
    final source = f.sourceText.replaceFirst(_beforeText, _afterText);
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request(
            'dialogue.source_update',
            f.parameters('dialogue.source_update',
                source: source, edits: [_edit()])));
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId, operationId: 'partial-text-edit'),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    final recovered = await f.api
        .recover(f.opened.projectHandle, operationId: 'partial-text-edit');
    expect(await f.sourceFile.readAsString(), source);
    final after = await f.loader.load(f.opened.projectHandle);
    for (var i = 0; i < f.project.scenes.length; i++) {
      expect(after.manifest.scenes[i], _replaceSceneText(f.project.scenes[i]));
    }
    final receipt = Map<String, Object?>.from(recovered['receipt']! as Map);
    await f.api.undo(f.opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'undo-recovered-edit');
    expect(await f.projectFile.readAsBytes(), bytes);
    expect(await f.sourceFile.readAsString(), f.sourceText);
  });

  test('ordinary error before first promotion leaves both resources unchanged',
      () async {
    var failed = false;
    final f = await _Fixture.create(
        copies: 2,
        faultInjector: (context) {
          if (!failed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.beforeResourcePromotion &&
              context.promotionIndex == 0) {
            failed = true;
            throw StateError('ordinary error before promotion');
          }
        });
    addTearDown(f.dispose);
    final bytes = await f.projectFile.readAsBytes();
    final source = f.sourceText.replaceFirst(_beforeText, _afterText);
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request(
            'dialogue.source_update',
            f.parameters('dialogue.source_update',
                source: source, edits: [_edit()])));
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId, operationId: 'ordinary-failure'),
        throwsA(isA<StateError>().having((error) => error.message, 'message',
            'ordinary error before promotion')));
    expect(failed, isTrue);
    expect(await f.projectFile.readAsBytes(), bytes);
    expect(await f.sourceFile.readAsString(), f.sourceText);
    final recovered = await f.api
        .recover(f.opened.projectHandle, operationId: 'ordinary-failure');
    expect(await f.sourceFile.readAsString(), source);
    final after = await f.loader.load(f.opened.projectHandle);
    for (var i = 0; i < f.project.scenes.length; i++) {
      expect(after.manifest.scenes[i], _replaceSceneText(f.project.scenes[i]));
    }
    final receipt = Map<String, Object?>.from(recovered['receipt']! as Map);
    await f.api.undo(f.opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'undo-ordinary-error');
    expect(await f.projectFile.readAsBytes(), bytes);
    expect(await f.sourceFile.readAsString(), f.sourceText);
  });
}

Map<String, Object?> _edit() => {
      'nodeName': 'Start',
      'lineIndex': 0,
      'beforeText': _beforeText,
      'afterText': _afterText,
    };

Matcher _domain(String code) => throwsA(isA<NarrativeAuthoringException>()
    .having((error) => error.code, 'code', code));

SceneYarnDialoguePayload _payload(SceneAsset scene) =>
    scene.graph.nodes.singleWhere((node) => node.id == 'node_1').payload
        as SceneYarnDialoguePayload;

SceneAsset _replaceSceneText(SceneAsset scene) {
  final json = jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>;
  final graph = json['graph'] as Map<String, dynamic>;
  final nodes = graph['nodes'] as List<dynamic>;
  final node = nodes
      .cast<Map<String, dynamic>>()
      .singleWhere((node) => node['id'] == 'node_1');
  final payload = node['payload'] as Map<String, dynamic>;
  final policies = payload['linePolicies'] as List<dynamic>;
  final feedback = (policies.first as Map<String, dynamic>)['feedback']
      as Map<String, dynamic>;
  ((feedback['segments'] as List<dynamic>).single
      as Map<String, dynamic>)['text'] = _afterText;
  return SceneAsset.fromJson(json);
}

final class _Fixture {
  _Fixture(this.directory, this.entry, this.sourceText, this.project,
      this.handles, this.opened, this.loader, this.api, this.readApi);
  final Directory directory;
  final ProjectDialogueEntry entry;
  final String sourceText;
  final ProjectManifest project;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  File get projectFile => File('${directory.path}/project.json');
  File get sourceFile => File('${directory.path}/${entry.relativePath}');

  static Future<_Fixture> create({
    int copies = 1,
    bool withAudio = false,
    int? inlineOffset,
    bool withEditedRichLine = false,
    bool withUneditedRichLine = false,
    bool withUneditedIconLine = false,
    bool withEmptySegments = false,
    bool withEditedIconLine = false,
    bool withoutPolicies = false,
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final native = jsonDecode(
        await File('test/fixtures/dialogue_line_text_edits/fishing_guru.json')
            .readAsString()) as Map<String, dynamic>;
    final entry =
        ProjectDialogueEntry.fromJson(native['entry'] as Map<String, dynamic>);
    var source = native['source'] as String;
    final payload = native['payload'] as Map<String, dynamic>;
    final policies = payload['linePolicies'] as List<dynamic>;
    final feedback = (policies.single as Map<String, dynamic>)['feedback']
        as Map<String, dynamic>;
    if (withAudio) {
      feedback.addAll({
        'revealIntervalMicros': 25000,
        'advance': {'kind': 'autoAfterReveal', 'delayMicros': 2000000},
        'audioCue': {
          'mediaAssetId': 'pickup',
          'cueId': 'fishing_guru',
          'volume': 0.75,
          'role': 'musicEffect',
          'bgmInterruption': {'fadeOutMs': 200, 'fadeInMs': 1000},
        },
      });
      if (inlineOffset != null) {
        feedback['audioCue'] = {
          'mediaAssetId': 'pickup', 'cueId': 'fishing_guru',
          'volume': 0.75, 'revealOffset': inlineOffset,
        };
      }
    }
    if (withEditedRichLine) {
      feedback['segments'] = [
        {'kind': 'text', 'text': 'Tell me, '},
        {
          'kind': 'text',
          'text': 'do you like to fish?',
          'style': {'colorArgb': 0xff3050c8}
        },
      ];
    }
    if (withEmptySegments) feedback['segments'] = [];
    if (withEditedIconLine) {
      source = source.replaceFirst(_beforeText, '$_beforeText\uFFFC');
      feedback['segments'] = [
        {'kind': 'text', 'text': _beforeText},
        {
          'kind': 'icon',
          'assetId': 'pickup_icon',
          'widthPx': 24,
          'heightPx': 32
        },
      ];
    }
    if (withUneditedRichLine || withUneditedIconLine) {
      source = source.replaceFirst('===',
          'Other rich line.${withUneditedIconLine ? '\uFFFC' : ''}\n===');
      policies.add({
        'nodeName': 'Start',
        'lineIndex': 1,
        'feedback': {
          'segments': [
            {
              'kind': 'text',
              'text': 'Other ',
              'style': {'colorArgb': 0xff3050c8}
            },
            {'kind': 'text', 'text': 'rich line.'},
            if (withUneditedIconLine)
              {
                'kind': 'icon',
                'assetId': 'pickup_icon',
                'widthPx': 24,
                'heightPx': 32
              },
          ],
          'advance': {'kind': 'confirm'},
        },
      });
    }
    if (withoutPolicies) policies.clear();
    final project = ProjectManifest(
      name: 'Converted fishing-guru text edit',
      maps: const [],
      tilesets: [
        if (withEditedIconLine || withUneditedIconLine)
          const ProjectTilesetEntry(
              id: 'pickup_icon', name: 'Icon', relativePath: 'assets/icon.png')
      ],
      dialogues: [entry],
      cinematicMediaAssets: [
        if (withAudio)
          CinematicMediaAsset(
              id: 'pickup',
              label: 'Pickup',
              kind: CinematicMediaAssetKind.sound,
              relativePath: 'media/pickup.ogg'),
      ],
      scenes: [
        for (var i = 0; i < copies; i++)
          SceneAsset(
            id: i == 0 ? 'ac13_fc60c94b9ed3a200f4e1d2df' : 'other_scene',
            name: 'Fishing guru $i',
            graph: SceneGraph(startNodeId: 'start', nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                  id: 'node_1',
                  kind: SceneNodeKind.yarnDialogue,
                  payload: SceneYarnDialoguePayload.fromJson(payload)),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ], edges: [
              SceneEdge(
                  id: 'entry',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'node_1',
                  kind: SceneEdgeKind.defaultFlow),
              SceneEdge(
                  id: 'completed',
                  fromNodeId: 'node_1',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.defaultFlow),
              for (final outcome in ['choice_0', 'choice_1'])
                SceneEdge(
                    id: outcome,
                    fromNodeId: 'node_1',
                    fromPortId: outcome,
                    toNodeId: 'end',
                    kind: SceneEdgeKind.dialogueOutcome),
            ]),
          ),
      ],
    );
    final directory = await Directory.systemTemp.createTemp('line_text_edits_');
    final sourceFile = File('${directory.path}/${entry.relativePath}');
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString(source);
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    if (withAudio) {
      final media = File('${directory.path}/media/pickup.ogg');
      await media.parent.create(recursive: true);
      await media.writeAsBytes([0]);
    }
    if (withEditedIconLine || withUneditedIconLine) {
      final icon = File('${directory.path}/assets/icon.png');
      await icon.parent.create(recursive: true);
      await icon.writeAsBytes(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6eZsAAAAASUVORK5CYII='));
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(directory.path);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: loader, faultInjector: faultInjector);
    await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(directory, entry, source, project, handles, opened, loader,
        api, AuthoringReadApi(openService: opener, snapshotLoader: loader));
  }

  Map<String, Object?> parameters(String action,
          {required String source, List<Map<String, Object?>>? edits}) =>
      {
        if (action == 'dialogue.update')
          'entry': entry.copyWith(name: 'Pêcheur traduit').toJson()
        else
          'dialogueId': entry.id,
        'source': source,
        if (edits != null) 'lineTextEdits': edits,
      };

  Future<AuthoringRequest> request(
          String action, Map<String, Object?> parameters) async =>
      AuthoringRequest(
        requestId: action,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: (await loader.load(opened.projectHandle)).revision,
        idempotencyKey: jsonEncode(parameters),
        parameters: parameters,
      );

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}

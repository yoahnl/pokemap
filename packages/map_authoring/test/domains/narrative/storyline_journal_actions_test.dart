import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _journal = {
  'title': {
    'fallback': 'Le rival',
    'translations': {'en': 'The rival'},
  },
  'text': {'fallback': 'Il attend au labo.'},
};
const _clue = {
  'id': 'tracks',
  'factId': 'fact_tracks',
  'text': {'fallback': 'Des traces au nord.'},
};

void main() {
  test('journal actions are described storyline trame actions', () {
    final ids = StorylineActions.descriptors.map((item) => item.id).toSet();
    expect(StorylineJournalActions.ids, {
      'storyline.milestone.set_journal',
      'storyline.clues.set',
    });
    expect(ids, containsAll(StorylineJournalActions.ids));
    expect(StorylineTrameActions.ids, containsAll(StorylineJournalActions.ids));
  });

  for (final wire in [false, true]) {
    final transport = wire ? 'JSONL' : 'direct API';
    test('$transport sets a journal and clue notes, reopens and undoes',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final initial = await f.manifest.readAsBytes();
      final set = await f.run('storyline.milestone.set_journal', wire, {
        'storylineId': 'main',
        'chapterId': 'act_1',
        'stepId': 'wake_up',
        'journal': _journal,
      });
      expect([
        for (final entry in ((set['receipt'] as Map)['diff'] as Map)['entries'])
          (entry['operation'], entry['path'])
      ], [
        ('replace', '/storylines/main'),
      ]);
      await f.run('storyline.clues.set', wire, {
        'storylineId': 'main',
        'clues': [_clue],
      });

      await f.reopen();
      var storyline =
          (await f.snapshots.load(f.project)).manifest.storylines.single;
      expect(
          storyline.chapters.single.steps.single.journal?.toJson(), _journal);
      expect(
          [for (final clue in storyline.journalClues) clue.toJson()], [_clue]);

      await f.run('storyline.milestone.set_journal', wire, {
        'storylineId': 'main',
        'chapterId': 'act_1',
        'stepId': 'wake_up',
        'journal': null,
      });
      storyline =
          (await f.snapshots.load(f.project)).manifest.storylines.single;
      expect(storyline.chapters.single.steps.single.journal, isNull);

      for (final receipt in (await f.mutations
          .history(f.project, limit: 20))['entries'] as List) {
        await f.mutations.undo(f.project,
            entryId: (receipt as Map)['entryId'] as String,
            idempotencyKey: 'undo-${receipt['entryId']}');
      }
      expect(await f.manifest.readAsBytes(), initial);
    });
  }

  test('rejections are typed and leave the project untouched', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.manifest.readAsBytes();
    final step = {'storylineId': 'main', 'chapterId': 'act_1'};
    for (final (action, parameters, code) in [
      (
        'storyline.milestone.set_journal',
        {...step, 'stepId': 'missing', 'journal': _journal},
        'stepNotFound'
      ),
      (
        'storyline.milestone.set_journal',
        {
          ...step,
          'stepId': 'wake_up',
          'journal': {
            'title': {'fallback': ' '},
            'text': {'fallback': 'x'},
          },
        },
        'storyline.journal_invalid'
      ),
      (
        'storyline.milestone.set_journal',
        {...step, 'stepId': 'wake_up'},
        'invalid_request'
      ),
      (
        'storyline.clues.set',
        {
          'storylineId': 'main',
          'clues': [
            {..._clue, 'factId': 'fact_missing'},
          ],
        },
        'journalClueFactInvalid'
      ),
      (
        'storyline.clues.set',
        {
          'storylineId': 'main',
          'clues': [
            {..._clue, 'factId': 'fact_counter'},
          ],
        },
        'must be a boolean Fact'
      ),
      (
        'storyline.clues.set',
        {
          'storylineId': 'main',
          'clues': [_clue],
          'extra': true,
        },
        'invalid_request'
      ),
    ]) {
      final result = await f.command('plan', {
        'projectHandle': f.project.value,
        'request': (await f.request(action, parameters)).toJson(),
      });
      expect(result.status, AuthoringResultStatus.failure, reason: code);
      expect(jsonEncode(result.error!.toJson()), contains(code), reason: code);
    }
    expect(await f.manifest.readAsBytes(), before);
  });

  test('a fact cited by a clue note cannot be deleted', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    await f.run('storyline.clues.set', false, {
      'storylineId': 'main',
      'clues': [_clue],
    });
    final cited = await f.manifest.readAsBytes();

    final result = await f.command('plan', {
      'projectHandle': f.project.value,
      'request':
          (await f.request('fact.delete', {'factId': 'fact_tracks'})).toJson(),
    });

    expect(result.status, AuthoringResultStatus.failure);
    expect(jsonEncode(result.error!.toJson()), contains('journalClues[0]'));
    expect(await f.manifest.readAsBytes(), cited);
  });
}

final class _Fixture {
  _Fixture(this.directory, this.snapshots, this.mutations, this.worker);

  final Directory directory;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;

  File get manifest => File('${directory.path}/project.json');

  static Future<_Fixture> create() async {
    final root = await Directory('/Users/karim/Library/Caches/AveluneQA/c6')
        .create(recursive: true);
    final directory = await root.createTemp('journal-');
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(ProjectManifest(
      name: 'Journal transport',
      tilesets: const [],
      maps: const [],
      facts: [
        NarrativeFactDefinition(id: 'fact_tracks', label: 'Traces'),
        NarrativeFactDefinition(
            id: 'fact_counter',
            label: 'Compteur',
            initialValue: NarrativeValue.integer(0)),
      ],
      storylines: [
        StorylineAsset(
          id: 'main',
          type: StorylineType.main,
          title: 'Main',
          chapters: [
            StorylineChapter(id: 'act_1', title: 'Act 1', order: 0, steps: [
              StorylineStep(id: 'wake_up', title: 'Wake up', order: 0),
            ]),
          ],
        ),
      ],
    ).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final fixture = _Fixture(directory, snapshots, mutations,
        JsonlWorker(api: api, mutations: mutations));
    await fixture.open();
    return fixture;
  }

  Future<void> open() async {
    final result = await command('open', {'projectRoot': directory.path});
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    workspace = WorkspaceHandle(result.data['workspaceHandle'] as String);
    project = ProjectHandle(result.data['projectHandle'] as String);
  }

  Future<void> reopen() async {
    await command('close', {'workspaceHandle': workspace.value});
    await open();
  }

  Future<AuthoringResult> command(
          String command, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
        'id': 'journal-${++sequence}',
        'command': command,
        'args': args,
      }))) as Map<String, dynamic>);

  Future<AuthoringRequest> request(
      String action, Map<String, Object?> parameters) async {
    final id = 'journal-request-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: parameters);
  }

  Future<Map<String, Object?>> run(
      String action, bool wire, Map<String, Object?> parameters) async {
    final planned = await request(action, parameters);
    if (!wire) {
      final plan = await mutations.plan(project, planned);
      return mutations.apply(project,
          planId: plan['planId'] as String, operationId: 'apply-$sequence');
    }
    final plan = await command(
        'plan', {'projectHandle': project.value, 'request': planned.toJson()});
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    final applied = await command('apply', {
      'projectHandle': project.value,
      'planId': plan.data['planId'],
      'operationId': 'apply-$sequence',
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    return applied.data;
  }

  Future<void> dispose() async {
    await command('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}

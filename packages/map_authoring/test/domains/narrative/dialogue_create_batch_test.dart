import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('dialogue batch advertises bounded create-only atomic semantics', () {
    final descriptor = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((entry) => entry.id == 'dialogue.create_batch');
    expect(descriptor.resourceKinds, unorderedEquals(['project', 'dialogue']));
    expect(descriptor.extensions['batch'], {
      'minDialogues': 1,
      'maxDialogues': 128,
      'maximumSourceUtf8Bytes': 524288,
      'uniqueBy': ['id', 'relativePath'],
      'semantics': 'createOnly',
      'atomic': true,
    });
    expect(descriptor.guarantees, containsAll(AuthoringGuarantee.values));
    expect((descriptor.extensions['editorWorkflow'] as Map)['applicability'],
        'notApplicable');
    expect(
        AuthoringFullParityCatalog.canonical()
            .requireMutationAction('dialogue.create_batch')
            .endToEndEvidence
            .keys,
        unorderedEquals([
          AuthoringTransport.directApi,
          AuthoringTransport.cli,
          AuthoringTransport.mcp
        ]));
  });

  for (final wire in [false, true]) {
    test(
        '${wire ? 'JSONL' : 'API'} commits, replays, cold reopens and undoes a batch',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final values = [
        _dialogue('first'),
        _dialogue('second', text: 'Évoli 🦊')
      ];
      final planned = await f.plan(values, wire: wire);
      expect(await f.manifest.readAsBytes(), before);
      final changeSet = (planned['plan'] as Map)['changeSet'] as Map;
      final changes = changeSet['changes'] as List;
      expect(changes, hasLength(3));
      expect(changes.where((v) => (v as Map)['resource']['kind'] == 'project'),
          hasLength(1));
      final applied = await f.apply(planned['planId'] as String, wire: wire);
      expect(
          (await f.apply(planned['planId'] as String, wire: wire))['receipt'],
          applied['receipt']);
      await f.reopen();
      final snapshot = await f.loader.load(f.opened.projectHandle);
      expect(snapshot.manifest.dialogues.map((v) => v.id),
          ['existing', 'first', 'second']);
      for (final value in values) {
        final entry = value['entry'] as Map;
        expect(
            await File('${f.directory.path}/${entry['relativePath']}')
                .readAsString(),
            value['source']);
      }
      await f.api.undo(f.opened.projectHandle,
          entryId: (applied['receipt'] as Map)['receiptId'] as String,
          idempotencyKey: 'undo-batch');
      expect(await f.manifest.readAsBytes(), before);
      expect(await File('${f.directory.path}/dialogues/first.yarn').exists(),
          isFalse);
      expect(await File('${f.directory.path}/dialogues/second.yarn').exists(),
          isFalse);
      expect(await f.existingSource.readAsString(), _Fixture.existingText);
    });
  }
  test(
      'batch and sequential creates retain identical models, sources and diagnostics',
      () async {
    final unit = await _Fixture.create();
    final batch = await _Fixture.create();
    addTearDown(unit.dispose);
    addTearDown(batch.dispose);
    final values = [
      _dialogue('first'),
      _dialogue('second', text: 'Salut\n-> Continuer\n  Oui')
    ];
    for (final (i, value) in values.indexed) {
      final plan =
          await unit.plan([], action: 'dialogue.create', parameters: value);
      await unit.apply(plan['planId'] as String, operation: 'single-$i');
    }
    final planned = await batch.plan(values);
    await batch.apply(planned['planId'] as String);
    final warm = await batch.loader.load(batch.opened.projectHandle);
    batch.loader.invalidate(batch.opened.projectHandle);
    final cold = await batch.loader.load(batch.opened.projectHandle);
    final single = await unit.loader.load(unit.opened.projectHandle);
    expect(cold.manifest.toJson(), single.manifest.toJson());
    expect(warm.revision, cold.revision);
    expect(warm.loadDiagnostics, cold.loadDiagnostics);
    expect(cold.loadDiagnostics, single.loadDiagnostics);
    for (final entry in cold.manifest.dialogues) {
      expect(cold.resourceBytes('dialogueSource:${entry.id}'),
          warm.resourceBytes('dialogueSource:${entry.id}'));
    }
    expect(
        await batch.manifest.readAsBytes(), await unit.manifest.readAsBytes());
    for (final value in values) {
      final entry = value['entry'] as Map;
      expect(
          await File('${batch.directory.path}/${entry['relativePath']}')
              .readAsBytes(),
          await File('${unit.directory.path}/${entry['relativePath']}')
              .readAsBytes());
    }
  });

  test(
      'malformed entries and invalid final sources refuse the entire plan without writes',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.manifest.readAsBytes();
    final valid = _dialogue('first');
    final missingNode = _dialogue('missing');
    (missingNode['entry'] as Map)['defaultStartNode'] = 'Absent';
    final cases = <List<Object?>>[
      [],
      List.generate(129, (i) => _dialogue('d_$i')),
      [valid, valid],
      [valid, _dialogue('existing', path: 'dialogues/other.yarn')],
      [valid, _dialogue('second', path: 'dialogues/first.yarn')],
      [valid, _dialogue('second', path: 'dialogues/FIRST.yarn')],
      [valid, _dialogue('second', path: 'dialogues/EXISTING.yarn')],
      [valid, _dialogue('second', path: '../escape.yarn')],
      [valid, _dialogue('second', path: 'dialogues/second.json')],
      [valid, 42],
      [valid, <String, Object?>{}],
      [
        valid,
        {..._dialogue('second'), 'extra': true}
      ],
      [
        valid,
        {..._dialogue('second'), 'source': 42}
      ],
      [
        valid,
        {..._dialogue('second'), 'source': 'invalid Yarn'}
      ],
      [
        valid,
        {..._dialogue('second'), 'source': 'title: Start\n---\n\u0000\n===\n'}
      ],
      [valid, missingNode],
      [valid, _dialogue('second', text: List.filled(131072, '🌿').join())],
    ];
    for (final values in cases) {
      await expectLater(f.plan(values), throwsA(anything),
          reason: values.length.toString());
      expect(await f.manifest.readAsBytes(), before);
      expect(await f.existingSource.readAsString(), _Fixture.existingText);
      expect(
          (await Directory('${f.directory.path}/dialogues').list().toList())
              .length,
          1);
    }
  });

  test('batch retains unit compilation refusal diagnostics for an invalid tail',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final invalid = {..._dialogue('bad'), 'source': 'invalid Yarn'};
    Future<NarrativeAuthoringException> refusal(
        Future<Object?> Function() invoke) async {
      try {
        await invoke();
      } on NarrativeAuthoringException catch (error) {
        return error;
      }
      throw StateError('Expected a narrative refusal');
    }

    final unit = await refusal(
        () => f.plan([], action: 'dialogue.create', parameters: invalid));
    final batch = await refusal(() => f.plan([_dialogue('first'), invalid]));
    expect(batch.code, unit.code);
    expect(batch.message, unit.message);
    expect(batch.details, unit.details);
  });

  test('existing identity refusal and UTF-8 bounds are exact before writes',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.manifest.readAsBytes();
    await expectLater(
        f.plan([_dialogue('existing')]),
        throwsA(isA<NarrativeAuthoringException>()
            .having((e) => e.code, 'code', 'dialogue.id_conflict')));
    await expectLater(
        f.plan([_dialogue('huge', text: List.filled(262144, 'é').join())]),
        throwsA(isA<NarrativeAuthoringException>()
            .having((e) => e.code, 'code', 'dialogue.batch_source_limit')));
    expect(await f.manifest.readAsBytes(), before);
  });

  test(
      '128 dialogues actually publish and cold reopen as one recoverable transaction',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final values = List.generate(128, (i) => _dialogue('max_$i'));
    final plan = await f.plan(values);
    final applied = await f.apply(plan['planId'] as String);
    expect((applied['receipt'] as Map)['actionId'], 'dialogue.create_batch');
    await f.reopen();
    final snapshot = await f.loader.load(f.opened.projectHandle);
    expect(snapshot.manifest.dialogues, hasLength(129));
    for (final value in values) {
      final entry = value['entry'] as Map;
      expect(
          await File('${f.directory.path}/${entry['relativePath']}')
              .readAsString(),
          value['source']);
    }
  });

  test(
      '128 creates use one manifest write and dry-run or stale plans cannot publish',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.manifest.readAsBytes();
    final maximum =
        await f.plan(List.generate(128, (i) => _dialogue('max_$i')));
    expect(((maximum['plan'] as Map)['changeSet'] as Map)['changes'],
        hasLength(129));
    final preview = await f.plan([_dialogue('dry')], dryRun: true);
    expect(preview['applicable'], isFalse);
    await expectLater(f.apply(preview['planId'] as String, operation: 'dry'),
        throwsA(anything));
    expect(await f.manifest.readAsBytes(), before);
    final stale = await f.plan([_dialogue('stale')]);
    final current = await f.plan([_dialogue('first')]);
    await f.apply(current['planId'] as String);
    final saved = await f.manifest.readAsBytes();
    await expectLater(f.apply(stale['planId'] as String, operation: 'stale'),
        throwsA(anything));
    expect(await f.manifest.readAsBytes(), saved);
  });

  test('an occupied unowned source cannot be overwritten', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final occupied = File('${f.directory.path}/dialogues/occupied.yarn');
    await occupied.writeAsString('External bytes');
    final before = await f.manifest.readAsBytes();
    await expectLater(() async {
      final plan = await f.plan([_dialogue('first'), _dialogue('occupied')]);
      await f.apply(plan['planId'] as String);
    }, throwsA(anything));
    expect(await occupied.readAsString(), 'External bytes');
    expect(await f.manifest.readAsBytes(), before);
    expect(await File('${f.directory.path}/dialogues/first.yarn').exists(),
        isFalse);
  });

  for (final boundary in [0, 1]) {
    test(
        'recovery after promotion $boundary preserves the whole batch and undo',
        () async {
      var crashed = false;
      final f = await _Fixture.create(faultInjector: (context) {
        if (!crashed &&
            context.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted &&
            context.promotionIndex == boundary) {
          crashed = true;
          throw const AuthoringTransactionSimulatedCrash();
        }
      });
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final plan = await f.plan([_dialogue('first'), _dialogue('second')]);
      await expectLater(f.apply(plan['planId'] as String),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      final recovered = await f.api
          .recover(f.opened.projectHandle, operationId: 'batch-apply');
      await f.reopen();
      expect(
          (await f.loader.load(f.opened.projectHandle))
              .manifest
              .dialogues
              .map((v) => v.id),
          ['existing', 'first', 'second']);
      expect(
          await File('${f.directory.path}/dialogues/first.yarn').readAsString(),
          _dialogue('first')['source']);
      expect(
          await File('${f.directory.path}/dialogues/second.yarn')
              .readAsString(),
          _dialogue('second')['source']);
      await f.api.undo(f.opened.projectHandle,
          entryId: (recovered['receipt'] as Map)['receiptId'] as String,
          idempotencyKey: 'undo-recovered');
      expect(await f.manifest.readAsBytes(), before);
      expect(await File('${f.directory.path}/dialogues/first.yarn').exists(),
          isFalse);
      expect(await File('${f.directory.path}/dialogues/second.yarn').exists(),
          isFalse);
    });
  }
}

Map<String, Object?> _dialogue(String id,
        {String? path, String text = 'Bonjour'}) =>
    {
      'entry': ProjectDialogueEntry(
              id: id,
              name: id,
              relativePath: path ?? 'dialogues/$id.yarn',
              defaultStartNode: 'Start')
          .toJson(),
      'source': 'title: Start\n---\n$text\n===\n',
    };

final class _Fixture {
  _Fixture(this.directory, this.handles, this.opener, this.opened, this.loader,
      this.api, this.readApi);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final ProjectOpenService opener;
  OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  int sequence = 0;
  File get manifest => File('${directory.path}/project.json');
  File get existingSource => File('${directory.path}/dialogues/existing.yarn');
  static const existingText = 'title: Start\n---\nExistant\n===\n';

  static Future<_Fixture> create(
      {AuthoringTransactionFaultInjector? faultInjector}) async {
    final directory = await Directory.systemTemp.createTemp('dialogue_batch_');
    await Directory('${directory.path}/dialogues').create();
    await File('${directory.path}/dialogues/existing.yarn')
        .writeAsString(existingText);
    await File('${directory.path}/project.json').writeAsString(jsonEncode(
        const ProjectManifest(
            name: 'Dialogue batch',
            maps: [],
            tilesets: [],
            dialogues: [
          ProjectDialogueEntry(
              id: 'existing',
              name: 'Existant',
              relativePath: 'dialogues/existing.yarn',
              defaultStartNode: 'Start')
        ]).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(directory.path);
    final loader = ProjectSnapshotLoader(
        handles: handles, snapshotCache: ProjectSnapshotCache());
    final api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: loader, faultInjector: faultInjector);
    await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(directory, handles, opener, opened, loader, api,
        AuthoringReadApi(openService: opener, snapshotLoader: loader));
  }

  Future<Map<String, Object?>> command(
      String name, Map<String, Object?> args) async {
    final worker = JsonlWorker(api: readApi, mutations: api);
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
        jsonEncode({
      'id': 'command-${++sequence}',
      'command': name,
      'args': args
    }))) as Map<String, dynamic>);
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    return result.data;
  }

  Future<Map<String, Object?>> plan(List<Object?> values,
      {bool wire = false,
      String action = 'dialogue.create_batch',
      Map<String, Object?>? parameters,
      bool dryRun = false}) async {
    final request = AuthoringRequest(
        requestId: 'request-${++sequence}',
        actionId: action,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: (await loader.load(opened.projectHandle)).revision,
        idempotencyKey: 'key-$sequence',
        dryRun: dryRun,
        parameters: parameters ?? {'dialogues': values});
    return wire
        ? command('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          })
        : (await api.planMutation(opened.projectHandle, request)).toJson();
  }

  Future<Map<String, Object?>> apply(String id,
          {bool wire = false, String operation = 'batch-apply'}) =>
      wire
          ? command('apply', {
              'projectHandle': opened.projectHandle.value,
              'planId': id,
              'operationId': operation
            })
          : api.apply(opened.projectHandle, planId: id, operationId: operation);

  Future<void> reopen() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    opened = await opener.openProject(directory.path);
    await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}

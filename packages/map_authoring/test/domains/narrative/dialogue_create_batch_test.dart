import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/support/authoring_performance_observer.dart';
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

  for (final unrelated in [0, 120]) {
    for (final wire in [false, true]) {
      for (final action in ['dialogue.create', 'dialogue.create_batch']) {
        test(
            'working catalog $action ${wire ? 'JSONL' : 'API'} stays local with $unrelated foreign documents',
            () async {
          final f = await _Fixture.create(catalog: true, unrelated: unrelated);
          addTearDown(f.dispose);
          final foreign = await f.foreignBytes();
          for (final round in [0, 1]) {
            final value = _dialogue('local-$round',
                text:
                    'Score {{ fact.score }}\n-> Choisir {{ fact.label }}\n  Oui');
            (value['entry'] as Map)['folderId'] = 'child';
            final parameters = action == 'dialogue.create'
                ? value
                : {
                    'dialogues': [value]
                  };
            f.reader.paths.clear();
            f.observer.counters.clear();
            final timer = Stopwatch()..start();
            final selected = await f.api.readWorkshopSnapshot(
                f.opened.projectHandle,
                actionId: action,
                parameters: parameters);
            expect(selected.manifest.trainers, isEmpty);
            expect(selected.manifest.scenes, isEmpty);
            expect(selected.manifest.maps, isEmpty);
            expect(selected.manifest.facts.map((entry) => entry.id),
                ['score', 'label']);
            expect(selected.manifest.dialogueFolders.map((entry) => entry.id),
                ['parent', 'child']);
            final planned = await f
                .plan([], action: action, parameters: parameters, wire: wire);
            final applied = await f.apply(planned['planId'] as String,
                wire: wire, operation: 'local-$round');
            final elapsed = timer.elapsedMicroseconds;
            expect(f.reader.paths.where(f.foreignPaths.contains), isEmpty);
            expect(f.reader.paths.where((path) => path.startsWith('maps/')),
                isEmpty);
            expect(f.reader.paths.length, lessThan(250));
            print(jsonEncode({
              'action': action,
              'wire': wire,
              'foreignDocumentsPerKind': unrelated,
              'round': round,
              'readCalls': f.reader.paths.length,
              'readObjectDecodes': f.reader.paths
                  .where((path) => path.startsWith('catalog/objects/'))
                  .length,
              'gatewayCounters': f.observer.counters,
              'planAndDurableApplyMicros': elapsed
            }));
            expect(await f.foreignBytes(), foreign);
            await f.reopen();
            await expectLater(
                f.plan([], action: action, parameters: parameters),
                throwsA(isA<NarrativeAuthoringException>().having(
                    (error) => error.code, 'code', 'dialogue.id_conflict')));
            await f.api.undo(f.opened.projectHandle,
                entryId: (applied['receipt'] as Map)['receiptId'] as String,
                idempotencyKey: 'undo-local-$round');
            expect(
                await File('${f.directory.path}/dialogues/local-$round.yarn')
                    .exists(),
                isFalse);
            expect(await f.foreignBytes(), foreign);
          }
        });
      }
    }
  }

  for (final action in ['dialogue.create', 'dialogue.create_batch']) {
    for (final wire in [false, true]) {
      for (final missingSource in [false, true]) {
        test('working catalog $action ${wire ? 'JSONL' : 'API'} refuses case-folded owned paths with missingSource=$missingSource', () async {
          final f = await _Fixture.create(catalog: true);
          addTearDown(f.dispose);
          if (missingSource) {
            await f.existingSource.delete();
          }
          final head = File('${f.directory.path}/catalog/HEAD.json');
          final before = await head.readAsBytes();
          for (final id in ['new-id', 'existing']) {
            final value = _dialogue(id, path: 'dialogues/EXISTING.yarn');
            final code = id == 'existing' ? 'dialogue.id_conflict' : 'dialogue.path_conflict';
            await expectLater(f.plan([], action: action, wire: wire,
                parameters: action == 'dialogue.create' ? value : {'dialogues': [value]}),
                throwsA(wire
                    ? isA<AuthoringError>().having((error) => error.details['domainCode'], 'domainCode', code)
                    : isA<NarrativeAuthoringException>().having((error) => error.code, 'code', code)));
            expect(await head.readAsBytes(), before);
            expect(await f.existingSource.exists(), !missingSource);
            if (!missingSource) {
              expect(await f.existingSource.readAsString(), _Fixture.existingText);
            }
          }
        });
      }
    }
  }

  for (final action in ['dialogue.create', 'dialogue.create_batch']) {
    for (final wire in [false, true]) {
      test('working catalog $action ${wire ? 'JSONL' : 'API'} rejects case-folded map-owned paths', () async {
        final f = await _Fixture.create(catalog: true, mapOwnedPath: 'dialogues/Map-owned.yarn');
        addTearDown(f.dispose);
        final head = File('${f.directory.path}/catalog/HEAD.json');
        final before = await head.readAsBytes();
        for (final id in ['new-id', 'existing']) {
          final value = _dialogue(id, path: 'dialogues/map-owned.yarn');
          final code = id == 'existing' ? 'dialogue.id_conflict' : 'dialogue.path_conflict';
          await expectLater(f.plan([], action: action, wire: wire,
              parameters: action == 'dialogue.create' ? value : {'dialogues': [value]}),
              throwsA(wire
                  ? isA<AuthoringError>().having((error) => error.details['domainCode'], 'domainCode', code)
                  : isA<NarrativeAuthoringException>().having((error) => error.code, 'code', code)));
          expect(await head.readAsBytes(), before);
          expect(await File('${f.directory.path}/dialogues/Map-owned.yarn').exists(), isFalse);
        }
      });
    }
  }

  test('working catalog create remains bounded after unrelated retained history', () async {
    final f = await _Fixture.create(catalog: true, unrelated: 20);
    addTearDown(f.dispose);
    for (var i = 0; i < 8; i++) {
      final plan = await f.plan([_dialogue('history-$i')]);
      final applied = await f.apply(plan['planId'] as String, operation: 'history-$i');
      await f.api.undo(f.opened.projectHandle,
          entryId: (applied['receipt'] as Map)['receiptId'] as String,
          idempotencyKey: 'undo-history-$i');
    }
    await f.reopen();
    f.reader.paths.clear();
    f.observer.counters.clear();
    final plan = await f.plan([_dialogue('after-history')]);
    await f.apply(plan['planId'] as String, operation: 'after-history');
    expect(f.reader.paths.where(f.foreignPaths.contains), isEmpty);
    expect(f.reader.paths.length, lessThan(250));
    expect(f.observer.counters['filesystem.write'], lessThan(65));
    expect(f.observer.counters['json.decode'], lessThan(100));
    print(jsonEncode({'retainedForeignOperations': 16, 'readCalls': f.reader.paths.length,
      'gatewayCounters': f.observer.counters}));
  });

  for (final boundary in [0, 1]) {
    test('working catalog recovery after promotion $boundary retains the atomic batch', () async {
      var crashed = false;
      final f = await _Fixture.create(catalog: true, faultInjector: (context) {
        if (!crashed && context.checkpoint == AuthoringTransactionCheckpoint.afterResourcePromoted && context.promotionIndex == boundary) {
          crashed = true;
          throw const AuthoringTransactionSimulatedCrash();
        }
      });
      addTearDown(f.dispose);
      final foreign = await f.foreignBytes();
      final values = [_dialogue('first'), _dialogue('second')];
      final plan = await f.plan(values);
      await expectLater(f.apply(plan['planId'] as String), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      final recovered = await f.api.recover(f.opened.projectHandle, operationId: 'batch-apply');
      await f.reopen();
      final selected = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
          actionId: 'dialogue.create_batch', parameters: {'dialogues': values});
      expect(selected.manifest.dialogues.map((entry) => entry.id), ['first', 'second']);
      expect(await f.foreignBytes(), foreign);
      await f.api.undo(f.opened.projectHandle,
          entryId: (recovered['receipt'] as Map)['receiptId'] as String,
          idempotencyKey: 'undo-recovered');
      expect(await File('${f.directory.path}/dialogues/first.yarn').exists(), isFalse);
      expect(await File('${f.directory.path}/dialogues/second.yarn').exists(), isFalse);
      expect(await f.foreignBytes(), foreign);
    });
  }

  test(
      'working catalog refuses foreign path ownership, dangling Facts and occupied sources',
      () async {
    final f = await _Fixture.create(catalog: true);
    addTearDown(f.dispose);
    final foreign = await f.foreignBytes();
    for (final value in [
      _dialogue('first', path: 'dialogues/EXISTING.yarn'),
      _dialogue('first', text: '{{ fact.missing }}'),
    ]) {
      await expectLater(
          f.plan([value]), throwsA(isA<NarrativeAuthoringException>()));
      expect(await f.foreignBytes(), foreign);
    }
    final occupied = File('${f.directory.path}/dialogues/occupied.yarn');
    await occupied.writeAsString('External bytes');
    await expectLater(() async {
      final plan = await f.plan([_dialogue('first'), _dialogue('occupied')]);
      await f.apply(plan['planId'] as String);
    }, throwsA(anything));
    expect(await occupied.readAsString(), 'External bytes');
    expect(await File('${f.directory.path}/dialogues/first.yarn').exists(),
        isFalse);
    expect(await f.foreignBytes(), foreign);
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
      this.api, this.readApi, this.reader, this.observer, this.foreignPaths);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final ProjectOpenService opener;
  OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  final _CountingReader reader;
  final _Observer observer;
  final Set<String> foreignPaths;
  int sequence = 0;
  File get manifest => File('${directory.path}/project.json');
  File get existingSource => File('${directory.path}/dialogues/existing.yarn');
  static const existingText = 'title: Start\n---\nExistant\n===\n';

  static Future<_Fixture> create(
      {AuthoringTransactionFaultInjector? faultInjector,
      bool catalog = false,
      int unrelated = 0, String? mapOwnedPath}) async {
    final qaRoot = Directory(
        '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/dialogue-scope');
    await qaRoot.create(recursive: true);
    final directory = await qaRoot.createTemp('dialogue-batch-');
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
    final foreignPaths = <String>{};
    if (catalog) {
      final project = ProjectManifest.fromJson(jsonDecode(
              await File('${directory.path}/project.json').readAsString())
          as Map<String, dynamic>);
      await File('${directory.path}/project.json').delete();
      final store = await CatalogStorageStore.open(projectRoot: directory.path);
      final working = await WorkingProjectCatalog.create(
          store: store,
          projectId: 'dialogues',
          project: project.copyWith(
            tilesets: [
              ProjectTilesetEntry(
                  id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
            ],
            settings: const ProjectSettings(defaultPlayerCharacterId: 'silver'),
            maps: [if (mapOwnedPath != null) ProjectMapEntry(id: 'map-owner', name: 'Map owner', relativePath: mapOwnedPath)],
            facts: [
              NarrativeFactDefinition(
                  id: 'score',
                  label: 'Score',
                  initialValue: NarrativeValue.integer(3)),
              NarrativeFactDefinition(
                  id: 'label',
                  label: 'Label',
                  initialValue: NarrativeValue.string('Oran'))
            ],
            dialogueFolders: [
              ProjectDialogueFolder(id: 'parent', name: 'Parent'),
              ProjectDialogueFolder(
                  id: 'child', name: 'Child', parentFolderId: 'parent')
            ],
            dialogues: [
              ...project.dialogues,
              for (var i = 0; i < unrelated; i++)
                ProjectDialogueEntry(
                    id: 'foreign-$i',
                    name: 'Foreign',
                    relativePath: 'dialogues/foreign-$i.yarn')
            ],
            scenes: [
              for (var i = 0; i < unrelated; i++)
                SceneAsset(
                    id: 'foreign-$i',
                    name: 'Foreign',
                    graph: SceneGraph(startNodeId: 'start', nodes: [
                      SceneNode(id: 'start', kind: SceneNodeKind.start)
                    ]))
            ],
            characters: [
              ProjectCharacterEntry(
                  id: 'silver', name: 'Silver', tilesetId: 'tiles')
            ],
            trainers: [
              for (var i = 0; i <= unrelated; i++)
                ProjectTrainerEntry.fromJson({
                  'id': 'rival-$i',
                  'name': 'Rival',
                  'trainerClass': 'rival',
                  'characterId': 'silver',
                  'team': []
                })
            ],
          ));
      for (final field in ['trainers', 'scenes', 'dialogues']) {
        final count = field == 'trainers'
            ? unrelated + 1
            : field == 'dialogues'
                ? unrelated + 1
                : unrelated;
        for (var position = 0; position < count; position++) {
          final entry = (await working.catalog.snapshot.indexEntry(
              CatalogMetadataDocuments.definitionKey(field, position)))!;
          foreignPaths.add('catalog/objects/${entry.reference.sha256}.json');
        }
      }
      for (var i = 0; i < unrelated; i++) {
        await File('${directory.path}/dialogues/foreign-$i.yarn')
            .writeAsString(existingText);
      }
      ProjectValidator.validate(working.catalog.projectMetadata.copyWith(
        characters: [
          ProjectCharacterEntry(
              id: 'silver', name: 'Silver', tilesetId: 'tiles')
        ],
        tilesets: [
          ProjectTilesetEntry(
              id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
        ],
      ));
    }
    final reader = _CountingReader();
    final observer = _Observer();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: catalog ? {} : null);
    final opened = await opener.openProject(directory.path);
    final loader = ProjectSnapshotLoader(
        handles: handles, snapshotCache: ProjectSnapshotCache());
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        faultInjector: faultInjector,
        catalogFileReader: reader,
        performanceObserver: observer);
    await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(
        directory,
        handles,
        opener,
        opened,
        loader,
        api,
        AuthoringReadApi(openService: opener, snapshotLoader: loader),
        reader,
        observer,
        foreignPaths);
  }

  Future<Map<String, List<int>>> foreignBytes() async => {
        for (final path in foreignPaths)
          path: await File('${directory.path}/$path').readAsBytes(),
        'existingSource': await existingSource.readAsBytes(),
      };

  Future<Map<String, Object?>> command(
      String name, Map<String, Object?> args) async {
    final worker = JsonlWorker(api: readApi, mutations: api);
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
        jsonEncode({
      'id': 'command-${++sequence}',
      'command': name,
      'args': args
    }))) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw result.error!;
    }
    return result.data;
  }

  Future<Map<String, Object?>> plan(List<Object?> values,
      {bool wire = false,
      String action = 'dialogue.create_batch',
      Map<String, Object?>? parameters,
      bool dryRun = false}) async {
    final String revision;
    if (api.isCatalogProject(opened.projectHandle) && wire) {
      final selected = await command('workshop_snapshot', {
        'projectHandle': opened.projectHandle.value,
        'actionId': action,
        'parameters': parameters ?? {'dialogues': values},
      });
      revision = selected['snapshotRevision'] as String;
    } else {
      final selected = api.isCatalogProject(opened.projectHandle)
          ? await api.readWorkshopSnapshot(opened.projectHandle, actionId: action, parameters: parameters ?? {'dialogues': values})
          : await loader.load(opened.projectHandle);
      revision = selected.revision;
    }
    final request = AuthoringRequest(
        requestId: 'request-${++sequence}',
        actionId: action,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: revision,
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

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}

final class _Observer implements AuthoringPerformanceObserver {
  final counters = <String, int>{};
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
  @override
  void incrementCounter(String name, {int by = 1}) =>
      counters.update(name, (value) => value + by, ifAbsent: () => by);
}

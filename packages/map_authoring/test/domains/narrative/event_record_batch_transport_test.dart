import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _id = 'evt_019abcde-0000-7000-8000-000000000001';
Map<String, Object?> _source(String kind,
        [String triggerId = 'owner', String mapId = 'map']) =>
    {'kind': kind, 'mapId': mapId, 'triggerId': triggerId};
Map<String, Object?> _record(Map<String, Object?> source) => {
      'state': 'configured',
      'enabled': false,
      'definition': {
        'id': _id,
        'name': 'Contact owner',
        'source': source,
        'conditions': <Object?>[],
        'sceneId': 'hello',
        'reusePolicy': 'reusable',
        'priority': 0,
        'order': 0,
      },
    };

Map<String, dynamic> _sharedFixture() => jsonDecode(
      File('test/fixtures/event_v2_transport_parity.json').readAsStringSync(),
    ) as Map<String, dynamic>;

Future<void> _verifySharedContract(bool wire) async {
  final data = _sharedFixture();
  var f = await _Fixture.createShared(data);
  addTearDown(() => f.dispose());
  final initial =
      ProjectManifest.fromJson(data['project'] as Map<String, dynamic>);
  final protectedMap = await f.map.readAsBytes();
  var sequence = 0;
  Future<Map<String, Object?>> call(
      String command, Map<String, Object?> args) async {
    if (wire) {
      final result =
          await f.command(command, {'projectHandle': f.project.value, ...args});
      expect(result.status, AuthoringResultStatus.success,
          reason: jsonEncode(result.toJson()));
      return result.data;
    }
    return switch (command) {
      'plan' => f.mutations.plan(
          f.project,
          AuthoringRequest.fromJson(
              Map<String, dynamic>.from(args['request'] as Map))),
      'apply' => f.mutations.apply(f.project,
          planId: args['planId'] as String,
          operationId: args['operationId'] as String,
          confirmationToken: args['confirmationToken'] as String?),
      'confirm' =>
        f.mutations.confirm(f.project, planId: args['planId'] as String),
      'history' => f.mutations.history(f.project, limit: 1),
      'undo' => f.mutations.undo(f.project,
          entryId: args['entryId'] as String,
          idempotencyKey: args['idempotencyKey'] as String),
      'query' => f.api.query(
          f.project,
          AuthoringQueryRequest.fromJson(
              Map<String, dynamic>.from(args['request'] as Map))),
      _ => throw StateError(command),
    };
  }

  Future<void> refuses(
      String command, Map<String, Object?> args, String code) async {
    if (wire) {
      final result =
          await f.command(command, {'projectHandle': f.project.value, ...args});
      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error!.code, isNot(AuthoringErrorCode.internal));
      expect(result.error!.details['domainCode'], code);
    } else {
      Object? failure;
      try {
        await call(command, args);
      } on Object catch (error) {
        failure = error;
      }
      expect(failure, isNotNull, reason: code);
      expect((failure as dynamic).code, code);
    }
  }

  Future<Map<String, Object?>> plan(Map operation) async => call('plan', {
        'request': (await f.request(operation['actionId'] as String,
                Map<String, Object?>.from(operation['parameters'] as Map)))
            .toJson(),
      });
  Future<void> verify(Map registry) async {
    final current = ProjectManifest.fromJson(
        jsonDecode(await f.manifest.readAsString()) as Map<String, dynamic>);
    expect(current.eventRegistry!.toJson(), registry);
    expect(current.copyWith(eventRegistry: initial.eventRegistry), initial);
    expect(await f.map.readAsBytes(), protectedMap);
    final result = await call('query', {
      'request': AuthoringQueryRequest(
              resourceKind: 'eventV2',
              operation: AuthoringQueryOperation.list,
              view: AuthoringQueryView.detail)
          .toJson(),
    });
    final queried = {
      for (final raw in (result['items'] as List).cast<Map>())
        raw['id']: {
          'state': raw['state'],
          if (raw['state'] == 'draft')
            'draft': raw['draft']
          else ...{
            'definition': raw['definition'],
            'enabled': raw['enabled'],
            if (raw.containsKey('activeInLegacyMode'))
              'activeInLegacyMode': raw['activeInLegacyMode'],
          },
        },
    };
    expect(queried, {
      for (final raw in (registry['records'] as List).cast<Map>())
        ((raw['definition'] ?? raw['draft']) as Map)['id']: raw,
    });
  }

  Future<void> refusals(String after) async {
    for (final invalid in (data['refusals'] as List)
        .cast<Map>()
        .where((entry) => entry['afterOperation'] == after)) {
      final before = await f.manifest.readAsBytes();
      final request = await f.request(invalid['actionId'] as String,
          Map<String, Object?>.from(invalid['parameters'] as Map));
      await refuses('plan', {'request': request.toJson()},
          invalid['domainCode'] as String);
      expect(await f.manifest.readAsBytes(), before,
          reason: invalid['id'] as String);
      expect(await f.map.readAsBytes(), protectedMap);
    }
  }

  final beforeBound = await f.manifest.readAsBytes();
  final accepted = await plan({
    'actionId': 'event_v2.record_upsert_batch',
    'parameters': {'records': data['acceptedBatch']},
  });
  expect((((accepted['plan'] as Map)['preview'] as Map)['recordIds'] as List),
      hasLength(128));
  expect(await f.manifest.readAsBytes(), beforeBound);
  await refusals('initial');
  for (final operation in (data['operations'] as List).cast<Map>()) {
    final before = await f.manifest.readAsBytes();
    final beforeRegistry =
        (jsonDecode(utf8.decode(before)) as Map)['eventRegistry'] as Map;
    final planned = await plan(operation);
    expect(await f.manifest.readAsBytes(), before);
    final stale = operation['id'] == 'batch' ? await plan(operation) : null;
    final args = <String, Object?>{
      'planId': planned['planId'],
      'operationId': 'shared-${sequence++}',
    };
    if (operation['confirmation'] == true) {
      await refuses(
          'apply',
          {...args, 'operationId': 'unconfirmed-${sequence++}'},
          data['confirmationDomainCode'] as String);
      expect(await f.manifest.readAsBytes(), before);
      args['confirmationToken'] = (await call(
          'confirm', {'planId': planned['planId']}))['confirmationToken'];
    }
    final applied = await call('apply', args);
    final committed = await f.manifest.readAsBytes();
    expect((await call('apply', args))['receipt'], applied['receipt']);
    expect(await f.manifest.readAsBytes(), committed);
    await verify(operation['expectedRegistry'] as Map);
    if (stale != null) {
      await refuses(
          'apply',
          {'planId': stale['planId'], 'operationId': 'stale-${sequence++}'},
          data['staleDomainCode'] as String);
      expect(await f.manifest.readAsBytes(), committed);
    }
    if (operation['id'] == 'batch' || operation['id'] == 'delete') {
      final history = await call('history', {'limit': 1});
      final entry = ((history['entries'] as List).first as Map);
      expect((entry['receipt'] as Map)['actionId'], operation['actionId']);
      await call('undo', {
        'entryId': entry['entryId'],
        'idempotencyKey': 'undo-${sequence++}'
      });
      expect(await f.manifest.readAsBytes(), before);
      await verify(beforeRegistry);
      final restored = await plan(operation);
      await call('apply', {
        'planId': restored['planId'],
        'operationId': 'restored-${sequence++}',
        if (operation['confirmation'] == true)
          'confirmationToken': (await call(
              'confirm', {'planId': restored['planId']}))['confirmationToken'],
      });
      await verify(operation['expectedRegistry'] as Map);
    }
    await refusals(operation['id'] as String);
  }
  final expected =
      ((data['operations'] as List).last as Map)['expectedRegistry'] as Map;
  final directory = f.directory;
  await f.worker.close();
  f = await _Fixture.openDirectory(directory,
      mapRelativePath: 'maps/port.json');
  await verify(expected);
}

void main() {
  test('the nine Event V2 actions declare their exact transport proofs', () {
    final data = _sharedFixture();
    final catalog = AuthoringFullParityCatalog.canonical();
    final ids = (data['expectedActionIds'] as List).cast<String>();
    expect(EventV2Actions.descriptors.map((action) => action.id).toSet(),
        ids.toSet());
    for (final id in ids) {
      final action = catalog.mutationActions
          .singleWhere((action) => action.actionId == id);
      expect(
          action.endToEndEvidence,
          {
            AuthoringTransport.directApi:
                'test/domains/narrative/event_record_batch_transport_test.dart',
            AuthoringTransport.cli:
                'test/domains/narrative/event_record_batch_transport_test.dart',
            AuthoringTransport.editor:
                '../map_editor/test/authoring_api/event_v2_transport_parity_test.dart',
            AuthoringTransport.mcp:
                '../../tools/pokemap_mcp/test/event_v2_transport_parity_stdio.test.ts',
          },
          reason: id);
    }
  });
  for (final wire in [false, true]) {
    test(
        '${wire ? 'JSONL' : 'direct API'} executes the shared nine-action Event V2 contract',
        () => _verifySharedContract(wire));
  }
  for (final wire in [false, true]) {
    final label = wire ? 'JSONL' : 'direct API';
    test('$label applies ordered Event V2 records atomically and reopens',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final configured = _batchRecord(3)['definition'] as Map<String, dynamic>;
      final records = [
        {..._batchRecord(2), 'enabled': true},
        _batchRecord(1),
        {
          'state': 'draft',
          'draft': {...configured}..remove('reusePolicy')
        },
      ];
      final request =
          await f.request('event_v2.record_upsert_batch', {'records': records});
      final before = await f.manifest.readAsBytes();
      final planned = await f.plan(request, wire);
      expect(await f.manifest.readAsBytes(), before);
      Future<Map<String, Object?>> apply() async {
        if (!wire) {
          return f.mutations.apply(f.project,
              planId: planned['planId'] as String, operationId: 'batch-apply');
        }
        final result = await f.command('apply', {
          'projectHandle': f.project.value,
          'planId': planned['planId'],
          'operationId': 'batch-apply',
        });
        expect(result.status, AuthoringResultStatus.success);
        return result.data;
      }

      final applied = await apply();
      final appliedBytes = await f.manifest.readAsBytes();
      final repeated = await apply();
      expect(repeated['receipt'], applied['receipt']);
      expect((applied['receipt'] as Map)['status'], 'applied');
      expect(await f.manifest.readAsBytes(), appliedBytes);
      await f.reopen();
      final saved = (await f.snapshots.load(f.project)).manifest.eventRegistry!;
      expect(saved.records.map((r) => r.id),
          [_batchRecordId(1), _batchRecordId(2), _batchRecordId(3)]);
      final legacy = records.fold<ProjectManifest>(
          ProjectManifest.fromJson(
              jsonDecode(utf8.decode(before)) as Map<String, dynamic>),
          (project, record) => const EventV2Actions().upsertRecord(project,
              maps: [
                MapData.fromJson(jsonDecode(utf8.decode(f.mapBefore))
                    as Map<String, dynamic>)
              ],
              record: NarrativeEventRecord.fromJson(record)));
      expect(utf8.encode(jsonEncode(saved.toJson())),
          utf8.encode(jsonEncode(legacy.eventRegistry!.toJson())));
      expect(await f.map.readAsBytes(), f.mapBefore);
    });
    test('$label refuses invalid batch members without partial writes',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      for (final records in <Object?>[
        [],
        List.generate(129, (i) => _batchRecord(i + 1)),
        [_batchRecord(2), _batchRecord(2)],
        [
          _batchRecord(2),
          {'state': 'configured', 'definition': {}}
        ],
        [_batchRecord(2), _batchRecord(3, scene: 'missing')],
        [
          _batchRecord(2),
          _batchRecord(3, source: _source('triggerBump', 'missing'))
        ],
        [
          _batchRecord(2),
          {
            'state': 'draft',
            'draft': {
              'id': _batchRecordId(3),
              'name': 'Invalid contact',
              'source': _source('triggerBump', 'missing'),
              'conditions': [],
              'priority': 0,
              'order': 0
            }
          }
        ],
      ]) {
        final request = await f
            .request('event_v2.record_upsert_batch', {'records': records});
        if (wire) {
          final result = await f.command('plan',
              {'projectHandle': f.project.value, 'request': request.toJson()});
          expect(result.status, AuthoringResultStatus.failure);
          expect(result.error!.details['domainCode'], startsWith('event_v2.'));
        } else {
          await expectLater(f.mutations.plan(f.project, request),
              throwsA(isA<NarrativeAuthoringException>()));
        }
        expect(await f.manifest.readAsBytes(), before);
        expect(await f.map.readAsBytes(), f.mapBefore);
      }
    });
    test('$label accepts the 128 record bound and rejects stale revision',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final request = await f.request('event_v2.record_upsert_batch',
          {'records': List.generate(128, (i) => _batchRecord(i + 1))});
      final planned = await f.plan(request, wire);
      final stale = await f.plan(
          await f.request('event_v2.record_upsert_batch', {
            'records': [_batchRecord(129)]
          }),
          wire);
      await f.apply(planned['planId'] as String, wire);
      await expectLater(
          f.mutations.apply(f.project,
              planId: stale['planId'] as String, operationId: 'stale-batch'),
          throwsA(anything));
      expect(
          (await f.snapshots.load(f.project))
              .manifest
              .eventRegistry!
              .records
              .length,
          128);
    });
  }
}

String _batchRecordId(int index) =>
    'evt_019abcde-0000-7000-8000-${index.toString().padLeft(12, '0')}';
Map<String, dynamic> _batchRecord(int index,
        {String scene = 'hello', Map<String, Object?>? source}) =>
    {
      'state': 'configured',
      'enabled': false,
      'definition': {
        'id': _batchRecordId(index),
        'name': 'Batch $index',
        'source': source ?? {'kind': 'mapEnter', 'mapId': 'map'},
        'conditions': <Object?>[],
        'sceneId': scene,
        'reusePolicy': 'reusable',
        'priority': 0,
        'order': index,
      }
    };

final class _Fixture {
  _Fixture(this.directory, this.api, this.snapshots, this.mutations,
      this.worker, this.mapBefore,
      {this.mapRelativePath = 'maps/map.json'});
  final Directory directory;
  final AuthoringReadApi api;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  final List<int> mapBefore;
  final String mapRelativePath;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;
  File get manifest => File('${directory.path}/project.json');
  File get map => File('${directory.path}/$mapRelativePath');

  static Future<_Fixture> create(
      {bool duplicateOwners = false,
      bool threeD = false,
      bool initialDraft = false}) async {
    final directory =
        await Directory.systemTemp.createTemp('native-trigger-contact-api-');
    await Directory('${directory.path}/maps').create();
    final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 6, height: 6),
        version: threeD ? ProjectVersion.v9 : ProjectVersion.v8,
        spatialScene: threeD ? MapSpatialScene(width: 6, depth: 6) : null,
        triggers: [
          for (final id in [
            'owner',
            'duplicate-owner',
            if (duplicateOwners) 'duplicate-owner'
          ])
            MapTrigger(
                id: id,
                name: id,
                type: TriggerType.event,
                area: const MapRect(
                    pos: GridPos(x: 1, y: 1),
                    size: GridSize(width: 1, height: 1))),
          const MapTrigger(
              id: 'system',
              name: 'System',
              type: TriggerType.custom,
              area: MapRect(
                  pos: GridPos(x: 2, y: 2),
                  size: GridSize(width: 1, height: 1))),
        ]);
    final project = ProjectManifest(
        name: 'Native trigger contact transport',
        version: threeD ? ProjectVersion.v9 : ProjectVersion.v8,
        settings: ProjectSettings(
            dimension:
                threeD ? ProjectDimension.threeD : ProjectDimension.twoD),
        tilesets: const [],
        maps: const [
          ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
        ],
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              if (initialDraft)
                NarrativeEventRecord.draft(NarrativeEventDraft(
                    id: _id,
                    name: 'Draft contact',
                    source: NarrativeEventSourceRef.triggerBump('map', 'owner'),
                    sceneId: 'hello',
                    conditions: const [],
                    priority: 0,
                    order: 0))
              else
                NarrativeEventRecord.fromJson(
                    _record({'kind': 'mapEnter', 'mapId': 'map'}))
            ],
            legacyClaims: const []),
        scenes: [
          SceneAsset(
              id: 'hello',
              name: 'Hello',
              graph: SceneGraph(startNodeId: 'start', nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(id: 'end', kind: SceneNodeKind.end)
              ], edges: [
                SceneEdge(
                    id: 'done',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.defaultFlow)
              ]))
        ]);
    ProjectManifest.fromJson(
        jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>);
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    final mapFile = File('${directory.path}/maps/map.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    return openDirectory(directory);
  }

  static Future<_Fixture> createShared(Map<String, dynamic> data) async {
    final root = await Directory.systemTemp.createTemp('event-v2-parity-');
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(data['project']));
    final maps = (data['maps'] as List).cast<Map>();
    for (final map in maps) {
      final file = File('${root.path}/${map['relativePath']}');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(map['content']));
    }
    return openDirectory(root,
        mapRelativePath: maps.single['relativePath'] as String);
  }

  static Future<_Fixture> openDirectory(Directory directory,
      {String mapRelativePath = 'maps/map.json'}) async {
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
    final worker = JsonlWorker(api: api, mutations: mutations);
    final fixture = _Fixture(directory, api, snapshots, mutations, worker,
        await File('${directory.path}/$mapRelativePath').readAsBytes(),
        mapRelativePath: mapRelativePath);
    await fixture.open();
    return fixture;
  }

  Future<void> open() async {
    final opened = await command('open', {'projectRoot': directory.path});
    expect(opened.status, AuthoringResultStatus.success,
        reason: jsonEncode(opened.toJson()));
    workspace = WorkspaceHandle(opened.data['workspaceHandle'] as String);
    project = ProjectHandle(opened.data['projectHandle'] as String);
  }

  Future<void> reopen() async {
    await command('close', {'workspaceHandle': workspace.value});
    await open();
  }

  Future<AuthoringResult> command(
          String name, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
              {'id': 'wire-${++sequence}', 'command': name, 'args': args})))
          as Map<String, dynamic>);
  Future<AuthoringRequest> request(
      String action, Map<String, Object?> parameters) async {
    final id = 'trigger-contact-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: parameters);
  }

  Future<Map<String, Object?>> plan(AuthoringRequest request, bool wire) async {
    if (!wire) return mutations.plan(project, request);
    final result = await command(
        'plan', {'projectHandle': project.value, 'request': request.toJson()});
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    return result.data;
  }

  Future<void> apply(String planId, bool wire) async {
    final id = 'apply-${++sequence}';
    if (!wire) {
      await mutations.apply(project, planId: planId, operationId: id);
      return;
    }
    final result = await command('apply',
        {'projectHandle': project.value, 'planId': planId, 'operationId': id});
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
  }

  Future<void> dispose() async {
    await command('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}

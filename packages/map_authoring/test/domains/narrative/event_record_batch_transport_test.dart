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

void main() {
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
        {'state': 'draft', 'draft': {...configured}..remove('reusePolicy')},
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
      this.worker, this.mapBefore);
  final Directory directory;
  final AuthoringReadApi api;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  final List<int> mapBefore;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;
  File get manifest => File('${directory.path}/project.json');
  File get map => File('${directory.path}/maps/map.json');

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
        await mapFile.readAsBytes());
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

import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _id = 'evt_019abcde-0000-7000-8000-000000000001';
Map<String, Object?> _source(String kind,
        [String entityId = 'owner', String mapId = 'map']) =>
    {'kind': kind, 'mapId': mapId, 'entityId': entityId};
Map<String, Object?> _record(Map<String, Object?> source) => {
      'state': 'configured',
      'enabled': false,
      'definition': {
        'id': _id,
        'name': 'Automatic owner',
        'source': source,
        'conditions': <Object?>[],
        'sceneId': 'hello',
        'reusePolicy': 'reusable',
        'priority': 0,
        'order': 0,
      },
    };

void main() {
  test(
      'canonical event actions and resource contracts expose native entity autorun',
      () {
    for (final descriptor in EventV2Actions.descriptors) {
      final sources = descriptor.extensions['sourceVariants'] as List;
      final autorun = (sources.cast<Map>())
          .singleWhere((source) => source['kind'] == 'entityAutorun');
      expect(autorun['requiredFields'], ['kind', 'mapId', 'entityId']);
      expect(autorun['dimension'], 'twoD');
      expect(autorun['entityReference'], 'knownUniqueLogicalMapEntity');
    }
    final descriptor = AuthoringResourceKindRegistry.canonical()
        .resourceKinds
        .singleWhere((kind) => kind.id == 'eventV2');
    expect(
        (descriptor.extensions['sourceVariants'] as List)
            .cast<Map>()
            .any((source) => source['kind'] == 'entityAutorun'),
        isTrue);
  });

  for (final wire in [false, true]) {
    final label = wire ? 'JSONL' : 'direct API';
    test(
        '$label preserves a genuine source change through upsert and cold reopen',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final request = await f.request('event_v2.record_upsert',
          {'record': _record(_source('entityAutorun'))});
      final before = await f.manifest.readAsBytes();
      final planned = await f.plan(request, wire);
      expect(await f.manifest.readAsBytes(), before);
      await f.apply(planned['planId'] as String, wire);
      final saved = jsonDecode(await f.manifest.readAsString()) as Map;
      final record =
          ((saved['eventRegistry'] as Map)['records'] as List).single as Map;
      expect((record['definition'] as Map)['source'], _source('entityAutorun'));
      expect(await f.map.readAsBytes(), f.mapBefore);
      await f.reopen();
      final reopened = (await f.snapshots.load(f.project))
          .manifest
          .eventRegistry!
          .records
          .single;
      expect(reopened.definitionOrNull!.source,
          NarrativeEventSourceRef.entityAutorun('map', 'owner'));
      expect(reopened.definitionOrNull!.source,
          isNot(NarrativeEventSourceRef.entityInteract('map', 'owner')));
    });

    test('$label creates a native draft with an exact autorun source',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final request = await f.request('event_v2.create_draft', {
        'name': 'Automatic draft',
        'rawUuid': '019abcde-0000-7000-8000-000000000002',
        'initialSource': _source('entityAutorun'),
      });
      final planned = await f.plan(request, wire);
      await f.apply(planned['planId'] as String, wire);
      await f.reopen();
      final draft = (await f.snapshots.load(f.project))
          .manifest
          .eventRegistry!
          .records
          .singleWhere((record) => record.id.endsWith('000000000002'))
          .draftOrNull!;
      expect(
          draft.source, NarrativeEventSourceRef.entityAutorun('map', 'owner'));
    });

    test(
        '$label refuses invalid and incompatible autorun references before writes',
        () async {
      final f = await _Fixture.create(duplicateOwners: true);
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final sources = <Map<String, Object?>>[
        for (final owner in ['missing', 'duplicate-owner'])
          _source('entityAutorun', owner),
        _source('entityAutorun', 'owner', 'missing'),
        {'kind': 'entityAutorun', 'mapId': 'map', 'entityId': null},
        {'kind': 'entityAutorun', 'mapId': 'map', 'entityId': ' owner'},
        {..._source('entityAutorun'), 'triggerId': 'zone'},
        {..._source('entityAutorun'), 'unknown': true},
      ];
      for (final source in sources) {
        final request = await f
            .request('event_v2.record_upsert', {'record': _record(source)});
        if (wire) {
          final result = await f.command('plan',
              {'projectHandle': f.project.value, 'request': request.toJson()});
          expect(result.status, AuthoringResultStatus.failure);
          expect(result.error!.details['domainCode'], startsWith('event_v2.'));
          expect(result.error!.details['domainCode'], isNot('worker.internal'));
        } else {
          await expectLater(f.mutations.plan(f.project, request),
              throwsA(isA<NarrativeAuthoringException>()));
        }
        expect(await f.manifest.readAsBytes(), before);
        expect(await f.map.readAsBytes(), f.mapBefore);
      }
    });
  }
}

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

  static Future<_Fixture> create({bool duplicateOwners = false}) async {
    final directory =
        await Directory.systemTemp.createTemp('native-autorun-api-');
    await Directory('${directory.path}/maps').create();
    final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 6, height: 6),
        entities: [
          const MapEntity(
              id: 'owner',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 1, y: 1),
              blocksMovement: false),
          const MapEntity(
              id: 'plain-npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2, y: 1),
              blocksMovement: false),
          const MapEntity(
              id: 'sign',
              kind: MapEntityKind.sign,
              pos: GridPos(x: 3, y: 1),
              blocksMovement: false),
          const MapEntity(
              id: 'duplicate-owner',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 2, y: 2),
              blocksMovement: false),
          if (duplicateOwners)
            const MapEntity(
                id: 'duplicate-owner',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 3, y: 2),
                blocksMovement: false),
        ]);
    final project = ProjectManifest(
        name: 'Native autorun transport',
        tilesets: const [],
        maps: const [
          ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
        ],
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
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
    final id = 'autorun-${++sequence}';
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

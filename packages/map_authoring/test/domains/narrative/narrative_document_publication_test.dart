import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/narrative/narrative_document_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/standard_event_template_fixture.dart';

void main() {
  test(
      'scoped publication validates the changed map without unrelated producers',
      () {
    final map = templateMap();
    final scene = SceneAsset(
        id: 'other_scene',
        name: 'Other',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [
          SceneEdge(
              id: 'flow',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow)
        ]));
    final project = templateProject().copyWith(
        trainers: [],
        maps: [
          ...templateProject().maps,
          const ProjectMapEntry(
              id: 'other', name: 'Other', relativePath: 'maps/other.json'),
        ],
        scenes: [
          scene
        ],
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            legacyClaims: [],
            records: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                  NarrativeEventDefinition(
                      id: 'evt_00000000-0000-7000-8000-000000000041',
                      name: 'Other map',
                      source: NarrativeEventSourceRef.mapEnter('other'),
                      conditions: [],
                      sceneId: scene.id,
                      reusePolicy: NarrativeEventReusePolicy.reusable,
                      priority: 0,
                      order: 0),
                  enabled: true),
            ]));
    final draft = const NarrativeDocumentActions()
        .build(_scopedContext(project, map, {}));
    expect(draft.changeSet.changes.map((change) => change.storageKey),
        ['maps/room.json']);
  });

  test(
      'composite scoped publication refuses a fact type change without incoming proof',
      () {
    final fact = NarrativeFactDefinition(
        id: 'met', label: 'Met', initialValue: NarrativeValue.integer(1));
    expect(
        () => const NarrativeDocumentActions().build(_scopedContext(
                templateProject().copyWith(trainers: []), templateMap(), {
              'facts': [fact.toJson()]
            })),
        throwsA(isA<AuthoringPlanException>().having(
            (error) => error.code, 'code', 'catalog.mutation_scope_required')));
  });

  test('scoped narrative publication preserves map geometry boundaries', () {
    final map = templateMap();
    expect(
        () => const NarrativeDocumentActions().build(_scopedContext(
                templateProject().copyWith(trainers: []), map, {
              'map': map
                  .copyWith(size: const GridSize(width: 8, height: 8))
                  .toJson()
            })),
        throwsA(isA<AuthoringPlanException>().having(
            (error) => error.code, 'code', 'catalog.mutation_scope_required')));
  });

  test('scoped map publication refuses removal of a configured event source',
      () {
    final map = templateMap();
    final projection = compileStandardEventTemplate(
        project: templateProject(),
        maps: [map],
        spec: templateSpec(StandardEventTemplateKind.conditionalNpc));
    final project = templateProject().copyWith(
        trainers: [],
        scenes: projection.scenes,
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: projection.events,
            legacyClaims: []));
    expect(
        () => const NarrativeDocumentActions().build(_scopedContext(
            project, map, {'map': map.copyWith(entities: []).toJson()})),
        throwsStateError);
  });

  test('JSONL discovers coherent dialogue/map publication and reopens it',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('narrative_document_');
    final root = Directory(await temporary.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    final map = MapData(
        id: 'garden',
        name: 'Jardin',
        size: const GridSize(width: 2, height: 2),
        layers: [
          TileLayer(id: 'ground', name: 'Sol', cells: [0, 0, 0, 0])
        ]);
    final manifest = ProjectManifest(name: 'Publication', maps: [
      const ProjectMapEntry(
          id: 'garden', name: 'Jardin', relativePath: 'maps/garden.json')
    ], tilesets: []);
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/garden.json')
        .writeAsString(jsonEncode(map.toJson()));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(root.path);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() => mutations.detachWorkspace(opened.workspaceHandle));
    final worker = JsonlWorker(
        api: AuthoringReadApi(openService: opener, snapshotLoader: snapshots),
        mutations: mutations);
    Future<AuthoringResult> request(
            String id, String command, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(jsonDecode(await worker.processLine(
                jsonEncode({'id': id, 'command': command, 'args': args})))
            as Map<String, dynamic>);
    final described = await request('describe', 'describe', {});
    expect(
        jsonEncode(described.toJson()), contains('narrative.publish_document'));
    final snapshot = await snapshots.load(opened.projectHandle);
    final dirty = map.copyWith(name: 'Carte et dialogue');
    const entry = ProjectDialogueEntry(
        id: 'hello', name: 'Bonjour', relativePath: 'dialogues/hello.yarn');
    const source = 'title: Start\n---\nBonjour !\n===\n';
    final plan = await request('plan', 'plan', {
      'projectHandle': opened.projectHandle.value,
      'request': AuthoringRequest(
          requestId: 'narrative_plan',
          actionId: 'narrative.publish_document',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'narrative_publish',
          parameters: {
            'map': dirty.toJson(),
            'mapRevision': narrativeEventBytesFingerprint(
                snapshot.resourceBytes('map:garden')),
            'dialogues': [
              {'entry': entry.toJson(), 'source': source, 'revision': null}
            ],
          }).toJson(),
    });
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    expect(await File('${root.path}/dialogues/hello.yarn').exists(), false);
    final applied = await request('apply', 'apply', {
      'projectHandle': opened.projectHandle.value,
      'planId': plan.data['planId'],
      'operationId': 'narrative_apply'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    final after = await snapshots.load(opened.projectHandle);
    expect(after.manifest.dialogues, [entry]);
    expect(after.maps.single, dirty);
    expect(utf8.decode(after.resourceBytes('dialogueSource:hello')), source);
    expect(after.manifest.eventRegistry, manifest.eventRegistry);
  });
}

AuthoringPlanningContext _scopedContext(
    ProjectManifest project, MapData map, Map<String, Object?> additional) {
  final bytes = utf8.encode(jsonEncode(map.toJson()));
  final projectBytes = utf8.encode(jsonEncode(project.toJson()));
  final revision = narrativeEventBytesFingerprint(bytes);
  return AuthoringPlanningContext(
      snapshot: ProjectSnapshot(
          projectHandle: const ProjectHandle('project'),
          revision: revision,
          manifest: project,
          maps: [
            map
          ],
          availableProjectSections: const {
            'maps',
            'scenes',
            'eventRegistry',
            'facts'
          },
          resourceFingerprints: {
            'project': computeAuthoringBytesFingerprint(projectBytes,
                logicalName: 'project.json'),
            'map:${map.id}': computeAuthoringBytesFingerprint(bytes,
                logicalName: 'maps/${map.id}.json')
          },
          resourceStorageKeys: {
            'project': 'project.json',
            'map:${map.id}': 'maps/${map.id}.json'
          },
          resourceBytes: {
            'project': projectBytes,
            'map:${map.id}': bytes
          }),
      request: AuthoringRequest(
          requestId: 'scoped',
          actionId: 'narrative.publish_document',
          actionVersion: 1,
          workspaceHandle: 'workspace',
          expectedRevision: revision,
          idempotencyKey: 'scoped',
          parameters: {
            'map': map.copyWith(name: 'Edited').toJson(),
            'mapRevision': revision,
            ...additional
          },
          extensions: const {
            'workshopScope': true
          }),
      planId: 'plan',
      seed: 1);
}

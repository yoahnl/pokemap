import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _actions = <String>[
  'presentationCinematic.create',
  'presentationCinematicTemplate.instantiate',
  'presentationCinematic.publish',
  'scene.preSession.presentation.createAndLink',
];

void main() {
  for (final dimension in ProjectDimension.values) {
    for (final action in _actions) {
      test('$action preserves ${dimension.name} through direct and JSONL',
          () async {
        final direct = await _run(dimension, action, false);
        final jsonl = await _run(dimension, action, true);
        expect(jsonl, direct);
        final project = ProjectManifest.fromJson(direct);
        expect(project.settings.dimension, dimension);
        expect(
            project.version,
            dimension == ProjectDimension.threeD
                ? ProjectVersion.v9
                : ProjectVersion.v8);
        expect(project.presentationCinematics.single.id, 'opening');
        if (action == 'presentationCinematic.publish' ||
            action == 'scene.preSession.presentation.createAndLink') {
          expect(project.cinematicLibraryCatalog.entries.single.cinematicId,
              'opening');
        }
        if (action == 'scene.preSession.presentation.createAndLink') {
          expect(project.scenes.single.graph.nodes.map((node) => node.kind),
              contains(SceneNodeKind.presentationCinematic));
        }
      });
    }
  }
  for (final (version, dimension) in <(ProjectVersion, ProjectDimension)>[
    (ProjectVersion.v6, ProjectDimension.twoD),
    (ProjectVersion.v7, ProjectDimension.twoD),
    (ProjectVersion.v8, ProjectDimension.threeD),
    (ProjectVersion.v9, ProjectDimension.twoD),
  ]) {
    for (final action in _actions) {
      test('$action rejects ${version.name} with ${dimension.name}', () async {
        final manifest = ProjectManifest(
            name: 'Unsupported',
            version: version,
            settings: ProjectSettings(
              dimension: dimension,
              spatialCamera: dimension == ProjectDimension.threeD
                  ? SpatialCameraProfile()
                  : null,
            ),
            maps: const [],
            tilesets: const []);
        final bytes = utf8.encode(jsonEncode(manifest.toJson()));
        final snapshot = ProjectSnapshot(
          projectHandle: const ProjectHandle('project_unsupported'),
          revision: 'sha256:${List<String>.filled(64, 'a').join()}',
          manifest: manifest,
          maps: const [],
          resourceFingerprints: {
            'project': computeAuthoringBytesFingerprint(bytes,
                logicalName: 'project.json')
          },
          resourceBytes: {'project': bytes},
        );
        final context = AuthoringPlanningContext(
            snapshot: snapshot,
            request: AuthoringRequest(
                requestId: action,
                actionId: action,
                actionVersion: 1,
                workspaceHandle: 'workspace_unsupported',
                expectedRevision: snapshot.revision,
                idempotencyKey: action,
                parameters: _parameters(action)),
            planId: 'plan_unsupported',
            seed: 1);
        await expectLater(
            () async => await MapMutationDispatcher.canonical().build(context),
            throwsA(anyOf(
              isA<PresentationCinematicAuthoringException>().having(
                  (error) => error.code,
                  'code',
                  'presentation_cinematic.project_version_unsupported'),
              isA<PresentationCinematicTemplateAuthoringException>().having(
                  (error) => error.code,
                  'code',
                  'presentation_cinematic_template.project_version_unsupported'),
              isA<NarrativeAuthoringException>().having(
                  (error) => error.code,
                  'code',
                  'scene.preSession.presentation.project_version_unsupported'),
              isA<StateError>().having((error) => error.message, 'message',
                  contains('v8 (2D) ou v9 (3D)')),
            )));
        expect(manifest.presentationCinematics, isEmpty);
      });
    }
  }
}

Future<Map<String, dynamic>> _run(
    ProjectDimension dimension, String action, bool jsonl) async {
  final temp = await Directory.systemTemp.createTemp('presentation_dimension_');
  final root = Directory(await temp.resolveSymbolicLinks());
  final file = File('${root.path}/project.json');
  final manifest = ProjectManifest(
    name: 'Presentation dimension fixture',
    version: dimension == ProjectDimension.threeD
        ? ProjectVersion.v9
        : ProjectVersion.v8,
    settings: ProjectSettings(
      dimension: dimension,
      spatialCamera:
          dimension == ProjectDimension.threeD ? SpatialCameraProfile() : null,
    ),
    maps: const [],
    tilesets: const [],
    scenes: <SceneAsset>[
      SceneAsset(
        id: 'intro',
        name: 'Introduction',
        executionProfile: SceneExecutionProfile.preSession,
        declaredOutcomes: <SceneOutcome>[
          SceneOutcome(id: 'ready', label: 'Ready')
        ],
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'end',
                kind: SceneNodeKind.end,
                payload: SceneEndPayload(
                    sceneOutcomeId: 'ready',
                    outcomePolicy: SceneOutcomePolicy.progression)),
          ],
          edges: <SceneEdge>[
            SceneEdge(
                id: 'start_end',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow),
          ],
        ),
      ),
    ],
  );
  await file.writeAsString(jsonEncode(manifest.toJson()));
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: snapshots);
  final mutations =
      LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
  final worker = JsonlWorker(api: api, mutations: mutations);
  Future<Map<String, Object?>> request(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': command, 'command': command, 'args': args})))
        as Map<String, dynamic>);
    expect(result.status, AuthoringResultStatus.success,
        reason: result.error?.toJson().toString());
    return result.data;
  }

  final opened = jsonl
      ? await request('open', {'projectRoot': root.path})
      : await api.open(root.path);
  final project = ProjectHandle(opened['projectHandle'] as String);
  final workspace = WorkspaceHandle(opened['workspaceHandle'] as String);
  try {
    if (!jsonl) {
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: workspace,
          projectHandle: project);
    }
    final before = await file.readAsBytes();
    final revision = (await snapshots.load(project)).revision;
    final command = AuthoringRequest(
      requestId: action,
      actionId: action,
      actionVersion: 1,
      workspaceHandle: workspace.value,
      expectedRevision: revision,
      idempotencyKey: action,
      parameters: _parameters(action),
    );
    final plan = jsonl
        ? await request('plan',
            {'projectHandle': project.value, 'request': command.toJson()})
        : await mutations.plan(project, command);
    expect(await file.readAsBytes(), before);
    if (jsonl) {
      await request('apply', {
        'projectHandle': project.value,
        'planId': plan['planId'],
        'operationId': action
      });
    } else {
      await mutations.apply(project,
          planId: plan['planId'] as String, operationId: action);
    }
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } finally {
    if (jsonl) {
      await request('close', {'workspaceHandle': workspace.value});
    } else {
      await mutations.detachWorkspace(workspace);
      await api.close(workspace);
    }
    await root.delete(recursive: true);
  }
}

Map<String, Object?> _parameters(String action) => switch (action) {
      'presentationCinematic.create' => {
          'cinematicId': 'opening',
          'title': 'Opening',
          'description': null,
          'durationUs': 1000000,
        },
      'presentationCinematicTemplate.instantiate' => {
          'templateId': 'blank',
          'templateVersion': 1,
          'cinematicId': 'opening',
          'title': 'Opening',
          'description': null,
        },
      'presentationCinematic.publish' => {
          'cinematic': encodePresentationCinematicAsset(
              PresentationCinematicAsset(
                  id: 'opening', title: 'Opening', durationUs: 1000000)),
          'expectedCinematic': null,
          'expectedEntry': null,
          'expectedMedia': [],
          'folderId': null,
          'imports': [],
        },
      _ => {
          'sceneId': 'intro',
          'nodeId': 'opening',
          'targetNodeId': 'end',
          'cinematicId': 'opening',
          'title': 'Opening',
          'templateId': 'blank',
          'templateVersion': 1,
          'targetFolderId': null,
          'targetIndex': 0,
        },
    };

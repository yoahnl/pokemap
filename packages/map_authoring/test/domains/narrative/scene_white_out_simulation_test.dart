import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Scene actions publish the autonomous whiteOut contract', () {
    for (final id in ['scene.upsert', 'scene.graph.patch']) {
      final contract = SceneActions.descriptors
          .singleWhere((action) => action.id == id)
          .extensions['whiteOut'] as Map;
      expect(contract['interactiveCommandKind'], 'whiteOut');
      expect(contract['parameters'], isEmpty);
      expect(contract['activation'], 'afterSuccessfulSceneCompletion');
      expect(contract['projectDimension'], 'twoD');
      expect(contract['outputPorts'], ['completed']);
    }
  });

  for (final battle in [false, true]) {
    for (final dimension in ProjectDimension.values) {
      for (final completed in [false, true]) {
        test(
            'simulation $dimension battle=$battle completed=$completed proposes recovery only at successful completion',
            () async {
          final root =
              await Directory.systemTemp.createTemp('whiteout-simulation-');
          final file = File('${root.path}/project.json');
          final project = ProjectManifest(
              name: 'Simulation',
              version: dimension == ProjectDimension.threeD ? ProjectVersion.v9 : ProjectVersion.v8,
              maps: const [],
              tilesets: const [],
              scenes: [_scene(battle)],
              settings: ProjectSettings(dimension: dimension));
          final original = jsonEncode(project.toJson());
          await file.writeAsString(original);
          const reader = LocalProjectFileReader();
          final handles = WorkspaceHandleStore();
          final api = AuthoringReadApi(
              openService: ProjectOpenService(
                  policy: await WorkspacePolicy.create(
                      allowedRootPaths: [root.path], fileReader: reader),
                  fileReader: reader,
                  handles: handles),
              snapshotLoader: ProjectSnapshotLoader(handles: handles));
          final opened = await api.openProject(root.path);
          addTearDown(() async {
            await api.closeWorkspace(opened.workspaceHandle);
            await root.delete(recursive: true);
          });
          final response = api.queryProject(
              opened.projectHandle,
              AuthoringQueryRequest(
                  resourceKind: 'scene',
                  operation: AuthoringQueryOperation.get,
                  ids: [
                    'recovery'
                  ],
                  extensions: {
                    'actionId': 'scene.simulate',
                    'parameters': {
                      'portsByNodeId': {
                        'request': battle ? 'defeat' : 'completed',
                        if (completed) 'followup': 'completed',
                      }
                    }
                  }));
          if (dimension != ProjectDimension.twoD) {
            await expectLater(
                response,
                throwsA(isA<NarrativeAuthoringException>().having(
                    (error) => error.code,
                    'code',
                    'scene.simulation_unsupported_dimension')));
            expect(await file.readAsString(), original);
            return;
          }
          final result = (await response).items.single;
          expect(result['status'], completed ? 'completed' : 'failed');
          expect(result['proofKind'], 'simulation');
          expect(result['mountedPlayer'], isFalse);
          expect(result['effects'], 'proposedOnly');
          expect(
              result['proposedDefeatRecoveries'],
              completed
                  ? [
                      {
                        'nodeId': 'request',
                        'source': battle ? 'battleDefeat' : 'whiteOut',
                        'activation': 'afterSuccessfulSceneCompletion'
                      },
                    ]
                  : isEmpty);
          expect(await file.readAsString(), original);
        });
      }
    }
  }
}

SceneAsset _scene(bool battle) => SceneAsset(
    id: 'recovery',
    name: 'Recovery',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'request',
            kind: battle ? SceneNodeKind.battle : SceneNodeKind.action,
            payload: battle
                ? SceneBattlePayload(
                    battleKind: 'trainer',
                    trainerId: 'rival',
                    defeatRecovery:
                        SceneBattleDefeatRecovery.returnToRecoveryPoint,
                    declaredOutcomes: const ['victory', 'defeat'])
                : SceneActionPayload.interactive(
                    SceneInteractiveCommand.fromJson({'kind': 'whiteOut'}))),
        SceneNode(
            id: 'followup',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.wait(durationMs: 0))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
            id: 'begin',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'request',
            kind: SceneEdgeKind.defaultFlow),
        if (battle)
          SceneEdge(
              id: 'win',
              fromNodeId: 'request',
              fromPortId: 'victory',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleVictory),
        SceneEdge(
            id: 'continue',
            fromNodeId: 'request',
            fromPortId: battle ? 'defeat' : 'completed',
            toNodeId: 'followup',
            kind: battle
                ? SceneEdgeKind.battleDefeat
                : SceneEdgeKind.defaultFlow),
        SceneEdge(
            id: 'finish',
            fromNodeId: 'followup',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow),
      ],
    ));

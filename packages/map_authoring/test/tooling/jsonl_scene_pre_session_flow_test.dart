import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('preSession actions keep direct and JSONL projects equivalent',
      () async {
    final direct = await _Harness.create('direct');
    final jsonl = await _Harness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directResult = await direct.run(useJsonl: false);
    final jsonlResult = await jsonl.run(useJsonl: true);

    expect(directResult.dryRunBytes, directResult.initialBytes);
    expect(jsonlResult.dryRunBytes, jsonlResult.initialBytes);
    expect(directResult.appliedReceipt, directResult.replayReceipt);
    expect(jsonlResult.appliedReceipt, jsonlResult.replayReceipt);
    expect(directResult.actionIds, _actionIds);
    expect(jsonlResult.actionIds, _actionIds);
    expect(directResult.scene, jsonlResult.scene);
    expect(directResult.finalBytes, jsonlResult.finalBytes);
    expect(directResult.staleCode, 'plan.stale');
    expect(jsonlResult.staleCode, 'plan.stale');
  });
}

final class _Harness {
  _Harness._(
    this.root,
    this.readApi,
    this.mutations,
    this.snapshots,
    this.worker,
  );

  static Future<_Harness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp('pre_session_$suffix');
    await Directory('${root.path}/maps').create(recursive: true);
    final manifest = ProjectManifest(
      name: 'Pre-session transport fixture',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_start',
          name: 'Départ',
          relativePath: 'maps/map_start.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: [
        PresentationCinematicAsset(
          id: 'presentation_opening',
          title: 'Ouverture',
          durationUs: 1000000,
          tracks: [
            PresentationTrack(
              id: 'markers',
              label: 'Repères',
              kind: PresentationTrackKind.marker,
              clips: [
                PresentationMarkerClip(
                  id: 'cue_player_name',
                  startUs: 500000,
                  label: 'Demander le nom',
                  markerKind: PresentationMarkerKind.interactionCue,
                ),
              ],
            ),
          ],
        ),
      ],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'map_start',
      ),
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    await File('${root.path}/maps/map_start.json').writeAsString(
      jsonEncode(
        const MapData(
          id: 'map_start',
          name: 'Départ',
          version: ProjectVersion.v6,
          size: GridSize(width: 2, height: 2),
          layers: <MapLayer>[
            MapLayer.tile(
              id: 'ground',
              name: 'Sol',
              cells: <int>[0, 0, 0, 0],
            ),
          ],
        ).toJson(),
      ),
      flush: true,
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _Harness._(
      root,
      readApi,
      mutations,
      snapshots,
      JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<_Result> run({required bool useJsonl}) async {
    final opened = useJsonl
        ? await _success('open', <String, Object?>{'projectRoot': root.path})
        : await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    if (!useJsonl) {
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: workspace,
        projectHandle: project,
      );
    }
    final initialBytes = await _bytes();
    var revision = await _revision(project, useJsonl: useJsonl);
    final dryRunRequest = _request(
      workspace.value,
      revision,
      sequence: 0,
      actionId: 'scene.preSession.create',
      parameters: _createParameters,
      dryRun: true,
    );
    final dryRun = useJsonl
        ? await _success('plan', <String, Object?>{
            'projectHandle': project.value,
            'request': dryRunRequest.toJson(),
          })
        : await mutations.plan(project, dryRunRequest);
    expect(dryRun['nonApplicableReason'], 'dry_run');
    final dryRunBytes = await _bytes();
    final actionIds = <String>{};
    Map<String, Object?>? appliedReceipt;
    Map<String, Object?>? replayReceipt;

    Future<void> apply(
      int sequence,
      String actionId,
      Map<String, Object?> parameters,
    ) async {
      final request = _request(
        workspace.value,
        revision,
        sequence: sequence,
        actionId: actionId,
        parameters: parameters,
      );
      final plan = useJsonl
          ? await _success('plan', <String, Object?>{
              'projectHandle': project.value,
              'request': request.toJson(),
            })
          : await mutations.plan(project, request);
      final operationId = 'pre-session-operation-$sequence';
      final response = useJsonl
          ? await _success('apply', <String, Object?>{
              'projectHandle': project.value,
              'planId': plan['planId'],
              'operationId': operationId,
            })
          : await mutations.apply(
              project,
              planId: plan['planId']! as String,
              operationId: operationId,
            );
      final receipt = _stableReceipt(response);
      actionIds.add(receipt['actionId']! as String);
      if (sequence == 4) {
        final replay = useJsonl
            ? await _success('apply', <String, Object?>{
                'projectHandle': project.value,
                'planId': plan['planId'],
                'operationId': operationId,
              })
            : await mutations.apply(
                project,
                planId: plan['planId']! as String,
                operationId: operationId,
              );
        appliedReceipt = receipt;
        replayReceipt = _stableReceipt(replay);
      }
      revision = await _revision(project, useJsonl: useJsonl);
    }

    await apply(1, 'scene.preSession.create', _createParameters);
    await apply(2, 'scene.preSession.interaction.insert', <String, Object?>{
      'sceneId': 'new_game_intro',
      'nodeId': 'ask_name',
      'targetNodeId': 'end',
      'interaction': ScenePreSessionInteractionSpec.text(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.playerName.prompt',
        ),
        resultBinding: const ScenePreSessionResultBinding(
          field: ScenePreSessionDraftField.playerName,
        ),
      ).toJson(),
    });
    await apply(3, 'scene.preSession.presentation.insert', const {
      'sceneId': 'new_game_intro',
      'nodeId': 'opening',
      'targetNodeId': 'ask_name',
      'presentationCinematicId': 'presentation_opening',
    });
    await apply(4, 'scene.preSession.interaction.update', <String, Object?>{
      'sceneId': 'new_game_intro',
      'nodeId': 'ask_name',
      'interaction': ScenePreSessionInteractionSpec.text(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.playerName.prompt',
          fallbackText: 'Comment veux-tu t’appeler ?',
        ),
        resultBinding: const ScenePreSessionResultBinding(
          field: ScenePreSessionDraftField.playerName,
        ),
      ).toJson(),
      'cueBinding': const <String, Object?>{
        'presentationNodeId': 'opening',
        'markerId': 'cue_player_name',
      },
    });
    await apply(5, 'scene.preSession.presentation.createAndLink', const {
      'sceneId': 'new_game_intro',
      'nodeId': 'studio_logo',
      'targetNodeId': 'end',
      'cinematicId': 'presentation_studio_logo',
      'title': 'Logo du studio',
      'templateId': 'blank',
      'templateVersion': 1,
      'targetFolderId': null,
      'targetIndex': 0,
    });
    await apply(6, 'scene.preSession.condition.insert', const {
      'sceneId': 'new_game_intro',
      'nodeId': 'has_name',
      'targetNodeId': 'end',
      'falseEndNodeId': 'end_missing_name',
      'draftField': 'playerName',
      'operator': 'isTrue',
    });
    await apply(7, 'scene.preSession.end.configure', const {
      'sceneId': 'new_game_intro',
      'nodeId': 'end',
      'outcomeId': 'ready',
      'outcomeLabel': 'Prêt',
      'outcomePolicy': 'progression',
    });

    final query = AuthoringQueryRequest(
      resourceKind: 'scene',
      operation: AuthoringQueryOperation.get,
      ids: const <String>['new_game_intro'],
      view: AuthoringQueryView.detail,
    );
    final queryResponse = useJsonl
        ? await _success('query', <String, Object?>{
            'projectHandle': project.value,
            'request': query.toJson(),
          })
        : await readApi.query(project, query);
    final staleCode = await _staleCode(
      project,
      workspace,
      useJsonl: useJsonl,
    );
    return _Result(
      initialBytes: initialBytes,
      dryRunBytes: dryRunBytes,
      finalBytes: await _bytes(),
      actionIds: actionIds,
      appliedReceipt: appliedReceipt!,
      replayReceipt: replayReceipt!,
      scene: Map<String, Object?>.from(
        (queryResponse['items']! as List).single as Map,
      ),
      staleCode: staleCode,
    );
  }

  Future<String> _revision(
    ProjectHandle project, {
    required bool useJsonl,
  }) async {
    if (useJsonl) {
      return (await _success('validate', <String, Object?>{
        'projectHandle': project.value,
      }))['snapshotRevision']! as String;
    }
    return (await snapshots.load(project)).revision;
  }

  Future<String> _staleCode(
    ProjectHandle project,
    WorkspaceHandle workspace, {
    required bool useJsonl,
  }) async {
    final request = _request(
      workspace.value,
      _staleRevision,
      sequence: 99,
      actionId: 'scene.preSession.interaction.insert',
      parameters: <String, Object?>{
        'sceneId': 'new_game_intro',
        'nodeId': 'stale',
        'targetNodeId': 'end',
        'interaction': ScenePreSessionInteractionSpec.message(
          prompt: SceneInteractionPrompt(
            localizationKey: 'stale.prompt',
          ),
        ).toJson(),
      },
    );
    if (useJsonl) {
      final result = await _result('plan', <String, Object?>{
        'projectHandle': project.value,
        'request': request.toJson(),
      });
      return result.error!.details['domainCode']! as String;
    }
    try {
      await mutations.plan(project, request);
    } on AuthoringPlanException catch (error) {
      return error.code;
    }
    throw StateError('Stale preSession request accepted.');
  }

  Future<Map<String, Object?>> _success(
    String command,
    Map<String, Object?> args,
  ) async {
    final result = await _result(command, args);
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: result.error?.toJson().toString(),
    );
    return result.data;
  }

  Future<AuthoringResult> _result(
    String command,
    Map<String, Object?> args,
  ) async {
    final line = await worker.processLine(jsonEncode(<String, Object?>{
      'id': 'request-$command',
      'command': command,
      'args': args,
    }));
    return AuthoringResult.fromJson(
      jsonDecode(line) as Map<String, dynamic>,
    );
  }

  Future<List<int>> _bytes() => File('${root.path}/project.json').readAsBytes();

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _Result {
  const _Result({
    required this.initialBytes,
    required this.dryRunBytes,
    required this.finalBytes,
    required this.actionIds,
    required this.appliedReceipt,
    required this.replayReceipt,
    required this.scene,
    required this.staleCode,
  });

  final List<int> initialBytes;
  final List<int> dryRunBytes;
  final List<int> finalBytes;
  final Set<String> actionIds;
  final Map<String, Object?> appliedReceipt;
  final Map<String, Object?> replayReceipt;
  final Map<String, Object?> scene;
  final String staleCode;
}

const _createParameters = <String, Object?>{
  'sceneId': 'new_game_intro',
  'name': 'Nouvelle partie',
  'templateId': 'minimal',
  'setAsEntrypoint': true,
};

const _actionIds = <String>{
  'scene.preSession.create',
  'scene.preSession.interaction.insert',
  'scene.preSession.interaction.update',
  'scene.preSession.presentation.insert',
  'scene.preSession.presentation.createAndLink',
  'scene.preSession.condition.insert',
  'scene.preSession.end.configure',
};

AuthoringRequest _request(
  String workspace,
  String revision, {
  required int sequence,
  required String actionId,
  required Map<String, Object?> parameters,
  bool dryRun = false,
}) {
  return AuthoringRequest(
    requestId: 'pre-session-request-$sequence',
    actionId: actionId,
    actionVersion: 1,
    workspaceHandle: workspace,
    parameters: parameters,
    expectedRevision: revision,
    idempotencyKey: 'pre-session-idempotency-$sequence',
    dryRun: dryRun,
  );
}

Map<String, Object?> _stableReceipt(Map<String, Object?> response) {
  final receipt = Map<String, Object?>.from(response['receipt']! as Map);
  return <String, Object?>{
    for (final key in const <String>[
      'requestId',
      'actionId',
      'actionVersion',
      'status',
      'beforeRevision',
      'afterRevision',
      'diff',
      'affectedResources',
    ])
      key: receipt[key],
  };
}

const _staleRevision =
    'sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

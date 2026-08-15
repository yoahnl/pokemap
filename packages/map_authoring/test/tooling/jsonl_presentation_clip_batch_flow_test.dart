import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Presentation clip batch keeps direct and JSONL commits equivalent',
      () async {
    final direct = await _Fixture.create('direct');
    final jsonl = await _Fixture.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directResult = await direct.runDirect();
    final jsonlResult = await jsonl.runJsonl();

    expect(directResult.actionId, 'presentationClip.batch');
    expect(jsonlResult.actionId, 'presentationClip.batch');
    expect(directResult.afterStartUs, 2000000);
    expect(jsonlResult.afterStartUs, 2000000);
    expect(directResult.afterUndoStartUs, 1000000);
    expect(jsonlResult.afterUndoStartUs, 1000000);
    expect(directResult.deleteActionId, 'presentationClip.deleteBatch');
    expect(jsonlResult.deleteActionId, 'presentationClip.deleteBatch');
    expect(directResult.deletedClipCount, 0);
    expect(jsonlResult.deletedClipCount, 0);
    expect(directResult.afterDeleteUndoStartUs, 1000000);
    expect(jsonlResult.afterDeleteUndoStartUs, 1000000);
    expect(directResult.changeSet, jsonlResult.changeSet);
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_Fixture> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_presentation_batch_$suffix',
    );
    final manifest = ProjectManifest(
      name: 'Presentation batch transport',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 5000000,
          tracks: <PresentationTrack>[
            PresentationTrack(
              id: 'markers',
              label: 'Markers',
              kind: PresentationTrackKind.marker,
              clips: <PresentationClip>[
                PresentationMarkerClip(
                  id: 'anchor',
                  startUs: 1000000,
                  label: 'Anchor',
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(manifest.toJson()),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
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
    return _Fixture(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<_Result> runDirect() async {
    final opened = await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final snapshot = await snapshots.load(project);
    final plan = await mutations.plan(
      project,
      _request(workspace.value, snapshot.revision, 'direct'),
    );
    final applied = await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'presentation-batch-direct',
    );
    final history = await mutations.history(project, limit: 1);
    final entry = Map<String, Object?>.from(
      (history['entries']! as List<Object?>).single! as Map,
    );
    final afterStartUs = _startUs();
    await mutations.undo(
      project,
      entryId: entry['entryId']! as String,
      idempotencyKey: 'presentation-batch-direct-undo',
    );
    final afterUndoStartUs = _startUs();
    final deleteSnapshot = await snapshots.load(project);
    final deletePlan = await mutations.plan(
      project,
      _deleteRequest(workspace.value, deleteSnapshot.revision, 'direct'),
    );
    final confirmation = await mutations.confirm(
      project,
      planId: deletePlan['planId']! as String,
    );
    final deleted = await mutations.apply(
      project,
      planId: deletePlan['planId']! as String,
      operationId: 'presentation-delete-batch-direct',
      confirmationToken: confirmation['confirmationToken']! as String,
    );
    final deleteHistory = await mutations.history(project, limit: 1);
    final deleteEntry = Map<String, Object?>.from(
      (deleteHistory['entries']! as List<Object?>).single! as Map,
    );
    final deletedClipCount = _clipCount();
    await mutations.undo(
      project,
      entryId: deleteEntry['entryId']! as String,
      idempotencyKey: 'presentation-delete-batch-direct-undo',
    );
    return _Result(
      actionId: _receipt(applied)['actionId']! as String,
      changeSet: Map<String, Object?>.from(
        (plan['plan']! as Map)['changeSet']! as Map,
      ),
      afterStartUs: afterStartUs,
      afterUndoStartUs: afterUndoStartUs,
      deleteActionId: _receipt(deleted)['actionId']! as String,
      deletedClipCount: deletedClipCount,
      afterDeleteUndoStartUs: _startUs(),
    );
  }

  Future<_Result> runJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    final validation = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final plan = await _jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        validation['snapshotRevision']! as String,
        'jsonl',
      ).toJson(),
    });
    final applied = await _jsonl('apply', <String, Object?>{
      'projectHandle': project,
      'planId': plan['planId'],
      'operationId': 'presentation-batch-jsonl',
    });
    final history = await _jsonl('history', <String, Object?>{
      'projectHandle': project,
      'limit': 1,
    });
    final entry = Map<String, Object?>.from(
      (history['entries']! as List<Object?>).single! as Map,
    );
    final afterStartUs = _startUs();
    await _jsonl('undo', <String, Object?>{
      'projectHandle': project,
      'entryId': entry['entryId'],
      'idempotencyKey': 'presentation-batch-jsonl-undo',
    });
    final afterUndoStartUs = _startUs();
    final deleteValidation = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final deletePlan = await _jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': _deleteRequest(
        workspace,
        deleteValidation['snapshotRevision']! as String,
        'jsonl',
      ).toJson(),
    });
    final confirmation = await _jsonl('confirm', <String, Object?>{
      'projectHandle': project,
      'planId': deletePlan['planId'],
    });
    final deleted = await _jsonl('apply', <String, Object?>{
      'projectHandle': project,
      'planId': deletePlan['planId'],
      'operationId': 'presentation-delete-batch-jsonl',
      'confirmationToken': confirmation['confirmationToken'],
    });
    final deleteHistory = await _jsonl('history', <String, Object?>{
      'projectHandle': project,
      'limit': 1,
    });
    final deleteEntry = Map<String, Object?>.from(
      (deleteHistory['entries']! as List<Object?>).single! as Map,
    );
    final deletedClipCount = _clipCount();
    await _jsonl('undo', <String, Object?>{
      'projectHandle': project,
      'entryId': deleteEntry['entryId'],
      'idempotencyKey': 'presentation-delete-batch-jsonl-undo',
    });
    return _Result(
      actionId: _receipt(applied)['actionId']! as String,
      changeSet: Map<String, Object?>.from(
        (plan['plan']! as Map)['changeSet']! as Map,
      ),
      afterStartUs: afterStartUs,
      afterUndoStartUs: afterUndoStartUs,
      deleteActionId: _receipt(deleted)['actionId']! as String,
      deletedClipCount: deletedClipCount,
      afterDeleteUndoStartUs: _startUs(),
    );
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final result = AuthoringResult.fromJson(
      jsonDecode(
        await worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'request-$command',
            'command': command,
            'args': args,
          }),
        ),
      ) as Map<String, dynamic>,
    );
    expect(result.status, AuthoringResultStatus.success);
    return result.data;
  }

  int _startUs() {
    final raw =
        jsonDecode(File('${root.path}/project.json').readAsStringSync());
    return ProjectManifest.fromJson(
      Map<String, dynamic>.from(raw as Map),
    ).presentationCinematics.single.tracks.single.clips.single.startUs;
  }

  int _clipCount() {
    final raw =
        jsonDecode(File('${root.path}/project.json').readAsStringSync());
    return ProjectManifest.fromJson(
      Map<String, dynamic>.from(raw as Map),
    ).presentationCinematics.single.tracks.single.clips.length;
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _Result {
  const _Result({
    required this.actionId,
    required this.changeSet,
    required this.afterStartUs,
    required this.afterUndoStartUs,
    required this.deleteActionId,
    required this.deletedClipCount,
    required this.afterDeleteUndoStartUs,
  });

  final String actionId;
  final Map<String, Object?> changeSet;
  final int afterStartUs;
  final int afterUndoStartUs;
  final String deleteActionId;
  final int deletedClipCount;
  final int afterDeleteUndoStartUs;
}

AuthoringRequest _request(
  String workspaceHandle,
  String revision,
  String sequence,
) =>
    AuthoringRequest(
      requestId: 'presentation-batch-$sequence',
      actionId: 'presentationClip.batch',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const <String, Object?>{
        'cinematicId': 'opening',
        'operations': <Object?>[
          <String, Object?>{
            'kind': 'edit',
            'clipId': 'anchor',
            'targetTrackId': 'markers',
            'startUs': 2000000,
            'durationUs': 0,
          },
        ],
      },
      expectedRevision: revision,
      idempotencyKey: 'presentation-batch-$sequence',
    );

AuthoringRequest _deleteRequest(
  String workspaceHandle,
  String revision,
  String sequence,
) =>
    AuthoringRequest(
      requestId: 'presentation-delete-batch-$sequence',
      actionId: 'presentationClip.deleteBatch',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const <String, Object?>{
        'cinematicId': 'opening',
        'clipIds': <String>['anchor'],
      },
      expectedRevision: revision,
      idempotencyKey: 'presentation-delete-batch-$sequence',
    );

Map<String, Object?> _receipt(Map<String, Object?> response) =>
    Map<String, Object?>.from(response['receipt']! as Map);

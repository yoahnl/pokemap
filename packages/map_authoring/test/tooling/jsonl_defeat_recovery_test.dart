import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const config = ProjectDefeatRecoveryConfig(recoveredFactId: 'after-loss');
  test(
      'direct canonical recovery update validates a bool reference and clears explicitly',
      () async {
    final setup = await _DefeatJsonlSetup.create();
    addTearDown(setup.dispose);
    final project = ProjectManifest.fromJson(
        jsonDecode(await File('${setup.root.path}/project.json').readAsString())
            as Map<String, dynamic>);
    final updated =
        const CampaignContentActions().updateDefeatRecovery(project, config);
    expect(updated.defeatRecovery, config);
    expect(updated.newGame, project.newGame);
    expect(
        const CampaignContentActions()
            .updateDefeatRecovery(updated, null)
            .defeatRecovery,
        isNull);
    for (final id in ['unknown', 'count']) {
      expect(
          () => const CampaignContentActions().updateDefeatRecovery(
              project, ProjectDefeatRecoveryConfig(recoveredFactId: id)),
          throwsA(isA<ValidationException>()));
    }
  });
  test(
      'JSONL discovers, rejects invalid refs, applies, replays, cold reopens and clears the hook',
      () async {
    final setup = await _DefeatJsonlSetup.create();
    addTearDown(setup.dispose);
    final opened =
        await setup.request('open', args: {'projectRoot': setup.root.path});
    final handle = ProjectHandle(opened.data['projectHandle']! as String);
    final workspace = opened.data['workspaceHandle']! as String;
    final descriptor = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((entry) => entry.id == 'campaign.defeat_recovery.update');
    expect((descriptor.extensions['defeatRecovery'] as Map)['value'], true);
    final before = await setup.snapshots.load(handle);
    final original =
        await File('${setup.root.path}/project.json').readAsBytes();
    var sequence = 0;
    Future<AuthoringResult> plan(Object? value, String revision) =>
        setup.request('plan', args: {
          'projectHandle': handle.value,
          'request': AuthoringRequest(
                  requestId: 'defeat-${++sequence}',
                  actionId: 'campaign.defeat_recovery.update',
                  actionVersion: 1,
                  workspaceHandle: workspace,
                  parameters: {'defeatRecovery': value},
                  expectedRevision: revision,
                  idempotencyKey: 'defeat-$sequence')
              .toJson()
        });
    for (final value in [
      {'recoveredFactId': 'unknown'},
      {'recoveredFactId': 'count'},
      {'recoveredFactId': 'after-loss', 'value': false},
      {'recoveredFactId': ''}
    ]) {
      final result = await plan(value, before.revision);
      expect(result.status, isNot(AuthoringResultStatus.success));
      expect(jsonEncode(result.toJson()), isNot(contains('worker.internal')));
      expect(await File('${setup.root.path}/project.json').readAsBytes(),
          original);
    }
    final prepared = await plan(config.toJson(), before.revision);
    expect(prepared.status, AuthoringResultStatus.success,
        reason: prepared.toJson().toString());
    final input = {
      'projectHandle': handle.value,
      'planId': prepared.data['planId'],
      'operationId': 'defeat-apply'
    };
    final applied = await setup.request('apply', args: input);
    expect(applied.status, AuthoringResultStatus.success);
    final saved = await File('${setup.root.path}/project.json').readAsBytes();
    final replay = await setup.request('apply', args: input);
    expect(replay.data['receipt'], applied.data['receipt']);
    expect(await File('${setup.root.path}/project.json').readAsBytes(), saved);
    final reopened =
        await setup.request('open', args: {'projectRoot': setup.root.path});
    final cold = await setup.snapshots
        .load(ProjectHandle(reopened.data['projectHandle']! as String));
    expect(cold.manifest.defeatRecovery, config);
    final clearing = await plan(null, cold.revision);
    expect(clearing.status, AuthoringResultStatus.success);
    expect(
        (await setup.request('apply', args: {
          'projectHandle': handle.value,
          'planId': clearing.data['planId'],
          'operationId': 'defeat-clear'
        }))
            .status,
        AuthoringResultStatus.success);
    final cleared = ProjectManifest.fromJson(
        jsonDecode(await File('${setup.root.path}/project.json').readAsString())
            as Map<String, dynamic>);
    expect(cleared.defeatRecovery, isNull);
  });
}

final class _DefeatJsonlSetup {
  const _DefeatJsonlSetup({
    required this.root,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_DefeatJsonlSetup> create() async {
    final root = await Directory.systemTemp.createTemp('jsonl-recovery-');
    await Directory('${root.path}/maps').create(recursive: true);
    const maps = [
      MapData(
        id: 'alpha',
        name: 'Alpha',
        size: GridSize(width: 4, height: 3),
      ),
      MapData(
        id: 'beta',
        name: 'Beta',
        size: GridSize(width: 3, height: 3),
      ),
    ];
    final manifest = ProjectManifest(
      name: 'Defeat hook',
      facts: [
        NarrativeFactDefinition(id: 'after-loss', label: 'Retour'),
        NarrativeFactDefinition(
            id: 'count',
            label: 'Count',
            initialValue: NarrativeValue.integer(0))
      ],
      maps: [
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
        ProjectMapEntry(
          id: 'beta',
          name: 'Beta',
          relativePath: 'maps/beta.json',
        ),
      ],
      tilesets: [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    for (final map in maps) {
      await File('${root.path}/maps/${map.id}.json').writeAsBytes(
        encodeMapAuthoringDocument(map),
        flush: true,
      );
    }
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
    return _DefeatJsonlSetup(
      root: root,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<AuthoringResult> request(
    String command, {
    Map<String, Object?> args = const {},
  }) async {
    final decoded = jsonDecode(
      await worker.processLine(
        jsonEncode({
          'id': 'jsonl-recovery-$command',
          'command': command,
          'args': args,
        }),
      ),
    ) as Map<String, dynamic>;
    return AuthoringResult.fromJson(decoded);
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const config = ProjectBattleSavingsConfig(
      enabledFactId: 'after-loss',
      balanceFactId: 'count',
      percentage: 25,
      maximumBalance: 999999);
  test(
      'scoped JSONL refuses alias conflicts exactly like direct API without mutation',
      () async {
    final setup = await _DefeatJsonlSetup.create();
    addTearDown(setup.dispose);
    final file = File('${setup.root.path}/project.json');
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final facts = (raw['facts'] as List).cast<Map>();
    facts.first['legacyFlagName'] = 'shared-flag';
    raw['facts'] = [
      ...facts,
      NarrativeFactDefinition(
              id: 'conflicting',
              label: 'Conflict',
              legacyFlagName: 'shared-flag')
          .toJson()
    ];
    await file.writeAsString(jsonEncode(raw));
    final original = await file.readAsBytes();
    final project = ProjectManifest.fromJson(raw);
    expect(
        () =>
            const CampaignContentActions().updateBattleSavings(project, config),
        throwsA(isA<ValidationException>()));
    final opened =
        await setup.request('open', args: {'projectRoot': setup.root.path});
    final handle = opened.data['projectHandle']! as String;
    final scoped = await setup.request('workshop_snapshot', args: {
      'projectHandle': handle,
      'actionId': 'campaign.battle_savings.update',
      'parameters': {'battleSavings': config.toJson()}
    });
    final planned = await setup.request('plan', args: {
      'projectHandle': handle,
      'request': AuthoringRequest(
          requestId: 'conflict',
          actionId: 'campaign.battle_savings.update',
          actionVersion: 1,
          workspaceHandle: opened.data['workspaceHandle']! as String,
          parameters: {'battleSavings': config.toJson()},
          expectedRevision: scoped.data['snapshotRevision']! as String,
          idempotencyKey: 'conflict',
          extensions: const {'workshopScope': true}).toJson()
    });
    expect(planned.status, isNot(AuthoringResultStatus.success));
    expect(await file.readAsBytes(), original);
  });
  test(
      'direct canonical savings update validates typed Fact references and clears explicitly',
      () async {
    final setup = await _DefeatJsonlSetup.create();
    addTearDown(setup.dispose);
    final project = ProjectManifest.fromJson(
        jsonDecode(await File('${setup.root.path}/project.json').readAsString())
            as Map<String, dynamic>);
    final updated =
        const CampaignContentActions().updateBattleSavings(project, config);
    expect(updated.battleSavings, config);
    expect(updated.newGame, project.newGame);
    expect(
        const CampaignContentActions()
            .updateBattleSavings(updated, null)
            .battleSavings,
        isNull);
    for (final id in ['unknown', 'count']) {
      expect(
          () => const CampaignContentActions().updateBattleSavings(
              project,
              ProjectBattleSavingsConfig(
                  enabledFactId: id,
                  balanceFactId: id == 'count' ? 'after-loss' : 'count',
                  percentage: 25,
                  maximumBalance: 999999)),
          throwsA(isA<ValidationException>()));
    }
  });
  test(
      'JSONL discovers, rejects invalid refs, applies, replays, cold reopens and clears the policy',
      () async {
    final setup = await _DefeatJsonlSetup.create();
    addTearDown(setup.dispose);
    final opened =
        await setup.request('open', args: {'projectRoot': setup.root.path});
    final handle = ProjectHandle(opened.data['projectHandle']! as String);
    final workspace = opened.data['workspaceHandle']! as String;
    final descriptor = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((entry) => entry.id == 'campaign.battle_savings.update');
    expect((descriptor.extensions['battleSavings'] as Map)['percentage'],
        'integer:0..100');
    final before = await setup.snapshots.load(handle);
    final original =
        await File('${setup.root.path}/project.json').readAsBytes();
    var sequence = 0;
    Future<AuthoringResult> plan(Object? value, String revision) async {
      final scoped = await setup.request('workshop_snapshot', args: {
        'projectHandle': handle.value,
        'actionId': 'campaign.battle_savings.update',
        'parameters': {'battleSavings': value},
      });
      expect(scoped.status, AuthoringResultStatus.success);
      return setup.request('plan', args: {
        'projectHandle': handle.value,
        'request': AuthoringRequest(
            requestId: 'saving-${++sequence}',
            actionId: 'campaign.battle_savings.update',
            actionVersion: 1,
            workspaceHandle: workspace,
            parameters: {'battleSavings': value},
            expectedRevision: scoped.data['snapshotRevision']! as String,
            idempotencyKey: 'saving-$sequence',
            extensions: const {'workshopScope': true}).toJson(),
      });
    }

    for (final value in [
      {...config.toJson(), 'enabledFactId': 'unknown'},
      {...config.toJson(), 'enabledFactId': 'count'},
      {...config.toJson(), 'percentage': 101},
      {...config.toJson(), 'enabledFactId': ''}
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
    expect(cold.manifest.battleSavings, config);
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
    expect(cleared.battleSavings, isNull);
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
    final taskRoot =
        Directory('/Users/karim/Library/Caches/AveluneQA/battle-savings');
    await taskRoot.create(recursive: true);
    final root = await taskRoot.createTemp('jsonl-');
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
      name: 'Battle savings',
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

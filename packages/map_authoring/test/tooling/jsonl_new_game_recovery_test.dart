import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const point = ProjectNewGameRecoveryPoint(
      mapId: 'beta', position: GridPos(x: 0, y: 1), facing: EntityFacing.west);
  const config = ProjectNewGameConfig(
      enabled: true, startMapId: 'alpha', initialRecoveryPoint: point);
  test('direct authoring validates recovery using the declared map snapshot',
      () async {
    final setup = await _RecoveryJsonlSetup.create();
    addTearDown(setup.dispose);
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await File('${setup.root.path}/project.json').readAsString())
            as Map<String, dynamic>);
    const target =
        MapData(id: 'beta', name: 'Beta', size: GridSize(width: 3, height: 3));
    final updated = const CampaignContentActions()
        .updateNewGame(manifest, config, maps: [target]);
    expect(updated.newGame.initialRecoveryPoint, point);
    expect(() => const CampaignContentActions().updateNewGame(manifest, config),
        throwsA(isA<ValidationException>()));
    expect(
        () => const CampaignContentActions().updateNewGame(manifest, config,
            maps: [target.copyWith(size: const GridSize(width: 1, height: 1))]),
        throwsA(isA<ValidationException>()));
  });
  test(
      'JSONL discovers, refuses invalid points, applies, replays, reopens recovery',
      () async {
    final setup = await _RecoveryJsonlSetup.create();
    addTearDown(setup.dispose);
    final opened =
        await setup.request('open', args: {'projectRoot': setup.root.path});
    final handle = ProjectHandle(opened.data['projectHandle']! as String);
    final workspace = opened.data['workspaceHandle']! as String;
    final descriptor = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((action) => action.id == 'campaign.new_game.update');
    expect(
        (descriptor.extensions['initialRecoveryPoint']
            as Map)['preservesEntrySpawn'],
        isTrue);
    final before = await setup.snapshots.load(handle);
    final original =
        await File('${setup.root.path}/project.json').readAsBytes();
    var sequence = 0;
    Future<AuthoringResult> plan(Map<String, dynamic> newGame) =>
        setup.request('plan', args: {
          'projectHandle': handle.value,
          'request': AuthoringRequest(
                  requestId: 'recovery-${++sequence}',
                  actionId: 'campaign.new_game.update',
                  actionVersion: 1,
                  workspaceHandle: workspace,
                  parameters: {'newGame': newGame},
                  expectedRevision: before.revision,
                  idempotencyKey: 'recovery-$sequence')
              .toJson(),
        });
    for (final invalid in [
      {...point.toJson(), 'mapId': 'missing'},
      {
        ...point.toJson(),
        'position': {'x': 3, 'y': 1}
      },
      {...point.toJson(), 'facing': 'diagonal'},
      {...point.toJson(), 'metadata': {}},
    ]) {
      final failed =
          await plan({...config.toJson(), 'initialRecoveryPoint': invalid});
      expect(failed.status, isNot(AuthoringResultStatus.success));
      expect(jsonEncode(failed.toJson()), isNot(contains('worker.internal')));
      expect(await File('${setup.root.path}/project.json').readAsBytes(),
          original);
    }
    final prepared = await plan(config.toJson());
    expect(prepared.status, AuthoringResultStatus.success,
        reason: prepared.toJson().toString());
    final args = {
      'projectHandle': handle.value,
      'planId': prepared.data['planId'],
      'operationId': 'recovery-apply'
    };
    final applied = await setup.request('apply', args: args);
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    final saved = await File('${setup.root.path}/project.json').readAsBytes();
    expect(
        ProjectManifest.fromJson(
                jsonDecode(utf8.decode(saved)) as Map<String, dynamic>)
            .newGame,
        config);
    expect((await setup.request('apply', args: args)).status,
        AuthoringResultStatus.success);
    expect(await File('${setup.root.path}/project.json').readAsBytes(), saved);
    final reopened =
        await setup.request('open', args: {'projectRoot': setup.root.path});
    final cold = await setup.snapshots
        .load(ProjectHandle(reopened.data['projectHandle']! as String));
    expect(cold.manifest.newGame.initialRecoveryPoint, point);
  });
}

final class _RecoveryJsonlSetup {
  const _RecoveryJsonlSetup({
    required this.root,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_RecoveryJsonlSetup> create() async {
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
    const manifest = ProjectManifest(
      name: 'JSONL connection fixture',
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
    return _RecoveryJsonlSetup(
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

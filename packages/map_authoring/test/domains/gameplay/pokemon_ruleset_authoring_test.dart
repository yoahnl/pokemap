import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('rejects the active project ruleset through direct and JSONL', () async {
    final direct = await _RulesetHarness.create('direct');
    final jsonl = await _RulesetHarness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);
    final directBefore = await direct.projectJson();
    final jsonlBefore = await jsonl.projectJson();

    await expectLater(
      direct.planCurrentProfile(),
      throwsA(
        isA<PokemonRulesetAuthoringException>().having(
          (error) => error.code,
          'code',
          'pokemon.ruleset.no_change',
        ),
      ),
    );
    final jsonlResult = await jsonl.planCurrentProfileJsonl();

    expect(jsonlResult.status, AuthoringResultStatus.failure);
    expect(
      jsonlResult.error?.details['domainCode'],
      'pokemon.ruleset.no_change',
    );
    expect(await direct.projectJson(), directBefore);
    expect(await jsonl.projectJson(), jsonlBefore);
  });

  test('canonical dispatcher exposes the versioned Pokemon ruleset action', () {
    final descriptor = MapMutationDispatcher.canonical()
        .descriptors
        .singleWhere((entry) => entry.id == 'pokemon.ruleset.set');

    expect(descriptor.version, 1);
    expect(descriptor.resourceKinds, contains('pokemonRuleset'));
  });

  test('rejects an invalid profile before writing the project', () async {
    final harness = await _RulesetHarness.create('invalid');
    addTearDown(harness.dispose);
    final before = await harness.projectJson();

    await expectLater(
      harness.planInvalidProfile(),
      throwsA(isA<PokemonRulesetAuthoringException>()),
    );

    expect(await harness.projectJson(), before);
  });

  test('rejects a stale project revision before writing the project', () async {
    final harness = await _RulesetHarness.create('stale');
    addTearDown(harness.dispose);
    final before = await harness.projectJson();

    await expectLater(
      harness.planStaleRevision(),
      throwsA(isA<AuthoringPlanException>()),
    );

    expect(await harness.projectJson(), before);
  });
}

final class _RulesetHarness {
  _RulesetHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_RulesetHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemon-ruleset-$suffix-',
    );
    final json = const ProjectManifest(
      name: 'Pokemon ruleset fixture',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    ).toJson();
    await File('${root.path}/project.json').writeAsString(jsonEncode(json));

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
    return _RulesetHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<void> planCurrentProfile() async {
    await _planDirect();
  }

  Future<AuthoringResult> planCurrentProfileJsonl() async {
    final opened = await _wireRequest(
      worker,
      'open',
      args: <String, Object?>{'projectRoot': root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    return _wireRequest(
      worker,
      'plan',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'request': _request(
          workspaceHandle: workspaceHandle,
          revision: snapshot.revision,
          suffix: 'jsonl',
        ).toJson(),
      },
    );
  }

  Future<void> planInvalidProfile() async {
    final profile = PokemonRulesetProfile.pokeMapBetaV1.toJson()
      ..['speedTiePolicyId'] = 'unknown-policy';
    await _planDirect(profile: profile);
  }

  Future<void> planStaleRevision() async {
    await _planDirect(staleRevision: true);
  }

  Future<void> _planDirect({
    Map<String, dynamic>? profile,
    bool staleRevision = false,
  }) async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    final revision = staleRevision
        ? '${snapshot.revision.substring(0, snapshot.revision.length - 1)}'
            '${snapshot.revision.endsWith('0') ? '1' : '0'}'
        : snapshot.revision;
    await mutations.plan(
      opened.projectHandle,
      _request(
        workspaceHandle: opened.workspaceHandle.value,
        revision: revision,
        suffix: staleRevision ? 'stale' : 'invalid',
        profile: profile,
      ),
    );
  }

  AuthoringRequest _request({
    required String workspaceHandle,
    required String revision,
    required String suffix,
    Map<String, dynamic>? profile,
  }) {
    return AuthoringRequest(
      requestId: 'pokemon-ruleset-$suffix',
      actionId: 'pokemon.ruleset.set',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: <String, Object?>{
        'profile': profile ?? PokemonRulesetProfile.pokeMapBetaV1.toJson(),
      },
      expectedRevision: revision,
      idempotencyKey: 'pokemon-ruleset-$suffix',
      dryRun: false,
    );
  }

  Future<Map<String, dynamic>> projectJson() async {
    return jsonDecode(await File('${root.path}/project.json').readAsString())
        as Map<String, dynamic>;
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<AuthoringResult> _wireRequest(
  JsonlWorker worker,
  String command, {
  Map<String, Object?> args = const <String, Object?>{},
}) async {
  final response = await worker.processLine(
    jsonEncode(<String, Object?>{
      'id': 'pokemon-ruleset-$command',
      'command': command,
      'args': args,
    }),
  );
  return AuthoringResult.fromJson(
    jsonDecode(response) as Map<String, dynamic>,
  );
}

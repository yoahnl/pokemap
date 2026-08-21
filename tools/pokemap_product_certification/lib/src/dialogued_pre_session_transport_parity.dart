import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/authoring_transport.dart';
import 'package:path/path.dart' as p;

import 'dialogued_pre_session_fixture.dart';
import 'neutral_certification_game_fixture.dart';

/// The four transports BETA-CIN-083 requires the fixture to agree on.
enum DialoguedPreSessionTransport {
  directApi('directApi'),
  jsonl('jsonl'),
  editor('editor'),
  mcp('mcp');

  const DialoguedPreSessionTransport(this.wireName);

  final String wireName;
}

/// What one transport produced.
final class DialoguedPreSessionTransportRun {
  const DialoguedPreSessionTransportRun({
    required this.transport,
    required this.appliedActionIds,
    required this.project,
  });

  final DialoguedPreSessionTransport transport;
  final List<String> appliedActionIds;

  /// The decoded project, so a comparison is semantic rather than a byte diff
  /// that whitespace or key order could break for the wrong reason.
  final ProjectManifest project;
}

/// Replays the declared authoring sequence over every transport.
///
/// The sequence itself lives in [DialoguedPreSessionFixture]; nothing here
/// knows what is being authored. That separation is what makes the comparison
/// worth anything: four hand-written scripts could agree with each other and
/// still all be wrong, whereas one list replayed four ways can only disagree if
/// a transport actually behaves differently.
final class DialoguedPreSessionTransportParity {
  const DialoguedPreSessionTransportParity();

  /// MCP needs the packaged server built, exactly as the Item collector does.
  /// Absence is reported, never silently skipped.
  static bool mcpRunnerIsBuilt(Directory mcpPackageRoot) =>
      File(p.join(mcpPackageRoot.path, 'dist/src/authoring_sequence_runner.js'))
          .existsSync() &&
      File(p.join(mcpPackageRoot.path, 'dist/src/index.js')).existsSync();

  Future<DialoguedPreSessionTransportRun> run(
    DialoguedPreSessionTransport transport, {
    required Directory workRoot,
    Directory? mcpPackageRoot,
  }) async {
    final projectRoot = Directory(
      p.join(workRoot.path, transport.wireName),
    );
    await const NeutralCertificationGameFixture(dialoguedPreSession: true)
        .writeAuthorWorkspace(projectRoot);
    final steps = const DialoguedPreSessionFixture().steps;

    final appliedActionIds = switch (transport) {
      DialoguedPreSessionTransport.directApi =>
        await _runLocal(projectRoot, steps, useJsonl: false),
      DialoguedPreSessionTransport.jsonl =>
        await _runLocal(projectRoot, steps, useJsonl: true),
      DialoguedPreSessionTransport.editor =>
        await _runEditor(projectRoot, steps),
      DialoguedPreSessionTransport.mcp => await _runMcp(
          projectRoot,
          steps,
          mcpPackageRoot: ArgumentError.checkNotNull(
            mcpPackageRoot,
            'mcpPackageRoot',
          ),
        ),
    };

    return DialoguedPreSessionTransportRun(
      transport: transport,
      appliedActionIds: appliedActionIds,
      project: ProjectManifest.fromJson(
        jsonDecode(
          await File(p.join(projectRoot.path, 'project.json')).readAsString(),
        ) as Map<String, dynamic>,
      ),
    );
  }

  Future<List<String>> _runLocal(
    Directory projectRoot,
    List<DialoguedPreSessionAuthoringStep> steps, {
    required bool useJsonl,
  }) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[projectRoot.path],
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
    final worker = JsonlWorker(api: readApi, mutations: mutations);

    var line = 0;
    Future<Map<String, Object?>> success(
      String command,
      Map<String, Object?> args,
    ) async {
      line += 1;
      final result = AuthoringResult.fromJson(
        jsonDecode(
          await worker.processLine(
            jsonEncode(<String, Object?>{
              'id': 'cin083-$command-$line',
              'command': command,
              'args': args,
            }),
          ),
        ) as Map<String, dynamic>,
      );
      if (result.error != null) {
        throw StateError('JSONL $command failed: ${result.error}');
      }
      return result.data;
    }

    final opened = useJsonl
        ? await success('open', <String, Object?>{
            'projectRoot': projectRoot.path,
          })
        : await readApi.open(projectRoot.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    if (!useJsonl) {
      await mutations.attachProject(
        projectRootPath: projectRoot.path,
        workspaceHandle: workspace,
        projectHandle: project,
      );
    }

    Future<String> revision() async => useJsonl
        ? (await success('validate', <String, Object?>{
            'projectHandle': project.value,
          }))['snapshotRevision']! as String
        : (await snapshots.load(project)).revision;

    final applied = <String>[];
    for (final (index, step) in steps.indexed) {
      final request = _request(workspace.value, await revision(), index, step);
      final plan = useJsonl
          ? await success('plan', <String, Object?>{
              'projectHandle': project.value,
              'request': request.toJson(),
            })
          : await mutations.plan(project, request);
      final response = useJsonl
          ? await success('apply', <String, Object?>{
              'projectHandle': project.value,
              'planId': plan['planId'],
              'operationId': 'cin083-$index',
            })
          : await mutations.apply(
              project,
              planId: plan['planId']! as String,
              operationId: 'cin083-$index',
            );
      applied.add(
        (response['receipt']! as Map)['actionId']! as String,
      );
    }
    return applied;
  }

  Future<List<String>> _runEditor(
    Directory projectRoot,
    List<DialoguedPreSessionAuthoringStep> steps,
  ) async {
    const reader = LocalProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: _FixedProjectRoot(projectRoot.path),
    );
    var revision = (await queries.open(projectRoot.path)).snapshotRevision;
    final applied = <String>[];
    for (final (index, step) in steps.indexed) {
      final plan = await mutations.plan(
        projectRoot.path,
        actionId: step.actionId,
        parameters: step.parameters,
        idempotencyKey: 'cin083-editor-$index',
        expectedRevision: revision,
      );
      final result = await mutations.apply(
        plan,
        operationId: 'cin083-editor-$index',
      );
      applied.add(result.receipt.actionId);
      revision = result.snapshotRevision;
    }
    return applied;
  }

  Future<List<String>> _runMcp(
    Directory projectRoot,
    List<DialoguedPreSessionAuthoringStep> steps, {
    required Directory mcpPackageRoot,
  }) async {
    if (!mcpRunnerIsBuilt(mcpPackageRoot)) {
      throw StateError(
        'The packaged MCP authoring sequence runner has not been built.',
      );
    }
    final actionsFile = File(p.join(projectRoot.parent.path, 'mcp-actions.json'))
      ..writeAsStringSync(
        jsonEncode(<Object?>[
          for (final step in steps)
            <String, Object?>{
              'actionId': step.actionId,
              'parameters': step.parameters,
            },
        ]),
        flush: true,
      );
    final projectOut = p.join(projectRoot.parent.path, 'mcp-project.json');
    // `node`, never Platform.resolvedExecutable: inside a flutter test that
    // resolves to flutter_tester, which happily accepts a .js path and then
    // hangs forever instead of failing.
    final result = await Process.run('node', <String>[
      p.join(mcpPackageRoot.path, 'dist/src/authoring_sequence_runner.js'),
      '--project-root',
      projectRoot.path,
      '--server',
      p.join(mcpPackageRoot.path, 'dist/src/index.js'),
      '--actions',
      actionsFile.path,
      '--project-out',
      projectOut,
    ]);
    if (result.exitCode != 0) {
      throw StateError('The MCP sequence runner failed: ${result.stderr}');
    }
    // The runner works on its own copy, so the project it produced replaces
    // this transport's workspace before the comparison reads it.
    await File(projectOut).copy(p.join(projectRoot.path, 'project.json'));
    final summary = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    return <String>[
      for (final id in summary['appliedActionIds']! as List) id as String,
    ];
  }

  static AuthoringRequest _request(
    String workspace,
    String revision,
    int index,
    DialoguedPreSessionAuthoringStep step,
  ) =>
      AuthoringRequest(
        requestId: 'cin083-request-$index',
        actionId: step.actionId,
        actionVersion: 1,
        workspaceHandle: workspace,
        parameters: step.parameters,
        expectedRevision: revision,
        idempotencyKey: 'cin083-idempotency-$index',
      );
}

final class _FixedProjectRoot implements EditorProjectRootLocator {
  const _FixedProjectRoot(this.path);

  final String path;

  @override
  Future<String> locateForResource(String resourcePath) async => path;
}

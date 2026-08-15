import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('template list and instantiation keep direct and JSONL parity',
      () async {
    final direct = await _Harness.create('direct');
    final jsonl = await _Harness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directResult = await direct.runDirect();
    final jsonlResult = await jsonl.runJsonl();

    expect(directResult.templates, jsonlResult.templates);
    expect(directResult.templates['totalAvailable'], 6);
    expect(directResult.cinematic, jsonlResult.cinematic);
    expect(
      ((directResult.cinematic['items']! as List<Object?>).single
          as Map<Object?, Object?>)['id'],
      'opening',
    );
    expect(
      directResult.unknownTemplateDomainCode,
      'presentation_cinematic_template.unknown',
    );
    expect(
      jsonlResult.unknownTemplateDomainCode,
      directResult.unknownTemplateDomainCode,
    );
  });
}

final class _Harness {
  _Harness._({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_Harness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_presentation_template_$suffix',
    );
    final manifest = ProjectManifest(
      name: 'Presentation template transport fixture',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
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
    return _Harness._(
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

  Future<_FlowResult> runDirect() async {
    final opened = await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final templates = await readApi.query(project, _templateQuery());
    final snapshot = await snapshots.load(project);
    final plan = await mutations.plan(
      project,
      _request(workspace.value, snapshot.revision),
    );
    await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'instantiate-presentation-template',
    );
    final cinematic = await readApi.query(project, _cinematicQuery());
    return _FlowResult(
      templates: templates,
      cinematic: cinematic,
      unknownTemplateDomainCode: await _directUnknownCode(
        project,
        workspace.value,
      ),
    );
  }

  Future<_FlowResult> runJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    final validated = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final templates = await _jsonl('query', <String, Object?>{
      'projectHandle': project,
      'request': _templateQuery().toJson(),
    });
    final plan = await _jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        validated['snapshotRevision']! as String,
      ).toJson(),
    });
    await _jsonl('apply', <String, Object?>{
      'projectHandle': project,
      'planId': plan['planId'],
      'operationId': 'instantiate-presentation-template',
    });
    final cinematic = await _jsonl('query', <String, Object?>{
      'projectHandle': project,
      'request': _cinematicQuery().toJson(),
    });
    final latest = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final unknown = await _jsonlResult('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        latest['snapshotRevision']! as String,
        templateId: 'unknown',
        cinematicId: 'unknown-template',
      ).toJson(),
    });
    return _FlowResult(
      templates: templates,
      cinematic: cinematic,
      unknownTemplateDomainCode:
          unknown.error!.details['domainCode']! as String,
    );
  }

  Future<String> _directUnknownCode(
    ProjectHandle project,
    String workspace,
  ) async {
    final snapshot = await snapshots.load(project);
    try {
      await mutations.plan(
        project,
        _request(
          workspace,
          snapshot.revision,
          templateId: 'unknown',
          cinematicId: 'unknown-template',
        ),
      );
    } on PresentationCinematicTemplateAuthoringException catch (error) {
      return error.code;
    }
    throw StateError('The unknown Presentation template was accepted.');
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final result = await _jsonlResult(command, args);
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: result.error?.toJson().toString(),
    );
    return result.data;
  }

  Future<AuthoringResult> _jsonlResult(
    String command,
    Map<String, Object?> args,
  ) async =>
      AuthoringResult.fromJson(
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

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _FlowResult {
  const _FlowResult({
    required this.templates,
    required this.cinematic,
    required this.unknownTemplateDomainCode,
  });

  final Map<String, Object?> templates;
  final Map<String, Object?> cinematic;
  final String unknownTemplateDomainCode;
}

AuthoringRequest _request(
  String workspaceHandle,
  String revision, {
  String templateId = 'interactivePath',
  String cinematicId = 'opening',
}) =>
    AuthoringRequest(
      requestId: 'request-template-$cinematicId',
      actionId: 'presentationCinematicTemplate.instantiate',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: <String, Object?>{
        'templateId': templateId,
        'templateVersion': 1,
        'cinematicId': cinematicId,
        'title': 'Opening',
        'description': 'A responsive opening',
      },
      expectedRevision: revision,
      idempotencyKey: 'idempotency-template-$cinematicId',
    );

AuthoringQueryRequest _templateQuery() => AuthoringQueryRequest(
      resourceKind: 'presentationCinematicTemplate',
      operation: AuthoringQueryOperation.list,
      view: AuthoringQueryView.detail,
      pageSize: 10,
    );

AuthoringQueryRequest _cinematicQuery() => AuthoringQueryRequest(
      resourceKind: 'presentationCinematic',
      operation: AuthoringQueryOperation.get,
      ids: const <String>['opening'],
      view: AuthoringQueryView.detail,
    );

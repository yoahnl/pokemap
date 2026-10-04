import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_information_actions_test.dart' show informationFixture;

ProjectManifest smartInformationFixture() {
  final preset = ProjectSmartTilePreset(
    id: 'ground',
    name: 'Sol',
    categoryId: 'shared',
    usage: SmartTileUsage.terrain,
    topology: SmartTileTopology.uniform,
    templateHint: SmartTileTemplateHint.simple,
    status: SmartTilePresetStatus.published,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile:
        const SmartTileCoverageProfile(mode: SmartTileCoverageMode.template),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'material',
    allowedMaterialIds: const ['material'],
    rules: const [
      SmartTileRule(
          id: 'base',
          centerMatch: SmartTileSlotMatch.material('material'),
          signature: SmartTileSignature(),
          candidates: [
            SmartTileCandidate(id: 'base', parts: [
              SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                          atlasId: 'atlas', column: 0, row: 0)))
            ])
          ])
    ],
    tags: const ['préservé'],
  );
  return informationFixture().copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
    categories: const [
      ProjectSmartTileCategory(id: 'shared', name: 'Terrains')
    ],
    atlases: const [
      ProjectSmartTileAtlas(
          id: 'atlas', name: 'Atlas', tilesetId: 'sheet', columns: 2, rows: 2)
    ],
    materials: const [
      ProjectSmartTileMaterial(
          id: 'material', name: 'Herbe', connectionGroupId: 'ground')
    ],
    presets: [preset],
    drafts: const [
      ProjectSmartTileAuthoringDraft(
          id: 'editing',
          targetPresetId: 'ground',
          sourcePresetId: 'ground',
          name: 'Mon brouillon non publié',
          categoryId: 'shared',
          usage: SmartTileUsage.terrain,
          lastStage: SmartTileAuthoringStage.usage)
    ],
  ));
}

final class ResourceInformationFixture {
  ResourceInformationFixture(this.root, this.snapshots, this.worker,
      this.project, this.workspace, this.mutations);

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  final String project;
  final String workspace;
  final LocalMapAuthoringMutationApi mutations;
  int next = 0;

  static Future<ResourceInformationFixture> create(
      ProjectManifest manifest) async {
    final root = await Directory.systemTemp.createTemp('uwu3-information-');
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final read = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final worker = JsonlWorker(api: read, mutations: mutations);
    final opened = AuthoringResult.fromJson(
        jsonDecode(await worker.processLine(jsonEncode({
      'id': 'open',
      'command': 'open',
      'args': {'projectRoot': root.path}
    }))));
    expect(opened.status, AuthoringResultStatus.success);
    return ResourceInformationFixture(
        root,
        snapshots,
        worker,
        opened.data['projectHandle']! as String,
        opened.data['workspaceHandle']! as String,
        mutations);
  }

  Future<AuthoringResult> command(
          String command, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
          {'id': 'request-${next++}', 'command': command, 'args': args}))));

  Future<AuthoringResult> plan(
      String action, Map<String, Object?> parameters) async {
    final snapshot = await snapshots.load(ProjectHandle(project));
    return command('plan', {
      'projectHandle': project,
      'request': AuthoringRequest(
        requestId: 'request-${next++}',
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'key-${next++}',
      ).toJson()
    });
  }

  Future<AuthoringResult> apply(AuthoringResult plan, {String? operation}) =>
      command('apply', {
        'projectHandle': project,
        'planId': plan.data['planId'],
        'operationId': operation ?? 'apply-${next++}'
      });

  Future<AuthoringResult> mutate(
      String action, Map<String, Object?> parameters) async {
    final planned = await plan(action, parameters);
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    final applied = await apply(planned);
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    return applied;
  }

  Future<ProjectManifest> read() async => ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString()));

  Future<void> dispose() async {
    await command('close', {'projectHandle': project});
    await root.delete(recursive: true);
  }
}

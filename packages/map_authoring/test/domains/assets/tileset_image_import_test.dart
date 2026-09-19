import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL discovers, stages, plans, applies and reopens image import',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final described = await fixture.request('describe');
    expect(jsonEncode(described.toJson()), contains('tileset.import_image'));
    final plan = await fixture.plan();
    expect(plan.status, AuthoringResultStatus.success);
    final before = await fixture.projectFile.readAsBytes();
    expect(await File('${fixture.root.path}/assets/studio/trees.png').exists(),
        isFalse);
    final applied = await fixture.apply(plan);
    expect(applied.status, AuthoringResultStatus.success);
    final snapshot = await fixture.snapshots.load(fixture.project);
    final tileset = snapshot.manifest.tilesets.single;
    expect(tileset.id, 'trees');
    expect(
        await File('${fixture.root.path}/${tileset.relativePath}')
            .readAsBytes(),
        _png);
    expect(await fixture.projectFile.readAsBytes(), isNot(before));
    expect(snapshot.maps, isEmpty);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8.decode(
      snapshot.resourceBytes(assetCatalogResourceIdentity),
    )) as Map<String, dynamic>);
    expect(catalog.records.single.logicalPath, tileset.relativePath);
  });

  test('image import preflight rejects invalid geometry without publishing',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final before = await fixture.projectFile.readAsBytes();
    final result = await fixture.plan(tileWidth: 2);
    expect(result.status, AuthoringResultStatus.failure);
    expect(await fixture.projectFile.readAsBytes(), before);
    expect(await Directory('${fixture.root.path}/assets').exists(), isFalse);
  });

  test('concurrent manifest update between plan and apply is never overwritten',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final plan = await fixture.plan();
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await fixture.projectFile.readAsString())
            as Map<String, dynamic>);
    await fixture.projectFile.writeAsString(
        jsonEncode(manifest.copyWith(name: 'External').toJson()));
    final external = await fixture.projectFile.readAsBytes();
    final result = await fixture.apply(plan);
    expect(result.status, AuthoringResultStatus.failure);
    expect(await fixture.projectFile.readAsBytes(), external);
    expect(await Directory('${fixture.root.path}/assets').exists(), isFalse);
  });

  test(
      'interrupted publication resumes its journal without losing source or maps',
      () async {
    final fixture = await _Fixture.create(failAfterPromotion: true);
    addTearDown(fixture.dispose);
    final before = await fixture.projectFile.readAsBytes();
    final plan = await fixture.plan();
    final result = await fixture.apply(plan);
    expect(result.status, AuthoringResultStatus.failure);
    expect(await fixture.projectFile.readAsBytes(), before);
    final recovered = await fixture.request('recover', {
      'projectHandle': fixture.project.value,
      'operationId': fixture.lastOperation,
    });
    expect(recovered.status, AuthoringResultStatus.success);
    expect(
        await File('${fixture.root.path}/assets/studio/trees.png')
            .readAsBytes(),
        _png);
    expect(
        (await fixture.snapshots.load(fixture.project))
            .manifest
            .tilesets
            .single
            .id,
        'trees');
  });

  test('element category creation validates geometry in the same transaction',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    expect((await fixture.apply(await fixture.plan())).status,
        AuthoringResultStatus.success);
    final before = await fixture.projectFile.readAsBytes();
    final result = await fixture.planAction('element.upsert', {
      'category':
          const ProjectElementCategory(id: 'decor', name: 'Décors').toJson(),
      'element': const ProjectElementEntry(
        id: 'tree',
        name: 'Arbre',
        tilesetId: 'trees',
        categoryId: 'decor',
        frames: [
          TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1))
        ],
      ).toJson(),
    });
    expect(result.status, AuthoringResultStatus.failure);
    expect(await fixture.projectFile.readAsBytes(), before);
  });
}

final class _Fixture {
  _Fixture(
      this.root, this.snapshots, this.worker, this.project, this.workspace);

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  int sequence = 0;
  String? lastOperation;

  File get projectFile => File('${root.path}/project.json');

  static Future<_Fixture> create({bool failAfterPromotion = false}) async {
    final root = await Directory.systemTemp.createTemp('tileset-image-import-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      ProjectManifest(name: 'Image import', maps: [], tilesets: []).toJson(),
    ));
    await File('${root.path}/input.png').writeAsBytes(_png);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final readApi =
        AuthoringReadApi(openService: opener, snapshotLoader: snapshots);
    final artifacts = LocalArtifactStore(
        allowedSourceRoots: [root.path], maximumArtifactBytes: 1024);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
      faultInjector: failAfterPromotion
          ? (context) {
              if (context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
                throw const FileSystemException('Injected write failure');
              }
            }
          : null,
    );
    final opened = await opener.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(
        root,
        snapshots,
        JsonlWorker(api: readApi, mutations: mutations),
        opened.projectHandle,
        opened.workspaceHandle);
  }

  Future<AuthoringResult> request(String command,
      [Map<String, Object?> args = const {}]) async {
    final response = await worker.processLine(jsonEncode({
      'id': 'request-${sequence++}',
      'command': command,
      'args': args,
    }));
    return AuthoringResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>);
  }

  Future<AuthoringResult> plan({int tileWidth = 1}) async {
    final staged = await request(
        'stage_artifact', {'sourcePath': '${root.path}/input.png'});
    expect(staged.status, AuthoringResultStatus.success);
    return planAction('tileset.import_image', {
      'artifactHandle': staged.data['artifactHandle'],
      'tilesetId': 'trees',
      'name': 'Arbres',
      'tileWidth': tileWidth,
      'tileHeight': 1,
    });
  }

  Future<AuthoringResult> planAction(
      String action, Map<String, Object?> parameters) async {
    final snapshot = await snapshots.load(project);
    return request('plan', {
      'projectHandle': project.value,
      'request': AuthoringRequest(
        requestId: 'plan-${sequence++}',
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'operation-${sequence++}',
      ).toJson(),
    });
  }

  Future<AuthoringResult> apply(AuthoringResult plan) {
    lastOperation = 'apply-${sequence++}';
    return request('apply', {
      'projectHandle': project.value,
      'planId': plan.data['planId'],
      'operationId': lastOperation,
    });
  }

  Future<void> dispose() => root.delete(recursive: true);
}

final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLttAAAAABJRU5ErkJggg==');

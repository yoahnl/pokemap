import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('released local PNG staging rejects planning without publication',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final staged = await fixture.api.stageArtifactFile(
        sourcePath: fixture.source.path, declaredMediaType: 'image/png');
    final handle = staged.reference.handle;
    final before = await fixture.manifest.readAsBytes();
    expect(fixture.artifacts.inspect(handle), isNotNull);
    expect(await fixture.artifacts.release(handle), true);
    expect(fixture.artifacts.inspect(handle), isNull);
    await expectLater(
        fixture.plan(handle),
        throwsA(isA<AssetActionException>().having(
            (failure) => failure.code, 'domainCode', 'artifact.unknown')));
    expect(await fixture.manifest.readAsBytes(), before);
    expect(await fixture.destination.exists(), false);
    expect(await File('${fixture.root.path}/.pokemap/assets.json').exists(),
        false);
    expect(handle, staged.reference.handle);
    expect(await fixture.source.readAsBytes(), fixture.png);
  });

  test('prepared asset plan retains frozen PNG after staging release',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final staged = await fixture.api.stageArtifactFile(
        sourcePath: fixture.source.path, declaredMediaType: 'image/png');
    final plan = await fixture.plan(staged.reference.handle);
    expect(await fixture.destination.exists(), false);
    expect(await fixture.artifacts.release(staged.reference.handle), true);
    expect(fixture.artifacts.inspect(staged.reference.handle), isNull);
    final result = await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: plan.planId, operationId: 'frozen-local-png');
    expect(result.receipt.status, AuthoringReceiptStatus.applied);
    expect(await fixture.destination.readAsBytes(), fixture.png);
    final snapshot = await fixture.snapshots.load(fixture.opened.projectHandle);
    final catalog = AssetCatalog.fromJson(
        jsonDecode(utf8.decode(snapshot.resourceBytes('assetCatalog'))));
    expect(catalog.records.single.id, 'picture');
    expect(catalog.records.single.artifact.handle, staged.reference.handle);
  });
}

final class _Fixture {
  _Fixture(this.root, this.png, this.artifacts, this.handles, this.opened,
      this.snapshots, this.api);

  final Directory root;
  final List<int> png;
  final LocalArtifactStore artifacts;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi api;
  File get source => File('${root.path}/source.png');
  File get manifest => File('${root.path}/project.json');
  File get destination => File('${root.path}/images/picture.png');

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp('uwu3-staging-life-');
    final png = image.encodePng(image.Image(width: 32, height: 32));
    await File('${root.path}/source.png').writeAsBytes(png);
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        ProjectManifest(name: 'Staging', maps: const [], tilesets: const [])
            .toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles)
        .openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final artifacts = LocalArtifactStore(
        allowedSourceRoots: [root.path], maximumArtifactBytes: 1024 * 1024);
    final api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, artifactStore: artifacts);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, png, artifacts, handles, opened, snapshots, api);
  }

  Future<AuthoringMutationPlanResult> plan(String handle) async {
    final snapshot = await snapshots.load(opened.projectHandle);
    return api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'staging-lifetime',
            actionId: 'asset.import',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: {
              'artifactHandle': handle,
              'assetId': 'picture',
              'logicalPath': 'images/picture.png',
            },
            expectedRevision: snapshot.revision,
            idempotencyKey: 'staging-lifetime'));
  }

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

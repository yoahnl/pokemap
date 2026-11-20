import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/reliability_map_fixture.dart' show ReliabilityCountingReader;
import '../support/tileset_regrid_fixture.dart' show writeTilesetRegridFixture;

void main() {
  test('plans and publishes one unused grid with bounded reads', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    await fixture.prepare();
    final revision = (await fixture.tileset('sheet')).snapshotRevision;
    final head = await fixture.readHead();
    final descriptor =
        await File('${fixture.root.path}/project.json').readAsBytes();
    fixture.reader.paths.clear();
    fixture.loads.clear();
    final request = fixture.request('regrid', revision);
    final planned =
        await fixture.mutations.planMutation(fixture.project, request);
    expect(planned.plan.changeSet.changes.map((change) => change.storageKey),
        ['catalog/HEAD.json']);
    final diff = planned.plan.changeSet.diff.entries
        .singleWhere((entry) => entry.path == '/tilesets/sheet/source');
    expect(diff.before, containsPair('tileWidth', 32));
    expect(diff.after, containsPair('tileWidth', 16));
    expect(diff.after, containsPair('pixelWidth', 64));
    expect(await fixture.readHead(), head);
    final applied = await fixture.mutations.applyMutation(fixture.project,
        planId: planned.planId, operationId: 'apply-grid');
    expect(fixture.loads, isEmpty);
    expect(
        fixture.reader.paths.where((path) => path.endsWith('.png')), isEmpty);
    expect(fixture.reader.paths.where((path) => path.startsWith('maps/')),
        isEmpty);
    expect(fixture.reader.paths.where(fixture.foreignPaths.contains), isEmpty);
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        descriptor);

    await fixture.reopen();
    final saved =
        (await fixture.tileset('sheet')).items.single['source'] as Map;
    expect(saved['tileWidth'], 16);
    expect(saved['tileHeight'], 16);
    expect(saved['pixelWidth'], 64);
    expect(saved['assetId'], 'asset-sheet');
    await fixture.mutations.undoMutation(fixture.project,
        entryId: applied.receipt.receiptId, idempotencyKey: 'undo-grid');
    expect((await fixture.tileset('sheet')).items.single['source'],
        containsPair('tileWidth', 32));
  });

  test('rejects missing proof, a used atlas, tile metadata and invalid sizes',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    var revision = (await fixture.tileset('sheet')).snapshotRevision;
    await expectLater(
      fixture.mutations.planMutation(
          fixture.project, fixture.request('unindexed', revision)),
      throwsA(isA<CatalogStorageException>().having((error) => error.code,
          'code', 'catalog.resource_usage.preparation_required')),
    );
    await fixture.prepare();
    revision = (await fixture.tileset('sheet')).snapshotRevision;
    final head = await fixture.readHead();
    for (final (id, code) in [
      ('used', 'catalog.definition_in_use'),
      ('tagged', 'tileset.regrid_local_uses'),
      ('legacy', 'tileset.atlas_missing'),
    ]) {
      await expectLater(
        fixture.mutations.planMutation(fixture.project,
            fixture.request('blocked-$id', revision, tilesetId: id)),
        throwsA(isA<MapAuthoringException>()
            .having((error) => error.code, 'code', code)),
      );
    }
    await expectLater(
      fixture.mutations.planMutation(fixture.project,
          fixture.request('oversize', revision, tileWidth: 65)),
      throwsA(isA<MapAuthoringException>()
          .having((error) => error.code, 'code', 'tileset.grid_invalid')),
    );
    expect(await fixture.readHead(), head);
  });

  test('JSONL rejects a plan when a map starts to use the atlas', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    await fixture.prepare();
    final revision = (await fixture.tileset('sheet')).snapshotRevision;
    final worker = JsonlWorker(api: fixture.api, mutations: fixture.mutations);
    final planned = await _command(worker, 'plan', {
      'projectHandle': fixture.project.value,
      'request': fixture.request('stale-grid', revision).toJson(),
    });
    final queried = await fixture.api.queryProject(
        fixture.project,
        AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: const ['garden']));
    final map = MapData.fromJson(Map<String, dynamic>.from(queried.items.single)
      ..remove('resourceKind')
      ..remove('revision'));
    final save = await fixture.mutations.planMutation(
        fixture.project,
        AuthoringRequest(
          requestId: 'map-uses-grid',
          actionId: 'map.save',
          actionVersion: 1,
          workspaceHandle: fixture.opened.workspaceHandle.value,
          expectedRevision: queried.snapshotRevision,
          idempotencyKey: 'map-uses-grid',
          parameters: {'map': map.copyWith(tilesetId: 'sheet').toJson()},
        ));
    await fixture.mutations.applyMutation(fixture.project,
        planId: save.planId, operationId: 'edit-map-uses-grid');
    final head = await fixture.readHead();
    final refusal = jsonDecode(await worker.processLine(jsonEncode({
      'id': 'apply-stale-grid',
      'command': 'apply',
      'args': {
        'projectHandle': fixture.project.value,
        'planId': planned['planId'],
        'operationId': 'apply-stale-grid',
      },
    }))) as Map;
    expect(refusal['status'], 'failure');
    expect((refusal['error'] as Map)['details'],
        containsPair('domainCode', 'catalog.revision_conflict'));
    expect(await fixture.readHead(), head);
    final latest = await fixture.tileset('sheet');
    expect(latest.items.single['source'], containsPair('tileWidth', 32));
    await expectLater(
        fixture.mutations.planMutation(fixture.project,
            fixture.request('regrid-now-used', latest.snapshotRevision)),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'catalog.definition_in_use')));
  });
}

Future<Map<String, dynamic>> _command(
    JsonlWorker worker, String command, Map<String, Object?> args) async {
  final result = jsonDecode(await worker.processLine(
      jsonEncode({'id': command, 'command': command, 'args': args}))) as Map;
  expect(result['status'], 'success', reason: jsonEncode(result));
  return Map<String, dynamic>.from(result['data'] as Map);
}

final class _Fixture {
  _Fixture(this.root, this.reader, this.api, this.mutations, this.opened,
      this.foreignPaths, this.loads);

  final Directory root;
  final ReliabilityCountingReader reader;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  OpenedProject opened;
  final Set<String> foreignPaths;
  final List<ProjectSnapshotLoadProfile> loads;
  ProjectHandle get project => opened.projectHandle;

  static Future<_Fixture> open() async {
    final root = await Directory.systemTemp.createTemp('tileset-regrid-');
    final paths = await writeTilesetRegridFixture(root);
    final reader = ReliabilityCountingReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final loads = <ProjectSnapshotLoadProfile>[];
    final loader =
        ProjectSnapshotLoader(handles: handles, profileSink: loads.add);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: loader);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: loader, catalogFileReader: reader);
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, reader, api, mutations, opened, paths, loads);
  }

  Future<List<int>> readHead() =>
      File('${root.path}/catalog/HEAD.json').readAsBytes();

  Future<void> prepare() async {
    await mutations.prepareWorkshopCatalog(project);
    await mutations.prepareWorkshopCatalog(project, scope: 'resourceIndexes');
  }

  Future<AuthoringQueryPage> tileset(String id) => api.queryProject(
      project,
      AuthoringQueryRequest(
          resourceKind: 'tileset',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: [id]));

  AuthoringRequest request(String key, String revision,
          {String tilesetId = 'sheet', int tileWidth = 16}) =>
      AuthoringRequest(
          requestId: key,
          actionId: 'tileset.regrid',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: revision,
          idempotencyKey: key,
          parameters: {
            'tilesetId': tilesetId,
            'tileWidth': tileWidth,
            'tileHeight': 16
          });

  Future<void> reopen() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> close() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

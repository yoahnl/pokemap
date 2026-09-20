import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'draft and world placement publish atomically (${jsonl ? 'JSONL' : 'direct'})',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.file.readAsBytes();
      final asset = CinematicAsset(
          id: 'departure',
          title: 'Départ',
          timeline: CinematicTimeline(steps: [
            CinematicTimelineStep(
                id: 'wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: 1700)
          ]));
      final request = await f.request('cinematic.upsert', {
        'cinematic': asset.toJson(),
        'libraryPlacement': {'folderId': null, 'index': 0},
      });
      final described = await f.command('describe', {});
      expect(jsonEncode(described.toJson()), contains('libraryPlacement'));
      late String planId;
      if (jsonl) {
        final plan = await f.command('plan', {
          'projectHandle': f.opened.projectHandle.value,
          'request': request.toJson(),
        });
        expect(plan.status, AuthoringResultStatus.success,
            reason: jsonEncode(plan.toJson()));
        planId = plan.data['planId'] as String;
      } else {
        final plan = await f.api.planMutation(f.opened.projectHandle, request);
        expect(plan.plan.changeSet.changes.map((e) => e.storageKey),
            ['project.json']);
        planId = plan.planId;
      }
      expect(await f.file.readAsBytes(), before);
      if (jsonl) {
        final applied = await f.command('apply', {
          'projectHandle': f.opened.projectHandle.value,
          'planId': planId,
          'operationId': 'publish',
        });
        expect(applied.status, AuthoringResultStatus.success,
            reason: jsonEncode(applied.toJson()));
      } else {
        await f.api.applyMutation(f.opened.projectHandle,
            planId: planId, operationId: 'publish');
      }
      final disk = (await f.loader.load(f.opened.projectHandle)).manifest;
      expect(disk.cinematics.single, asset);
      expect(disk.cinematicLibraryCatalog.entries.single.cinematicId, asset.id);
      expect(disk.cinematicLibraryCatalog.entries.single.family,
          CinematicLibraryFamily.world);
      expect(disk.maps, isEmpty);
    });
  }

  test(
      'placement rejects v6, invalid folder and unknown fields before any write',
      () async {
    for (final version in [ProjectVersion.v6, ProjectVersion.v7]) {
      final f = await _Fixture.create(version: version);
      addTearDown(f.dispose);
      final before = await f.file.readAsBytes();
      for (final placement in [
        {'folderId': 'missing', 'index': 0},
        {'folderId': null, 'index': 0, 'unknown': true},
      ]) {
        await expectLater(
            f.api.planMutation(
                f.opened.projectHandle,
                await f.request('cinematic.upsert', {
                  'cinematic': CinematicAsset(
                          id: 'draft',
                          title: 'Draft',
                          timeline: CinematicTimeline())
                      .toJson(),
                  'libraryPlacement': placement,
                })),
            throwsA(anything));
        expect(await f.file.readAsBytes(), before);
      }
    }
  });

  test('delete remains confirmation protected', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final asset = CinematicAsset(
        id: 'draft', title: 'Draft', timeline: CinematicTimeline());
    final created = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request('cinematic.upsert', {
          'cinematic': asset.toJson(),
          'libraryPlacement': {'folderId': null, 'index': 0}
        }));
    await f.api.applyMutation(f.opened.projectHandle,
        planId: created.planId, operationId: 'create');
    final deleted = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request('cinematicLibraryAsset.delete',
            {'family': 'world', 'cinematicId': asset.id}));
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: deleted.planId, operationId: 'unconfirmed'),
        throwsA(anything));
    expect(
        (await f.loader.load(f.opened.projectHandle))
            .manifest
            .cinematics
            .single,
        asset);
  });
}

class _Fixture {
  _Fixture(this.directory, this.handles, this.opened, this.loader, this.api,
      this.readApi);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  File get file => File('${directory.path}/project.json');

  static Future<_Fixture> create(
      {ProjectVersion version = ProjectVersion.v7}) async {
    final directory =
        await Directory.systemTemp.createTemp('cinematic_atomic_');
    await File('${directory.path}/project.json').writeAsString(jsonEncode(
        ProjectManifest(
            name: 'Cinematic',
            version: version,
            maps: const [],
            tilesets: const []).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(directory.path);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(directory, handles, opened, loader, api,
        AuthoringReadApi(openService: opener, snapshotLoader: loader));
  }

  Future<AuthoringRequest> request(
          String action, Map<String, Object?> parameters) async =>
      AuthoringRequest(
          requestId: '$action-${DateTime.now().microsecondsSinceEpoch}',
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: (await loader.load(opened.projectHandle)).revision,
          idempotencyKey: '$action-${DateTime.now().microsecondsSinceEpoch}',
          parameters: parameters);

  Future<AuthoringResult> command(
          String name, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(
          await JsonlWorker(api: readApi, mutations: api)
              .processLine(jsonEncode({
        'id': name,
        'command': name,
        'args': args,
      }))) as Map<String, dynamic>);

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}

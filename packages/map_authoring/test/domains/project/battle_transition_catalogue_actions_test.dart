import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, Object?> definition(String id) => {
  'id': id, 'label': 'Effect $id', 'usages': ['wild', 'trainer'],
  'phases': [
    {'kind': 'flash', 'durationSeconds': 0.2, 'factor': 2},
    {'kind': 'interleavedBands', 'durationSeconds': 0.4, 'bandHeight': 4},
    {'kind': 'holdBlack', 'durationSeconds': 0.1},
  ],
};

void main() {
  for (final jsonl in [false, true]) {
    test('${jsonl ? 'JSONL' : 'API'} authors independent project transitions with canonical upsert', () async {
      for (final id in ['aurora', 'clockwork']) {
        final h = await _Harness.create(id);
        addTearDown(h.dispose);
        expect((await h.query(jsonl)).items, isEmpty);
        await h.configure({'definitions': [definition(id)], 'wildTransitionId': id, 'trainerTransitionId': id}, jsonl);
        expect((await h.query(jsonl)).items.single['id'], id);
        final stored = ProjectManifest.fromJson(jsonDecode(await h.file.readAsString()) as Map<String, dynamic>);
        expect(stored.battleTransitions!.definitions.single.toJson(), definition(id));
        await h.configure({'definitions': [definition('$id-next')]}, jsonl);
        expect((await h.query(jsonl)).items, hasLength(2));
        await h.configure({'definitions': [{...definition(id), 'label': 'Changed'}]}, jsonl);
        final items = (await h.query(jsonl)).items;
        expect(items, hasLength(2));
        expect(items.singleWhere((item) => item['id'] == id)['label'], 'Changed');
        final beforeUsageChange = await h.file.readAsBytes();
        await expectLater(h.configure({'definitions': [
          {...definition(id), 'usages': ['trainer']},
        ]}, jsonl), throwsA(anything));
        expect(await h.file.readAsBytes(), beforeUsageChange);
        await h.configure({'wildTransitionId': null, 'trainerTransitionId': null}, jsonl);
        final finalProject = ProjectManifest.fromJson(jsonDecode(await h.file.readAsString()) as Map<String, dynamic>);
        expect(finalProject.battleTransitions!.wildTransitionId, isNull);
        expect(finalProject.battleTransitions!.definitions, hasLength(2));
      }
    });
  }
  test('malformed effects and stale revisions preserve exact project bytes', () async {
    final h = await _Harness.create('guarded');
    addTearDown(h.dispose);
    final before = await h.file.readAsBytes();
    for (final invalid in <Map<String, Object?>>[
      {'definitions': []},
      {'definitions': [definition('x'), definition('x')]},
      {'definitions': [{...definition('x'), 'phases': [{'kind': 'unknown', 'durationSeconds': 1}]}]},
      {'definitions': [definition('x')], 'wildTransitionId': 'absent'},
    ]) {
      await expectLater(h.configure(invalid, false), throwsA(anything));
      expect(await h.file.readAsBytes(), before);
    }
    final revision = (await h.snapshots.load(h.opened.projectHandle)).revision;
    await h.configure({'definitions': [definition('x')]}, false);
    final after = await h.file.readAsBytes();
    await expectLater(h.configure({'wildTransitionId': 'x'}, false, revision: revision), throwsA(anything));
    expect(await h.file.readAsBytes(), after);
  });
  test('upsert cannot remove the usage of a trainer reference', () async {
    final h = await _Harness.create('referenced');
    addTearDown(h.dispose);
    await h.configure({'definitions': [definition('shared')]}, false);
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await h.file.readAsString()) as Map<String, dynamic>);
    await h.file.writeAsString(jsonEncode(manifest.copyWith(trainers: [
      const ProjectTrainerEntry(id: 'guide', name: 'Guide', trainerClass: 'Guide',
          battleTransitionId: 'shared'),
    ]).toJson()));
    final before = await h.file.readAsBytes();
    await expectLater(h.configure({'definitions': [
      {...definition('shared'), 'usages': ['wild']},
    ]}, false), throwsA(anything));
    expect(await h.file.readAsBytes(), before);
  });
  test('upsert preserves interactive encounter references', () async {
    final h = await _Harness.create('interactive');
    addTearDown(h.dispose);
    await h.configure({'definitions': [definition('shared')]}, false);
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await h.file.readAsString()) as Map<String, dynamic>);
    final map = MapData(id: 'garden', name: 'Garden',
      size: const GridSize(width: 1, height: 1), entities: [
        MapEntity(id: 'tree', kind: MapEntityKind.custom,
          pos: const GridPos(x: 0, y: 0),
          interactiveEncounter: MapEntityInteractiveEncounterData(
            trigger: InteractiveEncounterTrigger.headbutt, encounterTableId: 'tree',
            presentation: const EncounterZonePayload(encounterTableId: 'tree',
              encounterKind: EncounterKind.headbutt, battleTransitionIds: ['shared']))),
      ]);
    await Directory('${h.root.path}/maps').create();
    await File('${h.root.path}/maps/garden.json').writeAsString(jsonEncode(map.toJson()));
    await h.file.writeAsString(jsonEncode(manifest.copyWith(maps: [
      const ProjectMapEntry(id: 'garden', name: 'Garden', relativePath: 'maps/garden.json'),
    ]).toJson()));
    final before = await h.file.readAsBytes();
    await expectLater(h.configure({'definitions': [
      {...definition('shared'), 'usages': ['trainer']},
    ]}, false), throwsA(anything));
    expect(await h.file.readAsBytes(), before);
  });
}

class _Harness {
  _Harness(this.root, this.file, this.api, this.mutations, this.snapshots,
      this.opened, this.worker);
  final Directory root;
  final File file;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;

  static Future<_Harness> create(String name) async {
    final root = await Directory.systemTemp.createTemp('runtime-policy-');
    final file = File('${root.path}/project.json');
    await file.writeAsString(jsonEncode(
        ProjectManifest(name: name, maps: [], tilesets: []).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Harness(root, file, api, mutations, snapshots, opened,
        JsonlWorker(api: api, mutations: mutations));
  }

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': command, 'command': command, 'args': args})))
        as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw StateError(result.toJson().toString());
    }
    return result.data;
  }

  Future<AuthoringQueryPage> query(bool jsonl) async {
    final request = AuthoringQueryRequest(
        resourceKind: 'battleTransitionDefinition',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail);
    return jsonl
        ? AuthoringQueryPage.fromJson(Map<String, dynamic>.from(await wire(
            'query', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          })))
        : api.queryProject(opened.projectHandle, request);
  }

  Future<void> configure(Map<String, Object?> parameters, bool jsonl,
      {String? revision}) async {
    final id = 'policy-${sequence++}';
    final request = AuthoringRequest(
        requestId: id,
        actionId: 'project.battle_transitions.update',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision:
            revision ?? (await snapshots.load(opened.projectHandle)).revision,
        idempotencyKey: id,
        parameters: parameters);
    final before = await file.readAsBytes();
    final plan = jsonl
        ? await wire('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          })
        : await mutations.plan(opened.projectHandle, request);
    expect(await file.readAsBytes(), before);
    if (jsonl) {
      await wire('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan['planId'],
        'operationId': id
      });
    } else {
      await mutations.apply(opened.projectHandle,
          planId: plan['planId']! as String, operationId: id);
    }
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

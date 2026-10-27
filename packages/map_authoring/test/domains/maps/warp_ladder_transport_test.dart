import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const action = 'warp.ladder.configure';
void main() {
  test('ladder configuration is discoverable across transports', () {
    final descriptor = WarpConnectionActions.descriptors
        .singleWhere((entry) => entry.id == action);
    expect((descriptor.extensions['inputSchema'] as Map)['required'],
        ['mapId', 'warpId', 'ladder']);
    expect(
        AuthoringFullParityCatalog.canonical()
            .requireMutationAction(action)
            .endToEndEvidence
            .keys
            .toSet(),
        AuthoringTransport.values.toSet());
  });
  for (final wire in [false, true]) {
    test(
        'ladder config persists, clears and preserves unrelated bytes via $wire',
        () async {
      final f = await _Fixture.create(spatial: true);
      addTearDown(f.dispose);
      const warp = MapWarp(
          id: 'first',
          pos: GridPos(x: 1, y: 1),
          targetMapId: 'beta',
          targetPos: GridPos(x: 2, y: 1));
      await f.mutate('warp.create', {'warp': warp.toJson()}, wire);
      final before = [
        await f.manifest.readAsBytes(),
        await f.beta.readAsBytes()
      ];
      final ladder = MapWarpLadder(
          direction: MapWarpLadderDirection.down, facing: EntityFacing.south);
      await f.mutate(
          action, {'warpId': 'first', 'ladder': ladder.toJson()}, wire);
      await f.reopen();
      final saved =
          (await f.snapshots.load(f.project)).mapById('alpha')!.warps.single;
      expect(saved, warp.copyWith(ladder: ladder));
      for (final value in [
        {'direction': 'sideways'},
        {...ladder.toJson(), 'heightCells': 0},
        {...ladder.toJson(), 'extra': true}
      ]) {
        await f.reject(action, {'warpId': 'first', 'ladder': value}, wire);
      }
      await f.mutate(action, {'warpId': 'first', 'ladder': null}, wire);
      await f.reopen();
      expect((await f.snapshots.load(f.project)).mapById('alpha')!.warps.single,
          warp);
      expect(await f.manifest.readAsBytes(), before[0]);
      expect(await f.beta.readAsBytes(), before[1]);
    });
    test('2D and passive warps cannot acquire a ladder via $wire', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      await f.mutate(
          'warp.create',
          {
            'warp': const MapWarp(
                    id: 'first',
                    pos: GridPos(x: 1, y: 1),
                    targetMapId: 'beta',
                    targetPos: GridPos(x: 2, y: 1))
                .toJson()
          },
          wire);
      await f.reject(action,
          {'warpId': 'first', 'ladder': MapWarpLadder().toJson()}, wire);
    });
  }
}

final class _Fixture {
  _Fixture(this.directory, this.snapshots, this.mutations, this.worker);
  final Directory directory;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;
  File get manifest => File('${directory.path}/project.json');
  File get alpha => File('${directory.path}/maps/alpha.json');
  File get beta => File('${directory.path}/maps/beta.json');

  static Future<_Fixture> create(
      {bool seeded = false, bool spatial = false}) async {
    final directory =
        await Directory.systemTemp.createTemp('warp-transition-api-');
    await Directory('${directory.path}/maps').create();
    final manifest = ProjectManifest(
        name: 'Native arrival',
        version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
        settings: ProjectSettings(
            dimension:
                spatial ? ProjectDimension.threeD : ProjectDimension.twoD,
            spatialCamera: spatial ? SpatialCameraProfile() : null),
        tilesets: const [],
        maps: const [
          ProjectMapEntry(
              id: 'alpha', name: 'Alpha', relativePath: 'maps/alpha.json'),
          ProjectMapEntry(
              id: 'beta', name: 'Beta', relativePath: 'maps/beta.json'),
        ]);
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    for (final id in ['alpha', 'beta']) {
      final map = MapData(
          id: id,
          name: id,
          version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
          spatialScene: spatial ? MapSpatialScene(width: 4, depth: 4) : null,
          size: const GridSize(width: 4, height: 4),
          warps: [
            if (seeded && id == 'alpha')
              const MapWarp(
                  id: 'arrival',
                  pos: GridPos(x: 1, y: 1),
                  targetMapId: 'alpha',
                  targetPos: GridPos(x: 1, y: 1),
                  triggerMode: MapWarpTriggerMode.sceneOnly),
          ]);
      await File('${directory.path}/maps/$id.json')
          .writeAsString(jsonEncode(map.toJson()));
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: LocalArtifactStore(
          allowedSourceRoots: [directory.path], maximumArtifactBytes: 1048576),
    );
    final f = _Fixture(directory, snapshots, mutations,
        JsonlWorker(api: api, mutations: mutations));
    await f.open();
    return f;
  }

  Future<AuthoringResult> command(
          String name, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
        'id': 'wire-${++sequence}',
        'command': name,
        'args': args,
      }))) as Map<String, dynamic>);
  Future<void> open() async {
    final result = await command('open', {'projectRoot': directory.path});
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    workspace = WorkspaceHandle(result.data['workspaceHandle'] as String);
    project = ProjectHandle(result.data['projectHandle'] as String);
  }

  Future<void> reopen() async {
    await command('close', {'workspaceHandle': workspace.value});
    await open();
  }

  Future<AuthoringRequest> request(
      String action, Map<String, Object?> parameters) async {
    final id = 'arrival-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: {
          if (!action.startsWith('model3d.')) 'mapId': 'alpha',
          ...parameters
        });
  }

  Future<void> mutate(
      String action, Map<String, Object?> parameters, bool wire) async {
    final before = await alpha.readAsBytes();
    final input = await request(action, parameters);
    final Map<String, Object?> planned;
    if (wire) {
      final result = await command(
          'plan', {'projectHandle': project.value, 'request': input.toJson()});
      expect(result.status, AuthoringResultStatus.success,
          reason: jsonEncode(result.toJson()));
      planned = result.data;
    } else {
      planned = await mutations.plan(project, input);
    }
    expect(await alpha.readAsBytes(), before);
    final operation = 'apply-${++sequence}';
    if (wire) {
      final result = await command('apply', {
        'projectHandle': project.value,
        'planId': planned['planId'],
        'operationId': operation
      });
      expect(result.status, AuthoringResultStatus.success,
          reason: jsonEncode(result.toJson()));
    } else {
      await mutations.apply(project,
          planId: planned['planId'] as String, operationId: operation);
    }
  }

  Future<void> reject(String action, Map<String, Object?> parameters, bool wire,
      {String? code}) async {
    final before = [
      await manifest.readAsBytes(),
      await alpha.readAsBytes(),
      await beta.readAsBytes()
    ];
    final input = await request(action, parameters);
    if (wire) {
      final result = await command(
          'plan', {'projectHandle': project.value, 'request': input.toJson()});
      expect(result.status, AuthoringResultStatus.failure,
          reason: jsonEncode(result.toJson()));
      if (code != null) expect(result.error!.details['domainCode'], code);
    } else {
      await expectLater(
          mutations.plan(project, input),
          throwsA(code == null
              ? isA<MapAuthoringException>()
              : isA<MapAuthoringException>()
                  .having((e) => e.code, 'code', code)));
    }
    expect(await manifest.readAsBytes(), before[0]);
    expect(await alpha.readAsBytes(), before[1]);
    expect(await beta.readAsBytes(), before[2]);
  }

  Future<void> dispose() async {
    await command('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _lifecycle = [
  'placed_element.place',
  'placed_element.move',
  'placed_element.clone',
  'placed_element.delete',
];

Map<String, Object?> _rock({String id = 'rock-1', int x = 1, int y = 1}) =>
    MapPlacedElement(
      id: id,
      layerId: 'decor',
      elementId: 'rock',
      pos: GridPos(x: x, y: y),
      opacity: .5,
      applyCollision: false,
      properties: const {
        'pokemapPlacementOrigin': 'authored',
        'note': 'garder',
      },
    ).toJson();

void main() {
  test('the decor lifecycle cites its receipts on every transport', () {
    final catalog = AuthoringFullParityCatalog.canonical();
    for (final action in _lifecycle) {
      final evidence = catalog.requireMutationAction(action);
      expect(evidence.endToEndEvidence.keys.toSet(),
          AuthoringTransport.values.toSet(),
          reason: action);
      expect(evidence.endToEndEvidence[AuthoringTransport.directApi],
          'test/domains/maps/placed_element_lifecycle_transport_test.dart',
          reason: action);
    }
  });

  for (final wire in [false, true]) {
    final label = wire ? 'JSONL' : 'direct API';

    test('$label places, moves, clones and deletes a decor then cold reopens',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final manifestBefore = await f.manifest.readAsBytes();
      await f.mutate('placed_element.place', {'instance': _rock()}, wire);
      await f.mutate('placed_element.move',
          {'instanceId': 'rock-1', 'x': 2, 'y': 1}, wire);
      await f.mutate('placed_element.clone',
          {'instanceId': 'rock-1', 'newId': 'rock-2', 'x': 3, 'y': 3}, wire);
      await f.mutate('placed_element.delete', {'instanceId': 'rock-1'}, wire);
      await f.reopen();
      final map = (await f.snapshots.load(f.project)).mapById('alpha')!;
      expect(map.placedElements, [
        MapPlacedElement.fromJson(
          _rock(id: 'rock-2', x: 3, y: 3).cast<String, dynamic>(),
        ),
      ]);
      expect(await f.manifest.readAsBytes(), manifestBefore);
    });

    test('$label refuses invalid decor changes before any write', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      await f.mutate('placed_element.place', {'instance': _rock()}, wire);
      await f.reject('placed_element.place',
          {'instance': _rock(id: 'edge', x: 5, y: 5)}, wire,
          code: 'placed_element.footprint_out_of_bounds');
      await f.reject('placed_element.place', {'instance': _rock()}, wire,
          code: 'placed_element.exists');
      await f.reject(
          'placed_element.place',
          {
            'instance': {..._rock(id: 'ghost'), 'elementId': 'missing'}
          },
          wire,
          code: 'placed_element.element_missing');
      await f.reject(
          'placed_element.move', {'instanceId': 'rock-1', 'x': 5, 'y': 5}, wire,
          code: 'placed_element.footprint_out_of_bounds');
      await f.reject('placed_element.move',
          {'instanceId': 'nowhere', 'x': 2, 'y': 2}, wire,
          code: 'placed_element.not_found');
      await f.reject('placed_element.clone',
          {'instanceId': 'rock-1', 'newId': 'rock-1', 'x': 3, 'y': 3}, wire,
          code: 'placed_element.exists');
      await f.reject('placed_element.delete', {'instanceId': 'nowhere'}, wire);
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

  static Future<_Fixture> create() async {
    final directory = await Directory.systemTemp.createTemp('decor-life-');
    await Directory('${directory.path}/maps').create();
    const manifest = ProjectManifest(
      name: 'Decor lifecycle',
      maps: [
        ProjectMapEntry(
            id: 'alpha', name: 'Alpha', relativePath: 'maps/alpha.json'),
      ],
      tilesets: [
        ProjectTilesetEntry(id: 'ts', name: 'TS', relativePath: 'assets/ts.png')
      ],
      elementCategories: [ProjectElementCategory(id: 'cat', name: 'Cat')],
      elements: [
        ProjectElementEntry(
          id: 'rock',
          name: 'Rock',
          tilesetId: 'ts',
          categoryId: 'cat',
          frames: [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2))
          ],
        ),
      ],
    );
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final map = MapData(
      id: 'alpha',
      name: 'Alpha',
      size: const GridSize(width: 6, height: 6),
      layers: [
        MapLayer.tile(id: 'decor', name: 'Decor', cells: List.filled(36, 0)),
      ],
    );
    await File('${directory.path}/maps/alpha.json')
        .writeAsString(jsonEncode(map.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
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
    final id = 'decor-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: {'mapId': 'alpha', ...parameters});
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
    final before = [await manifest.readAsBytes(), await alpha.readAsBytes()];
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
  }

  Future<void> dispose() async {
    await command('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}

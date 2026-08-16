import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('typed mutation facade owns contracts before wire serialization',
      () async {
    final root = await Directory.systemTemp.createTemp('typed-mutation-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: WorkspaceHandleStore()),
    );

    final typed = (mutations as dynamic).describeMutationContracts();

    expect(typed, isA<AuthoringMutationDescription>());
    expect(typed.toJson(), mutations.describeMutations());
  });

  test('JSONL exposes lifecycle plan and apply without leaking roots',
      () async {
    final root = await Directory.systemTemp.createTemp('jsonl-mutation-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final manifest = ProjectManifest(
      name: 'JSONL Mutation Fixture',
      version: ProjectVersion.v6,
      maps: const [],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'atlas_a',
          name: 'Atlas A',
          relativePath: 'assets/atlas_a.png',
          source: ProjectTilesetSource.regularAtlas(
            assetId: 'atlas-a-image',
            pixelWidth: 1,
            pixelHeight: 1,
            tileWidth: 1,
            tileHeight: 1,
          ),
        ),
        ProjectTilesetEntry(
          id: 'atlas_b',
          name: 'Atlas B',
          relativePath: 'assets/atlas_b.png',
          source: ProjectTilesetSource.regularAtlas(
            assetId: 'atlas-b-image',
            pixelWidth: 1,
            pixelHeight: 1,
            tileWidth: 1,
            tileHeight: 1,
          ),
        ),
      ],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
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

    final described = await _request(worker, 'describe');
    expect(described.status, AuthoringResultStatus.success);
    expect(described.data['readOnly'], isFalse);
    final mapAction = (described.data['mutationActions']! as List)
        .cast<Map<String, Object?>>()
        .singleWhere((action) => action['id'] == 'map.apply_operations');
    expect(
      (mapAction['extensions']! as Map)['tileLayerEncoding'],
      'tile_palette_v1',
    );
    expect(
      (described.data['commands']! as List)
          .cast<Map<String, Object?>>()
          .map((command) => command['id']),
      [
        'apply',
        'close',
        'confirm',
        'describe',
        'history',
        'open',
        'plan',
        'query',
        'recover',
        'stage_artifact',
        'undo',
        'validate'
      ],
    );

    final opened = await _request(
      worker,
      'open',
      args: {'projectRoot': root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    expect(opened.data['readOnly'], isFalse);
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final manifestFile = File('${root.path}/project.json');
    final beforeRemovedCommand = await manifestFile.readAsBytes();
    final removedCommand = await _request(
      worker,
      'plan',
      args: {
        'projectHandle': projectHandle,
        'request': AuthoringRequest(
          requestId: 'removed-scenario-command',
          actionId: 'scenario.upsert',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          parameters: const <String, Object?>{},
          expectedRevision: snapshot.revision,
          idempotencyKey: 'removed-scenario-command',
          dryRun: false,
        ).toJson(),
      },
    );
    expect(removedCommand.status, AuthoringResultStatus.failure);
    expect(removedCommand.error?.code, AuthoringErrorCode.unsupported);
    expect(
      removedCommand.error?.details['domainCode'],
      'cinematic.capability_removed',
    );
    expect(await manifestFile.readAsBytes(), beforeRemovedCommand);
    expect(
      (await snapshots.load(ProjectHandle(projectHandle))).revision,
      snapshot.revision,
    );
    expect(
      (await mutations.history(ProjectHandle(projectHandle),
          limit: 10))['entries'],
      isEmpty,
    );
    final request = AuthoringRequest(
      requestId: 'create-jsonl-map',
      actionId: 'map.create',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const {
        'mapId': 'jsonl_map',
        'width': 2,
        'height': 2,
      },
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_jsonl_map',
      dryRun: false,
    );
    final planned = await _request(
      worker,
      'plan',
      args: {
        'projectHandle': projectHandle,
        'request': request.toJson(),
      },
    );
    expect(planned.status, AuthoringResultStatus.success);
    final applied = await _request(
      worker,
      'apply',
      args: {
        'projectHandle': projectHandle,
        'planId': planned.data['planId'],
        'operationId': 'operation_jsonl_map',
      },
    );
    expect(applied.status, AuthoringResultStatus.success);
    expect(
      (applied.data['receipt']! as Map<String, Object?>)['status'],
      'applied',
    );
    final typedReplay = await mutations.applyMutation(
      ProjectHandle(projectHandle),
      planId: planned.data['planId']! as String,
      operationId: 'operation_jsonl_map',
    );
    expect(typedReplay.toJson(), applied.data);
    expect(await File('${root.path}/maps/jsonl_map.json').exists(), isTrue);

    final history = await _request(
      worker,
      'history',
      args: {
        'projectHandle': projectHandle,
        'limit': 1,
      },
    );
    expect(history.status, AuthoringResultStatus.success);
    expect(history.data['entries'], hasLength(1));
    expect(
      ((history.data['entries']! as List).single as Map)['operationId'],
      'operation_jsonl_map',
    );
    final directHistory = await mutations.listMutationHistory(
      ProjectHandle(projectHandle),
      limit: 1,
    );
    expect(history.data, directHistory.toJson());

    final beforePalette = await snapshots.load(ProjectHandle(projectHandle));
    final paletteRequest = AuthoringRequest(
      requestId: 'jsonl-map-palette',
      actionId: 'map.apply_operations',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const <String, Object?>{
        'mapId': 'jsonl_map',
        'operations': <Object?>[
          <String, Object?>{
            'kind': 'layer.add',
            'layerKind': 'tile',
            'layerId': 'mixed',
            'name': 'Mixed sources',
          },
          <String, Object?>{
            'kind': 'region.paint',
            'layerId': 'mixed',
            'x': 0,
            'y': 0,
            'value': <String, Object?>{
              'tilesetId': 'atlas_a',
              'localTileId': 0,
            },
          },
          <String, Object?>{
            'kind': 'region.paint',
            'layerId': 'mixed',
            'x': 1,
            'y': 0,
            'value': <String, Object?>{
              'tilesetId': 'atlas_b',
              'localTileId': 0,
            },
          },
        ],
      },
      expectedRevision: beforePalette.revision,
      idempotencyKey: 'idem_jsonl_map_palette',
      dryRun: false,
    );
    final palettePlanned = await _request(
      worker,
      'plan',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'request': paletteRequest.toJson(),
      },
    );
    expect(palettePlanned.status, AuthoringResultStatus.success);
    final paletteApplied = await _request(
      worker,
      'apply',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'planId': palettePlanned.data['planId'],
        'operationId': 'operation_jsonl_map_palette',
      },
    );
    expect(paletteApplied.status, AuthoringResultStatus.success);

    final region = await _request(
      worker,
      'query',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'request': AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['jsonl_map'],
          view: AuthoringQueryView.detail,
          extensions: const <String, Object?>{
            'region': <String, Object?>{
              'x': 0,
              'y': 0,
              'width': 2,
              'height': 1,
            },
          },
        ).toJson(),
      },
    );
    expect(region.status, AuthoringResultStatus.success);
    final regionItem = (region.data['items']! as List).single as Map;
    final mixedLayer = (regionItem['layers']! as List)
        .cast<Map>()
        .singleWhere((layer) => layer['id'] == 'mixed');
    expect(mixedLayer['encoding'], 'tile_palette_v1');
    expect(
      (mixedLayer['palette']! as List)
          .cast<Map>()
          .map((entry) => entry['tilesetId']),
      <String>['atlas_a', 'atlas_b'],
    );
    expect(mixedLayer['rows'], <Object?>[
      <Object?>[1, 2],
    ]);

    final transcript = jsonEncode({
      'describe': described.toJson(),
      'open': opened.toJson(),
      'plan': planned.toJson(),
      'apply': applied.toJson(),
      'history': history.toJson(),
      'palettePlan': palettePlanned.toJson(),
      'paletteApply': paletteApplied.toJson(),
      'region': region.toJson(),
    });
    expect(transcript, isNot(contains(root.path)));
    expect(transcript, isNot(contains('/private/')));
  });

  test('JSONL relays creation guards and applies Smart Tile cell edits',
      () async {
    final root = await Directory.systemTemp.createTemp('jsonl-smart-guard-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    await Directory('${root.path}/maps').create();
    final manifest = ProjectManifest(
      name: 'JSONL Smart Tile guard fixture',
      version: ProjectVersion.v6,
      maps: const [
        ProjectMapEntry(
          id: 'fixture',
          name: 'Fixture',
          relativePath: 'maps/fixture.json',
        ),
      ],
      tilesets: const [],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'road',
            name: 'Road',
            connectionGroupId: 'road',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'path',
            name: 'Path',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.cardinal4,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'road',
            allowedMaterialIds: <String>['road'],
          ),
        ],
      ),
    );
    const map = MapData(
      id: 'fixture',
      name: 'Fixture',
      version: ProjectVersion.v6,
      size: GridSize(width: 2, height: 2),
      layers: [
        MapLayer.tile(id: 'base', name: 'Base', cells: [0, 0, 0, 0]),
        SmartTileLayer(
          id: 'smart',
          name: 'Smart',
          presetId: 'path',
          usage: SmartTileUsage.path,
          materialPalette: ['', 'road'],
          field: SmartTileField.cell(semanticCells: [1, 0, 0, 0]),
        ),
      ],
    );
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(manifest.toJson()),
      flush: true,
    );
    final mapFile = File('${root.path}/maps/fixture.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()), flush: true);
    final beforeMap = await mapFile.readAsBytes();

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
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
    final opened = await _request(
      worker,
      'open',
      args: {'projectRoot': root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final before = await snapshots.load(ProjectHandle(projectHandle));
    final request = AuthoringRequest(
      requestId: 'reject-native-smart-layer',
      actionId: 'map.apply_operations',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const {
        'mapId': 'fixture',
        'operations': [
          {
            'kind': 'layer.add',
            'layerKind': 'smart_tile',
            'layerId': 'smart',
            'name': 'Smart',
            'presetId': 'path',
            'usage': 'path',
            'defaultMaterialId': 'road',
          },
        ],
      },
      expectedRevision: before.revision,
      idempotencyKey: 'idem-reject-native-smart-layer',
      dryRun: false,
    );

    final rejected = await _request(
      worker,
      'plan',
      args: {
        'projectHandle': projectHandle,
        'request': request.toJson(),
      },
    );

    expect(rejected.status, AuthoringResultStatus.failure);
    expect(rejected.data, isEmpty);
    expect(
      rejected.error?.details['domainCode'],
      'map.operation_invalid',
    );
    final after = await snapshots.load(ProjectHandle(projectHandle));
    expect(after.revision, before.revision);
    expect(await mapFile.readAsBytes(), beforeMap);
    final history =
        await mutations.history(ProjectHandle(projectHandle), limit: 10);
    expect(history['entries'], isEmpty);

    final clearRequest = AuthoringRequest(
      requestId: 'reject-native-smart-clear',
      actionId: 'map.apply_operations',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const {
        'mapId': 'fixture',
        'operations': [
          {'kind': 'layer.clear', 'layerId': 'smart'},
          {
            'kind': 'region.paint',
            'layerId': 'smart',
            'x': 1,
            'y': 1,
            'value': 'road',
          },
        ],
      },
      expectedRevision: before.revision,
      idempotencyKey: 'idem-reject-native-smart-clear',
      dryRun: false,
    );
    final clearPlanned = await _request(
      worker,
      'plan',
      args: {
        'projectHandle': projectHandle,
        'request': clearRequest.toJson(),
      },
    );

    expect(clearPlanned.status, AuthoringResultStatus.success);
    final clearApplied = await _request(
      worker,
      'apply',
      args: {
        'projectHandle': projectHandle,
        'planId': clearPlanned.data['planId'],
        'operationId': 'operation-native-smart-clear',
      },
    );
    expect(clearApplied.status, AuthoringResultStatus.success);
    final afterClear = await snapshots.load(ProjectHandle(projectHandle));
    expect(afterClear.revision, isNot(before.revision));
    final clearedMap = MapData.fromJson(
      jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
    );
    final clearedLayer = clearedMap.layers.last as SmartTileLayer;
    expect(smartTileSemanticCells(clearedLayer), <int>[0, 0, 0, 1]);
    final historyAfterClear =
        await mutations.history(ProjectHandle(projectHandle), limit: 10);
    expect(historyAfterClear['entries'], hasLength(1));
  });
}

Future<AuthoringResult> _request(
  JsonlWorker worker,
  String command, {
  Map<String, Object?> args = const {},
}) async {
  final decoded = jsonDecode(
    await worker.processLine(
      jsonEncode({
        'id': 'request-$command',
        'command': command,
        'args': args,
      }),
    ),
  ) as Map<String, dynamic>;
  return AuthoringResult.fromJson(decoded);
}

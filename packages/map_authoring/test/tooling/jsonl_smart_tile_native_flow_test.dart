import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('native Smart Tile direct/JSONL parity', () {
    test('rejects decoded out-of-image atlas geometry through both transports',
        () async {
      final direct = await _Harness.create('out_of_image_direct');
      final jsonl = await _Harness.create('out_of_image_jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      await expectLater(
        direct.planDirect(
          actionId: 'smart_tile.atlas.upsert',
          parameters: <String, Object?>{
            'atlas': _atlas(columns: 2).toJson(),
          },
          sequence: 'out-of-image',
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.atlas.out_of_image',
          ),
        ),
      );

      final failure = await jsonl.planJsonlFailure(
        actionId: 'smart_tile.atlas.upsert',
        parameters: <String, Object?>{
          'atlas': _atlas(columns: 2).toJson(),
        },
        sequence: 'out-of-image',
      );
      expect(
        failure.error?.details['domainCode'],
        'smart_tile.atlas.out_of_image',
      );
      expect(await direct.projectBytes(), await jsonl.projectBytes());
      expect(await direct.mapBytes(), await jsonl.mapBytes());
    });

    test('applies animation and atomic publish/create with stable receipts',
        () async {
      final direct = await _Harness.create('direct');
      final jsonl = await _Harness.create('jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directResult = await direct.applyDirectFlow();
      final jsonlResult = await jsonl.applyJsonlFlow();

      expect(directResult.animationReplay, directResult.animationReceipt);
      expect(jsonlResult.animationReplay, jsonlResult.animationReceipt);
      expect(
        _stableReceipt(directResult.animationReceipt),
        _stableReceipt(jsonlResult.animationReceipt),
      );
      expect(
        _stableReceipt(directResult.publishReceipt),
        _stableReceipt(jsonlResult.publishReceipt),
      );
      expect(await direct.projectBytes(), await jsonl.projectBytes());
      expect(await direct.mapBytes(), await jsonl.mapBytes());
      expect(directResult.animationQuery['totalAvailable'], 1);
      expect(jsonlResult.animationQuery['totalAvailable'], 1);

      final map = MapData.fromJson(
        jsonDecode(utf8.decode(await direct.mapBytes()))
            as Map<String, dynamic>,
      );
      expect(map.version, ProjectVersion.v6);
      expect(map.layers.single, isA<SmartTileLayer>());
      final layer = map.layers.single as SmartTileLayer;
      expect(layer.presetId, 'grass');
      expect(smartTileSemanticCells(layer), <int>[1]);
    });

    test('persists, reopens and publishes drafts byte-identically', () async {
      final direct = await _Harness.create('draft_direct');
      final jsonl = await _Harness.create('draft_jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directResult = await direct.applyDirectDraftFlow();
      final jsonlResult = await jsonl.applyJsonlDraftFlow();

      expect(directResult.queryBeforeReopen, directResult.queryAfterReopen);
      expect(jsonlResult.queryBeforeReopen, jsonlResult.queryAfterReopen);
      expect(
        directResult.queryAfterReopen['items'],
        jsonlResult.queryAfterReopen['items'],
      );
      expect(
        _stableReceipt(directResult.upsertReceipt),
        _stableReceipt(jsonlResult.upsertReceipt),
      );
      expect(
        _stableReceipt(directResult.publishReceipt),
        _stableReceipt(jsonlResult.publishReceipt),
      );
      expect(await direct.projectBytes(), await jsonl.projectBytes());
      expect(await direct.mapBytes(), await jsonl.mapBytes());

      final manifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(await direct.projectBytes()))
            as Map<String, dynamic>,
      );
      expect(manifest.smartTileCatalog.drafts, isEmpty);
      expect(manifest.smartTileCatalog.presets.single.id, 'grass-draft');
      final transitionRule = manifest.smartTileCatalog.presets.single.rules
          .singleWhere((rule) => rule.id == 'grass-water-stone');
      expect(transitionRule.centerMatch.materialId, 'grass');
      expect(transitionRule.signature.northEdge.materialId, 'water');
      expect(transitionRule.signature.eastEdge.materialId, 'stone');
      final map = MapData.fromJson(
        jsonDecode(utf8.decode(await direct.mapBytes()))
            as Map<String, dynamic>,
      );
      expect(map.layers.single, isA<SmartTileLayer>());
    });

    test('paints and erases one gesture byte-identically through JSONL',
        () async {
      final direct = await _Harness.create('cells_direct');
      final jsonl = await _Harness.create('cells_jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      await direct.applyDirectFlow();
      await jsonl.applyJsonlFlow();
      final directResult = await direct.applyDirectCellFlow();
      final jsonlResult = await jsonl.applyJsonlCellFlow();

      expect(
        _stableReceipt(directResult.eraseReceipt),
        _stableReceipt(jsonlResult.eraseReceipt),
      );
      expect(
        _stableReceipt(directResult.paintReceipt),
        _stableReceipt(jsonlResult.paintReceipt),
      );
      expect(await direct.projectBytes(), await jsonl.projectBytes());
      expect(await direct.mapBytes(), await jsonl.mapBytes());
      final map = MapData.fromJson(
        jsonDecode(utf8.decode(await direct.mapBytes()))
            as Map<String, dynamic>,
      );
      final layer = map.layers.single as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[1]);
      expect(layer.field, isA<SmartTileMixedField>());
      final field = layer.field as SmartTileMixedField;
      expect(field.horizontalEdges, <int>[1, 1]);
      expect(field.verticalEdges, <int>[1, 1]);
      expect(field.corners, <int>[1, 1, 1, 1]);
    });

    test('rejects stale planning and replays one operation exactly once',
        () async {
      final harness = await _Harness.create('cas');
      addTearDown(harness.dispose);
      final opened = await harness.openDirect();
      final before = await harness.snapshots.load(opened.project);
      final plan = await harness.mutations.plan(
        opened.project,
        _request(
          workspaceHandle: opened.workspace.value,
          revision: before.revision,
          actionId: 'smart_tile.preset.draft.upsert',
          parameters: <String, Object?>{
            'draft': _draft().toJson(),
          },
          sequence: 'cas-apply',
        ),
      );
      final first = await harness.mutations.apply(
        opened.project,
        planId: plan['planId']! as String,
        operationId: 'operation-cas-replay',
      );
      final replay = await harness.mutations.apply(
        opened.project,
        planId: plan['planId']! as String,
        operationId: 'operation-cas-replay',
      );
      expect(replay['receipt'], first['receipt']);
      final duplicateApply = await harness.mutations.apply(
        opened.project,
        planId: plan['planId']! as String,
        operationId: 'operation-cas-duplicate',
      );
      expect(duplicateApply['receipt'], first['receipt']);

      await expectLater(
        () => harness.mutations.plan(
          opened.project,
          _request(
            workspaceHandle: opened.workspace.value,
            revision: before.revision,
            actionId: 'smart_tile.material.upsert',
            parameters: <String, Object?>{
              'material': const ProjectSmartTileMaterial(
                id: 'dirt',
                name: 'Dirt',
                connectionGroupId: 'ground',
              ).toJson(),
            },
            sequence: 'cas-stale',
          ),
        ),
        throwsA(
          isA<AuthoringPlanException>().having(
            (error) => error.code,
            'code',
            'plan.stale',
          ),
        ),
      );
    });
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
      'pokemap_stn03_$suffix',
    );
    await Directory('${root.path}/maps').create(recursive: true);
    await Directory('${root.path}/assets/.pokemap-store')
        .create(recursive: true);
    final artifact = ContentArtifactRef.fromBytes(
      _pngBytes,
      mediaType: 'image/png',
    );
    final assets = AssetCatalog(
      records: <AssetRecord>[
        AssetRecord(
          id: 'tileset-image',
          logicalPath: 'assets/tileset.png',
          artifact: artifact,
        ),
      ],
    );
    final manifest = ProjectManifest(
      name: 'STN-03 transport fixture',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map',
          name: 'Map',
          relativePath: 'maps/map.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'tileset',
          name: 'Tileset',
          relativePath: 'assets/tileset.png',
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: <ProjectSmartTileAtlas>[_atlas()],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
      ),
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
    );
    await File('${root.path}/project.json').writeAsBytes(
      _encode(manifest.toJson()),
    );
    await File('${root.path}/maps/map.json').writeAsBytes(
      _encode(map.toJson()),
    );
    await File('${root.path}/$assetCatalogStorageKey').writeAsBytes(
      _encode(assets.toJson()),
    );
    await File('${root.path}/${assetBlobStorageKey(artifact)}')
        .writeAsBytes(_pngBytes);

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

  Future<({WorkspaceHandle workspace, ProjectHandle project})>
      openDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    return (workspace: workspace, project: project);
  }

  Future<Map<String, Object?>> planDirect({
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
  }) async {
    final opened = await openDirect();
    final snapshot = await snapshots.load(opened.project);
    return mutations.plan(
      opened.project,
      _request(
        workspaceHandle: opened.workspace.value,
        revision: snapshot.revision,
        actionId: actionId,
        parameters: parameters,
        sequence: sequence,
      ),
    );
  }

  Future<_FlowResult> applyDirectFlow() async {
    final opened = await openDirect();

    Future<Map<String, Object?>> apply({
      required String actionId,
      required Map<String, Object?> parameters,
      required String sequence,
      required String operationId,
    }) async {
      final snapshot = await snapshots.load(opened.project);
      final plan = await mutations.plan(
        opened.project,
        _request(
          workspaceHandle: opened.workspace.value,
          revision: snapshot.revision,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ),
      );
      final applied = await mutations.apply(
        opened.project,
        planId: plan['planId']! as String,
        operationId: operationId,
      );
      return <String, Object?>{
        ...applied,
        'planId': plan['planId'],
      };
    }

    final animation = await apply(
      actionId: 'smart_tile.animation.upsert',
      parameters: <String, Object?>{'animation': _animation().toJson()},
      sequence: 'animation',
      operationId: 'operation-animation',
    );
    final animationReplay = await mutations.apply(
      opened.project,
      planId: animation['planId']! as String,
      operationId: 'operation-animation',
    );
    final publish = await apply(
      actionId: 'smart_tile.preset.publish',
      parameters: <String, Object?>{
        'preset': _preset().toJson(),
        'layer': const <String, Object?>{
          'mapId': 'map',
          'layerId': 'terrain',
          'name': 'Terrain',
        },
      },
      sequence: 'publish',
      operationId: 'operation-publish',
    );
    final query = await readApi.query(
      opened.project,
      AuthoringQueryRequest(
        resourceKind: 'smartTileAnimation',
        operation: AuthoringQueryOperation.list,
      ),
    );
    return _FlowResult(
      animationReceipt: _receipt(animation),
      animationReplay: _receipt(animationReplay),
      publishReceipt: _receipt(publish),
      animationQuery: query,
    );
  }

  Future<_DraftFlowResult> applyDirectDraftFlow() async {
    final opened = await openDirect();

    Future<Map<String, Object?>> apply({
      required String actionId,
      required Map<String, Object?> parameters,
      required String sequence,
      required String operationId,
    }) async {
      final snapshot = await snapshots.load(opened.project);
      final plan = await mutations.plan(
        opened.project,
        _request(
          workspaceHandle: opened.workspace.value,
          revision: snapshot.revision,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ),
      );
      return mutations.apply(
        opened.project,
        planId: plan['planId']! as String,
        operationId: operationId,
      );
    }

    final upsert = await apply(
      actionId: 'smart_tile.preset.draft.upsert',
      parameters: <String, Object?>{'draft': _draft().toJson()},
      sequence: 'draft-upsert',
      operationId: 'operation-draft-upsert',
    );
    final queryBefore = await readApi.query(
      opened.project,
      AuthoringQueryRequest(
        resourceKind: 'smartTileDraft',
        operation: AuthoringQueryOperation.get,
        ids: <String>['draft-grass'],
      ),
    );

    final reopened = await openDirect();
    final queryAfter = await readApi.query(
      reopened.project,
      AuthoringQueryRequest(
        resourceKind: 'smartTileDraft',
        operation: AuthoringQueryOperation.get,
        ids: <String>['draft-grass'],
      ),
    );
    final publish = await apply(
      actionId: 'smart_tile.preset.publish',
      parameters: const <String, Object?>{
        'draftId': 'draft-grass',
        'layer': <String, Object?>{
          'mapId': 'map',
          'layerId': 'terrain',
          'name': 'Terrain',
        },
      },
      sequence: 'draft-publish',
      operationId: 'operation-draft-publish',
    );
    return _DraftFlowResult(
      upsertReceipt: _receipt(upsert),
      publishReceipt: _receipt(publish),
      queryBeforeReopen: queryBefore,
      queryAfterReopen: queryAfter,
    );
  }

  Future<_CellFlowResult> applyDirectCellFlow() async {
    final opened = await openDirect();

    Future<Map<String, Object?>> apply(
      String actionId,
      Map<String, Object?> parameters,
      String sequence,
    ) async {
      final snapshot = await snapshots.load(opened.project);
      final plan = await mutations.plan(
        opened.project,
        _request(
          workspaceHandle: opened.workspace.value,
          revision: snapshot.revision,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ),
      );
      return mutations.apply(
        opened.project,
        planId: plan['planId']! as String,
        operationId: 'operation-$sequence',
      );
    }

    final erase = await apply(
      'smart_tile.cell.erase',
      const <String, Object?>{
        'mapId': 'map',
        'layerId': 'terrain',
        'cells': <Map<String, int>>[
          <String, int>{'x': 0, 'y': 0},
        ],
      },
      'cell-erase',
    );
    final paint = await apply(
      'smart_tile.cell.paint',
      const <String, Object?>{
        'mapId': 'map',
        'layerId': 'terrain',
        'materialId': 'grass',
        'cells': <Map<String, int>>[
          <String, int>{'x': 0, 'y': 0},
        ],
      },
      'cell-paint',
    );
    return _CellFlowResult(
      eraseReceipt: _receipt(erase),
      paintReceipt: _receipt(paint),
    );
  }

  Future<AuthoringResult> planJsonlFailure({
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
  }) async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final validation = await _jsonl('validate', <String, Object?>{
      'projectHandle': opened['projectHandle'],
    });
    return _jsonlResult('plan', <String, Object?>{
      'projectHandle': opened['projectHandle'],
      'request': _request(
        workspaceHandle: opened['workspaceHandle']! as String,
        revision: validation['snapshotRevision']! as String,
        actionId: actionId,
        parameters: parameters,
        sequence: sequence,
      ).toJson(),
    });
  }

  Future<_FlowResult> applyJsonlFlow() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;

    Future<Map<String, Object?>> apply({
      required String actionId,
      required Map<String, Object?> parameters,
      required String sequence,
      required String operationId,
    }) async {
      final validation = await _jsonl('validate', <String, Object?>{
        'projectHandle': project,
      });
      final plan = await _jsonl('plan', <String, Object?>{
        'projectHandle': project,
        'request': _request(
          workspaceHandle: workspace,
          revision: validation['snapshotRevision']! as String,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ).toJson(),
      });
      final applied = await _jsonl('apply', <String, Object?>{
        'projectHandle': project,
        'planId': plan['planId'],
        'operationId': operationId,
      });
      return <String, Object?>{
        ...applied,
        'planId': plan['planId'],
      };
    }

    final animation = await apply(
      actionId: 'smart_tile.animation.upsert',
      parameters: <String, Object?>{'animation': _animation().toJson()},
      sequence: 'animation',
      operationId: 'operation-animation',
    );
    final animationReplay = await _jsonl('apply', <String, Object?>{
      'projectHandle': project,
      'planId': animation['planId'],
      'operationId': 'operation-animation',
    });
    final publish = await apply(
      actionId: 'smart_tile.preset.publish',
      parameters: <String, Object?>{
        'preset': _preset().toJson(),
        'layer': const <String, Object?>{
          'mapId': 'map',
          'layerId': 'terrain',
          'name': 'Terrain',
        },
      },
      sequence: 'publish',
      operationId: 'operation-publish',
    );
    final query = await _jsonl('query', <String, Object?>{
      'projectHandle': project,
      'request': AuthoringQueryRequest(
        resourceKind: 'smartTileAnimation',
        operation: AuthoringQueryOperation.list,
      ).toJson(),
    });
    return _FlowResult(
      animationReceipt: _receipt(animation),
      animationReplay: _receipt(animationReplay),
      publishReceipt: _receipt(publish),
      animationQuery: query,
    );
  }

  Future<_DraftFlowResult> applyJsonlDraftFlow() async {
    var opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    var project = opened['projectHandle']! as String;
    var workspace = opened['workspaceHandle']! as String;

    Future<Map<String, Object?>> apply({
      required String actionId,
      required Map<String, Object?> parameters,
      required String sequence,
      required String operationId,
    }) async {
      final validation = await _jsonl('validate', <String, Object?>{
        'projectHandle': project,
      });
      final plan = await _jsonl('plan', <String, Object?>{
        'projectHandle': project,
        'request': _request(
          workspaceHandle: workspace,
          revision: validation['snapshotRevision']! as String,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ).toJson(),
      });
      return _jsonl('apply', <String, Object?>{
        'projectHandle': project,
        'planId': plan['planId'],
        'operationId': operationId,
      });
    }

    final upsert = await apply(
      actionId: 'smart_tile.preset.draft.upsert',
      parameters: <String, Object?>{'draft': _draft().toJson()},
      sequence: 'draft-upsert',
      operationId: 'operation-draft-upsert',
    );
    final queryBefore = await _jsonl('query', <String, Object?>{
      'projectHandle': project,
      'request': AuthoringQueryRequest(
        resourceKind: 'smartTileDraft',
        operation: AuthoringQueryOperation.get,
        ids: <String>['draft-grass'],
      ).toJson(),
    });

    opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    project = opened['projectHandle']! as String;
    workspace = opened['workspaceHandle']! as String;
    final queryAfter = await _jsonl('query', <String, Object?>{
      'projectHandle': project,
      'request': AuthoringQueryRequest(
        resourceKind: 'smartTileDraft',
        operation: AuthoringQueryOperation.get,
        ids: <String>['draft-grass'],
      ).toJson(),
    });
    final publish = await apply(
      actionId: 'smart_tile.preset.publish',
      parameters: const <String, Object?>{
        'draftId': 'draft-grass',
        'layer': <String, Object?>{
          'mapId': 'map',
          'layerId': 'terrain',
          'name': 'Terrain',
        },
      },
      sequence: 'draft-publish',
      operationId: 'operation-draft-publish',
    );
    return _DraftFlowResult(
      upsertReceipt: _receipt(upsert),
      publishReceipt: _receipt(publish),
      queryBeforeReopen: queryBefore,
      queryAfterReopen: queryAfter,
    );
  }

  Future<_CellFlowResult> applyJsonlCellFlow() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;

    Future<Map<String, Object?>> apply(
      String actionId,
      Map<String, Object?> parameters,
      String sequence,
    ) async {
      final validation = await _jsonl('validate', <String, Object?>{
        'projectHandle': project,
      });
      final plan = await _jsonl('plan', <String, Object?>{
        'projectHandle': project,
        'request': _request(
          workspaceHandle: workspace,
          revision: validation['snapshotRevision']! as String,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ).toJson(),
      });
      return _jsonl('apply', <String, Object?>{
        'projectHandle': project,
        'planId': plan['planId'],
        'operationId': 'operation-$sequence',
      });
    }

    final erase = await apply(
      'smart_tile.cell.erase',
      const <String, Object?>{
        'mapId': 'map',
        'layerId': 'terrain',
        'cells': <Map<String, int>>[
          <String, int>{'x': 0, 'y': 0},
        ],
      },
      'cell-erase',
    );
    final paint = await apply(
      'smart_tile.cell.paint',
      const <String, Object?>{
        'mapId': 'map',
        'layerId': 'terrain',
        'materialId': 'grass',
        'cells': <Map<String, int>>[
          <String, int>{'x': 0, 'y': 0},
        ],
      },
      'cell-paint',
    );
    return _CellFlowResult(
      eraseReceipt: _receipt(erase),
      paintReceipt: _receipt(paint),
    );
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

  Future<List<int>> projectBytes() =>
      File('${root.path}/project.json').readAsBytes();

  Future<List<int>> mapBytes() =>
      File('${root.path}/maps/map.json').readAsBytes();

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _FlowResult {
  const _FlowResult({
    required this.animationReceipt,
    required this.animationReplay,
    required this.publishReceipt,
    required this.animationQuery,
  });

  final Map<String, Object?> animationReceipt;
  final Map<String, Object?> animationReplay;
  final Map<String, Object?> publishReceipt;
  final Map<String, Object?> animationQuery;
}

final class _DraftFlowResult {
  const _DraftFlowResult({
    required this.upsertReceipt,
    required this.publishReceipt,
    required this.queryBeforeReopen,
    required this.queryAfterReopen,
  });

  final Map<String, Object?> upsertReceipt;
  final Map<String, Object?> publishReceipt;
  final Map<String, Object?> queryBeforeReopen;
  final Map<String, Object?> queryAfterReopen;
}

final class _CellFlowResult {
  const _CellFlowResult({
    required this.eraseReceipt,
    required this.paintReceipt,
  });

  final Map<String, Object?> eraseReceipt;
  final Map<String, Object?> paintReceipt;
}

AuthoringRequest _request({
  required String workspaceHandle,
  required String revision,
  required String actionId,
  required Map<String, Object?> parameters,
  required String sequence,
}) =>
    AuthoringRequest(
      requestId: 'request-$sequence',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: parameters,
      expectedRevision: revision,
      idempotencyKey: 'idempotency-$sequence',
    );

Map<String, Object?> _receipt(Map<String, Object?> response) =>
    Map<String, Object?>.from(response['receipt']! as Map);

Map<String, Object?> _stableReceipt(Map<String, Object?> receipt) =>
    <String, Object?>{
      'requestId': receipt['requestId'],
      'actionId': receipt['actionId'],
      'actionVersion': receipt['actionVersion'],
      'status': receipt['status'],
      'beforeRevision': receipt['beforeRevision'],
      'afterRevision': receipt['afterRevision'],
      'diff': receipt['diff'],
      'affectedResources': receipt['affectedResources'],
    };

ProjectSmartTileAtlas _atlas({int columns = 1}) => ProjectSmartTileAtlas(
      id: 'atlas',
      name: 'Atlas',
      tilesetId: 'tileset',
      cellWidth: 1,
      cellHeight: 1,
      columns: columns,
      rows: 1,
    );

ProjectSmartTileAnimation _animation() => const ProjectSmartTileAnimation(
      id: 'wind',
      name: 'Wind',
      frames: <ProjectSmartTileAnimationFrame>[
        ProjectSmartTileAnimationFrame(
          frame: SmartTileFrameRef(
            atlasId: 'atlas',
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    );

ProjectSmartTilePreset _preset() => ProjectSmartTilePreset(
      id: 'grass',
      name: 'Grass',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.wang8,
      templateHint: SmartTileTemplateHint.mixed256,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        for (var mask = 0; mask < 256; mask++)
          SmartTileRule(
            id: smartTileCanonicalRuleId(mask),
            centerMatch: const SmartTileSlotMatch.material('grass'),
            signature: smartTileSignatureForMask(
              mask,
              topology: SmartTileTopology.wang8,
            ),
            candidates: <SmartTileCandidate>[
              const SmartTileCandidate(
                id: 'base',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.animation(
                      animationId: 'wind',
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );

ProjectSmartTileAuthoringDraft _draft() => ProjectSmartTileAuthoringDraft(
      id: 'draft-grass',
      targetPresetId: 'grass-draft',
      name: 'Grass draft',
      usage: SmartTileUsage.terrain,
      lastStage: SmartTileAuthoringStage.publish,
      sourceTilesetIds: const <String>['tileset'],
      atlases: <ProjectSmartTileAtlas>[_atlas()],
      primaryAtlasId: 'atlas',
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
        ProjectSmartTileMaterial(
          id: 'water',
          name: 'Water',
          connectionGroupId: 'water',
        ),
        ProjectSmartTileMaterial(
          id: 'stone',
          name: 'Stone',
          connectionGroupId: 'stone',
        ),
      ],
      animations: <ProjectSmartTileAnimation>[_animation()],
      defaultMaterialId: 'grass',
      allowedMaterialIds: const <String>['grass', 'water', 'stone'],
      topology: SmartTileTopology.wang8,
      templateHint: SmartTileTemplateHint.mixed256,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        requiredScenarios: <SmartTileCoverageScenario>[
          SmartTileCoverageScenario(
            id: 'grass-water-stone',
            centerMaterialId: 'grass',
            signature: SmartTileExactSignature(
              northEdge: 'water',
              eastEdge: 'stone',
            ),
          ),
        ],
      ),
      rules: <SmartTileRule>[
        ..._preset().rules,
        const SmartTileRule(
          id: 'grass-water-stone',
          centerMatch: SmartTileSlotMatch.material('grass'),
          signature: SmartTileSignature(
            northEdge: SmartTileSlotMatch.material('water'),
            eastEdge: SmartTileSlotMatch.material('stone'),
          ),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'grass-water-stone-visual',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartTileLayerActions', () {
    test('advertises revisioned, idempotent, undoable canonical actions', () {
      final descriptors = SmartTileLayerActions.descriptors;

      expect(
        descriptors.map((descriptor) => descriptor.id),
        ['smart_tile.layer.merge', 'smart_tile.layer.normalize'],
      );
      for (final descriptor in descriptors) {
        expect(descriptor.guarantees, contains(AuthoringGuarantee.dryRun));
        expect(descriptor.guarantees, contains(AuthoringGuarantee.idempotent));
        expect(
          descriptor.guarantees,
          contains(AuthoringGuarantee.revisionChecked),
        );
        expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      }
    });

    test('rejects pre-v5 normalize and merge without a partial transition', () {
      final fixture = _m01Fixture(version: ProjectVersion.v4);
      final beforeMap = fixture.map.toJson();
      final beforeManifest = fixture.manifest.toJson();
      final beforeBytes = fixture.snapshot.resourceBytes(
        'map:map_hanazuki_village',
      );
      final beforeRevision = fixture.snapshot.revision;
      final cases = <({String actionId, Map<String, Object?> parameters})>[
        (
          actionId: 'smart_tile.layer.normalize',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'layerId': 'l_qc02_terrain',
          },
        ),
        (
          actionId: 'smart_tile.layer.merge',
          parameters: _mergeParameters,
        ),
      ];

      for (final testCase in cases) {
        expect(
          () => const SmartTileLayerActions().build(
            _context(
              fixture.snapshot,
              actionId: testCase.actionId,
              parameters: testCase.parameters,
            ),
          ),
          throwsA(
            isA<MapAuthoringException>()
                .having(
                  (error) => error.code,
                  'code',
                  smartTileNativeAuthoringRequiresStn03Code,
                )
                .having(
                  (error) => error.details['operation'],
                  'operation',
                  testCase.actionId,
                ),
          ),
        );
        expect(fixture.map.toJson(), beforeMap);
        expect(fixture.manifest.toJson(), beforeManifest);
        expect(
          fixture.snapshot.resourceBytes('map:map_hanazuki_village'),
          beforeBytes,
        );
        expect(fixture.snapshot.revision, beforeRevision);
      }
    });

    test('JSONL rejects pre-v5 maintenance without revision or file changes',
        () async {
      for (final testCase in <({
        String slug,
        String actionId,
        Map<String, Object?> parameters,
      })>[
        (
          slug: 'normalize',
          actionId: 'smart_tile.layer.normalize',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'layerId': 'l_qc02_terrain',
          },
        ),
        (
          slug: 'merge',
          actionId: 'smart_tile.layer.merge',
          parameters: _mergeParameters,
        ),
      ]) {
        final harness = await _M01TransportHarness.create(
          'pre_v5_${testCase.slug}',
          version: ProjectVersion.v4,
        );
        addTearDown(harness.dispose);

        final result = await harness.rejectJsonl(
          actionId: testCase.actionId,
          parameters: testCase.parameters,
          sequence: 'reject_${testCase.slug}',
        );

        expect(result.code, smartTileNativeAuthoringRequiresStn03Code);
        expect(result.afterRevision, result.beforeRevision);
        expect(result.afterMapBytes, result.beforeMapBytes);
      }
    });

    test('normalizes the M01 terrain without losing metadata or layer order',
        () {
      final fixture = _m01Fixture();
      final beforeLayer = fixture.map.layers[1] as SmartTileLayer;

      final draft = const SmartTileLayerActions().build(
        _context(
          fixture.snapshot,
          actionId: 'smart_tile.layer.normalize',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'layerId': 'l_qc02_terrain',
          },
        ),
      );
      final projected = _projectedMap(draft);
      final normalized = projected.layers[1] as SmartTileLayer;

      expect(
        projected.layers.map((layer) => layer.id),
        fixture.map.layers.map((layer) => layer.id),
      );
      expect(normalized.materialPalette, ['', 'grass']);
      expect(smartTileSemanticCells(normalized),
          smartTileSemanticCells(beforeLayer));
      expect(
        smartTileHorizontalEdges(normalized),
        smartTileHorizontalEdges(beforeLayer),
      );
      expect(
        smartTileVerticalEdges(normalized),
        smartTileVerticalEdges(beforeLayer),
      );
      expect(smartTileCorners(normalized), smartTileCorners(beforeLayer));
      expect(normalized.id, beforeLayer.id);
      expect(normalized.name, beforeLayer.name);
      expect(normalized.isVisible, beforeLayer.isVisible);
      expect(normalized.opacity, beforeLayer.opacity);
      expect(normalized.presetId, beforeLayer.presetId);
      expect(normalized.usage, beforeLayer.usage);
      expect(normalized.layerSeed, beforeLayer.layerSeed);
      expect(normalized.properties, beforeLayer.properties);
      expect(draft.preview['removedMaterialCount'], 1);
      expect(draft.preview['removedMaterials'], [
        {'materialId': 'smart_material_empty', 'oldIndex': 2},
      ]);
      expect(draft.preview['reindexedEntryCount'], 0);
      expect(
        () => MapValidator.validate(
          projected,
          projectDialogueContext: fixture.manifest,
        ),
        returnsNormally,
      );
    });

    test('normalizes then merges the crossing M01 paths as one exact union',
        () {
      final fixture = _m01Fixture();
      final normalizedDraft = const SmartTileLayerActions().build(
        _context(
          fixture.snapshot,
          actionId: 'smart_tile.layer.normalize',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'layerId': 'l_qc02_terrain',
          },
        ),
      );
      final normalizedMap = _projectedMap(normalizedDraft);
      final normalizedSnapshot = _snapshot(fixture.manifest, normalizedMap);
      final targetBefore = normalizedMap.layers[2] as SmartTileLayer;

      final mergeDraft = const SmartTileLayerActions().build(
        _context(
          normalizedSnapshot,
          actionId: 'smart_tile.layer.merge',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'sourceLayerIds': [
              'l_qc02_path_dirt',
              'l_qc02_path_compacted',
            ],
            'targetLayerId': 'l_qc02_path_dirt',
            'mode': 'union',
            'removeSources': true,
            'conflictPolicy': 'reject',
          },
        ),
      );
      final mergedMap = _projectedMap(mergeDraft);
      final target = mergedMap.layers[2] as SmartTileLayer;

      expect(
        mergedMap.layers.map((layer) => layer.id),
        [
          'l_base',
          'l_qc02_terrain',
          'l_qc02_path_dirt',
          'l_collisions',
        ],
      );
      expect(target.materialPalette, ['', 'dirt']);
      expect(smartTileSemanticCells(target), [0, 1, 0, 1, 1, 1, 0, 1, 0]);
      expect(
        smartTileHorizontalEdges(target),
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
      );
      expect(
        smartTileVerticalEdges(target),
        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
      );
      expect(
        smartTileCorners(target),
        [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      );
      expect(target.id, targetBefore.id);
      expect(target.name, targetBefore.name);
      expect(target.isVisible, targetBefore.isVisible);
      expect(target.opacity, targetBefore.opacity);
      expect(target.presetId, targetBefore.presetId);
      expect(target.usage, targetBefore.usage);
      expect(target.layerSeed, targetBefore.layerSeed);
      expect(target.properties, targetBefore.properties);
      expect(mergeDraft.preview['removedSourceLayerIds'], [
        'l_qc02_path_compacted',
      ]);
      expect(mergeDraft.preview['mergedEntryCount'], 6);
      expect(
        () => MapValidator.validate(
          mergedMap,
          projectDialogueContext: fixture.manifest,
        ),
        returnsNormally,
      );
    });

    test('accepts an explicit material correspondence for compatible presets',
        () {
      final fixture = _m01Fixture(
        sourceMaterialId: 'compacted',
        sourcePresetId: 'path_compacted',
      );
      final normalizedMap = _projectedMap(
        const SmartTileLayerActions().build(
          _context(
            fixture.snapshot,
            actionId: 'smart_tile.layer.normalize',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'layerId': 'l_qc02_terrain',
            },
          ),
        ),
      );

      final draft = const SmartTileLayerActions().build(
        _context(
          _snapshot(fixture.manifest, normalizedMap),
          actionId: 'smart_tile.layer.merge',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'sourceLayerIds': ['l_qc02_path_compacted'],
            'targetLayerId': 'l_qc02_path_dirt',
            'mode': 'union',
            'removeSources': true,
            'conflictPolicy': 'reject',
            'materialMappings': {
              'l_qc02_path_compacted': {'compacted': 'dirt'},
            },
          },
        ),
      );
      final target = _projectedMap(draft).layers[2] as SmartTileLayer;

      expect(target.materialPalette, ['', 'dirt']);
      expect(smartTileSemanticCells(target), [0, 1, 0, 1, 1, 1, 0, 1, 0]);
      expect(draft.preview['materialMappingsApplied'], 1);
    });

    test('rejects incompatible usage before removing a source layer', () {
      final fixture = _m01Fixture(sourceUsage: SmartTileUsage.forestSurface);
      final originalBytes = fixture.snapshot.resourceBytes(
        'map:map_hanazuki_village',
      );

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            fixture.snapshot,
            actionId: 'smart_tile.layer.merge',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'sourceLayerIds': ['l_qc02_path_compacted'],
              'targetLayerId': 'l_qc02_path_dirt',
              'mode': 'union',
              'removeSources': true,
              'conflictPolicy': 'reject',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.layer_usage_incompatible',
          ),
        ),
      );
      expect(
        fixture.snapshot.resourceBytes('map:map_hanazuki_village'),
        originalBytes,
      );
      expect(
        fixture.map.layers.map((layer) => layer.id),
        contains('l_qc02_path_compacted'),
      );
    });

    test('rejects source lattices that do not match the map dimensions', () {
      final fixture = _m01Fixture();
      final source = fixture.map.layers[3] as SmartTileLayer;
      final malformed = fixture.map.copyWith(
        layers: [
          ...fixture.map.layers.take(3),
          source.copyWith(
            field: SmartTileField.mixed(
              semanticCells: smartTileSemanticCells(source).take(8).toList(),
              horizontalEdges: smartTileHorizontalEdges(source),
              verticalEdges: smartTileVerticalEdges(source),
              corners: smartTileCorners(source),
            ),
          ),
          fixture.map.layers[4],
        ],
      );

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            _snapshot(fixture.manifest, malformed),
            actionId: 'smart_tile.layer.merge',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'sourceLayerIds': ['l_qc02_path_compacted'],
              'targetLayerId': 'l_qc02_path_dirt',
              'mode': 'union',
              'removeSources': true,
              'conflictPolicy': 'reject',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'smart_tile.layer_dimensions_incompatible',
              )
              .having(
                (error) => error.details['field'],
                'field',
                'semanticCells',
              ),
        ),
      );
    });

    test('rejects presets with incompatible topology', () {
      final fixture = _m01Fixture();
      final catalog = fixture.manifest.smartTileCatalog;
      final manifest = fixture.manifest.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          formatVersion: catalog.formatVersion,
          categories: catalog.categories,
          atlases: catalog.atlases,
          materials: catalog.materials,
          animations: catalog.animations,
          presets: [
            ...catalog.presets,
            const ProjectSmartTilePreset(
              id: 'path_blob',
              name: 'Blob path',
              usage: SmartTileUsage.path,
              topology: SmartTileTopology.blob8,
              templateHint: SmartTileTemplateHint.blob47,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'dirt',
              allowedMaterialIds: ['dirt'],
            ),
          ],
        ),
      );
      final source = fixture.map.layers[3] as SmartTileLayer;
      final map = fixture.map.copyWith(
        layers: [
          ...fixture.map.layers.take(3),
          source.copyWith(presetId: 'path_blob'),
          fixture.map.layers[4],
        ],
      );

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            _snapshot(manifest, map),
            actionId: 'smart_tile.layer.merge',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'sourceLayerIds': ['l_qc02_path_compacted'],
              'targetLayerId': 'l_qc02_path_dirt',
              'mode': 'union',
              'removeSources': true,
              'conflictPolicy': 'reject',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.layer_preset_incompatible',
          ),
        ),
      );
    });

    test('rejects ambiguous overlaps with lattice and material diagnostics',
        () {
      final fixture = _m01Fixture(conflictingSourceMaterial: 'stone');

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            fixture.snapshot,
            actionId: 'smart_tile.layer.merge',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'sourceLayerIds': ['l_qc02_path_compacted'],
              'targetLayerId': 'l_qc02_path_dirt',
              'mode': 'union',
              'removeSources': false,
              'conflictPolicy': 'reject',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'smart_tile.layer_merge_conflict',
              )
              .having(
                (error) => error.details['lattice'],
                'lattice',
                'semanticCells',
              )
              .having((error) => error.details['offset'], 'offset', 4),
        ),
      );
    });

    test('direct API and JSONL apply the same complete M01 repair', () async {
      final direct = await _M01TransportHarness.create('direct');
      final jsonl = await _M01TransportHarness.create('jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directResult = await direct.applyDirect();
      final jsonlResult = await jsonl.applyJsonl();

      expect(jsonlResult.map.toJson(), directResult.map.toJson());
      expect(directResult.map.version, ProjectVersion.v5);
      expect(jsonlResult.map.version, ProjectVersion.v5);
      expect(directResult.actionIds, [
        'smart_tile.layer.normalize',
        'smart_tile.layer.merge',
      ]);
      expect(jsonlResult.actionIds, directResult.actionIds);
      for (final validation in [
        directResult.validation,
        jsonlResult.validation,
      ]) {
        expect(
          validation['valid'],
          isTrue,
          reason: validation.toString(),
        );
        expect(validation['structure'], containsPair('valid', true));
        expect(validation['references'], containsPair('valid', true));
        expect(
          validation['capabilityCertification'],
          containsPair('status', 'not_requested'),
        );
      }
      expect(
        directResult.map.layers.map((layer) => layer.id),
        [
          'l_base',
          'l_qc02_terrain',
          'l_qc02_path_dirt',
          'l_collisions',
        ],
      );
      final merged = directResult.map.layers[2] as SmartTileLayer;
      expect(smartTileSemanticCells(merged), [0, 1, 0, 1, 1, 1, 0, 1, 0]);
      expect(merged.name, 'Target path metadata');
      expect(merged.properties, {'role': 'main', 'keep': 'yes'});
    });
  });
}

final class _M01TransportHarness {
  const _M01TransportHarness._({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_M01TransportHarness> create(
    String label, {
    ProjectVersion version = ProjectVersion.v5,
  }) async {
    final root = await Directory.systemTemp.createTemp('m01_$label');
    final fixture = _m01Fixture(version: version);
    final persistedManifest = version == ProjectVersion.v5
        ? fixture.manifest
        : fixture.manifest.copyWith(
            smartTileCatalog: ProjectSmartTileCatalog(),
          );
    final persistedMap = version == ProjectVersion.v5
        ? fixture.map
        : fixture.map.copyWith(
            layers: [fixture.map.layers.first, fixture.map.layers.last],
          );
    await Directory('${root.path}/maps').create();
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(persistedManifest.toJson()),
      flush: true,
    );
    await File('${root.path}/maps/map_hanazuki_village.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(persistedMap.toJson()),
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
    return _M01TransportHarness._(
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

  Future<
      ({
        String code,
        String beforeRevision,
        String afterRevision,
        List<int> beforeMapBytes,
        List<int> afterMapBytes,
      })> rejectJsonl({
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
  }) async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final projectHandle = opened['projectHandle']! as String;
    final workspaceHandle = opened['workspaceHandle']! as String;
    final project = ProjectHandle(projectHandle);
    final before = await snapshots.load(project);
    final mapFile = File('${root.path}/maps/map_hanazuki_village.json');
    final beforeMapBytes = await mapFile.readAsBytes();
    final rejected = await _jsonlResult('plan', {
      'projectHandle': projectHandle,
      'request': _transportRequest(
        actionId: actionId,
        parameters: parameters,
        sequence: sequence,
        workspaceHandle: workspaceHandle,
        revision: before.revision,
      ).toJson(),
    });
    expect(rejected.status, AuthoringResultStatus.failure);
    final after = await snapshots.load(project);
    return (
      code: rejected.error?.details['domainCode']! as String,
      beforeRevision: before.revision,
      afterRevision: after.revision,
      beforeMapBytes: beforeMapBytes,
      afterMapBytes: await mapFile.readAsBytes(),
    );
  }

  Future<
      ({
        MapData map,
        Map<String, Object?> validation,
        List<String> actionIds,
      })> applyDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final actionIds = <String>[];

    Future<void> apply(
      String actionId,
      Map<String, Object?> parameters,
      String sequence,
    ) async {
      final snapshot = await snapshots.load(project);
      final planned = await mutations.plan(
        project,
        _transportRequest(
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
          workspaceHandle: workspace.value,
          revision: snapshot.revision,
        ),
      );
      final applied = await mutations.apply(
        project,
        planId: planned['planId']! as String,
        operationId: 'operation_direct_$sequence',
      );
      final receipt = applied['receipt']! as Map<String, Object?>;
      actionIds.add(receipt['actionId']! as String);
    }

    await apply(
      'smart_tile.layer.normalize',
      const {
        'mapId': 'map_hanazuki_village',
        'layerId': 'l_qc02_terrain',
      },
      'normalize',
    );
    await apply(
      'smart_tile.layer.merge',
      _mergeParameters,
      'merge',
    );
    final validation = await readApi.validate(project);
    return (
      map: await _readMap(),
      validation: validation,
      actionIds: actionIds,
    );
  }

  Future<
      ({
        MapData map,
        Map<String, Object?> validation,
        List<String> actionIds,
      })> applyJsonl() async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final projectHandle = opened['projectHandle']! as String;
    final workspaceHandle = opened['workspaceHandle']! as String;
    final actionIds = <String>[];

    Future<void> apply(
      String actionId,
      Map<String, Object?> parameters,
      String sequence,
    ) async {
      final validation = await _jsonl(
        'validate',
        {'projectHandle': projectHandle},
      );
      final planned = await _jsonl('plan', {
        'projectHandle': projectHandle,
        'request': _transportRequest(
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
          workspaceHandle: workspaceHandle,
          revision: validation['snapshotRevision']! as String,
        ).toJson(),
      });
      final applied = await _jsonl('apply', {
        'projectHandle': projectHandle,
        'planId': planned['planId'],
        'operationId': 'operation_jsonl_$sequence',
      });
      final receipt = applied['receipt']! as Map<String, Object?>;
      actionIds.add(receipt['actionId']! as String);
    }

    await apply(
      'smart_tile.layer.normalize',
      const {
        'mapId': 'map_hanazuki_village',
        'layerId': 'l_qc02_terrain',
      },
      'normalize',
    );
    await apply('smart_tile.layer.merge', _mergeParameters, 'merge');
    final validation = await _jsonl(
      'validate',
      {'projectHandle': projectHandle},
    );
    return (
      map: await _readMap(),
      validation: validation,
      actionIds: actionIds,
    );
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final decoded = await _jsonlResult(command, args);
    expect(
      decoded.status,
      AuthoringResultStatus.success,
      reason: decoded.error?.toJson().toString(),
    );
    return decoded.data;
  }

  Future<AuthoringResult> _jsonlResult(
    String command,
    Map<String, Object?> args,
  ) async =>
      AuthoringResult.fromJson(
        jsonDecode(
          await worker.processLine(
            jsonEncode({
              'id': 'm01_$command',
              'command': command,
              'args': args,
            }),
          ),
        ) as Map<String, dynamic>,
      );

  Future<MapData> _readMap() async => MapData.fromJson(
        jsonDecode(
          await File('${root.path}/maps/map_hanazuki_village.json')
              .readAsString(),
        ) as Map<String, dynamic>,
      );

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

const Map<String, Object?> _mergeParameters = {
  'mapId': 'map_hanazuki_village',
  'sourceLayerIds': [
    'l_qc02_path_dirt',
    'l_qc02_path_compacted',
  ],
  'targetLayerId': 'l_qc02_path_dirt',
  'mode': 'union',
  'removeSources': true,
  'conflictPolicy': 'reject',
};

AuthoringRequest _transportRequest({
  required String actionId,
  required Map<String, Object?> parameters,
  required String sequence,
  required String workspaceHandle,
  required String revision,
}) =>
    AuthoringRequest(
      requestId: 'request_$sequence',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: parameters,
      expectedRevision: revision,
      idempotencyKey: 'idem_$sequence',
      dryRun: false,
    );

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request_${actionId.replaceAll('.', '_')}',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'ws_m01',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_${actionId.replaceAll('.', '_')}',
        dryRun: true,
      ),
      planId: 'plan_m01',
      seed: 41,
    );

MapData _projectedMap(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map<String, dynamic>,
    );

({
  ProjectManifest manifest,
  MapData map,
  ProjectSnapshot snapshot,
}) _m01Fixture({
  ProjectVersion version = ProjectVersion.v5,
  String sourceMaterialId = 'dirt',
  String sourcePresetId = 'path',
  SmartTileUsage sourceUsage = SmartTileUsage.path,
  String? conflictingSourceMaterial,
}) {
  final sourceMaterial = conflictingSourceMaterial ?? sourceMaterialId;
  final manifest = ProjectManifest(
    name: 'M01 Smart Tile fixture',
    version: version,
    maps: const [
      ProjectMapEntry(
        id: 'map_hanazuki_village',
        name: 'Hanazuki Village',
        relativePath: 'maps/map_hanazuki_village.json',
      ),
    ],
    tilesets: const [],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
        ProjectSmartTileMaterial(
          id: 'smart_material_empty',
          name: 'Legacy empty',
          connectionGroupId: 'empty',
          isEmpty: true,
        ),
        ProjectSmartTileMaterial(
          id: 'dirt',
          name: 'Dirt',
          connectionGroupId: 'path',
        ),
        ProjectSmartTileMaterial(
          id: 'compacted',
          name: 'Compacted dirt',
          connectionGroupId: 'path',
        ),
        ProjectSmartTileMaterial(
          id: 'stone',
          name: 'Stone',
          connectionGroupId: 'path',
        ),
      ],
      presets: [
        const ProjectSmartTilePreset(
          id: 'terrain',
          name: 'Terrain',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.wang8,
          templateHint: SmartTileTemplateHint.mixed256,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: ['grass'],
        ),
        const ProjectSmartTilePreset(
          id: 'path',
          name: 'Path',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.wang8,
          templateHint: SmartTileTemplateHint.mixed256,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'dirt',
          allowedMaterialIds: ['dirt', 'stone'],
        ),
        const ProjectSmartTilePreset(
          id: 'path_compacted',
          name: 'Compacted path',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.wang8,
          templateHint: SmartTileTemplateHint.mixed256,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'compacted',
          allowedMaterialIds: ['compacted'],
        ),
        if (sourceUsage == SmartTileUsage.forestSurface)
          const ProjectSmartTilePreset(
            id: 'forest',
            name: 'Forest',
            usage: SmartTileUsage.forestSurface,
            topology: SmartTileTopology.wang8,
            templateHint: SmartTileTemplateHint.mixed256,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'dirt',
            allowedMaterialIds: ['dirt'],
          ),
      ],
    ),
  );
  final resolvedSourcePreset =
      sourceUsage == SmartTileUsage.forestSurface ? 'forest' : sourcePresetId;
  final map = MapData(
    id: 'map_hanazuki_village',
    name: 'Hanazuki Village',
    size: const GridSize(width: 3, height: 3),
    version: version,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(9, 0),
      ),
      MapLayer.smartTile(
        id: 'l_qc02_terrain',
        name: 'Terrain metadata',
        isVisible: false,
        opacity: 0.75,
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: const ['', 'grass', 'smart_material_empty'],
        field: SmartTileField.mixed(
          semanticCells: List<int>.filled(9, 1),
          horizontalEdges: List<int>.filled(12, 0),
          verticalEdges: List<int>.filled(12, 0),
          corners: List<int>.filled(16, 0),
        ),
        layerSeed: 71,
        properties: const {'role': 'terrain', 'biome': 'village'},
      ),
      MapLayer.smartTile(
        id: 'l_qc02_path_dirt',
        name: 'Target path metadata',
        isVisible: false,
        opacity: 0.55,
        presetId: 'path',
        usage: SmartTileUsage.path,
        materialPalette: const ['', 'dirt'],
        field: SmartTileField.mixed(
          semanticCells: const [0, 0, 0, 1, 1, 1, 0, 0, 0],
          horizontalEdges: const [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          verticalEdges: List<int>.filled(12, 0),
          corners: List<int>.filled(16, 0),
        ),
        layerSeed: 29,
        properties: const {'role': 'main', 'keep': 'yes'},
      ),
      MapLayer.smartTile(
        id: 'l_qc02_path_compacted',
        name: 'Source path',
        presetId: resolvedSourcePreset,
        usage: sourceUsage,
        materialPalette: ['', sourceMaterial],
        field: const SmartTileField.mixed(
          semanticCells: [0, 1, 0, 0, 1, 0, 0, 1, 0],
          horizontalEdges: [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
          verticalEdges: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
          corners: [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        ),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Collisions',
        collisions: List<bool>.filled(9, false),
      ),
    ],
  );
  return (
    manifest: manifest,
    map: map,
    snapshot: _snapshot(manifest, map),
  );
}

ProjectSnapshot _snapshot(ProjectManifest manifest, MapData map) {
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  final projectRevision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: manifestBytes,
    ),
  ]);
  final mapRevision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'maps/map_hanazuki_village.json',
      bytes: mapBytes,
    ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_m01'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/map_hanazuki_village.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: manifest,
    maps: [map],
    resourceFingerprints: {
      'project': projectRevision,
      'map:map_hanazuki_village': mapRevision,
    },
    resourceStorageKeys: const {
      'project': 'project.json',
      'map:map_hanazuki_village': 'maps/map_hanazuki_village.json',
    },
    resourceBytes: {
      'project': manifestBytes,
      'map:map_hanazuki_village': mapBytes,
    },
  );
}

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('smart_tile.layer.change_preset', () {
    test('reprojects one layer without changing its authored geometry', () {
      final fixture = _fixture();
      final before = fixture.map.layers.single as SmartTileLayer;

      final draft = const SmartTileLayerActions().build(
        _context(
          fixture.snapshot,
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'path',
            'targetPresetId': 'rural-path',
            'materialMappings': <String, Object?>{'dark': 'rural'},
          },
        ),
      );
      final projected = _projectedMap(draft);
      final changed = projected.layers.single as SmartTileLayer;

      expect(changed.id, before.id);
      expect(changed.name, before.name);
      expect(changed.isVisible, before.isVisible);
      expect(changed.opacity, before.opacity);
      expect(changed.usage, before.usage);
      expect(changed.presetId, 'rural-path');
      expect(changed.materialPalette, const <String>['', 'shared', 'rural']);
      expect(
        changed.field,
        const SmartTileField.cell(semanticCells: <int>[2, 1]),
      );
      expect(changed.patternStrokes, before.patternStrokes);
      expect(changed.layerSeed, before.layerSeed);
      expect(changed.properties, before.properties);
      expect(changed.candidateWeights, isEmpty);
      expect(before.presetId, 'dark-path');
      expect(
        before.field,
        const SmartTileField.cell(semanticCells: <int>[1, 2]),
      );
      expect(draft.preview, containsPair('sourcePresetId', 'dark-path'));
      expect(draft.preview, containsPair('targetPresetId', 'rural-path'));
      expect(draft.preview, containsPair('remappedEntryCount', 2));
      expect(draft.preview, containsPair('clearedCandidateWeightCount', 1));
      expect(draft.preview, containsPair('geometryPreserved', true));
      expect(draft.preview, containsPair('batchAtomicity', 'all_or_nothing'));
      expect(draft.changeSet.changes, hasLength(1));
    });

    test('reports mappings required by the target preset', () {
      final fixture = _fixture();

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            fixture.snapshot,
            parameters: const <String, Object?>{
              'mapId': 'map',
              'layerId': 'path',
              'targetPresetId': 'rural-path',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
            (error) => error.code,
            'code',
            'smart_tile.layer_preset_material_mapping_required',
          )
              .having(
            (error) => error.details['requiredMaterialIds'],
            'requiredMaterialIds',
            const <String>['dark'],
          ),
        ),
      );
    });

    test('rejects malformed material mappings before planning', () {
      final fixture = _fixture();

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            fixture.snapshot,
            parameters: const <String, Object?>{
              'mapId': 'map',
              'layerId': 'path',
              'targetPresetId': 'rural-path',
              'materialMappings': <String, Object?>{'dark': 42},
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'map.request_invalid',
          ),
        ),
      );
    });

    test('direct API and JSONL apply the same atomic projection', () async {
      final direct = await _PresetChangeTransportHarness.create('direct');
      final jsonl = await _PresetChangeTransportHarness.create('jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directMap = await direct.applyDirect();
      final jsonlMap = await jsonl.applyJsonl();

      expect(jsonlMap.toJson(), directMap.toJson());
      final changed = directMap.layers.single as SmartTileLayer;
      expect(changed.presetId, 'rural-path');
      expect(changed.field, const SmartTileField.cell(semanticCells: [2, 1]));
    });
  });
}

final class _PresetChangeTransportHarness {
  const _PresetChangeTransportHarness._({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_PresetChangeTransportHarness> create(String label) async {
    final root = await Directory.systemTemp.createTemp('preset_change_$label');
    final fixture = _fixture();
    await Directory('${root.path}/maps').create();
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(fixture.snapshot.manifest.toJson()),
      flush: true,
    );
    await File('${root.path}/maps/map.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(fixture.map.toJson()),
      flush: true,
    );
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
    return _PresetChangeTransportHarness._(
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

  Future<MapData> applyDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final snapshot = await snapshots.load(project);
    final planned = await mutations.plan(
      project,
      _request(
        workspaceHandle: workspace.value,
        revision: snapshot.revision,
        sequence: 'direct',
      ),
    );
    await mutations.apply(
      project,
      planId: planned['planId']! as String,
      operationId: 'operation_direct',
    );
    return _readMap();
  }

  Future<MapData> applyJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final projectHandle = opened['projectHandle']! as String;
    final validation = await _jsonl('validate', <String, Object?>{
      'projectHandle': projectHandle,
    });
    final planned = await _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': _request(
        workspaceHandle: opened['workspaceHandle']! as String,
        revision: validation['snapshotRevision']! as String,
        sequence: 'jsonl',
      ).toJson(),
    });
    await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned['planId'],
      'operationId': 'operation_jsonl',
    });
    return _readMap();
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final result = AuthoringResult.fromJson(
      jsonDecode(
        await worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'preset_change_$command',
            'command': command,
            'args': args,
          }),
        ),
      ) as Map<String, dynamic>,
    );
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: result.error?.toJson().toString(),
    );
    return result.data;
  }

  Future<MapData> _readMap() async => MapData.fromJson(
        jsonDecode(
          await File('${root.path}/maps/map.json').readAsString(),
        ) as Map<String, dynamic>,
      );

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

AuthoringRequest _request({
  required String workspaceHandle,
  required String revision,
  required String sequence,
}) =>
    AuthoringRequest(
      requestId: 'request_$sequence',
      actionId: 'smart_tile.layer.change_preset',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const <String, Object?>{
        'mapId': 'map',
        'layerId': 'path',
        'targetPresetId': 'rural-path',
        'materialMappings': <String, Object?>{'dark': 'rural'},
      },
      expectedRevision: revision,
      idempotencyKey: 'idem_$sequence',
      dryRun: false,
    );

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required Map<String, Object?> parameters,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request_change_preset',
        actionId: 'smart_tile.layer.change_preset',
        actionVersion: 1,
        workspaceHandle: 'workspace',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_change_preset',
        dryRun: true,
      ),
      planId: 'plan_change_preset',
      seed: 41,
    );

MapData _projectedMap(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map<String, dynamic>,
    );

({MapData map, ProjectSnapshot snapshot}) _fixture() {
  final source = _preset(
    id: 'dark-path',
    allowedMaterialIds: const <String>['dark', 'shared'],
  );
  final target = _preset(
    id: 'rural-path',
    allowedMaterialIds: const <String>['shared', 'rural'],
    defaultMaterialId: 'rural',
  );
  final manifest = ProjectManifest(
    name: 'Preset change fixture',
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
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'tiles.png',
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'asset',
          pixelWidth: 32,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tiles',
          columns: 1,
          rows: 1,
        ),
      ],
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'dark',
          name: 'Dark dirt',
          connectionGroupId: 'path',
        ),
        ProjectSmartTileMaterial(
          id: 'shared',
          name: 'Shared dirt',
          connectionGroupId: 'path',
        ),
        ProjectSmartTileMaterial(
          id: 'rural',
          name: 'Rural dirt',
          connectionGroupId: 'path',
        ),
      ],
      presets: <ProjectSmartTilePreset>[source, target],
      patterns: const <ProjectSmartTilePattern>[
        ProjectSmartTilePattern(
          id: 'pattern',
          name: 'Pattern',
          usage: SmartTileUsage.path,
          width: 1,
          height: 1,
          cells: <SmartTilePatternCell>[
            SmartTilePatternCell(
              x: 0,
              y: 0,
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
    ),
  );
  const layer = SmartTileLayer(
    id: 'path',
    name: 'Main path',
    isVisible: false,
    opacity: 0.75,
    presetId: 'dark-path',
    usage: SmartTileUsage.path,
    materialPalette: <String>['', 'dark', 'shared'],
    field: SmartTileField.cell(semanticCells: <int>[1, 2]),
    patternStrokes: <SmartTilePatternStroke>[
      SmartTilePatternStroke(
        id: 'stroke',
        patternId: 'pattern',
        cells: <GridPos>[GridPos(x: 1, y: 0)],
        phaseX: 2,
        phaseY: 3,
      ),
    ],
    layerSeed: 42,
    candidateWeights: <String, int>{'dark-path-candidate': 2},
    properties: <String, String>{'author': 'Yoahn'},
  );
  const map = MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 2, height: 1),
    version: ProjectVersion.v6,
    layers: <MapLayer>[layer],
  );
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  final projectRevision = _fingerprint('project.json', manifestBytes);
  final mapRevision = _fingerprint('maps/map.json', mapBytes);
  return (
    map: map,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('project'),
      revision:
          computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: manifestBytes,
        ),
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/map.json',
          bytes: mapBytes,
        ),
      ]),
      manifest: manifest,
      maps: const <MapData>[map],
      resourceFingerprints: <String, String>{
        'project': projectRevision,
        'map:map': mapRevision,
      },
      resourceStorageKeys: const <String, String>{
        'project': 'project.json',
        'map:map': 'maps/map.json',
      },
      resourceBytes: <String, List<int>>{
        'project': manifestBytes,
        'map:map': mapBytes,
      },
    ),
  );
}

ProjectSmartTilePreset _preset({
  required String id,
  required List<String> allowedMaterialIds,
  String defaultMaterialId = 'dark',
}) =>
    ProjectSmartTilePreset(
      id: id,
      name: id,
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.uniform,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        requiredScenarios: <SmartTileCoverageScenario>[
          SmartTileCoverageScenario(
            id: '$id-center',
            centerMaterialId: defaultMaterialId,
            signature: const SmartTileExactSignature(),
          ),
        ],
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: defaultMaterialId,
      allowedMaterialIds: allowedMaterialIds,
      rules: <SmartTileRule>[
        SmartTileRule(
          id: '$id-rule',
          centerMatch: const SmartTileSlotMatch.any(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: '$id-candidate',
              parts: const <SmartTileVisualPart>[
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

List<int> _encode(Map<String, dynamic> json) => utf8.encode(jsonEncode(json));

String _fingerprint(String path, List<int> bytes) =>
    computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
      NarrativeProjectFingerprintEntry(relativePath: path, bytes: bytes),
    ]);

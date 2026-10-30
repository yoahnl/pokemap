import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../domains/maps/border_face_ground_warning_actions_test.dart'
    show directedCliffAuthoringFixture;
import '../domains/maps/environment_spatial_actions_test.dart'
    show environmentModelGlb;

enum ReliabilityMapVariant {
  healthy,
  shoreGap,
  floatingCliff,
  missingCliff,
  interiorHole,
  dockOverlap,
  ambiguousMaterial,
  noWorkingMap,
  combined,
}

enum ReliabilityStorage { classic, catalog }

final class ReliabilityMapContent {
  ReliabilityMapContent(
      {required this.project,
      required this.map,
      required this.variant,
      required this.reservedVariant});

  static const width = 24;
  static const depth = 16;
  static const hole = GridPos(x: 12, y: 8);
  final ProjectManifest project;
  final MapData map;
  final ReliabilityMapVariant variant;
  final int reservedVariant;
  int get contourY => 4 + reservedVariant;
  List<GridPos> get contour =>
      [for (var x = 3; x <= 6; x++) GridPos(x: x, y: contourY)];
  BorderFeature get feature =>
      map.layers.whereType<BorderLayer>().single.content.features.single;

  static ReliabilityMapContent create(ReliabilityMapVariant variant,
      {int reservedVariant = 0}) {
    if (reservedVariant < 0 || reservedVariant > 3) {
      throw RangeError.range(reservedVariant, 0, 3, 'reservedVariant');
    }
    final base = directedCliffAuthoringFixture(levels: List.filled(24, 1));
    final y = 4 + reservedVariant;
    final floating = variant == ReliabilityMapVariant.floatingCliff ||
        variant == ReliabilityMapVariant.combined;
    final levels = [
      for (var z = 0; z < depth; z++)
        for (var x = 0; x < width; x++) floating || z >= y ? 1 : 0
    ];
    final materials = [
      const ProjectSmartTileMaterial(
          id: 'grass', name: 'Herbe', connectionGroupId: 'land'),
      ProjectSmartTileMaterial(
          id: 'sea',
          name: ['Mer', 'Océan', 'Lagon', 'Eau salée'][reservedVariant],
          connectionGroupId: 'water'),
      if (variant == ReliabilityMapVariant.ambiguousMaterial)
        const ProjectSmartTileMaterial(
            id: 'sea-alternate', name: 'Mer', connectionGroupId: 'other-water'),
    ];
    final catalog = ProjectSmartTileCatalog(
      atlases: const [
        ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Synthetic',
            tilesetId: 'sheet',
            columns: 1,
            rows: 1)
      ],
      materials: materials,
      presets: [
        ProjectSmartTilePreset(
          id: 'ground',
          name: 'Ground',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          templateHint: SmartTileTemplateHint.simple,
          status: SmartTilePresetStatus.published,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: const SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template),
          transformPolicy: const SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: [for (final m in materials) m.id],
          rules: [
            for (final m in materials)
              SmartTileRule(
                id: m.id,
                centerMatch: SmartTileSlotMatch.material(m.id),
                signature: const SmartTileSignature(),
                candidates: const [
                  SmartTileCandidate(id: 'solid', parts: [
                    SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                                atlasId: 'atlas', column: 0, row: 0)))
                  ])
                ],
              )
          ],
        )
      ],
    );
    final cells = [
      for (var z = 0; z < depth; z++)
        for (var x = 0; x < width; x++) z < y ? 2 : 1
    ];
    if (variant == ReliabilityMapVariant.interiorHole ||
        variant == ReliabilityMapVariant.combined) {
      cells[hole.y * width + hole.x] = 0;
    }
    if (variant == ReliabilityMapVariant.shoreGap) {
      for (var x = 3; x <= 6; x++) {
        cells[y * width + x] = 0;
      }
    }
    final source =
        base.map.layers.whereType<BorderLayer>().single.content.features.single;
    final feature = BorderFeature(
        id: source.id,
        name: source.name,
        blueprintId: source.blueprintId,
        seed: source.seed,
        overrides: const [],
        keepOutRegions: const [],
        geometry: BorderStrokeGeometry(strokes: [
          BorderStroke(
              id: 'step',
              points: [for (var x = 3; x <= 6; x++) GridPos(x: x, y: y)],
              closed: false)
        ]));
    var map = MapData(
        version: ProjectVersion.v9,
        id: 'map',
        name: 'Reliability field',
        size: const GridSize(width: width, height: depth),
        properties: const {'unrelated-marker': 'preserve'},
        spatialScene: MapSpatialScene(
            width: width,
            depth: depth,
            heightLevels: levels,
            instances: [
              SpatialModelInstance(
                  id: 'unrelated-object',
                  modelId: 'tree',
                  position: Model3dVector3(x: 20, y: 1, z: 12)),
            ]),
        layers: [
          MapLayer.smartTile(
              id: 'terrain',
              name: 'Terrain',
              presetId: 'ground',
              usage: SmartTileUsage.terrain,
              materialPalette: const ['', 'grass', 'sea'],
              field: SmartTileField.cell(semanticCells: cells)),
          MapLayer.border(
              id: 'border',
              name: 'Cliffs',
              content: BorderLayerContent(
                  features: variant == ReliabilityMapVariant.missingCliff
                      ? []
                      : [feature])),
        ]);
    var project = base.project.copyWith(
        name: 'Synthetic map reliability',
        smartTileCatalog: catalog,
        tilesets: const [
          ProjectTilesetEntry(
              id: 'sheet',
              name: 'Synthetic ground',
              relativePath: 'assets/ground.png')
        ]);
    if (variant == ReliabilityMapVariant.shoreGap) {
      final raw = encodeBorderBlueprintRecordJson(
          project.borderCatalog.records.single,
          formatVersion: 9);
      for (final key in ['draft', 'latestPublished']) {
        final definition = (raw[key] as Map)['definition'] as Map;
        definition['replacesGround'] = true;
        for (final primitive
            in (definition['primitives'] as List).cast<Map>()) {
          primitive['groundSurfaces'] = [
            {
              'sourceSmartTilePresetId': 'ground',
              'materialId': 'grass',
              'height': 0,
              'footprints': [
                [
                  {'x': -.5, 'z': -.5},
                  {'x': .5, 'z': -.5},
                  {'x': .5, 'z': .5},
                  {'x': -.5, 'z': .5},
                ]
              ],
            }
          ];
        }
      }
      project = project.copyWith(
          borderCatalog: ProjectBorderCatalog(formatVersion: 9, records: [
        decodeBorderBlueprintRecordJson(raw, formatVersion: 9)
      ]));
    }
    if (variant != ReliabilityMapVariant.missingCliff) {
      final resolution = resolveSpatialBorderFeature(
          manifest: project, map: map, layerId: 'border', featureId: 'fence');
      if (!resolution.result.canApply) {
        throw StateError(
            'Invalid reliability contour: ${resolution.result.diagnostics}');
      }
      map = applySpatialBorderFeaturePreview(map,
          manifest: project, proposedResult: resolution);
      if (variant == ReliabilityMapVariant.dockOverlap ||
          variant == ReliabilityMapVariant.combined) {
        final module = resolution.modelInstances[1];
        map = map.copyWith(
            spatialScene: map.spatialScene!.copyWith(instances: [
          ...map.spatialScene!.instances,
          SpatialModelInstance(
              id: 'dock',
              modelId: 'cliff',
              position: module.position,
              rotationDegrees: module.rotationDegrees),
        ]));
      }
    }
    return ReliabilityMapContent(
        project: variant == ReliabilityMapVariant.noWorkingMap
            ? project.copyWith(maps: const [])
            : project,
        map: map,
        variant: variant,
        reservedVariant: reservedVariant);
  }
}

final class ReliabilityMapFixture {
  ReliabilityMapFixture._(this.root, this.content, this.storage, this.reader,
      this.dispatcher, this.faultInjector);

  static const defaultQaRoot =
      '/Users/karim/Library/Caches/AveluneQA/mcp-map-reliability/r0';
  final Directory root;
  final ReliabilityMapContent content;
  final ReliabilityStorage storage;
  final ReliabilityCountingReader reader;
  final MapMutationDispatcher? dispatcher;
  final AuthoringTransactionFaultInjector? faultInjector;
  final handles = WorkspaceHandleStore();
  late OpenedProject opened;
  late LocalMapAuthoringMutationApi api;
  late JsonlWorker worker;
  late ProjectSnapshotLoader snapshots;
  final List<Map<String, Object?>> measurements = [];
  int _sequence = 0;
  int jsonlCalls = 0;
  int jsonlRequestBytes = 0;
  int jsonlResponseBytes = 0;
  File get mapFile => File('${root.path}/maps/map.json');

  static Future<ReliabilityMapFixture> create({
    required ReliabilityMapVariant variant,
    ReliabilityStorage storage = ReliabilityStorage.classic,
    int reservedVariant = 0,
    String qaRoot = defaultQaRoot,
    MapMutationDispatcher? dispatcher,
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final owner = Directory(qaRoot);
    await owner.create(recursive: true);
    final root = await owner.createTemp('${storage.name}-${variant.name}-');
    final content =
        ReliabilityMapContent.create(variant, reservedVariant: reservedVariant);
    final fixture = ReliabilityMapFixture._(root, content, storage,
        ReliabilityCountingReader(), dispatcher, faultInjector);
    try {
      if (storage == ReliabilityStorage.catalog) {
        await WorkingProjectCatalog.create(
            store: await CatalogStorageStore.open(projectRoot: root.path),
            projectId: 'map-reliability',
            project: content.project);
      } else {
        await File('${root.path}/project.json')
            .writeAsString(jsonEncode(content.project.toJson()));
      }
      if (variant != ReliabilityMapVariant.noWorkingMap) {
        await fixture.mapFile.parent.create(recursive: true);
        await fixture.mapFile.writeAsString(jsonEncode(content.map.toJson()));
      }
      final assets = <AssetRecord>[];
      for (final model in content.project.models3d) {
        final file = File('${root.path}/${model.relativePath}');
        await file.parent.create(recursive: true);
        final bytes = environmentModelGlb();
        await file.writeAsBytes(bytes);
        final artifact =
            ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
        final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
        await blob.parent.create(recursive: true);
        await blob.writeAsBytes(bytes);
        assets.add(AssetRecord(
            id: model.sourceAssetId,
            logicalPath: model.relativePath,
            artifact: artifact));
      }
      await File('${root.path}/assets/.pokemap-assets.json')
          .writeAsString(jsonEncode(AssetCatalog(records: assets).toJson()));
      final atlas = File('${root.path}/assets/ground.png');
      await atlas.parent.create(recursive: true);
      await atlas.writeAsBytes(image.encodePng(
          image.Image(width: 32, height: 32)
            ..clear(image.ColorRgb8(32, 160, 64))));
      await fixture._open();
      return fixture;
    } catch (_) {
      await root.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> _open() async {
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final loader = ProjectSnapshotLoader(handles: handles);
    snapshots = loader;
    final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {});
    opened = await opener.openProject(root.path);
    api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        catalogFileReader: reader,
        dispatcher: dispatcher,
        faultInjector: faultInjector);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    worker = JsonlWorker(
        api: AuthoringReadApi(openService: opener, snapshotLoader: loader),
        mutations: api);
  }

  Future<AuthoringMutationPlanResult> plan(
      String action, Map<String, Object?> parameters,
      {String? identity, bool confirm = false}) async {
    final id = identity ?? 'reference-${_sequence++}';
    final snapshot = storage == ReliabilityStorage.catalog
        ? await api.readWorkshopSnapshot(opened.projectHandle,
            actionId: action, parameters: parameters)
        : await snapshots.load(opened.projectHandle);
    return api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: id,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
            parameters: parameters));
  }

  Future<AuthoringMutationResult> apply(
      String action, Map<String, Object?> parameters,
      {String? identity, bool confirm = false}) async {
    final id = identity ?? 'reference-${_sequence++}';
    reader.paths.clear();
    final timer = Stopwatch()..start();
    final prepared = await plan(action, parameters, identity: id);
    final plannedUs = timer.elapsedMicroseconds;
    final token = confirm
        ? (await api.confirmMutation(opened.projectHandle,
                planId: prepared.planId))
            .confirmationToken
        : null;
    final result = await api.applyMutation(opened.projectHandle,
        planId: prepared.planId, operationId: id, confirmationToken: token);
    timer.stop();
    measurements.add({
      'actionId': action,
      'storage': storage.name,
      'phase': measurements.isEmpty ? 'first' : 'repeated',
      'planUs': plannedUs,
      'durableUs': timer.elapsedMicroseconds,
      'readerCalls': reader.paths.length,
      'changedResources': result.receipt.affectedResources.length,
      'mcpCalls': 0,
      'jsonlCalls': 0
    });
    return result;
  }

  Future<AuthoringResult> command(
      String command, Map<String, Object?> args) async {
    final line = jsonEncode(
        {'id': 'jsonl-${_sequence++}', 'command': command, 'args': args});
    jsonlCalls++;
    jsonlRequestBytes += utf8.encode(line).length;
    final response = await worker.processLine(line);
    jsonlResponseBytes += utf8.encode(response).length;
    return AuthoringResult.fromJson(jsonDecode(response));
  }

  Future<MapData> readMap() async =>
      MapData.fromJson(jsonDecode(await mapFile.readAsString()));

  Future<void> reopen() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await _open();
  }

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class ReliabilityCountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader,
        ProjectResourceIdentityReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<ProjectResourceIdentity?> readIdentity(
          {required String projectRoot, required String relativePath}) =>
      delegate.readIdentity(
          projectRoot: projectRoot, relativePath: relativePath);
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}

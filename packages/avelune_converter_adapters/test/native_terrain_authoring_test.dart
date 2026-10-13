import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart'
    hide PixelOffset, PixelSize;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/original_asset_fixture.dart';

void main() {
  for (final direct in [true, false]) {
    test(
        'converted terrain and whole tree are authored and reopened through ${direct ? 'direct API' : 'JSONL'}',
        () async {
      final root = await Directory.systemTemp
          .createTemp('native-terrain-authoring-original-');
      addTearDown(() => root.delete(recursive: true));
      final fixture = await OriginalAssetFixture.create(
          sourceRootPath: '${root.path}/source', includeTerrainPixels: true);
      final sourceBefore = await _treeBytes('${root.path}/source');
      final output = await Directory('${root.path}/output').create();
      final literal = await fixture.compose(parentPath: output.path);
      final candidates = [fixture.terrainCandidate(), fixture.treeCandidate()]
          .map((candidate) => AssetCandidate.fromJson({
                ...candidate.toJson(),
                'state': 'approved',
                'approvedRevision': candidate.revision,
              }))
          .toList();
      expect(candidates.first.terrainLayout, AssetTerrainLayout.cardinal3x3);
      final decisions = _decisions(fixture, candidates);
      final library = await const ApprovedAssetLibraryComposer().compose(
          source: fixture.literalFixture.source,
          files: fixture.literalFixture.files,
          candidates: candidates,
          approvedCandidateHashes: {
            for (final candidate in candidates)
              candidate.candidateId: candidate.canonicalHash,
          },
          decisions: decisions,
          outputMode: AssetOutputMode.standaloneObjects);
      expect(library.canExport, isTrue);
      final base = literal.draft!;
      final draft = NativeProjectDraft(
          source: base.source,
          projectName: base.projectName,
          parentPath: base.parentPath,
          folderName: base.folderName,
          sourceRootPath: base.sourceRootPath,
          mapIds: base.mapIds,
          artifacts: {
            for (final artifact in [...base.artifacts, ...library.artifacts])
              artifact.handle: artifact,
          }.values.toList(),
          sourceArtifacts: library.sourceArtifacts,
          mutations: [...base.mutations, ...library.mutations],
          compositionEvidence: {
            ...base.compositionEvidence,
            'assetLibrary': library.evidence,
          },
          defaultMapWidth: base.defaultMapWidth,
          defaultMapHeight: base.defaultMapHeight);
      final approval = _approve(draft, candidates, decisions);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, draft);
      expect(receipt.verified, isTrue);
      var session = await _NativeSession.open(receipt.projectPath, direct);
      addTearDown(() => session.close());
      final described = await session.command('describe', {});
      expect(
          (described['mutationActions'] as List)
              .map((value) => (value as Map)['id']),
          containsAll([
            'smart_tile.layer.create',
            'smart_tile.cell.paint_batch',
            'smart_tile.cell.erase',
            'placed_element.place',
          ]));
      final initial = await session.load();
      final mapId = draft.mapIds[12]!;
      final originalMap = initial.mapById(mapId)!;
      final originalOtherMaps = {
        for (final entry in initial.manifest.maps)
          if (entry.id != mapId)
            entry.relativePath:
                await File('${receipt.projectPath}/${entry.relativePath}')
                    .readAsBytes(),
      };
      final originalAssets = {
        for (final tileset in initial.manifest.tilesets)
          tileset.relativePath:
              await File('${receipt.projectPath}/${tileset.relativePath}')
                  .readAsBytes(),
      };
      final preset = initial.manifest.smartTileCatalog.presets.single;
      final materialId = preset.defaultMaterialId;
      final terrainBinding = library.candidateBindings.singleWhere(
          (binding) => binding.candidateId == candidates.first.candidateId);
      final treeBinding = library.candidateBindings.singleWhere(
          (binding) => binding.candidateId == candidates.last.candidateId);
      final tree = initial.manifest.elements
          .singleWhere((element) => element.id == treeBinding.nativeElementId);
      expect(tree.collisionProfile, isNull);
      expect(tree.frames.single.source.width, 2);
      expect(tree.frames.single.source.height, 3);
      final treeTileset = initial.manifest.tilesets
          .singleWhere((tileset) => tileset.id == tree.tilesetId);
      final treeRaster = image.decodePng(
          Uint8List.fromList(originalAssets[treeTileset.relativePath]!))!;
      expect((treeRaster.width, treeRaster.height), (64, 96));
      expect(treeRaster.getBytes(order: image.ChannelOrder.rgba),
          fixture.expectedTreeRgba);
      final coverage = analyzeSmartTileCoverage(
          preset: preset,
          materials: initial.manifest.smartTileCatalog.materials,
          atlases: initial.manifest.smartTileCatalog.atlases,
          animations: initial.manifest.smartTileCatalog.animations);
      expect(coverage.isExact, isTrue);
      expect(coverage.cases, hasLength(16));
      await session.mutate('smart_tile.layer.create', {
        'mapId': mapId,
        'presetId': preset.id,
        'layerId': 'authored-path',
        'name': 'Chemin contrôlé',
        'insertIndex': 0,
      });
      final atlas = initial.manifest.smartTileCatalog.atlases.single;
      final terrainTileset = initial.manifest.tilesets
          .singleWhere((tileset) => tileset.id == atlas.tilesetId);
      final terrainRaster = image.decodePng(
          Uint8List.fromList(originalAssets[terrainTileset.relativePath]!))!;
      expect((terrainRaster.width, terrainRaster.height), (128, 128));
      expect(terrainBinding.record['placementsSubstituted'], isFalse);

      Future<void> check(Map<(int, int), int> masks) async {
        final snapshot = await session.load();
        final map = snapshot.mapById(mapId)!;
        expect((await session.readMap(mapId)).toJson(), map.toJson());
        expect(mapPaintsFirstLayerInFront(map), isTrue);
        expect(map.layers.first.id, 'authored-path');
        expect(
            buildMapVisualCompositionPlan(map)
                .plan!
                .authoredLayerSteps
                .last
                .layer!
                .id,
            'authored-path');
        _expectVisuals(map, snapshot.manifest, masks, terrainRaster, fixture);
        expect(
            map
                .copyWith(
                    layers: map.layers
                        .where((layer) => layer.id != 'authored-path')
                        .toList(),
                    placedElements: map.placedElements
                        .where((instance) => instance.id != 'authored-tree')
                        .toList())
                .toJson(),
            originalMap.toJson());
      }

      await check({});
      await session.paint(mapId, materialId, const [(3, 2)]);
      await check({(3, 2): 0});
      await session.paint(mapId, materialId, const [(0, 0), (0, 1), (1, 1)]);
      await check({(0, 0): 4, (0, 1): 3, (1, 1): 8, (3, 2): 0});
      await session.erase(mapId, const [(0, 0), (0, 1), (1, 1)]);
      await session
          .paint(mapId, materialId, const [(0, 0), (1, 0), (2, 0), (1, 1)]);
      await check({(0, 0): 2, (1, 0): 14, (2, 0): 8, (1, 1): 1, (3, 2): 0});
      await session.mutate('placed_element.place', {
        'mapId': mapId,
        'instance': MapPlacedElement(
                id: 'authored-tree',
                layerId: originalMap.layers.first.id,
                elementId: tree.id,
                pos: const GridPos(x: 2, y: 0))
            .toJson(),
      });
      await session.close();
      session = await _NativeSession.open(receipt.projectPath, direct);
      await check({(0, 0): 2, (1, 0): 14, (2, 0): 8, (1, 1): 1, (3, 2): 0});
      final reloaded = await session.load();
      final instance = reloaded
          .mapById(mapId)!
          .placedElements
          .singleWhere((instance) => instance.id == 'authored-tree');
      final geometry = resolveMapPlacedElementGeometry(
          instance: instance,
          element: tree,
          tileSize: const PixelSize(width: 32, height: 32));
      expect(geometry.naturalPixelSize, const PixelSize(width: 64, height: 96));
      expect(geometry.pixelSize, const PixelSize(width: 64, height: 96));
      expect(
          (geometry.logicalRect.leftPx, geometry.logicalRect.topPx), (64, 0));
      expect(
          resolveMapPlacedElementCollisionRects(
              instance: instance,
              element: tree,
              tileSize: const PixelSize(width: 32, height: 32)),
          isEmpty);
      await session.erase(mapId, const [(1, 0)]);
      await check({(0, 0): 0, (2, 0): 0, (1, 1): 0, (3, 2): 0});
      await session.erase(mapId, const [(0, 0), (2, 0), (1, 1), (3, 2)]);
      await session.close();
      session = await _NativeSession.open(receipt.projectPath, direct);
      await check({});
      for (final entry in {...originalOtherMaps, ...originalAssets}.entries) {
        expect(await File('${receipt.projectPath}/${entry.key}').readAsBytes(),
            entry.value,
            reason: entry.key);
      }
      expect(await _treeBytes('${root.path}/source'), sourceBefore);
      final validation = await session.api.validateProject(session.project);
      expect(validation.structure.valid, isTrue);
      expect(validation.references.valid, isTrue);
    });
  }
}

void _expectVisuals(
    MapData map,
    ProjectManifest manifest,
    Map<(int, int), int> masks,
    image.Image atlas,
    OriginalAssetFixture original) {
  final layer = map.layers.whereType<SmartTileLayer>().single;
  final field = layer.field as SmartTileCellField;
  for (var y = 0; y < map.size.height; y++) {
    for (var x = 0; x < map.size.width; x++) {
      final index = field.semanticCells[y * map.size.width + x];
      expect(index != 0, masks.containsKey((x, y)), reason: 'cell($x,$y)');
    }
  }
  final preset = manifest.smartTileCatalog.presets.single;
  final plan = buildSmartTileLayerVisualPlan(
      map: map,
      layer: layer,
      catalog: manifest.smartTileCatalog,
      pass: SmartTileVisualPass.background,
      destinationCellWidth: 32,
      destinationCellHeight: 32);
  final visuals = plan.resolveBatch().visuals;
  expect(visuals, hasLength(masks.length));
  for (final visual in visuals) {
    final mask = masks[(visual.cellX, visual.cellY)]!;
    final rule = preset.rules.singleWhere((rule) => rule.id == visual.ruleId);
    final wanted =
        smartTileSignatureForMask(mask, topology: SmartTileTopology.cardinal4);
    expect(rule.signature.toJson(), wanted.toJson());
    final rect = visual.sourceRect;
    expect((rect.width, rect.height), (32, 32));
    expect(
        visual.geometry.visualBounds,
        SmartTileGeometryRect(
            left: visual.cellX * 32.0,
            top: visual.cellY * 32.0,
            width: 32,
            height: 32));
    final expected = Uint8List(32 * 32 * 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final left = x < 16;
        final top = y < 16;
        final connectedHorizontal = mask & (left ? 8 : 2) != 0;
        final connectedVertical = mask & (top ? 1 : 4) != 0;
        final column = connectedHorizontal ? 1 : (left ? 0 : 2);
        final row = connectedVertical ? 1 : (top ? 0 : 2);
        final sourceX = column * 32 + x;
        final sourceY = 96 + row * 32 + y;
        final offset = (sourceY * OriginalAssetFixture.width + sourceX) * 4;
        expected.setRange((y * 32 + x) * 4, (y * 32 + x) * 4 + 4,
            original.rgba.sublist(offset, offset + 4));
      }
    }
    expect(
        image
            .copyCrop(atlas,
                x: rect.x, y: rect.y, width: rect.width, height: rect.height)
            .getBytes(order: image.ChannelOrder.rgba),
        expected,
        reason: 'mask=$mask cell(${visual.cellX},${visual.cellY})');
  }
}

ReviewDecisions _decisions(
        OriginalAssetFixture fixture, List<AssetCandidate> candidates) =>
    ReviewDecisions.fromJson({
      'schemaVersion': '1.0',
      'kind': 'reviewDecisions',
      'exampleOnly': false,
      'sessionId': 'native-terrain-authoring-original',
      'sourceSnapshotHash': fixture.literalFixture.snapshot.canonicalHash.value,
      'revision': 1,
      'decisions': [
        for (final candidate in candidates)
          {
            'decisionId': 'approve:${candidate.candidateId.value}',
            'candidateId': candidate.candidateId.value,
            'candidateRevision': candidate.revision,
            'action': 'approve',
            'humanConfirmed': true,
            'replacementCandidateIds': <String>[],
            'note': 'Original synthetic fixture approval',
          }
      ],
    });

NativeFixtureApproval _approve(NativeProjectDraft draft,
    List<AssetCandidate> candidates, ReviewDecisions decisions) {
  final base = approveNativeFixtureDraft(draft);
  final plan = ConversionPlan.fromJson({
    ...base.plan.toJson(),
    'decisionsHash': decisions.canonicalHash.value,
    'decisionRevision': decisions.revision,
    'outputPolicy': {
      ...base.plan.outputPolicy.toJson(),
      'assetOutputMode': AssetOutputMode.standaloneObjects.name
    },
    'operations': [
      for (final raw in base.plan.toJson()['operations'] as List)
        {
          ...(raw as Map),
          'domain': (raw['targetActionId'] as String).startsWith('map.')
              ? 'maps'
              : 'assets',
        }
    ],
  });
  return NativeFixtureApproval(
      plan,
      PlanContext(
          logicalProjectNamespace: base.context.logicalProjectNamespace,
          sourceSnapshotHash: base.context.sourceSnapshotHash,
          sessionId: decisions.sessionId,
          targetCapabilities: base.context.targetCapabilities,
          rulesHash: base.context.rulesHash,
          decisions: decisions,
          candidates: candidates,
          converterVersion: base.context.converterVersion,
          approvedPlanHash: plan.canonicalHash,
          sourceMapIds: base.context.sourceMapIds,
          sourceEntityIds: base.context.sourceEntityIds,
          targetEntityIds: base.context.targetEntityIds,
          actionCapabilities: base.context.actionCapabilities,
          approvedCandidateHashes: {
            for (final candidate in candidates)
              candidate.candidateId: candidate.canonicalHash
          }));
}

Future<Map<String, List<int>>> _treeBytes(String path) async => {
      for (final file in await Directory(path)
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList())
        file.path.substring(path.length + 1): await file.readAsBytes(),
    };

final class _NativeSession {
  _NativeSession(this.direct, this.handles, this.snapshots, this.api,
      this.mutations, this.worker, this.project, this.workspace);

  final bool direct;
  final WorkspaceHandleStore handles;
  final ProjectSnapshotLoader snapshots;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  var _sequence = 0;
  var _closed = false;

  static Future<_NativeSession> open(String path, bool direct) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final worker = JsonlWorker(api: api, mutations: mutations);
    late ProjectHandle project;
    late WorkspaceHandle workspace;
    if (direct) {
      final opened = await api.openProject(path);
      project = opened.projectHandle;
      workspace = opened.workspaceHandle;
      await mutations.attachProject(
          projectRootPath: path,
          workspaceHandle: workspace,
          projectHandle: project);
    } else {
      final result = AuthoringResult.fromJson(
          jsonDecode(await worker.processLine(jsonEncode({
        'id': 'open',
        'command': 'open',
        'args': {'projectRoot': path}
      }))));
      expect(result.status, AuthoringResultStatus.success,
          reason: result.toJson().toString());
      project = ProjectHandle(result.data['projectHandle'] as String);
      workspace = WorkspaceHandle(result.data['workspaceHandle'] as String);
    }
    return _NativeSession(
        direct, handles, snapshots, api, mutations, worker, project, workspace);
  }

  Future<ProjectSnapshot> load() => snapshots.load(project);

  Future<MapData> readMap(String mapId) async {
    final request = AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: [mapId]);
    final queried = direct
        ? await api.query(project, request)
        : await command('query', {
            'projectHandle': project.value,
            'request': request.toJson(),
          });
    return MapData.fromJson(
        Map<String, dynamic>.from((queried['items'] as List).single as Map));
  }

  Future<Map<String, Object?>> command(
      String command, Map<String, Object?> arguments) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
        jsonEncode({
      'id': 'jsonl-${++_sequence}',
      'command': command,
      'args': arguments
    }))));
    expect(result.status, AuthoringResultStatus.success,
        reason: result.toJson().toString());
    return result.data;
  }

  Future<void> mutate(String action, Map<String, Object?> parameters) async {
    final snapshot = await load();
    final id = 'terrain-${++_sequence}';
    final request = AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: id);
    final planned = direct
        ? await mutations.plan(project, request)
        : await command('plan',
            {'projectHandle': project.value, 'request': request.toJson()});
    expect((await load()).revision, snapshot.revision);
    final applied = direct
        ? await mutations.apply(project,
            planId: planned['planId'] as String, operationId: 'apply-$id')
        : await command('apply', {
            'projectHandle': project.value,
            'planId': planned['planId'],
            'operationId': 'apply-$id'
          });
    expect((applied['receipt'] as Map)['status'], 'applied');
  }

  Future<void> paint(String mapId, String materialId, List<(int, int)> cells) =>
      mutate('smart_tile.cell.paint_batch', {
        'mapId': mapId,
        'layerId': 'authored-path',
        'strokes': [
          {
            'materialId': materialId,
            'cells': [
              for (final (x, y) in cells) {'x': x, 'y': y}
            ]
          }
        ],
      });

  Future<void> erase(String mapId, List<(int, int)> cells) =>
      mutate('smart_tile.cell.erase', {
        'mapId': mapId,
        'layerId': 'authored-path',
        'cells': [
          for (final (x, y) in cells) {'x': x, 'y': y}
        ],
      });

  Future<void> close() async {
    if (_closed) return;
    if (direct) {
      await mutations.detachWorkspace(workspace);
      await api.closeWorkspace(workspace);
    } else {
      await command('close', {'workspaceHandle': workspace.value});
    }
    _closed = true;
  }
}

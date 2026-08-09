import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sourceProjectFile = Platform.environment['POKEMAP_STN14_PROJECT'];
  final mapId = Platform.environment['POKEMAP_STN14_MAP_ID'] ??
      'route_hanazuki_vers_gare_hanazuki';
  final layerId = Platform.environment['POKEMAP_STN14_LAYER_ID'] ??
      'smart_path_erw_hanazuki_dirt_dark_layer';
  final targetPresetId =
      Platform.environment['POKEMAP_STN14_TARGET_PRESET_ID'] ??
          'smart_path_path_global_dirt';

  test(
    'licensed ERW project changes appearance without changing its trace',
    () async {
      final sourceFile = File(sourceProjectFile!);
      final temporaryRoot =
          await Directory.systemTemp.createTemp('stn_14_4_erw_');
      addTearDown(() async {
        if (await temporaryRoot.exists()) {
          await temporaryRoot.delete(recursive: true);
        }
      });
      final projectRoot = Directory('${temporaryRoot.path}/project');
      await _copyProject(Directory(sourceFile.parent.path), projectRoot);
      final projectFilePath =
          p.join(projectRoot.path, p.basename(sourceFile.path));
      final projectFile = File(projectFilePath);
      final projectBytes = await projectFile.readAsBytes();
      final beforeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      final sourceLayer = _layerById(beforeBundle.map, layerId);
      final targetPreset = beforeBundle.manifest.smartTileCatalog.presets
          .where((preset) => preset.id == targetPresetId)
          .firstOrNull;
      final sourcePreset = beforeBundle.manifest.smartTileCatalog.presets
          .where((preset) => preset.id == sourceLayer.presetId)
          .firstOrNull;
      expect(sourcePreset, isNotNull);
      expect(targetPreset, isNotNull);
      final mappingProbe = planSmartTileLayerPresetChange(
        map: beforeBundle.map,
        layer: sourceLayer,
        sourcePreset: sourcePreset!,
        targetPreset: targetPreset!,
        catalog: beforeBundle.manifest.smartTileCatalog,
      );
      final requiredMappings = switch (mappingProbe) {
        SmartTileLayerPresetChangeFailure(:final requiredMaterialIds) =>
          requiredMaterialIds,
        SmartTileLayerPresetChangeSuccess() => const <String>[],
      };
      final materialMappings = <String, String>{
        for (final materialId in requiredMappings)
          materialId: targetPreset.defaultMaterialId,
      };
      final mappedProbe = planSmartTileLayerPresetChange(
        map: beforeBundle.map,
        layer: sourceLayer,
        sourcePreset: sourcePreset,
        targetPreset: targetPreset,
        catalog: beforeBundle.manifest.smartTileCatalog,
        materialMappings: materialMappings,
      );
      expect(mappedProbe, isA<SmartTileLayerPresetChangeSuccess>());
      final region = _renderRegion(beforeBundle, sourceLayer);
      final beforeRender = await _renderBundleRegion(beforeBundle, region);
      addTearDown(beforeRender.dispose);
      final beforePixels = await _rgbaBytes(beforeRender);
      final beforeLayerIds = beforeBundle.map.layers
          .map((layer) => layer.id)
          .toList(growable: false);
      final beforeOccupancy = _occupiedCells(sourceLayer);
      final beforeZones = jsonEncode(
        beforeBundle.map.gameplayZones
            .map((zone) => zone.toJson())
            .toList(growable: false),
      );

      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: <String>[projectRoot.path],
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
      final opened = await readApi.open(projectRoot.path);
      final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
      final project = ProjectHandle(opened['projectHandle']! as String);
      await mutations.attachProject(
        projectRootPath: projectRoot.path,
        workspaceHandle: workspace,
        projectHandle: project,
      );
      final snapshot = await snapshots.load(project);
      final planned = await mutations.plan(
        project,
        _request(
          workspaceHandle: workspace.value,
          revision: snapshot.revision,
          mapId: mapId,
          layerId: layerId,
          targetPresetId: targetPresetId,
          materialMappings: materialMappings,
          sequence: 'apply',
        ),
      );
      final applied = await mutations.apply(
        project,
        planId: planned['planId']! as String,
        operationId: 'stn-14-4-erw-apply',
      );
      final receipt = applied['receipt']! as Map<String, Object?>;
      final afterBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      final changedLayer = _layerById(afterBundle.map, layerId);
      final afterRender = await _renderBundleRegion(afterBundle, region);
      addTearDown(afterRender.dispose);
      final afterPixels = await _rgbaBytes(afterRender);

      expect(afterBundle.map.layers.map((layer) => layer.id), beforeLayerIds);
      expect(changedLayer.id, sourceLayer.id);
      expect(changedLayer.presetId, targetPresetId);
      expect(_occupiedCells(changedLayer), beforeOccupancy);
      expect(afterPixels, isNot(orderedEquals(beforePixels)));
      expect(afterPixels.any((value) => value != 0), isTrue);
      expect(
        jsonEncode(
          afterBundle.map.gameplayZones
              .map((zone) => zone.toJson())
              .toList(growable: false),
        ),
        beforeZones,
      );
      expect(await projectFile.readAsBytes(), projectBytes);

      await mutations.undo(
        project,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'stn-14-4-erw-undo',
      );
      final undoneBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      expect(
          _layerById(undoneBundle.map, layerId).presetId, sourceLayer.presetId);

      final undoneSnapshot = await snapshots.load(project);
      final redoPlan = await mutations.plan(
        project,
        _request(
          workspaceHandle: workspace.value,
          revision: undoneSnapshot.revision,
          mapId: mapId,
          layerId: layerId,
          targetPresetId: targetPresetId,
          materialMappings: materialMappings,
          sequence: 'redo',
        ),
      );
      await mutations.apply(
        project,
        planId: redoPlan['planId']! as String,
        operationId: 'stn-14-4-erw-redo',
      );
      final redoneBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      expect(_layerById(redoneBundle.map, layerId).presetId, targetPresetId);
      expect(_occupiedCells(_layerById(redoneBundle.map, layerId)),
          beforeOccupancy);
      expect(await projectFile.readAsBytes(), projectBytes);
    },
    skip: sourceProjectFile == null
        ? 'Set POKEMAP_STN14_PROJECT to a licensed project.json copy source.'
        : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

AuthoringRequest _request({
  required String workspaceHandle,
  required String revision,
  required String mapId,
  required String layerId,
  required String targetPresetId,
  required Map<String, String> materialMappings,
  required String sequence,
}) =>
    AuthoringRequest(
      requestId: 'stn-14-4-erw-$sequence',
      actionId: 'smart_tile.layer.change_preset',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: <String, Object?>{
        'mapId': mapId,
        'layerId': layerId,
        'targetPresetId': targetPresetId,
        if (materialMappings.isNotEmpty) 'materialMappings': materialMappings,
      },
      expectedRevision: revision,
      idempotencyKey: 'stn-14-4-erw-$sequence',
      dryRun: false,
    );

SmartTileLayer _layerById(MapData map, String layerId) => map.layers
    .whereType<SmartTileLayer>()
    .where((layer) => layer.id == layerId)
    .single;

List<bool> _occupiedCells(SmartTileLayer layer) =>
    smartTileSemanticCells(layer).map((value) => value != 0).toList();

Rect _renderRegion(RuntimeMapBundle bundle, SmartTileLayer layer) {
  final cells = smartTileSemanticCells(layer);
  final first = cells.indexWhere((value) => value != 0);
  if (first < 0) throw StateError('The licensed source layer is empty.');
  final x = first % bundle.map.size.width;
  final y = first ~/ bundle.map.size.width;
  final leftCell = (x - 2).clamp(0, bundle.map.size.width - 1);
  final topCell = (y - 2).clamp(0, bundle.map.size.height - 1);
  final widthCells = (bundle.map.size.width - leftCell).clamp(1, 5);
  final heightCells = (bundle.map.size.height - topCell).clamp(1, 5);
  return Rect.fromLTWH(
    leftCell * bundle.cellWidth,
    topCell * bundle.cellHeight,
    widthCells * bundle.cellWidth,
    heightCells * bundle.cellHeight,
  );
}

Future<ui.Image> _renderBundleRegion(
  RuntimeMapBundle bundle,
  Rect region,
) async {
  final images = await loadTilesetImagesById(bundle.tilesetAbsolutePathsById);
  try {
    final component = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: images,
    )..setVisibleLocalRect(region);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..translate(-region.left, -region.top);
    component.render(canvas);
    return await recorder.endRecording().toImage(
          region.width.ceil(),
          region.height.ceil(),
        );
  } finally {
    final uniqueImages = Set<RuntimeTilesetImage>.identity()
      ..addAll(images.values);
    for (final image in uniqueImages) {
      image.dispose();
    }
  }
}

Future<List<int>> _rgbaBytes(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes!.buffer.asUint8List();
}

Future<void> _copyProject(Directory source, Directory target) async {
  await target.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final name = p.basename(entity.path);
    if (name == '.git' ||
        name.endsWith('.lock') ||
        name.startsWith('.pokemap-project-')) {
      continue;
    }
    final destination = p.join(target.path, name);
    if (entity is Directory) {
      await _copyProject(entity, Directory(destination));
    } else if (entity is File) {
      await entity.copy(destination);
    } else if (entity is Link) {
      await Link(destination).create(await entity.target());
    }
  }
}

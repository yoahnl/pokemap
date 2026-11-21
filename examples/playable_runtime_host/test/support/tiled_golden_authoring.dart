import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../packages/map_authoring/bin/src/tiled_image_collection_cli_png_codec.dart';

Future<({ProjectSnapshot imported, ProjectSnapshot reopened, String mapId})>
importGoldenTiledMap({
  required Directory project,
  required String tmxPath,
  required String sourceRootPath,
  required Map<int, TiledMapLayerImportMode> layerModes,
}) async {
  final sourceRoot = await Directory(sourceRootPath).resolveSymbolicLinks();
  final tmx = await _sourceFile(sourceRoot, tmxPath);
  final document = parseTiledMap(await tmx.readAsString());
  final mapName = p.basenameWithoutExtension(tmx.path);
  final mapId = 'golden-${sha256.convert(await tmx.readAsBytes()).toString().substring(0, 8)}';
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [project.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final opener = ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: snapshots,
    artifactStore: LocalArtifactStore(
      allowedSourceRoots: [sourceRoot],
      maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
    ),
    tiledImageCollectionRasterCodec: const CliPngTiledImageCollectionRasterCodec(),
  );
  final opened = await opener.openProject(project.path);
  late final ProjectSnapshot imported;
  try {
    await api.attachProject(
      projectRootPath: project.path,
      projectHandle: opened.projectHandle,
      workspaceHandle: opened.workspaceHandle,
    );
    final stagedMap = await api.stageArtifactFile(sourcePath: tmx.path);
    final tilesets = <Map<String, Object?>>[];
    for (final reference in document.dependencyClosure.tilesets) {
      final tsx = await _sourceFile(
        sourceRoot,
        p.join(tmx.parent.path, reference.source),
      );
      final source = await tsx.readAsString();
      final tileset = parseTiledTileset(source);
      final id = 'golden-${sha256.convert(utf8.encode(reference.source)).toString().substring(0, 12)}';
      final images = <Map<String, Object?>>[];
      for (final dependency in tileset.dependencyClosure.images) {
        final file = await _sourceFile(
          sourceRoot,
          p.join(tsx.parent.path, dependency.source),
        );
        final staged = await api.stageArtifactFile(sourcePath: file.path);
        images.add({'source': dependency.source, 'artifactHandle': staged.reference.handle});
      }
      tilesets.add({
        'source': reference.source,
        'tsx': source,
        'tilesetId': id,
        'assetId': '$id-image',
        'logicalPath': tileset.layout is TiledImageCollectionLayout
            ? 'assets/tilesets/$id'
            : 'assets/tilesets/$id.png',
        'imageArtifacts': images,
      });
    }
    final plan = await api.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: mapId,
        idempotencyKey: mapId,
        actionId: 'map.tiled.import',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: (await snapshots.load(opened.projectHandle)).revision,
        parameters: {
          'mapId': mapId,
          'displayName': mapName,
          'tmxArtifactHandle': stagedMap.reference.handle,
          'tilesets': tilesets,
          'layerModes': {
            for (final entry in layerModes.entries) '${entry.key}': entry.value.name,
          },
        },
      ),
    );
    final confirmation = await api.confirmMutation(opened.projectHandle, planId: plan.planId);
    final applied = await api.applyMutation(
      opened.projectHandle,
      planId: plan.planId,
      operationId: '$mapId-apply',
      confirmationToken: confirmation.confirmationToken,
    );
    if (applied.receipt.status != AuthoringReceiptStatus.applied) {
      throw StateError('Tiled import did not publish.');
    }
    imported = await snapshots.load(opened.projectHandle);
  } finally {
    try {
      await api.detachWorkspace(opened.workspaceHandle);
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }
  final cold = await opener.openProject(project.path);
  try {
    final reopened = await ProjectSnapshotLoader(handles: handles).load(cold.projectHandle);
    return (imported: imported, reopened: reopened, mapId: mapId);
  } finally {
    opener.closeWorkspace(cold.workspaceHandle);
  }
}

Future<File> _sourceFile(String root, String path) async {
  final resolved = await File(path).resolveSymbolicLinks();
  if (!p.isWithin(root, resolved)) {
    throw FileSystemException('Tiled source is outside the selected fixture', path);
  }
  return File(resolved);
}

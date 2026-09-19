import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_request.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'asset_actions.dart';
import 'asset_store.dart';
import 'raster_image_dimensions.dart';
import 'tileset_actions.dart';

final class TilesetImageImportActions {
  const TilesetImageImportActions({required this.artifactStore});

  final ArtifactStore artifactStore;

  static final descriptors = [
    visualLibraryDescriptor(
      'tileset.import_image',
      'Atomically import a staged PNG asset and its canonical regular tileset',
      resourceKinds: const [
        'project',
        'tileset',
        'assetCatalog',
        'assetBlob',
        'asset'
      ],
    ),
  ];

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final fields = VisualLibraryParameters(context.request.parameters);
    fields.allow(const {
      'artifactHandle',
      'tilesetId',
      'name',
      'tileWidth',
      'tileHeight'
    });
    final handle = fields.string('artifactHandle');
    final artifact = artifactStore.inspect(handle);
    if (artifact == null || artifact.mediaType != 'image/png') {
      throw const FormatException('A staged PNG image is required.');
    }
    final dimensions = decodeRasterImageDimensions(
      await artifactStore.read(handle),
      mediaType: artifact.mediaType,
    );
    final width = context.request.parameters['tileWidth'];
    final height = context.request.parameters['tileHeight'];
    if (dimensions == null ||
        width is! int ||
        height is! int ||
        width <= 0 ||
        height <= 0 ||
        dimensions.width < width ||
        dimensions.height < height ||
        dimensions.width % width != 0 ||
        dimensions.height % height != 0) {
      throw const FormatException(
          'The PNG dimensions must contain complete grid cells.');
    }
    final id = fields.string('tilesetId');
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) ||
        context.snapshot.manifest.tilesets.any((entry) => entry.id == id)) {
      throw const FormatException('The new tileset identity must be unique.');
    }
    final path = 'assets/studio/$id.png';
    final assetId = 'image_$id';
    final assetDraft = await AssetActions(artifactStore: artifactStore).build(
      AuthoringPlanningContext(
        snapshot: context.snapshot,
        request: AuthoringRequest(
          requestId: context.request.requestId,
          actionId: 'asset.import',
          actionVersion: 1,
          workspaceHandle: context.request.workspaceHandle,
          parameters: {
            'artifactHandle': handle,
            'assetId': assetId,
            'logicalPath': path,
            'usages': ['tileset'],
          },
        ),
        planId: context.planId,
        seed: context.seed,
      ),
    );
    final catalogChange = assetDraft.changeSet.changes.singleWhere(
      (change) => change.storageKey == assetCatalogStorageKey,
    );
    final catalog = AssetCatalog.fromJson(
      jsonDecode(utf8.decode(catalogChange.afterBytes!))
          as Map<String, dynamic>,
    );
    final tileset = ProjectTilesetEntry(
      id: id,
      name: fields.string('name'),
      relativePath: path,
      source: ProjectRegularAtlasTilesetSource(
        assetId: assetId,
        pixelWidth: dimensions.width,
        pixelHeight: dimensions.height,
        tileWidth: width,
        tileHeight: height,
      ),
    );
    final manifest = const TilesetImportProjector().project(
      context.snapshot.manifest,
      assets: catalog,
      tileset: tileset,
    );
    final manifestDraft = buildVisualManifestDraft(
      context.snapshot,
      manifest,
      operation: 'tileset.import_image',
      path: '/tilesets/$id',
      after: tileset.toJson(),
    );
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          ...assetDraft.changeSet.changes,
          ...manifestDraft.changeSet.changes
        ],
        diff: AuthoringDiff([
          ...assetDraft.changeSet.diff.entries,
          ...manifestDraft.changeSet.diff.entries
        ]),
      ),
      preview: {'operation': 'tileset.import_image', 'tilesetId': id},
      artifacts: assetDraft.artifacts,
    );
  }
}

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
import 'package:map_distribution/map_distribution.dart';
import 'png_decoding.dart';
import 'tileset_actions.dart';

final class TilesetImageImportActions {
  const TilesetImageImportActions({required this.artifactStore});

  final ArtifactStore artifactStore;

  static final descriptors = [
    visualLibraryDescriptor(
      'tileset.import_image',
      'Atomically import a staged PNG and its tileset, optionally publishing a terrain',
      resourceKinds: const [
        'project',
        'tileset',
        'assetCatalog',
        'assetBlob',
        'asset',
        'smartTileAtlas',
        'smartTileMaterial',
        'smartTilePreset',
      ],
      inputSchema: const {
        'type': 'object',
        'additionalProperties': false,
        'required': ['artifactHandle', 'tilesetId', 'name', 'tileWidth', 'tileHeight'],
        'properties': {
          'artifactHandle': {'type': 'string'},
          'tilesetId': {'type': 'string'},
          'name': {'type': 'string'},
          'tileWidth': {'type': 'integer', 'minimum': 1},
          'tileHeight': {'type': 'integer', 'minimum': 1},
          'terrain': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['id', 'column', 'row'],
            'properties': {
              'id': {'type': 'string', 'pattern': r'^[a-zA-Z0-9_-]{1,128}$'},
              'column': {'type': 'integer', 'minimum': 0},
              'row': {'type': 'integer', 'minimum': 0},
            },
          },
        },
      },
    ),
  ];

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final fields = VisualLibraryParameters(context.request.parameters);
    fields.allow(const {
      'artifactHandle',
      'tilesetId',
      'name',
      'tileWidth',
      'tileHeight',
      'terrain',
    });
    final terrain = TilesetTerrainImport.read(context.request.parameters);
    final handle = fields.string('artifactHandle');
    final artifact = artifactStore.inspect(handle);
    if (artifact == null || artifact.mediaType != 'image/png') {
      throw const FormatException('A staged PNG image is required.');
    }
    final bytes = await artifactStore.read(handle);
    final dimensions = decodeRasterImageDimensions(
      bytes,
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
    if (!decodesAsSingleFramePng(bytes,
        width: dimensions.width, height: dimensions.height)) {
      throw VisualLibraryException('tileset.image_decode_failed',
          'The PNG does not decode as one complete image.');
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
    final imported = const TilesetImportProjector().project(
      context.snapshot.manifest,
      assets: catalog,
      tileset: tileset,
    );
    final manifest = terrain?.project(imported, tileset) ?? imported;
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
      preview: {
        'operation': 'tileset.import_image',
        'tilesetId': id,
        if (terrain != null) 'terrainId': terrain.id,
      },
      artifacts: assetDraft.artifacts,
    );
  }
}

final class TilesetTerrainImport {
  const TilesetTerrainImport._(this.id, this.column, this.row);

  final String id;
  final int column;
  final int row;

  static TilesetTerrainImport? read(Map<String, Object?> parameters) {
    if (!parameters.containsKey('terrain')) return null;
    final value = parameters['terrain'];
    if (value is! Map) {
      throw const FormatException('Expected a terrain import object.');
    }
    final fields = VisualLibraryParameters(Map<String, Object?>.from(value));
    fields.allow(const {'id', 'column', 'row'});
    final id = fields.string('id');
    final column = value['column'];
    final row = value['row'];
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        column is! int || row is! int || column < 0 || row < 0) {
      throw const FormatException('Invalid terrain identity or grid cell.');
    }
    return TilesetTerrainImport._(id, column, row);
  }

  ProjectManifest project(ProjectManifest manifest, ProjectTilesetEntry tileset) {
    final atlas = smartTileAuthoringAtlas(tileset, id);
    if (column >= atlas.columns || row >= atlas.rows) {
      throw const FormatException('The terrain cell is outside the PNG grid.');
    }
    final catalog = manifest.smartTileCatalog;
    if (catalog.atlases.any((atlas) => atlas.id == id) ||
        catalog.materials.any((material) => material.id == id) ||
        catalog.presets.any((preset) => preset.id == id)) {
      throw const FormatException('The terrain identity is already in use.');
    }
    final material = ProjectSmartTileMaterial(
      id: id,
      name: tileset.name,
      connectionGroupId: id,
    );
    final preset = ProjectSmartTilePreset(
      id: id,
      name: tileset.name,
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(mode: SmartTileCoverageMode.template),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: id,
      allowedMaterialIds: [id],
      rules: [
        SmartTileRule(
          id: 'base',
          centerMatch: SmartTileSlotMatch.material(id),
          candidates: [
            SmartTileCandidate(id: 'base', parts: [
              SmartTileVisualPart(source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(atlasId: id, column: column, row: row),
              )),
            ]),
          ],
        ),
      ],
    );
    return manifest.copyWith(smartTileCatalog: ProjectSmartTileCatalog(
      categories: catalog.categories,
      atlases: [...catalog.atlases, atlas],
      materials: [...catalog.materials, material],
      animations: catalog.animations,
      presets: [...catalog.presets, preset],
      patterns: catalog.patterns,
      drafts: catalog.drafts,
    ));
  }
}

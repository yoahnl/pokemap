import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../maps/semantic_map_action_support.dart';
import 'asset_store.dart';
import 'tiled_image_collection_packer.dart';
import 'tiled_tileset_import_projection.dart';
import 'tileset_actions.dart';

/// Public Tiled tileset import boundary.
///
/// The TSX and staged images are inputs only. The resulting project owns its
/// canonical assets and source model; regular Wang atlases additionally
/// compile their native Smart Tile catalog.
final class TiledTilesetImportActions {
  const TiledTilesetImportActions({
    required this.artifactStore,
    this.imageCollectionRasterCodec,
  });

  final ArtifactStore artifactStore;
  final TiledImageCollectionRasterCodec? imageCollectionRasterCodec;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      visualLibraryDescriptor(
        'tileset.tiled.import',
        'Import one Tiled tileset as canonical PokeMap resources',
        resourceKinds: const <String>[
          'project',
          'asset',
          'tileset',
          'smartTileAtlas',
          'smartTileMaterial',
          'smartTileAnimation',
          'smartTilePreset',
        ],
      ),
      visualLibraryDescriptor(
        'tileset.tiled.wang_bundle.delete',
        'Delete one unreferenced imported Tiled Wang bundle',
        risk: AuthoringRiskLevel.high,
        resourceKinds: const <String>[
          'project',
          'asset',
          'tileset',
          'smartTileAtlas',
          'smartTileMaterial',
          'smartTileAnimation',
          'smartTilePreset',
        ],
      ),
    ],
  );

  Future<AuthoringMutationDraft> build(
    AuthoringPlanningContext context,
  ) async {
    final parameters = _TiledTilesetImportParameters(
      context.request.parameters,
    );
    if (context.request.actionId == 'tileset.tiled.wang_bundle.delete') {
      parameters.allow(const <String>{'importId'});
      return const TiledTilesetImportProjector().deleteWangBundle(
        snapshot: context.snapshot,
        importId: parameters.string('importId'),
      );
    }
    if (context.request.actionId != 'tileset.tiled.import') {
      throw semanticFailure(
        'tileset.tiled.action_unsupported',
        'The requested Tiled tileset action is unsupported.',
      );
    }
    parameters.allow(const <String>{
      'artifactHandle',
      'imageArtifacts',
      'assetId',
      'logicalPath',
      'tilesetId',
      'displayName',
      'importId',
      'tsx',
      'selections',
      'tags',
      'usages',
    });
    final document = _parseTileset(parameters.text('tsx'));
    return switch (document.layout) {
      TiledRegularAtlasLayout() => _buildRegular(
          context,
          parameters,
          document,
        ),
      TiledImageCollectionLayout() => _buildImageCollection(
          context,
          parameters,
          document,
        ),
    };
  }

  Future<AuthoringMutationDraft> _buildRegular(
    AuthoringPlanningContext context,
    _TiledTilesetImportParameters parameters,
    TiledTilesetDocument parsedDocument,
  ) async {
    if (parameters.contains('imageArtifacts')) {
      throw semanticFailure(
        'tileset.tiled.artifact_shape_invalid',
        'A regular Tiled atlas accepts exactly one artifact handle.',
      );
    }
    final artifactHandle = parameters.string('artifactHandle');
    final artifact = artifactStore.inspect(artifactHandle);
    if (artifact == null) {
      throw const ArtifactStoreException(
        'artifact.unknown',
        'The artifact handle is unknown or has expired.',
      );
    }
    if (!artifact.mediaType.startsWith('image/')) {
      throw const ArtifactStoreException(
        'artifact.media_type_invalid',
        'The Tiled tileset artifact must be a raster image.',
      );
    }
    final imageBytes = await artifactStore.read(artifact.handle);

    final document = _parseTsx(parameters.text('tsx'));
    final tilesetId = parameters.string('tilesetId');
    final selections = _selections(parameters.list('selections'));
    final bundle = _compileWang(
      document,
      importId: parameters.string('importId'),
      tilesetId: tilesetId,
      selections: selections,
    );
    final asset = AssetRecord(
      id: parameters.string('assetId'),
      logicalPath: parameters.string('logicalPath'),
      artifact: artifact,
      tags: parameters.strings('tags'),
      usages: parameters.strings('usages'),
    );
    final tileset = ProjectTilesetEntry(
      id: tilesetId,
      name: parameters.string('displayName'),
      relativePath: asset.logicalPath,
      transparentColor: (parsedDocument.layout as TiledRegularAtlasLayout)
          .image
          .transparentColor,
      source: ProjectRegularAtlasTilesetSource(
        assetId: asset.id,
        pixelWidth: document.imageWidth,
        pixelHeight: document.imageHeight,
        tileWidth: document.tileWidth,
        tileHeight: document.tileHeight,
        marginX: document.margin,
        marginY: document.margin,
        spacingX: document.spacing,
        spacingY: document.spacing,
        pixelOffsetX: document.tileOffsetX,
        pixelOffsetY: document.tileOffsetY,
        tileAnimations: _regularAtlasAnimations(parsedDocument),
      ),
    );
    return const TiledTilesetImportProjector().project(
      snapshot: context.snapshot,
      asset: asset,
      imageBytes: imageBytes,
      tileset: tileset,
      wangBundle: bundle,
      importId: parameters.string('importId'),
    );
  }

  Future<AuthoringMutationDraft> _buildImageCollection(
    AuthoringPlanningContext context,
    _TiledTilesetImportParameters parameters,
    TiledTilesetDocument document,
  ) async {
    if (parameters.contains('artifactHandle')) {
      throw semanticFailure(
        'tileset.tiled.artifact_shape_invalid',
        'A Tiled image collection accepts its complete image artifact list.',
      );
    }
    final codec = imageCollectionRasterCodec;
    if (codec == null) {
      throw semanticFailure(
        'tileset.tiled.image_codec_unavailable',
        'This authoring transport cannot decode and pack image collections.',
      );
    }
    if (parameters.list('selections').isNotEmpty) {
      throw semanticFailure(
        'smart_tile.tiled_wang.collection_unsupported',
        'Wang Set compilation for image collections is not supported yet.',
      );
    }

    final packingInputs = await _collectionInputs(
      parameters.list('imageArtifacts'),
      document.dependencyClosure.images,
    );
    late final TiledImageCollectionPackingResult packing;
    try {
      packing = TiledImageCollectionPacker(codec: codec).pack(packingInputs);
    } on TiledImageCollectionPackingException catch (error) {
      throw semanticFailure(
        error.code,
        error.message,
        details: <String, Object?>{
          if (error.source != null) 'source': error.source,
        },
      );
    }

    final assetId = parameters.string('assetId');
    final logicalPath = parameters.string('logicalPath');
    final tags = parameters.strings('tags');
    final usages = parameters.strings('usages');
    final assets = <AssetRecord>[
      for (final page in packing.pages)
        AssetRecord(
          id: '$assetId-${page.id}',
          logicalPath: '${_pathPrefix(logicalPath)}/${page.id}.png',
          artifact: page.artifact,
          tags: tags,
          usages: usages,
        ),
    ];
    final assetsByPageId = <String, AssetRecord>{
      for (var index = 0; index < packing.pages.length; index += 1)
        packing.pages[index].id: assets[index],
    };
    final tileset = ProjectTilesetEntry(
      id: parameters.string('tilesetId'),
      name: parameters.string('displayName'),
      relativePath: _pathPrefix(logicalPath),
      source: _imageCollectionSource(
        document,
        packing,
        assetsByPageId,
      ),
    );
    return const TiledTilesetImportProjector().projectImageCollection(
      snapshot: context.snapshot,
      assets: assets,
      pageBytes: <String, List<int>>{
        for (final page in packing.pages) page.id: page.bytes,
      },
      tileset: tileset,
      importId: parameters.string('importId'),
      sourceImageCount: packingInputs.length,
    );
  }

  Future<List<TiledImageCollectionPackingInput>> _collectionInputs(
    List<Object?> rawArtifacts,
    List<TiledTilesetImageDependency> dependencies,
  ) async {
    final handlesBySource = <String, String>{};
    for (var index = 0; index < rawArtifacts.length; index += 1) {
      final raw = rawArtifacts[index];
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw semanticFailure(
          'tileset.tiled.image_artifact_invalid',
          'Every image collection artifact must be a JSON object.',
          details: <String, Object?>{'artifactIndex': index},
        );
      }
      final artifact = _TiledTilesetImportParameters(
        Map<String, Object?>.from(raw),
      )..allow(const <String>{'source', 'artifactHandle'});
      final source = artifact.string('source');
      if (handlesBySource.containsKey(source)) {
        throw semanticFailure(
          'tileset.tiled.image_dependency_duplicate',
          'An image collection dependency is staged more than once.',
          details: <String, Object?>{'source': source},
        );
      }
      handlesBySource[source] = artifact.string('artifactHandle');
    }
    final expectedSources = dependencies.map((item) => item.source).toSet();
    final unknown = handlesBySource.keys
        .where((source) => !expectedSources.contains(source))
        .toList()
      ..sort();
    final missing = expectedSources
        .where((source) => !handlesBySource.containsKey(source))
        .toList()
      ..sort();
    if (unknown.isNotEmpty || missing.isNotEmpty) {
      throw semanticFailure(
        'tileset.tiled.image_dependency_mismatch',
        'The staged images must exactly match the TSX dependency closure.',
        details: <String, Object?>{
          'missingSources': missing,
          'unknownSources': unknown,
        },
      );
    }

    final inputs = <TiledImageCollectionPackingInput>[];
    for (final dependency in dependencies) {
      final handle = handlesBySource[dependency.source]!;
      final artifact = artifactStore.inspect(handle);
      if (artifact == null) {
        throw const ArtifactStoreException(
          'artifact.unknown',
          'An image collection artifact handle is unknown or has expired.',
        );
      }
      if (!artifact.mediaType.startsWith('image/')) {
        throw const ArtifactStoreException(
          'artifact.media_type_invalid',
          'Every Tiled image collection artifact must be a raster image.',
        );
      }
      inputs.add(
        TiledImageCollectionPackingInput(
          source: dependency.source,
          bytes: await artifactStore.read(handle),
          declaredPixelWidth: dependency.pixelWidth,
          declaredPixelHeight: dependency.pixelHeight,
          transparentColor: dependency.transparentColor,
        ),
      );
    }
    return List<TiledImageCollectionPackingInput>.unmodifiable(inputs);
  }
}

TiledTilesetDocument _parseTileset(String source) {
  try {
    return parseTiledTileset(source);
  } on TiledTilesetImportException catch (error) {
    throw semanticFailure(error.code, error.message);
  }
}

String _pathPrefix(String value) => value.replaceFirst(RegExp(r'/+$'), '');

ProjectImageCollectionTilesetSource _imageCollectionSource(
  TiledTilesetDocument document,
  TiledImageCollectionPackingResult packing,
  Map<String, AssetRecord> assetsByPageId,
) {
  final tiles = document.tiles.values.toList()
    ..sort((left, right) => left.tileId.compareTo(right.tileId));
  return ProjectImageCollectionTilesetSource(
    pages: <ProjectImageCollectionPage>[
      for (final page in packing.pages)
        ProjectImageCollectionPage(
          id: page.id,
          assetId: assetsByPageId[page.id]!.id,
          pixelWidth: page.pixelWidth,
          pixelHeight: page.pixelHeight,
        ),
    ],
    tileDefinitions: <ProjectImageCollectionTileDefinition>[
      for (final tile in tiles) _imageCollectionTile(document, packing, tile),
    ],
    properties: _projectProperties(document.properties),
  );
}

ProjectImageCollectionTileDefinition _imageCollectionTile(
  TiledTilesetDocument document,
  TiledImageCollectionPackingResult packing,
  TiledTileMetadata tile,
) {
  final image = tile.image;
  if (image == null) {
    throw semanticFailure(
      'tileset.tiled.image_reference_missing',
      'Every image collection tile must reference one image.',
      details: <String, Object?>{'tileId': tile.tileId},
    );
  }
  final placement = packing.placementForSource(image.source);
  return ProjectImageCollectionTileDefinition(
    tileId: tile.tileId,
    pageId: placement.pageId,
    sourceRect: placement.sourceRect,
    offsetX: document.tileOffsetX,
    offsetY: document.tileOffsetY,
    animation: <ProjectImageCollectionAnimationFrame>[
      for (final frame in tile.animation)
        ProjectImageCollectionAnimationFrame(
          tileId: frame.tileId,
          durationMs: frame.durationMs,
        ),
    ],
    properties: <ProjectTilesetProperty>[
      ..._projectProperties(tile.properties),
      if (tile.probability != 1)
        ProjectTilesetProperty(
          name: 'tiled:probability',
          type: ProjectTilesetPropertyType.decimal,
          value: tile.probability,
        ),
    ],
    collisionObjects: <ProjectTilesetCollisionObject>[
      for (final object in tile.collisionObjects)
        ProjectTilesetCollisionObject(
          id: object.id,
          name: object.name,
          type: object.className,
          shape: _projectCollisionShape(object.shape),
          x: object.x,
          y: object.y,
          width: object.width,
          height: object.height,
          rotation: object.rotation,
          points: <ProjectTilesetPixelPoint>[
            for (final point in object.points)
              ProjectTilesetPixelPoint(x: point.x, y: point.y),
          ],
          properties: _projectProperties(object.properties),
        ),
    ],
  );
}

List<ProjectRegularAtlasTileAnimation> _regularAtlasAnimations(
  TiledTilesetDocument document,
) =>
    <ProjectRegularAtlasTileAnimation>[
      for (final tile in document.tiles.values)
        if (tile.animation.isNotEmpty)
          ProjectRegularAtlasTileAnimation(
            tileId: tile.tileId,
            frames: <ProjectImageCollectionAnimationFrame>[
              for (final frame in tile.animation)
                ProjectImageCollectionAnimationFrame(
                  tileId: frame.tileId,
                  durationMs: frame.durationMs,
                ),
            ],
          ),
    ];

List<ProjectTilesetProperty> _projectProperties(
  Iterable<TiledProperty> properties,
) =>
    List<ProjectTilesetProperty>.unmodifiable(
      properties.map(
        (property) => ProjectTilesetProperty(
          name: property.name,
          type: _projectPropertyType(property.type),
          value: _projectPropertyValue(property),
          customType: property.customType,
        ),
      ),
    );

Object? _projectPropertyValue(TiledProperty property) =>
    property.type == TiledPropertyValueType.structured
        ? <String, Object?>{
            for (final member in property.members)
              member.name: _projectPropertyValue(member),
          }
        : property.value;

ProjectTilesetPropertyType _projectPropertyType(TiledPropertyValueType type) =>
    switch (type) {
      TiledPropertyValueType.string => ProjectTilesetPropertyType.string,
      TiledPropertyValueType.integer => ProjectTilesetPropertyType.integer,
      TiledPropertyValueType.decimal => ProjectTilesetPropertyType.decimal,
      TiledPropertyValueType.boolean => ProjectTilesetPropertyType.boolean,
      TiledPropertyValueType.color => ProjectTilesetPropertyType.color,
      TiledPropertyValueType.file => ProjectTilesetPropertyType.assetReference,
      TiledPropertyValueType.object =>
        ProjectTilesetPropertyType.objectReference,
      TiledPropertyValueType.structured =>
        ProjectTilesetPropertyType.structured,
    };

ProjectTilesetCollisionShape _projectCollisionShape(
  TiledCollisionShape shape,
) =>
    switch (shape) {
      TiledCollisionShape.rectangle => ProjectTilesetCollisionShape.rectangle,
      TiledCollisionShape.ellipse => ProjectTilesetCollisionShape.ellipse,
      TiledCollisionShape.polygon => ProjectTilesetCollisionShape.polygon,
      TiledCollisionShape.polyline => ProjectTilesetCollisionShape.polyline,
      TiledCollisionShape.point => ProjectTilesetCollisionShape.point,
    };

TiledWangTilesetDocument _parseTsx(String source) {
  try {
    return parseTiledWangTileset(source);
  } on TiledTilesetImportException catch (error) {
    throw semanticFailure(error.code, error.message);
  }
}

TiledWangImportBundle _compileWang(
  TiledWangTilesetDocument document, {
  required String importId,
  required String tilesetId,
  required List<TiledWangSetSelection> selections,
}) {
  try {
    return compileTiledWangImport(
      document: document,
      importId: importId,
      tilesetId: tilesetId,
      selections: selections,
    );
  } on TiledTilesetImportException catch (error) {
    throw semanticFailure(error.code, error.message);
  }
}

List<TiledWangSetSelection> _selections(List<Object?> rawSelections) {
  final selections = <TiledWangSetSelection>[];
  for (var index = 0; index < rawSelections.length; index += 1) {
    final raw = rawSelections[index];
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw semanticFailure(
        'smart_tile.tiled_wang.selection_invalid',
        'Every Wang Set selection must be a JSON object.',
        details: <String, Object?>{'selectionIndex': index},
      );
    }
    final selection = _TiledTilesetImportParameters(
      Map<String, Object?>.from(raw),
    )..allow(const <String>{'wangSetIndex', 'usage'});
    final usage = switch (selection.string('usage')) {
      'terrain' => SmartTileUsage.terrain,
      'path' => SmartTileUsage.path,
      'forest_surface' => SmartTileUsage.forestSurface,
      final unsupported => throw semanticFailure(
          'smart_tile.tiled_wang.usage_invalid',
          'The selected Wang Set usage is unsupported.',
          details: <String, Object?>{
            'selectionIndex': index,
            'usage': unsupported,
          },
        ),
    };
    selections.add(
      TiledWangSetSelection(
        wangSetIndex: selection.integer('wangSetIndex'),
        usage: usage,
      ),
    );
  }
  return List<TiledWangSetSelection>.unmodifiable(selections);
}

final class _TiledTilesetImportParameters {
  _TiledTilesetImportParameters(Map<String, Object?> values)
      : _values = Map<String, Object?>.unmodifiable(values);

  final Map<String, Object?> _values;

  bool contains(String key) => _values.containsKey(key);

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw VisualLibraryException(
        'visual.parameter_unknown',
        'The Tiled tileset import contains unsupported parameters.',
        details: <String, Object?>{'parameters': unknown},
      );
    }
  }

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required Tiled tileset import parameter is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  String text(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required Tiled tileset import text parameter is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  int integer(String key) {
    final value = _values[key];
    if (value is! int) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required Tiled tileset import integer is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  List<Object?> list(String key) {
    final value = _values[key];
    if (value is! List) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required Tiled tileset import list is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return List<Object?>.unmodifiable(value);
  }

  List<String> strings(String key) {
    final value = _values[key];
    if (value == null) return const <String>[];
    if (value is! List ||
        value.any(
          (item) =>
              item is! String || item.trim().isEmpty || item != item.trim(),
        )) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A Tiled tileset import string list is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}

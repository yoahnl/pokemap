import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

enum BorderSmartTileGroundSnapshotErrorCode {
  invalidProjectRoot,
  missingSmartTilePreset,
  unpublishedSmartTilePreset,
  unresolvedSmartTileRole,
  missingAnimation,
  incompatibleAnimationTimelines,
  missingAtlas,
  atlasFrameOutOfBounds,
  missingTileset,
  unsafeTilesetPath,
  missingTilesetFile,
  unreadableTilesetFile,
  invalidSmartTileVisual,
  unsupportedModel3dGround,
}

final class BorderSmartTileGroundSnapshotException implements Exception {
  const BorderSmartTileGroundSnapshotException({
    required this.code,
    required this.userMessage,
    this.sourceSmartTilePresetId,
    this.groundRole,
    this.animationId,
    this.atlasId,
    this.tilesetId,
    this.relativePath,
    this.cause,
  });

  final BorderSmartTileGroundSnapshotErrorCode code;
  final String userMessage;
  final String? sourceSmartTilePresetId;
  final BorderGroundVariantRole? groundRole;
  final String? animationId;
  final String? atlasId;
  final String? tilesetId;
  final String? relativePath;
  final Object? cause;

  @override
  String toString() =>
      'BorderSmartTileGroundSnapshotException.${code.name}: $userMessage';
}

typedef CanonicalBorderPngReader = Future<List<int>> Function(
    ProjectTilesetEntry tileset, String assetId);

final class CanonicalBorderGroundFrame {
  CanonicalBorderGroundFrame(
      {required this.sourceProjectRelativePath,
      required Uint8List encodedImageBytes,
      this.durationMs})
      : encodedImageBytes =
            Uint8List.fromList(encodedImageBytes).asUnmodifiableView();
  final String sourceProjectRelativePath;
  final Uint8List encodedImageBytes;
  final int? durationMs;
  BorderSnapshotContentFrame get contentFrame {
    final image = img.decodePng(encodedImageBytes)!;
    return BorderSnapshotContentFrame(
        sourceRectPx: BorderPixelRect(
            x: 0, y: 0, width: image.width, height: image.height),
        durationMs: durationMs ?? 100,
        rgbaBytes: image.getBytes(order: img.ChannelOrder.rgba));
  }
}

final class CanonicalBorderGroundComposer {
  const CanonicalBorderGroundComposer();
  Future<Map<BorderGroundVariantRole, List<CanonicalBorderGroundFrame>>>
      composeAllRoles(
          {required ProjectManifest manifest,
          required String sourceSmartTilePresetId,
          required CanonicalBorderPngReader readPng}) async {
    final presetId = sourceSmartTilePresetId.trim();
    final catalog = manifest.smartTileCatalog;
    final preset = _presetById(catalog, presetId);
    if (preset == null) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.missingSmartTilePreset,
        userMessage:
            'Le preset Smart Tile sélectionné n’existe plus dans le projet.',
        sourceSmartTilePresetId: presetId,
      );
    }
    if (preset.status != SmartTilePresetStatus.published) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.unpublishedSmartTilePreset,
        userMessage: 'Publiez le preset Smart Tile avant de l’utiliser dans '
            'une bordure.',
        sourceSmartTilePresetId: presetId,
      );
    }
    final materialId = preset.defaultMaterialId;
    final materials = <String, ProjectSmartTileMaterial>{
      for (final material in catalog.materials) material.id: material,
    };
    final material = materials[materialId];
    if (material == null || material.isEmpty) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.invalidSmartTileVisual,
        userMessage:
            'Le matériau par défaut du preset Smart Tile est invalide.',
        sourceSmartTilePresetId: presetId,
      );
    }

    final atlasById = <String, ProjectSmartTileAtlas>{
      for (final atlas in catalog.atlases) atlas.id: atlas,
    };
    final animationById = <String, ProjectSmartTileAnimation>{
      for (final animation in catalog.animations) animation.id: animation,
    };
    final tilesetById = <String, ProjectTilesetEntry>{
      for (final tileset in manifest.tilesets) tileset.id: tileset,
    };
    final imageByTilesetId = <String, img.Image>{};
    final result =
        <BorderGroundVariantRole, List<CanonicalBorderGroundFrame>>{};

    for (final role in standardBorderGroundVariantRoleOrder) {
      final resolution = resolveSmartTile(
        preset: preset,
        materials: catalog.materials,
        context: _contextForRole(
          role,
          topology: preset.topology,
          materialId: materialId,
        ),
        x: 0,
        y: 0,
        mapId: 'border-ground-snapshot',
        layerId: preset.id,
      );
      final candidate = resolution.candidate;
      final backgroundParts = candidate?.parts
              .where((part) => _belongsToGroundSnapshot(part.channel))
              .toList(growable: false) ??
          const <SmartTileVisualPart>[];
      if (candidate == null || backgroundParts.isEmpty) {
        throw BorderSmartTileGroundSnapshotException(
          code: BorderSmartTileGroundSnapshotErrorCode.unresolvedSmartTileRole,
          userMessage: 'Le preset Smart Tile ne résout pas la variante de sol '
              '« ${role.name} ».',
          sourceSmartTilePresetId: presetId,
          groundRole: role,
        );
      }

      final timeline = _timelineForParts(
        backgroundParts,
        animationById: animationById,
        presetId: presetId,
        role: role,
      );
      final frames = <CanonicalBorderGroundFrame>[];
      for (var frameIndex = 0; frameIndex < timeline.frameCount; frameIndex++) {
        final canvas = img.Image(
          width: manifest.settings.tileWidth,
          height: manifest.settings.tileHeight,
          numChannels: 4,
        );
        final orderedParts = backgroundParts.toList(growable: false)
          ..sort((left, right) => left.drawOrder.compareTo(right.drawOrder));
        for (final part in orderedParts) {
          final frame = _frameForPart(
            part,
            frameIndex: frameIndex,
            animationById: animationById,
          );
          final atlas = atlasById[frame.atlasId];
          if (atlas == null) {
            throw BorderSmartTileGroundSnapshotException(
              code: BorderSmartTileGroundSnapshotErrorCode.missingAtlas,
              userMessage: 'L’atlas Smart Tile de la variante '
                  '« ${role.name} » est introuvable.',
              sourceSmartTilePresetId: presetId,
              groundRole: role,
              atlasId: frame.atlasId,
            );
          }
          try {
            atlas.sourceRectFor(
                column: frame.column,
                row: frame.row,
                columnSpan: frame.columnSpan,
                rowSpan: frame.rowSpan);
          } on RangeError catch (error) {
            throw BorderSmartTileGroundSnapshotException(
                code: BorderSmartTileGroundSnapshotErrorCode
                    .atlasFrameOutOfBounds,
                userMessage: 'Une frame Smart Tile dépasse son atlas.',
                atlasId: atlas.id,
                cause: error);
          }
          final tileset = tilesetById[atlas.tilesetId];
          if (tileset == null) {
            throw BorderSmartTileGroundSnapshotException(
              code: BorderSmartTileGroundSnapshotErrorCode.missingTileset,
              userMessage: 'Le tileset Smart Tile est introuvable.',
              tilesetId: atlas.tilesetId,
            );
          }
          final sourceImage = imageByTilesetId[tileset.id] ??=
              await _decodeImage(tileset, readPng);
          var pixels = _resolvePixels(atlas, frame, sourceImage, tileset);
          pixels = _applyTransform(
            pixels,
            composeSmartTileSpriteTransforms(
              first: part.transform,
              second: resolution.transform,
            ),
          );
          final offsetScaleX = part.offsetUnit == SmartTileOffsetUnit.cell
              ? manifest.settings.tileWidth
              : 1;
          final offsetScaleY = part.offsetUnit == SmartTileOffsetUnit.cell
              ? manifest.settings.tileHeight
              : 1;
          img.compositeImage(
            canvas,
            pixels,
            dstX: part.offsetX * offsetScaleX -
                part.anchorX * manifest.settings.tileWidth +
                atlas.pixelOffsetX,
            dstY: part.offsetY * offsetScaleY -
                part.anchorY * manifest.settings.tileHeight +
                atlas.pixelOffsetY,
            dstW: part.footprintWidth * manifest.settings.tileWidth,
            dstH: part.footprintHeight * manifest.settings.tileHeight,
          );
        }
        frames.add(
          CanonicalBorderGroundFrame(
            sourceProjectRelativePath:
                'assets/smart_tiles/composite/$presetId/${role.name}.png',
            encodedImageBytes: Uint8List.fromList(img.encodePng(canvas)),
            durationMs: timeline.durationAt(frameIndex),
          ),
        );
      }

      result[role] = List.unmodifiable(frames);
    }
    return Map.unmodifiable(result);
  }
}

ProjectSmartTilePreset? _presetById(
  ProjectSmartTileCatalog catalog,
  String presetId,
) {
  for (final preset in catalog.presets) {
    if (preset.id == presetId) return preset;
  }
  return null;
}

bool _belongsToGroundSnapshot(SmartTileRenderChannel channel) =>
    switch (channel) {
      SmartTileRenderChannel.ground ||
      SmartTileRenderChannel.understory =>
        true,
      SmartTileRenderChannel.canopy ||
      SmartTileRenderChannel.foreground ||
      SmartTileRenderChannel.actorOcclusion =>
        false,
    };

SmartTileCellContext _contextForRole(
  BorderGroundVariantRole role, {
  required SmartTileTopology topology,
  required String materialId,
}) {
  final mask = _smartTileMaskForSurfaceRole(role, topology: topology);
  SmartTileObservedSlot slot(int bit) => SmartTileObservedSlot.inside(
        materialId: mask & bit == 0 ? null : materialId,
      );
  return SmartTileCellContext(
    centerMaterialId: materialId,
    observed: SmartTileObservedSignature(
      northEdge: slot(smartTileNorthBit),
      northEastCorner: slot(smartTileNorthEastBit),
      eastEdge: slot(smartTileEastBit),
      southEastCorner: slot(smartTileSouthEastBit),
      southEdge: slot(smartTileSouthBit),
      southWestCorner: slot(smartTileSouthWestBit),
      westEdge: slot(smartTileWestBit),
      northWestCorner: slot(smartTileNorthWestBit),
    ),
  );
}

int _smartTileMaskForSurfaceRole(
  BorderGroundVariantRole role, {
  required SmartTileTopology topology,
}) {
  final cardinal = switch (role) {
    BorderGroundVariantRole.isolated => 0,
    BorderGroundVariantRole.endNorth => 1,
    BorderGroundVariantRole.endEast => 2,
    BorderGroundVariantRole.cornerNE => 3,
    BorderGroundVariantRole.endSouth => 4,
    BorderGroundVariantRole.vertical => 5,
    BorderGroundVariantRole.cornerSE => 6,
    BorderGroundVariantRole.teeEast => 7,
    BorderGroundVariantRole.endWest => 8,
    BorderGroundVariantRole.cornerNW => 9,
    BorderGroundVariantRole.horizontal => 10,
    BorderGroundVariantRole.teeNorth => 11,
    BorderGroundVariantRole.cornerSW => 12,
    BorderGroundVariantRole.teeWest => 13,
    BorderGroundVariantRole.teeSouth => 14,
    BorderGroundVariantRole.innerCornerNE ||
    BorderGroundVariantRole.innerCornerSE ||
    BorderGroundVariantRole.innerCornerSW ||
    BorderGroundVariantRole.innerCornerNW ||
    BorderGroundVariantRole.cross =>
      15,
  };
  if (topology != SmartTileTopology.blob8 &&
      topology != SmartTileTopology.wang8 &&
      topology != SmartTileTopology.wangCorner4) {
    return cardinal;
  }
  var mask = cardinal;
  if (cardinal & 1 != 0 && cardinal & 8 != 0) mask |= smartTileNorthWestBit;
  if (cardinal & 1 != 0 && cardinal & 2 != 0) mask |= smartTileNorthEastBit;
  if (cardinal & 4 != 0 && cardinal & 2 != 0) mask |= smartTileSouthEastBit;
  if (cardinal & 4 != 0 && cardinal & 8 != 0) mask |= smartTileSouthWestBit;
  return switch (role) {
    BorderGroundVariantRole.innerCornerNE => mask & ~smartTileNorthEastBit,
    BorderGroundVariantRole.innerCornerSE => mask & ~smartTileSouthEastBit,
    BorderGroundVariantRole.innerCornerSW => mask & ~smartTileSouthWestBit,
    BorderGroundVariantRole.innerCornerNW => mask & ~smartTileNorthWestBit,
    _ => mask,
  };
}

final class _CompositeTimeline {
  const _CompositeTimeline(this.durations);

  final List<int>? durations;

  int get frameCount => durations?.length ?? 1;

  int? durationAt(int index) => durations?[index];
}

_CompositeTimeline _timelineForParts(
  List<SmartTileVisualPart> parts, {
  required Map<String, ProjectSmartTileAnimation> animationById,
  required String presetId,
  required BorderGroundVariantRole role,
}) {
  List<int>? expected;
  for (final part in parts) {
    final source = part.source;
    if (source is! SmartTileAnimationSource) continue;
    final animation = animationById[source.animationId];
    if (animation == null || animation.frames.isEmpty) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.missingAnimation,
        userMessage: 'Une animation Smart Tile est introuvable.',
        sourceSmartTilePresetId: presetId,
        groundRole: role,
        animationId: source.animationId,
      );
    }
    if (animation.loop == SmartTileAnimationLoop.once) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode
            .incompatibleAnimationTimelines,
        userMessage: 'Une animation non bouclée ne peut pas être figée dans '
            'un sol Border bouclé.',
        sourceSmartTilePresetId: presetId,
        groundRole: role,
        animationId: source.animationId,
      );
    }
    final durations = <int>[
      for (final frame in _expandedAnimationFrames(animation)) frame.durationMs,
    ];
    if (expected != null && !_intListsEqual(expected, durations)) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode
            .incompatibleAnimationTimelines,
        userMessage: 'Les parties animées du Smart Tile doivent partager la '
            'même timeline pour être figées ensemble.',
        sourceSmartTilePresetId: presetId,
        groundRole: role,
        animationId: source.animationId,
      );
    }
    expected ??= durations;
  }
  return _CompositeTimeline(
      expected == null ? null : List.unmodifiable(expected));
}

SmartTileFrameRef _frameForPart(
  SmartTileVisualPart part, {
  required int frameIndex,
  required Map<String, ProjectSmartTileAnimation> animationById,
}) {
  final source = part.source;
  if (source is SmartTileFrameSource) return source.frame;
  if (source is SmartTileModel3dSource) {
    throw const BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.unsupportedModel3dGround,
      userMessage:
          'Un sol Border 2D issu d’un modèle 3D exige un renderer headless non disponible en v1.',
    );
  }
  final animation =
      animationById[(source as SmartTileAnimationSource).animationId]!;
  final frames = _expandedAnimationFrames(animation);
  return frames[frameIndex % frames.length].frame;
}

List<ProjectSmartTileAnimationFrame> _expandedAnimationFrames(
  ProjectSmartTileAnimation animation,
) {
  if (animation.loop != SmartTileAnimationLoop.pingPong ||
      animation.frames.length < 3) {
    return animation.frames;
  }
  return <ProjectSmartTileAnimationFrame>[
    ...animation.frames,
    ...animation.frames.sublist(1, animation.frames.length - 1).reversed,
  ];
}

img.Image _applyTransform(
  img.Image source,
  SmartTileSpriteTransform transform,
) {
  var result = transform.flipX ? img.flipHorizontal(source) : source;
  if (transform.quarterTurns != 0) {
    result = img.copyRotate(result, angle: transform.quarterTurns * 90);
  }
  return result;
}

bool _intListsEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Future<img.Image> _decodeImage(
    ProjectTilesetEntry tileset, CanonicalBorderPngReader readPng) async {
  final source = tileset.source;
  if (source is ProjectImageCollectionTilesetSource) {
    throw const BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.invalidSmartTileVisual,
        userMessage:
            'Un atlas Smart Tile nécessite une source régulière résoluble.');
  }
  final bytes = await readPng(tileset,
      source is ProjectRegularAtlasTilesetSource ? source.assetId : '');
  final image = img.decodePng(Uint8List.fromList(bytes));
  if (image == null) {
    throw const BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.unreadableTilesetFile,
        userMessage: 'Le fichier image Smart Tile ne peut pas être décodé.');
  }
  final color = tileset.transparentColor;
  if (color != null) {
    for (final pixel in image) {
      if (pixel.r == color.red &&
          pixel.g == color.green &&
          pixel.b == color.blue) {
        pixel.setRgba(0, 0, 0, 0);
      }
    }
  }
  return image;
}

img.Image _resolvePixels(ProjectSmartTileAtlas atlas, SmartTileFrameRef frame,
    img.Image image, ProjectTilesetEntry tileset) {
  try {
    atlas.sourceRectFor(
        column: frame.column,
        row: frame.row,
        columnSpan: frame.columnSpan,
        rowSpan: frame.rowSpan);
    final marginX = atlas.originX + atlas.marginX;
    final marginY = atlas.originY + atlas.marginY;
    final source = ProjectTilesetSource.regularAtlas(
        assetId: 'composition',
        pixelWidth: marginX * 2 +
            atlas.columns * atlas.cellWidth +
            (atlas.columns - 1) * atlas.spacingX,
        pixelHeight: marginY * 2 +
            atlas.rows * atlas.cellHeight +
            (atlas.rows - 1) * atlas.spacingY,
        tileWidth: atlas.cellWidth,
        tileHeight: atlas.cellHeight,
        marginX: marginX,
        marginY: marginY,
        spacingX: atlas.spacingX,
        spacingY: atlas.spacingY);
    final resolved = const ProjectTilesetVisualResolver()
        .resolve(
            source: source,
            selection: ProjectTilesetVisualSelection.regularAtlas(
                source: TilesetSourceRect(
                    x: frame.column,
                    y: frame.row,
                    width: frame.columnSpan,
                    height: frame.rowSpan)),
            cellWidth: atlas.cellWidth,
            cellHeight: atlas.cellHeight)
        .frames
        .single;
    final output = img.Image(
        width: frame.columnSpan * atlas.cellWidth,
        height: frame.rowSpan * atlas.cellHeight,
        numChannels: 4);
    for (final slice in resolved.slices) {
      final rect = slice.sourceRect;
      if (rect.x < 0 ||
          rect.y < 0 ||
          rect.x + rect.width > image.width ||
          rect.y + rect.height > image.height) {
        throw RangeError('Source frame');
      }
      img.compositeImage(
          output,
          img.copyCrop(image,
              x: rect.x, y: rect.y, width: rect.width, height: rect.height),
          dstX: slice.destinationRect.x,
          dstY: slice.destinationRect.y);
    }
    return output;
  } catch (error) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.atlasFrameOutOfBounds,
      userMessage: 'Une frame Smart Tile dépasse son atlas.',
      atlasId: atlas.id,
      tilesetId: tileset.id,
      cause: error,
    );
  }
}

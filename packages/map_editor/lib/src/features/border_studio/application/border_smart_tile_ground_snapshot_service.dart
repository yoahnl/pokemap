import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'border_asset_alpha_analyzer.dart';
import 'border_asset_snapshot_service.dart';

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

/// Freezes a published Smart Tile preset into immutable Border ground pixels.
///
/// Border keeps its historical twenty logical ground roles because those roles
/// are part of the persisted Border materialization contract. Each role is
/// resolved through the native Smart Tile resolver. Every background visual
/// part is then composited into one cell-sized image before the ordinary
/// content-addressed Border snapshot service is invoked. Published Border
/// revisions consequently never read the mutable Smart Tile catalog at render
/// time.
final class BorderSmartTileGroundSnapshotService {
  const BorderSmartTileGroundSnapshotService({
    this.snapshotService = const BorderAssetSnapshotService(),
  });

  final BorderAssetSnapshotService snapshotService;

  Future<Map<BorderGroundVariantRole, BorderAssetSnapshotPreparation>>
      prepareAllRoles({
    required ProjectManifest manifest,
    required String projectRootPath,
    required String sourceSmartTilePresetId,
  }) async {
    final root = await _resolveProjectRoot(projectRootPath);
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
    final result = <BorderGroundVariantRole, BorderAssetSnapshotPreparation>{};

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
      final frames = <BorderAssetSnapshotSourceFrame>[];
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
          SmartTileSourceRect sourceRect;
          try {
            sourceRect = atlas.sourceRectFor(
              column: frame.column,
              row: frame.row,
              columnSpan: frame.columnSpan,
              rowSpan: frame.rowSpan,
            );
          } on RangeError catch (error) {
            throw BorderSmartTileGroundSnapshotException(
              code:
                  BorderSmartTileGroundSnapshotErrorCode.atlasFrameOutOfBounds,
              userMessage: 'Une frame Smart Tile dépasse son atlas.',
              sourceSmartTilePresetId: presetId,
              groundRole: role,
              atlasId: atlas.id,
              cause: error,
            );
          }
          final tileset = tilesetById[atlas.tilesetId];
          if (tileset == null) {
            throw BorderSmartTileGroundSnapshotException(
              code: BorderSmartTileGroundSnapshotErrorCode.missingTileset,
              userMessage: 'Le tileset Smart Tile de la variante '
                  '« ${role.name} » est introuvable.',
              sourceSmartTilePresetId: presetId,
              groundRole: role,
              atlasId: atlas.id,
              tilesetId: atlas.tilesetId,
            );
          }
          final sourceImage = imageByTilesetId[tileset.id] ??=
              await _readTilesetImage(root, tileset);
          if (sourceRect.x < 0 ||
              sourceRect.y < 0 ||
              sourceRect.x + sourceRect.width > sourceImage.width ||
              sourceRect.y + sourceRect.height > sourceImage.height) {
            throw BorderSmartTileGroundSnapshotException(
              code:
                  BorderSmartTileGroundSnapshotErrorCode.atlasFrameOutOfBounds,
              userMessage: 'Une frame Smart Tile dépasse l’image du tileset.',
              sourceSmartTilePresetId: presetId,
              groundRole: role,
              atlasId: atlas.id,
              tilesetId: tileset.id,
            );
          }
          var pixels = img.copyCrop(
            sourceImage,
            x: sourceRect.x,
            y: sourceRect.y,
            width: sourceRect.width,
            height: sourceRect.height,
          );
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
          BorderAssetSnapshotSourceFrame(
            sourceProjectRelativePath:
                'assets/smart_tiles/composite/$presetId/${role.name}.png',
            encodedImageBytes: Uint8List.fromList(img.encodePng(canvas)),
            durationMs: timeline.durationAt(frameIndex),
          ),
        );
      }

      try {
        result[role] = snapshotService.prepare(
          BorderAssetSnapshotRequest(
            sourceElementId: presetId,
            frames: frames,
          ),
        );
      } on BorderAssetSnapshotException catch (error) {
        throw BorderSmartTileGroundSnapshotException(
          code: BorderSmartTileGroundSnapshotErrorCode.invalidSmartTileVisual,
          userMessage: 'La variante Smart Tile « ${role.name} » ne peut pas '
              'être préparée : ${error.userMessage}',
          sourceSmartTilePresetId: presetId,
          groundRole: role,
          cause: error,
        );
      } on BorderAssetAlphaAnalysisException catch (error) {
        throw BorderSmartTileGroundSnapshotException(
          code: BorderSmartTileGroundSnapshotErrorCode.invalidSmartTileVisual,
          userMessage: 'La variante Smart Tile « ${role.name} » ne peut pas '
              'être préparée : ${error.userMessage}',
          sourceSmartTilePresetId: presetId,
          groundRole: role,
          cause: error,
        );
      }
    }
    return Map<BorderGroundVariantRole,
        BorderAssetSnapshotPreparation>.unmodifiable(
      result,
    );
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
      SmartTileRenderChannel.understory ||
      SmartTileRenderChannel.shadow =>
        true,
      SmartTileRenderChannel.canopy ||
      SmartTileRenderChannel.foreground =>
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

Future<String> _resolveProjectRoot(String projectRootPath) async {
  final trimmed = projectRootPath.trim();
  if (trimmed.isEmpty) {
    throw const BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Ouvrez un projet avant de préparer le Smart Tile.',
    );
  }
  final root = Directory(p.normalize(p.absolute(trimmed)));
  if (!await root.exists()) {
    throw const BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Le dossier du projet est introuvable.',
    );
  }
  try {
    return p.normalize(await root.resolveSymbolicLinks());
  } on FileSystemException catch (error) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.invalidProjectRoot,
      userMessage: 'Le dossier du projet ne peut pas être ouvert.',
      cause: error,
    );
  }
}

Future<img.Image> _readTilesetImage(
  String projectRoot,
  ProjectTilesetEntry tileset,
) async {
  final relativePath = tileset.relativePath;
  if (!_isSafeProjectRelativePath(relativePath)) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.unsafeTilesetPath,
      userMessage: 'Le chemin du tileset Smart Tile sort du projet.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  final candidate = p.normalize(
    p.joinAll(<String>[projectRoot, ...p.posix.split(relativePath)]),
  );
  if (!p.isWithin(projectRoot, candidate)) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.unsafeTilesetPath,
      userMessage: 'Le chemin du tileset Smart Tile sort du projet.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  final file = File(candidate);
  if (!await file.exists()) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.missingTilesetFile,
      userMessage: 'Le fichier image du tileset Smart Tile est introuvable.',
      tilesetId: tileset.id,
      relativePath: relativePath,
    );
  }
  try {
    final resolvedFile = p.normalize(await file.resolveSymbolicLinks());
    if (!p.isWithin(projectRoot, resolvedFile)) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.unsafeTilesetPath,
        userMessage: 'Le fichier du tileset Smart Tile sort du projet.',
        tilesetId: tileset.id,
        relativePath: relativePath,
      );
    }
    final bytes = await File(resolvedFile).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw BorderSmartTileGroundSnapshotException(
        code: BorderSmartTileGroundSnapshotErrorCode.unreadableTilesetFile,
        userMessage: 'Le fichier image Smart Tile ne peut pas être décodé.',
        tilesetId: tileset.id,
        relativePath: relativePath,
      );
    }
    final transparent = tileset.transparentColor;
    if (transparent != null) {
      for (final pixel in decoded) {
        if (pixel.r == transparent.red &&
            pixel.g == transparent.green &&
            pixel.b == transparent.blue) {
          pixel.setRgba(0, 0, 0, 0);
        }
      }
    }
    return decoded;
  } on BorderSmartTileGroundSnapshotException {
    rethrow;
  } on FileSystemException catch (error) {
    throw BorderSmartTileGroundSnapshotException(
      code: BorderSmartTileGroundSnapshotErrorCode.unreadableTilesetFile,
      userMessage:
          'Le fichier image du tileset Smart Tile ne peut pas être lu.',
      tilesetId: tileset.id,
      relativePath: relativePath,
      cause: error,
    );
  }
}

bool _isSafeProjectRelativePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains(r'\') ||
      path.contains(':') ||
      path.trim() != path) {
    return false;
  }
  return path.split('/').every(
        (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
      );
}

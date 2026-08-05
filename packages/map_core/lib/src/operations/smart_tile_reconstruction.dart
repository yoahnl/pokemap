import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/project_tileset_source.dart';
import '../models/smart_tile.dart';
import '../models/smart_tile_field.dart';
import 'narrative_event_canonical_json.dart';
import 'smart_tile_layer_context.dart';
import 'smart_tile_resolver.dart';
import 'smart_tile_sprite_geometry.dart';

/// Non-destructive assessment for turning a literal tile layer into native
/// semantic Smart Tile intent.
///
/// The proposed layer is deliberately hidden and the literal source is never
/// modified. Callers can therefore present the coverage and diagnostics before
/// applying the proposal through their normal revision/confirmation flow.
final class SmartTileLayerReconstructionAssessment {
  SmartTileLayerReconstructionAssessment({
    required this.sourceLayerId,
    required this.presetId,
    required this.sourceCellCount,
    required this.reconstructedCellCount,
    required Iterable<int> unresolvedCellIndices,
    required Iterable<int> ambiguousCellIndices,
    required this.conflictCount,
    required this.unsupportedCandidateCount,
    required this.exactVisualMatchCount,
    required Iterable<int> visualMismatchCellIndices,
    required this.assessmentChecksum,
    required this.proposedLayer,
  })  : unresolvedCellIndices = List<int>.unmodifiable(
          unresolvedCellIndices,
        ),
        ambiguousCellIndices = List<int>.unmodifiable(
          ambiguousCellIndices,
        ),
        visualMismatchCellIndices = List<int>.unmodifiable(
          visualMismatchCellIndices,
        );

  final String sourceLayerId;
  final String presetId;
  final int sourceCellCount;
  final int reconstructedCellCount;
  final List<int> unresolvedCellIndices;
  final List<int> ambiguousCellIndices;
  final int conflictCount;
  final int unsupportedCandidateCount;
  final int exactVisualMatchCount;
  final List<int> visualMismatchCellIndices;
  final String assessmentChecksum;
  final SmartTileLayer? proposedLayer;

  double get coverage =>
      sourceCellCount == 0 ? 0 : reconstructedCellCount / sourceCellCount;

  bool get hasProposal => proposedLayer != null;

  Map<String, Object?> toPreviewJson() => <String, Object?>{
        'sourceLayerId': sourceLayerId,
        'presetId': presetId,
        'sourceCellCount': sourceCellCount,
        'reconstructedCellCount': reconstructedCellCount,
        'coverage': coverage,
        'unresolvedCellCount': unresolvedCellIndices.length,
        'unresolvedCellIndices': unresolvedCellIndices,
        'ambiguousCellCount': ambiguousCellIndices.length,
        'ambiguousCellIndices': ambiguousCellIndices,
        'conflictCount': conflictCount,
        'unsupportedCandidateCount': unsupportedCandidateCount,
        'exactVisualMatchCount': exactVisualMatchCount,
        'visualMismatchCellCount': visualMismatchCellIndices.length,
        'visualMismatchCellIndices': visualMismatchCellIndices,
        'assessmentChecksum': assessmentChecksum,
        'hasProposal': hasProposal,
        'sourcePreserved': true,
        'proposedLayerVisible': proposedLayer?.isVisible,
      };
}

final class SmartTileReconstructionException implements Exception {
  const SmartTileReconstructionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// Assesses and prepares a hidden native Smart Tile layer from one literal
/// [TileLayer] and one existing canonical preset.
///
/// This is a generic inverse resolver. It uses canonical atlas, animation and
/// rule data only and carries no Tiled- or game-specific runtime dependency.
SmartTileLayerReconstructionAssessment assessSmartTileLayerReconstruction({
  required MapData map,
  required String sourceLayerId,
  required ProjectManifest manifest,
  required String presetId,
  required String targetLayerId,
  required String targetLayerName,
}) {
  final sourceLayer = _literalLayer(map, sourceLayerId);
  if (sourceLayer.purpose != MapLayerPurpose.visual) {
    throw const SmartTileReconstructionException(
      'smart_tile.reconstruction_source_not_visual',
      'Technical data layers cannot be reconstructed as visual Smart Tiles.',
    );
  }
  final preset = _preset(manifest, presetId);
  final normalizedTargetId = targetLayerId.trim();
  final normalizedTargetName = targetLayerName.trim();
  if (normalizedTargetId.isEmpty || normalizedTargetId != targetLayerId) {
    throw const SmartTileReconstructionException(
      'smart_tile.reconstruction_target_id_invalid',
      'The target layer id must be a nonblank trimmed string.',
    );
  }
  if (normalizedTargetName.isEmpty || normalizedTargetName != targetLayerName) {
    throw const SmartTileReconstructionException(
      'smart_tile.reconstruction_target_name_invalid',
      'The target layer name must be a nonblank trimmed string.',
    );
  }
  if (map.layers.any((layer) => layer.id == normalizedTargetId)) {
    throw SmartTileReconstructionException(
      'smart_tile.reconstruction_target_duplicate',
      'Layer "$normalizedTargetId" already exists.',
    );
  }

  final catalog = manifest.smartTileCatalog;
  final atlasesById = <String, ProjectSmartTileAtlas>{
    for (final atlas in catalog.atlases) atlas.id: atlas,
  };
  final tilesetsById = <String, ProjectTilesetEntry>{
    for (final tileset in manifest.tilesets) tileset.id: tileset,
  };
  final animationsById = <String, ProjectSmartTileAnimation>{
    for (final animation in catalog.animations) animation.id: animation,
  };
  final palette = _materialPalette(preset);
  final materialIndexes = <String, int>{
    for (var index = 1; index < palette.length; index++) palette[index]: index,
  };

  final unsupportedCandidateKeys = <String>{};
  final inverseRules = <_VisualKey, Map<String, _SemanticOption>>{};
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      final baseVisuals = _candidateBaseVisuals(
        candidate,
        atlasesById: atlasesById,
        tilesetsById: tilesetsById,
        animationsById: animationsById,
      );
      if (baseVisuals == null || baseVisuals.isEmpty) {
        unsupportedCandidateKeys.add('${rule.id}\u0000${candidate.id}');
        continue;
      }
      for (final ruleTransform
          in smartTileAllowedTransforms(preset.transformPolicy)) {
        final signature = transformSmartTileSignature(
          rule.signature,
          ruleTransform,
        );
        final centerMaterialId = switch (rule.centerMatch.kind) {
          SmartTileMatchKind.material => rule.centerMatch.materialId,
          SmartTileMatchKind.empty => null,
          SmartTileMatchKind.any ||
          SmartTileMatchKind.same ||
          SmartTileMatchKind.different =>
            preset.defaultMaterialId,
        };
        if (centerMaterialId == null ||
            !materialIndexes.containsKey(centerMaterialId) ||
            !_signatureCanBeProjected(
              signature,
              topology: preset.topology,
              materialIndexes: materialIndexes,
            )) {
          unsupportedCandidateKeys.add('${rule.id}\u0000${candidate.id}');
          continue;
        }
        final option = _SemanticOption(
          centerMaterialId: centerMaterialId,
          signature: signature,
        );
        for (final base in baseVisuals) {
          final key = base.copyWith(
            transform: composeSmartTileSpriteTransforms(
              first: base.transform,
              second: ruleTransform,
            ),
          );
          inverseRules
              .putIfAbsent(key, () => <String, _SemanticOption>{})
              .putIfAbsent(option.semanticKey, () => option);
        }
      }
    }
  }

  final cellCount = map.size.width * map.size.height;
  final semanticCells = List<int>.filled(cellCount, 0);
  final horizontalEdges = List<int>.filled(
    map.size.width * (map.size.height + 1),
    _unassigned,
  );
  final verticalEdges = List<int>.filled(
    (map.size.width + 1) * map.size.height,
    _unassigned,
  );
  final corners = List<int>.filled(
    (map.size.width + 1) * (map.size.height + 1),
    _unassigned,
  );
  final unresolved = <int>[];
  final ambiguous = <int>[];
  final reconstructed = <int, _SemanticOption>{};
  final conflictKeys = <String>{};
  var sourceCellCount = 0;

  for (var cellIndex = 0; cellIndex < cellCount; cellIndex++) {
    final visual = resolveTileLayerCell(sourceLayer, cellIndex);
    if (visual == null) continue;
    sourceCellCount += 1;
    final options = inverseRules[_VisualKey.fromPaletteEntry(visual)]
            ?.values
            .toList(growable: false) ??
        const <_SemanticOption>[];
    if (options.isEmpty) {
      unresolved.add(cellIndex);
      continue;
    }
    if (options.length > 1) {
      ambiguous.add(cellIndex);
      continue;
    }
    final option = options.single;
    final centerIndex = materialIndexes[option.centerMaterialId]!;
    semanticCells[cellIndex] = centerIndex;
    reconstructed[cellIndex] = option;
    final x = cellIndex % map.size.width;
    final y = cellIndex ~/ map.size.width;
    _projectSignature(
      signature: option.signature,
      topology: preset.topology,
      centerIndex: centerIndex,
      materialIndexes: materialIndexes,
      x: x,
      y: y,
      width: map.size.width,
      horizontalEdges: horizontalEdges,
      verticalEdges: verticalEdges,
      corners: corners,
      conflictKeys: conflictKeys,
    );
  }

  SmartTileLayer? proposal;
  var exactVisualMatchCount = 0;
  final visualMismatches = <int>[];
  if (reconstructed.isNotEmpty) {
    final field = _field(
      topology: preset.topology,
      semanticCells: semanticCells,
      horizontalEdges: horizontalEdges,
      verticalEdges: verticalEdges,
      corners: corners,
    );
    proposal = SmartTileLayer(
      id: normalizedTargetId,
      name: normalizedTargetName,
      isVisible: false,
      presetId: preset.id,
      usage: preset.usage,
      materialPalette: palette,
      field: field,
      layerSeed: preset.seedSalt,
      properties: <String, String>{
        'reconstruction.sourceLayerId': sourceLayer.id,
        'reconstruction.presetId': preset.id,
        'reconstruction.coverage':
            (reconstructed.length / sourceCellCount).toStringAsFixed(6),
        'reconstruction.sourcePreserved': 'true',
      },
    );
    final projectedMap = map.copyWith(
      layers: <MapLayer>[...map.layers, proposal],
    );
    final resolver = PreparedSmartTileResolver(
      preset: preset,
      materials: catalog.materials,
      mapId: map.id,
      layerId: proposal.id,
      layerSeed: proposal.layerSeed,
    );
    for (final entry in reconstructed.entries) {
      final cellIndex = entry.key;
      final x = cellIndex % map.size.width;
      final y = cellIndex ~/ map.size.width;
      final resolution = resolver.resolve(
        context: smartTileCellContextForLayerCell(
          layer: proposal,
          map: projectedMap,
          preset: preset,
          x: x,
          y: y,
        ),
        x: x,
        y: y,
      );
      final sourceVisual = resolveTileLayerCell(sourceLayer, cellIndex)!;
      final resolvedVisuals = resolution.candidate == null
          ? const <_VisualKey>[]
          : (_candidateBaseVisuals(
                    resolution.candidate!,
                    atlasesById: atlasesById,
                    tilesetsById: tilesetsById,
                    animationsById: animationsById,
                  ) ??
                  const <_VisualKey>[])
              .map(
                (base) => base.copyWith(
                  transform: composeSmartTileSpriteTransforms(
                    first: base.transform,
                    second: resolution.transform,
                  ),
                ),
              )
              .toList(growable: false);
      if (resolvedVisuals.contains(_VisualKey.fromPaletteEntry(sourceVisual))) {
        exactVisualMatchCount += 1;
      } else {
        visualMismatches.add(cellIndex);
      }
    }
  }

  final coverage =
      sourceCellCount == 0 ? 0 : reconstructed.length / sourceCellCount;
  final checksumPayload = <String, Object?>{
    'sourceLayerId': sourceLayer.id,
    'presetId': preset.id,
    'targetLayerId': normalizedTargetId,
    'targetLayerName': normalizedTargetName,
    'sourceCellCount': sourceCellCount,
    'reconstructedCellCount': reconstructed.length,
    'unresolvedCellIndices': unresolved,
    'ambiguousCellIndices': ambiguous,
    'conflicts': conflictKeys.toList()..sort(),
    'unsupportedCandidateCount': unsupportedCandidateKeys.length,
    'exactVisualMatchCount': exactVisualMatchCount,
    'visualMismatchCellIndices': visualMismatches,
    'coverage': coverage,
    'proposedLayer': proposal?.toJson(),
  };
  final checksum = 'sha256:${narrativeEventCanonicalSha256(checksumPayload)}';
  if (proposal != null) {
    proposal = proposal.copyWith(
      properties: <String, String>{
        ...proposal.properties,
        'reconstruction.assessmentChecksum': checksum,
      },
    );
  }
  return SmartTileLayerReconstructionAssessment(
    sourceLayerId: sourceLayer.id,
    presetId: preset.id,
    sourceCellCount: sourceCellCount,
    reconstructedCellCount: reconstructed.length,
    unresolvedCellIndices: unresolved,
    ambiguousCellIndices: ambiguous,
    conflictCount: conflictKeys.length,
    unsupportedCandidateCount: unsupportedCandidateKeys.length,
    exactVisualMatchCount: exactVisualMatchCount,
    visualMismatchCellIndices: visualMismatches,
    assessmentChecksum: checksum,
    proposedLayer: proposal,
  );
}

const int _unassigned = -1;

TileLayer _literalLayer(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId && layer is TileLayer) return layer;
  }
  throw SmartTileReconstructionException(
    'smart_tile.reconstruction_source_invalid',
    'Layer "$layerId" is not a literal tile layer.',
  );
}

ProjectSmartTilePreset _preset(ProjectManifest manifest, String presetId) {
  for (final preset in manifest.smartTileCatalog.presets) {
    if (preset.id == presetId) return preset;
  }
  throw SmartTileReconstructionException(
    'smart_tile.reconstruction_preset_missing',
    'Preset "$presetId" does not exist.',
  );
}

List<String> _materialPalette(ProjectSmartTilePreset preset) {
  final materials = <String>[''];
  final seen = <String>{};
  for (final materialId in preset.allowedMaterialIds) {
    if (materialId.isNotEmpty && seen.add(materialId)) {
      materials.add(materialId);
    }
  }
  if (!seen.contains(preset.defaultMaterialId)) {
    throw const SmartTileReconstructionException(
      'smart_tile.reconstruction_default_material_invalid',
      'The preset default material is not in allowedMaterialIds.',
    );
  }
  return List<String>.unmodifiable(materials);
}

List<_VisualKey>? _candidateBaseVisuals(
  SmartTileCandidate candidate, {
  required Map<String, ProjectSmartTileAtlas> atlasesById,
  required Map<String, ProjectTilesetEntry> tilesetsById,
  required Map<String, ProjectSmartTileAnimation> animationsById,
}) {
  if (candidate.parts.length != 1) return null;
  final part = candidate.parts.single;
  if (part.channel != SmartTileRenderChannel.ground ||
      part.frameSampling != SmartTileFrameSampling.fullFrame ||
      part.offsetUnit != SmartTileOffsetUnit.pixel ||
      part.offsetX != 0 ||
      part.offsetY != 0 ||
      part.footprintWidth != 1 ||
      part.footprintHeight != 1 ||
      part.anchorX != 0 ||
      part.anchorY != 0) {
    return null;
  }
  return switch (part.source) {
    SmartTileFrameSource(:final frame) => <_VisualKey>[
        if (_frameVisual(
          frame,
          atlasesById: atlasesById,
          tilesetsById: tilesetsById,
          transform: part.transform,
        )
            case final _VisualKey visual)
          visual,
      ],
    SmartTileAnimationSource(:final animationId) => _animationVisuals(
        animationId,
        partTransform: part.transform,
        atlasesById: atlasesById,
        tilesetsById: tilesetsById,
        animationsById: animationsById,
      ),
  };
}

_VisualKey? _frameVisual(
  SmartTileFrameRef frame, {
  required Map<String, ProjectSmartTileAtlas> atlasesById,
  required Map<String, ProjectTilesetEntry> tilesetsById,
  required SmartTileSpriteTransform transform,
}) {
  if (frame.columnSpan != 1 || frame.rowSpan != 1) return null;
  final atlas = atlasesById[frame.atlasId];
  if (atlas == null) return null;
  final source = tilesetsById[atlas.tilesetId]?.source;
  if (source is! ProjectRegularAtlasTilesetSource) return null;
  final rect = atlas.sourceRectFor(column: frame.column, row: frame.row);
  if (rect.width != source.tileWidth || rect.height != source.tileHeight) {
    return null;
  }
  final strideX = source.tileWidth + source.spacingX;
  final strideY = source.tileHeight + source.spacingY;
  final deltaX = rect.x - source.marginX;
  final deltaY = rect.y - source.marginY;
  if (deltaX < 0 ||
      deltaY < 0 ||
      deltaX % strideX != 0 ||
      deltaY % strideY != 0) {
    return null;
  }
  final column = deltaX ~/ strideX;
  final row = deltaY ~/ strideY;
  if (column >= source.columns || row >= source.rows) return null;
  return _VisualKey(
    tilesetId: atlas.tilesetId,
    localTileId: row * source.columns + column,
    transform: transform,
  );
}

List<_VisualKey>? _animationVisuals(
  String animationId, {
  required SmartTileSpriteTransform partTransform,
  required Map<String, ProjectSmartTileAtlas> atlasesById,
  required Map<String, ProjectTilesetEntry> tilesetsById,
  required Map<String, ProjectSmartTileAnimation> animationsById,
}) {
  final animation = animationsById[animationId];
  if (animation == null || animation.frames.isEmpty) return null;
  String? tilesetId;
  final frameIds = <int>[];
  final durations = <int>[];
  for (final frame in animation.frames) {
    final visual = _frameVisual(
      frame.frame,
      atlasesById: atlasesById,
      tilesetsById: tilesetsById,
      transform: partTransform,
    );
    if (visual == null ||
        (tilesetId != null && tilesetId != visual.tilesetId)) {
      return null;
    }
    tilesetId = visual.tilesetId;
    frameIds.add(visual.localTileId);
    durations.add(frame.durationMs);
  }
  final source = tilesetsById[tilesetId]?.source;
  if (source is! ProjectRegularAtlasTilesetSource) return null;
  final result = <_VisualKey>[];
  for (final candidate in source.tileAnimations) {
    if (candidate.frames.length != frameIds.length) continue;
    var same = true;
    for (var index = 0; index < frameIds.length; index++) {
      final frame = candidate.frames[index];
      if (frame.tileId != frameIds[index] ||
          frame.durationMs != durations[index]) {
        same = false;
        break;
      }
    }
    if (same) {
      result.add(
        _VisualKey(
          tilesetId: tilesetId!,
          localTileId: candidate.tileId,
          transform: partTransform,
        ),
      );
    }
  }
  return result.isEmpty ? null : List<_VisualKey>.unmodifiable(result);
}

bool _signatureCanBeProjected(
  SmartTileSignature signature, {
  required SmartTileTopology topology,
  required Map<String, int> materialIndexes,
}) {
  if (topology != SmartTileTopology.wangEdge4 &&
      topology != SmartTileTopology.wangCorner4 &&
      topology != SmartTileTopology.wang8) {
    return true;
  }
  final active = switch (topology) {
    SmartTileTopology.wangEdge4 => <SmartTileSlotMatch>[
        signature.northEdge,
        signature.eastEdge,
        signature.southEdge,
        signature.westEdge,
      ],
    SmartTileTopology.wangCorner4 => <SmartTileSlotMatch>[
        signature.northEastCorner,
        signature.southEastCorner,
        signature.southWestCorner,
        signature.northWestCorner,
      ],
    SmartTileTopology.wang8 => <SmartTileSlotMatch>[
        signature.northEdge,
        signature.northEastCorner,
        signature.eastEdge,
        signature.southEastCorner,
        signature.southEdge,
        signature.southWestCorner,
        signature.westEdge,
        signature.northWestCorner,
      ],
    _ => const <SmartTileSlotMatch>[],
  };
  return active.every(
    (slot) => switch (slot.kind) {
      SmartTileMatchKind.different => false,
      SmartTileMatchKind.material =>
        materialIndexes.containsKey(slot.materialId),
      _ => true,
    },
  );
}

void _projectSignature({
  required SmartTileSignature signature,
  required SmartTileTopology topology,
  required int centerIndex,
  required Map<String, int> materialIndexes,
  required int x,
  required int y,
  required int width,
  required List<int> horizontalEdges,
  required List<int> verticalEdges,
  required List<int> corners,
  required Set<String> conflictKeys,
}) {
  int? value(SmartTileSlotMatch slot) => switch (slot.kind) {
        SmartTileMatchKind.any => null,
        SmartTileMatchKind.empty => 0,
        SmartTileMatchKind.same => centerIndex,
        SmartTileMatchKind.material => materialIndexes[slot.materialId],
        SmartTileMatchKind.different => null,
      };

  void assign(List<int> lattice, int index, int? next, String key) {
    if (next == null) return;
    final current = lattice[index];
    if (current == _unassigned) {
      lattice[index] = next;
    } else if (current != next) {
      conflictKeys.add(key);
    }
  }

  if (topology == SmartTileTopology.wangEdge4 ||
      topology == SmartTileTopology.wang8) {
    assign(
      horizontalEdges,
      y * width + x,
      value(signature.northEdge),
      'horizontal:$x:$y',
    );
    assign(
      verticalEdges,
      y * (width + 1) + x + 1,
      value(signature.eastEdge),
      'vertical:${x + 1}:$y',
    );
    assign(
      horizontalEdges,
      (y + 1) * width + x,
      value(signature.southEdge),
      'horizontal:$x:${y + 1}',
    );
    assign(
      verticalEdges,
      y * (width + 1) + x,
      value(signature.westEdge),
      'vertical:$x:$y',
    );
  }
  if (topology == SmartTileTopology.wangCorner4 ||
      topology == SmartTileTopology.wang8) {
    assign(
      corners,
      y * (width + 1) + x + 1,
      value(signature.northEastCorner),
      'corner:${x + 1}:$y',
    );
    assign(
      corners,
      (y + 1) * (width + 1) + x + 1,
      value(signature.southEastCorner),
      'corner:${x + 1}:${y + 1}',
    );
    assign(
      corners,
      (y + 1) * (width + 1) + x,
      value(signature.southWestCorner),
      'corner:$x:${y + 1}',
    );
    assign(
      corners,
      y * (width + 1) + x,
      value(signature.northWestCorner),
      'corner:$x:$y',
    );
  }
}

SmartTileField _field({
  required SmartTileTopology topology,
  required List<int> semanticCells,
  required List<int> horizontalEdges,
  required List<int> verticalEdges,
  required List<int> corners,
}) {
  List<int> finalized(List<int> values) => List<int>.unmodifiable(
        values.map((value) => value == _unassigned ? 0 : value),
      );
  return switch (topology) {
    SmartTileTopology.uniform ||
    SmartTileTopology.cardinal4 ||
    SmartTileTopology.blob8 =>
      SmartTileField.cell(semanticCells: semanticCells),
    SmartTileTopology.wangEdge4 => SmartTileField.edge(
        semanticCells: semanticCells,
        horizontalEdges: finalized(horizontalEdges),
        verticalEdges: finalized(verticalEdges),
      ),
    SmartTileTopology.wangCorner4 => SmartTileField.corner(
        semanticCells: semanticCells,
        corners: finalized(corners),
      ),
    SmartTileTopology.wang8 => SmartTileField.mixed(
        semanticCells: semanticCells,
        horizontalEdges: finalized(horizontalEdges),
        verticalEdges: finalized(verticalEdges),
        corners: finalized(corners),
      ),
  };
}

final class _VisualKey {
  const _VisualKey({
    required this.tilesetId,
    required this.localTileId,
    required this.transform,
  });

  factory _VisualKey.fromPaletteEntry(TileLayerPaletteEntry entry) =>
      _VisualKey(
        tilesetId: entry.tilesetId,
        localTileId: entry.localTileId,
        transform: entry.transform,
      );

  final String tilesetId;
  final int localTileId;
  final SmartTileSpriteTransform transform;

  _VisualKey copyWith({SmartTileSpriteTransform? transform}) => _VisualKey(
        tilesetId: tilesetId,
        localTileId: localTileId,
        transform: transform ?? this.transform,
      );

  @override
  bool operator ==(Object other) =>
      other is _VisualKey &&
      other.tilesetId == tilesetId &&
      other.localTileId == localTileId &&
      other.transform == transform;

  @override
  int get hashCode => Object.hash(tilesetId, localTileId, transform);
}

final class _SemanticOption {
  const _SemanticOption({
    required this.centerMaterialId,
    required this.signature,
  });

  final String centerMaterialId;
  final SmartTileSignature signature;

  String get semanticKey => canonicalizeNarrativeEventJson(<String, Object?>{
        'centerMaterialId': centerMaterialId,
        'signature': signature.toJson(),
      });
}

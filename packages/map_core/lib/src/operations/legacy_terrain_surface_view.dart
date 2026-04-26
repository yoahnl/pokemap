import '../models/enums.dart';
import '../models/project_manifest.dart';

const int _defaultTerrainPresetVariantWeight = 1;

/// Read-only surface-shaped view over a legacy [ProjectTerrainPreset].
///
/// This is the terrain-side counterpart to `LegacyPathSurfaceView`, but it is
/// deliberately not a shared union or common Surface abstraction. The future
/// Surface Engine still needs design space for paths, terrains, water, tall
/// grass, gameplay overlays, encounters, and animation rules. V0 only gives
/// callers a stable, read-only way to inspect current terrain preset data.
///
/// The adapter is non-persistent:
///
/// - no JSON;
/// - no Freezed model;
/// - no manifest schema change;
/// - no runtime/editor/gameplay dependency;
/// - no migration behavior.
///
/// It preserves the source data instead of improving it. Variant order, frame
/// order, frame values, frame objects, and weights are all kept exactly as the
/// legacy preset authored them.
final class LegacyTerrainSurfaceView {
  LegacyTerrainSurfaceView({
    required this.id,
    required this.name,
    required this.terrainType,
    required this.tilesetId,
    required this.categoryId,
    required this.sortOrder,
    required List<LegacyTerrainSurfaceVariantView> variants,
  }) : variants = List.unmodifiable(variants);

  /// Legacy terrain preset id.
  final String id;

  /// Legacy terrain preset display name.
  final String name;

  /// Terrain role already carried by the legacy terrain preset.
  ///
  /// This stays as [TerrainType], not [PathSurfaceKind], so terrain and path
  /// compatibility layers do not collapse into one premature model.
  final TerrainType terrainType;

  /// Preset-level tileset id.
  ///
  /// Individual [TilesetVisualFrame] values may still override this with their
  /// own non-empty `tilesetId`, matching the existing frame model.
  final String tilesetId;

  /// Optional terrain preset category id.
  ///
  /// The source [ProjectTerrainPreset.categoryId] is nullable, so the adapter
  /// keeps it nullable rather than inventing an empty-string sentinel.
  final String? categoryId;

  /// Authoring sort order copied from the preset.
  final int sortOrder;

  /// Read-only list of weighted terrain visual variants.
  final List<LegacyTerrainSurfaceVariantView> variants;

  /// Whether the legacy preset currently has any authored visual variants.
  bool get hasVariants => variants.isNotEmpty;

  /// Whether at least one terrain variant has multiple visual frames.
  ///
  /// This is a structural check only. It does not inspect frame durations or
  /// invoke [resolveTileVisualFrameTimeline]; the adapter is not an animation
  /// engine.
  bool get hasAnimatedVariants => variants.any((variant) => variant.isAnimated);

  /// Whether at least one variant uses a non-default weight.
  ///
  /// The audited default in [TerrainPresetVariant] is `@Default(1)`. V0 does
  /// not normalize or validate weights; it only reports whether authored data
  /// differs from that legacy default.
  bool get hasWeightedVariants => variants.any(
        (variant) => variant.weight != _defaultTerrainPresetVariantWeight,
      );
}

/// Read-only view of one legacy terrain visual variant.
final class LegacyTerrainSurfaceVariantView {
  LegacyTerrainSurfaceVariantView({
    required List<TilesetVisualFrame> frames,
    required this.weight,
  }) : frames = List.unmodifiable(frames);

  /// Read-only visual frames for this terrain variant.
  ///
  /// Frame objects are not cloned; [TilesetVisualFrame] is already an immutable
  /// Freezed value and preserving object identity helps prove the adapter does
  /// not reinterpret visual data.
  final List<TilesetVisualFrame> frames;

  /// Legacy weight copied from [TerrainPresetVariant.weight].
  ///
  /// V0 does not use this value to choose a variant. Selection policy belongs
  /// to future editor/runtime code, not to this read-only bridge.
  final int weight;

  /// Whether this variant has at least one visual frame.
  bool get hasFrames => frames.isNotEmpty;

  /// Whether this variant has multiple visual frames.
  bool get isAnimated => frames.length > 1;
}

/// Creates a read-only legacy terrain surface view from [preset].
///
/// This is a pure adapter. It performs no validation and no migration; it only
/// snapshots the current legacy terrain preset data into unmodifiable lists.
LegacyTerrainSurfaceView createLegacyTerrainSurfaceView(
  ProjectTerrainPreset preset,
) {
  return LegacyTerrainSurfaceView(
    id: preset.id,
    name: preset.name,
    terrainType: preset.terrainType,
    tilesetId: preset.tilesetId,
    categoryId: preset.categoryId,
    sortOrder: preset.sortOrder,
    variants: preset.variants
        .map(
          (variant) => LegacyTerrainSurfaceVariantView(
            frames: variant.frames,
            weight: variant.weight,
          ),
        )
        .toList(growable: false),
  );
}

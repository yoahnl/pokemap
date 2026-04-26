import '../models/enums.dart';
import '../models/project_manifest.dart';

/// Read-only surface-shaped view over a legacy [ProjectPathPreset].
///
/// This is a transition adapter, not a persisted Surface model. It exists so
/// future Surface Engine work can talk about current path presets with surface
/// vocabulary without changing JSON, Freezed contracts, editor behavior, or
/// runtime rendering.
///
/// V0 intentionally preserves the source data instead of improving it:
///
/// - [surfaceKind] is copied from [ProjectPathPreset.surfaceKind].
/// - [tilesetId] keeps the preset-level tileset id.
/// - [categoryId] stays nullable because the source model is nullable.
/// - [variants] keeps the exact authored order.
/// - frame lists keep their exact authored order and exact frame objects.
///
/// The adapter does not resolve autotile variants, timeline frames, gameplay
/// rules, fallbacks, or duplicate mappings. Those are separate concerns that
/// should remain explicit while the future Surface Engine takes shape.
final class LegacyPathSurfaceView {
  LegacyPathSurfaceView({
    required this.id,
    required this.name,
    required this.surfaceKind,
    required this.tilesetId,
    required this.categoryId,
    required this.sortOrder,
    required List<LegacyPathSurfaceVariantView> variants,
  }) : variants = List.unmodifiable(variants);

  /// Legacy preset id.
  final String id;

  /// Legacy preset display name.
  final String name;

  /// Surface kind already carried by the legacy path preset.
  final PathSurfaceKind surfaceKind;

  /// Preset-level tileset id.
  ///
  /// Individual [TilesetVisualFrame] values may still override this with their
  /// own non-empty `tilesetId`, matching the existing frame model.
  final String tilesetId;

  /// Optional path preset category id.
  ///
  /// The source [ProjectPathPreset.categoryId] is nullable, so the adapter keeps
  /// it nullable rather than inventing an empty-string sentinel.
  final String? categoryId;

  /// Authoring sort order copied from the preset.
  final int sortOrder;

  /// Read-only list of path variant visual mappings.
  final List<LegacyPathSurfaceVariantView> variants;

  /// Whether the legacy preset currently has any authored variant mappings.
  bool get hasVariants => variants.isNotEmpty;

  /// Whether at least one variant has multiple visual frames.
  ///
  /// This is a structural check only. It does not inspect frame durations or
  /// invoke [resolveTileVisualFrameTimeline]; the adapter is not an animation
  /// engine.
  bool get hasAnimatedVariants => variants.any((variant) => variant.isAnimated);

  /// Returns the frames for the first authored mapping matching [variant].
  ///
  /// The legacy source model stores mappings as a list and does not enforce
  /// uniqueness. V0 therefore returns the first match and does not merge,
  /// de-duplicate, fallback, or synthesize frames. Missing variants return a
  /// shared empty read-only list.
  List<TilesetVisualFrame> framesForVariant(TerrainPathVariant variant) {
    for (final mapping in variants) {
      if (mapping.variant == variant) {
        return mapping.frames;
      }
    }
    return const <TilesetVisualFrame>[];
  }
}

/// Read-only view of one legacy path variant mapping.
///
/// This keeps the existing [TerrainPathVariant] vocabulary so current autotile
/// behavior remains explicit while future Surface definitions are designed.
final class LegacyPathSurfaceVariantView {
  LegacyPathSurfaceVariantView({
    required this.variant,
    required List<TilesetVisualFrame> frames,
  }) : frames = List.unmodifiable(frames);

  /// Legacy autotile/path variant role.
  final TerrainPathVariant variant;

  /// Read-only visual frames for [variant].
  ///
  /// Frame objects are not cloned; [TilesetVisualFrame] is already an immutable
  /// Freezed value and preserving object identity helps prove the adapter does
  /// not reinterpret visual data.
  final List<TilesetVisualFrame> frames;

  /// Whether this mapping has at least one visual frame.
  bool get hasFrames => frames.isNotEmpty;

  /// Whether this mapping has multiple visual frames.
  bool get isAnimated => frames.length > 1;
}

/// Creates a read-only legacy surface view from [preset].
///
/// This is a pure adapter. It performs no validation and no migration; it only
/// snapshots the current legacy path preset data into unmodifiable lists.
LegacyPathSurfaceView createLegacyPathSurfaceView(ProjectPathPreset preset) {
  return LegacyPathSurfaceView(
    id: preset.id,
    name: preset.name,
    surfaceKind: preset.surfaceKind,
    tilesetId: preset.tilesetId,
    categoryId: preset.categoryId,
    sortOrder: preset.sortOrder,
    variants: preset.variants
        .map(
          (mapping) => LegacyPathSurfaceVariantView(
            variant: mapping.variant,
            frames: mapping.frames,
          ),
        )
        .toList(growable: false),
  );
}

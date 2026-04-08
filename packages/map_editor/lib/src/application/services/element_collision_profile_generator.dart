import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import 'element_collision_authoring_service.dart';

/// Backward-compatible facade kept for the editor notifier.
///
/// Historically this service inspected sprite pixels. The new direction is
/// intentionally simpler and fully grid based:
/// - resolve a default padding for known presets when the author did not set one
/// - derive base cells from that padding
/// - persist the final cells only
///
/// No image analysis happens here anymore.
class ElementCollisionProfileGenerator {
  const ElementCollisionProfileGenerator({
    this.authoringService = const ElementCollisionAuthoringService(),
  });

  final ElementCollisionAuthoringService authoringService;

  Future<ElementCollisionProfile> generate({
    required String tilesetImagePath,
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required ElementPresetKind presetKind,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final normalizedPath = tilesetImagePath.trim();
    if (normalizedPath.isEmpty) {
      throw const FormatException('Tileset image path is empty');
    }
    if (tileWidth <= 0 || tileHeight <= 0) {
      throw const FormatException('Tile size must be strictly positive');
    }
    if (source.width <= 0 || source.height <= 0) {
      throw const FormatException(
        'Element source size must be strictly positive',
      );
    }

    final resolvedPadding = _resolveAutoPadding(
      presetKind: presetKind,
      padding: padding,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );

    return authoringService.recalculateFromPadding(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: resolvedPadding,
      preserveOverrides: false,
    );
  }

  WarpTriggerPadding _resolveAutoPadding({
    required ElementPresetKind presetKind,
    required WarpTriggerPadding padding,
    required int tileWidth,
    required int tileHeight,
  }) {
    if (padding.top > 0 ||
        padding.right > 0 ||
        padding.bottom > 0 ||
        padding.left > 0) {
      return padding;
    }

    int px(double ratio, int tile) {
      return math.max(0, (tile * ratio).round());
    }

    return switch (presetKind) {
      ElementPresetKind.tree => WarpTriggerPadding(
          left: px(0.18, tileWidth),
          right: px(0.18, tileWidth),
          bottom: px(0.06, tileHeight),
        ),
      ElementPresetKind.building => WarpTriggerPadding(
          left: px(0.10, tileWidth),
          right: px(0.10, tileWidth),
        ),
      ElementPresetKind.rock => WarpTriggerPadding(
          left: px(0.12, tileWidth),
          right: px(0.12, tileWidth),
        ),
      ElementPresetKind.tallDecoration => WarpTriggerPadding(
          left: px(0.15, tileWidth),
          right: px(0.15, tileWidth),
        ),
      ElementPresetKind.cliff ||
      ElementPresetKind.generic =>
        const WarpTriggerPadding(),
    };
  }
}

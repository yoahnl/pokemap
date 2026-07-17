import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'border_geometry.dart';
import 'border_materialization.dart';
import 'border_signed_int64.dart';
import 'border_value_objects.dart';

/// Integer pixel delta applied to one generated Border slot.
@immutable
final class BorderPixelOffset {
  const BorderPixelOffset({required this.x, required this.y});

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPixelOffset && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Persisted local correction attached to one stable generated slot.
@immutable
final class BorderSlotOverride {
  BorderSlotOverride({
    required this.slotKey,
    required this.variationSalt,
    required this.suppressed,
    required this.locked,
    this.lockedPlacement,
    this.replacementPrimitiveId,
    this.offsetDeltaPx,
    this.transformOverride,
  }) {
    _requireStableText(slotKey, 'BorderSlotOverride.slotKey');
    final replacement = replacementPrimitiveId;
    if (replacement != null) {
      _requireStableText(
        replacement,
        'BorderSlotOverride.replacementPrimitiveId',
      );
    }
    if (locked != (lockedPlacement != null)) {
      throw const ValidationException(
        'BorderSlotOverride.locked must be true exactly when '
        'lockedPlacement is present',
      );
    }
    final placement = lockedPlacement;
    if (placement != null && placement.slotKey != slotKey) {
      throw const ValidationException(
        'BorderSlotOverride.lockedPlacement.slotKey must match slotKey',
      );
    }
    if (suppressed &&
        (locked ||
            placement != null ||
            replacement != null ||
            offsetDeltaPx != null ||
            transformOverride != null)) {
      throw const ValidationException(
        'A suppressed BorderSlotOverride cannot also lock, replace, move, '
        'or transform its slot',
      );
    }
  }

  final String slotKey;
  final BorderSignedInt64 variationSalt;
  final bool suppressed;
  final bool locked;
  final BorderResolvedPlacement? lockedPlacement;
  final String? replacementPrimitiveId;
  final BorderPixelOffset? offsetDeltaPx;
  final BorderSpriteTransform? transformOverride;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderSlotOverride &&
          slotKey == other.slotKey &&
          variationSalt == other.variationSalt &&
          suppressed == other.suppressed &&
          locked == other.locked &&
          lockedPlacement == other.lockedPlacement &&
          replacementPrimitiveId == other.replacementPrimitiveId &&
          offsetDeltaPx == other.offsetDeltaPx &&
          transformOverride == other.transformOverride;

  @override
  int get hashCode => Object.hash(
        slotKey,
        variationSalt,
        suppressed,
        locked,
        lockedPlacement,
        replacementPrimitiveId,
        offsetDeltaPx,
        transformOverride,
      );
}

/// One named Border intent and its last explicitly applied visual output.
@immutable
final class BorderFeature {
  BorderFeature({
    required this.id,
    required this.name,
    required this.blueprintId,
    required this.seed,
    required this.geometry,
    this.lineSide = BorderLineSide.primary,
    this.paramsOverride,
    required List<BorderSlotOverride> overrides,
    required List<BorderKeepOutRegion> keepOutRegions,
    this.materialization,
  })  : _overrides = List<BorderSlotOverride>.unmodifiable(overrides),
        _keepOutRegions =
            List<BorderKeepOutRegion>.unmodifiable(keepOutRegions) {
    _requireStableText(id, 'BorderFeature.id');
    _requireStableText(name, 'BorderFeature.name');
    _requireStableText(blueprintId, 'BorderFeature.blueprintId');
    _requireUniqueOverrideSlotKeys(_overrides);
    _requireUniqueKeepOutIds(_keepOutRegions);
  }

  final String id;
  final String name;
  final String blueprintId;
  final BorderSignedInt64 seed;
  final BorderFeatureGeometry geometry;
  final BorderLineSide lineSide;
  final BorderGenerationParams? paramsOverride;
  final List<BorderSlotOverride> _overrides;
  final List<BorderKeepOutRegion> _keepOutRegions;
  final BorderMaterialization? materialization;

  List<BorderSlotOverride> get overrides => _overrides;

  List<BorderKeepOutRegion> get keepOutRegions => _keepOutRegions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderFeature &&
          id == other.id &&
          name == other.name &&
          blueprintId == other.blueprintId &&
          seed == other.seed &&
          geometry == other.geometry &&
          lineSide == other.lineSide &&
          paramsOverride == other.paramsOverride &&
          _listsEqual(_overrides, other._overrides) &&
          _listsEqual(_keepOutRegions, other._keepOutRegions) &&
          materialization == other.materialization;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        blueprintId,
        seed,
        geometry,
        lineSide,
        paramsOverride,
        Object.hashAll(_overrides),
        Object.hashAll(_keepOutRegions),
        materialization,
      );
}

void _requireUniqueOverrideSlotKeys(List<BorderSlotOverride> overrides) {
  final seen = <String>{};
  for (final override in overrides) {
    if (!seen.add(override.slotKey)) {
      throw ValidationException(
        'BorderFeature.overrides must not contain duplicate slotKey: '
        '${override.slotKey}',
      );
    }
  }
}

void _requireUniqueKeepOutIds(List<BorderKeepOutRegion> keepOutRegions) {
  final seen = <String>{};
  for (final region in keepOutRegions) {
    if (!seen.add(region.id)) {
      throw ValidationException(
        'BorderFeature.keepOutRegions must not contain duplicate id: '
        '${region.id}',
      );
    }
  }
}

void _requireStableText(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
}

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

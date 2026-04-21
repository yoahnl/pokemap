// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'map_data.dart';

part 'element_collision_profile.freezed.dart';
part 'element_collision_profile.g.dart';

@freezed
class ElementCollisionPixelMask with _$ElementCollisionPixelMask {
  @JsonSerializable(explicitToJson: true)
  const factory ElementCollisionPixelMask({
    required int widthPx,
    required int heightPx,
    @Default(ElementCollisionMaskEncoding.packedBitsV1)
    ElementCollisionMaskEncoding encoding,
    @Default('') String dataBase64,
  }) = _ElementCollisionPixelMask;

  factory ElementCollisionPixelMask.fromJson(Map<String, dynamic> json) =>
      _$ElementCollisionPixelMaskFromJson(json);
}

@freezed
class ElementCollisionProfile with _$ElementCollisionProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ElementCollisionProfile({
    @Default(ElementCollisionProfileSource.generated)
    ElementCollisionProfileSource source,
    ElementCollisionPixelMask? visualMask,
    @JsonKey(name: 'pixelMask') ElementCollisionPixelMask? collisionMask,
    ElementCollisionPixelMask? occlusionMask,
    @Default(WarpTriggerPadding()) WarpTriggerPadding padding,
    // Authoring base when `source == manual`.
    //
    // This field is editor-facing only. It stores the main collision shape as
    // authored by the user (for example a lasso/polygon around a building).
    //
    // Important product invariant:
    // - when this manual shape exists, it is the primary collision base
    // - padding stays available as a secondary helper only
    // - runtime still ignores this field and consumes only `cells`
    @Default([]) List<GridPos> shapeCells,
    // Runtime truth: the gameplay/runtime layers only read these final cells.
    // Editor-only concepts such as base cells or paint modes must be resolved
    // before data reaches this field.
    @Default([]) List<GridPos> cells,
    // Authoring intent: cells explicitly added on top of the current primary
    // base.
    //
    // That base is:
    // - the padding-derived rectangle when `source == generated`
    // - the author polygon/shape when `source == manual`
    @Default([]) List<GridPos> manualAddedCells,
    // Authoring intent: cells explicitly removed from the current primary base.
    // Runtime ignores this field; the editor folds it into `cells` before
    // save/use.
    @Default([]) List<GridPos> manualRemovedCells,
  }) = _ElementCollisionProfile;

  factory ElementCollisionProfile.fromJson(Map<String, dynamic> json) =>
      _$ElementCollisionProfileFromJson(json);
}

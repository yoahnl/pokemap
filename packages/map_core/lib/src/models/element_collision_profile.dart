// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'map_data.dart';

part 'element_collision_profile.freezed.dart';
part 'element_collision_profile.g.dart';

@freezed
class ElementCollisionProfile with _$ElementCollisionProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ElementCollisionProfile({
    @Default(ElementCollisionProfileSource.generated)
    ElementCollisionProfileSource source,
    @Default(WarpTriggerPadding()) WarpTriggerPadding padding,
    // Authoring base when `source == manual`.
    //
    // This field is editor-facing only. It stores the main collision shape as
    // authored by the user (for example a lasso/polygon around a building).
    // Runtime still ignores it and consumes only `cells`.
    @Default([]) List<GridPos> shapeCells,
    // Runtime truth: the gameplay/runtime layers only read these final cells.
    // Editor-only concepts such as base cells or paint modes must be resolved
    // before data reaches this field.
    @Default([]) List<GridPos> cells,
    // Authoring intent: cells explicitly added on top of the base shape derived
    // from padding. Keeping this intent lets the editor recompute `cells`
    // deterministically whenever padding changes.
    @Default([]) List<GridPos> manualAddedCells,
    // Authoring intent: cells explicitly removed from the base shape derived
    // from padding. Runtime ignores this field; the editor folds it into
    // `cells` before save/use.
    @Default([]) List<GridPos> manualRemovedCells,
  }) = _ElementCollisionProfile;

  factory ElementCollisionProfile.fromJson(Map<String, dynamic> json) =>
      _$ElementCollisionProfileFromJson(json);
}

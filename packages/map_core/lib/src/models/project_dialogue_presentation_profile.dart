// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_presentation_window_profile.dart';

part 'project_dialogue_presentation_profile.freezed.dart';
part 'project_dialogue_presentation_profile.g.dart';

enum ProjectDialoguePlacement { bottom, top, center }

enum ProjectDialoguePortraitSide { start, end }

enum ProjectDialoguePortraitShape { circle, rounded, square, cutCorner }

enum ProjectDialogueNameplateStyle { inline, badge, floating }

enum ProjectDialogueChoiceShape { rounded, pill, rectangle, cutCorner }

enum ProjectDialogueProgressIndicator { chevron, arrow, dots, none }

enum ProjectDialoguePortraitTransition { none, fade, scale, slide }

const double projectDialogueMinWidthFactor = .4;
const double projectDialogueMaxWidthFactor = .96;
const double projectDialogueMinMargin = 0;
const double projectDialogueMaxMargin = 64;
const double projectDialogueMinContentPadding = 8;
const double projectDialogueMaxContentPadding = 48;
const double projectDialogueMinCornerRadius = 0;
const double projectDialogueMaxCornerRadius = 40;
const double projectDialogueMinBorderWidth = 0;
const double projectDialogueMaxBorderWidth = 8;
const double projectDialogueMinFillOpacity = .4;
const double projectDialogueMaxFillOpacity = 1;
const double projectDialogueMinPortraitSize = 48;
const double projectDialogueMaxPortraitSize = 160;
const double projectDialogueMinPortraitFrameWidth = 0;
const double projectDialogueMaxPortraitFrameWidth = 8;
const double projectDialogueMinNameplateBorderWidth = 0;
const double projectDialogueMaxNameplateBorderWidth = 6;
const double projectDialogueMinChoiceSpacing = 4;
const double projectDialogueMaxChoiceSpacing = 24;
const double projectDialogueMinChoiceDisabledOpacity = .25;
const double projectDialogueMaxChoiceDisabledOpacity = 1;
const int projectDialogueMinPortraitTransitionMilliseconds = 0;
const int projectDialogueMaxPortraitTransitionMilliseconds = 800;

@Freezed(fromJson: true, toJson: true)
abstract class ProjectDialoguePresentationProfile
    with _$ProjectDialoguePresentationProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectDialoguePresentationProfile({
    @Default(ProjectDialoguePlacement.bottom)
    ProjectDialoguePlacement placement,
    @Default(.82) double maxWidthFactor,
    @Default(8) double margin,
    @Default(16) double contentPadding,
    @Default(ProjectWindowShape.rounded) ProjectWindowShape shape,
    @Default(16) double cornerRadius,
    @Default(1) double borderWidth,
    @Default(1) double fillOpacity,
    @JsonKey(includeIfNull: false) String? surfaceColor,
    @JsonKey(includeIfNull: false) String? borderColor,
    @JsonKey(includeIfNull: false) String? textColor,
    @Default(ProjectDialoguePortraitSide.start)
    ProjectDialoguePortraitSide portraitSide,
    @Default(96) double portraitSize,
    @Default(ProjectDialoguePortraitShape.rounded)
    ProjectDialoguePortraitShape portraitShape,
    @Default(1) double portraitFrameWidth,
    @JsonKey(includeIfNull: false) String? portraitFrameColor,
    @Default(ProjectDialogueNameplateStyle.inline)
    ProjectDialogueNameplateStyle nameplateStyle,
    @Default(1) double nameplateBorderWidth,
    @JsonKey(includeIfNull: false) String? nameplateSurfaceColor,
    @JsonKey(includeIfNull: false) String? nameplateBorderColor,
    @JsonKey(includeIfNull: false) String? nameplateTextColor,
    @Default(8) double choiceSpacing,
    @Default(ProjectDialogueChoiceShape.rounded)
    ProjectDialogueChoiceShape choiceShape,
    @Default(.5) double choiceDisabledOpacity,
    @JsonKey(includeIfNull: false) String? choiceSelectedColor,
    @Default(ProjectDialogueProgressIndicator.chevron)
    ProjectDialogueProgressIndicator progressIndicator,
    @JsonKey(includeIfNull: false) String? progressIndicatorColor,
    @Default(ProjectDialoguePortraitTransition.fade)
    ProjectDialoguePortraitTransition portraitTransition,
    @Default(180) int portraitTransitionMilliseconds,
  }) = _ProjectDialoguePresentationProfile;

  factory ProjectDialoguePresentationProfile.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectDialoguePresentationProfileFromJson(json);
}

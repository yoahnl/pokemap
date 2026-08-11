// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_dialogue_presentation_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectDialoguePresentationProfile
_$ProjectDialoguePresentationProfileFromJson(Map<String, dynamic> json) =>
    _ProjectDialoguePresentationProfile(
      placement:
          $enumDecodeNullable(
            _$ProjectDialoguePlacementEnumMap,
            json['placement'],
          ) ??
          ProjectDialoguePlacement.bottom,
      maxWidthFactor: (json['maxWidthFactor'] as num?)?.toDouble() ?? .82,
      margin: (json['margin'] as num?)?.toDouble() ?? 8,
      contentPadding: (json['contentPadding'] as num?)?.toDouble() ?? 16,
      shape:
          $enumDecodeNullable(_$ProjectWindowShapeEnumMap, json['shape']) ??
          ProjectWindowShape.rounded,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 16,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 1,
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 1,
      surfaceColor: json['surfaceColor'] as String?,
      borderColor: json['borderColor'] as String?,
      textColor: json['textColor'] as String?,
      portraitSide:
          $enumDecodeNullable(
            _$ProjectDialoguePortraitSideEnumMap,
            json['portraitSide'],
          ) ??
          ProjectDialoguePortraitSide.start,
      portraitSize: (json['portraitSize'] as num?)?.toDouble() ?? 96,
      portraitShape:
          $enumDecodeNullable(
            _$ProjectDialoguePortraitShapeEnumMap,
            json['portraitShape'],
          ) ??
          ProjectDialoguePortraitShape.rounded,
      portraitFrameWidth: (json['portraitFrameWidth'] as num?)?.toDouble() ?? 1,
      portraitFrameColor: json['portraitFrameColor'] as String?,
      nameplateStyle:
          $enumDecodeNullable(
            _$ProjectDialogueNameplateStyleEnumMap,
            json['nameplateStyle'],
          ) ??
          ProjectDialogueNameplateStyle.inline,
      nameplateBorderWidth:
          (json['nameplateBorderWidth'] as num?)?.toDouble() ?? 1,
      nameplateSurfaceColor: json['nameplateSurfaceColor'] as String?,
      nameplateBorderColor: json['nameplateBorderColor'] as String?,
      nameplateTextColor: json['nameplateTextColor'] as String?,
      choiceSpacing: (json['choiceSpacing'] as num?)?.toDouble() ?? 8,
      choiceShape:
          $enumDecodeNullable(
            _$ProjectDialogueChoiceShapeEnumMap,
            json['choiceShape'],
          ) ??
          ProjectDialogueChoiceShape.rounded,
      choiceDisabledOpacity:
          (json['choiceDisabledOpacity'] as num?)?.toDouble() ?? .5,
      choiceSelectedColor: json['choiceSelectedColor'] as String?,
      progressIndicator:
          $enumDecodeNullable(
            _$ProjectDialogueProgressIndicatorEnumMap,
            json['progressIndicator'],
          ) ??
          ProjectDialogueProgressIndicator.chevron,
      progressIndicatorColor: json['progressIndicatorColor'] as String?,
      portraitTransition:
          $enumDecodeNullable(
            _$ProjectDialoguePortraitTransitionEnumMap,
            json['portraitTransition'],
          ) ??
          ProjectDialoguePortraitTransition.fade,
      portraitTransitionMilliseconds:
          (json['portraitTransitionMilliseconds'] as num?)?.toInt() ?? 180,
    );

Map<String, dynamic> _$ProjectDialoguePresentationProfileToJson(
  _ProjectDialoguePresentationProfile instance,
) => <String, dynamic>{
  'placement': _$ProjectDialoguePlacementEnumMap[instance.placement]!,
  'maxWidthFactor': instance.maxWidthFactor,
  'margin': instance.margin,
  'contentPadding': instance.contentPadding,
  'shape': _$ProjectWindowShapeEnumMap[instance.shape]!,
  'cornerRadius': instance.cornerRadius,
  'borderWidth': instance.borderWidth,
  'fillOpacity': instance.fillOpacity,
  'surfaceColor': ?instance.surfaceColor,
  'borderColor': ?instance.borderColor,
  'textColor': ?instance.textColor,
  'portraitSide': _$ProjectDialoguePortraitSideEnumMap[instance.portraitSide]!,
  'portraitSize': instance.portraitSize,
  'portraitShape':
      _$ProjectDialoguePortraitShapeEnumMap[instance.portraitShape]!,
  'portraitFrameWidth': instance.portraitFrameWidth,
  'portraitFrameColor': ?instance.portraitFrameColor,
  'nameplateStyle':
      _$ProjectDialogueNameplateStyleEnumMap[instance.nameplateStyle]!,
  'nameplateBorderWidth': instance.nameplateBorderWidth,
  'nameplateSurfaceColor': ?instance.nameplateSurfaceColor,
  'nameplateBorderColor': ?instance.nameplateBorderColor,
  'nameplateTextColor': ?instance.nameplateTextColor,
  'choiceSpacing': instance.choiceSpacing,
  'choiceShape': _$ProjectDialogueChoiceShapeEnumMap[instance.choiceShape]!,
  'choiceDisabledOpacity': instance.choiceDisabledOpacity,
  'choiceSelectedColor': ?instance.choiceSelectedColor,
  'progressIndicator':
      _$ProjectDialogueProgressIndicatorEnumMap[instance.progressIndicator]!,
  'progressIndicatorColor': ?instance.progressIndicatorColor,
  'portraitTransition':
      _$ProjectDialoguePortraitTransitionEnumMap[instance.portraitTransition]!,
  'portraitTransitionMilliseconds': instance.portraitTransitionMilliseconds,
};

const _$ProjectDialoguePlacementEnumMap = {
  ProjectDialoguePlacement.bottom: 'bottom',
  ProjectDialoguePlacement.top: 'top',
  ProjectDialoguePlacement.center: 'center',
};

const _$ProjectWindowShapeEnumMap = {
  ProjectWindowShape.rectangle: 'rectangle',
  ProjectWindowShape.rounded: 'rounded',
  ProjectWindowShape.capsule: 'capsule',
  ProjectWindowShape.cutCorner: 'cutCorner',
  ProjectWindowShape.speech: 'speech',
};

const _$ProjectDialoguePortraitSideEnumMap = {
  ProjectDialoguePortraitSide.start: 'start',
  ProjectDialoguePortraitSide.end: 'end',
};

const _$ProjectDialoguePortraitShapeEnumMap = {
  ProjectDialoguePortraitShape.circle: 'circle',
  ProjectDialoguePortraitShape.rounded: 'rounded',
  ProjectDialoguePortraitShape.square: 'square',
  ProjectDialoguePortraitShape.cutCorner: 'cutCorner',
};

const _$ProjectDialogueNameplateStyleEnumMap = {
  ProjectDialogueNameplateStyle.inline: 'inline',
  ProjectDialogueNameplateStyle.badge: 'badge',
  ProjectDialogueNameplateStyle.floating: 'floating',
};

const _$ProjectDialogueChoiceShapeEnumMap = {
  ProjectDialogueChoiceShape.rounded: 'rounded',
  ProjectDialogueChoiceShape.pill: 'pill',
  ProjectDialogueChoiceShape.rectangle: 'rectangle',
  ProjectDialogueChoiceShape.cutCorner: 'cutCorner',
};

const _$ProjectDialogueProgressIndicatorEnumMap = {
  ProjectDialogueProgressIndicator.chevron: 'chevron',
  ProjectDialogueProgressIndicator.arrow: 'arrow',
  ProjectDialogueProgressIndicator.dots: 'dots',
  ProjectDialogueProgressIndicator.none: 'none',
};

const _$ProjectDialoguePortraitTransitionEnumMap = {
  ProjectDialoguePortraitTransition.none: 'none',
  ProjectDialoguePortraitTransition.fade: 'fade',
  ProjectDialoguePortraitTransition.scale: 'scale',
  ProjectDialoguePortraitTransition.slide: 'slide',
};

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

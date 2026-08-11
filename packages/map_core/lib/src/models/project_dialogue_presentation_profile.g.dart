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

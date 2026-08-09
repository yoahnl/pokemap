// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_presentation_window_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectWindowStyleProfile _$ProjectWindowStyleProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectWindowStyleProfile(
  id: json['id'] as String,
  fillToken: json['fillToken'] as String,
  borderToken: json['borderToken'] as String,
  borderWidth: (json['borderWidth'] as num).toInt(),
  cornerRadius: (json['cornerRadius'] as num).toInt(),
  contentPadding: (json['contentPadding'] as num).toInt(),
  shadowElevation: (json['shadowElevation'] as num).toInt(),
);

Map<String, dynamic> _$ProjectWindowStyleProfileToJson(
  _ProjectWindowStyleProfile instance,
) => <String, dynamic>{
  'id': instance.id,
  'fillToken': instance.fillToken,
  'borderToken': instance.borderToken,
  'borderWidth': instance.borderWidth,
  'cornerRadius': instance.cornerRadius,
  'contentPadding': instance.contentPadding,
  'shadowElevation': instance.shadowElevation,
};

_ProjectPresentationWindowsProfile _$ProjectPresentationWindowsProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectPresentationWindowsProfile(
  styles: (json['styles'] as List<dynamic>)
      .map((e) => ProjectWindowStyleProfile.fromJson(e as Map<String, dynamic>))
      .toList(),
  defaultStyleId: json['defaultStyleId'] as String,
  pauseMenuStyleId: json['pauseMenuStyleId'] as String,
  dialogueStyleId: json['dialogueStyleId'] as String,
  pauseBackdropOpacity: (json['pauseBackdropOpacity'] as num).toDouble(),
);

Map<String, dynamic> _$ProjectPresentationWindowsProfileToJson(
  _ProjectPresentationWindowsProfile instance,
) => <String, dynamic>{
  'styles': instance.styles.map((e) => e.toJson()).toList(),
  'defaultStyleId': instance.defaultStyleId,
  'pauseMenuStyleId': instance.pauseMenuStyleId,
  'dialogueStyleId': instance.dialogueStyleId,
  'pauseBackdropOpacity': instance.pauseBackdropOpacity,
};

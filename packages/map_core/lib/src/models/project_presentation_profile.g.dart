// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_presentation_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectBrandingProfileImpl _$$ProjectBrandingProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectBrandingProfileImpl(
      iconPath: json['iconPath'] as String?,
      coverPath: json['coverPath'] as String?,
      heroPath: json['heroPath'] as String?,
      accentColor: json['accentColor'] as String?,
      titleMusicPath: json['titleMusicPath'] as String?,
      layoutVariant: json['layoutVariant'] as String? ?? 'standard',
    );

Map<String, dynamic> _$$ProjectBrandingProfileImplToJson(
        _$ProjectBrandingProfileImpl instance) =>
    <String, dynamic>{
      if (instance.iconPath case final value?) 'iconPath': value,
      if (instance.coverPath case final value?) 'coverPath': value,
      if (instance.heroPath case final value?) 'heroPath': value,
      if (instance.accentColor case final value?) 'accentColor': value,
      if (instance.titleMusicPath case final value?) 'titleMusicPath': value,
      'layoutVariant': instance.layoutVariant,
    };

_$ProjectPresentationProfileImpl _$$ProjectPresentationProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectPresentationProfileImpl(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ??
          ProjectPresentationProfile.supportedSchemaVersion,
      branding: json['branding'] == null
          ? const ProjectBrandingProfile()
          : ProjectBrandingProfile.fromJson(
              json['branding'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProjectPresentationProfileImplToJson(
        _$ProjectPresentationProfileImpl instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'branding': instance.branding.toJson(),
    };

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

_$ProjectIntroVideoProfileImpl _$$ProjectIntroVideoProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectIntroVideoProfileImpl(
      videoPath: json['videoPath'] as String,
      posterPath: json['posterPath'] as String?,
      captionsPath: json['captionsPath'] as String?,
      durationMilliseconds: (json['durationMilliseconds'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      bitrateKbps: (json['bitrateKbps'] as num).toInt(),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      videoCodec: json['videoCodec'] as String,
      audioCodec: json['audioCodec'] as String? ?? 'none',
      reducedMotionBehavior:
          json['reducedMotionBehavior'] as String? ?? 'poster',
      allowReplay: json['allowReplay'] as bool? ?? true,
    );

Map<String, dynamic> _$$ProjectIntroVideoProfileImplToJson(
        _$ProjectIntroVideoProfileImpl instance) =>
    <String, dynamic>{
      'videoPath': instance.videoPath,
      if (instance.posterPath case final value?) 'posterPath': value,
      if (instance.captionsPath case final value?) 'captionsPath': value,
      'durationMilliseconds': instance.durationMilliseconds,
      'width': instance.width,
      'height': instance.height,
      'bitrateKbps': instance.bitrateKbps,
      'sizeBytes': instance.sizeBytes,
      'videoCodec': instance.videoCodec,
      'audioCodec': instance.audioCodec,
      'reducedMotionBehavior': instance.reducedMotionBehavior,
      'allowReplay': instance.allowReplay,
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
      intro: json['intro'] == null
          ? null
          : ProjectIntroVideoProfile.fromJson(
              json['intro'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProjectPresentationProfileImplToJson(
        _$ProjectPresentationProfileImpl instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'branding': instance.branding.toJson(),
      if (instance.intro?.toJson() case final value?) 'intro': value,
    };

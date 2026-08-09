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

_$ProjectVideoVariantProfileImpl _$$ProjectVideoVariantProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectVideoVariantProfileImpl(
      videoPath: json['videoPath'] as String,
      posterPath: json['posterPath'] as String,
      captionsPath: json['captionsPath'] as String?,
      durationMilliseconds: (json['durationMilliseconds'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      bitrateKbps: (json['bitrateKbps'] as num).toInt(),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      videoCodec: json['videoCodec'] as String,
      audioCodec: json['audioCodec'] as String? ?? 'none',
      focalX: (json['focalX'] as num?)?.toDouble() ?? 0.5,
      focalY: (json['focalY'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$$ProjectVideoVariantProfileImplToJson(
        _$ProjectVideoVariantProfileImpl instance) =>
    <String, dynamic>{
      'videoPath': instance.videoPath,
      'posterPath': instance.posterPath,
      if (instance.captionsPath case final value?) 'captionsPath': value,
      'durationMilliseconds': instance.durationMilliseconds,
      'width': instance.width,
      'height': instance.height,
      'bitrateKbps': instance.bitrateKbps,
      'sizeBytes': instance.sizeBytes,
      'videoCodec': instance.videoCodec,
      'audioCodec': instance.audioCodec,
      'focalX': instance.focalX,
      'focalY': instance.focalY,
    };

_$ProjectResponsiveVideoProfileImpl
    _$$ProjectResponsiveVideoProfileImplFromJson(Map<String, dynamic> json) =>
        _$ProjectResponsiveVideoProfileImpl(
          landscape: ProjectVideoVariantProfile.fromJson(
              json['landscape'] as Map<String, dynamic>),
          portrait: json['portrait'] == null
              ? null
              : ProjectVideoVariantProfile.fromJson(
                  json['portrait'] as Map<String, dynamic>),
        );

Map<String, dynamic> _$$ProjectResponsiveVideoProfileImplToJson(
        _$ProjectResponsiveVideoProfileImpl instance) =>
    <String, dynamic>{
      'landscape': instance.landscape.toJson(),
      if (instance.portrait?.toJson() case final value?) 'portrait': value,
    };

_$ProjectIntroVideoProfileImpl _$$ProjectIntroVideoProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectIntroVideoProfileImpl(
      media: ProjectResponsiveVideoProfile.fromJson(
          json['media'] as Map<String, dynamic>),
      reducedMotionBehavior:
          json['reducedMotionBehavior'] as String? ?? 'poster',
      allowReplay: json['allowReplay'] as bool? ?? true,
    );

Map<String, dynamic> _$$ProjectIntroVideoProfileImplToJson(
        _$ProjectIntroVideoProfileImpl instance) =>
    <String, dynamic>{
      'media': instance.media.toJson(),
      'reducedMotionBehavior': instance.reducedMotionBehavior,
      'allowReplay': instance.allowReplay,
    };

_$ProjectTitleMotionProfileImpl _$$ProjectTitleMotionProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTitleMotionProfileImpl(
      promptLoop: json['promptLoop'] == null
          ? null
          : ProjectResponsiveVideoProfile.fromJson(
              json['promptLoop'] as Map<String, dynamic>),
      menuLoop: json['menuLoop'] == null
          ? null
          : ProjectResponsiveVideoProfile.fromJson(
              json['menuLoop'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProjectTitleMotionProfileImplToJson(
        _$ProjectTitleMotionProfileImpl instance) =>
    <String, dynamic>{
      if (instance.promptLoop?.toJson() case final value?) 'promptLoop': value,
      if (instance.menuLoop?.toJson() case final value?) 'menuLoop': value,
    };

_$ProjectTypographyRoleProfileImpl _$$ProjectTypographyRoleProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTypographyRoleProfileImpl(
      fontPath: json['fontPath'] as String?,
      family: json['family'] as String?,
      licensePath: json['licensePath'] as String?,
      redistributable: json['redistributable'] as bool? ?? false,
      fallbackFamilies: (json['fallbackFamilies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>['sans-serif'],
      glyphCoverage: (json['glyphCoverage'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$ProjectTypographyRoleProfileImplToJson(
        _$ProjectTypographyRoleProfileImpl instance) =>
    <String, dynamic>{
      if (instance.fontPath case final value?) 'fontPath': value,
      if (instance.family case final value?) 'family': value,
      if (instance.licensePath case final value?) 'licensePath': value,
      'redistributable': instance.redistributable,
      'fallbackFamilies': instance.fallbackFamilies,
      'glyphCoverage': instance.glyphCoverage,
    };

_$ProjectTypographyProfileImpl _$$ProjectTypographyProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTypographyProfileImpl(
      display: json['display'] == null
          ? const ProjectTypographyRoleProfile()
          : ProjectTypographyRoleProfile.fromJson(
              json['display'] as Map<String, dynamic>),
      body: json['body'] == null
          ? const ProjectTypographyRoleProfile()
          : ProjectTypographyRoleProfile.fromJson(
              json['body'] as Map<String, dynamic>),
      dialogue: json['dialogue'] == null
          ? const ProjectTypographyRoleProfile()
          : ProjectTypographyRoleProfile.fromJson(
              json['dialogue'] as Map<String, dynamic>),
      numbers: json['numbers'] == null
          ? const ProjectTypographyRoleProfile()
          : ProjectTypographyRoleProfile.fromJson(
              json['numbers'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProjectTypographyProfileImplToJson(
        _$ProjectTypographyProfileImpl instance) =>
    <String, dynamic>{
      'display': instance.display.toJson(),
      'body': instance.body.toJson(),
      'dialogue': instance.dialogue.toJson(),
      'numbers': instance.numbers.toJson(),
    };

_$ProjectSemanticThemeProfileImpl _$$ProjectSemanticThemeProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectSemanticThemeProfileImpl(
      primary: json['primary'] as String,
      onPrimary: json['onPrimary'] as String,
      background: json['background'] as String,
      surface: json['surface'] as String,
      surfaceElevated: json['surfaceElevated'] as String,
      textPrimary: json['textPrimary'] as String,
      textSecondary: json['textSecondary'] as String,
      outline: json['outline'] as String,
      success: json['success'] as String,
      warning: json['warning'] as String,
      danger: json['danger'] as String,
      titleSurface: json['titleSurface'] as String,
      dialogueSurface: json['dialogueSurface'] as String,
      menuSurface: json['menuSurface'] as String,
      overworldHudSurface: json['overworldHudSurface'] as String,
      battleHudSurface: json['battleHudSurface'] as String,
    );

Map<String, dynamic> _$$ProjectSemanticThemeProfileImplToJson(
        _$ProjectSemanticThemeProfileImpl instance) =>
    <String, dynamic>{
      'primary': instance.primary,
      'onPrimary': instance.onPrimary,
      'background': instance.background,
      'surface': instance.surface,
      'surfaceElevated': instance.surfaceElevated,
      'textPrimary': instance.textPrimary,
      'textSecondary': instance.textSecondary,
      'outline': instance.outline,
      'success': instance.success,
      'warning': instance.warning,
      'danger': instance.danger,
      'titleSurface': instance.titleSurface,
      'dialogueSurface': instance.dialogueSurface,
      'menuSurface': instance.menuSurface,
      'overworldHudSurface': instance.overworldHudSurface,
      'battleHudSurface': instance.battleHudSurface,
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
      titleMotion: json['titleMotion'] == null
          ? null
          : ProjectTitleMotionProfile.fromJson(
              json['titleMotion'] as Map<String, dynamic>),
      typography: json['typography'] == null
          ? null
          : ProjectTypographyProfile.fromJson(
              json['typography'] as Map<String, dynamic>),
      theme: json['theme'] == null
          ? null
          : ProjectSemanticThemeProfile.fromJson(
              json['theme'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProjectPresentationProfileImplToJson(
        _$ProjectPresentationProfileImpl instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'branding': instance.branding.toJson(),
      if (instance.intro?.toJson() case final value?) 'intro': value,
      if (instance.titleMotion?.toJson() case final value?)
        'titleMotion': value,
      if (instance.typography?.toJson() case final value?) 'typography': value,
      if (instance.theme?.toJson() case final value?) 'theme': value,
    };

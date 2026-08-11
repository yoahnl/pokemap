// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_presentation_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectBrandingProfile _$ProjectBrandingProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectBrandingProfile(
  iconPath: json['iconPath'] as String?,
  coverPath: json['coverPath'] as String?,
  heroPath: json['heroPath'] as String?,
  accentColor: json['accentColor'] as String?,
  titleMusicPath: json['titleMusicPath'] as String?,
  layoutVariant: json['layoutVariant'] as String? ?? 'standard',
);

Map<String, dynamic> _$ProjectBrandingProfileToJson(
  _ProjectBrandingProfile instance,
) => <String, dynamic>{
  'iconPath': ?instance.iconPath,
  'coverPath': ?instance.coverPath,
  'heroPath': ?instance.heroPath,
  'accentColor': ?instance.accentColor,
  'titleMusicPath': ?instance.titleMusicPath,
  'layoutVariant': instance.layoutVariant,
};

_ProjectVideoVariantProfile _$ProjectVideoVariantProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectVideoVariantProfile(
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

Map<String, dynamic> _$ProjectVideoVariantProfileToJson(
  _ProjectVideoVariantProfile instance,
) => <String, dynamic>{
  'videoPath': instance.videoPath,
  'posterPath': instance.posterPath,
  'captionsPath': ?instance.captionsPath,
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

_ProjectResponsiveVideoProfile _$ProjectResponsiveVideoProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectResponsiveVideoProfile(
  landscape: ProjectVideoVariantProfile.fromJson(
    json['landscape'] as Map<String, dynamic>,
  ),
  portrait: json['portrait'] == null
      ? null
      : ProjectVideoVariantProfile.fromJson(
          json['portrait'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectResponsiveVideoProfileToJson(
  _ProjectResponsiveVideoProfile instance,
) => <String, dynamic>{
  'landscape': instance.landscape.toJson(),
  'portrait': ?instance.portrait?.toJson(),
};

_ProjectIntroVideoProfile _$ProjectIntroVideoProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectIntroVideoProfile(
  media: ProjectResponsiveVideoProfile.fromJson(
    json['media'] as Map<String, dynamic>,
  ),
  reducedMotionBehavior: json['reducedMotionBehavior'] as String? ?? 'poster',
  allowReplay: json['allowReplay'] as bool? ?? true,
);

Map<String, dynamic> _$ProjectIntroVideoProfileToJson(
  _ProjectIntroVideoProfile instance,
) => <String, dynamic>{
  'media': instance.media.toJson(),
  'reducedMotionBehavior': instance.reducedMotionBehavior,
  'allowReplay': instance.allowReplay,
};

_ProjectTitleMotionProfile _$ProjectTitleMotionProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTitleMotionProfile(
  promptLoop: json['promptLoop'] == null
      ? null
      : ProjectResponsiveVideoProfile.fromJson(
          json['promptLoop'] as Map<String, dynamic>,
        ),
  menuLoop: json['menuLoop'] == null
      ? null
      : ProjectResponsiveVideoProfile.fromJson(
          json['menuLoop'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectTitleMotionProfileToJson(
  _ProjectTitleMotionProfile instance,
) => <String, dynamic>{
  'promptLoop': ?instance.promptLoop?.toJson(),
  'menuLoop': ?instance.menuLoop?.toJson(),
};

_ProjectTypographyRoleProfile _$ProjectTypographyRoleProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTypographyRoleProfile(
  fontPath: json['fontPath'] as String?,
  family: json['family'] as String?,
  licensePath: json['licensePath'] as String?,
  redistributable: json['redistributable'] as bool? ?? false,
  fallbackFamilies:
      (json['fallbackFamilies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>['sans-serif'],
  glyphCoverage:
      (json['glyphCoverage'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  metrics: json['metrics'] == null
      ? null
      : ProjectTypographyMetricsProfile.fromJson(
          json['metrics'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectTypographyRoleProfileToJson(
  _ProjectTypographyRoleProfile instance,
) => <String, dynamic>{
  'fontPath': ?instance.fontPath,
  'family': ?instance.family,
  'licensePath': ?instance.licensePath,
  'redistributable': instance.redistributable,
  'fallbackFamilies': instance.fallbackFamilies,
  'glyphCoverage': instance.glyphCoverage,
  'metrics': ?instance.metrics?.toJson(),
};

_ProjectTypographyProfile _$ProjectTypographyProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTypographyProfile(
  display: json['display'] == null
      ? const ProjectTypographyRoleProfile()
      : ProjectTypographyRoleProfile.fromJson(
          json['display'] as Map<String, dynamic>,
        ),
  body: json['body'] == null
      ? const ProjectTypographyRoleProfile()
      : ProjectTypographyRoleProfile.fromJson(
          json['body'] as Map<String, dynamic>,
        ),
  dialogue: json['dialogue'] == null
      ? const ProjectTypographyRoleProfile()
      : ProjectTypographyRoleProfile.fromJson(
          json['dialogue'] as Map<String, dynamic>,
        ),
  numbers: json['numbers'] == null
      ? const ProjectTypographyRoleProfile()
      : ProjectTypographyRoleProfile.fromJson(
          json['numbers'] as Map<String, dynamic>,
        ),
  combat: json['combat'] == null
      ? null
      : ProjectTypographyRoleProfile.fromJson(
          json['combat'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectTypographyProfileToJson(
  _ProjectTypographyProfile instance,
) => <String, dynamic>{
  'display': instance.display.toJson(),
  'body': instance.body.toJson(),
  'dialogue': instance.dialogue.toJson(),
  'numbers': instance.numbers.toJson(),
  'combat': ?instance.combat?.toJson(),
};

_ProjectSemanticThemeProfile _$ProjectSemanticThemeProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectSemanticThemeProfile(
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

Map<String, dynamic> _$ProjectSemanticThemeProfileToJson(
  _ProjectSemanticThemeProfile instance,
) => <String, dynamic>{
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

_ProjectMenuLabelsProfile _$ProjectMenuLabelsProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectMenuLabelsProfile(
  pauseTitle: json['pauseTitle'] as String?,
  resume: json['resume'] as String?,
  party: json['party'] as String?,
  bag: json['bag'] as String?,
  pokedex: json['pokedex'] as String?,
  map: json['map'] as String?,
  save: json['save'] as String?,
  options: json['options'] as String?,
  returnToTitle: json['returnToTitle'] as String?,
);

Map<String, dynamic> _$ProjectMenuLabelsProfileToJson(
  _ProjectMenuLabelsProfile instance,
) => <String, dynamic>{
  'pauseTitle': ?instance.pauseTitle,
  'resume': ?instance.resume,
  'party': ?instance.party,
  'bag': ?instance.bag,
  'pokedex': ?instance.pokedex,
  'map': ?instance.map,
  'save': ?instance.save,
  'options': ?instance.options,
  'returnToTitle': ?instance.returnToTitle,
};

_ProjectPresentationProfile _$ProjectPresentationProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectPresentationProfile(
  schemaVersion:
      (json['schemaVersion'] as num?)?.toInt() ??
      ProjectPresentationProfile.supportedSchemaVersion,
  branding: json['branding'] == null
      ? const ProjectBrandingProfile()
      : ProjectBrandingProfile.fromJson(
          json['branding'] as Map<String, dynamic>,
        ),
  intro: json['intro'] == null
      ? null
      : ProjectIntroVideoProfile.fromJson(
          json['intro'] as Map<String, dynamic>,
        ),
  titleMotion: json['titleMotion'] == null
      ? null
      : ProjectTitleMotionProfile.fromJson(
          json['titleMotion'] as Map<String, dynamic>,
        ),
  typography: json['typography'] == null
      ? null
      : ProjectTypographyProfile.fromJson(
          json['typography'] as Map<String, dynamic>,
        ),
  theme: json['theme'] == null
      ? null
      : ProjectSemanticThemeProfile.fromJson(
          json['theme'] as Map<String, dynamic>,
        ),
  surfacePalettes: json['surfacePalettes'] == null
      ? null
      : ProjectPresentationSurfacePalettesProfile.fromJson(
          json['surfacePalettes'] as Map<String, dynamic>,
        ),
  menuLabels: json['menuLabels'] == null
      ? null
      : ProjectMenuLabelsProfile.fromJson(
          json['menuLabels'] as Map<String, dynamic>,
        ),
  windows: json['windows'] == null
      ? null
      : ProjectPresentationWindowsProfile.fromJson(
          json['windows'] as Map<String, dynamic>,
        ),
  layouts: json['layouts'] == null
      ? null
      : ProjectPresentationLayoutsProfile.fromJson(
          json['layouts'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectPresentationProfileToJson(
  _ProjectPresentationProfile instance,
) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'branding': instance.branding.toJson(),
  'intro': ?instance.intro?.toJson(),
  'titleMotion': ?instance.titleMotion?.toJson(),
  'typography': ?instance.typography?.toJson(),
  'theme': ?instance.theme?.toJson(),
  'surfacePalettes': ?instance.surfacePalettes?.toJson(),
  'menuLabels': ?instance.menuLabels?.toJson(),
  'windows': ?instance.windows?.toJson(),
  'layouts': ?instance.layouts?.toJson(),
};

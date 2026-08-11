// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_presentation_visual_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectTypographyMetricsProfile _$ProjectTypographyMetricsProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTypographyMetricsProfile(
  sizeScale: (json['sizeScale'] as num?)?.toDouble() ?? 1,
  weight: (json['weight'] as num?)?.toInt() ?? 400,
  lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.25,
  letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$ProjectTypographyMetricsProfileToJson(
  _ProjectTypographyMetricsProfile instance,
) => <String, dynamic>{
  'sizeScale': instance.sizeScale,
  'weight': instance.weight,
  'lineHeight': instance.lineHeight,
  'letterSpacing': instance.letterSpacing,
};

_ProjectSurfacePaletteProfile _$ProjectSurfacePaletteProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectSurfacePaletteProfile(
  background: json['background'] as String?,
  surface: json['surface'] as String?,
  border: json['border'] as String?,
  text: json['text'] as String?,
  accent: json['accent'] as String?,
  selection: json['selection'] as String?,
);

Map<String, dynamic> _$ProjectSurfacePaletteProfileToJson(
  _ProjectSurfacePaletteProfile instance,
) => <String, dynamic>{
  'background': ?instance.background,
  'surface': ?instance.surface,
  'border': ?instance.border,
  'text': ?instance.text,
  'accent': ?instance.accent,
  'selection': ?instance.selection,
};

_ProjectPresentationSurfacePalettesProfile
_$ProjectPresentationSurfacePalettesProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectPresentationSurfacePalettesProfile(
  title: json['title'] == null
      ? null
      : ProjectSurfacePaletteProfile.fromJson(
          json['title'] as Map<String, dynamic>,
        ),
  pauseMenu: json['pauseMenu'] == null
      ? null
      : ProjectSurfacePaletteProfile.fromJson(
          json['pauseMenu'] as Map<String, dynamic>,
        ),
  dialogue: json['dialogue'] == null
      ? null
      : ProjectSurfacePaletteProfile.fromJson(
          json['dialogue'] as Map<String, dynamic>,
        ),
  battle: json['battle'] == null
      ? null
      : ProjectSurfacePaletteProfile.fromJson(
          json['battle'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectPresentationSurfacePalettesProfileToJson(
  _ProjectPresentationSurfacePalettesProfile instance,
) => <String, dynamic>{
  'title': ?instance.title?.toJson(),
  'pauseMenu': ?instance.pauseMenu?.toJson(),
  'dialogue': ?instance.dialogue?.toJson(),
  'battle': ?instance.battle?.toJson(),
};

// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_presentation_surface_role.dart';

part 'project_presentation_visual_profile.freezed.dart';
part 'project_presentation_visual_profile.g.dart';

@Freezed(fromJson: true, toJson: true)
abstract class ProjectTypographyMetricsProfile
    with _$ProjectTypographyMetricsProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTypographyMetricsProfile({
    @Default(1) double sizeScale,
    @Default(400) int weight,
    @Default(1.25) double lineHeight,
    @Default(0) double letterSpacing,
  }) = _ProjectTypographyMetricsProfile;

  factory ProjectTypographyMetricsProfile.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectTypographyMetricsProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectSurfacePaletteProfile
    with _$ProjectSurfacePaletteProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSurfacePaletteProfile({
    @JsonKey(includeIfNull: false) String? background,
    @JsonKey(includeIfNull: false) String? surface,
    @JsonKey(includeIfNull: false) String? border,
    @JsonKey(includeIfNull: false) String? text,
    @JsonKey(includeIfNull: false) String? accent,
    @JsonKey(includeIfNull: false) String? selection,
  }) = _ProjectSurfacePaletteProfile;

  factory ProjectSurfacePaletteProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectSurfacePaletteProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectPresentationSurfacePalettesProfile
    with _$ProjectPresentationSurfacePalettesProfile {
  const ProjectPresentationSurfacePalettesProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectPresentationSurfacePalettesProfile({
    @JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? title,
    @JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? pauseMenu,
    @JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? dialogue,
    @JsonKey(includeIfNull: false) ProjectSurfacePaletteProfile? battle,
  }) = _ProjectPresentationSurfacePalettesProfile;

  factory ProjectPresentationSurfacePalettesProfile.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectPresentationSurfacePalettesProfileFromJson(json);

  ProjectSurfacePaletteProfile? resolve(
    ProjectPresentationSurfaceRole role,
  ) => switch (role) {
    ProjectPresentationSurfaceRole.title ||
    ProjectPresentationSurfaceRole.titlePrompt ||
    ProjectPresentationSurfaceRole.credits => title,
    ProjectPresentationSurfaceRole.pauseMenu ||
    ProjectPresentationSurfaceRole.party ||
    ProjectPresentationSurfaceRole.bag ||
    ProjectPresentationSurfaceRole.pokedex ||
    ProjectPresentationSurfaceRole.map ||
    ProjectPresentationSurfaceRole.save ||
    ProjectPresentationSurfaceRole.options ||
    ProjectPresentationSurfaceRole.confirmation => pauseMenu,
    ProjectPresentationSurfaceRole.dialogue => dialogue,
    ProjectPresentationSurfaceRole.battleHud ||
    ProjectPresentationSurfaceRole.battleResult ||
    ProjectPresentationSurfaceRole.captureResult => battle,
    ProjectPresentationSurfaceRole.notification ||
    ProjectPresentationSurfaceRole.overworldHud => null,
  };
}

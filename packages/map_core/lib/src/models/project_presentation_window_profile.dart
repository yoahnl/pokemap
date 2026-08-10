// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_presentation_window_profile.freezed.dart';
part 'project_presentation_window_profile.g.dart';

enum ProjectWindowRole { standard, pauseMenu, dialogue, battle }

@Freezed(fromJson: true, toJson: true)
abstract class ProjectWindowStyleProfile with _$ProjectWindowStyleProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectWindowStyleProfile({
    required String id,
    required String fillToken,
    required String borderToken,
    required int borderWidth,
    required int cornerRadius,
    required int contentPadding,
    required int shadowElevation,
  }) = _ProjectWindowStyleProfile;

  factory ProjectWindowStyleProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectWindowStyleProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectPresentationWindowsProfile
    with _$ProjectPresentationWindowsProfile {
  const ProjectPresentationWindowsProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectPresentationWindowsProfile({
    required List<ProjectWindowStyleProfile> styles,
    required String defaultStyleId,
    required String pauseMenuStyleId,
    required String dialogueStyleId,
    @JsonKey(includeIfNull: false) String? battleStyleId,
    required double pauseBackdropOpacity,
  }) = _ProjectPresentationWindowsProfile;

  factory ProjectPresentationWindowsProfile.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectPresentationWindowsProfileFromJson(json);

  ProjectWindowStyleProfile resolve(ProjectWindowRole role) {
    final styleId = switch (role) {
      ProjectWindowRole.standard => defaultStyleId,
      ProjectWindowRole.pauseMenu => pauseMenuStyleId,
      ProjectWindowRole.dialogue => dialogueStyleId,
      ProjectWindowRole.battle => battleStyleId ?? defaultStyleId,
    };
    return styles.singleWhere((style) => style.id == styleId);
  }
}

const supportedProjectWindowFillTokens = <String>{
  'surface',
  'surfaceElevated',
  'titleSurface',
  'dialogueSurface',
  'menuSurface',
  'overworldHudSurface',
  'battleHudSurface',
};

const supportedProjectWindowBorderTokens = <String>{
  'outline',
  'primary',
  'success',
  'warning',
  'danger',
};

const int projectWindowMinBorderWidth = 0;
const int projectWindowMaxBorderWidth = 4;
const int projectWindowMinCornerRadius = 0;
const int projectWindowMaxCornerRadius = 32;
const int projectWindowMinContentPadding = 8;
const int projectWindowMaxContentPadding = 32;
const int projectWindowMinShadowElevation = 0;
const int projectWindowMaxShadowElevation = 16;
const double projectWindowMinBackdropOpacity = .35;
const double projectWindowMaxBackdropOpacity = .9;

const legacyProjectPresentationWindows = ProjectPresentationWindowsProfile(
  styles: <ProjectWindowStyleProfile>[
    ProjectWindowStyleProfile(
      id: 'default',
      fillToken: 'surface',
      borderToken: 'outline',
      borderWidth: 1,
      cornerRadius: 16,
      contentPadding: 24,
      shadowElevation: 8,
    ),
    ProjectWindowStyleProfile(
      id: 'pause-menu',
      fillToken: 'menuSurface',
      borderToken: 'outline',
      borderWidth: 1,
      cornerRadius: 16,
      contentPadding: 24,
      shadowElevation: 8,
    ),
    ProjectWindowStyleProfile(
      id: 'dialogue',
      fillToken: 'dialogueSurface',
      borderToken: 'outline',
      borderWidth: 1,
      cornerRadius: 16,
      contentPadding: 16,
      shadowElevation: 8,
    ),
  ],
  defaultStyleId: 'default',
  pauseMenuStyleId: 'pause-menu',
  dialogueStyleId: 'dialogue',
  pauseBackdropOpacity: .7,
);

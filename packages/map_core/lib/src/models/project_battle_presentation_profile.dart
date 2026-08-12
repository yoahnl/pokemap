import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_presentation_window_profile.dart';

part 'project_battle_presentation_profile.freezed.dart';
part 'project_battle_presentation_profile.g.dart';

enum ProjectBattleCommandLayout { grid, list, radial }

enum ProjectBattleCommandId { fight, bag, party, run }

enum ProjectBattleCommandIcon { fight, bag, party, run }

enum ProjectBattleHpBarShape { flat, rounded, segmented }

enum ProjectBattleHudPosition { topStart, topEnd, bottomStart, bottomEnd }

@Freezed(fromJson: true, toJson: true)
abstract class ProjectBattleCommandProfile with _$ProjectBattleCommandProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectBattleCommandProfile({
    required ProjectBattleCommandId id,
    @JsonKey(includeIfNull: false) String? label,
    @JsonKey(includeIfNull: false) ProjectBattleCommandIcon? icon,
  }) = _ProjectBattleCommandProfile;

  factory ProjectBattleCommandProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectBattleCommandProfileFromJson(json);
}

const List<ProjectBattleCommandProfile> defaultProjectBattleCommands =
    <ProjectBattleCommandProfile>[
      ProjectBattleCommandProfile(
        id: ProjectBattleCommandId.fight,
        icon: ProjectBattleCommandIcon.fight,
      ),
      ProjectBattleCommandProfile(
        id: ProjectBattleCommandId.bag,
        icon: ProjectBattleCommandIcon.bag,
      ),
      ProjectBattleCommandProfile(
        id: ProjectBattleCommandId.party,
        icon: ProjectBattleCommandIcon.party,
      ),
      ProjectBattleCommandProfile(
        id: ProjectBattleCommandId.run,
        icon: ProjectBattleCommandIcon.run,
      ),
    ];

@Freezed(fromJson: true, toJson: true)
abstract class ProjectBattlePanelPresentationProfile
    with _$ProjectBattlePanelPresentationProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectBattlePanelPresentationProfile({
    @Default(ProjectBattleCommandLayout.grid) ProjectBattleCommandLayout layout,
    @Default(2) int columns,
    @Default(ProjectWindowShape.rounded) ProjectWindowShape shape,
    @Default(12) double padding,
    @JsonKey(includeIfNull: false) String? surfaceColor,
    @JsonKey(includeIfNull: false) String? borderColor,
    @JsonKey(includeIfNull: false) String? textColor,
    @JsonKey(includeIfNull: false) String? selectionColor,
  }) = _ProjectBattlePanelPresentationProfile;

  factory ProjectBattlePanelPresentationProfile.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectBattlePanelPresentationProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectBattlePresentationProfile
    with _$ProjectBattlePresentationProfile {
  const ProjectBattlePresentationProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectBattlePresentationProfile({
    @Default(ProjectBattleCommandLayout.grid)
    ProjectBattleCommandLayout commandLayout,
    @Default(2) int commandColumns,
    @Default(true) bool showCommandIcons,
    @Default(ProjectWindowShape.rounded) ProjectWindowShape commandShape,
    @Default(12) double commandPadding,
    @JsonKey(includeIfNull: false) String? commandSurfaceColor,
    @JsonKey(includeIfNull: false) String? commandBorderColor,
    @JsonKey(includeIfNull: false) String? commandTextColor,
    @JsonKey(includeIfNull: false) String? commandSelectionColor,
    @JsonKey(includeIfNull: false) List<ProjectBattleCommandProfile>? commands,
    @Default(ProjectWindowShape.rounded) ProjectWindowShape hudShape,
    @Default(ProjectBattleHudPosition.topStart)
    ProjectBattleHudPosition enemyHudPosition,
    @Default(ProjectBattleHudPosition.bottomEnd)
    ProjectBattleHudPosition playerHudPosition,
    @Default(true) bool showOwnerLabel,
    @Default(true) bool showLevel,
    @Default(true) bool showExactHp,
    @Default(ProjectBattleHpBarShape.rounded)
    ProjectBattleHpBarShape hpBarShape,
    @Default('#16794B') String hpHealthyColor,
    @Default('#8A5100') String hpWarningColor,
    @Default('#B4233C') String hpDangerColor,
    @Default('#8A5100') String statusColor,
    @Default(ProjectBattlePanelPresentationProfile())
    ProjectBattlePanelPresentationProfile moves,
    @Default(ProjectBattlePanelPresentationProfile())
    ProjectBattlePanelPresentationProfile target,
    @Default(ProjectBattlePanelPresentationProfile())
    ProjectBattlePanelPresentationProfile message,
  }) = _ProjectBattlePresentationProfile;

  factory ProjectBattlePresentationProfile.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectBattlePresentationProfileFromJson(json);

  List<ProjectBattleCommandProfile> get effectiveCommands =>
      commands ?? defaultProjectBattleCommands;
}

// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_presentation_surface_role.dart';

part 'project_presentation_layout_profile.freezed.dart';
part 'project_presentation_layout_profile.g.dart';

enum ProjectPresentationBreakpoint { compact, regular, expanded }

enum ProjectPresentationLayoutSlot {
  center,
  bottomCenter,
  bottomLeft,
  leftPane,
  fullScreen,
  left,
  right,
  topCenter,
}

enum ProjectPresentationContentWidth { narrow, comfortable, wide }

enum ProjectPresentationSpacing { compact, normal, airy }

enum ProjectPresentationScreenMargin { none, compact, comfortable }

enum ProjectPresentationSecondaryElement {
  titleLogo,
  titleAuthor,
  titleDescription,
  pauseGameTitle,
  dialoguePortrait,
}

Set<ProjectPresentationLayoutSlot> projectPresentationLayoutSlotsFor(
  ProjectPresentationSurfaceRole role,
  ProjectPresentationBreakpoint breakpoint,
) => switch ((role, breakpoint)) {
  (
    ProjectPresentationSurfaceRole.title ||
        ProjectPresentationSurfaceRole.titlePrompt,
    ProjectPresentationBreakpoint.compact,
  ) =>
    const <ProjectPresentationLayoutSlot>{
      ProjectPresentationLayoutSlot.center,
      ProjectPresentationLayoutSlot.bottomCenter,
    },
  (
    ProjectPresentationSurfaceRole.title ||
        ProjectPresentationSurfaceRole.titlePrompt,
    _,
  ) =>
    const <ProjectPresentationLayoutSlot>{
      ProjectPresentationLayoutSlot.center,
      ProjectPresentationLayoutSlot.bottomCenter,
      ProjectPresentationLayoutSlot.bottomLeft,
      ProjectPresentationLayoutSlot.leftPane,
    },
  (
    ProjectPresentationSurfaceRole.pauseMenu,
    ProjectPresentationBreakpoint.compact,
  ) =>
    const <ProjectPresentationLayoutSlot>{
      ProjectPresentationLayoutSlot.bottomCenter,
      ProjectPresentationLayoutSlot.fullScreen,
    },
  (ProjectPresentationSurfaceRole.pauseMenu, _) =>
    const <ProjectPresentationLayoutSlot>{
      ProjectPresentationLayoutSlot.left,
      ProjectPresentationLayoutSlot.center,
      ProjectPresentationLayoutSlot.right,
      ProjectPresentationLayoutSlot.leftPane,
    },
  (ProjectPresentationSurfaceRole.dialogue, _) =>
    const <ProjectPresentationLayoutSlot>{
      ProjectPresentationLayoutSlot.center,
      ProjectPresentationLayoutSlot.topCenter,
      ProjectPresentationLayoutSlot.bottomCenter,
    },
  (ProjectPresentationSurfaceRole.battleHud, _) =>
    const <ProjectPresentationLayoutSlot>{
      ProjectPresentationLayoutSlot.bottomCenter,
      ProjectPresentationLayoutSlot.right,
      ProjectPresentationLayoutSlot.fullScreen,
    },
  _ => const <ProjectPresentationLayoutSlot>{},
};

Set<ProjectPresentationSecondaryElement>
projectPresentationSecondaryElementsFor(ProjectPresentationSurfaceRole role) =>
    switch (role) {
      ProjectPresentationSurfaceRole.title ||
      ProjectPresentationSurfaceRole.titlePrompt =>
        const <ProjectPresentationSecondaryElement>{
          ProjectPresentationSecondaryElement.titleLogo,
          ProjectPresentationSecondaryElement.titleAuthor,
          ProjectPresentationSecondaryElement.titleDescription,
        },
      ProjectPresentationSurfaceRole.pauseMenu =>
        const <ProjectPresentationSecondaryElement>{
          ProjectPresentationSecondaryElement.pauseGameTitle,
        },
      ProjectPresentationSurfaceRole.dialogue =>
        const <ProjectPresentationSecondaryElement>{
          ProjectPresentationSecondaryElement.dialoguePortrait,
        },
      _ => const <ProjectPresentationSecondaryElement>{},
    };

@Freezed(fromJson: true, toJson: true)
abstract class ProjectSurfaceLayoutVariant with _$ProjectSurfaceLayoutVariant {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSurfaceLayoutVariant({
    required ProjectPresentationBreakpoint breakpoint,
    required ProjectPresentationLayoutSlot slot,
    @Default(ProjectPresentationContentWidth.comfortable)
    ProjectPresentationContentWidth width,
    @Default(ProjectPresentationSpacing.normal)
    ProjectPresentationSpacing spacing,
    @Default(ProjectPresentationScreenMargin.compact)
    ProjectPresentationScreenMargin screenMargin,
    @Default(<ProjectPresentationSecondaryElement>[])
    List<ProjectPresentationSecondaryElement> visibleSecondaryElements,
  }) = _ProjectSurfaceLayoutVariant;

  factory ProjectSurfaceLayoutVariant.fromJson(Map<String, dynamic> json) =>
      _$ProjectSurfaceLayoutVariantFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectResponsiveSurfaceLayoutProfile
    with _$ProjectResponsiveSurfaceLayoutProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectResponsiveSurfaceLayoutProfile({
    required ProjectSurfaceLayoutVariant compact,
    required ProjectSurfaceLayoutVariant regular,
    required ProjectSurfaceLayoutVariant expanded,
  }) = _ProjectResponsiveSurfaceLayoutProfile;

  factory ProjectResponsiveSurfaceLayoutProfile.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectResponsiveSurfaceLayoutProfileFromJson(json);

  const ProjectResponsiveSurfaceLayoutProfile._();

  ProjectSurfaceLayoutVariant resolve(
    ProjectPresentationBreakpoint breakpoint,
  ) => switch (breakpoint) {
    ProjectPresentationBreakpoint.compact => compact,
    ProjectPresentationBreakpoint.regular => regular,
    ProjectPresentationBreakpoint.expanded => expanded,
  };
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectPresentationLayoutsProfile
    with _$ProjectPresentationLayoutsProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectPresentationLayoutsProfile({
    required ProjectResponsiveSurfaceLayoutProfile title,
    required ProjectResponsiveSurfaceLayoutProfile pauseMenu,
    required ProjectResponsiveSurfaceLayoutProfile dialogue,
    @JsonKey(includeIfNull: false)
    ProjectResponsiveSurfaceLayoutProfile? battle,
  }) = _ProjectPresentationLayoutsProfile;

  factory ProjectPresentationLayoutsProfile.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectPresentationLayoutsProfileFromJson(json);

  const ProjectPresentationLayoutsProfile._();

  ProjectResponsiveSurfaceLayoutProfile resolve(
    ProjectPresentationSurfaceRole role,
  ) => switch (role) {
    ProjectPresentationSurfaceRole.title ||
    ProjectPresentationSurfaceRole.titlePrompt => title,
    ProjectPresentationSurfaceRole.pauseMenu => pauseMenu,
    ProjectPresentationSurfaceRole.dialogue => dialogue,
    ProjectPresentationSurfaceRole.battleHud =>
      battle ??
          (throw ArgumentError.value(
            role,
            'role',
            'does not own an authored responsive layout',
          )),
    _ => throw ArgumentError.value(
      role,
      'role',
      'does not own a responsive layout',
    ),
  };
}

ProjectPresentationLayoutsProfile suggestedProjectPresentationLayouts(
  String titleLayoutVariant,
) {
  final titleExpandedSlot = titleLayoutVariant == 'cinematic'
      ? ProjectPresentationLayoutSlot.bottomLeft
      : ProjectPresentationLayoutSlot.center;
  return ProjectPresentationLayoutsProfile(
    title: ProjectResponsiveSurfaceLayoutProfile(
      compact: _surfaceVariant(
        ProjectPresentationBreakpoint.compact,
        ProjectPresentationLayoutSlot.bottomCenter,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.titleLogo,
          ProjectPresentationSecondaryElement.titleAuthor,
        ],
      ),
      regular: _surfaceVariant(
        ProjectPresentationBreakpoint.regular,
        titleLayoutVariant == 'cinematic'
            ? ProjectPresentationLayoutSlot.bottomLeft
            : ProjectPresentationLayoutSlot.center,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.titleLogo,
          ProjectPresentationSecondaryElement.titleAuthor,
          ProjectPresentationSecondaryElement.titleDescription,
        ],
      ),
      expanded: _surfaceVariant(
        ProjectPresentationBreakpoint.expanded,
        titleExpandedSlot,
        width: titleLayoutVariant == 'cinematic'
            ? ProjectPresentationContentWidth.narrow
            : ProjectPresentationContentWidth.comfortable,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.titleLogo,
          ProjectPresentationSecondaryElement.titleAuthor,
          ProjectPresentationSecondaryElement.titleDescription,
        ],
      ),
    ),
    pauseMenu: ProjectResponsiveSurfaceLayoutProfile(
      compact: _surfaceVariant(
        ProjectPresentationBreakpoint.compact,
        ProjectPresentationLayoutSlot.fullScreen,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.pauseGameTitle,
        ],
      ),
      regular: _surfaceVariant(
        ProjectPresentationBreakpoint.regular,
        ProjectPresentationLayoutSlot.left,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.pauseGameTitle,
        ],
      ),
      expanded: _surfaceVariant(
        ProjectPresentationBreakpoint.expanded,
        ProjectPresentationLayoutSlot.leftPane,
        width: ProjectPresentationContentWidth.narrow,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.pauseGameTitle,
        ],
      ),
    ),
    dialogue: ProjectResponsiveSurfaceLayoutProfile(
      compact: _surfaceVariant(
        ProjectPresentationBreakpoint.compact,
        ProjectPresentationLayoutSlot.bottomCenter,
        width: ProjectPresentationContentWidth.wide,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.dialoguePortrait,
        ],
      ),
      regular: _surfaceVariant(
        ProjectPresentationBreakpoint.regular,
        ProjectPresentationLayoutSlot.bottomCenter,
        width: ProjectPresentationContentWidth.wide,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.dialoguePortrait,
        ],
      ),
      expanded: _surfaceVariant(
        ProjectPresentationBreakpoint.expanded,
        ProjectPresentationLayoutSlot.bottomCenter,
        width: ProjectPresentationContentWidth.comfortable,
        secondary: const <ProjectPresentationSecondaryElement>[
          ProjectPresentationSecondaryElement.dialoguePortrait,
        ],
      ),
    ),
    battle: ProjectResponsiveSurfaceLayoutProfile(
      compact: _surfaceVariant(
        ProjectPresentationBreakpoint.compact,
        ProjectPresentationLayoutSlot.bottomCenter,
        width: ProjectPresentationContentWidth.wide,
        secondary: const <ProjectPresentationSecondaryElement>[],
      ),
      regular: _surfaceVariant(
        ProjectPresentationBreakpoint.regular,
        ProjectPresentationLayoutSlot.bottomCenter,
        width: ProjectPresentationContentWidth.wide,
        secondary: const <ProjectPresentationSecondaryElement>[],
      ),
      expanded: _surfaceVariant(
        ProjectPresentationBreakpoint.expanded,
        ProjectPresentationLayoutSlot.bottomCenter,
        width: ProjectPresentationContentWidth.wide,
        secondary: const <ProjectPresentationSecondaryElement>[],
      ),
    ),
  );
}

ProjectSurfaceLayoutVariant _surfaceVariant(
  ProjectPresentationBreakpoint breakpoint,
  ProjectPresentationLayoutSlot slot, {
  ProjectPresentationContentWidth width =
      ProjectPresentationContentWidth.comfortable,
  List<ProjectPresentationSecondaryElement> secondary =
      const <ProjectPresentationSecondaryElement>[],
}) => ProjectSurfaceLayoutVariant(
  breakpoint: breakpoint,
  slot: slot,
  width: width,
  visibleSecondaryElements: secondary,
);

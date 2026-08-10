import 'project_presentation_window_profile.dart';

enum ProjectPresentationSurfaceRole {
  title,
  titlePrompt,
  dialogue,
  pauseMenu,
  party,
  bag,
  pokedex,
  map,
  save,
  options,
  credits,
  notification,
  confirmation,
  overworldHud,
  battleHud,
  battleResult,
  captureResult,
}

enum ProjectPresentationSurfaceThemeToken {
  titleSurface,
  dialogueSurface,
  menuSurface,
  overworldHudSurface,
  battleHudSurface,
}

enum ProjectPresentationMenuLabelKey {
  pauseTitle,
  resume,
  party,
  bag,
  pokedex,
  map,
  save,
  options,
  returnToTitle,
}

final class ProjectPresentationSurfaceAssignment {
  const ProjectPresentationSurfaceAssignment({
    required this.role,
    required this.themeToken,
    this.windowRole,
    this.layoutRole,
    this.labelKeys = const <ProjectPresentationMenuLabelKey>[],
  });

  final ProjectPresentationSurfaceRole role;
  final ProjectPresentationSurfaceThemeToken themeToken;
  final ProjectWindowRole? windowRole;
  final ProjectPresentationSurfaceRole? layoutRole;
  final List<ProjectPresentationMenuLabelKey> labelKeys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectPresentationSurfaceAssignment &&
          other.role == role &&
          other.themeToken == themeToken &&
          other.windowRole == windowRole &&
          other.layoutRole == layoutRole &&
          _listEquals(other.labelKeys, labelKeys);

  @override
  int get hashCode => Object.hash(
    role,
    themeToken,
    windowRole,
    layoutRole,
    Object.hashAll(labelKeys),
  );
}

const projectPresentationSurfaceAssignments =
    <ProjectPresentationSurfaceAssignment>[
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.title,
        themeToken: ProjectPresentationSurfaceThemeToken.titleSurface,
        layoutRole: ProjectPresentationSurfaceRole.title,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.titlePrompt,
        themeToken: ProjectPresentationSurfaceThemeToken.titleSurface,
        layoutRole: ProjectPresentationSurfaceRole.title,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.dialogue,
        themeToken: ProjectPresentationSurfaceThemeToken.dialogueSurface,
        windowRole: ProjectWindowRole.dialogue,
        layoutRole: ProjectPresentationSurfaceRole.dialogue,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.pauseMenu,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.pauseMenu,
        layoutRole: ProjectPresentationSurfaceRole.pauseMenu,
        labelKeys: <ProjectPresentationMenuLabelKey>[
          ProjectPresentationMenuLabelKey.pauseTitle,
          ProjectPresentationMenuLabelKey.resume,
          ProjectPresentationMenuLabelKey.party,
          ProjectPresentationMenuLabelKey.bag,
          ProjectPresentationMenuLabelKey.pokedex,
          ProjectPresentationMenuLabelKey.map,
          ProjectPresentationMenuLabelKey.save,
          ProjectPresentationMenuLabelKey.options,
          ProjectPresentationMenuLabelKey.returnToTitle,
        ],
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.party,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.standard,
        labelKeys: <ProjectPresentationMenuLabelKey>[
          ProjectPresentationMenuLabelKey.party,
        ],
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.bag,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.standard,
        labelKeys: <ProjectPresentationMenuLabelKey>[
          ProjectPresentationMenuLabelKey.bag,
        ],
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.pokedex,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.standard,
        labelKeys: <ProjectPresentationMenuLabelKey>[
          ProjectPresentationMenuLabelKey.pokedex,
        ],
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.map,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.standard,
        labelKeys: <ProjectPresentationMenuLabelKey>[
          ProjectPresentationMenuLabelKey.map,
        ],
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.save,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.standard,
        labelKeys: <ProjectPresentationMenuLabelKey>[
          ProjectPresentationMenuLabelKey.save,
        ],
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.options,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.standard,
        labelKeys: <ProjectPresentationMenuLabelKey>[
          ProjectPresentationMenuLabelKey.options,
        ],
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.credits,
        themeToken: ProjectPresentationSurfaceThemeToken.titleSurface,
        windowRole: ProjectWindowRole.standard,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.notification,
        themeToken: ProjectPresentationSurfaceThemeToken.overworldHudSurface,
        windowRole: ProjectWindowRole.standard,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.confirmation,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.standard,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.overworldHud,
        themeToken: ProjectPresentationSurfaceThemeToken.overworldHudSurface,
        windowRole: ProjectWindowRole.standard,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.battleHud,
        themeToken: ProjectPresentationSurfaceThemeToken.battleHudSurface,
        windowRole: ProjectWindowRole.standard,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.battleResult,
        themeToken: ProjectPresentationSurfaceThemeToken.battleHudSurface,
        windowRole: ProjectWindowRole.standard,
      ),
      ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.captureResult,
        themeToken: ProjectPresentationSurfaceThemeToken.battleHudSurface,
        windowRole: ProjectWindowRole.standard,
      ),
    ];

ProjectPresentationSurfaceAssignment projectPresentationSurfaceAssignment(
  ProjectPresentationSurfaceRole role,
) => projectPresentationSurfaceAssignments.singleWhere(
  (assignment) => assignment.role == role,
);

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

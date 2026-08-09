import 'package:map_core/map_core.dart';

final class ProjectWindowStylePreset {
  const ProjectWindowStylePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.profile,
  });

  final String id;
  final String label;
  final String description;
  final ProjectPresentationWindowsProfile profile;
}

const classicProjectWindowStylePreset = ProjectWindowStylePreset(
  id: 'classic',
  label: 'Classique PokeMap',
  description: 'Le cadre équilibré utilisé par défaut dans le lecteur.',
  profile: legacyProjectPresentationWindows,
);

const compactProjectWindowStylePreset = ProjectWindowStylePreset(
  id: 'compact',
  label: 'Compact lisible',
  description: 'Des fenêtres plus denses qui laissent davantage voir le jeu.',
  profile: ProjectPresentationWindowsProfile(
    styles: <ProjectWindowStyleProfile>[
      ProjectWindowStyleProfile(
        id: 'default',
        fillToken: 'surface',
        borderToken: 'outline',
        borderWidth: 1,
        cornerRadius: 8,
        contentPadding: 12,
        shadowElevation: 2,
      ),
      ProjectWindowStyleProfile(
        id: 'pause-menu',
        fillToken: 'menuSurface',
        borderToken: 'outline',
        borderWidth: 1,
        cornerRadius: 8,
        contentPadding: 12,
        shadowElevation: 2,
      ),
      ProjectWindowStyleProfile(
        id: 'dialogue',
        fillToken: 'dialogueSurface',
        borderToken: 'outline',
        borderWidth: 1,
        cornerRadius: 8,
        contentPadding: 12,
        shadowElevation: 2,
      ),
    ],
    defaultStyleId: 'default',
    pauseMenuStyleId: 'pause-menu',
    dialogueStyleId: 'dialogue',
    pauseBackdropOpacity: .65,
  ),
);

const softProjectWindowStylePreset = ProjectWindowStylePreset(
  id: 'soft',
  label: 'Doux',
  description: 'Des angles généreux et une profondeur plus présente.',
  profile: ProjectPresentationWindowsProfile(
    styles: <ProjectWindowStyleProfile>[
      ProjectWindowStyleProfile(
        id: 'default',
        fillToken: 'surfaceElevated',
        borderToken: 'outline',
        borderWidth: 1,
        cornerRadius: 24,
        contentPadding: 24,
        shadowElevation: 12,
      ),
      ProjectWindowStyleProfile(
        id: 'pause-menu',
        fillToken: 'menuSurface',
        borderToken: 'outline',
        borderWidth: 1,
        cornerRadius: 24,
        contentPadding: 24,
        shadowElevation: 12,
      ),
      ProjectWindowStyleProfile(
        id: 'dialogue',
        fillToken: 'dialogueSurface',
        borderToken: 'outline',
        borderWidth: 1,
        cornerRadius: 24,
        contentPadding: 20,
        shadowElevation: 8,
      ),
    ],
    defaultStyleId: 'default',
    pauseMenuStyleId: 'pause-menu',
    dialogueStyleId: 'dialogue',
    pauseBackdropOpacity: .75,
  ),
);

const outlinedProjectWindowStylePreset = ProjectWindowStylePreset(
  id: 'outlined',
  label: 'Contour renforcé',
  description: 'Un cadre très net pour mieux séparer les informations.',
  profile: ProjectPresentationWindowsProfile(
    styles: <ProjectWindowStyleProfile>[
      ProjectWindowStyleProfile(
        id: 'default',
        fillToken: 'surface',
        borderToken: 'primary',
        borderWidth: 3,
        cornerRadius: 12,
        contentPadding: 20,
        shadowElevation: 4,
      ),
      ProjectWindowStyleProfile(
        id: 'pause-menu',
        fillToken: 'menuSurface',
        borderToken: 'primary',
        borderWidth: 3,
        cornerRadius: 12,
        contentPadding: 20,
        shadowElevation: 4,
      ),
      ProjectWindowStyleProfile(
        id: 'dialogue',
        fillToken: 'dialogueSurface',
        borderToken: 'primary',
        borderWidth: 3,
        cornerRadius: 12,
        contentPadding: 20,
        shadowElevation: 4,
      ),
    ],
    defaultStyleId: 'default',
    pauseMenuStyleId: 'pause-menu',
    dialogueStyleId: 'dialogue',
    pauseBackdropOpacity: .8,
  ),
);

const projectWindowStylePresets = <ProjectWindowStylePreset>[
  classicProjectWindowStylePreset,
  compactProjectWindowStylePreset,
  softProjectWindowStylePreset,
  outlinedProjectWindowStylePreset,
];

import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'project_window_style_presets.dart';

final class ProjectPresentationPreset {
  const ProjectPresentationPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.profile,
    required this.categories,
  });

  final String id;
  final String label;
  final String description;
  final ProjectPresentationProfile profile;
  final Set<ProjectPresentationCategory> categories;

  bool supports(ProjectPresentationCategory category) =>
      categories.contains(category);

  ProjectPresentationProfile apply(
    ProjectPresentationProfile current,
    ProjectPresentationCategory category,
  ) {
    if (!supports(category)) return current;
    return switch (category) {
      ProjectPresentationCategory.branding => current.copyWith(
        branding: profile.branding,
        title: profile.title,
        titleMotion: profile.titleMotion,
      ),
      ProjectPresentationCategory.intro => current.copyWith(
        intro: profile.intro,
      ),
      ProjectPresentationCategory.typography => current.copyWith(
        typography: profile.typography,
      ),
      ProjectPresentationCategory.theme => current.copyWith(
        theme: profile.theme,
        pause: profile.pause,
        menuLabels: null,
        windows: profile.windows,
      ),
      ProjectPresentationCategory.layouts => current.copyWith(
        layouts: profile.layouts,
      ),
    };
  }
}

final cinematicPresentationPreset = ProjectPresentationPreset(
  id: 'cinematic',
  label: 'Cinématique',
  description: 'Titre immersif et HUD sombre à fort contraste.',
  categories: <ProjectPresentationCategory>{
    ProjectPresentationCategory.branding,
    ProjectPresentationCategory.theme,
    ProjectPresentationCategory.layouts,
  },
  profile: ProjectPresentationProfile(
    branding: ProjectBrandingProfile(
      accentColor: '#8C5CFF',
      layoutVariant: 'cinematic',
    ),
    theme: ProjectSemanticThemeProfile(
      primary: '#8C5CFF',
      onPrimary: '#FFFFFF',
      background: '#090B14',
      surface: '#121728',
      surfaceElevated: '#1C2338',
      textPrimary: '#FFFFFF',
      textSecondary: '#C6CBE0',
      outline: '#8791AD',
      success: '#4ADE80',
      warning: '#FBBF24',
      danger: '#FB7185',
      titleSurface: '#11182C',
      dialogueSurface: '#161D30',
      menuSurface: '#1C2338',
      overworldHudSurface: '#10182B',
      battleHudSurface: '#171F33',
    ),
    windows: softProjectWindowStylePreset.profile,
    layouts: suggestedProjectPresentationLayouts('cinematic'),
  ),
);

final classicPresentationPreset = ProjectPresentationPreset(
  id: 'classic',
  label: 'Aventure classique',
  description: 'Présentation claire, centrée et lisible.',
  categories: <ProjectPresentationCategory>{
    ProjectPresentationCategory.branding,
    ProjectPresentationCategory.typography,
    ProjectPresentationCategory.theme,
    ProjectPresentationCategory.layouts,
  },
  profile: ProjectPresentationProfile(
    branding: ProjectBrandingProfile(
      accentColor: '#003A44',
      layoutVariant: 'centered',
    ),
    typography: ProjectTypographyProfile(),
    theme: safeProjectSemanticTheme,
    windows: legacyProjectPresentationWindows,
    layouts: suggestedProjectPresentationLayouts('centered'),
  ),
);

final accessiblePresentationPreset = ProjectPresentationPreset(
  id: 'accessible',
  label: 'Contraste renforcé',
  description: 'Palette claire avec repères très distincts.',
  categories: <ProjectPresentationCategory>{ProjectPresentationCategory.theme},
  profile: ProjectPresentationProfile(
    theme: safeProjectSemanticTheme,
    windows: outlinedProjectWindowStylePreset.profile,
  ),
);

final projectPresentationPresets = <ProjectPresentationPreset>[
  classicPresentationPreset,
  cinematicPresentationPreset,
  accessiblePresentationPreset,
];

ProjectPresentationProfile resetProjectPresentationCategory(
  ProjectPresentationProfile current,
  ProjectPresentationCategory category,
) => switch (category) {
  ProjectPresentationCategory.branding => current.copyWith(
    branding: const ProjectBrandingProfile(),
    title: null,
    titleMotion: null,
  ),
  ProjectPresentationCategory.intro => current.copyWith(intro: null),
  ProjectPresentationCategory.typography => current.copyWith(typography: null),
  ProjectPresentationCategory.theme => current.copyWith(
    theme: null,
    pause: null,
    menuLabels: null,
    windows: null,
  ),
  ProjectPresentationCategory.layouts => current.copyWith(layouts: null),
};

final class ProjectPresentationComparison {
  const ProjectPresentationComparison({required this.changedPaths});

  final List<String> changedPaths;
  bool get isIdentical => changedPaths.isEmpty;
}

ProjectPresentationComparison compareProjectPresentation(
  ProjectPresentationProfile baseline,
  ProjectPresentationProfile current,
) {
  final changed = <String>[];
  final baselineBranding = baseline.branding.toJson();
  final currentBranding = current.branding.toJson();
  for (final key in <String>{
    ...baselineBranding.keys,
    ...currentBranding.keys,
  }) {
    if (!_jsonEqual(baselineBranding[key], currentBranding[key])) {
      changed.add(r'$.branding.' + key);
    }
  }
  if (!_jsonEqual(baseline.intro?.toJson(), current.intro?.toJson())) {
    changed.add(r'$.intro');
  }
  if (!_jsonEqual(baseline.title?.toJson(), current.title?.toJson())) {
    changed.add(r'$.title');
  }
  if (!_jsonEqual(
    baseline.titleMotion?.toJson(),
    current.titleMotion?.toJson(),
  )) {
    changed.add(r'$.titleMotion');
  }
  if (!_jsonEqual(
    baseline.typography?.toJson(),
    current.typography?.toJson(),
  )) {
    changed.add(r'$.typography');
  }
  if (!_jsonEqual(baseline.theme?.toJson(), current.theme?.toJson())) {
    changed.add(r'$.theme');
  }
  if (!_jsonEqual(baseline.pause?.toJson(), current.pause?.toJson())) {
    changed.add(r'$.pause');
  }
  if (!_jsonEqual(baseline.windows?.toJson(), current.windows?.toJson())) {
    changed.add(r'$.windows');
  }
  if (!_jsonEqual(baseline.layouts?.toJson(), current.layouts?.toJson())) {
    changed.add(r'$.layouts');
  }
  return ProjectPresentationComparison(
    changedPaths: List<String>.unmodifiable(changed),
  );
}

bool _jsonEqual(Object? left, Object? right) =>
    jsonEncode(left) == jsonEncode(right);

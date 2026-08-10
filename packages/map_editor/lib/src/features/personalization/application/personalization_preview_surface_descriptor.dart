import 'package:map_core/map_core.dart';

enum PersonalizationStudioScene {
  globalStyle,
  title,
  intro,
  pause,
  dialogue,
  battle,
}

enum PersonalizationPreviewThemeRole {
  globalBackground,
  titleSurface,
  dialogueSurface,
  menuSurface,
  battleSurface,
}

final class PersonalizationStudioSceneDescriptor {
  const PersonalizationStudioSceneDescriptor({
    required this.surface,
    required this.label,
    required this.themeRole,
    required this.typographyRole,
    required this.supportsReducedMotion,
    this.defaultCategory,
  });

  final PersonalizationStudioScene surface;
  final String label;
  final ProjectPresentationCategory? defaultCategory;
  final PersonalizationPreviewThemeRole themeRole;
  final ProjectTypographyRole typographyRole;
  final bool supportsReducedMotion;

  String backgroundHex(ProjectSemanticThemeProfile theme) =>
      switch (themeRole) {
        PersonalizationPreviewThemeRole.globalBackground => theme.background,
        PersonalizationPreviewThemeRole.titleSurface => theme.titleSurface,
        PersonalizationPreviewThemeRole.dialogueSurface =>
          theme.dialogueSurface,
        PersonalizationPreviewThemeRole.menuSurface => theme.menuSurface,
        PersonalizationPreviewThemeRole.battleSurface => theme.battleHudSurface,
      };

  ProjectTypographyRoleProfile? typographyProfile(
    ProjectTypographyProfile? typography,
  ) => switch (typographyRole) {
    ProjectTypographyRole.display => typography?.display,
    ProjectTypographyRole.body => typography?.body,
    ProjectTypographyRole.dialogue => typography?.dialogue,
    ProjectTypographyRole.combat => typography?.combat ?? typography?.body,
    ProjectTypographyRole.numbers => typography?.numbers,
  };

  static PersonalizationStudioSceneDescriptor forSurface(
    PersonalizationStudioScene surface,
  ) => personalizationPreviewSurfaceDescriptors.singleWhere(
    (descriptor) => descriptor.surface == surface,
  );

  static PersonalizationStudioSceneDescriptor defaultForCategory(
    ProjectPresentationCategory category,
  ) => category == ProjectPresentationCategory.layouts
      ? forSurface(PersonalizationStudioScene.title)
      : personalizationPreviewSurfaceDescriptors.singleWhere(
          (descriptor) => descriptor.defaultCategory == category,
        );
}

const personalizationPreviewSurfaceDescriptors =
    <PersonalizationStudioSceneDescriptor>[
      PersonalizationStudioSceneDescriptor(
        surface: PersonalizationStudioScene.globalStyle,
        label: 'Style global',
        defaultCategory: ProjectPresentationCategory.theme,
        themeRole: PersonalizationPreviewThemeRole.globalBackground,
        typographyRole: ProjectTypographyRole.body,
        supportsReducedMotion: false,
      ),
      PersonalizationStudioSceneDescriptor(
        surface: PersonalizationStudioScene.title,
        label: 'Écran titre',
        defaultCategory: ProjectPresentationCategory.branding,
        themeRole: PersonalizationPreviewThemeRole.titleSurface,
        typographyRole: ProjectTypographyRole.display,
        supportsReducedMotion: true,
      ),
      PersonalizationStudioSceneDescriptor(
        surface: PersonalizationStudioScene.intro,
        label: 'Intro',
        defaultCategory: ProjectPresentationCategory.intro,
        themeRole: PersonalizationPreviewThemeRole.titleSurface,
        typographyRole: ProjectTypographyRole.display,
        supportsReducedMotion: true,
      ),
      PersonalizationStudioSceneDescriptor(
        surface: PersonalizationStudioScene.pause,
        label: 'Menu Pause',
        themeRole: PersonalizationPreviewThemeRole.menuSurface,
        typographyRole: ProjectTypographyRole.body,
        supportsReducedMotion: false,
      ),
      PersonalizationStudioSceneDescriptor(
        surface: PersonalizationStudioScene.dialogue,
        label: 'Dialogue',
        defaultCategory: ProjectPresentationCategory.typography,
        themeRole: PersonalizationPreviewThemeRole.dialogueSurface,
        typographyRole: ProjectTypographyRole.dialogue,
        supportsReducedMotion: false,
      ),
      PersonalizationStudioSceneDescriptor(
        surface: PersonalizationStudioScene.battle,
        label: 'Combat',
        themeRole: PersonalizationPreviewThemeRole.battleSurface,
        typographyRole: ProjectTypographyRole.numbers,
        supportsReducedMotion: false,
      ),
    ];

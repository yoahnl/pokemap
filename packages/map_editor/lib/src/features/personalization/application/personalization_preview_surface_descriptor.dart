import 'package:map_core/map_core.dart';

enum PersonalizationPreviewSurface {
  intro,
  title,
  dialogue,
  menu,
  overworldHud,
  battleHud,
}

enum PersonalizationPreviewThemeRole {
  titleSurface,
  dialogueSurface,
  menuSurface,
  overworldHudSurface,
  battleHudSurface,
}

final class PersonalizationPreviewSurfaceDescriptor {
  const PersonalizationPreviewSurfaceDescriptor({
    required this.surface,
    required this.label,
    required this.themeRole,
    required this.typographyRole,
    required this.supportsReducedMotion,
    this.defaultCategory,
  });

  final PersonalizationPreviewSurface surface;
  final String label;
  final ProjectPresentationCategory? defaultCategory;
  final PersonalizationPreviewThemeRole themeRole;
  final ProjectTypographyRole typographyRole;
  final bool supportsReducedMotion;

  String backgroundHex(
    ProjectSemanticThemeProfile theme,
  ) => switch (themeRole) {
    PersonalizationPreviewThemeRole.titleSurface => theme.titleSurface,
    PersonalizationPreviewThemeRole.dialogueSurface => theme.dialogueSurface,
    PersonalizationPreviewThemeRole.menuSurface => theme.menuSurface,
    PersonalizationPreviewThemeRole.overworldHudSurface =>
      theme.overworldHudSurface,
    PersonalizationPreviewThemeRole.battleHudSurface => theme.battleHudSurface,
  };

  ProjectTypographyRoleProfile? typographyProfile(
    ProjectTypographyProfile? typography,
  ) => switch (typographyRole) {
    ProjectTypographyRole.display => typography?.display,
    ProjectTypographyRole.body => typography?.body,
    ProjectTypographyRole.dialogue => typography?.dialogue,
    ProjectTypographyRole.numbers => typography?.numbers,
  };

  static PersonalizationPreviewSurfaceDescriptor forSurface(
    PersonalizationPreviewSurface surface,
  ) => personalizationPreviewSurfaceDescriptors.singleWhere(
    (descriptor) => descriptor.surface == surface,
  );

  static PersonalizationPreviewSurfaceDescriptor defaultForCategory(
    ProjectPresentationCategory category,
  ) => category == ProjectPresentationCategory.layouts
      ? forSurface(PersonalizationPreviewSurface.title)
      : personalizationPreviewSurfaceDescriptors.singleWhere(
          (descriptor) => descriptor.defaultCategory == category,
        );
}

const personalizationPreviewSurfaceDescriptors =
    <PersonalizationPreviewSurfaceDescriptor>[
      PersonalizationPreviewSurfaceDescriptor(
        surface: PersonalizationPreviewSurface.intro,
        label: 'Intro',
        defaultCategory: ProjectPresentationCategory.intro,
        themeRole: PersonalizationPreviewThemeRole.titleSurface,
        typographyRole: ProjectTypographyRole.display,
        supportsReducedMotion: true,
      ),
      PersonalizationPreviewSurfaceDescriptor(
        surface: PersonalizationPreviewSurface.title,
        label: 'Titre',
        defaultCategory: ProjectPresentationCategory.branding,
        themeRole: PersonalizationPreviewThemeRole.titleSurface,
        typographyRole: ProjectTypographyRole.display,
        supportsReducedMotion: true,
      ),
      PersonalizationPreviewSurfaceDescriptor(
        surface: PersonalizationPreviewSurface.dialogue,
        label: 'Dialogue',
        defaultCategory: ProjectPresentationCategory.typography,
        themeRole: PersonalizationPreviewThemeRole.dialogueSurface,
        typographyRole: ProjectTypographyRole.dialogue,
        supportsReducedMotion: false,
      ),
      PersonalizationPreviewSurfaceDescriptor(
        surface: PersonalizationPreviewSurface.menu,
        label: 'Menu',
        defaultCategory: ProjectPresentationCategory.theme,
        themeRole: PersonalizationPreviewThemeRole.menuSurface,
        typographyRole: ProjectTypographyRole.body,
        supportsReducedMotion: false,
      ),
      PersonalizationPreviewSurfaceDescriptor(
        surface: PersonalizationPreviewSurface.overworldHud,
        label: 'HUD exploration',
        themeRole: PersonalizationPreviewThemeRole.overworldHudSurface,
        typographyRole: ProjectTypographyRole.body,
        supportsReducedMotion: false,
      ),
      PersonalizationPreviewSurfaceDescriptor(
        surface: PersonalizationPreviewSurface.battleHud,
        label: 'HUD combat',
        themeRole: PersonalizationPreviewThemeRole.battleHudSurface,
        typographyRole: ProjectTypographyRole.numbers,
        supportsReducedMotion: false,
      ),
    ];

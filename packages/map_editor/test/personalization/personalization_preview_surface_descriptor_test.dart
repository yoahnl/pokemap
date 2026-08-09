import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test('describes every preview surface exactly once', () {
    expect(
      personalizationPreviewSurfaceDescriptors.map((value) => value.surface),
      unorderedEquals(PersonalizationPreviewSurface.values),
    );
    expect(
      personalizationPreviewSurfaceDescriptors
          .map((value) => value.label)
          .toSet(),
      hasLength(PersonalizationPreviewSurface.values.length),
    );
  });

  test('maps each authoring category to one contextual surface', () {
    expect(
      PersonalizationPreviewSurfaceDescriptor.defaultForCategory(
        ProjectPresentationCategory.branding,
      ).surface,
      PersonalizationPreviewSurface.title,
    );
    expect(
      PersonalizationPreviewSurfaceDescriptor.defaultForCategory(
        ProjectPresentationCategory.intro,
      ).surface,
      PersonalizationPreviewSurface.intro,
    );
    expect(
      PersonalizationPreviewSurfaceDescriptor.defaultForCategory(
        ProjectPresentationCategory.typography,
      ).surface,
      PersonalizationPreviewSurface.dialogue,
    );
    expect(
      PersonalizationPreviewSurfaceDescriptor.defaultForCategory(
        ProjectPresentationCategory.theme,
      ).surface,
      PersonalizationPreviewSurface.menu,
    );
  });

  test('declares the projection roles and reduced motion support', () {
    final title = PersonalizationPreviewSurfaceDescriptor.forSurface(
      PersonalizationPreviewSurface.title,
    );
    final menu = PersonalizationPreviewSurfaceDescriptor.forSurface(
      PersonalizationPreviewSurface.menu,
    );

    expect(title.themeRole, PersonalizationPreviewThemeRole.titleSurface);
    expect(title.typographyRole, ProjectTypographyRole.display);
    expect(title.supportsReducedMotion, isTrue);
    expect(menu.themeRole, PersonalizationPreviewThemeRole.menuSurface);
    expect(menu.typographyRole, ProjectTypographyRole.body);
    expect(menu.supportsReducedMotion, isFalse);
  });
}

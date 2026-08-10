import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test('describes the six studio scenes exactly once', () {
    expect(
      personalizationPreviewSurfaceDescriptors.map((value) => value.surface),
      orderedEquals(const <PersonalizationStudioScene>[
        PersonalizationStudioScene.globalStyle,
        PersonalizationStudioScene.title,
        PersonalizationStudioScene.intro,
        PersonalizationStudioScene.pause,
        PersonalizationStudioScene.dialogue,
        PersonalizationStudioScene.battle,
      ]),
    );
    expect(
      personalizationPreviewSurfaceDescriptors
          .map((value) => value.label)
          .toSet(),
      hasLength(6),
    );
    expect(
      personalizationPreviewSurfaceDescriptors.map((value) => value.label),
      orderedEquals(const <String>[
        'Style global',
        'Écran titre',
        'Intro',
        'Menu Pause',
        'Dialogue',
        'Combat',
      ]),
    );
  });

  test('maps each authoring category to one contextual surface', () {
    expect(
      PersonalizationStudioSceneDescriptor.defaultForCategory(
        ProjectPresentationCategory.branding,
      ).surface,
      PersonalizationStudioScene.title,
    );
    expect(
      PersonalizationStudioSceneDescriptor.defaultForCategory(
        ProjectPresentationCategory.intro,
      ).surface,
      PersonalizationStudioScene.intro,
    );
    expect(
      PersonalizationStudioSceneDescriptor.defaultForCategory(
        ProjectPresentationCategory.typography,
      ).surface,
      PersonalizationStudioScene.dialogue,
    );
    expect(
      PersonalizationStudioSceneDescriptor.defaultForCategory(
        ProjectPresentationCategory.theme,
      ).surface,
      PersonalizationStudioScene.globalStyle,
    );
    expect(
      PersonalizationStudioSceneDescriptor.defaultForCategory(
        ProjectPresentationCategory.layouts,
      ).surface,
      PersonalizationStudioScene.title,
    );
  });

  test('declares the projection roles and reduced motion support', () {
    final title = PersonalizationStudioSceneDescriptor.forSurface(
      PersonalizationStudioScene.title,
    );
    final pause = PersonalizationStudioSceneDescriptor.forSurface(
      PersonalizationStudioScene.pause,
    );

    expect(title.themeRole, PersonalizationPreviewThemeRole.titleSurface);
    expect(title.typographyRole, ProjectTypographyRole.display);
    expect(title.supportsReducedMotion, isTrue);
    expect(pause.themeRole, PersonalizationPreviewThemeRole.menuSurface);
    expect(pause.typographyRole, ProjectTypographyRole.body);
    expect(pause.supportsReducedMotion, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test('canonical registry describes every visible studio capability', () {
    expect(
      personalizationCapabilityRegistry.ids,
      containsAll(<String>{
        'preview.viewport',
        'preview.textScale',
        'preview.reducedMotion',
        'preview.compare',
        'studio.sceneNavigation',
        'inspector.targetNavigation',
        'global.colors',
        'global.windows',
        'global.typography',
        'title.presentation',
        'title.media',
        'title.motion',
        'intro.media',
        'intro.focalPoint',
        'pause.layout',
        'pause.windows',
        'pause.typography',
        'pause.labels',
        'dialogue.layout',
        'dialogue.windows',
        'dialogue.typography',
        'dialogue.previewCharacter',
        'dialogue.previewPortrait',
        'dialogue.previewName',
        'dialogue.previewChoices',
        'battle.previewState',
        'battle.layout',
        'battle.windows',
        'battle.typography',
      }),
    );
    expect(personalizationCapabilityRegistry.descriptors, hasLength(29));
  });

  test('project capabilities require persistence and runtime evidence', () {
    expect(
      () => PersonalizationCapabilityDescriptor(
        id: 'dialogue.window',
        scene: PersonalizationStudioScene.dialogue,
        label: 'Fenêtre',
        effect: PersonalizationControlEffect.project,
      ),
      throwsArgumentError,
    );
    expect(
      () => PersonalizationCapabilityDescriptor(
        id: 'dialogue.window',
        scene: PersonalizationStudioScene.dialogue,
        label: 'Fenêtre',
        effect: PersonalizationControlEffect.project,
        projectPath: '/presentation/windows/dialogue',
      ),
      throwsArgumentError,
    );
  });

  test('preview and navigation capabilities cannot pretend to persist', () {
    for (final effect in <PersonalizationControlEffect>[
      PersonalizationControlEffect.previewOnly,
      PersonalizationControlEffect.navigation,
    ]) {
      expect(
        () => PersonalizationCapabilityDescriptor(
          id: 'local.control',
          scene: PersonalizationStudioScene.dialogue,
          label: 'Local',
          effect: effect,
          projectPath: '/presentation/fake',
          testKey: 'local-control',
        ),
        throwsArgumentError,
      );
    }
  });

  test('registry rejects duplicates, missing controls and orphan entries', () {
    final descriptor = PersonalizationCapabilityDescriptor(
      id: 'preview.toggle',
      scene: PersonalizationStudioScene.dialogue,
      label: 'Option de test',
      effect: PersonalizationControlEffect.previewOnly,
      testKey: 'preview-toggle',
    );
    expect(
      () => PersonalizationCapabilityRegistry(
        <PersonalizationCapabilityDescriptor>[descriptor, descriptor],
      ),
      throwsArgumentError,
    );
    final registry = PersonalizationCapabilityRegistry(
      <PersonalizationCapabilityDescriptor>[descriptor],
    );
    expect(
      () => registry.requireExactControlIds(<String>{'missing.control'}),
      throwsStateError,
    );
    expect(
      () => registry.requireExactControlIds(<String>{
        'preview.toggle',
        'orphan.control',
      }),
      throwsStateError,
    );
  });
}

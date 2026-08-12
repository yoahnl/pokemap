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
        'preview.contentSource',
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
        'pause.actions',
        'dialogue.geometry',
        'dialogue.colors',
        'dialogue.portrait',
        'dialogue.nameplate',
        'dialogue.choices',
        'dialogue.progress',
        'dialogue.motion',
        'dialogue.typography',
        'dialogue.previewCharacter',
        'dialogue.previewPortrait',
        'dialogue.previewName',
        'dialogue.previewChoices',
        'battle.previewState',
        'battle.commands',
        'battle.hud',
        'battle.moves',
        'battle.target',
        'battle.message',
        'battle.layout',
        'battle.windows',
        'battle.typography',
      }),
    );
    expect(personalizationCapabilityRegistry.descriptors, hasLength(40));
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

  test('every concrete preview control resolves to an honest capability', () {
    const controls = <String>{
      'personalization-preview-viewport-landscape',
      'personalization-preview-viewport-portrait',
      'personalization-preview-text-scale-100',
      'personalization-preview-text-scale-150',
      'personalization-preview-text-scale-200',
      'personalization-preview-reduced-motion',
      'personalization-preview-compare',
      'personalization-preview-source-project',
      'personalization-preview-source-demonstration',
    };

    for (final control in controls) {
      expect(
        personalizationCapabilityRegistry.requireByControlKey(control).effect,
        PersonalizationControlEffect.previewOnly,
        reason: control,
      );
    }
    expect(
      personalizationCapabilityRegistry.controlKeys,
      containsAll(controls),
    );
  });

  test('registry rejects duplicate concrete control keys', () {
    final first = PersonalizationCapabilityDescriptor(
      id: 'preview.first',
      scene: PersonalizationStudioScene.dialogue,
      label: 'Premier',
      effect: PersonalizationControlEffect.previewOnly,
      testKey: 'shared-control',
    );
    final second = PersonalizationCapabilityDescriptor(
      id: 'preview.second',
      scene: PersonalizationStudioScene.dialogue,
      label: 'Second',
      effect: PersonalizationControlEffect.previewOnly,
      testKey: 'other-control',
      additionalTestKeys: const <String>{'shared-control'},
    );

    expect(
      () => PersonalizationCapabilityRegistry(
        <PersonalizationCapabilityDescriptor>[first, second],
      ),
      throwsArgumentError,
    );
  });

  test('visible Studio capability bindings match the registry exactly', () {
    expect(
      () => personalizationCapabilityRegistry.requireExactControlIds(
        personalizationStudioVisibleCapabilityIds,
      ),
      returnsNormally,
    );
  });
}

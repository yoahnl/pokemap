import 'personalization_capability_descriptor.dart';
import 'personalization_preview_surface_descriptor.dart';

final class PersonalizationCapabilityRegistry {
  PersonalizationCapabilityRegistry(
    Iterable<PersonalizationCapabilityDescriptor> descriptors,
  ) : descriptors = List.unmodifiable(descriptors) {
    final byId = <String, PersonalizationCapabilityDescriptor>{};
    for (final descriptor in this.descriptors) {
      if (byId.containsKey(descriptor.id)) {
        throw ArgumentError.value(descriptor.id, 'descriptors');
      }
      byId[descriptor.id] = descriptor;
    }
    _byId = Map.unmodifiable(byId);
  }

  final List<PersonalizationCapabilityDescriptor> descriptors;
  late final Map<String, PersonalizationCapabilityDescriptor> _byId;

  Set<String> get ids => Set.unmodifiable(_byId.keys);

  PersonalizationCapabilityDescriptor require(String id) =>
      _byId[id] ?? (throw StateError('Unknown personalization control: $id'));

  void requireExactControlIds(Set<String> controlIds) {
    final missing = controlIds.difference(ids);
    final orphaned = ids.difference(controlIds);
    if (missing.isNotEmpty || orphaned.isNotEmpty) {
      throw StateError(
        'Personalization capability mismatch. Missing: '
        '${missing.toList()..sort()}; orphaned: ${orphaned.toList()..sort()}.',
      );
    }
  }
}

final personalizationCapabilityRegistry =
    PersonalizationCapabilityRegistry(<PersonalizationCapabilityDescriptor>[
      _local(
        'preview.viewport',
        PersonalizationStudioScene.globalStyle,
        'Format de l’aperçu',
        'personalization-preview-viewport-landscape',
      ),
      _local(
        'preview.textScale',
        PersonalizationStudioScene.globalStyle,
        'Taille du texte de test',
        'personalization-preview-text-scale-100',
      ),
      _local(
        'preview.reducedMotion',
        PersonalizationStudioScene.intro,
        'Mouvement réduit de test',
        'personalization-preview-reduced-motion',
      ),
      _local(
        'preview.compare',
        PersonalizationStudioScene.globalStyle,
        'Comparaison avant/après',
        'personalization-preview-compare',
      ),
      _navigation(
        'studio.sceneNavigation',
        PersonalizationStudioScene.globalStyle,
        'Navigation entre les scènes',
        'personalization-studio-navigation-list',
      ),
      _navigation(
        'inspector.targetNavigation',
        PersonalizationStudioScene.globalStyle,
        'Navigation entre les réglages',
        'personalization-studio-scene-inspector',
      ),
      _project(
        'global.colors',
        PersonalizationStudioScene.globalStyle,
        'Couleurs',
        '/presentation/theme',
        'RuntimePlayerPresentation',
        'global-style-color-accent',
      ),
      _project(
        'global.windows',
        PersonalizationStudioScene.globalStyle,
        'Fenêtres',
        '/presentation/windows',
        'PokeMapPlayerWindowTheme',
        'window-field-corner-radius',
      ),
      _project(
        'global.typography',
        PersonalizationStudioScene.globalStyle,
        'Typographie',
        '/presentation/typography',
        'PokeMapPlayerTheme',
        'typography-import-common',
      ),
      _project(
        'title.presentation',
        PersonalizationStudioScene.title,
        'Composition de l’écran titre',
        '/presentation/layouts/title',
        'PlayerTitleSurface',
        'title-preset-centered',
      ),
      _project(
        'title.media',
        PersonalizationStudioScene.title,
        'Médias de l’écran titre',
        '/presentation/branding',
        'PlayerTitleSurface',
        'branding-import-cover',
      ),
      _project(
        'title.motion',
        PersonalizationStudioScene.title,
        'Animation de l’écran titre',
        '/presentation/titleMotion',
        'PlayerTitleMotion',
        'title-motion-import-menuLoop',
      ),
      _project(
        'intro.media',
        PersonalizationStudioScene.intro,
        'Média d’introduction',
        '/presentation/intro',
        'PlayerIntroVideoSurface',
        'personalization-intro-import',
      ),
      _project(
        'intro.focalPoint',
        PersonalizationStudioScene.intro,
        'Point important de l’introduction',
        '/presentation/intro/media',
        'PlayerIntroVideoSurface',
        'intro-focal-center',
      ),
      _project(
        'pause.layout',
        PersonalizationStudioScene.pause,
        'Disposition du menu Pause',
        '/presentation/layouts/pauseMenu',
        'RuntimePlayerPauseShell',
        'layout-preset-adaptive',
      ),
      _project(
        'pause.windows',
        PersonalizationStudioScene.pause,
        'Fenêtre du menu Pause',
        '/presentation/windows',
        'RuntimePlayerPauseShell',
        'window-field-fill',
      ),
      _project(
        'pause.typography',
        PersonalizationStudioScene.pause,
        'Typographie du menu Pause',
        '/presentation/typography',
        'RuntimePlayerPauseShell',
        'typography-import-common',
      ),
      _project(
        'pause.labels',
        PersonalizationStudioScene.pause,
        'Libellés du menu Pause',
        '/presentation/menuLabels',
        'RuntimePlayerPauseShell',
        'menu-label-pokedex',
      ),
      _project(
        'dialogue.layout',
        PersonalizationStudioScene.dialogue,
        'Disposition du dialogue',
        '/presentation/layouts/dialogue',
        'PlayerDialogueSurface',
        'dialogue-layout-bottom',
      ),
      _project(
        'dialogue.windows',
        PersonalizationStudioScene.dialogue,
        'Fenêtre du dialogue',
        '/presentation/windows',
        'PlayerDialogueSurface',
        'window-field-corner-radius',
      ),
      _project(
        'dialogue.typography',
        PersonalizationStudioScene.dialogue,
        'Typographie du dialogue',
        '/presentation/typography',
        'PlayerDialogueSurface',
        'typography-import-dialogue',
      ),
      _local(
        'dialogue.previewCharacter',
        PersonalizationStudioScene.dialogue,
        'Personnage de test',
        'dialogue-preview-character',
      ),
      _local(
        'dialogue.previewPortrait',
        PersonalizationStudioScene.dialogue,
        'Portrait de test',
        'dialogue-preview-portrait',
      ),
      _local(
        'dialogue.previewName',
        PersonalizationStudioScene.dialogue,
        'Nom de test',
        'dialogue-preview-name',
      ),
      _local(
        'dialogue.previewChoices',
        PersonalizationStudioScene.dialogue,
        'Choix de réponse de test',
        'dialogue-preview-choices',
      ),
      _local(
        'battle.previewState',
        PersonalizationStudioScene.battle,
        'État du combat de test',
        'battle-preview-state-commands',
      ),
      _project(
        'battle.layout',
        PersonalizationStudioScene.battle,
        'Disposition du combat',
        '/presentation/layouts/battle',
        'PlayerBattleSurface',
        'battle-preset-classic',
      ),
      _project(
        'battle.windows',
        PersonalizationStudioScene.battle,
        'Fenêtre de combat',
        '/presentation/windows',
        'PlayerBattleSurface',
        'window-field-fill',
      ),
      _project(
        'battle.typography',
        PersonalizationStudioScene.battle,
        'Typographie de combat',
        '/presentation/typography',
        'PlayerBattleSurface',
        'typography-import-combat',
      ),
    ]);

PersonalizationCapabilityDescriptor _project(
  String id,
  PersonalizationStudioScene scene,
  String label,
  String projectPath,
  String runtimeSurface,
  String testKey,
) => PersonalizationCapabilityDescriptor(
  id: id,
  scene: scene,
  label: label,
  effect: PersonalizationControlEffect.project,
  projectPath: projectPath,
  runtimeSurface: runtimeSurface,
  testKey: testKey,
);

PersonalizationCapabilityDescriptor _local(
  String id,
  PersonalizationStudioScene scene,
  String label,
  String testKey,
) => PersonalizationCapabilityDescriptor(
  id: id,
  scene: scene,
  label: label,
  effect: PersonalizationControlEffect.previewOnly,
  testKey: testKey,
);

PersonalizationCapabilityDescriptor _navigation(
  String id,
  PersonalizationStudioScene scene,
  String label,
  String testKey,
) => PersonalizationCapabilityDescriptor(
  id: id,
  scene: scene,
  label: label,
  effect: PersonalizationControlEffect.navigation,
  testKey: testKey,
);

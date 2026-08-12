import 'personalization_capability_descriptor.dart';
import 'personalization_preview_surface_descriptor.dart';

final class PersonalizationCapabilityRegistry {
  PersonalizationCapabilityRegistry(
    Iterable<PersonalizationCapabilityDescriptor> descriptors,
  ) : descriptors = List.unmodifiable(descriptors) {
    final byId = <String, PersonalizationCapabilityDescriptor>{};
    final byControlKey =
        <
          (PersonalizationStudioScene, String),
          PersonalizationCapabilityDescriptor
        >{};
    for (final descriptor in this.descriptors) {
      if (byId.containsKey(descriptor.id)) {
        throw ArgumentError.value(descriptor.id, 'descriptors');
      }
      byId[descriptor.id] = descriptor;
      for (final controlKey in descriptor.testKeys) {
        final scopedKey = (descriptor.scene, controlKey);
        if (byControlKey.containsKey(scopedKey)) {
          throw ArgumentError.value(controlKey, 'descriptors');
        }
        byControlKey[scopedKey] = descriptor;
      }
    }
    _byId = Map.unmodifiable(byId);
    _byControlKey = Map.unmodifiable(byControlKey);
  }

  final List<PersonalizationCapabilityDescriptor> descriptors;
  late final Map<String, PersonalizationCapabilityDescriptor> _byId;
  late final Map<
    (PersonalizationStudioScene, String),
    PersonalizationCapabilityDescriptor
  >
  _byControlKey;

  Set<String> get ids => Set.unmodifiable(_byId.keys);
  Set<String> get controlKeys =>
      Set.unmodifiable(_byControlKey.keys.map((entry) => entry.$2).toSet());

  PersonalizationCapabilityDescriptor require(String id) =>
      _byId[id] ?? (throw StateError('Unknown personalization control: $id'));

  PersonalizationCapabilityDescriptor requireByControlKey(
    String controlKey, {
    PersonalizationStudioScene? scene,
  }) {
    if (scene != null) {
      return _byControlKey[(scene, controlKey)] ??
          (throw StateError(
            'Unknown personalization control key: $controlKey',
          ));
    }
    final matches = _byControlKey.entries
        .where((entry) => entry.key.$2 == controlKey)
        .map((entry) => entry.value)
        .toList(growable: false);
    if (matches.length == 1) return matches.single;
    if (matches.isEmpty) {
      throw StateError('Unknown personalization control key: $controlKey');
    }
    throw StateError('Ambiguous personalization control key: $controlKey');
  }

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

final personalizationCapabilityRegistry = PersonalizationCapabilityRegistry(
  <PersonalizationCapabilityDescriptor>[
    _local(
      'preview.viewport',
      PersonalizationStudioScene.globalStyle,
      'Format de l’aperçu',
      'personalization-preview-viewport-landscape',
      additionalTestKeys: const <String>{
        'personalization-preview-viewport-portrait',
      },
    ),
    _local(
      'preview.textScale',
      PersonalizationStudioScene.globalStyle,
      'Taille du texte de test',
      'personalization-preview-text-scale-100',
      additionalTestKeys: const <String>{
        'personalization-preview-text-scale-150',
        'personalization-preview-text-scale-200',
      },
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
      additionalProjectPaths: const <String>{'/presentation/surfacePalettes'},
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
      additionalProjectPaths: const <String>{'/presentation/title'},
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
      'pause.actions',
      PersonalizationStudioScene.pause,
      'Contenu et actions du menu Pause',
      '/presentation/pause',
      'RuntimePlayerPauseShell',
      'pause-action-label-pokedex',
      additionalProjectPaths: const <String>{'/presentation/menuLabels'},
    ),
    _project(
      'dialogue.geometry',
      PersonalizationStudioScene.dialogue,
      'Géométrie du dialogue',
      '/presentation/dialogue',
      'PlayerDialogueSurface',
      'dialogue-geometry-placement-bottom',
      additionalProjectPaths: const <String>{'/presentation/layouts/dialogue'},
    ),
    _project(
      'dialogue.colors',
      PersonalizationStudioScene.dialogue,
      'Couleurs du dialogue',
      '/presentation/dialogue',
      'PlayerDialogueSurface',
      'dialogue-color-surface',
    ),
    _project(
      'dialogue.portrait',
      PersonalizationStudioScene.dialogue,
      'Portrait du dialogue',
      '/presentation/dialogue',
      'PlayerDialogueSurface',
      'dialogue-portrait-size',
    ),
    _project(
      'dialogue.nameplate',
      PersonalizationStudioScene.dialogue,
      'Cartouche du nom',
      '/presentation/dialogue',
      'PlayerDialogueSurface',
      'dialogue-nameplate-style',
    ),
    _project(
      'dialogue.choices',
      PersonalizationStudioScene.dialogue,
      'Choix du dialogue',
      '/presentation/dialogue',
      'PlayerDialogueSurface',
      'dialogue-choice-shape',
    ),
    _project(
      'dialogue.progress',
      PersonalizationStudioScene.dialogue,
      'Indicateur du dialogue',
      '/presentation/dialogue',
      'PlayerDialogueSurface',
      'dialogue-progress-kind',
    ),
    _project(
      'dialogue.motion',
      PersonalizationStudioScene.dialogue,
      'Transition du portrait',
      '/presentation/dialogue',
      'PlayerDialogueSurface',
      'dialogue-motion-transition',
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
      'battle.commands',
      PersonalizationStudioScene.battle,
      'Commandes de combat',
      '/presentation/battle/commands',
      'PlayerBattleSurface',
      'battle-commands-editor',
    ),
    _project(
      'battle.hud',
      PersonalizationStudioScene.battle,
      'HUD et points de vie',
      '/presentation/battle',
      'PlayerBattleSurface',
      'battle-hud-editor',
    ),
    _project(
      'battle.moves',
      PersonalizationStudioScene.battle,
      'Panneau des capacités',
      '/presentation/battle/moves',
      'PlayerBattleSurface',
      'battle-moves-editor',
    ),
    _project(
      'battle.target',
      PersonalizationStudioScene.battle,
      'Panneau de cible',
      '/presentation/battle/target',
      'PlayerBattleSurface',
      'battle-target-editor',
    ),
    _project(
      'battle.message',
      PersonalizationStudioScene.battle,
      'Panneau de message',
      '/presentation/battle/message',
      'PlayerBattleSurface',
      'battle-message-editor',
    ),
    _project(
      'battle.layout',
      PersonalizationStudioScene.battle,
      'Disposition du combat',
      '/presentation/layouts/battle',
      'PlayerBattleScene',
      'battle-preset-classic',
    ),
    _project(
      'battle.windows',
      PersonalizationStudioScene.battle,
      'Fenêtre de combat',
      '/presentation/windows',
      'PlayerBattleScene',
      'window-field-fill',
    ),
    _project(
      'battle.typography',
      PersonalizationStudioScene.battle,
      'Typographie de combat',
      '/presentation/typography',
      'PlayerBattleScene',
      'typography-import-combat',
    ),
  ],
);

PersonalizationCapabilityDescriptor _project(
  String id,
  PersonalizationStudioScene scene,
  String label,
  String projectPath,
  String runtimeSurface,
  String testKey, {
  Set<String> additionalProjectPaths = const <String>{},
}) => PersonalizationCapabilityDescriptor(
  id: id,
  scene: scene,
  label: label,
  effect: PersonalizationControlEffect.project,
  projectPath: projectPath,
  additionalProjectPaths: additionalProjectPaths,
  runtimeSurface: runtimeSurface,
  testKey: testKey,
);

PersonalizationCapabilityDescriptor _local(
  String id,
  PersonalizationStudioScene scene,
  String label,
  String testKey, {
  Set<String> additionalTestKeys = const <String>{},
}) => PersonalizationCapabilityDescriptor(
  id: id,
  scene: scene,
  label: label,
  effect: PersonalizationControlEffect.previewOnly,
  testKey: testKey,
  additionalTestKeys: additionalTestKeys,
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

import 'package:map_core/map_core.dart';

import 'personalization_preview_surface_descriptor.dart';
import 'project_presentation_presets.dart';

final class PersonalizationScenePresetTransaction {
  const PersonalizationScenePresetTransaction({
    required this.profile,
    required this.replacedSections,
    required this.removedAssetPaths,
    required this.requiresConfirmation,
  });

  final ProjectPresentationProfile profile;
  final Set<String> replacedSections;
  final Set<String> removedAssetPaths;
  final bool requiresConfirmation;
}

final class PersonalizationScenePreset {
  const PersonalizationScenePreset({
    required this.id,
    required this.label,
    required this.scene,
    required this.replacedSections,
    required this.apply,
  });

  final String id;
  final String label;
  final PersonalizationStudioScene scene;
  final Set<String> replacedSections;
  final ProjectPresentationProfile Function(ProjectPresentationProfile current)
  apply;

  PersonalizationScenePresetTransaction preview(
    ProjectPresentationProfile current,
  ) {
    final next = apply(current);
    return PersonalizationScenePresetTransaction(
      profile: next,
      replacedSections: replacedSections,
      removedAssetPaths: const <String>{},
      requiresConfirmation: next != current,
    );
  }
}

List<PersonalizationScenePreset> personalizationScenePresetsFor(
  PersonalizationStudioScene scene,
) => List<PersonalizationScenePreset>.unmodifiable(
  _scenePresets.where((preset) => preset.scene == scene),
);

ProjectPresentationProfile copyGlobalStyleToScene({
  required PersonalizationStudioScene scene,
  required ProjectPresentationProfile current,
}) {
  if (scene == PersonalizationStudioScene.globalStyle) return current;
  final palettes = current.surfacePalettes;
  final windows = current.windows;
  final typography = current.typography;
  return current.copyWith(
    surfacePalettes: palettes == null
        ? null
        : switch (scene) {
            PersonalizationStudioScene.title => palettes.copyWith(title: null),
            PersonalizationStudioScene.pause => palettes.copyWith(
              pauseMenu: null,
            ),
            PersonalizationStudioScene.dialogue => palettes.copyWith(
              dialogue: null,
            ),
            PersonalizationStudioScene.battle => palettes.copyWith(
              battle: null,
            ),
            _ => palettes,
          },
    typography: typography == null
        ? null
        : switch (scene) {
            PersonalizationStudioScene.dialogue => typography.copyWith(
              dialogue: typography.body,
            ),
            PersonalizationStudioScene.battle => typography.copyWith(
              combat: typography.body,
            ),
            _ => typography,
          },
    windows: windows == null
        ? null
        : switch (scene) {
            PersonalizationStudioScene.pause => windows.copyWith(
              pauseMenuStyleId: windows.defaultStyleId,
            ),
            PersonalizationStudioScene.dialogue => windows.copyWith(
              dialogueStyleId: windows.defaultStyleId,
            ),
            PersonalizationStudioScene.battle => windows.copyWith(
              battleStyleId: windows.defaultStyleId,
            ),
            _ => windows,
          },
  );
}

ProjectPresentationProfile resetPersonalizationScene(
  ProjectPresentationProfile current,
  PersonalizationStudioScene scene,
) => switch (scene) {
  PersonalizationStudioScene.globalStyle => current.copyWith(
    theme: null,
    surfacePalettes: null,
    typography: null,
    windows: null,
  ),
  PersonalizationStudioScene.title => current.copyWith(
    title: null,
    titleMotion: null,
    layouts: _resetLayout(current.layouts, scene),
  ),
  PersonalizationStudioScene.intro => current.copyWith(intro: null),
  PersonalizationStudioScene.pause => current.copyWith(
    pause: null,
    menuLabels: null,
    layouts: _resetLayout(current.layouts, scene),
  ),
  PersonalizationStudioScene.dialogue => current.copyWith(
    dialogue: null,
    layouts: _resetLayout(current.layouts, scene),
  ),
  PersonalizationStudioScene.battle => current.copyWith(
    battle: null,
    layouts: _resetLayout(current.layouts, scene),
  ),
};

ProjectPresentationLayoutsProfile? _resetLayout(
  ProjectPresentationLayoutsProfile? layouts,
  PersonalizationStudioScene scene,
) {
  if (layouts == null) return null;
  final suggested = suggestedProjectPresentationLayouts('standard');
  return switch (scene) {
    PersonalizationStudioScene.title => layouts.copyWith(
      title: suggested.title,
    ),
    PersonalizationStudioScene.pause => layouts.copyWith(
      pauseMenu: suggested.pauseMenu,
    ),
    PersonalizationStudioScene.dialogue => layouts.copyWith(
      dialogue: suggested.dialogue,
    ),
    PersonalizationStudioScene.battle => layouts.copyWith(
      battle: suggested.battle,
    ),
    _ => layouts,
  };
}

ProjectPresentationProfile _applyLayoutPreset(
  ProjectPresentationProfile current,
  PersonalizationStudioScene scene,
  String variant, {
  ProjectPresentationLayoutSlot? titleSlot,
}) {
  final currentLayouts =
      current.layouts ??
      suggestedProjectPresentationLayouts(current.branding.layoutVariant);
  final suggested = suggestedProjectPresentationLayouts(variant);
  return current.copyWith(
    layouts: switch (scene) {
      PersonalizationStudioScene.title => currentLayouts.copyWith(
        title: titleSlot == null
            ? suggested.title
            : suggested.title.copyWith(
                regular: suggested.title.regular.copyWith(slot: titleSlot),
                expanded: suggested.title.expanded.copyWith(slot: titleSlot),
              ),
      ),
      PersonalizationStudioScene.pause => currentLayouts.copyWith(
        pauseMenu: suggested.pauseMenu,
      ),
      PersonalizationStudioScene.dialogue => currentLayouts.copyWith(
        dialogue: suggested.dialogue,
      ),
      PersonalizationStudioScene.battle => currentLayouts.copyWith(
        battle: suggested.battle,
      ),
      _ => currentLayouts,
    },
  );
}

final _scenePresets = <PersonalizationScenePreset>[
  for (final preset in projectPresentationPresets)
    PersonalizationScenePreset(
      id: 'global-${preset.id}',
      label: preset.label,
      scene: PersonalizationStudioScene.globalStyle,
      replacedSections: const <String>{
        'theme',
        'surfacePalettes',
        'typography',
        'windows',
      },
      apply: (current) => applyProjectPresentationPresetScope(
        current: current,
        preset: preset.profile,
        scope: ProjectPresentationPresetScope.globalStyle,
      ),
    ),
  for (final id in const <String>['classic', 'cinematic', 'sidebar'])
    PersonalizationScenePreset(
      id: 'title-$id',
      label: switch (id) {
        'classic' => 'Classique',
        'cinematic' => 'Cinématique',
        _ => 'Volet latéral',
      },
      scene: PersonalizationStudioScene.title,
      replacedSections: const <String>{'title', 'layouts.title'},
      apply: (current) => _applyLayoutPreset(
        current,
        PersonalizationStudioScene.title,
        id == 'cinematic' ? 'cinematic' : 'standard',
        titleSlot: id == 'sidebar'
            ? ProjectPresentationLayoutSlot.leftPane
            : id == 'classic'
            ? ProjectPresentationLayoutSlot.center
            : null,
      ),
    ),
  PersonalizationScenePreset(
    id: 'intro-immersive',
    label: 'Immersive',
    scene: PersonalizationStudioScene.intro,
    replacedSections: const <String>{'intro'},
    apply: (current) => current.intro == null
        ? current
        : current.copyWith(
            intro: current.intro!.copyWith(
              reducedMotionBehavior: 'poster',
              allowReplay: true,
            ),
          ),
  ),
  PersonalizationScenePreset(
    id: 'intro-poster',
    label: 'Poster',
    scene: PersonalizationStudioScene.intro,
    replacedSections: const <String>{'intro'},
    apply: (current) => current.intro == null
        ? current
        : current.copyWith(
            intro: current.intro!.copyWith(
              reducedMotionBehavior: 'poster',
              allowReplay: false,
            ),
          ),
  ),
  PersonalizationScenePreset(
    id: 'intro-direct',
    label: 'Passage direct',
    scene: PersonalizationStudioScene.intro,
    replacedSections: const <String>{'intro'},
    apply: (current) => current.intro == null
        ? current
        : current.copyWith(
            intro: current.intro!.copyWith(
              reducedMotionBehavior: 'skip',
              allowReplay: false,
            ),
          ),
  ),
  for (final id in const <String>['adaptive', 'centered', 'sidebar'])
    PersonalizationScenePreset(
      id: 'pause-$id',
      label: switch (id) {
        'adaptive' => 'Adaptatif',
        'centered' => 'Centré',
        _ => 'Volet latéral',
      },
      scene: PersonalizationStudioScene.pause,
      replacedSections: const <String>{'pause', 'layouts.pauseMenu'},
      apply: (current) {
        final base = _applyLayoutPreset(
          current,
          PersonalizationStudioScene.pause,
          'standard',
        );
        final layouts = base.layouts!;
        final pause = layouts.pauseMenu;
        return base.copyWith(
          layouts: layouts.copyWith(
            pauseMenu: switch (id) {
              'centered' => pause.copyWith(
                regular: pause.regular.copyWith(
                  slot: ProjectPresentationLayoutSlot.center,
                ),
                expanded: pause.expanded.copyWith(
                  slot: ProjectPresentationLayoutSlot.center,
                ),
              ),
              'sidebar' => pause.copyWith(
                regular: pause.regular.copyWith(
                  slot: ProjectPresentationLayoutSlot.left,
                  width: ProjectPresentationContentWidth.narrow,
                ),
                expanded: pause.expanded.copyWith(
                  slot: ProjectPresentationLayoutSlot.right,
                  width: ProjectPresentationContentWidth.narrow,
                ),
              ),
              _ => pause,
            },
          ),
        );
      },
    ),
  for (final id in const <String>['bottom', 'wide', 'top'])
    PersonalizationScenePreset(
      id: 'dialogue-$id',
      label: switch (id) {
        'bottom' => 'Bas',
        'wide' => 'Large',
        _ => 'Haut',
      },
      scene: PersonalizationStudioScene.dialogue,
      replacedSections: const <String>{'dialogue', 'layouts.dialogue'},
      apply: (current) {
        final positioned = current.copyWith(
          dialogue:
              (current.dialogue ?? const ProjectDialoguePresentationProfile())
                  .copyWith(
                    placement: id == 'top'
                        ? ProjectDialoguePlacement.top
                        : ProjectDialoguePlacement.bottom,
                    maxWidthFactor: id == 'wide' ? .94 : .82,
                  ),
        );
        return _applyLayoutPreset(
          positioned,
          PersonalizationStudioScene.dialogue,
          'standard',
        );
      },
    ),
  for (final id in const <String>['classic', 'compact', 'cinematic'])
    PersonalizationScenePreset(
      id: 'battle-$id',
      label: switch (id) {
        'classic' => 'Classique',
        'compact' => 'Compact',
        _ => 'Cinématique',
      },
      scene: PersonalizationStudioScene.battle,
      replacedSections: const <String>{'battle', 'layouts.battle'},
      apply: (current) {
        final base = _applyLayoutPreset(
          current,
          PersonalizationStudioScene.battle,
          'standard',
        );
        final layouts = base.layouts!;
        final battle = layouts.battle!;
        return base.copyWith(
          battle: (base.battle ?? const ProjectBattlePresentationProfile())
              .copyWith(
                commandLayout: id == 'cinematic'
                    ? ProjectBattleCommandLayout.radial
                    : ProjectBattleCommandLayout.grid,
              ),
          layouts: layouts.copyWith(
            battle: id == 'compact'
                ? battle.copyWith(
                    compact: battle.compact.copyWith(
                      width: ProjectPresentationContentWidth.narrow,
                      screenMargin: ProjectPresentationScreenMargin.none,
                    ),
                  )
                : battle,
          ),
        );
      },
    ),
];

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/personalization_character_preview_source.dart';
import '../personalization_surface_color_editor.dart';
import '../project_typography_editor.dart';
import '../project_window_studio.dart';

class PersonalizationDialogueInspector extends StatelessWidget {
  const PersonalizationDialogueInspector({
    super.key,
    required this.profile,
    required this.characterOptions,
    required this.selectedCharacterId,
    required this.showPortrait,
    required this.showName,
    required this.showChoices,
    required this.onCharacterSelected,
    required this.onShowPortraitChanged,
    required this.onShowNameChanged,
    required this.onShowChoicesChanged,
    required this.onWindowsChanged,
    required this.onLayoutsChanged,
    required this.onImportDialogueFont,
    required this.onUseSystemDialogueFont,
    this.onDialogueMetricsChanged,
    this.onSurfacePalettesChanged,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
  });

  final ProjectPresentationProfile profile;
  final List<PersonalizationCharacterPreviewOption> characterOptions;
  final String? selectedCharacterId;
  final bool showPortrait;
  final bool showName;
  final bool showChoices;
  final ValueChanged<String> onCharacterSelected;
  final ValueChanged<bool> onShowPortraitChanged;
  final ValueChanged<bool> onShowNameChanged;
  final ValueChanged<bool> onShowChoicesChanged;
  final ValueChanged<ProjectPresentationWindowsProfile?> onWindowsChanged;
  final ValueChanged<ProjectPresentationLayoutsProfile?> onLayoutsChanged;
  final VoidCallback onImportDialogueFont;
  final VoidCallback onUseSystemDialogueFont;
  final ValueChanged<ProjectTypographyMetricsProfile>? onDialogueMetricsChanged;
  final ValueChanged<ProjectPresentationSurfacePalettesProfile?>?
  onSurfacePalettesChanged;
  final Map<ProjectTypographyRole, String> previewFamilies;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('personalization-dialogue-inspector'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Disposition',
        description: 'Choisissez où la bulle apparaît à l’écran.',
      ),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _placementButton(
              id: 'bottom',
              label: 'Bas',
              slot: ProjectPresentationLayoutSlot.bottomCenter,
            ),
            _placementButton(
              id: 'top',
              label: 'Haut',
              slot: ProjectPresentationLayoutSlot.topCenter,
            ),
            _placementButton(
              id: 'center',
              label: 'Centrée',
              slot: ProjectPresentationLayoutSlot.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      ProjectWindowStudio(
        profile: profile.windows ?? legacyProjectPresentationWindows,
        fixedRole: ProjectWindowRole.dialogue,
        onChanged: onWindowsChanged,
      ),
      const SizedBox(height: 18),
      PersonalizationSurfaceColorEditor(
        role: ProjectPresentationSurfaceRole.dialogue,
        palette: personalizationSurfacePalette(
          profile.surfacePalettes,
          ProjectPresentationSurfaceRole.dialogue,
        ),
        inheritedTheme: profile.theme ?? safeProjectSemanticTheme,
        onChanged: (palette) => onSurfacePalettesChanged?.call(
          replacePersonalizationSurfacePalette(
            profile.surfacePalettes,
            ProjectPresentationSurfaceRole.dialogue,
            palette,
          ),
        ),
      ),
      const SizedBox(height: 18),
      ProjectTypographyEditor(
        profile: profile.typography ?? const ProjectTypographyProfile(),
        previewFamilies: previewFamilies,
        fixedRole: ProjectTypographyRole.dialogue,
        onImportRole: (_) => onImportDialogueFont(),
        onUseSystemFont: (_) => onUseSystemDialogueFont(),
        onMetricsChanged: onDialogueMetricsChanged == null
            ? null
            : (_, metrics) => onDialogueMetricsChanged!(metrics),
      ),
      const SizedBox(height: 18),
      const PokeMapSectionHeader(
        title: 'Contenu de test',
        description:
            'Ces options modifient uniquement l’aperçu, jamais les données du jeu.',
      ),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (characterOptions.isNotEmpty) ...<Widget>[
              PokeMapDropdownField<String>(
                key: const ValueKey<String>('dialogue-preview-character'),
                label: 'Personnage de test',
                value: _resolvedCharacterId,
                items: <PokeMapDropdownItem<String>>[
                  for (final option in characterOptions)
                    PokeMapDropdownItem<String>(
                      value: option.characterId,
                      label: option.displayName,
                    ),
                ],
                onChanged: onCharacterSelected,
              ),
              const SizedBox(height: 8),
            ],
            PokeMapToggleTile(
              key: const ValueKey<String>('dialogue-preview-portrait'),
              label: 'Portrait',
              value: showPortrait,
              onChanged: onShowPortraitChanged,
            ),
            PokeMapToggleTile(
              key: const ValueKey<String>('dialogue-preview-name'),
              label: 'Nom du personnage',
              value: showName,
              onChanged: onShowNameChanged,
            ),
            PokeMapToggleTile(
              key: const ValueKey<String>('dialogue-preview-choices'),
              label: 'Choix de réponse',
              value: showChoices,
              onChanged: onShowChoicesChanged,
            ),
          ],
        ),
      ),
    ],
  );

  String get _resolvedCharacterId {
    if (characterOptions.any(
      (option) => option.characterId == selectedCharacterId,
    )) {
      return selectedCharacterId!;
    }
    return characterOptions.first.characterId;
  }

  Widget _placementButton({
    required String id,
    required String label,
    required ProjectPresentationLayoutSlot slot,
  }) {
    final layouts =
        profile.layouts ??
        suggestedProjectPresentationLayouts(profile.branding.layoutVariant);
    return PokeMapButton(
      key: ValueKey<String>('dialogue-layout-$id'),
      size: PokeMapButtonSize.small,
      variant: PokeMapButtonVariant.secondary,
      isSelected: layouts.dialogue.regular.slot == slot,
      onPressed: () {
        final dialogue = layouts.dialogue;
        onLayoutsChanged(
          layouts.copyWith(
            dialogue: dialogue.copyWith(
              compact: dialogue.compact.copyWith(slot: slot),
              regular: dialogue.regular.copyWith(slot: slot),
              expanded: dialogue.expanded.copyWith(slot: slot),
            ),
          ),
        );
      },
      child: Text(label),
    );
  }
}

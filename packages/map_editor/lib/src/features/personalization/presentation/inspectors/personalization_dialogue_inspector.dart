import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/personalization_character_preview_source.dart';
import '../project_theme_token_dialog.dart';
import '../project_typography_editor.dart';

class PersonalizationDialogueInspector extends StatelessWidget {
  static const capabilityIds = <String>{
    'dialogue.geometry',
    'dialogue.colors',
    'dialogue.portrait',
    'dialogue.nameplate',
    'dialogue.typography',
    'dialogue.previewCharacter',
    'dialogue.previewPortrait',
    'dialogue.previewName',
    'dialogue.previewChoices',
  };

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
    required this.onDialogueChanged,
    required this.onImportDialogueFont,
    required this.onUseSystemDialogueFont,
    this.onDialogueMetricsChanged,
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
  final ValueChanged<ProjectDialoguePresentationProfile?> onDialogueChanged;
  final VoidCallback onImportDialogueFont;
  final VoidCallback onUseSystemDialogueFont;
  final ValueChanged<ProjectTypographyMetricsProfile>? onDialogueMetricsChanged;
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
              placement: ProjectDialoguePlacement.bottom,
            ),
            _placementButton(
              id: 'top',
              label: 'Haut',
              placement: ProjectDialoguePlacement.top,
            ),
            _placementButton(
              id: 'center',
              label: 'Centrée',
              placement: ProjectDialoguePlacement.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _geometryEditor(context),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: PokeMapButton(
          key: const ValueKey<String>('dialogue-geometry-reset'),
          size: PokeMapButtonSize.small,
          variant: PokeMapButtonVariant.secondary,
          onPressed: profile.dialogue == null
              ? null
              : () => onDialogueChanged(null),
          leading: const Icon(Icons.restart_alt_rounded),
          child: const Text('Réutiliser le style global'),
        ),
      ),
      const SizedBox(height: 18),
      _portraitEditor(context),
      const SizedBox(height: 18),
      _nameplateEditor(context),
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
                label: 'Personnage et expression de test',
                value: _resolvedCharacterId,
                items: <PokeMapDropdownItem<String>>[
                  for (final option in characterOptions)
                    PokeMapDropdownItem<String>(
                      value: option.id,
                      label: option.pickerLabel,
                    ),
                ],
                onChanged: onCharacterSelected,
              ),
              if (!_resolvedCharacter.isReady) ...<Widget>[
                const SizedBox(height: 8),
                const PokeMapDiagnosticCallout(
                  severity: PokeMapDiagnosticSeverity.warning,
                  message:
                      'Ce portrait est incomplet dans Character Studio. '
                      'La prévisualisation utilise un remplacement neutre.',
                ),
              ],
              const SizedBox(height: 8),
            ] else ...<Widget>[
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.warning,
                message:
                    'Aucun personnage n’est disponible. Créez-en un dans '
                    'Character Studio pour tester un portrait.',
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
    if (characterOptions.any((option) => option.id == selectedCharacterId)) {
      return selectedCharacterId!;
    }
    return characterOptions.first.id;
  }

  Widget _portraitEditor(BuildContext context) {
    final dialogue =
        profile.dialogue ?? const ProjectDialoguePresentationProfile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Portrait',
          description: 'Placez et encadrez le portrait du personnage.',
        ),
        const SizedBox(height: 8),
        PokeMapCard(
          key: const ValueKey<String>('dialogue-portrait-editor'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final side in ProjectDialoguePortraitSide.values)
                    PokeMapButton(
                      key: ValueKey<String>(
                        'dialogue-portrait-side-${side.name}',
                      ),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: dialogue.portraitSide == side,
                      onPressed: () => onDialogueChanged(
                        dialogue.copyWith(portraitSide: side),
                      ),
                      child: Text(
                        side == ProjectDialoguePortraitSide.start
                            ? 'À gauche'
                            : 'À droite',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              PokeMapDropdownField<ProjectDialoguePortraitShape>(
                key: const ValueKey<String>('dialogue-portrait-shape'),
                label: 'Forme du portrait',
                value: dialogue.portraitShape,
                items:
                    const <PokeMapDropdownItem<ProjectDialoguePortraitShape>>[
                      PokeMapDropdownItem(
                        value: ProjectDialoguePortraitShape.circle,
                        label: 'Cercle',
                      ),
                      PokeMapDropdownItem(
                        value: ProjectDialoguePortraitShape.rounded,
                        label: 'Arrondi',
                      ),
                      PokeMapDropdownItem(
                        value: ProjectDialoguePortraitShape.square,
                        label: 'Carré',
                      ),
                      PokeMapDropdownItem(
                        value: ProjectDialoguePortraitShape.cutCorner,
                        label: 'Angles coupés',
                      ),
                    ],
                onChanged: (shape) =>
                    onDialogueChanged(dialogue.copyWith(portraitShape: shape)),
              ),
              const SizedBox(height: 12),
              PokeMapGuidedSlider(
                key: const ValueKey<String>('dialogue-portrait-size'),
                label: 'Taille du portrait',
                min: 48,
                max: 160,
                value: dialogue.portraitSize.round(),
                onChanged: (value) => onDialogueChanged(
                  dialogue.copyWith(portraitSize: value.toDouble()),
                ),
              ),
              const SizedBox(height: 12),
              PokeMapGuidedSlider(
                key: const ValueKey<String>('dialogue-portrait-frame-width'),
                label: 'Épaisseur du cadre',
                min: 0,
                max: 8,
                value: dialogue.portraitFrameWidth.round(),
                onChanged: (value) => onDialogueChanged(
                  dialogue.copyWith(portraitFrameWidth: value.toDouble()),
                ),
              ),
              const SizedBox(height: 12),
              _colorControl(context, dialogue, _DialogueColor.portraitFrame),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nameplateEditor(BuildContext context) {
    final dialogue =
        profile.dialogue ?? const ProjectDialoguePresentationProfile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Nom du personnage',
          description: 'Choisissez la présentation du cartouche du nom.',
        ),
        const SizedBox(height: 8),
        PokeMapCard(
          key: const ValueKey<String>('dialogue-nameplate-editor'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PokeMapDropdownField<ProjectDialogueNameplateStyle>(
                key: const ValueKey<String>('dialogue-nameplate-style'),
                label: 'Style du cartouche',
                value: dialogue.nameplateStyle,
                items:
                    const <PokeMapDropdownItem<ProjectDialogueNameplateStyle>>[
                      PokeMapDropdownItem(
                        value: ProjectDialogueNameplateStyle.inline,
                        label: 'Texte simple',
                      ),
                      PokeMapDropdownItem(
                        value: ProjectDialogueNameplateStyle.badge,
                        label: 'Cartouche',
                      ),
                      PokeMapDropdownItem(
                        value: ProjectDialogueNameplateStyle.floating,
                        label: 'Cartouche flottant',
                      ),
                    ],
                onChanged: (style) =>
                    onDialogueChanged(dialogue.copyWith(nameplateStyle: style)),
              ),
              const SizedBox(height: 12),
              PokeMapGuidedSlider(
                key: const ValueKey<String>('dialogue-nameplate-border-width'),
                label: 'Épaisseur du contour',
                min: 0,
                max: 6,
                value: dialogue.nameplateBorderWidth.round(),
                onChanged: (value) => onDialogueChanged(
                  dialogue.copyWith(nameplateBorderWidth: value.toDouble()),
                ),
              ),
              const SizedBox(height: 12),
              for (final color in const <_DialogueColor>[
                _DialogueColor.nameplateSurface,
                _DialogueColor.nameplateBorder,
                _DialogueColor.nameplateText,
              ]) ...<Widget>[
                _colorControl(context, dialogue, color),
                if (color != _DialogueColor.nameplateText)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  PersonalizationCharacterPreviewOption get _resolvedCharacter =>
      characterOptions.firstWhere(
        (option) => option.id == _resolvedCharacterId,
      );

  Widget _geometryEditor(BuildContext context) {
    final dialogue =
        profile.dialogue ?? const ProjectDialoguePresentationProfile();
    return PokeMapCard(
      key: const ValueKey<String>('dialogue-geometry-editor'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapDropdownField<ProjectWindowShape>(
            key: const ValueKey<String>('dialogue-geometry-shape'),
            label: 'Forme de la bulle',
            value: dialogue.shape,
            items: const <PokeMapDropdownItem<ProjectWindowShape>>[
              PokeMapDropdownItem(
                value: ProjectWindowShape.rounded,
                label: 'Arrondie',
              ),
              PokeMapDropdownItem(
                value: ProjectWindowShape.rectangle,
                label: 'Rectangulaire',
              ),
              PokeMapDropdownItem(
                value: ProjectWindowShape.cutCorner,
                label: 'Angles coupés',
              ),
              PokeMapDropdownItem(
                value: ProjectWindowShape.speech,
                label: 'Bulle avec pointe',
              ),
            ],
            onChanged: (shape) =>
                onDialogueChanged(dialogue.copyWith(shape: shape)),
          ),
          const SizedBox(height: 12),
          PokeMapGuidedSlider(
            key: const ValueKey<String>('dialogue-geometry-width'),
            label: 'Largeur',
            description: 'Part de l’écran occupée par la bulle.',
            min: 40,
            max: 96,
            value: (dialogue.maxWidthFactor * 100).round(),
            onChanged: (value) => onDialogueChanged(
              dialogue.copyWith(maxWidthFactor: value / 100),
            ),
          ),
          const SizedBox(height: 12),
          PokeMapGuidedSlider(
            key: const ValueKey<String>('dialogue-geometry-margin'),
            label: 'Marge écran',
            min: 0,
            max: 64,
            value: dialogue.margin.round(),
            onChanged: (value) =>
                onDialogueChanged(dialogue.copyWith(margin: value.toDouble())),
          ),
          const SizedBox(height: 12),
          PokeMapGuidedSlider(
            key: const ValueKey<String>('dialogue-geometry-padding'),
            label: 'Espace intérieur',
            min: 8,
            max: 48,
            value: dialogue.contentPadding.round(),
            onChanged: (value) => onDialogueChanged(
              dialogue.copyWith(contentPadding: value.toDouble()),
            ),
          ),
          const SizedBox(height: 12),
          PokeMapGuidedSlider(
            key: const ValueKey<String>('dialogue-geometry-radius'),
            label: 'Arrondi',
            min: 0,
            max: 40,
            value: dialogue.cornerRadius.round(),
            onChanged: (value) => onDialogueChanged(
              dialogue.copyWith(cornerRadius: value.toDouble()),
            ),
          ),
          const SizedBox(height: 12),
          PokeMapGuidedSlider(
            key: const ValueKey<String>('dialogue-geometry-border'),
            label: 'Épaisseur du contour',
            min: 0,
            max: 8,
            value: dialogue.borderWidth.round(),
            onChanged: (value) => onDialogueChanged(
              dialogue.copyWith(borderWidth: value.toDouble()),
            ),
          ),
          const SizedBox(height: 12),
          PokeMapGuidedSlider(
            key: const ValueKey<String>('dialogue-geometry-opacity'),
            label: 'Opacité',
            min: 40,
            max: 100,
            value: (dialogue.fillOpacity * 100).round(),
            onChanged: (value) =>
                onDialogueChanged(dialogue.copyWith(fillOpacity: value / 100)),
          ),
          const SizedBox(height: 16),
          for (final color in const <_DialogueColor>[
            _DialogueColor.surface,
            _DialogueColor.border,
            _DialogueColor.text,
          ]) ...<Widget>[
            _colorControl(context, dialogue, color),
            if (color != _DialogueColor.text) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _colorControl(
    BuildContext context,
    ProjectDialoguePresentationProfile dialogue,
    _DialogueColor color,
  ) {
    final value = _resolvedColor(dialogue, color);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _colorLabel(color),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              PokeMapBadge(label: value),
            ],
          ),
        ),
        PokeMapButton(
          key: ValueKey<String>('dialogue-color-${color.name}'),
          size: PokeMapButtonSize.small,
          variant: PokeMapButtonVariant.secondary,
          onPressed: () => _editColor(context, dialogue, color, value),
          leading: const Icon(Icons.palette_outlined),
          child: const Text('Modifier'),
        ),
      ],
    );
  }

  Future<void> _editColor(
    BuildContext context,
    ProjectDialoguePresentationProfile dialogue,
    _DialogueColor color,
    String currentValue,
  ) async {
    final value = await showProjectThemeTokenDialog(
      context: context,
      tokenLabel: _colorLabel(color).toLowerCase(),
      currentValue: currentValue,
      impactDescription: 'Cette couleur affectera la bulle de dialogue.',
      validator: (candidate) {
        final updated = _replaceColor(dialogue, color, candidate);
        final invalid =
            validateProjectPresentationProfile(
              profile.copyWith(dialogue: updated),
            ).any(
              (diagnostic) =>
                  diagnostic.severity ==
                      ProjectPresentationDiagnosticSeverity.error &&
                  diagnostic.path.contains('.dialogue.'),
            );
        return invalid ? 'Cette couleur n’est pas valide.' : null;
      },
    );
    if (value == null || value == currentValue) return;
    onDialogueChanged(_replaceColor(dialogue, color, value));
  }

  String _resolvedColor(
    ProjectDialoguePresentationProfile dialogue,
    _DialogueColor color,
  ) {
    final theme = profile.theme ?? safeProjectSemanticTheme;
    final palette = profile.surfacePalettes?.resolve(
      ProjectPresentationSurfaceRole.dialogue,
    );
    return switch (color) {
      _DialogueColor.surface =>
        dialogue.surfaceColor ?? palette?.surface ?? theme.dialogueSurface,
      _DialogueColor.border =>
        dialogue.borderColor ?? palette?.border ?? theme.outline,
      _DialogueColor.text =>
        dialogue.textColor ?? palette?.text ?? theme.textPrimary,
      _DialogueColor.portraitFrame =>
        dialogue.portraitFrameColor ?? palette?.border ?? theme.outline,
      _DialogueColor.nameplateSurface =>
        dialogue.nameplateSurfaceColor ?? theme.surfaceElevated,
      _DialogueColor.nameplateBorder =>
        dialogue.nameplateBorderColor ?? palette?.border ?? theme.outline,
      _DialogueColor.nameplateText =>
        dialogue.nameplateTextColor ?? theme.primary,
    };
  }

  ProjectDialoguePresentationProfile _replaceColor(
    ProjectDialoguePresentationProfile dialogue,
    _DialogueColor color,
    String value,
  ) => switch (color) {
    _DialogueColor.surface => dialogue.copyWith(surfaceColor: value),
    _DialogueColor.border => dialogue.copyWith(borderColor: value),
    _DialogueColor.text => dialogue.copyWith(textColor: value),
    _DialogueColor.portraitFrame => dialogue.copyWith(
      portraitFrameColor: value,
    ),
    _DialogueColor.nameplateSurface => dialogue.copyWith(
      nameplateSurfaceColor: value,
    ),
    _DialogueColor.nameplateBorder => dialogue.copyWith(
      nameplateBorderColor: value,
    ),
    _DialogueColor.nameplateText => dialogue.copyWith(
      nameplateTextColor: value,
    ),
  };

  Widget _placementButton({
    required String id,
    required String label,
    required ProjectDialoguePlacement placement,
  }) {
    final dialogue =
        profile.dialogue ?? const ProjectDialoguePresentationProfile();
    return PokeMapButton(
      key: ValueKey<String>('dialogue-layout-$id'),
      size: PokeMapButtonSize.small,
      variant: PokeMapButtonVariant.secondary,
      isSelected: dialogue.placement == placement,
      onPressed: () =>
          onDialogueChanged(dialogue.copyWith(placement: placement)),
      child: Text(label),
    );
  }
}

enum _DialogueColor {
  surface,
  border,
  text,
  portraitFrame,
  nameplateSurface,
  nameplateBorder,
  nameplateText,
}

String _colorLabel(_DialogueColor color) => switch (color) {
  _DialogueColor.surface => 'Fond de la bulle',
  _DialogueColor.border => 'Contour',
  _DialogueColor.text => 'Texte',
  _DialogueColor.portraitFrame => 'Cadre du portrait',
  _DialogueColor.nameplateSurface => 'Fond du cartouche',
  _DialogueColor.nameplateBorder => 'Contour du cartouche',
  _DialogueColor.nameplateText => 'Texte du cartouche',
};

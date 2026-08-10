import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/project_branding_image_import_service.dart';
import '../../application/project_title_motion_import_service.dart';
import '../project_branding_editor.dart';
import '../project_title_motion_editor.dart';

enum PersonalizationTitlePreset { centered, left, cinematic }

class PersonalizationTitleInspector extends StatelessWidget {
  const PersonalizationTitleInspector({
    super.key,
    required this.profile,
    required this.projectName,
    required this.projectRootPath,
    required this.onChanged,
    required this.onImportImage,
    required this.onRemoveImage,
    required this.onEditAccent,
    required this.onResetAccent,
    required this.onImportTitleMusic,
    required this.onToggleTitleMusicPreview,
    required this.onRemoveTitleMusic,
    required this.onImportMotion,
    required this.onRemoveMotion,
    this.isTitleMusicPreviewPlaying = false,
  });

  final ProjectPresentationProfile profile;
  final String projectName;
  final String projectRootPath;
  final ValueChanged<ProjectPresentationProfile> onChanged;
  final ValueChanged<ProjectBrandingImageRole> onImportImage;
  final ValueChanged<ProjectBrandingImageRole> onRemoveImage;
  final VoidCallback onEditAccent;
  final VoidCallback onResetAccent;
  final VoidCallback onImportTitleMusic;
  final VoidCallback? onToggleTitleMusicPreview;
  final VoidCallback? onRemoveTitleMusic;
  final ValueChanged<ProjectTitleMotionLoopRole> onImportMotion;
  final ValueChanged<ProjectTitleMotionLoopRole> onRemoveMotion;
  final bool isTitleMusicPreviewPlaying;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('personalization-title-inspector'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Composition de l’écran titre',
        description:
            'Choisissez une base lisible, puis ajustez les images, la couleur, '
            'la musique et les animations.',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _presetButton(
            preset: PersonalizationTitlePreset.centered,
            label: 'Centrée',
            icon: Icons.align_horizontal_center_rounded,
          ),
          _presetButton(
            preset: PersonalizationTitlePreset.left,
            label: 'À gauche',
            icon: Icons.align_horizontal_left_rounded,
          ),
          _presetButton(
            preset: PersonalizationTitlePreset.cinematic,
            label: 'Cinématique',
            icon: Icons.movie_filter_outlined,
          ),
        ],
      ),
      const SizedBox(height: 18),
      ProjectBrandingEditor(
        profile: profile.branding,
        projectName: projectName,
        projectRootPath: projectRootPath,
        theme: profile.theme ?? safeProjectSemanticTheme,
        typography: profile.typography,
        onImportImage: onImportImage,
        onRemoveImage: onRemoveImage,
        onEditAccent: onEditAccent,
        onResetAccent: onResetAccent,
        onLayoutVariantChanged: (layoutVariant) => onChanged(
          profile.copyWith(
            branding: profile.branding.copyWith(layoutVariant: layoutVariant),
          ),
        ),
        onImportTitleMusic: onImportTitleMusic,
        onToggleTitleMusicPreview: onToggleTitleMusicPreview,
        onRemoveTitleMusic: onRemoveTitleMusic,
        isTitleMusicPreviewPlaying: isTitleMusicPreviewPlaying,
        showPreview: false,
      ),
      const SizedBox(height: 18),
      ProjectTitleMotionEditor(
        profile: profile.titleMotion,
        onImport: onImportMotion,
        onRemove: onRemoveMotion,
      ),
    ],
  );

  Widget _presetButton({
    required PersonalizationTitlePreset preset,
    required String label,
    required IconData icon,
  }) => PokeMapButton(
    key: ValueKey<String>('title-preset-${preset.name}'),
    size: PokeMapButtonSize.small,
    variant: PokeMapButtonVariant.secondary,
    isSelected: _selectedPreset == preset,
    leading: Icon(icon),
    onPressed: () => onChanged(_applyPreset(profile, preset)),
    child: Text(label),
  );

  PersonalizationTitlePreset get _selectedPreset {
    final title = profile.layouts?.title;
    if (title?.regular.slot == ProjectPresentationLayoutSlot.leftPane) {
      return PersonalizationTitlePreset.left;
    }
    if (profile.branding.layoutVariant == 'cinematic' ||
        title?.regular.slot == ProjectPresentationLayoutSlot.bottomLeft) {
      return PersonalizationTitlePreset.cinematic;
    }
    return PersonalizationTitlePreset.centered;
  }
}

ProjectPresentationProfile _applyPreset(
  ProjectPresentationProfile profile,
  PersonalizationTitlePreset preset,
) {
  final layouts =
      profile.layouts ??
      suggestedProjectPresentationLayouts(profile.branding.layoutVariant);
  final standard = suggestedProjectPresentationLayouts('standard').title;
  final title = switch (preset) {
    PersonalizationTitlePreset.centered => standard,
    PersonalizationTitlePreset.left => standard.copyWith(
      regular: standard.regular.copyWith(
        slot: ProjectPresentationLayoutSlot.leftPane,
      ),
      expanded: standard.expanded.copyWith(
        slot: ProjectPresentationLayoutSlot.leftPane,
      ),
    ),
    PersonalizationTitlePreset.cinematic => suggestedProjectPresentationLayouts(
      'cinematic',
    ).title,
  };
  final brandingLayout = switch (preset) {
    PersonalizationTitlePreset.centered => 'centered',
    PersonalizationTitlePreset.left => 'standard',
    PersonalizationTitlePreset.cinematic => 'cinematic',
  };
  return profile.copyWith(
    branding: profile.branding.copyWith(layoutVariant: brandingLayout),
    layouts: layouts.copyWith(title: title),
  );
}

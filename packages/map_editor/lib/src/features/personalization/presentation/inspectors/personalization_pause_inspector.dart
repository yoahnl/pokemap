import '../../../../ui/design_system/pokemap_button.dart';
import '../../../../ui/design_system/pokemap_dropdown_field.dart';
import '../../../../ui/design_system/pokemap_guided_slider.dart';
import '../../../../ui/design_system/pokemap_card.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../project_layout_studio.dart';
import '../project_pause_actions_editor.dart';
import '../personalization_surface_color_editor.dart';
import '../personalization_deferred_commit.dart';
import '../project_typography_editor.dart';
import '../project_window_studio.dart';

class PersonalizationPauseInspector extends StatelessWidget {
  static const capabilityIds = <String>{
    'pause.layout',
    'pause.windows',
    'pause.typography',
    'pause.actions',
  };

  const PersonalizationPauseInspector({
    super.key,
    required this.profile,
    required this.onPauseChanged,
    required this.onWindowsChanged,
    required this.onLayoutsChanged,
    required this.onImportBodyFont,
    required this.onUseSystemBodyFont,
    this.onPausePreviewChanged,
    this.onImportBackground,
    this.onBackgroundChanged,
    this.onStyleChanged,
    this.commitCoordinator,
    this.onBodyMetricsChanged,
    this.onSurfacePalettesChanged,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
  });

  final ProjectPresentationProfile profile;
  final VoidCallback? onImportBackground;
  final ValueChanged<ProjectPauseBackgroundProfile?>? onBackgroundChanged;
  final ValueChanged<ProjectPauseMenuStyle>? onStyleChanged;
  final ValueChanged<ProjectPausePresentationProfile?> onPauseChanged;
  final ValueChanged<ProjectPausePresentationProfile?>? onPausePreviewChanged;
  final PersonalizationDeferredCommitCoordinator? commitCoordinator;
  final ValueChanged<ProjectPresentationWindowsProfile?> onWindowsChanged;
  final ValueChanged<ProjectPresentationLayoutsProfile?> onLayoutsChanged;
  final VoidCallback onImportBodyFont;
  final VoidCallback onUseSystemBodyFont;
  final ValueChanged<ProjectTypographyMetricsProfile>? onBodyMetricsChanged;
  final ValueChanged<ProjectPresentationSurfacePalettesProfile?>?
  onSurfacePalettesChanged;
  final Map<ProjectTypographyRole, String> previewFamilies;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('personalization-pause-inspector'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      PokeMapCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapDropdownField<ProjectPauseMenuStyle>(
              label: 'Style du menu',
              value: profile.pause?.style ?? ProjectPauseMenuStyle.standard,
              enabled: onStyleChanged != null,
              items: const [
                PokeMapDropdownItem(
                  value: ProjectPauseMenuStyle.standard,
                  label: 'Standard',
                ),
                PokeMapDropdownItem(
                  value: ProjectPauseMenuStyle.nightIllustrated,
                  label: 'Nuit illustrée',
                ),
              ],
              onChanged: (style) => onStyleChanged?.call(style),
            ),
            const SizedBox(height: 8),
            PokeMapButton(
              key: const ValueKey('pause-import-background'),
              onPressed: onImportBackground,
              child: const Text('Choisir le fond du menu'),
            ),
            if (profile.pause?.background case final background?) ...[
              const SizedBox(height: 8),
              PokeMapGuidedSlider(
                label: 'Cadrage horizontal',
                value: (background.focalX * 100).round(),
                onChanged: (value) => onBackgroundChanged?.call(
                  background.copyWith(focalX: value / 100),
                ),
              ),
              PokeMapGuidedSlider(
                label: 'Cadrage vertical',
                value: (background.focalY * 100).round(),
                onChanged: (value) => onBackgroundChanged?.call(
                  background.copyWith(focalY: value / 100),
                ),
              ),
              PokeMapDropdownField<ProjectMenuImageSampling>(
                label: 'Style de l’image',
                value: background.sampling,
                items: const [
                  PokeMapDropdownItem(
                    value: ProjectMenuImageSampling.smooth,
                    label: 'Illustration',
                  ),
                  PokeMapDropdownItem(
                    value: ProjectMenuImageSampling.pixelArt,
                    label: 'Pixel art',
                  ),
                ],
                onChanged: (sampling) => onBackgroundChanged?.call(
                  background.copyWith(sampling: sampling),
                ),
              ),
              PokeMapButton(
                key: const ValueKey('pause-remove-background'),
                variant: PokeMapButtonVariant.ghost,
                onPressed: () => onBackgroundChanged?.call(null),
                child: const Text('Retirer le fond'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      ProjectLayoutStudio(
        profile: profile.layouts,
        brandingLayoutVariant: profile.branding.layoutVariant,
        fixedSurfaceRole: ProjectPresentationSurfaceRole.pauseMenu,
        simplePresetsOnly: true,
        onChanged: onLayoutsChanged,
      ),
      const SizedBox(height: 18),
      ProjectWindowStudio(
        profile: profile.windows ?? legacyProjectPresentationWindows,
        fixedRole: ProjectWindowRole.pauseMenu,
        onChanged: onWindowsChanged,
      ),
      const SizedBox(height: 18),
      PersonalizationSurfaceColorEditor(
        role: ProjectPresentationSurfaceRole.pauseMenu,
        palette: personalizationSurfacePalette(
          profile.surfacePalettes,
          ProjectPresentationSurfaceRole.pauseMenu,
        ),
        inheritedTheme: profile.theme ?? safeProjectSemanticTheme,
        onChanged: (palette) => onSurfacePalettesChanged?.call(
          replacePersonalizationSurfacePalette(
            profile.surfacePalettes,
            ProjectPresentationSurfaceRole.pauseMenu,
            palette,
          ),
        ),
      ),
      const SizedBox(height: 18),
      ProjectTypographyEditor(
        profile: profile.typography ?? const ProjectTypographyProfile(),
        previewFamilies: previewFamilies,
        fixedRole: ProjectTypographyRole.body,
        onImportRole: (_) => onImportBodyFont(),
        onUseSystemFont: (_) => onUseSystemBodyFont(),
        onMetricsChanged: onBodyMetricsChanged == null
            ? null
            : (_, metrics) => onBodyMetricsChanged!(metrics),
      ),
      const SizedBox(height: 18),
      ProjectPauseActionsEditor(
        profile:
            profile.effectivePause ?? const ProjectPausePresentationProfile(),
        onChanged: onPauseChanged,
        onPreviewChanged: onPausePreviewChanged,
        commitCoordinator: commitCoordinator,
      ),
    ],
  );
}

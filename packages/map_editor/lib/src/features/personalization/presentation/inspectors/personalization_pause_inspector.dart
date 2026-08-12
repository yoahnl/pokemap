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
    this.commitCoordinator,
    this.onBodyMetricsChanged,
    this.onSurfacePalettesChanged,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
  });

  final ProjectPresentationProfile profile;
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

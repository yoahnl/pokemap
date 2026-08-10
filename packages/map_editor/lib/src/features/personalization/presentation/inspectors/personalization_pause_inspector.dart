import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../project_layout_studio.dart';
import '../project_menu_labels_editor.dart';
import '../project_typography_editor.dart';
import '../project_window_studio.dart';

class PersonalizationPauseInspector extends StatelessWidget {
  const PersonalizationPauseInspector({
    super.key,
    required this.profile,
    required this.onMenuLabelsChanged,
    required this.onWindowsChanged,
    required this.onLayoutsChanged,
    required this.onImportCommonFont,
    required this.onUseSystemCommonFont,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
  });

  final ProjectPresentationProfile profile;
  final ValueChanged<ProjectMenuLabelsProfile?> onMenuLabelsChanged;
  final ValueChanged<ProjectPresentationWindowsProfile?> onWindowsChanged;
  final ValueChanged<ProjectPresentationLayoutsProfile?> onLayoutsChanged;
  final VoidCallback onImportCommonFont;
  final VoidCallback onUseSystemCommonFont;
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
      ProjectTypographyEditor(
        profile: profile.typography ?? const ProjectTypographyProfile(),
        previewFamilies: previewFamilies,
        commonOnly: true,
        onImportRole: (_) {},
        onUseSystemFont: (_) {},
        onImportCommonFont: onImportCommonFont,
        onUseSystemCommonFont: onUseSystemCommonFont,
      ),
      const SizedBox(height: 18),
      ProjectMenuLabelsEditor(
        profile: profile.menuLabels ?? const ProjectMenuLabelsProfile(),
        onChanged: onMenuLabelsChanged,
      ),
    ],
  );
}

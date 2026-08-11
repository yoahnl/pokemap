import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../project_semantic_theme_editor.dart';
import '../project_typography_editor.dart';
import '../project_window_studio.dart';

enum PersonalizationGlobalStyleSection { colors, forms, typography }

class PersonalizationGlobalStyleInspector extends StatelessWidget {
  const PersonalizationGlobalStyleInspector({
    super.key,
    required this.profile,
    required this.section,
    required this.onEditAccent,
    required this.onEditThemeToken,
    required this.onUseSafeFallback,
    required this.onWindowsChanged,
    required this.onImportCommonFont,
    required this.onUseSystemCommonFont,
    this.onCommonMetricsChanged,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
  });

  final ProjectPresentationProfile profile;
  final PersonalizationGlobalStyleSection section;
  final VoidCallback onEditAccent;
  final ProjectThemeTokenSelection onEditThemeToken;
  final VoidCallback onUseSafeFallback;
  final ValueChanged<ProjectPresentationWindowsProfile?> onWindowsChanged;
  final VoidCallback onImportCommonFont;
  final VoidCallback onUseSystemCommonFont;
  final ValueChanged<ProjectTypographyMetricsProfile>? onCommonMetricsChanged;
  final Map<ProjectTypographyRole, String> previewFamilies;

  @override
  Widget build(BuildContext context) {
    final theme = profile.theme ?? safeProjectSemanticTheme;
    final diagnostics = validateProjectSemanticTheme(theme);
    final blocked = diagnostics.any(
      (diagnostic) =>
          diagnostic.severity == ProjectPresentationDiagnosticSeverity.error,
    );
    return Column(
      key: const ValueKey<String>('personalization-global-style-inspector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (section != PersonalizationGlobalStyleSection.colors) ...<Widget>[
          PokeMapDiagnosticCallout(
            key: const ValueKey<String>('global-style-contrast-gate'),
            severity: blocked
                ? PokeMapDiagnosticSeverity.error
                : PokeMapDiagnosticSeverity.info,
            message: blocked
                ? 'Corrigez les contrastes avant de pouvoir enregistrer.'
                : 'Les contrastes sont validés pour le player.',
          ),
          const SizedBox(height: 12),
        ],
        switch (section) {
          PersonalizationGlobalStyleSection.colors => _colors(theme),
          PersonalizationGlobalStyleSection.forms => ProjectWindowStudio(
            profile: profile.windows ?? legacyProjectPresentationWindows,
            simplePresetsOnly: true,
            onChanged: onWindowsChanged,
          ),
          PersonalizationGlobalStyleSection.typography =>
            ProjectTypographyEditor(
              profile: profile.typography ?? const ProjectTypographyProfile(),
              previewFamilies: previewFamilies,
              commonOnly: true,
              onImportRole: (_) {},
              onUseSystemFont: (_) {},
              onImportCommonFont: onImportCommonFont,
              onUseSystemCommonFont: onUseSystemCommonFont,
              onCommonMetricsChanged: onCommonMetricsChanged,
            ),
        },
      ],
    );
  }

  Widget _colors(ProjectSemanticThemeProfile theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      PokeMapCard(
        child: Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Accent',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PokeMapBadge(label: profile.branding.accentColor ?? theme.outline),
            const SizedBox(width: 8),
            PokeMapButton(
              key: const ValueKey<String>('global-style-color-accent'),
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              onPressed: onEditAccent,
              leading: const Icon(Icons.palette_outlined),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      ProjectSemanticThemeEditor(
        profile: theme,
        simple: true,
        onEditToken: onEditThemeToken,
        onUseSafeFallback: onUseSafeFallback,
      ),
    ],
  );
}

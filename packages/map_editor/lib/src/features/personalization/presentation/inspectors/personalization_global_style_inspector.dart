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
    required this.onSectionChanged,
    required this.onEditAccent,
    required this.onEditThemeToken,
    required this.onUseSafeFallback,
    required this.onWindowsChanged,
    required this.onImportCommonFont,
    required this.onUseSystemCommonFont,
    required this.onResetColors,
    required this.onResetWindows,
    required this.onResetTypography,
    this.onCommonMetricsChanged,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
  });

  final ProjectPresentationProfile profile;
  final PersonalizationGlobalStyleSection section;
  final ValueChanged<PersonalizationGlobalStyleSection> onSectionChanged;
  final VoidCallback onEditAccent;
  final ProjectThemeTokenSelection onEditThemeToken;
  final VoidCallback onUseSafeFallback;
  final ValueChanged<ProjectPresentationWindowsProfile?> onWindowsChanged;
  final VoidCallback onImportCommonFont;
  final VoidCallback onUseSystemCommonFont;
  final VoidCallback onResetColors;
  final VoidCallback onResetWindows;
  final VoidCallback onResetTypography;
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
        PokeMapSegmentedTabs(
          tabs: <PokeMapSegmentedTab>[
            _tab(
              section: PersonalizationGlobalStyleSection.colors,
              keyName: 'colors',
              label: 'Couleurs',
            ),
            _tab(
              section: PersonalizationGlobalStyleSection.forms,
              keyName: 'windows',
              label: 'Fenêtres',
            ),
            _tab(
              section: PersonalizationGlobalStyleSection.typography,
              keyName: 'typography',
              label: 'Typographie',
            ),
          ],
          minimumHeight: 36,
          expandTabs: true,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: ValueKey<String>('global-style-reset-${_sectionKey(section)}'),
            semanticLabel: _resetSemanticLabel(section),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.ghost,
            onPressed: _resetCallback(section),
            leading: const Icon(Icons.restart_alt_rounded),
            child: const Text('Réinitialiser cette section'),
          ),
        ),
        const SizedBox(height: 12),
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

  PokeMapSegmentedTab _tab({
    required PersonalizationGlobalStyleSection section,
    required String keyName,
    required String label,
  }) => PokeMapSegmentedTab(
    key: ValueKey<String>('global-style-tab-$keyName'),
    label: label,
    semanticLabel: 'Onglet $label',
    selected: this.section == section,
    onTap: () => onSectionChanged(section),
  );

  VoidCallback _resetCallback(PersonalizationGlobalStyleSection section) =>
      switch (section) {
        PersonalizationGlobalStyleSection.colors => onResetColors,
        PersonalizationGlobalStyleSection.forms => onResetWindows,
        PersonalizationGlobalStyleSection.typography => onResetTypography,
      };

  Widget _colors(ProjectSemanticThemeProfile theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      PokeMapCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final badge = PokeMapBadge(
              label: profile.branding.accentColor ?? theme.outline,
            );
            final button = PokeMapButton(
              key: const ValueKey<String>('global-style-color-accent'),
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              onPressed: onEditAccent,
              leading: const Icon(Icons.palette_outlined),
              child: const Text('Modifier'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Accent',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: badge),
                  const SizedBox(height: 8),
                  button,
                ],
              );
            }
            return Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Accent',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                badge,
                const SizedBox(width: 8),
                button,
              ],
            );
          },
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

String _sectionKey(PersonalizationGlobalStyleSection section) =>
    switch (section) {
      PersonalizationGlobalStyleSection.colors => 'colors',
      PersonalizationGlobalStyleSection.forms => 'windows',
      PersonalizationGlobalStyleSection.typography => 'typography',
    };

String _resetSemanticLabel(PersonalizationGlobalStyleSection section) =>
    switch (section) {
      PersonalizationGlobalStyleSection.colors => 'Réinitialiser les couleurs',
      PersonalizationGlobalStyleSection.forms => 'Réinitialiser les fenêtres',
      PersonalizationGlobalStyleSection.typography =>
        'Réinitialiser la typographie',
    };

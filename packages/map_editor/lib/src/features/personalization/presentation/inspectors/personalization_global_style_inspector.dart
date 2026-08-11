import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../project_semantic_theme_editor.dart';
import '../project_typography_editor.dart';
import '../project_window_studio.dart';

enum PersonalizationGlobalStyleSection { colors, forms, typography }

class PersonalizationGlobalStyleInspector extends StatefulWidget {
  static const capabilityIds = <String>{
    'global.colors',
    'global.windows',
    'global.typography',
  };

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
    this.onImportRole,
    this.onUseSystemFont,
    this.onMetricsChanged,
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
  final ValueChanged<ProjectTypographyRole>? onImportRole;
  final ValueChanged<ProjectTypographyRole>? onUseSystemFont;
  final ProjectTypographyMetricsChanged? onMetricsChanged;
  final Map<ProjectTypographyRole, String> previewFamilies;

  @override
  State<PersonalizationGlobalStyleInspector> createState() =>
      _PersonalizationGlobalStyleInspectorState();
}

class _PersonalizationGlobalStyleInspectorState
    extends State<PersonalizationGlobalStyleInspector> {
  bool _showMore = false;

  @override
  void didUpdateWidget(PersonalizationGlobalStyleInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _showMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final section = widget.section;
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
          alignment: Alignment.centerLeft,
          child: PokeMapButton(
            key: const ValueKey<String>('global-style-more-settings'),
            semanticLabel: _showMore
                ? 'Masquer les réglages avancés'
                : 'Afficher plus de réglages',
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            isSelected: _showMore,
            onPressed: () => setState(() => _showMore = !_showMore),
            leading: Icon(
              _showMore ? Icons.expand_less_rounded : Icons.tune_rounded,
            ),
            child: Text(_showMore ? 'Réglages essentiels' : 'Plus de réglages'),
          ),
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
            simplePresetsOnly: !_showMore,
            onChanged: widget.onWindowsChanged,
          ),
          PersonalizationGlobalStyleSection.typography =>
            ProjectTypographyEditor(
              profile: profile.typography ?? const ProjectTypographyProfile(),
              previewFamilies: widget.previewFamilies,
              commonOnly: !_showMore,
              onImportRole: (role) => widget.onImportRole?.call(role),
              onUseSystemFont: (role) => widget.onUseSystemFont?.call(role),
              onImportCommonFont: widget.onImportCommonFont,
              onUseSystemCommonFont: widget.onUseSystemCommonFont,
              onMetricsChanged: widget.onMetricsChanged,
              onCommonMetricsChanged: widget.onCommonMetricsChanged,
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
    selected: widget.section == section,
    onTap: () => widget.onSectionChanged(section),
  );

  VoidCallback _resetCallback(PersonalizationGlobalStyleSection section) =>
      switch (section) {
        PersonalizationGlobalStyleSection.colors => widget.onResetColors,
        PersonalizationGlobalStyleSection.forms => widget.onResetWindows,
        PersonalizationGlobalStyleSection.typography =>
          widget.onResetTypography,
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
              label: widget.profile.branding.accentColor ?? theme.outline,
            );
            final button = PokeMapButton(
              key: const ValueKey<String>('global-style-color-accent'),
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              onPressed: widget.onEditAccent,
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
        simple: !_showMore,
        onEditToken: widget.onEditThemeToken,
        onUseSafeFallback: widget.onUseSafeFallback,
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

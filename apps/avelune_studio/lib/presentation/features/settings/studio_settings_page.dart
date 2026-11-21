import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/localization/studio_locale.dart';
import 'studio_ai_settings.dart';
import 'studio_general_settings.dart';

enum _SettingsSection { overview, general, display, ai }

class StudioSettingsPage extends StatefulWidget {
  const StudioSettingsPage({super.key});

  @override
  State<StudioSettingsPage> createState() => _StudioSettingsPageState();
}

class _StudioSettingsPageState extends State<StudioSettingsPage> {
  var _section = _SettingsSection.overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sections = {
      _SettingsSection.overview: (l10n.studioSettingsOverview, Icons.grid_view),
      _SettingsSection.general: (l10n.studioSettingsGeneral, Icons.language),
      _SettingsSection.display: (
        l10n.studioSettingsDisplay,
        Icons.monitor_outlined,
      ),
      _SettingsSection.ai: (l10n.studioSettingsAi, Icons.key_outlined),
    };
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxWidth < 610;
        final navigation = [
          for (final entry in sections.entries)
            StudioNavigationEntry(
              key: ValueKey('studio-settings-${entry.key.name}-nav'),
              label: entry.value.$1,
              icon: entry.value.$2,
              compact: compact,
              selected: _section == entry.key,
              onTap: () => setState(() => _section = entry.key),
            ),
        ];
        final content = SingleChildScrollView(
          key: ValueKey(_section),
          padding: const EdgeInsets.all(StudioSpacing.xxl),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: _content(context),
            ),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(StudioSpacing.s),
                child: Row(children: navigation),
              ),
              const Divider(height: 1),
              Expanded(child: content),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioSidebar(
              width: 220,
              child: ListView(
                primary: false,
                padding: const EdgeInsets.all(StudioSpacing.s),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(StudioSpacing.m),
                    child: Text(
                      l10n.studioSettings,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  ...navigation,
                ],
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final overview = _section == _SettingsSection.overview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.studioSettings, style: theme.textTheme.headlineSmall),
        const SizedBox(height: StudioSpacing.s),
        Text(l10n.studioSettingsDevice, style: theme.textTheme.bodySmall),
        const SizedBox(height: StudioSpacing.xxl),
        if (overview || _section == _SettingsSection.general)
          const StudioLanguageSettings(),
        if (overview) const SizedBox(height: StudioSpacing.xl),
        if (overview || _section == _SettingsSection.display)
          const StudioDisplaySettings(),
        if (overview) const SizedBox(height: StudioSpacing.xl),
        if (overview || _section == _SettingsSection.ai)
          const StudioAiSettings(),
      ],
    );
  }
}

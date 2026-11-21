import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/localization/studio_locale.dart';
import '../../shared/widgets/avelune_studio_brand.dart';
import '../../shell/studio_rail.dart';
import 'studio_ai_settings.dart';
import 'studio_general_settings.dart';

Future<StudioRailSection?> openStudioSettings(
  BuildContext context, {
  StudioRailSection? returnTo,
}) => Navigator.of(context).push(
  MaterialPageRoute<StudioRailSection>(
    builder: (_) => StudioSettingsPage(returnTo: returnTo),
  ),
);

enum _SettingsSection { overview, general, display, ai }

class StudioSettingsPage extends StatefulWidget {
  const StudioSettingsPage({super.key, this.returnTo});

  final StudioRailSection? returnTo;

  @override
  State<StudioSettingsPage> createState() => _StudioSettingsPageState();
}

class _StudioSettingsPageState extends State<StudioSettingsPage> {
  var _section = _SettingsSection.overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final compactBrand = MediaQuery.sizeOf(context).width < 420;
    final routes = {
      _SettingsSection.overview: (l10n.studioSettingsOverview, Icons.grid_view),
      _SettingsSection.general: (l10n.studioSettingsGeneral, Icons.language),
      _SettingsSection.display: (
        l10n.studioSettingsDisplay,
        Icons.monitor_outlined,
      ),
      _SettingsSection.ai: (l10n.studioSettingsAi, Icons.key_outlined),
    };
    return Scaffold(
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.xl),
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AveluneStudioBrand(compact: compactBrand),
                    StudioButton(
                      key: const ValueKey('studio-settings-back'),
                      label: l10n.studioSettingsBack,
                      icon: Icons.arrow_back,
                      secondary: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.returnTo != null)
                  StudioRail(
                    section: StudioRailSection.settings,
                    sectionAction: (section) =>
                        () => Navigator.of(context).pop(section),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final compact = bounds.maxWidth < 610;
                      final navigation = [
                        for (final entry in routes.entries)
                          StudioNavigationEntry(
                            key: ValueKey(
                              'studio-settings-${entry.key.name}-nav',
                            ),
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
                                  padding: const EdgeInsets.all(
                                    StudioSpacing.m,
                                  ),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

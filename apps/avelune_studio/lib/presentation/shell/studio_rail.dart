import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

const studioRailWidth = 64.0;

enum StudioRailSection { map, story }

class StudioRail extends StatelessWidget {
  const StudioRail({
    super.key,
    required this.onHome,
    this.section = StudioRailSection.map,
    this.onSection,
  });

  final VoidCallback onHome;
  final StudioRailSection section;
  final ValueChanged<StudioRailSection>? onSection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Ink(
      key: const ValueKey('studio-rail'),
      width: studioRailWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(vertical: StudioSpacing.l),
      child: Column(
        children: [
          _RailEntry(
            label: l10n.railHome,
            icon: Icons.home_outlined,
            onPressed: onHome,
          ),
          _RailEntry(
            key: const ValueKey('studio-rail-map'),
            label: l10n.railMapBuilder,
            icon: Icons.map_outlined,
            selected: section == StudioRailSection.map,
            onPressed: _open(StudioRailSection.map),
          ),
          _RailEntry(label: l10n.railRegionalMap, icon: Icons.explore_outlined),
          _RailEntry(
            label: l10n.railResources,
            icon: Icons.view_in_ar_outlined,
          ),
          _RailEntry(
            key: const ValueKey('studio-rail-story'),
            label: l10n.railStory,
            icon: Icons.menu_book_outlined,
            selected: section == StudioRailSection.story,
            onPressed: _open(StudioRailSection.story),
          ),
          const Spacer(),
          _RailEntry(label: l10n.railHelp, icon: Icons.help_outline),
          _RailEntry(label: l10n.railProjectSettings, icon: Icons.tune),
        ],
      ),
    );
  }

  VoidCallback? _open(StudioRailSection target) {
    final open = onSection;
    return open == null ? null : () => open(target);
  }
}

class _RailEntry extends StatelessWidget {
  const _RailEntry({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = selected || onPressed != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
      child: Tooltip(
        message: available
            ? label
            : context.l10n.notAvailableInNewStudio(label),
        child: Semantics(
          button: true,
          selected: selected,
          enabled: available,
          label: label,
          child: Material(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
              onTap: selected ? null : onPressed,
              child: SizedBox.square(
                dimension: 40,
                child: Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? scheme.onPrimary
                      : available
                      ? scheme.onSurfaceVariant
                      : scheme.onSurfaceVariant.withValues(alpha: .38),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

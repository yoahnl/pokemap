import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

const studioRailWidth = 64.0;
const _unavailable = 'Pas encore disponible dans le nouveau Studio';

class StudioRail extends StatelessWidget {
  const StudioRail({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            label: 'Accueil du projet',
            icon: Icons.home_outlined,
            onPressed: onHome,
          ),
          const _RailEntry(
            label: 'Constructeur de carte',
            icon: Icons.map_outlined,
            selected: true,
          ),
          const _RailEntry(
            label: 'Carte régionale',
            icon: Icons.explore_outlined,
          ),
          const _RailEntry(
            label: 'Gérer les ressources',
            icon: Icons.view_in_ar_outlined,
          ),
          const _RailEntry(label: 'Histoire', icon: Icons.menu_book_outlined),
          const Spacer(),
          const _RailEntry(
            label: 'Raccourcis et aide',
            icon: Icons.help_outline,
          ),
          const _RailEntry(label: 'Réglages du projet', icon: Icons.tune),
        ],
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  const _RailEntry({
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
        message: available ? label : '$label — $_unavailable',
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

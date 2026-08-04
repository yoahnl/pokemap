import 'package:flutter/material.dart';

import '../hub_dashboard_controller.dart';
import 'avelune_theme.dart';

class AveluneBottomNavigation extends StatelessWidget {
  const AveluneBottomNavigation({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final HubSection selectedSection;
  final ValueChanged<HubSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    return Material(
      color: colors.background,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outline)),
          ),
          child: SizedBox(
            height: 66,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _AveluneDestination(
                    key: const ValueKey<String>('avelune-nav-home'),
                    label: french ? 'Accueil' : 'Home',
                    icon: Icons.home_rounded,
                    selected: selectedSection != HubSection.preferences,
                    onPressed: () => onSectionSelected(HubSection.home),
                  ),
                ),
                Expanded(
                  child: _AveluneDestination(
                    key: const ValueKey<String>('avelune-nav-settings'),
                    label: french ? 'Paramètres' : 'Settings',
                    icon: Icons.settings_rounded,
                    selected: selectedSection == HubSection.preferences,
                    onPressed: () => onSectionSelected(HubSection.preferences),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AveluneDestination extends StatelessWidget {
  const _AveluneDestination({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final foreground = selected ? colors.primaryBright : colors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: foreground, size: 23),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryBright,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colors.glow.withValues(alpha: 0.62),
                          blurRadius: 7,
                        ),
                      ],
                    ),
                    child: const SizedBox(width: 54, height: 3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

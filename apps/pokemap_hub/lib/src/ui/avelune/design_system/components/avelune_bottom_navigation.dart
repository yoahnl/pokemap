import 'package:flutter/material.dart';

import '../foundation/avelune_shape_tokens.dart';
import '../foundation/avelune_spacing_tokens.dart';
import '../theme/avelune_theme_extensions.dart';
import 'avelune_pressable.dart';

enum AveluneNavigationItem { home, settings }

class AveluneBottomNavigation extends StatelessWidget {
  const AveluneBottomNavigation({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  final AveluneNavigationItem selectedItem;
  final ValueChanged<AveluneNavigationItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    return Material(
      color: colors.canvas,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outline)),
          ),
          child: SizedBox(
            height: AveluneShapes.minimumTouchTarget + AveluneSpacing.lg,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _AveluneDestination(
                    key: const ValueKey<String>('avelune-nav-home'),
                    label: french ? 'Accueil' : 'Home',
                    icon: Icons.home_rounded,
                    selected: selectedItem == AveluneNavigationItem.home,
                    onPressed: () => onItemSelected(AveluneNavigationItem.home),
                  ),
                ),
                Expanded(
                  child: _AveluneDestination(
                    key: const ValueKey<String>('avelune-nav-settings'),
                    label: french ? 'Paramètres' : 'Settings',
                    icon: Icons.settings_rounded,
                    selected: selectedItem == AveluneNavigationItem.settings,
                    onPressed: () =>
                        onItemSelected(AveluneNavigationItem.settings),
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
    final foreground = selected ? colors.accentBright : colors.textSecondary;
    return AvelunePressable(
      semanticLabel: label,
      selected: selected,
      selectedOutline: false,
      onPressed: onPressed,
      borderRadius: AveluneShapes.xs,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AveluneShapes.minimumTouchTarget,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: foreground, size: 23),
                const SizedBox(height: AveluneSpacing.xxs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.accentBright,
                    borderRadius: AveluneShapes.pill,
                    boxShadow: context.aveluneDepth.selectedGlow,
                  ),
                  child: const SizedBox(width: 54, height: 3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../foundation/avelune_glass_tokens.dart';
import '../foundation/avelune_shape_tokens.dart';
import '../foundation/avelune_spacing_tokens.dart';
import '../theme/avelune_theme_extensions.dart';
import 'avelune_glass_surface.dart';
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
    final french = Localizations.localeOf(context).languageCode == 'fr';
    // The approved prototype floats an inset capsule over the room instead of
    // capping it with an opaque bar, so the credenza keeps reading all the way
    // to the bottom edge of the screen. The capsule is glass: it has the room
    // behind it, which is what gives a lens something to refract.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AveluneSpacing.xxl,
          0,
          AveluneSpacing.xxl,
          AveluneSpacing.xxs,
        ),
        child: AveluneGlassSurface(
          key: const ValueKey<String>('avelune-nav-pill'),
          cornerRadius: AveluneGlass.capsuleRadius,
          child: SizedBox(
            // Taller than the 48 minimum touch target so the capsule reads as
            // a deliberate surface, but still inside the band
            // AveluneHomeGeometry reserves for it above the recent activity.
            height: 56,
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AveluneSpacing.md,
                  ),
                  child: SizedBox(
                    width: 1,
                    child: ColoredBox(color: AveluneGlass.border),
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
            // The capsule is height-capped, so large text scales have to scale
            // down rather than overflow it.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: foreground, size: 21),
                  const SizedBox(height: AveluneSpacing.hairline),
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

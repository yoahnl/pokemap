import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_shape_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_spacing_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/theme/avelune_theme_extensions.dart';
import 'package:pokemap_hub/presentation/design_system/components/avelune_pressable.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_icon_tokens.dart';

enum AveluneNavigationItem { home, settings }

/// Navigation capsule integrated into the warm library sheet.
class AveluneBottomNavigation extends StatelessWidget {
  const AveluneBottomNavigation({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  final AveluneNavigationItem selectedItem;
  final ValueChanged<AveluneNavigationItem> onItemSelected;

  /// Height of the capsule body. Comfortably above the 48 minimum touch target
  /// so it reads as a surface rather than a strip of buttons.
  static const double capsuleHeight = 52;

  @override
  Widget build(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final colors = context.aveluneColors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AveluneSpacing.xxl,
          0,
          AveluneSpacing.xxl,
          AveluneSpacing.xxs,
        ),
        child: DecoratedBox(
          key: const ValueKey<String>('avelune-nav-pill'),
          decoration: BoxDecoration(
            borderRadius: AveluneShapes.pill,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                colors.ivoryHighlight.withValues(alpha: 0.98),
                colors.ivory.withValues(alpha: 0.96),
              ],
            ),
            border: Border.all(
              color: colors.ivoryHighlight.withValues(alpha: 0.9),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.canvas.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: DecoratedBox(
            key: const ValueKey<String>('avelune-nav-ivory-surface'),
            decoration: const BoxDecoration(borderRadius: AveluneShapes.pill),
            child: SizedBox(
              height: capsuleHeight,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _AveluneDestination(
                      key: const ValueKey<String>('avelune-nav-home'),
                      label: french ? 'Accueil' : 'Home',
                      icon: AveluneIcons.home,
                      selected: selectedItem == AveluneNavigationItem.home,
                      onPressed: () =>
                          onItemSelected(AveluneNavigationItem.home),
                    ),
                  ),
                  SizedBox(
                    width: 1,
                    height: 30,
                    child: ColoredBox(
                      color: colors.wood.withValues(alpha: 0.18),
                    ),
                  ),
                  Expanded(
                    child: _AveluneDestination(
                      key: const ValueKey<String>('avelune-nav-settings'),
                      label: french ? 'Paramètres' : 'Settings',
                      icon: AveluneIcons.settings,
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
    final motion = context.aveluneMotion;
    final foreground =
        selected ? colors.accent : colors.surfaceRaised.withValues(alpha: 0.52);

    return AvelunePressable(
      semanticLabel: label,
      selected: selected,
      selectedOutline: false,
      onPressed: onPressed,
      borderRadius: AveluneShapes.pill,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AveluneSpacing.sm,
          vertical: AveluneSpacing.xs,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icon, color: foreground, size: 21),
                      const SizedBox(width: AveluneSpacing.sm),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: foreground,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: motion.selection,
              curve: motion.movementCurve,
              width: selected ? 58 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: AveluneShapes.pill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

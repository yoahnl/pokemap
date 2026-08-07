import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_glass_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_shape_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_spacing_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/theme/avelune_theme_extensions.dart';
import 'package:pokemap_hub/presentation/design_system/components/avelune_glass_surface.dart';
import 'package:pokemap_hub/presentation/design_system/components/avelune_pressable.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_icon_tokens.dart';

enum AveluneNavigationItem { home, settings }

/// Floating glass capsule over the room.
///
/// It is deliberately lifted clear of the bottom edge and sits over the
/// credenza rather than over the dark strip that used to run beneath it. That is
/// not decoration: a lens can only show refraction when something is behind it,
/// and glass over near-black renders as a grey box — which is exactly how the
/// first attempt looked.
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
  static const double capsuleHeight = 62;

  @override
  Widget build(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AveluneSpacing.xxl,
          0,
          AveluneSpacing.xxl,
          AveluneSpacing.xl,
        ),
        child: AveluneGlassSurface(
          key: const ValueKey<String>('avelune-nav-pill'),
          cornerRadius: AveluneGlass.capsuleRadius,
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
                    onPressed: () => onItemSelected(AveluneNavigationItem.home),
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
    final foreground = selected ? colors.textPrimary : colors.textSecondary;

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
        child: AnimatedContainer(
          // The selected item gets its own lit capsule inside the glass rather
          // than an underline hanging off the bottom, so the indicator belongs
          // to the same material as the surface carrying it.
          duration: motion.selection,
          curve: motion.movementCurve,
          decoration: BoxDecoration(
            borderRadius: AveluneShapes.pill,
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      colors.accentBright.withValues(alpha: 0.34),
                      colors.accent.withValues(alpha: 0.16),
                    ],
                  )
                : null,
            border: Border.all(
              color: selected ? AveluneGlass.border : AveluneGlass.clear,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, color: foreground, size: 20),
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
      ),
    );
  }
}

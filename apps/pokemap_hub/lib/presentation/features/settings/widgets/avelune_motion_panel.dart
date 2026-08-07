import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';

/// Motion state of the console.
///
/// Read-only by design. Avelune follows the operating system's reduce-motion
/// accessibility setting, and there is no persisted local override yet, so this
/// reports the effective state and where it comes from rather than offering a
/// switch that would not survive a restart.
class AveluneMotionPanel extends StatelessWidget {
  const AveluneMotionPanel({super.key, required this.reducedMotion});

  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';

    return Column(
      key: const ValueKey<String>('avelune-motion-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              reducedMotion
                  ? AveluneIcons.motionReduced
                  : AveluneIcons.motionOn,
              size: 20,
              color: colors.accentBright,
            ),
            const SizedBox(width: AveluneSpacing.sm),
            Expanded(
              child: Text(
                aveluneMotionSummary(reducedMotion, french: french),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AveluneSpacing.md),
        Text(
          french
              ? 'Avelune suit le réglage d’accessibilité « Réduire les '
                  'animations » de votre appareil. Modifiez-le dans les '
                  'réglages système pour changer ce comportement.'
              : 'Avelune follows your device\'s "Reduce Motion" accessibility '
                  'setting. Change it in the system settings to alter this '
                  'behaviour.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// One-line description of the effective motion state, shared with the settings
/// sheet so the summary and the panel cannot disagree.
String aveluneMotionSummary(bool reducedMotion, {required bool french}) {
  if (reducedMotion) {
    return french ? 'Animations réduites' : 'Reduced animations';
  }
  return french ? 'Animations naturelles activées' : 'Natural animations on';
}

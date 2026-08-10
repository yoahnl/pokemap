import 'package:flutter/material.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';

/// Shown when the window is smaller than the console geometry supports.
class HubViewportTooSmall extends StatelessWidget {
  const HubViewportTooSmall({
    required this.minimumWidth,
    required this.minimumHeight,
  });

  final double minimumWidth;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    return ColoredBox(
      key: const ValueKey<String>('avelune-viewport-too-small'),
      color: colors.canvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AveluneSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                AveluneIcons.viewport,
                color: colors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: AveluneSpacing.md),
              Text(
                french ? 'Fenêtre trop petite' : 'Window too small',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AveluneSpacing.xs),
              Text(
                french
                    ? 'Agrandissez la fenêtre à au moins '
                        '${minimumWidth.toInt()} x ${minimumHeight.toInt()}.'
                    : 'Resize the window to at least '
                        '${minimumWidth.toInt()} x ${minimumHeight.toInt()}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

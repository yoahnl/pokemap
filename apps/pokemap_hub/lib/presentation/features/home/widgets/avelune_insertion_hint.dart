import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';

/// Arrow and wording the prototype places between the hero cartridge and the
/// console slot, telling the player the cartridge is meant to go down.
///
/// Purely informative: the hero cartridge itself carries the gesture and the
/// semantics, so this is hidden from assistive technology to avoid announcing
/// the same action twice.
class AveluneInsertionHint extends StatelessWidget {
  const AveluneInsertionHint({super.key, required this.action});

  final AvelunePrimaryAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    final label = switch (action) {
      AvelunePrimaryAction.continueGame =>
        french ? 'Touchez pour insérer' : 'Tap to insert',
      AvelunePrimaryAction.play =>
        french ? 'Touchez pour insérer' : 'Tap to insert',
      AvelunePrimaryAction.disabled => french ? 'Indisponible' : 'Unavailable',
    };

    return ExcludeSemantics(
      child: IgnorePointer(
        key: const ValueKey<String>('avelune-insertion-hint'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              AveluneIcons.insert,
              size: 15,
              color: colors.primaryBright.withValues(alpha: 0.9),
            ),
            const SizedBox(height: AveluneSpacing.hairline),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10.5,
                letterSpacing: 0.2,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../avelune_theme.dart';
import 'avelune_home_view_data.dart';
import 'avelune_relative_time.dart';

/// Metadata column the approved prototype places to the right of the hero
/// cartridge: a visible details control, the game identity, and the real last
/// session.
///
/// Every line is projected from [game]. The prototype also shows a
/// "genre · players" line, which is intentionally absent here: the read model
/// carries no genre or player-count field, and AVELUNE-500 bars inventing one.
class AveluneHeroDetailsPanel extends StatelessWidget {
  const AveluneHeroDetailsPanel({
    super.key,
    required this.game,
    required this.referenceTime,
    this.onShowDetails,
    this.condensed = false,
  });

  final AveluneGameViewData game;
  final DateTime referenceTime;
  final ValueChanged<AveluneGameViewData>? onShowDetails;

  /// Drops the secondary lines when the size class or text scale cannot hold
  /// them without pushing the column past the hero.
  final bool condensed;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    final lastSaveAt = game.lastSaveAt;

    return Column(
      key: const ValueKey<String>('avelune-hero-details-panel'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (onShowDetails case final callback?) ...<Widget>[
          AvelunePressable(
            key: const ValueKey<String>('avelune-hero-details-button'),
            semanticLabel: french
                ? 'Détails de ${game.title}'
                : '${game.title} details',
            onPressed: () => callback(game),
            borderRadius: AveluneShapes.pill,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.86),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AveluneSpacing.xxs),
                child: Icon(
                  AveluneIcons.details,
                  size: 15,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AveluneSpacing.sm),
        ],
        Text(
          game.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.12,
          ),
        ),
        if (!condensed)
          if (game.subtitle case final subtitle?
              when subtitle.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AveluneSpacing.xxs),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                height: 1.24,
              ),
            ),
          ],
        const SizedBox(height: AveluneSpacing.xxs),
        Text(
          game.authorName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11.5,
            height: 1.24,
          ),
        ),
        if (lastSaveAt != null) ...<Widget>[
          const SizedBox(height: AveluneSpacing.sm),
          SizedBox(
            width: 96,
            child: ColoredBox(
              color: colors.outline.withValues(alpha: 0.7),
              child: const SizedBox(height: 1),
            ),
          ),
          const SizedBox(height: AveluneSpacing.sm),
          Text(
            french ? 'Dernière partie' : 'Last session',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AveluneSpacing.hairline),
          Text(
            aveluneRelativeTime(lastSaveAt, referenceTime, french: french),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

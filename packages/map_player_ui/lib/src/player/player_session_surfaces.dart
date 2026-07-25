import 'package:flutter/material.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';

class PlayerLoadingSurface extends StatelessWidget {
  const PlayerLoadingSurface({
    super.key,
    required this.stage,
    this.progress,
    this.onCancel,
  });

  final String stage;
  final double? progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PlayerSurface(
          maxWidth: 620,
          child: Center(
            child: PlayerProgressCard(
              title: context.playerL10n.loading,
              stage: stage,
              value: progress,
              onCancel: onCancel,
            ),
          ),
        ),
      );
}

class PlayerResultSurface extends StatelessWidget {
  const PlayerResultSurface({
    super.key,
    required this.title,
    required this.summary,
    this.details = const <String>[],
    required this.onShowCredits,
  });

  final String title;
  final String summary;
  final List<String> details;
  final VoidCallback onShowCredits;

  @override
  Widget build(BuildContext context) => _CenteredSessionPanel(
        icon: Icons.emoji_events_rounded,
        title: title,
        body: <Widget>[
          Text(summary, textAlign: TextAlign.center),
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.only(top: PlayerSpacing.xs),
              child: Text(detail, textAlign: TextAlign.center),
            ),
          const SizedBox(height: PlayerSpacing.lg),
          PlayerActionButton(
            label: context.playerL10n.showCredits,
            icon: Icons.movie_filter_rounded,
            autofocus: true,
            onPressed: onShowCredits,
          ),
        ],
      );
}

class PlayerCreditsSurface extends StatelessWidget {
  const PlayerCreditsSurface({
    super.key,
    required this.title,
    required this.author,
    this.endingLabel,
    required this.onReturnToTitle,
    required this.onReturnToHub,
  });

  final String title;
  final String author;
  final String? endingLabel;
  final VoidCallback? onReturnToTitle;
  final VoidCallback? onReturnToHub;

  @override
  Widget build(BuildContext context) => _CenteredSessionPanel(
        icon: Icons.auto_stories_rounded,
        title: title,
        body: <Widget>[
          Text(author, style: Theme.of(context).textTheme.titleLarge),
          if (endingLabel != null) ...<Widget>[
            const SizedBox(height: PlayerSpacing.sm),
            Text(endingLabel!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: PlayerSpacing.xl),
          PlayerActionButton(
            label: context.playerL10n.returnToTitle,
            icon: Icons.title_rounded,
            autofocus: onReturnToTitle != null,
            onPressed: onReturnToTitle,
            disabledReason: onReturnToTitle == null
                ? context.playerL10n.directReturnHub
                : null,
          ),
          const SizedBox(height: PlayerSpacing.xs),
          PlayerActionButton(
            label: context.playerL10n.returnToHub,
            icon: Icons.home_rounded,
            secondary: true,
            autofocus: onReturnToTitle == null,
            onPressed: onReturnToHub,
            disabledReason: onReturnToHub == null
                ? context.playerL10n.directReturnTitle
                : null,
          ),
        ],
      );
}

class PlayerErrorSurface extends StatelessWidget {
  const PlayerErrorSurface({
    super.key,
    required this.title,
    required this.message,
    required this.recommendation,
    this.code,
    this.onRetry,
    this.onReturnToHub,
  });

  final String title;
  final String message;
  final String recommendation;
  final String? code;
  final VoidCallback? onRetry;
  final VoidCallback? onReturnToHub;

  @override
  Widget build(BuildContext context) => _CenteredSessionPanel(
        icon: Icons.error_outline_rounded,
        title: title,
        iconColor: context.playerColors.danger,
        body: <Widget>[
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: PlayerSpacing.sm),
          Text(
            recommendation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (code != null) ...<Widget>[
            const SizedBox(height: PlayerSpacing.sm),
            PlayerBadge(
              label: code!,
              icon: Icons.tag_rounded,
              tone: PlayerBadgeTone.danger,
            ),
          ],
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: PlayerSpacing.lg),
            PlayerActionButton(
              label: context.playerL10n.retry,
              icon: Icons.refresh_rounded,
              autofocus: true,
              onPressed: onRetry,
            ),
          ],
          if (onReturnToHub != null) ...<Widget>[
            const SizedBox(height: PlayerSpacing.xs),
            PlayerActionButton(
              label: context.playerL10n.returnToHub,
              icon: Icons.home_rounded,
              secondary: true,
              autofocus: onRetry == null,
              onPressed: onReturnToHub,
            ),
          ],
        ],
      );
}

class _CenteredSessionPanel extends StatelessWidget {
  const _CenteredSessionPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final List<Widget> body;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PlayerSurface(
          maxWidth: 640,
          child: Center(
            child: SingleChildScrollView(
              child: PlayerPanel(
                elevated: true,
                child: Semantics(
                  container: true,
                  namesRoute: true,
                  label: title,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        icon,
                        size: 64,
                        color: iconColor ?? context.playerColors.primary,
                      ),
                      const SizedBox(height: PlayerSpacing.md),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: PlayerSpacing.md),
                      ...body,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

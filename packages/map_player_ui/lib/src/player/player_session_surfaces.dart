import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_paged_layout.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';

class PlayerDetailEntryCard extends StatelessWidget {
  const PlayerDetailEntryCard({
    super.key,
    required this.entry,
    this.surfaceRole,
  });

  final RuntimePlayerDetailEntrySnapshot entry;
  final ProjectPresentationSurfaceRole? surfaceRole;

  @override
  Widget build(BuildContext context) => PlayerPanel(
    surfaceRole: surfaceRole,
    child: Semantics(
      container: true,
      label: entry.title,
      value: entry.trailingLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (entry.trailingLabel case final trailing?)
                Text(trailing, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          if (entry.subtitle case final subtitle?) ...<Widget>[
            const SizedBox(height: PlayerSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (entry.progress case final progress?) ...<Widget>[
            const SizedBox(height: PlayerSpacing.sm),
            LinearProgressIndicator(value: progress),
          ],
        ],
      ),
    ),
  );
}

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
  final VoidCallback? onShowCredits;

  @override
  Widget build(BuildContext context) => _CenteredSessionPanel(
    icon: Icons.emoji_events_rounded,
    title: title,
    surfaceRole: ProjectPresentationSurfaceRole.battleResult,
    body: [
      Text(summary, textAlign: TextAlign.center),
      for (final detail in details) Text(detail, textAlign: TextAlign.center),
    ],
    actions: [
      PlayerActionButton(
        label: context.playerL10n.showCredits,
        icon: Icons.movie_filter_rounded,
        autofocus: true,
        onPressed: onShowCredits,
        disabledReason: onShowCredits == null
            ? context.playerL10n.actionUnavailable
            : null,
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
    surfaceRole: ProjectPresentationSurfaceRole.credits,
    body: [
      Text(author, style: Theme.of(context).textTheme.titleLarge),
      if (endingLabel != null) Text(endingLabel!, textAlign: TextAlign.center),
    ],
    actions: [
      PlayerActionButton(
        label: context.playerL10n.returnToTitle,
        icon: Icons.title_rounded,
        autofocus: onReturnToTitle != null,
        onPressed: onReturnToTitle,
        disabledReason: onReturnToTitle == null
            ? context.playerL10n.directReturnHub
            : null,
      ),
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
    this.stage,
    this.onRetry,
    this.onCancel,
    this.onReturnToHub,
    this.onShowDiagnostics,
  });

  final String title;
  final String message;
  final String recommendation;
  final String? code;
  final String? stage;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onReturnToHub;
  final VoidCallback? onShowDiagnostics;

  @override
  Widget build(BuildContext context) => _CenteredSessionPanel(
    icon: Icons.error_outline_rounded,
    iconColor: context.playerColors.danger,
    title: title,
    surfaceRole: ProjectPresentationSurfaceRole.notification,
    body: [
      Text(message, textAlign: TextAlign.center),
      Text(
        recommendation,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (code != null)
        PlayerBadge(
          label: code!,
          icon: Icons.tag_rounded,
          tone: PlayerBadgeTone.danger,
        ),
      if (stage != null)
        PlayerBadge(
          label: stage!,
          icon: Icons.route_rounded,
          tone: PlayerBadgeTone.warning,
        ),
    ],
    actions: [
      if (onRetry != null)
        PlayerActionButton(
          label: context.playerL10n.retry,
          icon: Icons.refresh_rounded,
          autofocus: true,
          onPressed: onRetry,
        ),
      if (onReturnToHub != null)
        PlayerActionButton(
          label: context.playerL10n.returnToHub,
          icon: Icons.home_rounded,
          secondary: true,
          autofocus: onRetry == null,
          onPressed: onReturnToHub,
        ),
      if (onCancel != null)
        PlayerActionButton(
          label: context.playerL10n.close,
          icon: Icons.close_rounded,
          secondary: true,
          autofocus: onRetry == null && onReturnToHub == null,
          onPressed: onCancel,
        ),
      if (onShowDiagnostics != null)
        PlayerActionButton(
          label: context.playerL10n.diagnostics,
          icon: Icons.health_and_safety_outlined,
          secondary: true,
          onPressed: onShowDiagnostics,
        ),
    ],
  );
}

class _CenteredSessionPanel extends StatelessWidget {
  const _CenteredSessionPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
    this.iconColor,
    this.surfaceRole,
  });
  final IconData icon;
  final String title;
  final List<Widget> body;
  final List<Widget> actions;
  final Color? iconColor;
  final ProjectPresentationSurfaceRole? surfaceRole;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PlayerSurface(
      maxWidth: 680,
      padding: const EdgeInsets.all(PlayerSpacing.md),
      child: PlayerPanel(
        elevated: true,
        surfaceRole: surfaceRole,
        padding: const EdgeInsets.all(PlayerSpacing.md),
        child: Semantics(
          container: true,
          namesRoute: true,
          label: title,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 400;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: compact ? 28 : 40,
                        color: iconColor ?? context.playerColors.primary,
                      ),
                      const SizedBox(width: PlayerSpacing.sm),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PlayerSpacing.md),
                  Expanded(
                    child: PlayerPagedList(
                      children: [
                        for (var index = 0; index < body.length; index++)
                          KeyedSubtree(
                            key: ValueKey('session-content-$index'),
                            child: body[index],
                          ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    const SizedBox(height: PlayerSpacing.md),
                  for (
                    var row = 0;
                    row < (actions.length / 2).ceil();
                    row++
                  ) ...[
                    if (row > 0) const SizedBox(height: PlayerSpacing.xs),
                    Row(
                      children: [
                        for (var column = 0; column < 2; column++) ...[
                          if (column > 0 && row * 2 + column < actions.length)
                            const SizedBox(width: PlayerSpacing.xs),
                          if (row * 2 + column < actions.length)
                            Expanded(child: actions[row * 2 + column]),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

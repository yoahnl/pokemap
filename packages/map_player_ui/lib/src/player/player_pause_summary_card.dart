import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_menu_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';

class PlayerPauseSummaryCard extends StatelessWidget {
  const PlayerPauseSummaryCard({
    super.key,
    required this.gameTitle,
    this.profile,
    this.portraitImage,
    this.compact = false,
  });

  final String gameTitle;
  final RuntimePlayerProfileSnapshot? profile;
  final ImageProvider? portraitImage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final l10n = context.playerL10n;
    final location = profile?.locationName?.trim();
    final heading = location == null || location.isEmpty ? gameTitle : location;
    final playerName = profile?.playerName.trim();
    final badges = profile?.badgeIds;
    final badgeTotal = profile?.badgeTotal;
    final seconds = profile?.playtimeSeconds;
    final pokedex = profile?.pokedex;
    final statistics = <({String label, String value})>[
      if (badges != null && (badges.isNotEmpty || (badgeTotal ?? 0) > 0))
        (
          label: l10n.badges,
          value: badgeTotal == null
              ? '${badges.length}'
              : '${badges.length} / $badgeTotal',
        ),
      if (seconds != null)
        (
          label: l10n.playTime,
          value: '${seconds ~/ 3600}:'
              '${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}',
        ),
      if (pokedex != null)
        (label: l10n.pokedex, value: '${pokedex.caught} / ${pokedex.total}'),
    ];
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(heading, style: theme.subtitle),
        ),
        if (playerName != null &&
            playerName.isNotEmpty &&
            playerName != heading) ...[
          const SizedBox(height: PlayerSpacing.xs),
          Text(playerName, style: theme.body),
        ],
        if (statistics.isNotEmpty) ...[
          const SizedBox(height: PlayerSpacing.sm),
          for (final statistic in statistics)
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '${statistic.label} : '),
                TextSpan(text: statistic.value, style: theme.numbers),
              ]),
              style: theme.body,
            ),
        ],
      ],
    );
    final portrait = ExcludeSemantics(
      child: SizedBox(
        width: compact ? 72 : 160,
        height: compact ? 84 : 184,
        child: Align(
          alignment: Alignment.bottomRight,
          child: _portrait(context),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: PlayerMenuPanel(
        key: const ValueKey('player-pause-summary-panel'),
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(builder: (context, constraints) {
          final stacked = constraints.maxWidth < (compact ? 280 : 480) ||
              MediaQuery.textScalerOf(context).scale(18) > 27;
          if (stacked) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: PlayerSpacing.sm),
                Align(alignment: Alignment.bottomRight, child: portrait),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: details),
              SizedBox(width: compact ? PlayerSpacing.sm : PlayerSpacing.md),
              portrait,
            ],
          );
        }),
      ),
    );
  }

  Widget _portrait(BuildContext context) {
    final fallback = Icon(
      Icons.person_rounded,
      key: const ValueKey('player-pause-summary-silhouette'),
      size: compact ? 72 : 144,
      color: context.playerMenuTheme.secondary,
    );
    final image = portraitImage;
    if (image == null) return fallback;
    return Image(
      key: const ValueKey('player-pause-summary-portrait'),
      image: ResizeImage(image,
          width: 320, height: 368, policy: ResizeImagePolicy.fit),
      fit: BoxFit.contain,
      alignment: Alignment.bottomRight,
      filterQuality: FilterQuality.medium,
      frameBuilder: (_, child, frame, synchronouslyLoaded) =>
          frame == null ? fallback : child,
      errorBuilder: (_, error, stack) => fallback,
    );
  }
}

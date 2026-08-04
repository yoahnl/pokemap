import 'package:flutter/material.dart';

import '../hub_dashboard_controller.dart';
import 'avelune_game_presentation.dart';
import 'avelune_theme.dart';

class AveluneGameDetailsScreen extends StatelessWidget {
  const AveluneGameDetailsScreen({
    super.key,
    required this.game,
    required this.referenceTime,
  });

  final HubGameView game;
  final DateTime referenceTime;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final activity = game.activity;
    final installation = game.game;
    return RepaintBoundary(
      key: const ValueKey<String>('avelune-details-root'),
      child: Scaffold(
        backgroundColor: colors.background,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 280,
              backgroundColor: colors.background,
              foregroundColor: colors.textPrimary,
              surfaceTintColor: colors.background,
              title: Text(installation.title),
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  key: const ValueKey<String>('avelune-details-artwork'),
                  tag: aveluneArtworkHeroTag(installation.gameId),
                  transitionOnUserGestures: true,
                  child: _AveluneDetailsArtwork(game: game),
                ),
              ),
            ),
            SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                sliver: SliverList.list(
                  children: <Widget>[
                    Text(
                      installation.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      installation.authorName,
                      style: TextStyle(
                        color: colors.gold,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      installation.description?.trim().isNotEmpty == true
                          ? installation.description!
                          : french
                              ? 'Aucune description fournie.'
                              : 'No description provided.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.outline),
                      ),
                      child: Column(
                        children: <Widget>[
                          _DetailRow(
                            label: french ? 'Version' : 'Version',
                            value: installation.current.gameVersion.toString(),
                          ),
                          const _DetailDivider(),
                          _DetailRow(
                            label: french ? 'Dernière partie' : 'Last played',
                            value: activity.lastSaveAt == null
                                ? (french ? 'Jamais' : 'Never')
                                : formatAveluneRelativeTime(
                                    activity.lastSaveAt!,
                                    referenceTime,
                                    french: french,
                                  ),
                          ),
                          const _DetailDivider(),
                          _DetailRow(
                            label: french ? 'Temps de jeu' : 'Play time',
                            value: _formatPlayTime(
                              activity.playTimeSeconds,
                              french: french,
                            ),
                          ),
                          const _DetailDivider(),
                          _DetailRow(
                            label: french ? 'État' : 'Status',
                            value: activity.installationHealthy
                                ? (french ? 'Prêt à jouer' : 'Ready to play')
                                : (french ? 'Jeu indisponible' : 'Unavailable'),
                            valueColor: activity.installationHealthy
                                ? colors.textPrimary
                                : colors.invalid,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AveluneDetailsArtwork extends StatelessWidget {
  const _AveluneDetailsArtwork({required this.game});

  final HubGameView game;

  @override
  Widget build(BuildContext context) {
    final image = aveluneArtworkFor(game);
    final colors = context.aveluneColors;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            aveluneShellColorFor(context, game),
            colors.surfaceElevated,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          color: colors.textPrimary,
          size: 72,
        ),
      ),
    );
    return Material(
      color: colors.surface,
      child: image == null
          ? fallback
          : Image(
              image: image,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: valueColor ?? colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: context.aveluneColors.outline,
      );
}

String _formatPlayTime(int seconds, {required bool french}) {
  if (seconds <= 0) return french ? 'Aucune partie' : 'No play time';
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  return '$hours h ${minutes.toString().padLeft(2, '0')} min';
}

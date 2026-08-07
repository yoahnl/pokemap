import 'package:flutter/material.dart';

import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_notifier.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_presentation.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';

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
      // No Scaffold and no SliverAppBar: the artwork runs full bleed under a
      // floating glass back control, the way the room's own chrome behaves.
      // A Material app bar would reintroduce its elevation, its tint overlay
      // and its title crossfade on top of a photograph.
      child: ColoredBox(
        color: colors.background,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium ??
              TextStyle(color: colors.textPrimary),
          child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 318,
                      child: Hero(
                        key: const ValueKey<String>('avelune-details-artwork'),
                        tag: aveluneArtworkHeroTag(installation.gameId),
                        transitionOnUserGestures: true,
                        flightShuttleBuilder: aveluneArtworkFlightShuttleBuilder,
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
            // The back control floats over the artwork instead of riding an
            // app bar, so nothing is stacked on top of the photograph.
            Positioned(
              left: AveluneSpacing.lg,
              top: AveluneSpacing.lg,
              child: SafeArea(
                bottom: false,
                child: AveluneIconControl(
                  semanticLabel: french ? 'Retour' : 'Back',
                  icon: AveluneIcons.back,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
          ),
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
    final fallback = Image.asset(
      kAveluneFallbackArtworkAssetPath,
      key: const ValueKey<String>('avelune-fallback-artwork'),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      excludeFromSemantics: true,
    );
    return ColoredBox(
      color: colors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          image == null
              ? fallback
              : Image(
                  image: image,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => fallback,
                ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  colors.background.withValues(alpha: 0.06),
                  colors.background.withValues(alpha: 0.94),
                ],
                stops: const <double>[0, 0.58, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.92,
                colors: <Color>[
                  Colors.transparent,
                  colors.background.withValues(alpha: 0.34),
                ],
              ),
            ),
          ),
        ],
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

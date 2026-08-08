import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/core/utils/relative_time.dart';

/// Metadata column the approved prototype places to the right of the hero
/// cartridge: a visible details control, the game identity, and the real last
/// session.
///
/// Every line is projected from [game]. The prototype also shows a
/// "genre · players" line, which is intentionally absent here: the read model
/// carries no genre or player-count field, and AVELUNE-500 bars inventing one.
class AveluneHeroDetailsPanel extends StatefulWidget {
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
  State<AveluneHeroDetailsPanel> createState() =>
      _AveluneHeroDetailsPanelState();
}

class _AveluneHeroDetailsPanelState extends State<AveluneHeroDetailsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  Curve _revealCurve = Curves.easeOutCubic;
  bool _configured = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: AveluneMotionTokens.standard.detailsReveal,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    _revealController.duration = context.aveluneMotion.detailsReveal;
    _revealCurve = context.aveluneMotion.movementCurve;
    final shouldStart = !_configured || _reducedMotion != reducedMotion;
    _configured = true;
    _reducedMotion = reducedMotion;
    if (shouldStart) _startReveal();
  }

  @override
  void didUpdateWidget(covariant AveluneHeroDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) _startReveal();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _startReveal() {
    if (_reducedMotion) {
      _revealController.value = 1;
    } else {
      _revealController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    final game = widget.game;
    final lastSaveAt = game.lastSaveAt;

    return Column(
      key: const ValueKey<String>('avelune-hero-details-panel'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.onShowDetails case final callback?) ...<Widget>[
          _reveal(
            id: 'action',
            index: 0,
            child: AvelunePressable(
              key: const ValueKey<String>('avelune-hero-details-button'),
              semanticLabel:
                  french ? 'Détails de ${game.title}' : '${game.title} details',
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
          ),
          const SizedBox(height: AveluneSpacing.sm),
        ],
        _reveal(
          id: 'title',
          index: 0,
          child: Text(
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
        ),
        if (!widget.condensed)
          if (game.subtitle case final subtitle?
              when subtitle.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AveluneSpacing.xxs),
            _reveal(
              id: 'subtitle',
              index: 1,
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  height: 1.24,
                ),
              ),
            ),
          ],
        const SizedBox(height: AveluneSpacing.xxs),
        _reveal(
          id: 'author',
          index: 2,
          child: Text(
            game.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
              height: 1.24,
            ),
          ),
        ),
        if (lastSaveAt != null) ...<Widget>[
          const SizedBox(height: AveluneSpacing.sm),
          _reveal(
            id: 'session',
            index: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
                  aveluneRelativeTime(
                    lastSaveAt,
                    widget.referenceTime,
                    french: french,
                  ),
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
            ),
          ),
        ],
      ],
    );
  }

  Widget _reveal({
    required String id,
    required int index,
    required Widget child,
  }) {
    final start = index * 0.14;
    final progress = CurvedAnimation(
      parent: _revealController,
      curve: Interval(
        start,
        (start + 0.58).clamp(0, 1),
        curve: _revealCurve,
      ),
    );
    return SlideTransition(
      key: ValueKey<String>('avelune-hero-details-reveal-$id'),
      position: Tween<Offset>(
        begin: const Offset(0.14, 0),
        end: Offset.zero,
      ).animate(progress),
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

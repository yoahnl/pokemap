import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/core/utils/relative_time.dart';

/// Editorial identity block placed above the hero cartridge: a visible details
/// control, the game identity, and the real last session.
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

    final titleSize = widget.condensed ? 27.0 : 38.0;

    return Column(
      key: const ValueKey<String>('avelune-hero-details-panel'),
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _reveal(
          id: 'title',
          index: 0,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w400,
                    height: 1.04,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              if (widget.onShowDetails case final callback?)
                AvelunePressable(
                  key: const ValueKey<String>('avelune-hero-details-button'),
                  semanticLabel: french
                      ? 'Détails de ${game.title}'
                      : '${game.title} details',
                  onPressed: () => callback(game),
                  borderRadius: AveluneShapes.pill,
                  child: Padding(
                    padding: const EdgeInsets.all(AveluneSpacing.xs),
                    child: Icon(
                      AveluneIcons.details,
                      size: 17,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AveluneSpacing.sm),
        _reveal(
          id: 'rule',
          index: 1,
          child: Row(
            children: <Widget>[
              Icon(
                AveluneIcons.motionOn,
                color: colors.accentBright,
                size: 13,
              ),
              const SizedBox(width: AveluneSpacing.xs),
              Flexible(
                child: Container(
                  height: 1,
                  constraints: const BoxConstraints(maxWidth: 210),
                  color: colors.accentBright.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        if (lastSaveAt != null) ...<Widget>[
          const SizedBox(height: AveluneSpacing.sm),
          _reveal(
            id: 'session',
            index: 2,
            child: Text(
              '${french ? 'Dernière partie' : 'Last session'}  ·  '
              '${aveluneRelativeTime(lastSaveAt, widget.referenceTime, french: french)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: widget.condensed ? 11.5 : 13.5,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
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

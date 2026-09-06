import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_menu_theme.dart';
import 'player_pause_summary_card.dart';

class PlayerPauseIllustratedRoot extends StatelessWidget {
  const PlayerPauseIllustratedRoot({
    super.key,
    required this.gameTitle,
    required this.menuTitle,
    required this.navigation,
    required this.background,
    this.profile,
    this.portraitImage,
    this.hint,
    this.showTitle = true,
    this.showGameTitle = false,
    this.showSummary = true,
    this.extraDetail,
  });

  final String gameTitle;
  final String menuTitle;
  final Widget navigation;
  final Widget background;
  final RuntimePlayerProfileSnapshot? profile;
  final ImageProvider? portraitImage;
  final String? hint;
  final bool showTitle;
  final bool showGameTitle;
  final bool showSummary;
  final Widget? extraDetail;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final theme = context.playerMenuTheme;
        final portrait = size.maxWidth < 650;
        final expanded = size.maxWidth >= 1100 && size.maxHeight >= 620;
        final railWidth = expanded ? 408.0 : 280.0;
        final slant = expanded ? 24.0 : 16.0;
        final inset = expanded ? 28.0 : 16.0;
        final hasHint = hint != null && hint!.trim().isNotEmpty;
        final titleHeight = MediaQuery.textScalerOf(context).scale(20) *
            ((showTitle ? 1 : 0) + (showGameTitle ? 2 : 0));
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle)
              Semantics(
                header: true,
                child: Text(menuTitle,
                    key: const ValueKey('pause-root-menu-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.meta),
              ),
            if (showGameTitle)
              Text(gameTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.meta),
          ],
        );
        final summary = PlayerPauseSummaryCard(
          gameTitle: gameTitle,
          profile: profile,
          portraitImage: portraitImage,
          compact: !expanded,
        );
        if (portrait) {
          return Stack(fit: StackFit.expand, children: [
            background,
            ColoredBox(color: theme.base.withValues(alpha: .84)),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(padding: const EdgeInsets.all(16), child: title),
              if (hasHint)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(hint!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.body),
                ),
              if (showSummary)
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: math.min(180, size.maxHeight * .34)),
                  child: SingleChildScrollView(
                    key: const ValueKey('pause-root-summary-scroll'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      summary,
                      if (extraDetail != null) extraDetail!,
                    ]),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: navigation,
                ),
              ),
            ]),
          ]);
        }
        final rightWidth = math.max(0.0, size.maxWidth - railWidth - slant);
        return Stack(fit: StackFit.expand, children: [
          Positioned(
            left: railWidth,
            top: 0,
            right: 0,
            bottom: 0,
            child: Stack(fit: StackFit.expand, children: [
              background,
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.base.withValues(alpha: 0),
                      theme.base.withValues(alpha: .64)
                    ],
                    stops: const [.35, 1],
                  ),
                ),
              ),
            ]),
          ),
          Positioned(
            key: const ValueKey('pause-root-rail'),
            left: 0,
            top: 0,
            bottom: 0,
            width: railWidth + slant,
            child: ClipPath(
              clipper: _PauseRailClipper(slant),
              child: ColoredBox(color: theme.base),
            ),
          ),
          Positioned(
              left: inset,
              top: expanded ? 28 : 16,
              width: railWidth - inset * 2,
              child: title),
          Positioned(
            left: inset,
            top: math.max(
                expanded ? 80 : 52, (expanded ? 28 : 16) + titleHeight + 16),
            bottom: 16,
            width: railWidth - inset * 2,
            child: navigation,
          ),
          if (hasHint && expanded)
            Positioned(
              left: railWidth + slant + 24,
              right: 24,
              top: size.maxHeight * .28,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: theme.base.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(hint!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.subtitle),
                    ),
                  ),
                ),
              ),
            ),
          if (showSummary || hasHint && !expanded)
            Positioned(
              right: 24,
              bottom: 24,
              width: math.min(640, math.max(0, rightWidth - 48)),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: math.max(0, size.maxHeight - 48)),
                child: SingleChildScrollView(
                  key: const ValueKey('pause-root-summary-scroll'),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (hasHint && !expanded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(hint!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.body),
                      ),
                    if (showSummary) summary,
                    if (extraDetail != null) extraDetail!
                  ]),
                ),
              ),
            ),
        ]);
      });
}

class _PauseRailClipper extends CustomClipper<Path> {
  const _PauseRailClipper(this.slant);
  final double slant;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width - slant, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_PauseRailClipper oldClipper) => oldClipper.slant != slant;
}

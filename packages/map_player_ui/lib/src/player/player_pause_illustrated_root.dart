import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_menu_components.dart';
import '../foundation/player_input_scope.dart';
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
    this.summaryInNavigation = false,
    this.extraDetail,
    this.footer,
    this.saveMessage,
    this.onBack,
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
  final bool summaryInNavigation;
  final Widget? extraDetail;
  final Widget? footer;
  final String? saveMessage;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final theme = context.playerMenuTheme;
      final mobile = size.biggest.shortestSide < 600;
      final portrait = size.maxWidth < 650;
      final expanded = size.maxWidth >= 1100 && size.maxHeight >= 620;
      final railWidth = expanded ? 408.0 : 280.0;
      final slant = expanded ? 24.0 : 16.0;
      final safePadding = MediaQuery.paddingOf(context);
      final inset = math.max(expanded ? 28.0 : 16.0, safePadding.left);
      final titleTop = math.max(expanded ? 28.0 : 16.0, safePadding.top);
      final hasHint = hint != null && hint!.trim().isNotEmpty;
      final titleHeight =
          MediaQuery.textScalerOf(context).scale(20) *
          ((showTitle ? 1 : 0) + (showGameTitle ? 2 : 0));
      final title = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle)
            Semantics(
              header: true,
              child: Text(
                menuTitle,
                key: const ValueKey('pause-root-menu-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.meta,
              ),
            ),
          if (showGameTitle)
            Text(
              gameTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.meta,
            ),
        ],
      );
      final summary = PlayerPauseSummaryCard(
        gameTitle: gameTitle,
        profile: profile,
        portraitImage: portraitImage,
        compact: !expanded,
        mobile: mobile,
        minimal: mobile && !portrait,
      );
      if (mobile) {
        final companion = PlayerCompanionScope.of(context);
        final tall = size.maxHeight > size.maxWidth && !companion;
        final safe = MediaQuery.paddingOf(context);
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final notice = companion && saveMessage?.trim().isNotEmpty == true
            ? saveMessage
            : null;
        final panelHeight = tall
            ? math.min(
                size.maxHeight - safe.top - 24,
                (390.0 + math.max(0, safe.bottom - 16)) * math.min(scale, 1.4),
              )
            : size.maxHeight;
        final panelWidth = tall || companion
            ? size.maxWidth
            : math.min(size.maxWidth, 350.0 + math.max(0.0, safe.right - 44));
        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(child: background),
            ExcludeSemantics(
              child: ColoredBox(color: theme.shadow.withValues(alpha: .5)),
            ),
            Align(
              alignment: tall ? Alignment.bottomCenter : Alignment.centerRight,
              child: SizedBox(
                key: const ValueKey('pause-root-sheet'),
                width: panelWidth,
                height: panelHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.base.withValues(alpha: theme.panelOpacity),
                    borderRadius: BorderRadius.zero,
                    border: Border(top: BorderSide(color: theme.border)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      tall ? math.max(16, safe.left) : 16,
                      tall ? 12 : math.max(12, safe.top),
                      math.max(16, safe.right),
                      math.max(8, safe.bottom),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showTitle || showGameTitle) ...[
                          Row(
                            children: [
                              if (onBack != null) ...[
                                PlayerMenuBackButton(onPressed: onBack!),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (showTitle)
                                      Text(
                                        menuTitle,
                                        key: const ValueKey(
                                          'pause-root-menu-title',
                                        ),
                                        style: theme.title.copyWith(
                                          fontSize: 23,
                                          height: 1.15,
                                        ),
                                      ),
                                    if (showSummary &&
                                        size.maxHeight >= 300) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        notice ??
                                            profile?.locationName ??
                                            gameTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.meta.copyWith(
                                          fontSize: 12,
                                          height: 1.35,
                                          color: theme.secondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (hasHint) ...[
                          Text(
                            hint!,
                            style: theme.meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Expanded(child: navigation),
                        if (footer != null) ...[
                          const SizedBox(height: 8),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      final rightWidth = math.max(0.0, size.maxWidth - railWidth - slant);
      return Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: railWidth,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      background,
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.base.withValues(alpha: 0),
                              theme.base.withValues(alpha: .64),
                            ],
                            stops: const [.35, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  top: titleTop,
                  width: railWidth - inset * 2,
                  child: title,
                ),
                Positioned(
                  left: inset,
                  top: math.max(
                    expanded ? 80 : 52,
                    titleTop + titleHeight + 16,
                  ),
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
                        child: PlayerMenuPanel(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            hint!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.subtitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showSummary && !summaryInNavigation || hasHint && !expanded)
                  Positioned(
                    right: 24,
                    bottom: 24,
                    width: math.min(640, math.max(0, rightWidth - 48)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(0, size.maxHeight - 48),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasHint && !expanded)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: PlayerMenuPanel(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  hint!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.body,
                                ),
                              ),
                            ),
                          if (showSummary && !summaryInNavigation) summary,
                          if (showSummary && extraDetail != null) extraDetail!,
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (footer != null)
            ColoredBox(
              color: theme.base,
              child: SafeArea(top: false, child: footer!),
            ),
        ],
      );
    },
  );
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

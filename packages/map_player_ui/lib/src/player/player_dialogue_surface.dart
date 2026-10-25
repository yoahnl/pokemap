import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_paged_layout.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_dialogue_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_window_theme.dart';

enum PlayerDialogueMode { line, choices }

@immutable
final class PlayerDialogueChoiceViewData {
  const PlayerDialogueChoiceViewData({
    required this.index,
    required this.label,
    required this.selected,
    this.enabled = true,
  });

  final int index;
  final String label;
  final bool selected;
  final bool enabled;
}

@immutable
final class PlayerDialogueViewData {
  const PlayerDialogueViewData({
    required this.revision,
    required this.mode,
    required this.speaker,
    required this.text,
    required this.fullText,
    required this.isCurrentLineFullyRevealed,
    required this.isLastContent,
    required this.choices,
    this.isAdvanceAvailable = true,
    this.lineSpan,
  });

  final int revision;
  final PlayerDialogueMode mode;
  final String? speaker;
  final String text;
  final String fullText;
  final bool isCurrentLineFullyRevealed;
  final bool isLastContent;
  final List<PlayerDialogueChoiceViewData> choices;
  final bool isAdvanceAvailable;
  final InlineSpan? lineSpan;
}

sealed class PlayerDialogueAction {
  const PlayerDialogueAction({required this.snapshotRevision});

  final int snapshotRevision;
}

final class PlayerDialogueAdvanceAction extends PlayerDialogueAction {
  const PlayerDialogueAdvanceAction({required super.snapshotRevision});
}

final class PlayerDialogueSelectChoiceAction extends PlayerDialogueAction {
  const PlayerDialogueSelectChoiceAction({
    required super.snapshotRevision,
    required this.choiceIndex,
  });

  final int choiceIndex;
}

final class PlayerDialoguePaginationController {
  bool Function()? _advance;
  bool advancePage() => _advance?.call() ?? false;
  void dispose() => _advance = null;
}

/// Boîte de dialogue joueur rendue en Flutter à partir du data runtime.
class PlayerDialogueSurface extends StatefulWidget {
  const PlayerDialogueSurface({
    super.key,
    required this.data,
    required this.onAction,
    this.portraitBuilder,
    this.resolvedPortrait,
    this.showSpeakerName = true,
    this.paginationController,
  });

  final PlayerDialogueViewData data;
  final ValueChanged<PlayerDialogueAction> onAction;
  final Widget Function(String speaker)? portraitBuilder;
  final Widget? resolvedPortrait;
  final bool showSpeakerName;
  final PlayerDialoguePaginationController? paginationController;

  @override
  State<PlayerDialogueSurface> createState() => _PlayerDialogueSurfaceState();
}

class _PlayerDialogueSurfaceState extends State<PlayerDialogueSurface> {
  final _pages = GlobalKey<_DialogueTextPagesState>();
  int? _acknowledgedRevision;
  PlayerDialogueViewData get data => widget.data;
  ValueChanged<PlayerDialogueAction> get onAction => widget.onAction;
  Widget Function(String speaker)? get portraitBuilder =>
      widget.portraitBuilder;
  Widget? get resolvedPortrait => widget.resolvedPortrait;
  bool get showSpeakerName => widget.showSpeakerName;

  @override
  void initState() {
    super.initState();
    widget.paginationController?._advance = _advancePage;
  }

  bool _advancePage() =>
      mounted &&
      data.isAdvanceAvailable &&
      data.isCurrentLineFullyRevealed &&
      (_pages.currentState?.nextPage() ?? false);

  @override
  void dispose() {
    if (widget.paginationController?._advance == _advancePage) {
      widget.paginationController?._advance = null;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(PlayerDialogueSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paginationController != widget.paginationController) {
      if (oldWidget.paginationController?._advance == _advancePage) {
        oldWidget.paginationController?._advance = null;
      }
      widget.paginationController?._advance = _advancePage;
    }
    if ((_acknowledgedRevision != null &&
            _acknowledgedRevision != data.revision) ||
        (oldWidget.data.isCurrentLineFullyRevealed &&
            !data.isCurrentLineFullyRevealed)) {
      _pages.currentState?.resetPage();
      _acknowledgedRevision = null;
    }
    if (oldWidget.data.fullText != data.fullText ||
        oldWidget.data.speaker != data.speaker ||
        oldWidget.data.mode != data.mode) {
      _acknowledgedRevision = null;
    }
  }

  void _advance() {
    if (!data.isAdvanceAvailable) return;
    if (data.isCurrentLineFullyRevealed) {
      if (_pages.currentState?.nextPage() ?? false) return;
      if (_acknowledgedRevision == data.revision) return;
      _acknowledgedRevision = data.revision;
    }
    onAction(PlayerDialogueAdvanceAction(snapshotRevision: data.revision));
  }

  @override
  Widget build(BuildContext context) => PlayerSurfacePaletteScope(
    role: ProjectPresentationSurfaceRole.dialogue,
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final menu = PokeMapPlayerMenuTheme.resolve(
      context,
      role: ProjectPresentationSurfaceRole.dialogue,
      opaque: true,
    );
    final ligue =
        context.playerDialogueProfile == null &&
        context.playerWindowTheme == null;
    final safeInsets = MediaQuery.paddingOf(context);
    final surface = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dialogue = context.playerDialogueProfile;
          final resolved = context.playerLayoutTheme?.resolve(
            ProjectPresentationSurfaceRole.dialogue,
            constraints,
          );
          final margin =
              dialogue?.margin ??
              PlayerSpacing.sm + (resolved?.additionalSafeAreaPadding ?? 0);
          final companion = PlayerCompanionScope.of(context);
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final fillCompanion = companion && ligue && resolved == null;
          final horizontalMargin = landscape && !companion ? 44.0 : 16.0;
          final bottomMargin = landscape || companion ? 16.0 : 24.0;
          final defaultInsets = EdgeInsets.fromLTRB(
            math.max(0, horizontalMargin - safeInsets.left),
            math.max(0, 16 - safeInsets.top),
            math.max(0, horizontalMargin - safeInsets.right),
            math.max(0, bottomMargin - safeInsets.bottom),
          );
          final insets = ligue && resolved == null
              ? defaultInsets
              : EdgeInsets.all(margin);
          final showPortrait =
              resolved == null ||
              resolved.variant.visibleSecondaryElements.contains(
                ProjectPresentationSecondaryElement.dialoguePortrait,
              );
          final alignment = dialogue == null
              ? switch (resolved?.variant.slot) {
                  ProjectPresentationLayoutSlot.topCenter =>
                    Alignment.topCenter,
                  ProjectPresentationLayoutSlot.center => Alignment.center,
                  _ => Alignment.bottomCenter,
                }
              : switch (dialogue.placement) {
                  ProjectDialoguePlacement.top => Alignment.topCenter,
                  ProjectDialoguePlacement.center => Alignment.center,
                  ProjectDialoguePlacement.bottom => Alignment.bottomCenter,
                };
          final contentPadding =
              dialogue?.contentPadding ??
              (ligue && resolved == null
                  ? companion
                        ? 10.0
                        : 18.0
                  : PlayerSpacing.md * (resolved?.spacingScale ?? 1));
          return Padding(
            padding: insets,
            child: Align(
              key: dialogue != null
                  ? const ValueKey<String>('player-dialogue-authored-bubble')
                  : resolved == null
                  ? null
                  : ValueKey<String>(
                      'player-dialogue-responsive-'
                      '${resolved.breakpoint.name}',
                    ),
              alignment: alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: fillCompanion
                      ? math.max(0, constraints.maxHeight - insets.vertical)
                      : 0,
                  maxWidth: resolved == null
                      ? dialogue == null
                            ? math.max(
                                0,
                                constraints.maxWidth - insets.horizontal,
                              )
                            : constraints.maxWidth * dialogue.maxWidthFactor
                      : dialogue == null
                      ? constraints.maxWidth * resolved.maxWidthFactor
                      : constraints.maxWidth * dialogue.maxWidthFactor,
                  maxHeight: math.max(
                    0,
                    constraints.maxHeight - insets.vertical,
                  ),
                ),
                child: _DialoguePanel(
                  dialogue: dialogue,
                  contentPadding: contentPadding,
                  child: AnimatedSwitcher(
                    duration: context.playerMotion.fast,
                    child: Semantics(
                      key: ValueKey<PlayerDialogueMode>(data.mode),
                      container: true,
                      liveRegion: true,
                      label: _semanticLabel(data, showSpeakerName),
                      child: switch (data.mode) {
                        PlayerDialogueMode.line => GestureDetector(
                          key: const ValueKey<String>('dialogue-tap-zone'),
                          behavior: HitTestBehavior.opaque,
                          onTap: data.isAdvanceAvailable ? _advance : null,
                          child: _DialogueLineContent(
                            preferredMaxHeight: resolved == null
                                ? math.max(
                                    0,
                                    constraints.maxHeight * .58 -
                                        contentPadding * 2,
                                  )
                                : null,
                            pageKey: _pages,
                            data: data,
                            dialogue: dialogue,
                            portraitBuilder: showPortrait
                                ? portraitBuilder
                                : null,
                            resolvedPortrait: showPortrait
                                ? resolvedPortrait
                                : null,
                            showSpeakerName: showSpeakerName,
                          ),
                        ),
                        PlayerDialogueMode.choices => _DialogueChoiceContent(
                          data: data,
                          onAction: onAction,
                          showSpeakerName: showSpeakerName,
                          portrait: showPortrait
                              ? resolvedPortrait ??
                                    (data.speaker == null
                                        ? null
                                        : portraitBuilder?.call(data.speaker!))
                              : null,
                          preferredMaxHeight: resolved == null
                              ? math.max(
                                  0,
                                  constraints.maxHeight * .58 -
                                      contentPadding * 2,
                                )
                              : null,
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    return ligue
        ? Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    key: const ValueKey('player-dialogue-ligue-backdrop'),
                    color: menu.shadow.withValues(alpha: .3),
                  ),
                ),
              ),
              surface,
            ],
          )
        : surface;
  }
}

class _DialoguePanel extends StatelessWidget {
  const _DialoguePanel({
    required this.dialogue,
    required this.contentPadding,
    required this.child,
  });

  final ProjectDialoguePresentationProfile? dialogue;
  final double contentPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final profile = dialogue;
    if (profile != null || context.playerWindowTheme != null) {
      return PlayerPanel(
        elevated: true,
        role: PlayerPanelRole.dialogue,
        surfaceRole: ProjectPresentationSurfaceRole.dialogue,
        padding: EdgeInsets.all(contentPadding),
        windowStyleOverride: profile == null
            ? null
            : ProjectWindowStyleProfile(
                id: 'dialogue-v9',
                shape: profile.shape,
                borderWidth: profile.borderWidth.round(),
                cornerRadius: profile.cornerRadius.round(),
                contentPadding: profile.contentPadding.round(),
                shadowElevation: 8,
                fillOpacity: profile.fillOpacity,
                fillToken: 'dialogueSurface',
                borderToken: 'outline',
              ),
        surfaceColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          profile?.surfaceColor,
        ),
        borderColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          profile?.borderColor,
        ),
        textColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          profile?.textColor,
        ),
        child: child,
      );
    }
    final menu = PokeMapPlayerMenuTheme.resolve(
      context,
      role: ProjectPresentationSurfaceRole.dialogue,
      opaque: true,
    );
    final baseTheme = Theme.of(context);
    final palette = context.playerSurfacePalette(
      ProjectPresentationSurfaceRole.dialogue,
    );
    final surface =
        PokeMapPlayerProjectColorResolver.tryOpaqueHex(palette?.surface) ??
        baseTheme
            .extension<PokeMapPlayerAuthoredSemanticTheme>()
            ?.semantic
            .dialogueSurface ??
        menu.base;
    final landscape = MediaQuery.sizeOf(context).aspectRatio > 1;
    final companion = PlayerCompanionScope.of(context);
    final textTheme = baseTheme.textTheme.apply(
      bodyColor: menu.text,
      displayColor: menu.text,
    );
    return Theme(
      data: baseTheme.copyWith(
        textTheme: textTheme.copyWith(
          bodyLarge: context.playerTypography.dialogueStyle(
            menu.body.copyWith(
              fontSize: companion
                  ? 18
                  : landscape
                  ? 16
                  : 17,
              height: 1.5,
            ),
          ),
          labelLarge: context.playerTypography.dialogueStyle(
            menu.label.copyWith(fontSize: 14, height: 1.5),
          ),
        ),
      ),
      child: DecoratedBox(
        key: const ValueKey('player-dialogue-ligue-panel'),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(3),
          border: Border(left: BorderSide(color: menu.accent, width: 5)),
        ),
        child: DefaultTextStyle(
          style: menu.body,
          child: IconTheme(
            data: IconThemeData(color: menu.text),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                contentPadding + 5,
                companion
                    ? contentPadding
                    : landscape
                    ? 14
                    : contentPadding,
                contentPadding,
                companion
                    ? contentPadding
                    : landscape
                    ? 14
                    : contentPadding,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogueLineContent extends StatelessWidget {
  const _DialogueLineContent({
    required this.data,
    required this.dialogue,
    required this.portraitBuilder,
    required this.resolvedPortrait,
    required this.showSpeakerName,
    required this.pageKey,
    this.preferredMaxHeight,
  });
  final PlayerDialogueViewData data;
  final ProjectDialoguePresentationProfile? dialogue;
  final Widget Function(String speaker)? portraitBuilder;
  final Widget? resolvedPortrait;
  final bool showSpeakerName;
  final GlobalKey<_DialogueTextPagesState> pageKey;
  final double? preferredMaxHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final speaker = data.speaker;
      final portrait =
          resolvedPortrait ??
          (speaker == null ? null : portraitBuilder?.call(speaker));
      final profile = dialogue;
      final dimension = math.min(
        profile == null
            ? (constraints.maxWidth < 420 ? 72.0 : 96.0)
            : constraints.maxWidth < 320
            ? profile.portraitSize.clamp(48.0, 72.0)
            : profile.portraitSize,
        math.min(
              constraints.maxHeight,
              preferredMaxHeight ?? constraints.maxHeight,
            ) *
            .48,
      );
      final textWidth = math.max(
        1.0,
        constraints.maxWidth -
            (portrait == null ? 0 : dimension + PlayerSpacing.md),
      );
      final scaler = MediaQuery.textScalerOf(context);
      double measure(String value, TextStyle style, {int? maxLines}) {
        final painter = TextPainter(
          text: TextSpan(
            text: value,
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: maxLines,
          ellipsis: maxLines == null ? null : '…',
        )..layout(maxWidth: textWidth);
        final height = painter.height;
        painter.dispose();
        return height;
      }

      final speakerHeight = speaker != null && showSpeakerName
          ? measure(
                  speaker,
                  context.playerTypography.dialogueStyle(
                    Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
                  ),
                  maxLines: profile == null ? null : 2,
                ) +
                PlayerSpacing.sm +
                (profile != null &&
                        profile.nameplateStyle !=
                            ProjectDialogueNameplateStyle.inline
                    ? 10
                    : 0)
          : 0.0;
      final bodyStyle = context.playerTypography.dialogueStyle(
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
      );
      final footerHeight = _dialogueFooterHeight(context);
      final minimumHeight =
          speakerHeight + measure('M', bodyStyle) + 12 + footerHeight;
      final naturalHeight =
          speakerHeight + measure(data.fullText, bodyStyle) + 12 + footerHeight;
      final height = math.min(
        constraints.maxHeight,
        math.max(
          math.max(portrait == null ? 0.0 : dimension, minimumHeight),
          math.min(preferredMaxHeight ?? constraints.maxHeight, naturalHeight),
        ),
      );
      Widget text() => ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (speaker != null && showSpeakerName) ...[
              profile == null
                  ? Text(
                      speaker,
                      style: context.playerTypography
                          .dialogueStyle(
                            Theme.of(context).textTheme.labelLarge ??
                                const TextStyle(),
                          )
                          .copyWith(
                            color: PokeMapPlayerMenuTheme.resolve(
                              context,
                              role: ProjectPresentationSurfaceRole.dialogue,
                              opaque: true,
                            ).accent,
                          ),
                    )
                  : _DialogueNameplate(speaker: speaker, dialogue: profile),
              const SizedBox(height: PlayerSpacing.sm),
            ],
            Expanded(
              child: _DialogueTextPages(key: pageKey, data: data),
            ),
          ],
        ),
      );
      if (portrait == null) return SizedBox(height: height, child: text());
      Widget framed = profile == null
          ? PlayerPortraitFrame(
              key: ValueKey((
                'dialogue-portrait-frame',
                portrait.key ?? speaker,
              )),
              dimension: dimension,
              child: portrait,
            )
          : _DialoguePortraitFrame(
              key: ValueKey((
                'dialogue-portrait-frame',
                portrait.key ?? speaker,
              )),
              dimension: dimension,
              shape: profile.portraitShape,
              borderWidth: profile.portraitFrameWidth,
              borderColor:
                  PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                    profile.portraitFrameColor,
                  ) ??
                  context.playerColors.outline,
              child: portrait,
            );
      final transition = context.playerMotion.fast == Duration.zero
          ? ProjectDialoguePortraitTransition.none
          : profile?.portraitTransition ??
                ProjectDialoguePortraitTransition.fade;
      framed = AnimatedSwitcher(
        key: profile == null
            ? null
            : ValueKey('dialogue-portrait-transition-${transition.name}'),
        duration: transition == ProjectDialoguePortraitTransition.none
            ? Duration.zero
            : Duration(
                milliseconds:
                    profile?.portraitTransitionMilliseconds ??
                    context.playerMotion.fast.inMilliseconds,
              ),
        transitionBuilder: (child, animation) => switch (transition) {
          ProjectDialoguePortraitTransition.none => child,
          ProjectDialoguePortraitTransition.fade => FadeTransition(
            opacity: animation,
            child: child,
          ),
          ProjectDialoguePortraitTransition.scale => ScaleTransition(
            scale: Tween<double>(begin: .9, end: 1).animate(animation),
            child: child,
          ),
          ProjectDialoguePortraitTransition.slide => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.08, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        },
        child: framed,
      );
      final semanticPortrait = speaker == null || showSpeakerName
          ? ExcludeSemantics(child: framed)
          : Semantics(
              container: true,
              image: true,
              label: 'Portrait de $speaker',
              child: framed,
            );
      return SizedBox(
        height: height,
        child: Row(
          key: profile == null
              ? null
              : ValueKey('dialogue-portrait-${profile.portraitSide.name}'),
          textDirection:
              profile?.portraitSide == ProjectDialoguePortraitSide.end
              ? _opposite(Directionality.of(context))
              : Directionality.of(context),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            semanticPortrait,
            const SizedBox(width: PlayerSpacing.md),
            Expanded(child: text()),
          ],
        ),
      );
    },
  );
}

class _DialogueTextPages extends StatefulWidget {
  const _DialogueTextPages({
    super.key,
    required this.data,
    this.promptOnly = false,
  });
  final PlayerDialogueViewData data;
  final bool promptOnly;
  @override
  State<_DialogueTextPages> createState() => _DialogueTextPagesState();
}

class _DialogueTextPagesState extends State<_DialogueTextPages> {
  var _page = 0;
  var _count = 1;

  @override
  void didUpdateWidget(_DialogueTextPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.fullText != widget.data.fullText ||
        oldWidget.data.speaker != widget.data.speaker) {
      _page = 0;
    }
  }

  void resetPage() => _page = 0;

  bool nextPage() {
    if (_page + 1 >= _count) return false;
    setState(() => _page++);
    return true;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final data = widget.data;
      final style = DefaultTextStyle.of(context).style.merge(
        context.playerTypography.dialogueStyle(
          Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
        ),
      );
      final scaler = MediaQuery.textScalerOf(context);
      final footerHeight = _dialogueFooterHeight(context);

      final visible = data.lineSpan ?? TextSpan(text: data.text);
      final full = data.isCurrentLineFullyRevealed
          ? visible
          : TextSpan(text: data.fullText);
      final plain = full.toPlainText(includeSemanticsLabels: false);
      final painter = TextPainter(
        text: TextSpan(style: style, children: [full]),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      );
      final placeholders = <PlaceholderDimensions>[];
      void collect(InlineSpan span) {
        if (span is WidgetSpan) {
          final child = span.child;
          final width = child is RawImage
              ? child.width
              : child is SizedBox
              ? child.width
              : null;
          final height = child is RawImage
              ? child.height
              : child is SizedBox
              ? child.height
              : null;
          placeholders.add(
            PlaceholderDimensions(
              size: Size(width ?? scaler.scale(16), height ?? scaler.scale(16)),
              alignment: span.alignment,
              baseline: span.baseline,
              baselineOffset: height ?? scaler.scale(16),
            ),
          );
        } else if (span is TextSpan) {
          for (final child in span.children ?? const <InlineSpan>[]) {
            collect(child);
          }
        }
      }

      collect(full);
      if (placeholders.isNotEmpty) {
        painter.setPlaceholderDimensions(placeholders);
      }
      painter.layout(maxWidth: constraints.maxWidth);
      final effectiveFooterHeight = widget.promptOnly
          ? (painter.height > constraints.maxHeight + .5 ? 48.0 : 0.0)
          : footerHeight;
      final available = math.max(
        scaler.scale(style.fontSize ?? 16) * 1.25,
        constraints.maxHeight -
            effectiveFooterHeight -
            (effectiveFooterHeight > 0 ? 12 : 0),
      );
      final lines = painter.computeLineMetrics();
      final ranges = <TextRange>[];
      var start = 0;
      var pageTop = 0.0;
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (index > 0 &&
            line.baseline + line.descent - pageTop > available + .5) {
          final position = painter.getPositionForOffset(
            Offset(0, line.baseline - line.ascent / 2),
          );
          final end = painter.getLineBoundary(position).start;
          if (end > start) {
            ranges.add(TextRange(start: start, end: end));
            start = end;
            pageTop = line.baseline - line.ascent;
          }
        }
      }
      ranges.add(TextRange(start: start, end: plain.length));
      painter.dispose();
      _count = ranges.length;
      _page = _page.clamp(0, _count - 1);
      final range = ranges[_page];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text.rich(
                _dialogueSpanRange(visible, range.start, range.end),
                key: const ValueKey('dialogue-page-text'),
                style: style,
              ),
            ),
          ),
          if (effectiveFooterHeight > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: effectiveFooterHeight,
              child: widget.promptOnly
                  ? Row(
                      children: [
                        IconButton(
                          key: const ValueKey('dialogue-question-previous'),
                          constraints: const BoxConstraints.tightFor(
                            width: 48,
                            height: 48,
                          ),
                          onPressed: _page > 0
                              ? () => setState(() => _page--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            '${_page + 1} / $_count',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('dialogue-question-next'),
                          constraints: const BoxConstraints.tightFor(
                            width: 48,
                            height: 48,
                          ),
                          onPressed: _page + 1 < _count
                              ? () => setState(() => _page++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (_count > 1)
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_page + 1} / $_count',
                                key: const ValueKey('dialogue-page-count'),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        Expanded(
                          child: _DialogueAdvanceLabel(
                            data: data,
                            hasMorePages: _page + 1 < _count,
                            compact: constraints.maxWidth < 200,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      );
    },
  );
}

InlineSpan _dialogueSpanRange(InlineSpan source, int start, int end) {
  var offset = 0;
  InlineSpan visit(InlineSpan span) {
    if (span is WidgetSpan) {
      final include = offset >= start && offset < end;
      offset++;
      return include ? span : const TextSpan();
    }
    if (span is! TextSpan) return const TextSpan();
    final text = span.text ?? '';
    final from = (start - offset).clamp(0, text.length);
    final to = (end - offset).clamp(0, text.length);
    offset += text.length;
    final children = [
      for (final child in span.children ?? const <InlineSpan>[]) visit(child),
    ];
    return TextSpan(
      text: text.substring(from, math.max(from, to)),
      style: span.style,
      children: children,
      recognizer: span.recognizer,
      locale: span.locale,
    );
  }

  return visit(source);
}

class _DialoguePortraitFrame extends StatelessWidget {
  const _DialoguePortraitFrame({
    super.key,
    required this.dimension,
    required this.shape,
    required this.borderWidth,
    required this.borderColor,
    required this.child,
  });

  final double dimension;
  final ProjectDialoguePortraitShape shape;
  final double borderWidth;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: borderColor, width: borderWidth);
    final frameShape = switch (shape) {
      ProjectDialoguePortraitShape.circle => CircleBorder(side: side),
      ProjectDialoguePortraitShape.rounded => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: side,
      ),
      ProjectDialoguePortraitShape.square => RoundedRectangleBorder(side: side),
      ProjectDialoguePortraitShape.cutCorner => BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: side,
      ),
    };
    return Material(
      key: ValueKey<String>('dialogue-portrait-shape-${shape.name}'),
      color: context.playerColors.surface,
      shape: frameShape,
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(dimension: dimension, child: child),
    );
  }
}

class _DialogueNameplate extends StatelessWidget {
  const _DialogueNameplate({required this.speaker, required this.dialogue});

  final String speaker;
  final ProjectDialoguePresentationProfile dialogue;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      speaker,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.playerTypography
          .dialogueStyle(
            Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
          )
          .copyWith(
            color:
                PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                  dialogue.nameplateTextColor,
                ) ??
                PokeMapPlayerMenuTheme.resolve(
                  context,
                  role: ProjectPresentationSurfaceRole.dialogue,
                  opaque: true,
                ).accent,
          ),
    );
    if (dialogue.nameplateStyle == ProjectDialogueNameplateStyle.inline) {
      return KeyedSubtree(
        key: const ValueKey<String>('dialogue-nameplate-inline'),
        child: text,
      );
    }
    final badge = Material(
      key: ValueKey<String>(
        'dialogue-nameplate-${dialogue.nameplateStyle.name}',
      ),
      color:
          PokeMapPlayerProjectColorResolver.tryOpaqueHex(
            dialogue.nameplateSurfaceColor,
          ) ??
          context.playerColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color:
              PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                dialogue.nameplateBorderColor,
              ) ??
              context.playerColors.outline,
          width: dialogue.nameplateBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: text,
      ),
    );
    return dialogue.nameplateStyle == ProjectDialogueNameplateStyle.floating
        ? Transform.translate(offset: const Offset(0, -6), child: badge)
        : badge;
  }
}

TextDirection _opposite(TextDirection direction) =>
    direction == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr;

double _dialogueFooterHeight(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  return context.playerDialogueProfile == null &&
          context.playerWindowTheme == null
      ? math.max(48, scaler.scale(20) + 20)
      : math.max(28, scaler.scale(14) * 1.5);
}

class _DialogueAdvanceLabel extends StatelessWidget {
  const _DialogueAdvanceLabel({
    required this.data,
    this.hasMorePages = false,
    this.compact = false,
  });

  final PlayerDialogueViewData data;
  final bool hasMorePages;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!data.isAdvanceAvailable) {
      return const Align(
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.more_horiz_rounded,
          key: ValueKey<String>('dialogue-progress-indicator-pending'),
        ),
      );
    }
    final dialogue = context.playerDialogueProfile;
    final kind = data.isCurrentLineFullyRevealed
        ? dialogue?.progressIndicator ??
              ProjectDialogueProgressIndicator.chevron
        : ProjectDialogueProgressIndicator.arrow;
    final color = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      dialogue?.progressIndicatorColor,
    );
    final icon = switch (kind) {
      ProjectDialogueProgressIndicator.chevron => Icons.navigate_next_rounded,
      ProjectDialogueProgressIndicator.arrow => Icons.arrow_forward_rounded,
      ProjectDialogueProgressIndicator.dots => Icons.more_horiz_rounded,
      ProjectDialogueProgressIndicator.none => null,
    };
    final label = !data.isCurrentLineFullyRevealed
        ? context.playerL10n.showFullText
        : data.isLastContent && !hasMorePages
        ? context.playerL10n.close
        : context.playerL10n.next;
    if (dialogue == null && context.playerWindowTheme == null) {
      final menu = PokeMapPlayerMenuTheme.resolve(
        context,
        role: ProjectPresentationSurfaceRole.dialogue,
        opaque: true,
      );
      final companion = PlayerCompanionScope.of(context);
      final foreground = companion ? menu.text : menu.selectionText;
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: companion ? double.infinity : null,
          child: DecoratedBox(
            key: const ValueKey('player-dialogue-ligue-advance'),
            decoration: BoxDecoration(
              color: companion ? menu.recessed : menu.selectionTop,
              borderRadius: BorderRadius.circular(3),
              border: Border(left: BorderSide(color: menu.accent, width: 3)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: companion ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (compact && icon != null)
                      Icon(icon, color: foreground)
                    else
                      Flexible(
                        child: Text(
                          label,
                          style: menu.actionLabel.copyWith(color: foreground),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(
            icon,
            key: ValueKey<String>('dialogue-progress-indicator-${kind.name}'),
            color: color,
          ),
          const SizedBox(width: PlayerSpacing.xxs),
        ] else
          const SizedBox.shrink(
            key: ValueKey<String>('dialogue-progress-indicator-none'),
          ),
        if (!compact || icon == null)
          Flexible(
            child: Text(
              !data.isCurrentLineFullyRevealed
                  ? context.playerL10n.showFullText
                  : data.isLastContent && !hasMorePages
                  ? context.playerL10n.close
                  : context.playerL10n.next,
              textAlign: TextAlign.end,
            ),
          ),
      ],
    );
  }
}

class _DialogueChoiceContent extends StatefulWidget {
  const _DialogueChoiceContent({
    required this.data,
    required this.onAction,
    required this.showSpeakerName,
    this.portrait,
    this.preferredMaxHeight,
  });

  final PlayerDialogueViewData data;
  final ValueChanged<PlayerDialogueAction> onAction;
  final bool showSpeakerName;
  final Widget? portrait;
  final double? preferredMaxHeight;

  @override
  State<_DialogueChoiceContent> createState() => _DialogueChoiceContentState();
}

class _DialogueChoiceContentState extends State<_DialogueChoiceContent> {
  final _choiceKeys = <int, GlobalKey>{};
  final _choiceFocus = <int, FocusNode>{};
  int? _focusedSelection;
  double? _choicesHeight;
  PlayerDialogueViewData get data => widget.data;
  ValueChanged<PlayerDialogueAction> get onAction => widget.onAction;

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(covariant _DialogueChoiceContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.data.choices
        .where((choice) => choice.selected)
        .firstOrNull
        ?.index;
    final selected = data.choices
        .where((choice) => choice.selected)
        .firstOrNull
        ?.index;
    if (previous != selected) {
      _revealSelected();
    }
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selected = data.choices
          .where((choice) => choice.selected)
          .firstOrNull;

      if (selected != null && selected.enabled) {
        _choiceFocus[selected.index]?.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final focus in _choiceFocus.values) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogue = context.playerDialogueProfile;
    final spacing = math.max(8.0, dialogue?.choiceSpacing ?? PlayerSpacing.xs);
    final authoredSelectedColor =
        PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          dialogue?.choiceSelectedColor,
        );
    final menuTheme = PokeMapPlayerMenuTheme.resolve(
      context,
      role: ProjectPresentationSurfaceRole.dialogue,
      opaque: true,
    );
    final selectedColor =
        authoredSelectedColor ??
        (dialogue == null ? menuTheme.selectionTop : menuTheme.accent);
    final selectedForeground = authoredSelectedColor == null
        ? menuTheme.selectionText
        : ThemeData.estimateBrightnessForColor(selectedColor) == Brightness.dark
        ? context.playerColors.onPrimary
        : context.playerColors.textPrimary;
    final shape = dialogue == null
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))
        : switch (dialogue.choiceShape) {
            ProjectDialogueChoiceShape.pill => const StadiumBorder(),
            ProjectDialogueChoiceShape.rectangle =>
              const RoundedRectangleBorder(),
            ProjectDialogueChoiceShape.cutCorner =>
              const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            _ => const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          };
    final selected = data.choices
        .where((choice) => choice.selected && choice.enabled)
        .firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasPrompt = data.fullText.isNotEmpty;
        final wide = constraints.maxWidth >= 600;
        final columns = wide ? 2 : 1;
        final questionWidth = constraints.maxWidth;
        final choiceWidth = wide
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        final textStyle = context.playerTypography.dialogueStyle(
          Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
        );
        final speakerStyle = context.playerTypography.dialogueStyle(
          Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
        );
        double measure(String text, TextStyle style, double width) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: DefaultTextStyle.of(context).style.merge(style),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: math.max(1, width));
          final height = painter.height;
          painter.dispose();
          return height;
        }

        final speakerHeight = widget.showSpeakerName && data.speaker != null
            ? measure(data.speaker!, speakerStyle, questionWidth) + 8
            : 0.0;
        final questionHeight = hasPrompt
            ? math.max(
                widget.portrait == null ? 0.0 : 64.0,
                speakerHeight +
                    2 +
                    measure(
                      data.fullText,
                      textStyle,
                      questionWidth - (widget.portrait == null ? 0 : 80),
                    ),
              )
            : measure(
                context.playerL10n.yourChoice,
                speakerStyle,
                questionWidth,
              );
        final buttonStyle = context.playerTypography.bodyStyle(
          Theme.of(context).textTheme.labelLarge ??
              const TextStyle(fontSize: 14),
        );
        final minimumChoice = data.choices.fold<double>(
          64,
          (height, choice) => math.max(
            height,
            measure(choice.label, buttonStyle, choiceWidth - 80) + 36,
          ),
        );
        double extent(PlayerDialogueChoiceViewData choice) => math.max(
          64,
          measure(choice.label, buttonStyle, choiceWidth - 80) + 36,
        );
        var estimatedChoicesHeight = 0.0;
        for (var i = 0; i < data.choices.length; i += columns) {
          if (i > 0) estimatedChoicesHeight += spacing;
          estimatedChoicesHeight += columns == 1 || i + 1 >= data.choices.length
              ? extent(data.choices[i])
              : math.max(extent(data.choices[i]), extent(data.choices[i + 1]));
        }
        final choicesHeight = _choicesHeight ?? estimatedChoicesHeight;
        final questionFloor = hasPrompt
            ? math.min(
                questionHeight,
                speakerHeight + measure('M', textStyle, questionWidth) + 60,
              )
            : questionHeight;
        final choiceFloor = math.min(
          choicesHeight,
          data.choices.length <= 2
              ? math.max(
                  minimumChoice + 56,
                  constraints.maxHeight - questionFloor - 16,
                )
              : minimumChoice + 56,
        );
        final natural = questionHeight + 16 + choicesHeight;
        final minimum = questionFloor + 16 + choiceFloor;
        final height = math.min(
          constraints.maxHeight,
          math.max(
            math.min(minimum, constraints.maxHeight),
            math.min(
              natural,
              widget.preferredMaxHeight ?? constraints.maxHeight,
            ),
          ),
        );
        final allocatedQuestion = math.min(
          questionHeight,
          math.max(0.0, height - 16 - choiceFloor),
        );
        final question = hasPrompt
            ? _DialogueChoicePrompt(
                data: data,
                showSpeakerName: widget.showSpeakerName,
                portrait: widget.portrait,
              )
            : Text(context.playerL10n.yourChoice, style: speakerStyle);
        Widget choiceButton(PlayerDialogueChoiceViewData choice) =>
            PlayerActionButton(
              key: ValueKey<String>('dialogue-choice-${choice.index}'),
              label: choice.label,
              labelMaxLines: 8,
              icon: choice.selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              autofocus: false,
              focusNode: _choiceFocus.putIfAbsent(choice.index, FocusNode.new),
              selected: choice.selected,
              secondary: !choice.selected,
              shape: shape,
              backgroundColor: choice.selected ? selectedColor : null,
              foregroundColor: choice.selected
                  ? selectedForeground
                  : menuTheme.text,
              disabledOpacity: dialogue?.choiceDisabledOpacity ?? 1,
              onPressed: choice.enabled
                  ? () => onAction(
                      PlayerDialogueSelectChoiceAction(
                        snapshotRevision: data.revision,
                        choiceIndex: choice.index,
                      ),
                    )
                  : null,
            );
        final choices = PlayerPagedList(
          spacing: spacing,
          onContentHeightChanged: (height) {
            if (mounted &&
                (_choicesHeight == null ||
                    (_choicesHeight! - height).abs() > .5)) {
              setState(() => _choicesHeight = height);
            }
          },
          revealChildKey: selected == null
              ? null
              : _choiceKeys.putIfAbsent(
                  selected.index ~/ columns * columns,
                  GlobalKey.new,
                ),
          onPageReady: () {
            if (selected != null && _focusedSelection != selected.index) {
              _focusedSelection = selected.index;
              _choiceFocus[selected.index]?.requestFocus();
            }
          },
          children: [
            for (var i = 0; i < data.choices.length; i += columns)
              KeyedSubtree(
                key: _choiceKeys.putIfAbsent(i, GlobalKey.new),
                child: columns == 1
                    ? choiceButton(data.choices[i])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: choiceButton(data.choices[i])),
                          SizedBox(width: spacing),
                          Expanded(
                            child: i + 1 < data.choices.length
                                ? choiceButton(data.choices[i + 1])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
              ),
          ],
        );
        return SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: allocatedQuestion, child: question),
              const SizedBox(height: 16),
              Expanded(child: choices),
            ],
          ),
        );
      },
    );
  }
}

String _semanticLabel(PlayerDialogueViewData data, bool showSpeakerName) {
  return switch (data.mode) {
    PlayerDialogueMode.line =>
      '${data.speaker == null || !showSpeakerName ? '' : '${data.speaker}, '}${data.fullText}',
    PlayerDialogueMode.choices =>
      'Choix de dialogue, ${data.choices.length} options',
  };
}

class _DialogueChoicePrompt extends StatelessWidget {
  const _DialogueChoicePrompt({
    required this.data,
    required this.showSpeakerName,
    this.portrait,
  });
  final PlayerDialogueViewData data;
  final bool showSpeakerName;
  final Widget? portrait;
  @override
  Widget build(BuildContext context) {
    final profile = context.playerDialogueProfile;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSpeakerName && data.speaker != null) ...[
          profile == null
              ? Text(
                  data.speaker!,
                  style: context.playerTypography
                      .dialogueStyle(
                        Theme.of(context).textTheme.labelLarge ??
                            const TextStyle(),
                      )
                      .copyWith(
                        color: PokeMapPlayerMenuTheme.resolve(
                          context,
                          role: ProjectPresentationSurfaceRole.dialogue,
                          opaque: true,
                        ).accent,
                      ),
                )
              : _DialogueNameplate(speaker: data.speaker!, dialogue: profile),
          const SizedBox(height: 8),
        ],
        Expanded(child: _DialogueTextPages(data: data, promptOnly: true)),
      ],
    );
    return portrait == null
        ? content
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profile == null
                  ? PlayerPortraitFrame(dimension: 64, child: portrait!)
                  : _DialoguePortraitFrame(
                      dimension: 64,
                      shape: profile.portraitShape,
                      borderWidth: profile.portraitFrameWidth,
                      borderColor:
                          PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                            profile.portraitFrameColor,
                          ) ??
                          context.playerColors.outline,
                      child: portrait!,
                    ),
              const SizedBox(width: 16),
              Expanded(child: content),
            ],
          );
  }
}

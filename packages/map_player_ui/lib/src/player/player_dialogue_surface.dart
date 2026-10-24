import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../foundation/player_paged_layout.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_dialogue_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';

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
    return SafeArea(
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
              PlayerSpacing.md * (resolved?.spacingScale ?? 1);
          return Padding(
            padding: EdgeInsets.all(margin),
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
                  maxWidth: resolved == null
                      ? dialogue == null
                            ? 760
                            : constraints.maxWidth * dialogue.maxWidthFactor
                      : dialogue == null
                      ? constraints.maxWidth * resolved.maxWidthFactor
                      : constraints.maxWidth * dialogue.maxWidthFactor,
                  maxHeight:
                      resolved == null && data.mode != PlayerDialogueMode.line
                      ? constraints.maxHeight * 0.58
                      : constraints.maxHeight - margin * 2,
                ),
                child: PlayerPanel(
                  elevated: true,
                  role: PlayerPanelRole.dialogue,
                  surfaceRole: ProjectPresentationSurfaceRole.dialogue,
                  padding: EdgeInsets.all(contentPadding),
                  windowStyleOverride: dialogue == null
                      ? null
                      : ProjectWindowStyleProfile(
                          id: 'dialogue-v9',
                          shape: dialogue.shape,
                          borderWidth: dialogue.borderWidth.round(),
                          cornerRadius: dialogue.cornerRadius.round(),
                          contentPadding: dialogue.contentPadding.round(),
                          shadowElevation: 8,
                          fillOpacity: dialogue.fillOpacity,
                          fillToken: 'dialogueSurface',
                          borderToken: 'outline',
                        ),
                  surfaceColorOverride:
                      PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                        dialogue?.surfaceColor,
                      ),
                  borderColorOverride:
                      PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                        dialogue?.borderColor,
                      ),
                  textColorOverride:
                      PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                        dialogue?.textColor,
                      ),
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
                    Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
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
      final footerHeight = math.max(28.0, scaler.scale(14) * 1.5);
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
                            Theme.of(context).textTheme.titleLarge ??
                                const TextStyle(),
                          )
                          .copyWith(color: context.playerColors.primary),
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
  const _DialogueTextPages({super.key, required this.data});
  final PlayerDialogueViewData data;
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
      final footerHeight = math.max(28.0, scaler.scale(14) * 1.5);
      final available = math.max(
        scaler.scale(style.fontSize ?? 16) * 1.25,
        constraints.maxHeight - footerHeight - 12,
      );
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
          const SizedBox(height: 12),
          SizedBox(
            height: footerHeight,
            child: Row(
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
            Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
          )
          .copyWith(
            color:
                PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                  dialogue.nameplateTextColor,
                ) ??
                context.playerColors.primary,
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
  const _DialogueChoiceContent({required this.data, required this.onAction});

  final PlayerDialogueViewData data;
  final ValueChanged<PlayerDialogueAction> onAction;

  @override
  State<_DialogueChoiceContent> createState() => _DialogueChoiceContentState();
}

class _DialogueChoiceContentState extends State<_DialogueChoiceContent> {
  final _choiceKeys = <int, GlobalKey>{};
  final _choiceFocus = <int, FocusNode>{};
  int? _focusedSelection;
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
    final selectedColor = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      dialogue?.choiceSelectedColor,
    );
    final selectedForeground = selectedColor == null
        ? null
        : ThemeData.estimateBrightnessForColor(selectedColor) == Brightness.dark
        ? context.playerColors.onPrimary
        : context.playerColors.textPrimary;
    final shape = switch (dialogue?.choiceShape) {
      ProjectDialogueChoiceShape.pill => const StadiumBorder(),
      ProjectDialogueChoiceShape.rectangle => const RoundedRectangleBorder(),
      ProjectDialogueChoiceShape.cutCorner => const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      _ => const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    };
    final selected = data.choices
        .where((choice) => choice.selected && choice.enabled)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.playerL10n.yourChoice,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PlayerPagedList(
            spacing: spacing,
            revealChildKey: selected == null
                ? null
                : _choiceKeys.putIfAbsent(selected.index, GlobalKey.new),
            onPageReady: () {
              if (selected != null && _focusedSelection != selected.index) {
                _focusedSelection = selected.index;
                _choiceFocus[selected.index]?.requestFocus();
              }
            },
            children: <Widget>[
              for (final choice in data.choices) ...<Widget>[
                KeyedSubtree(
                  key: _choiceKeys.putIfAbsent(choice.index, GlobalKey.new),
                  child: PlayerActionButton(
                    key: ValueKey<String>('dialogue-choice-${choice.index}'),
                    label: choice.label,
                    icon: choice.selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    autofocus: false,
                    focusNode: _choiceFocus.putIfAbsent(
                      choice.index,
                      FocusNode.new,
                    ),
                    selected: choice.selected,
                    secondary: !choice.selected,
                    shape: shape,
                    backgroundColor: choice.selected ? selectedColor : null,
                    foregroundColor: choice.selected
                        ? selectedForeground
                        : null,
                    disabledOpacity: dialogue?.choiceDisabledOpacity ?? 1,
                    onPressed: choice.enabled
                        ? () => onAction(
                            PlayerDialogueSelectChoiceAction(
                              snapshotRevision: data.revision,
                              choiceIndex: choice.index,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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

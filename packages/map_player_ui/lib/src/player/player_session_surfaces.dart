import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_paged_layout.dart';
import '../foundation/player_menu_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_menu_theme.dart';

class PlayerDetailEntryCard extends StatelessWidget {
  const PlayerDetailEntryCard({
    super.key,
    required this.entry,
    this.surfaceRole,
  });

  final RuntimePlayerDetailEntrySnapshot entry;
  final ProjectPresentationSurfaceRole? surfaceRole;

  @override
  Widget build(BuildContext context) => PlayerMenuThemeScope(
    role: surfaceRole ?? ProjectPresentationSurfaceRole.notification,
    child: Builder(
      builder: (context) => PlayerMenuPanel(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: entry.title,
          value: entry.trailingLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: context.playerMenuTheme.label,
                    ),
                  ),
                  if (entry.trailingLabel case final trailing?)
                    Flexible(
                      child: Text(
                        trailing,
                        style: context.playerMenuTheme.meta,
                      ),
                    ),
                ],
              ),
              if (entry.subtitle case final subtitle?) ...[
                const SizedBox(height: 8),
                Text(subtitle, style: context.playerMenuTheme.body),
              ],
              if (entry.progress case final progress?) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  color: context.playerMenuTheme.accent,
                  backgroundColor: context.playerMenuTheme.recessed,
                ),
              ],
            ],
          ),
        ),
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
  Widget build(BuildContext context) => PlayerSessionPanel(
    title: context.playerL10n.loading,
    framed: false,
    titleAlign: TextAlign.center,
    body: [
      Text(stage, textAlign: TextAlign.center),
      Semantics(
        liveRegion: true,
        value: progress == null ? null : '${(progress! * 100).round()} %',
        child: Builder(
          builder: (context) => TickerMode(
            enabled: progress != null,
            child: LinearProgressIndicator(
              value: progress,
              color: context.playerMenuTheme.accent,
              backgroundColor: context.playerMenuTheme.recessed,
              minHeight: 4,
            ),
          ),
        ),
      ),
    ],
    actions: [
      if (onCancel != null)
        PlayerActionButton(
          labelMaxLines: 3,
          label: context.playerL10n.cancel,
          icon: Icons.close,
          onPressed: onCancel,
        ),
    ],
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
  Widget build(BuildContext context) => PlayerSessionPanel(
    icon: Icons.emoji_events_rounded,
    title: title,
    surfaceRole: ProjectPresentationSurfaceRole.battleResult,
    body: [
      Text(summary, textAlign: TextAlign.center),
      for (final detail in details) Text(detail, textAlign: TextAlign.center),
    ],
    actions: [
      PlayerActionButton(
        labelMaxLines: 3,
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
    this.contributors = const [],
    this.licenses = const [],
    required this.onReturnToTitle,
    required this.onReturnToHub,
  });

  final String title;
  final String author;
  final String? endingLabel;
  final List<String> contributors;
  final List<String> licenses;
  final VoidCallback? onReturnToTitle;
  final VoidCallback? onReturnToHub;

  @override
  Widget build(BuildContext context) => PlayerSessionPanel(
    icon: Icons.auto_stories_rounded,
    title: title,
    surfaceRole: ProjectPresentationSurfaceRole.credits,
    body: [
      Text(author, style: Theme.of(context).textTheme.titleLarge),
      if (endingLabel != null) Text(endingLabel!, textAlign: TextAlign.center),
      for (final contributor in contributors)
        Text(contributor, textAlign: TextAlign.center),
      for (final license in licenses)
        Text(license, textAlign: TextAlign.center),
    ],
    actions: [
      PlayerActionButton(
        labelMaxLines: 3,
        label: context.playerL10n.returnToTitle,
        icon: Icons.title_rounded,
        autofocus: onReturnToTitle != null,
        onPressed: onReturnToTitle,
        disabledReason: onReturnToTitle == null
            ? context.playerL10n.directReturnHub
            : null,
      ),
      PlayerActionButton(
        labelMaxLines: 3,
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
  Widget build(BuildContext context) => PlayerSessionPanel(
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
        Builder(
          builder: (context) => Text(
            code!,
            textAlign: TextAlign.center,
            style: context.playerMenuTheme.meta.copyWith(
              color: context.playerMenuTheme.danger,
            ),
          ),
        ),
      if (stage != null)
        Builder(
          builder: (context) => Text(
            stage!,
            textAlign: TextAlign.center,
            style: context.playerMenuTheme.meta,
          ),
        ),
    ],
    actions: [
      if (onRetry != null)
        PlayerActionButton(
          labelMaxLines: 3,
          label: context.playerL10n.retry,
          icon: Icons.refresh_rounded,
          autofocus: true,
          onPressed: onRetry,
        ),
      if (onReturnToHub != null)
        PlayerActionButton(
          labelMaxLines: 3,
          label: context.playerL10n.returnToHub,
          icon: Icons.home_rounded,
          secondary: true,
          autofocus: onRetry == null,
          onPressed: onReturnToHub,
        ),
      if (onCancel != null)
        PlayerActionButton(
          labelMaxLines: 3,
          label: context.playerL10n.close,
          icon: Icons.close_rounded,
          secondary: true,
          autofocus: onRetry == null && onReturnToHub == null,
          onPressed: onCancel,
        ),
      if (onShowDiagnostics != null)
        PlayerActionButton(
          labelMaxLines: 3,
          label: context.playerL10n.diagnostics,
          icon: Icons.health_and_safety_outlined,
          secondary: true,
          onPressed: onShowDiagnostics,
        ),
    ],
  );
}

class PlayerSessionPanel extends StatefulWidget {
  const PlayerSessionPanel({
    super.key,
    this.icon,
    required this.title,
    required this.body,
    required this.actions,
    this.iconColor,
    this.surfaceRole = ProjectPresentationSurfaceRole.notification,
    this.framed = true,
    this.titleAlign = TextAlign.start,
  });

  final IconData? icon;
  final String title;
  final List<Widget> body;
  final List<Widget> actions;
  final Color? iconColor;
  final ProjectPresentationSurfaceRole surfaceRole;
  final bool framed;
  final TextAlign titleAlign;

  @override
  State<PlayerSessionPanel> createState() => _PlayerSessionPanelState();
}

class _PlayerSessionPanelState extends State<PlayerSessionPanel> {
  double? _contentHeight;

  List<Widget> _bodyAtoms(BuildContext context, double width, double height) {
    final result = <Widget>[];
    for (var index = 0; index < widget.body.length; index++) {
      final child = widget.body[index];
      if (child is! Text || child.data == null) {
        result.add(
          KeyedSubtree(key: ValueKey('session-content-$index'), child: child),
        );
        continue;
      }
      final graphemes = child.data!.characters.toList();
      final style = context.playerMenuTheme.body.merge(child.style);
      final painter = TextPainter(
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      );
      var start = 0;
      var part = 0;
      while (start < graphemes.length) {
        var low = start + 1;
        var high = graphemes.length;
        var end = low;
        while (low <= high) {
          final middle = (low + high) ~/ 2;
          painter.text = TextSpan(
            text: graphemes.sublist(start, middle).join(),
            style: style,
          );
          painter.layout(maxWidth: width);
          if (painter.height <= height) {
            end = middle;
            low = middle + 1;
          } else {
            high = middle - 1;
          }
        }
        result.add(
          Text(
            graphemes.sublist(start, end).join(),
            key: ValueKey('session-paragraph-$index-${part++}'),
            style: style,
            textAlign: child.textAlign,
            textDirection: child.textDirection,
          ),
        );
        start = end;
      }
      painter.dispose();
      if (graphemes.isEmpty) result.add(child);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => PlayerMenuThemeScope(
    role: widget.surfaceRole,
    child: Builder(
      builder: (context) {
        final theme = context.playerMenuTheme;
        return ColoredBox(
          color: theme.backdrop,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(640.0, constraints.maxWidth);
                  final height = math.min(
                    constraints.maxHeight,
                    (_contentHeight ?? constraints.maxHeight) + 32,
                  );
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  final columns = width >= 440 && scale < 1.5 ? 2 : 1;
                  final content = SizedBox(
                    width: width,
                    height: height,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PlayerPagedList(
                        onContentHeightChanged: (value) {
                          if (mounted && _contentHeight != value) {
                            setState(() => _contentHeight = value);
                          }
                        },
                        children: [
                          Row(
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  size: 24,
                                  color: widget.iconColor ?? theme.text,
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Text(
                                  widget.title,
                                  key: const ValueKey('player-session-title'),
                                  textAlign: widget.titleAlign,
                                  style: theme.title,
                                ),
                              ),
                            ],
                          ),
                          ..._bodyAtoms(
                            context,
                            math.max(1, width - 32),
                            math.max(48, constraints.maxHeight - 88),
                          ),
                          for (
                            var i = 0;
                            i < widget.actions.length;
                            i += columns
                          )
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (
                                  var j = i;
                                  j <
                                      math.min(
                                        i + columns,
                                        widget.actions.length,
                                      );
                                  j++
                                ) ...[
                                  if (j > i) const SizedBox(width: 8),
                                  Expanded(child: widget.actions[j]),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                  return Center(
                    heightFactor: 1,
                    widthFactor: 1,
                    child: Semantics(
                      container: true,
                      namesRoute: true,
                      label: widget.title,
                      child: widget.framed
                          ? PlayerMenuPanel(
                              padding: EdgeInsets.zero,
                              child: content,
                            )
                          : DefaultTextStyle(style: theme.body, child: content),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}

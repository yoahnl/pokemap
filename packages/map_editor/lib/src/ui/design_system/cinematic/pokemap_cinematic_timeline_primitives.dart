import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../pokemap_tone.dart';

enum PokeMapCinematicTimelineClipState { normal, disabled, pending, error }

class PokeMapCinematicTimelineRuler extends StatelessWidget {
  const PokeMapCinematicTimelineRuler({
    super.key,
    required this.duration,
    required this.playhead,
    required this.pixelsPerSecond,
    required this.semanticLabel,
    this.height = 32,
  }) : assert(pixelsPerSecond > 0),
       assert(height > 0);

  final Duration duration;
  final Duration playhead;
  final double pixelsPerSecond;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final width = duration.inMilliseconds / 1000 * pixelsPerSecond;
    final normalizedPlayhead = playhead < Duration.zero
        ? Duration.zero
        : playhead > duration
        ? duration
        : playhead;
    return Semantics(
      container: true,
      label:
          '$semanticLabel. ${_formatDuration(normalizedPlayhead)} sur ${_formatDuration(duration)}',
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _PokeMapCinematicTimelineRulerPainter(
            duration: duration,
            playhead: normalizedPlayhead,
            pixelsPerSecond: pixelsPerSecond,
            divider: colors.divider,
            tick: colors.textMuted,
            playheadColor: colors.brandPrimary,
          ),
        ),
      ),
    );
  }
}

class PokeMapCinematicTrackRow extends StatelessWidget {
  const PokeMapCinematicTrackRow({
    super.key,
    required this.label,
    required this.icon,
    required this.child,
    this.disabled = false,
    this.headerWidth = 160,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final Widget child;
  final bool disabled;
  final double headerWidth;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final foreground = disabled ? colors.textDisabled : colors.textSecondary;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      enabled: !disabled,
      label: label,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Container(
              width: headerWidth,
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                border: Border(
                  right: BorderSide(color: colors.divider),
                  bottom: BorderSide(color: colors.divider),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.contentSurface,
                  border: Border(bottom: BorderSide(color: colors.divider)),
                ),
                child: Opacity(opacity: disabled ? 0.52 : 1, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PokeMapCinematicTimelineClip extends StatelessWidget {
  const PokeMapCinematicTimelineClip({
    super.key,
    required this.label,
    required this.duration,
    required this.pixelsPerSecond,
    this.tone = PokeMapTone.cinematic,
    this.state = PokeMapCinematicTimelineClipState.normal,
    this.stateLabel,
    this.selected = false,
    this.onPressed,
    this.startTrimLabel,
    this.endTrimLabel,
    this.onStartTrim,
    this.onEndTrim,
  }) : assert(pixelsPerSecond > 0);

  final String label;
  final Duration duration;
  final double pixelsPerSecond;
  final PokeMapTone tone;
  final PokeMapCinematicTimelineClipState state;
  final String? stateLabel;
  final bool selected;
  final VoidCallback? onPressed;
  final String? startTrimLabel;
  final String? endTrimLabel;
  final ValueChanged<double>? onStartTrim;
  final ValueChanged<double>? onEndTrim;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    final enabled = state != PokeMapCinematicTimelineClipState.disabled;
    final width = math.max(
      48.0,
      duration.inMilliseconds / 1000 * pixelsPerSecond,
    );
    final status = stateLabel?.trim();
    final semanticLabel = status == null || status.isEmpty
        ? label
        : '$label. $status';
    final background = state == PokeMapCinematicTimelineClipState.error
        ? colors.errorSoft
        : toneColors.soft;
    final border = state == PokeMapCinematicTimelineClipState.error
        ? colors.errorBorder
        : selected
        ? colors.brandPrimaryBorder
        : toneColors.border;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: onPressed != null,
      enabled: enabled,
      selected: selected,
      label: semanticLabel,
      onTap: enabled ? onPressed : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            width: width,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border, width: selected ? 2 : 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 12 : 8,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      if (state ==
                          PokeMapCinematicTimelineClipState.pending) ...[
                        SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: toneColors.icon,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (state == PokeMapCinematicTimelineClipState.error) ...[
                        Icon(
                          Icons.error_outline_rounded,
                          size: 14,
                          color: colors.error,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (status != null && status.isNotEmpty)
                              Text(
                                status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      state ==
                                          PokeMapCinematicTimelineClipState
                                              .error
                                      ? colors.error
                                      : colors.textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected && startTrimLabel != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _PokeMapCinematicTrimHandle(
                      semanticLabel: startTrimLabel!,
                      onDrag: onStartTrim,
                    ),
                  ),
                if (selected && endTrimLabel != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _PokeMapCinematicTrimHandle(
                      semanticLabel: endTrimLabel!,
                      onDrag: onEndTrim,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PokeMapCinematicStripHost extends StatelessWidget {
  const PokeMapCinematicStripHost({
    super.key,
    required this.semanticLabel,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  final String semanticLabel;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      image: true,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _PokeMapCinematicTrimHandle extends StatelessWidget {
  const _PokeMapCinematicTrimHandle({
    required this.semanticLabel,
    required this.onDrag,
  });

  final String semanticLabel;
  final ValueChanged<double>? onDrag;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      label: semanticLabel,
      enabled: onDrag != null,
      child: MouseRegion(
        cursor: onDrag == null
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDrag == null ? null : () {},
          onHorizontalDragUpdate: onDrag == null
              ? null
              : (details) => onDrag!(details.delta.dx),
          child: SizedBox(
            width: 12,
            child: Center(
              child: Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.brandPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PokeMapCinematicTimelineRulerPainter extends CustomPainter {
  const _PokeMapCinematicTimelineRulerPainter({
    required this.duration,
    required this.playhead,
    required this.pixelsPerSecond,
    required this.divider,
    required this.tick,
    required this.playheadColor,
  });

  final Duration duration;
  final Duration playhead;
  final double pixelsPerSecond;
  final Color divider;
  final Color tick;
  final Color playheadColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      Paint()..color = divider,
    );
    final seconds = duration.inMilliseconds / 1000;
    for (var second = 0; second <= seconds.ceil(); second++) {
      final x = second * pixelsPerSecond;
      if (x > size.width) break;
      canvas.drawLine(
        Offset(x, size.height - 10),
        Offset(x, size.height),
        Paint()
          ..color = tick
          ..strokeWidth = 1,
      );
    }
    final playheadX = playhead.inMilliseconds / 1000 * pixelsPerSecond;
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()
        ..color = playheadColor
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_PokeMapCinematicTimelineRulerPainter oldDelegate) {
    return duration != oldDelegate.duration ||
        playhead != oldDelegate.playhead ||
        pixelsPerSecond != oldDelegate.pixelsPerSecond ||
        divider != oldDelegate.divider ||
        tick != oldDelegate.tick ||
        playheadColor != oldDelegate.playheadColor;
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

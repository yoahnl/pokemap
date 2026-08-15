import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
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

class PokeMapCinematicTimelineViewportRuler extends StatelessWidget {
  const PokeMapCinematicTimelineViewportRuler({
    super.key,
    required this.duration,
    required this.playhead,
    required this.pixelsPerSecond,
    required this.scrollOffset,
    required this.width,
    required this.semanticLabel,
    this.onSeekAtX,
    this.height = 32,
  }) : assert(pixelsPerSecond > 0),
       assert(scrollOffset >= 0),
       assert(width > 0),
       assert(height > 0);

  final Duration duration;
  final Duration playhead;
  final double pixelsPerSecond;
  final double scrollOffset;
  final double width;
  final String semanticLabel;
  final ValueChanged<double>? onSeekAtX;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final normalizedPlayhead = playhead < Duration.zero
        ? Duration.zero
        : playhead > duration
        ? duration
        : playhead;
    return Semantics(
      container: true,
      button: onSeekAtX != null,
      label:
          '$semanticLabel. ${_formatDuration(normalizedPlayhead)} sur ${_formatDuration(duration)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onSeekAtX == null
            ? null
            : (details) => onSeekAtX!(details.localPosition.dx),
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _PokeMapCinematicTimelineViewportRulerPainter(
              duration: duration,
              playhead: normalizedPlayhead,
              pixelsPerSecond: pixelsPerSecond,
              scrollOffset: scrollOffset,
              divider: colors.divider,
              tick: colors.textMuted,
              playheadColor: colors.brandPrimary,
            ),
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
    this.preview,
    this.selected = false,
    this.onPressed,
    this.startTrimLabel,
    this.endTrimLabel,
    this.onStartTrimBegin,
    this.onStartTrim,
    this.onStartTrimEnd,
    this.onStartTrimCancel,
    this.onEndTrimBegin,
    this.onEndTrim,
    this.onEndTrimEnd,
    this.onEndTrimCancel,
  }) : assert(pixelsPerSecond > 0);

  final String label;
  final Duration duration;
  final double pixelsPerSecond;
  final PokeMapTone tone;
  final PokeMapCinematicTimelineClipState state;
  final String? stateLabel;
  final Widget? preview;
  final bool selected;
  final VoidCallback? onPressed;
  final String? startTrimLabel;
  final String? endTrimLabel;
  final VoidCallback? onStartTrimBegin;
  final ValueChanged<double>? onStartTrim;
  final VoidCallback? onStartTrimEnd;
  final VoidCallback? onStartTrimCancel;
  final VoidCallback? onEndTrimBegin;
  final ValueChanged<double>? onEndTrim;
  final VoidCallback? onEndTrimEnd;
  final VoidCallback? onEndTrimCancel;

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
                if (preview != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: preview,
                      ),
                    ),
                  ),
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
                      onDragBegin: onStartTrimBegin,
                      onDrag: onStartTrim,
                      onDragEnd: onStartTrimEnd,
                      onDragCancel: onStartTrimCancel,
                    ),
                  ),
                if (selected && endTrimLabel != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _PokeMapCinematicTrimHandle(
                      semanticLabel: endTrimLabel!,
                      onDragBegin: onEndTrimBegin,
                      onDrag: onEndTrim,
                      onDragEnd: onEndTrimEnd,
                      onDragCancel: onEndTrimCancel,
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

class PokeMapCinematicAudioTimelinePreview extends StatelessWidget {
  const PokeMapCinematicAudioTimelinePreview({
    super.key,
    required this.amplitudes,
    required this.volume,
    required this.fadeInFraction,
    required this.fadeOutFraction,
    required this.loop,
  });

  final List<double> amplitudes;
  final double volume;
  final double fadeInFraction;
  final double fadeOutFraction;
  final bool loop;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _PokeMapCinematicWaveformPainter(
            amplitudes: amplitudes,
            color: colors.success.withValues(alpha: 0.42),
            fadeColor: colors.surfaceSubtle.withValues(alpha: 0.72),
            volume: volume,
            fadeInFraction: fadeInFraction,
            fadeOutFraction: fadeOutFraction,
          ),
        ),
        if (loop)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.repeat_rounded,
                size: 12,
                color: colors.success,
              ),
            ),
          ),
      ],
    );
  }
}

class PokeMapCinematicVideoTimelinePreview extends StatelessWidget {
  const PokeMapCinematicVideoTimelinePreview({
    super.key,
    required this.thumbnailBytes,
    required this.spacing,
    required this.fallbackUsed,
  });

  final Uint8List thumbnailBytes;
  final double spacing;
  final bool fallbackUsed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / spacing).ceil().clamp(1, 24);
        return Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                for (var index = 0; index < count; index += 1)
                  Expanded(
                    child: Image.memory(
                      thumbnailBytes,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                    ),
                  ),
              ],
            ),
            ColoredBox(color: colors.surfaceBase.withValues(alpha: 0.38)),
            if (fallbackUsed)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 12,
                    color: colors.warning,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PokeMapCinematicCaptionTimelinePreview extends StatelessWidget {
  const PokeMapCinematicCaptionTimelinePreview({
    super.key,
    required this.locale,
    required this.segments,
    required this.hasOverlap,
  });

  final String locale;
  final List<String> segments;
  final bool hasOverlap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              locale.toUpperCase(),
              style: TextStyle(color: colors.textSecondary, fontSize: 8),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              segments.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 8),
            ),
          ),
          if (hasOverlap)
            Icon(Icons.warning_amber_rounded, size: 11, color: colors.warning),
        ],
      ),
    );
  }
}

class PokeMapCinematicMarkerTimelinePreview extends StatelessWidget {
  const PokeMapCinematicMarkerTimelinePreview({
    super.key,
    required this.interactionCue,
    required this.required,
    required this.sceneUsageCount,
  });

  final bool interactionCue;
  final bool required;
  final int sceneUsageCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final linked = sceneUsageCount > 0;
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (interactionCue)
              Icon(
                linked ? Icons.link_rounded : Icons.link_off_rounded,
                size: 12,
                color: linked
                    ? colors.success
                    : required
                    ? colors.error
                    : colors.textMuted,
              ),
            const SizedBox(width: 3),
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: interactionCue ? colors.warning : colors.brandPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokeMapCinematicWaveformPainter extends CustomPainter {
  const _PokeMapCinematicWaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.fadeColor,
    required this.volume,
    required this.fadeInFraction,
    required this.fadeOutFraction,
  });

  final List<double> amplitudes;
  final Color color;
  final Color fadeColor;
  final double volume;
  final double fadeInFraction;
  final double fadeOutFraction;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty || size.isEmpty) return;
    final center = size.height / 2;
    final step = size.width / amplitudes.length;
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1, step * 0.55)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < amplitudes.length; index += 1) {
      final x = (index + 0.5) * step;
      final height =
          amplitudes[index].clamp(0, 1) * volume * size.height * 0.42;
      canvas.drawLine(
        Offset(x, center - height),
        Offset(x, center + height),
        paint,
      );
    }
    final fadePaint = Paint()..color = fadeColor;
    if (fadeInFraction > 0) {
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * fadeInFraction, 0)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, fadePaint);
    }
    if (fadeOutFraction > 0) {
      final start = size.width * (1 - fadeOutFraction);
      final path = Path()
        ..moveTo(start, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, fadePaint);
    }
  }

  @override
  bool shouldRepaint(_PokeMapCinematicWaveformPainter oldDelegate) =>
      !listEquals(amplitudes, oldDelegate.amplitudes) ||
      color != oldDelegate.color ||
      fadeColor != oldDelegate.fadeColor ||
      volume != oldDelegate.volume ||
      fadeInFraction != oldDelegate.fadeInFraction ||
      fadeOutFraction != oldDelegate.fadeOutFraction;
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
    required this.onDragBegin,
    required this.onDrag,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final String semanticLabel;
  final VoidCallback? onDragBegin;
  final ValueChanged<double>? onDrag;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragCancel;

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
          onHorizontalDragStart: onDrag == null
              ? null
              : (_) => onDragBegin?.call(),
          onHorizontalDragEnd: onDrag == null ? null : (_) => onDragEnd?.call(),
          onHorizontalDragCancel: onDrag == null ? null : onDragCancel,
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

class _PokeMapCinematicTimelineViewportRulerPainter extends CustomPainter {
  const _PokeMapCinematicTimelineViewportRulerPainter({
    required this.duration,
    required this.playhead,
    required this.pixelsPerSecond,
    required this.scrollOffset,
    required this.divider,
    required this.tick,
    required this.playheadColor,
  });

  final Duration duration;
  final Duration playhead;
  final double pixelsPerSecond;
  final double scrollOffset;
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
    final step = switch (pixelsPerSecond) {
      >= 160 => 0.5,
      >= 60 => 1.0,
      >= 30 => 2.0,
      _ => 5.0,
    };
    final visibleStartSeconds = scrollOffset / pixelsPerSecond;
    final visibleEndSeconds = (scrollOffset + size.width) / pixelsPerSecond;
    final durationSeconds = duration.inMicroseconds / 1000000;
    var second = (visibleStartSeconds / step).floor() * step;
    while (second <= visibleEndSeconds && second <= durationSeconds) {
      if (second >= 0) {
        final x = second * pixelsPerSecond - scrollOffset;
        canvas.drawLine(
          Offset(x, size.height - 10),
          Offset(x, size.height),
          Paint()
            ..color = tick
            ..strokeWidth = 1,
        );
        final label = TextPainter(
          text: TextSpan(
            text: _formatDuration(
              Duration(microseconds: (second * 1000000).round()),
            ),
            style: TextStyle(color: tick, fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        label.paint(canvas, Offset(x + 4, 3));
      }
      second += step;
    }
    final playheadX =
        playhead.inMicroseconds / 1000000 * pixelsPerSecond - scrollOffset;
    if (playheadX >= 0 && playheadX <= size.width) {
      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        Paint()
          ..color = playheadColor
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(
    _PokeMapCinematicTimelineViewportRulerPainter oldDelegate,
  ) {
    return duration != oldDelegate.duration ||
        playhead != oldDelegate.playhead ||
        pixelsPerSecond != oldDelegate.pixelsPerSecond ||
        scrollOffset != oldDelegate.scrollOffset ||
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

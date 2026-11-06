import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';

const _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 13);
const _iconSize = 22.0;
const _labelGap = 14.0;

class StudioNavigationEntry extends StatefulWidget {
  const StudioNavigationEntry({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.compact = false,
    this.unavailableReason,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected, compact;
  final String? unavailableReason;

  static double extentOf(
    BuildContext context, {
    required String label,
    required double width,
    bool compact = false,
  }) {
    if (compact) return _padding.vertical + _iconSize;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width - _padding.horizontal - _iconSize - _labelGap);
    final height = painter.height;
    painter.dispose();
    return _padding.vertical + math.max(_iconSize, height);
  }

  @override
  State<StudioNavigationEntry> createState() => _StudioNavigationEntryState();
}

class _StudioNavigationEntryState extends State<StudioNavigationEntry> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final reason = enabled ? null : widget.unavailableReason;
    final radius = BorderRadius.circular(StudioMetrics.controlRadius);
    final content = Padding(
      padding: _padding,
      child: Row(
        children: [
          Icon(widget.icon, size: _iconSize),
          if (!widget.compact) ...[
            const SizedBox(width: _labelGap),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return Tooltip(
      message: reason == null ? widget.label : '${widget.label} — $reason',
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        selected: widget.selected,
        enabled: enabled,
        label: widget.label,
        hint: reason,
        child: Material(
          color: widget.selected
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: _focused
                ? BorderSide(color: colors.onSurface, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            child: Stack(
              children: [
                content,
                if (widget.selected)
                  Positioned(
                    key: const ValueKey('studio-navigation-selected-marker'),
                    left: 0,
                    top: 9,
                    bottom: 9,
                    width: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.onPrimaryContainer,
                        borderRadius: BorderRadius.circular(2),
                      ),
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

import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';
import '../feedback/studio_badge.dart';

class StudioChoice extends StatefulWidget {
  const StudioChoice({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.leading,
    this.trailing,
    this.subtitle,
    this.tone,
    this.dense = false,
    this.selectionAccent = false,
    this.maxLines,
  });
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? leading;
  final Widget? trailing;
  final String? subtitle;
  final StudioTone? tone;
  final bool dense;
  final bool selectionAccent;
  final int? maxLines;
  @override
  State<StudioChoice> createState() => _StudioChoiceState();
}

class _StudioChoiceState extends State<StudioChoice> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = widget.tone?.color(context);
    final selectionAccent = widget.selected && widget.selectionAccent;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.dense ? 1 : 2),
      child: Semantics(
        selected: widget.selected,
        button: true,
        child: Material(
          color: selectionAccent
              ? colors.surfaceContainer
              : accent == null
              ? widget.selected
                    ? colors.primaryContainer
                    : colors.surface
              : Color.alphaBlend(
                  accent.withValues(alpha: widget.selected ? .2 : .07),
                  colors.surface,
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(
              color: _focused
                  ? colors.onSurface
                  : widget.selected && !selectionAccent
                  ? accent ?? colors.primary
                  : accent?.withValues(alpha: .3) ?? colors.outlineVariant,
              width: _focused ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InkWell(
                onTap: widget.onTap,
                onFocusChange: (value) => setState(() => _focused = value),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: widget.dense
                        ? StudioDensity.denseRow
                        : StudioDensity.row,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: widget.dense ? 4 : 7,
                    ),
                    child: Row(
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: 9),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                maxLines:
                                    widget.maxLines ?? (widget.dense ? 1 : 2),
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: widget.selected
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                              if (widget.subtitle != null && !widget.dense) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.dense && widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: theme.textTheme.bodySmall,
                          ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: 6),
                          widget.trailing!,
                        ],
                        if (widget.selected &&
                            !widget.dense &&
                            !selectionAccent) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check,
                            size: 14,
                            color: colors.onPrimaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (selectionAccent)
                PositionedDirectional(
                  key: const ValueKey('studio-choice-selection-accent'),
                  top: 0,
                  bottom: 0,
                  start: 0,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 2,
                      child: ColoredBox(color: accent ?? colors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

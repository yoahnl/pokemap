import 'package:flutter/material.dart';
import '../feedback/studio_badge.dart';

class StudioChoice extends StatefulWidget {
  const StudioChoice({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.leading,
    this.subtitle,
    this.tone,
    this.dense = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? leading;
  final String? subtitle;
  final StudioTone? tone;
  final bool dense;
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.dense ? 1 : 2),
      child: Semantics(
        selected: widget.selected,
        button: true,
        child: Material(
          color: accent == null
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
                  : widget.selected
                  ? accent ?? colors.primary
                  : accent?.withValues(alpha: .3) ?? colors.outlineVariant,
              width: _focused ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.dense ? 26 : 34),
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
                            maxLines: widget.dense ? 1 : 2,
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
                      Text(widget.subtitle!, style: theme.textTheme.bodySmall),
                    if (widget.selected && !widget.dense) ...[
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
        ),
      ),
    );
  }
}

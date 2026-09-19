import 'package:flutter/material.dart';

class StudioChoice extends StatefulWidget {
  const StudioChoice({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.leading,
    this.subtitle,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? leading;
  final String? subtitle;
  @override
  State<StudioChoice> createState() => _StudioChoiceState();
}

class _StudioChoiceState extends State<StudioChoice> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        selected: widget.selected,
        button: true,
        child: Material(
          color: widget.selected ? colors.primaryContainer : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(
              color: _focused
                  ? colors.onSurface
                  : widget.selected
                  ? colors.primary
                  : colors.outlineVariant,
              width: _focused ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: widget.selected
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
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
                    if (widget.selected) ...[
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

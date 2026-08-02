import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Compact, keyboard-accessible launcher used for dense tool families.
class PokeMapActionTile extends StatefulWidget {
  const PokeMapActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
    this.semanticLabel,
    this.disabledReason,
    this.height = 58,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isSelected;
  final String? semanticLabel;
  final String? disabledReason;
  final double height;

  @override
  State<PokeMapActionTile> createState() => _PokeMapActionTileState();
}

class _PokeMapActionTileState extends State<PokeMapActionTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final enabled = widget.onPressed != null;
    final foreground = !enabled
        ? colors.textDisabled
        : widget.isSelected
            ? colors.brandPrimary
            : colors.textSecondary;
    final background = !enabled
        ? colors.controlSurface.withValues(alpha: 0.55)
        : widget.isSelected
            ? colors.cardSelected
            : _hovered
                ? colors.cardHover
                : colors.controlSurface;
    final border = widget.isSelected
        ? colors.brandPrimaryBorder
        : _focused
            ? colors.focusRing
            : colors.borderSubtle;

    void activate() {
      if (!enabled) return;
      widget.onPressed?.call();
    }

    Widget tile = Semantics(
      button: true,
      enabled: enabled,
      selected: widget.isSelected,
      label: widget.semanticLabel ?? widget.label,
      hint: enabled ? null : widget.disabledReason,
      excludeSemantics: true,
      onTap: enabled ? activate : null,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) {
          if (_hovered != value) setState(() => _hovered = value);
        },
        onShowFocusHighlight: (value) {
          if (_focused != value) setState(() => _focused = value);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? activate : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            constraints: BoxConstraints(minHeight: widget.height),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: border,
                width: _focused ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 18, color: foreground),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    height: 1.05,
                    fontWeight:
                        widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final disabledReason = widget.disabledReason?.trim();
    if (!enabled && disabledReason != null && disabledReason.isNotEmpty) {
      tile = Tooltip(message: disabledReason, child: tile);
    }
    return tile;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

/// Token-driven selectable card for tiles, objects, and other editor assets.
///
/// A null [onPressed] makes the card inert for pointer and keyboard input.
/// [disabledReason] remains exposed through both tooltip and semantics so the
/// author understands how to make the asset available.
class PokeMapAssetCard extends StatefulWidget {
  const PokeMapAssetCard({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
    this.disabledReason,
    this.selected = false,
    this.focusNode,
    this.padding = const EdgeInsets.all(8),
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final Widget child;
  final String? disabledReason;
  final bool selected;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry padding;

  @override
  State<PokeMapAssetCard> createState() => _PokeMapAssetCardState();
}

class _PokeMapAssetCardState extends State<PokeMapAssetCard> {
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() {
    if (_enabled) widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final disabledReason = widget.disabledReason?.trim();
    final semanticLabel =
        !_enabled && disabledReason != null && disabledReason.isNotEmpty
            ? '${widget.semanticLabel}. Désactivé. $disabledReason'
            : widget.semanticLabel;
    final borderColor = widget.selected || _focused
        ? colors.brandPrimaryBorder
        : _hovered && _enabled
            ? colors.controlBorder
            : colors.borderSubtle;
    final backgroundColor = widget.selected
        ? colors.cardSelected
        : _hovered && _enabled
            ? colors.cardHover
            : colors.cardSurface;

    Widget card = FocusableActionDetector(
      focusNode: widget.focusNode,
      enabled: _enabled,
      mouseCursor:
          _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      onShowHoverHighlight: (value) {
        if (_hovered == value) return;
        setState(() => _hovered = value);
      },
      onShowFocusHighlight: (value) {
        if (_focused == value) return;
        setState(() => _focused = value);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? _activate : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.8 : 1,
            ),
            boxShadow: _focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: colors.focusRing.withValues(alpha: 0.22),
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ExcludeSemantics(
            child: Opacity(
              opacity: _enabled ? 1 : 0.56,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (!_enabled && disabledReason != null && disabledReason.isNotEmpty) {
      card = Tooltip(
        message: disabledReason,
        excludeFromSemantics: true,
        child: card,
      );
    }
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: semanticLabel,
      onTap: _enabled ? _activate : null,
      child: card,
    );
  }
}

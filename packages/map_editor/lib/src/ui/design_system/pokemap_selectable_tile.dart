import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

class PokeMapSelectableTile extends StatefulWidget {
  const PokeMapSelectableTile({
    super.key,
    required this.thumbnail,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.completed = false,
  });

  final Widget thumbnail;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool completed;

  @override
  State<PokeMapSelectableTile> createState() => _PokeMapSelectableTileState();
}

class _PokeMapSelectableTileState extends State<PokeMapSelectableTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final enabled = widget.onPressed != null;
    final selected = widget.selected || _focused;
    final background = selected
        ? colors.cardSelected
        : _hovered && enabled
        ? colors.cardHover
        : colors.cardSurface;
    final border = selected
        ? colors.brandPrimaryBorder
        : _hovered && enabled
        ? colors.controlBorder
        : colors.borderSubtle;

    void activate() {
      if (enabled) widget.onPressed?.call();
    }

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.label,
      onTap: enabled ? activate : null,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? activate : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: selected ? 1.8 : 1),
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
            child: Stack(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(child: Center(child: widget.thumbnail)),
                    const SizedBox(height: 5),
                    Text(
                      widget.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                if (widget.completed)
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      size: 14,
                      color: colors.success,
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

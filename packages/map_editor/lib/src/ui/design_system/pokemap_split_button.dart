import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';
import 'pokemap_context_menu.dart';

class PokeMapSplitButton<T> extends StatefulWidget {
  const PokeMapSplitButton({
    required this.onPressed,
    required this.items,
    required this.onSelected,
    required this.child,
    required this.tooltip,
    required this.menuTooltip,
    this.isSelected = false,
    this.focusNode,
    super.key,
  });

  final VoidCallback? onPressed;
  final List<PokeMapMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget child;
  final String tooltip;
  final String menuTooltip;
  final bool isSelected;
  final FocusNode? focusNode;

  @override
  State<PokeMapSplitButton<T>> createState() => _PokeMapSplitButtonState<T>();
}

class _PokeMapSplitButtonState<T> extends State<PokeMapSplitButton<T>> {
  final FocusNode _ownedPrimaryFocusNode =
      FocusNode(debugLabel: 'split button primary');
  final FocusNode _menuFocusNode = FocusNode(debugLabel: 'split button menu');
  final GlobalKey _menuSegmentKey = GlobalKey();

  OverlayEntry? _menuEntry;

  FocusNode get _primaryFocusNode => widget.focusNode ?? _ownedPrimaryFocusNode;

  bool get _menuEnabled => widget.items.any((item) => item.enabled);

  @override
  void didUpdateWidget(covariant PokeMapSplitButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_menuEntry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _menuEntry == null) return;
      if (!_menuEnabled) {
        _closeMenu(restorePrimaryFocus: true);
        return;
      }
      _menuEntry?.markNeedsBuild();
    });
  }

  @override
  void dispose() {
    final menuEntry = _menuEntry;
    menuEntry?.remove();
    menuEntry?.dispose();
    _menuEntry = null;
    _ownedPrimaryFocusNode.dispose();
    _menuFocusNode.dispose();
    super.dispose();
  }

  void _focusPrimary() {
    if (widget.onPressed != null) _primaryFocusNode.requestFocus();
  }

  void _focusMenu() {
    if (_menuEnabled) _menuFocusNode.requestFocus();
  }

  void _activatePrimary() {
    if (widget.onPressed == null) return;
    _primaryFocusNode.requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    widget.onPressed?.call();
  }

  void _openMenu() {
    if (!_menuEnabled || _menuEntry != null) return;
    _menuFocusNode.requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();

    final renderObject = _menuSegmentKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final globalAnchor = renderObject.localToGlobal(
      Offset(0, renderObject.size.height),
    );
    final overlay = Overlay.of(context);
    final overlayRenderObject = overlay.context.findRenderObject();
    if (overlayRenderObject is! RenderBox) return;
    final anchor = overlayRenderObject.globalToLocal(globalAnchor);
    final entry = OverlayEntry(
      builder: (context) => PokeMapContextMenu<T>(
        anchor: anchor,
        items: widget.items,
        invokerFocusNode: _menuFocusNode,
        onSelected: _handleMenuSelection,
        onDismiss: () => _closeMenu(),
      ),
    );
    _menuEntry = entry;
    overlay.insert(entry);
    setState(() {});
  }

  void _closeMenu({bool restorePrimaryFocus = false}) {
    final entry = _menuEntry;
    if (entry == null) return;
    _menuEntry = null;
    entry.remove();
    entry.dispose();
    if (restorePrimaryFocus && widget.onPressed != null) {
      _primaryFocusNode.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    if (mounted) setState(() {});
  }

  void _handleMenuSelection(T value) {
    final currentItems =
        widget.items.where((item) => item.value == value).toList();
    if (currentItems.length != 1 || !currentItems.single.enabled) return;
    widget.onSelected(currentItems.single.value);
  }

  @override
  Widget build(BuildContext context) {
    final primaryEnabled = widget.onPressed != null;
    _primaryFocusNode
      ..canRequestFocus = primaryEnabled
      ..skipTraversal = !primaryEnabled;
    _menuFocusNode
      ..canRequestFocus = _menuEnabled
      ..skipTraversal = !_menuEnabled;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowRight): _focusMenu,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _focusPrimary,
        const SingleActivator(LogicalKeyboardKey.arrowDown): _openMenu,
      },
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: _PokeMapSplitButtonSegment(
                focusNode: _primaryFocusNode,
                enabled: primaryEnabled,
                selected: widget.isSelected,
                tooltip: widget.tooltip,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                horizontalPadding: 12,
                onPressed: _activatePrimary,
                child: widget.child,
              ),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: _PokeMapSplitButtonSegment(
                key: _menuSegmentKey,
                focusNode: _menuFocusNode,
                enabled: _menuEnabled,
                selected: widget.isSelected || _menuEntry != null,
                tooltip: widget.menuTooltip,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(8),
                ),
                horizontalPadding: 8,
                onPressed: _openMenu,
                child: const Icon(Icons.arrow_drop_down_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokeMapSplitButtonSegment extends StatefulWidget {
  const _PokeMapSplitButtonSegment({
    required this.focusNode,
    required this.enabled,
    required this.selected,
    required this.tooltip,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.onPressed,
    required this.child,
    super.key,
  });

  final FocusNode focusNode;
  final bool enabled;
  final bool selected;
  final String tooltip;
  final BorderRadius borderRadius;
  final double horizontalPadding;
  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_PokeMapSplitButtonSegment> createState() =>
      _PokeMapSplitButtonSegmentState();
}

class _PokeMapSplitButtonSegmentState
    extends State<_PokeMapSplitButtonSegment> {
  bool _hovered = false;
  bool _focused = false;

  @override
  void didUpdateWidget(covariant _PokeMapSplitButtonSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _hovered = false;
      _focused = false;
    }
  }

  void _activate() {
    if (!widget.enabled) return;
    widget.focusNode.requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final background = !widget.enabled
        ? colors.controlSurface
        : widget.selected
            ? colors.cardSelected
            : _hovered
                ? colors.cardHover
                : colors.controlSurface;
    final foreground =
        widget.enabled ? colors.textPrimary : colors.textDisabled;

    return Tooltip(
      message: widget.tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        selected: widget.selected,
        label: widget.tooltip,
        onTap: widget.enabled ? _activate : null,
        child: ExcludeSemantics(
          child: FocusableActionDetector(
            focusNode: widget.focusNode,
            enabled: widget.enabled,
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
              if (mounted && _hovered != value) {
                setState(() => _hovered = value);
              }
            },
            onShowFocusHighlight: (value) {
              if (mounted && _focused != value) {
                setState(() => _focused = value);
              }
            },
            mouseCursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? _activate : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 36,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.horizontalPadding,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: widget.borderRadius,
                  border: Border.all(
                    color: widget.selected
                        ? colors.brandPrimaryBorder
                        : colors.controlBorder,
                  ),
                  boxShadow: _focused && widget.enabled
                      ? [
                          BoxShadow(
                            color: colors.focusRing.withValues(alpha: 0.28),
                            blurRadius: 0,
                            spreadRadius: 2.5,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: IconTheme.merge(
                    data: IconThemeData(color: foreground, size: 16),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

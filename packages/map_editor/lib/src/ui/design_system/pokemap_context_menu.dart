import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';
import 'pokemap_panel.dart';

@immutable
class PokeMapMenuItem<T> {
  const PokeMapMenuItem({
    required this.value,
    required this.label,
    this.shortcutLabel,
    this.enabled = true,
    this.disabledReason,
    this.destructive = false,
  });

  final T value;
  final String label;
  final String? shortcutLabel;
  final bool enabled;
  final String? disabledReason;
  final bool destructive;
}

/// Controlled context-menu overlay with no knowledge of editor commands.
///
/// [anchor] is expressed in the local coordinate space of the overlay or
/// `Stack` that directly hosts this widget.
class PokeMapContextMenu<T> extends StatefulWidget {
  const PokeMapContextMenu({
    required this.anchor,
    required this.items,
    required this.onSelected,
    required this.onDismiss,
    this.dividerAfter = const <int>{},
    this.invokerFocusNode,
    this.semanticLabel = 'Menu contextuel',
    this.width = 240,
    super.key,
  });

  final Offset anchor;
  final List<PokeMapMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  final Set<int> dividerAfter;
  final FocusNode? invokerFocusNode;
  final String semanticLabel;
  final double width;

  @override
  State<PokeMapContextMenu<T>> createState() => _PokeMapContextMenuState<T>();
}

class _PokeMapContextMenuState<T> extends State<PokeMapContextMenu<T>> {
  final FocusNode _menuFocusNode =
      FocusNode(debugLabel: 'context menu keyboard scope');
  late List<FocusNode> _itemFocusNodes;
  int? _focusedIndex;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _createFocusNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstEnabled());
  }

  @override
  void didUpdateWidget(covariant PokeMapContextMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      for (final node in _itemFocusNodes) {
        node.dispose();
      }
      _createFocusNodes();
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstEnabled());
      return;
    }
    final focusedIndex = _focusedIndex;
    final hasFocusedItem = _itemFocusNodes.any((node) => node.hasFocus);
    final hasEnabledItem = widget.items.any((item) => item.enabled);
    final focusedItemWasDisabled =
        focusedIndex != null && !widget.items[focusedIndex].enabled;
    if (hasEnabledItem &&
        (focusedIndex == null || !hasFocusedItem || focusedItemWasDisabled)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstEnabled());
    }
  }

  @override
  void dispose() {
    _menuFocusNode.dispose();
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _createFocusNodes() {
    _itemFocusNodes = List<FocusNode>.generate(
      widget.items.length,
      (index) => FocusNode(debugLabel: 'context menu item $index'),
    );
    _focusedIndex = null;
  }

  List<int> get _enabledIndices => <int>[
        for (var index = 0; index < widget.items.length; index += 1)
          if (widget.items[index].enabled) index,
      ];

  void _focusFirstEnabled() {
    if (!mounted) return;
    final enabledIndices = _enabledIndices;
    if (enabledIndices.isEmpty) {
      _menuFocusNode.requestFocus();
      return;
    }
    _focus(enabledIndices.first);
  }

  void _focus(int index) {
    if (!widget.items[index].enabled) return;
    setState(() => _focusedIndex = index);
    _itemFocusNodes[index].requestFocus();
  }

  void _moveFocus(int delta) {
    final enabledIndices = _enabledIndices;
    if (enabledIndices.isEmpty) return;
    final currentIndex = _itemFocusNodes.indexWhere((node) => node.hasFocus);
    final currentPosition = enabledIndices.indexOf(
      currentIndex >= 0 ? currentIndex : (_focusedIndex ?? -1),
    );
    final nextPosition = currentPosition < 0
        ? 0
        : (currentPosition + delta) % enabledIndices.length;
    _focus(enabledIndices[nextPosition]);
  }

  void _activateFocused() {
    final focusIndex = _itemFocusNodes.indexWhere((node) => node.hasFocus);
    final index = focusIndex >= 0 ? focusIndex : _focusedIndex;
    if (index != null && widget.items[index].enabled) _select(index);
  }

  void _select(int index) {
    final item = widget.items[index];
    if (!item.enabled) return;
    _dismiss(restoreFocusSynchronously: true);
    widget.onSelected(item.value);
  }

  void _dismiss({bool restoreFocusSynchronously = false}) {
    if (_isDismissing) return;
    _isDismissing = true;
    final invokerFocusNode = widget.invokerFocusNode;
    if (restoreFocusSynchronously &&
        invokerFocusNode?.context != null &&
        invokerFocusNode!.canRequestFocus) {
      invokerFocusNode.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    widget.onDismiss();
    if (restoreFocusSynchronously || invokerFocusNode == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (invokerFocusNode.context != null &&
          invokerFocusNode.canRequestFocus) {
        invokerFocusNode.requestFocus();
      }
    });
  }

  void _handleItemFocus(int index, bool focused) {
    if (focused && _focusedIndex != index && mounted) {
      setState(() => _focusedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    for (var index = 0; index < _itemFocusNodes.length; index += 1) {
      _itemFocusNodes[index]
        ..canRequestFocus = widget.items[index].enabled
        ..skipTraversal = !widget.items[index].enabled;
    }

    return Positioned.fill(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _moveFocus(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _moveFocus(-1),
          const SingleActivator(LogicalKeyboardKey.escape): _dismiss,
          const SingleActivator(LogicalKeyboardKey.enter): _activateFocused,
          const SingleActivator(LogicalKeyboardKey.space): _activateFocused,
        },
        child: Focus(
          focusNode: _menuFocusNode,
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('pokemap-context-menu-barrier'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  onSecondaryTap: _dismiss,
                  child: const SizedBox.expand(),
                ),
              ),
              CustomSingleChildLayout(
                delegate: _PokeMapContextMenuPositionDelegate(
                  anchor: widget.anchor,
                  width: widget.width,
                ),
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  label: widget.semanticLabel,
                  child: FocusTraversalGroup(
                    policy: ReadingOrderTraversalPolicy(),
                    child: PokeMapPanel(
                      borderRadius: 8,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var index = 0;
                              index < widget.items.length;
                              index += 1) ...[
                            _PokeMapContextMenuRow<T>(
                              item: widget.items[index],
                              focusNode: _itemFocusNodes[index],
                              focused: _focusedIndex == index,
                              onFocusChange: (focused) =>
                                  _handleItemFocus(index, focused),
                              onSelected: () => _select(index),
                            ),
                            if (widget.dividerAfter.contains(index))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: colors.divider,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
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

class _PokeMapContextMenuRow<T> extends StatefulWidget {
  const _PokeMapContextMenuRow({
    required this.item,
    required this.focusNode,
    required this.focused,
    required this.onFocusChange,
    required this.onSelected,
  });

  final PokeMapMenuItem<T> item;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onSelected;

  @override
  State<_PokeMapContextMenuRow<T>> createState() =>
      _PokeMapContextMenuRowState<T>();
}

class _PokeMapContextMenuRowState<T> extends State<_PokeMapContextMenuRow<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final item = widget.item;
    final highlighted = widget.focused || _hovered;
    final background = item.destructive
        ? (highlighted ? colors.errorSoft : colors.transparent)
        : (highlighted ? colors.cardSelected : colors.transparent);
    final foreground = !item.enabled
        ? colors.textDisabled
        : item.destructive
            ? colors.error
            : colors.textPrimary;
    final semanticLabel = !item.enabled &&
            item.disabledReason != null &&
            item.disabledReason!.isNotEmpty
        ? '${item.label}. Indisponible : ${item.disabledReason}'
        : item.label;

    Widget row = Semantics(
      button: true,
      enabled: item.enabled,
      label: semanticLabel,
      onTap: item.enabled ? widget.onSelected : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          enabled: item.enabled,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onSelected();
                return null;
              },
            ),
          },
          onFocusChange: widget.onFocusChange,
          onShowHoverHighlight: (value) {
            if (mounted && item.enabled) setState(() => _hovered = value);
          },
          mouseCursor: item.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: item.enabled ? widget.onSelected : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(6),
                border: widget.focused && item.enabled
                    ? Border.all(color: colors.focusRing, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: item.destructive
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.shortcutLabel != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      item.shortcutLabel!,
                      style: TextStyle(
                        color: item.enabled
                            ? colors.textMuted
                            : colors.textDisabled,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final disabledReason = item.disabledReason;
    if (!item.enabled && disabledReason != null && disabledReason.isNotEmpty) {
      row = Tooltip(
        message: disabledReason,
        excludeFromSemantics: true,
        child: row,
      );
    }
    return row;
  }
}

class _PokeMapContextMenuPositionDelegate extends SingleChildLayoutDelegate {
  const _PokeMapContextMenuPositionDelegate({
    required this.anchor,
    required this.width,
  });

  final Offset anchor;
  final double width;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    const edgeInsets = 16.0;
    final availableWidth =
        (constraints.maxWidth - edgeInsets).clamp(0, double.infinity);
    final availableHeight = (constraints.maxHeight - edgeInsets)
        .clamp(0, double.infinity)
        .toDouble();
    final resolvedWidth = width.clamp(0, availableWidth).toDouble();
    return BoxConstraints(
      minWidth: resolvedWidth,
      maxWidth: resolvedWidth,
      maxHeight: availableHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const edgePadding = 8.0;
    final maxX = (size.width - childSize.width - edgePadding)
        .clamp(edgePadding, double.infinity);
    final maxY = (size.height - childSize.height - edgePadding)
        .clamp(edgePadding, double.infinity);
    return Offset(
      anchor.dx.clamp(edgePadding, maxX),
      anchor.dy.clamp(edgePadding, maxY),
    );
  }

  @override
  bool shouldRelayout(
    covariant _PokeMapContextMenuPositionDelegate oldDelegate,
  ) {
    return oldDelegate.anchor != anchor || oldDelegate.width != width;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';
import 'pokemap_panel.dart';

const _menuRowHeight = 34.0;
const _menuVerticalPadding = 6.0;
const _menuDividerHeight = 1.0;
const _menuDividerVerticalPadding = 4.0;

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
  late List<PokeMapMenuItem<T>> _renderedItems;
  late List<FocusNode> _itemFocusNodes;
  int? _focusedIndex;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _renderedItems = List<PokeMapMenuItem<T>>.unmodifiable(widget.items);
    _createFocusNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstEnabled());
  }

  @override
  void didUpdateWidget(covariant PokeMapContextMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousItems = _renderedItems;
    final nextItems = List<PokeMapMenuItem<T>>.unmodifiable(widget.items);
    final previousFocusedIndex = _focusedIndex;
    int? reconciledIndex;
    if (previousFocusedIndex != null &&
        previousFocusedIndex < previousItems.length) {
      final focusedValue = previousItems[previousFocusedIndex].value;
      final oldMatches =
          previousItems.where((item) => item.value == focusedValue).length;
      final newMatches =
          nextItems.where((item) => item.value == focusedValue).length;
      if (oldMatches == 1 && newMatches == 1) {
        final candidateIndex =
            nextItems.indexWhere((item) => item.value == focusedValue);
        if (nextItems[candidateIndex].enabled) {
          reconciledIndex = candidateIndex;
        }
      }
    }

    final lengthChanged = previousItems.length != nextItems.length;
    if (lengthChanged) {
      for (final node in _itemFocusNodes) {
        node.dispose();
      }
    }
    _renderedItems = nextItems;
    if (lengthChanged) {
      _createFocusNodes();
    }
    _focusedIndex = reconciledIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetIndex = _focusedIndex;
      if (targetIndex == null ||
          targetIndex >= _renderedItems.length ||
          !_renderedItems[targetIndex].enabled) {
        _focusFirstEnabled();
      } else {
        _focus(targetIndex);
      }
    });
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
      _renderedItems.length,
      (index) => FocusNode(debugLabel: 'context menu item $index'),
    );
    _focusedIndex = null;
  }

  List<int> get _enabledIndices => <int>[
        for (var index = 0; index < _renderedItems.length; index += 1)
          if (_renderedItems[index].enabled) index,
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
    if (index < 0 ||
        index >= _renderedItems.length ||
        !_renderedItems[index].enabled) {
      return;
    }
    setState(() => _focusedIndex = index);
    _itemFocusNodes[index].requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          index >= _itemFocusNodes.length ||
          _focusedIndex != index) {
        return;
      }
      final itemContext = _itemFocusNodes[index].context;
      if (itemContext != null && itemContext.mounted) {
        Scrollable.ensureVisible(
          itemContext,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void _moveFocus(int delta) {
    final enabledIndices = _enabledIndices;
    if (enabledIndices.isEmpty) return;
    final currentPosition = enabledIndices.indexOf(_focusedIndex ?? -1);
    final nextPosition = currentPosition < 0
        ? 0
        : (currentPosition + delta) % enabledIndices.length;
    _focus(enabledIndices[nextPosition]);
  }

  void _activateFocused() {
    final index = _focusedIndex;
    if (index != null &&
        index < _renderedItems.length &&
        _renderedItems[index].enabled) {
      _select(index);
    }
  }

  void _select(int index) {
    if (index < 0 || index >= _renderedItems.length) return;
    final item = _renderedItems[index];
    if (!item.enabled) return;
    if (!_dismiss()) return;
    widget.onSelected(item.value);
  }

  bool _dismiss() {
    if (_isDismissing) return false;
    _isDismissing = true;
    final invokerFocusNode = widget.invokerFocusNode;
    if (invokerFocusNode?.context != null &&
        invokerFocusNode!.canRequestFocus) {
      invokerFocusNode.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    try {
      widget.onDismiss();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isDismissing = false;
      });
    }
    return true;
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
        ..canRequestFocus = _renderedItems[index].enabled
        ..skipTraversal = !_renderedItems[index].enabled;
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dividerCount = widget.dividerAfter
                        .where(
                          (index) =>
                              index >= 0 && index < _renderedItems.length,
                        )
                        .length;
                    final contentHeight = (_menuVerticalPadding * 2) +
                        (_renderedItems.length * _menuRowHeight) +
                        (dividerCount *
                            ((_menuDividerVerticalPadding * 2) +
                                _menuDividerHeight));
                    final menuHeight = contentHeight
                        .clamp(0, constraints.maxHeight)
                        .toDouble();
                    return SizedBox(
                      height: menuHeight,
                      child: Semantics(
                        container: true,
                        explicitChildNodes: true,
                        label: widget.semanticLabel,
                        child: FocusTraversalGroup(
                          policy: ReadingOrderTraversalPolicy(),
                          child: PokeMapPanel(
                            expandChild: true,
                            borderRadius: 8,
                            padding: const EdgeInsets.symmetric(
                              vertical: _menuVerticalPadding,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var index = 0;
                                      index < _renderedItems.length;
                                      index += 1) ...[
                                    _PokeMapContextMenuRow<T>(
                                      item: _renderedItems[index],
                                      focusNode: _itemFocusNodes[index],
                                      focused: _focusedIndex == index,
                                      onFocusChange: (focused) =>
                                          _handleItemFocus(index, focused),
                                      onSelected: () => _select(index),
                                    ),
                                    if (widget.dividerAfter.contains(index))
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: _menuDividerVerticalPadding,
                                        ),
                                        child: Divider(
                                          height: _menuDividerHeight,
                                          thickness: _menuDividerHeight,
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
                    );
                  },
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
      hint: item.shortcutLabel == null
          ? null
          : 'Raccourci : ${item.shortcutLabel}',
      onTap: item.enabled ? widget.onSelected : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          enabled: item.enabled,
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
              height: _menuRowHeight,
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

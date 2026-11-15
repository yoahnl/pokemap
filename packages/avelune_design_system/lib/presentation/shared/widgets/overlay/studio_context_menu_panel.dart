import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/studio_tokens.dart';
import 'studio_context_menu.dart';

class StudioContextMenuRoute extends PopupRoute<StudioContextMenuEntry> {
  StudioContextMenuRoute({
    required this.anchor,
    required this.items,
    required this.capturedThemes,
    required this.barrierLabel,
  });

  final Rect anchor;
  final List<StudioContextMenuItem> items;
  final CapturedThemes capturedThemes;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 90);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => capturedThemes.wrap(
    FadeTransition(
      opacity: animation,
      child: CustomSingleChildLayout(
        delegate: _StudioContextMenuLayout(
          anchor: anchor,
          padding: MediaQuery.paddingOf(context),
        ),
        child: StudioContextMenuPanel(items: items),
      ),
    ),
  );
}

class _StudioContextMenuLayout extends SingleChildLayoutDelegate {
  const _StudioContextMenuLayout({required this.anchor, required this.padding});

  final Rect anchor;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          constraints.maxWidth - StudioSpacing.m * 2,
          constraints.maxHeight - padding.vertical - StudioSpacing.m * 2,
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minX = StudioSpacing.m;
    final maxX = size.width - childSize.width - StudioSpacing.m;
    final minY = padding.top + StudioSpacing.m;
    final maxY =
        size.height - padding.bottom - childSize.height - StudioSpacing.m;
    var x = anchor.left;
    if (x > maxX) x = anchor.right - childSize.width;
    var y = anchor.bottom;
    if (y > maxY) y = anchor.top - childSize.height;
    return Offset(
      x.clamp(minX, maxX < minX ? minX : maxX),
      y.clamp(minY, maxY < minY ? minY : maxY),
    );
  }

  @override
  bool shouldRelayout(_StudioContextMenuLayout oldDelegate) =>
      anchor != oldDelegate.anchor || padding != oldDelegate.padding;
}

class StudioContextMenuPanel extends StatefulWidget {
  const StudioContextMenuPanel({super.key, required this.items});

  final List<StudioContextMenuItem> items;

  @override
  State<StudioContextMenuPanel> createState() => _StudioContextMenuPanelState();
}

class _StudioContextMenuPanelState extends State<StudioContextMenuPanel> {
  final _focus = FocusNode(debugLabel: 'StudioContextMenu');
  int? _highlighted;

  List<int> get _enabledIndexes => [
    for (var i = 0; i < widget.items.length; i++)
      if (widget.items[i] case StudioContextMenuEntry(enabled: true)) i,
  ];

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _select(StudioContextMenuEntry entry) {
    if (entry.enabled) Navigator.of(context).pop(entry);
  }

  void _move(int step) {
    final enabled = _enabledIndexes;
    if (enabled.isEmpty) return;
    final current = enabled.indexOf(_highlighted ?? -1);
    final next = current < 0
        ? (step > 0 ? 0 : enabled.length - 1)
        : (current + step) % enabled.length;
    setState(() => _highlighted = enabled[next]);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final index = _highlighted;
      if (index != null) _select(widget.items[index] as StudioContextMenuEntry);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Material(
        type: MaterialType.card,
        color: colors.surfaceContainerHigh,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    switch (widget.items[i]) {
                      StudioContextMenuSeparator() =>
                        const StudioContextMenuSeparatorLine(),
                      final StudioContextMenuEntry entry => _StudioMenuRow(
                        entry: entry,
                        highlighted: _highlighted == i,
                        onHover: () => setState(
                          () => _highlighted = entry.enabled ? i : null,
                        ),
                        onTap: () => _select(entry),
                      ),
                    },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudioContextMenuSeparatorLine extends StatelessWidget {
  const StudioContextMenuSeparatorLine({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
    child: Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

class _StudioMenuRow extends StatelessWidget {
  const _StudioMenuRow({
    required this.entry,
    required this.highlighted,
    required this.onHover,
    required this.onTap,
  });

  final StudioContextMenuEntry entry;
  final bool highlighted;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = !entry.enabled
        ? colors.onSurfaceVariant.withValues(alpha: .45)
        : entry.destructive
        ? colors.error
        : colors.onSurface;
    final row = MouseRegion(
      cursor: entry.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: entry.enabled ? onTap : null,
        child: Container(
          key: entry.key,
          height: StudioDensity.row - StudioSpacing.xs,
          margin: const EdgeInsets.symmetric(horizontal: StudioSpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.m),
          decoration: BoxDecoration(
            color: highlighted && entry.enabled
                ? (entry.destructive
                      ? colors.errorContainer
                      : colors.primaryContainer)
                : null,
            borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: entry.icon == null
                    ? null
                    : Icon(entry.icon, size: 16, color: foreground),
              ),
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: StudioTypeScale.label,
                    color: foreground,
                  ),
                ),
              ),
              if (entry.shortcut case final shortcut?)
                Padding(
                  padding: const EdgeInsets.only(left: StudioSpacing.xl),
                  child: Text(
                    shortcut,
                    style: TextStyle(
                      fontSize: StudioTypeScale.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final semantic = Semantics(
      button: true,
      enabled: entry.enabled,
      label: entry.label,
      excludeSemantics: true,
      child: row,
    );
    final reason = entry.disabledReason;
    return reason == null
        ? semantic
        : Tooltip(message: reason, child: semantic);
  }
}

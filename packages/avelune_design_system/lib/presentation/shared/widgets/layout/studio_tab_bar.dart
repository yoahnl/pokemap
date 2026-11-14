import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';

class StudioTab<T> {
  const StudioTab({required this.value, required this.label, this.key});

  final T value;
  final String label;
  final Key? key;
}

class StudioTabBar<T> extends StatelessWidget {
  const StudioTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.height = 48,
  });

  final List<StudioTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Ink(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: FocusTraversalGroup(
        child: Row(
          children: [
            for (final tab in tabs)
              _StudioTabEntry(
                key: tab.key,
                label: tab.label,
                selected: tab.value == selected,
                onTap: () => onSelected(tab.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudioTabEntry extends StatefulWidget {
  const _StudioTabEntry({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_StudioTabEntry> createState() => _StudioTabEntryState();
}

class _StudioTabEntryState extends State<_StudioTabEntry> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final underline = widget.selected
        ? BorderSide(color: scheme.primary, width: 2)
        : _focused
        ? BorderSide(color: scheme.onSurface, width: 2)
        : BorderSide.none;
    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (value) => setState(() => _focused = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border(bottom: underline)),
          child: ExcludeSemantics(
            child: Text(
              widget.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: widget.selected
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

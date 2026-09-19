import 'package:flutter/material.dart';
import 'studio_choice.dart';

class StudioTabs<T> extends StatelessWidget {
  const StudioTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });
  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      for (final item in items.entries)
        IntrinsicWidth(
          child: StudioChoice(
            label: item.value,
            selected: item.key == selected,
            onTap: () => onChanged(item.key),
          ),
        ),
    ],
  );
}

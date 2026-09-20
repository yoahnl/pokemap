import 'package:flutter/material.dart';

class StudioSelect extends StatelessWidget {
  const StudioSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('$label:$value:${options.keys.join(',')}'),
    initialValue: value != null && options.containsKey(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    hint: Text(
      value == null ? 'Choisir…' : 'Référence introuvable : $value',
      maxLines: 2,
    ),
    items: [
      for (final item in options.entries)
        DropdownMenuItem(
          value: item.key,
          child: Text(item.value, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged == null
        ? null
        : (value) {
            if (value != null) onChanged!(value);
          },
  );
}

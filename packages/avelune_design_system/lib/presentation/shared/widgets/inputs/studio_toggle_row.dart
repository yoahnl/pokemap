import 'package:flutter/material.dart';

class StudioToggleRow extends StatelessWidget {
  const StudioToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: description == null ? null : Text(description!),
    value: value,
    onChanged: onChanged,
  );
}

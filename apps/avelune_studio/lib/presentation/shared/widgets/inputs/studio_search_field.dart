import 'package:flutter/material.dart';

class StudioSearchField extends StatelessWidget {
  const StudioSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.label = 'Rechercher',
    this.hint,
    this.focusNode,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String label;
  final String? hint;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
      );
}

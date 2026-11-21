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
          decoration: _searchDecoration(
            label: label,
            hint: hint,
            suffix: value.text.isEmpty
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

class StudioInlineSearchField extends StatelessWidget {
  const StudioInlineSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
  });

  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    enabled: onChanged != null,
    decoration: _searchDecoration(hint: hint, dense: true),
  );
}

InputDecoration _searchDecoration({
  String? label,
  String? hint,
  Widget? suffix,
  bool? dense,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  prefixIcon: const Icon(Icons.search, size: 18),
  suffixIcon: suffix,
  isDense: dense,
);

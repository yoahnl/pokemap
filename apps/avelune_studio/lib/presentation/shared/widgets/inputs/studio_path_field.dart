import 'package:flutter/material.dart';

class StudioPathField extends StatelessWidget {
  const StudioPathField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.label = 'Dossier du projet',
    this.hint = 'Choisissez un dossier ou saisissez son chemin',
    this.onChanged,
    this.enabled = true,
    this.errorText,
  });
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    onChanged: onChanged,
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: TextInputAction.done,
    onSubmitted: (_) => onSubmitted(),
    decoration: InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      errorText: errorText,
      prefixIcon: const Icon(Icons.folder_outlined, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 32),
    ),
  );
}

import 'package:flutter/material.dart';

class StudioPathField extends StatelessWidget {
  const StudioPathField({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: TextInputAction.done,
    onSubmitted: (_) => onSubmitted(),
    decoration: const InputDecoration(
      labelText: 'Dossier du projet',
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: 'Choisissez un dossier ou saisissez son chemin',
      prefixIcon: Icon(Icons.folder_outlined, size: 16),
      prefixIconConstraints: BoxConstraints(minWidth: 34, minHeight: 32),
    ),
  );
}

import 'package:flutter/material.dart';

class StudioButton extends StatelessWidget {
  const StudioButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) => secondary
      ? OutlinedButton(onPressed: onPressed, child: Text(label))
      : FilledButton(onPressed: onPressed, child: Text(label));
}

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
      hintText: 'Choisissez un dossier ou saisissez son chemin',
    ),
  );
}

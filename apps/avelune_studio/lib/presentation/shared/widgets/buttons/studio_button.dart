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

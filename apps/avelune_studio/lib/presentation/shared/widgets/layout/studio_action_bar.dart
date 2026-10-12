import 'package:flutter/material.dart';

class StudioActionBar extends StatelessWidget {
  const StudioActionBar({super.key, required this.actions, this.message});

  final List<Widget> actions;
  final String? message;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          if (message != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(message!),
            ),
          ...actions,
        ],
      ),
    ),
  );
}

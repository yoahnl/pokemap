import 'package:flutter/material.dart';

class StudioSection extends StatelessWidget {
  const StudioSection({
    super.key,
    required this.title,
    required this.children,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });
  final String title;
  final List<Widget> children;
  final bool collapsible, initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (collapsible) {
      return ExpansionTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.all(12),
        children: children,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

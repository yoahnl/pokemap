import 'package:flutter/material.dart';

class StudioPageHeader extends StatelessWidget {
  const StudioPageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
  });
  final String title;
  final String? description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(description!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        );
        final buttons = Wrap(spacing: 8, runSpacing: 8, children: actions);
        if (constraints.maxWidth < 900 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              if (actions.isNotEmpty) ...[const SizedBox(height: 12), buttons],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            Flexible(child: buttons),
          ],
        );
      },
    ),
  );
}

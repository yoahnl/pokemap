import 'package:flutter/material.dart';
import '../../../theme/studio_tokens.dart';

class StudioPanel extends StatelessWidget {
  const StudioPanel({
    super.key,
    required this.children,
    this.title,
    this.actions = const [],
    this.compact = false,
  });
  final List<Widget> children;
  final String? title;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
    ),
    child: Padding(
      padding: EdgeInsets.all(compact ? 12 : StudioMetrics.panelPadding),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title!, style: Theme.of(context).textTheme.titleMedium),
                  ...actions,
                ],
              ),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    ),
  );
}

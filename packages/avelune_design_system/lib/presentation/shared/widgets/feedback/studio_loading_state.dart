import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';

class StudioLoadingState extends StatelessWidget {
  const StudioLoadingState({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Semantics(
        liveRegion: true,
        label: label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: StudioSpacing.l),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

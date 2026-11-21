import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';
import '../typography/studio_text.dart';
import 'studio_progress_indicator.dart';

class StudioLoadingState extends StatelessWidget {
  const StudioLoadingState({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
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
              const StudioProgressIndicator.compact(size: 24),
              const SizedBox(height: StudioSpacing.l),
              StudioCaption(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

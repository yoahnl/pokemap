import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class PokeMapHoverPreview extends StatelessWidget {
  const PokeMapHoverPreview({
    super.key,
    required this.label,
    required this.preview,
    required this.child,
  });

  final String label;
  final Widget preview;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Tooltip(
      waitDuration: const Duration(milliseconds: 250),
      exitDuration: const Duration(milliseconds: 100),
      preferBelow: false,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      richMessage: WidgetSpan(
        child: SizedBox(
          width: 160,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              preview,
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textPrimary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      child: Semantics(label: label, image: true, child: child),
    );
  }
}

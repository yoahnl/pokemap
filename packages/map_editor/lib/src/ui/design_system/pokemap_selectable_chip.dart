import 'package:flutter/cupertino.dart';

import '../shared/cupertino_editor_widgets.dart';

/// A pill-shaped chip that toggles between selected and unselected.
///
/// Extracted for BETA-BAT-034: the battle transition picker exists both in the
/// gameplay zone panel and in the Smart Tile encounter dialog, and both must
/// stay visually identical.
class PokeMapSelectableChip extends StatelessWidget {
  const PokeMapSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = EditorChrome.accentCoral;
    return GestureDetector(
      onTap: onToggle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.22)
              : EditorChrome.islandFill(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent
                : CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected
                  ? EditorChrome.primaryLabel(context)
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }
}

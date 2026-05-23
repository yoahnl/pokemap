import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A simple, elegant section header widget for PokeMap panels.
///
/// Typically used inside the inspector, side panels, or settings screens to segment
/// sections of controls. Displays a primary [title], an optional [description],
/// and an optional [trailing] widget (such as action buttons or status indicators).
class PokeMapSectionHeader extends StatelessWidget {
  const PokeMapSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
  });

  /// The primary section title text.
  final String title;

  /// Optional sub-label description text shown below the title.
  final String? description;

  /// Optional action widget displayed on the far right (e.g. icon buttons, checkboxes).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

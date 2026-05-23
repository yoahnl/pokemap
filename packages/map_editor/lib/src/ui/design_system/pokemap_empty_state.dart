import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A polished placeholder/empty-state prompt widget.
///
/// Designed to be shown when a panel, panel section, search list, or editor grid has
/// no content to display. Renders a centered stack containing an optional [icon],
/// a main [title], an optional sub [description], and an optional [action] button or widget.
class PokeMapEmptyState extends StatelessWidget {
  const PokeMapEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
  });

  /// Primary bold notification text explaining the empty state.
  final String title;

  /// Optional secondary text providing further explanation or instructions.
  final String? description;

  /// Optional top icon or graphic widget.
  final Widget? icon;

  /// Optional action widget shown below the text stack (e.g. "Create Event" button).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderSubtle, width: 1),
                ),
                alignment: Alignment.center,
                child: IconTheme.merge(
                  data: IconThemeData(color: colors.textMuted, size: 28),
                  child: icon!,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

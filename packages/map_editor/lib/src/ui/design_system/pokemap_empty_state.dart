import 'dart:math' as math;

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
    this.compact = false,
  });

  /// Primary bold notification text explaining the empty state.
  final String title;

  /// Optional secondary text providing further explanation or instructions.
  final String? description;

  /// Optional top icon or graphic widget.
  final Widget? icon;

  /// Optional action widget shown below the text stack (e.g. "Create Event" button).
  final Widget? action;

  /// Uses reduced spacing and icon sizing for constrained desktop panels.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final iconExtent = compact ? 40.0 : 64.0;
    final iconSize = compact ? 20.0 : 28.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = compact ||
                constraints.hasBoundedHeight && constraints.maxHeight < 300
            ? 12.0
            : 24.0;
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? math.max(0, constraints.maxHeight - padding * 2)
                : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: iconExtent,
                  height: iconExtent,
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderSubtle, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: colors.textMuted,
                      size: iconSize,
                    ),
                    child: icon!,
                  ),
                ),
                SizedBox(height: compact ? 8 : 16),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description != null) ...[
                SizedBox(height: compact ? 4 : 6),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
              if (action != null) ...[
                SizedBox(height: compact ? 8 : 16),
                action!,
              ],
            ],
          ),
        );
        if (!constraints.hasBoundedHeight) {
          return Padding(
            padding: EdgeInsets.all(padding),
            child: content,
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: content,
        );
      },
    );
  }
}

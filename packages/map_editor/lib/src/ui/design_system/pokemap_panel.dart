import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A structural panel layout container for large editor UI zones (e.g. sidebar contents, inspector).
///
/// Builds a clean surface using [backgroundShell], enclosed in a subtle border.
/// Supports standard [header] and [footer] widgets, inserting clean horizontal dividers automatically.
class PokeMapPanel extends StatelessWidget {
  const PokeMapPanel({
    super.key,
    this.header,
    required this.child,
    this.footer,
    this.padding,
    this.expandChild = false,
  });

  /// Optional widget displayed at the top of the panel (e.g., section title or actions toolbar).
  final Widget? header;

  /// Main content child widget.
  final Widget child;

  /// Optional widget displayed at the bottom of the panel (e.g., status flags or confirmation buttons).
  final Widget? footer;

  /// Inner padding around the [child] widget. Defaults to 16.
  final EdgeInsetsGeometry? padding;

  /// If true, wraps the child in an [Expanded] container. Defaults to false.
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    final childWidget = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12), // Standard radius: 12
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(11), // Inset clip to prevent background spill
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (header != null) ...[
              header!,
              Container(
                height: 1,
                color: colors.divider,
              ),
            ],
            if (expandChild) Expanded(child: childWidget) else childWidget,
            if (footer != null) ...[
              Container(
                height: 1,
                color: colors.divider,
              ),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'pokemap_tone.dart';

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
    this.borderRadius = 12,
    this.accentTone,
    this.accentWidth = 3,
  }) : assert(accentWidth > 0);

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

  /// Surface radius. Dense desktop workspaces may use 8 while the default
  /// remains unchanged for existing screens.
  final double borderRadius;

  /// Optional semantic accent rendered as a slim leading-edge rail.
  ///
  /// This is intended for dense repeated panels where users need to identify
  /// a category at a glance. The content must still expose that category as
  /// text because color is supplementary information.
  final PokeMapTone? accentTone;

  /// Width of the optional leading accent rail.
  final double accentWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final accentColor = accentTone?.resolve(context).icon;

    final childWidget = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          (borderRadius - 1).clamp(0, double.infinity).toDouble(),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Column(
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
            if (accentColor != null)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: accentWidth,
                child: ColoredBox(
                  key: const ValueKey<String>('pokemap-panel-accent-rail'),
                  color: accentColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

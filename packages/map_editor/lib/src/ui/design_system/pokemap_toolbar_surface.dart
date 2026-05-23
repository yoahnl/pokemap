import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A structural horizontal bar surface for editor toolbars and topbars.
///
/// Provides a consistent background using the design system's [surfaceBase] color
/// and places a subtle border/divider at the bottom. Sets up a standard padding container
/// for horizontal controls.
class PokeMapToolbarSurface extends StatelessWidget {
  const PokeMapToolbarSurface({
    super.key,
    required this.child,
    this.padding,
  });

  /// Main toolbar row contents or actions layout.
  final Widget child;

  /// Custom padding within the toolbar bar. Defaults to 8px vertical, 16px horizontal.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border(
          bottom: BorderSide(
            color: colors.divider,
            width: 1.0,
          ),
        ),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}

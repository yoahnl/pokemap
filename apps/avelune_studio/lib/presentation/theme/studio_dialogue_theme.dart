import 'package:flutter/material.dart';
import 'studio_tokens.dart';

class StudioDialogueTheme extends StatelessWidget {
  const StudioDialogueTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    if (base.brightness != Brightness.dark) return child;
    final colors = base.colorScheme.copyWith(
      primary: const Color(0xff1262ff),
      primaryContainer: const Color(0xff073971),
      surface: const Color(0xff031c30),
      surfaceContainerLowest: const Color(0xff001626),
      surfaceContainer: const Color(0xff062b49),
      surfaceContainerHigh: const Color(0xff10385d),
      outline: const Color(0xff205482),
      outlineVariant: const Color(0xff123c5d),
      onSurfaceVariant: const Color(0xffb9d4ed),
    );
    final accents = StudioColors.of(context).copyWith(
      canvasSelection: const Color(0xff00c8ff),
      featureAccent: const Color(0xff7952ff),
      success: const Color(0xff00ddb0),
    );
    return Theme(
      data: base.copyWith(
        colorScheme: colors,
        extensions: [
          ...base.extensions.values.where((value) => value is! StudioColors),
          accents,
        ],
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          fillColor: colors.surfaceContainer,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: base.filledButtonTheme.style?.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? colors.surfaceContainerHigh
                  : colors.primary,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: base.outlinedButtonTheme.style?.copyWith(
            backgroundColor: WidgetStatePropertyAll(colors.surfaceContainer),
          ),
        ),
      ),
      child: child,
    );
  }
}

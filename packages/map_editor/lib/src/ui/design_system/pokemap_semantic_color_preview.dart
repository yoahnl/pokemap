import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Design-system boundary for previewing project-authored semantic colors.
///
/// Feature screens pass validated hexadecimal tokens and never construct
/// project [Color] values themselves.
class PokeMapSemanticColorPreview extends StatelessWidget {
  const PokeMapSemanticColorPreview({
    super.key,
    required this.label,
    required this.backgroundHex,
    required this.foregroundHex,
    this.sample = 'Aa 123',
  });

  final String label;
  final String backgroundHex;
  final String foregroundHex;
  final String sample;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final background = _opaqueColor(backgroundHex) ?? colors.errorSoft;
    final foreground = _opaqueColor(foregroundHex) ?? colors.error;
    return Semantics(
      container: true,
      label: '$label, fond $backgroundHex, texte $foregroundHex',
      child: Container(
        constraints: const BoxConstraints(minHeight: 92, minWidth: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              sample,
              style: TextStyle(
                color: foreground,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color? _opaqueColor(String source) {
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(source)) return null;
  return Color(int.parse('FF${source.substring(1)}', radix: 16));
}

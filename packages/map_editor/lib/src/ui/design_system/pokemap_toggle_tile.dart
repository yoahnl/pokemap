import 'package:flutter/cupertino.dart';

import '../../theme/theme.dart';
import 'pokemap_card.dart';

/// Token-backed boolean setting with a descriptive label and native switch.
class PokeMapToggleTile extends StatelessWidget {
  const PokeMapToggleTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      toggled: value,
      label: label,
      child: PokeMapCard(
        selected: value,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description case final description?) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            CupertinoSwitch(
              value: value,
              activeTrackColor: colors.brandPrimary,
              inactiveTrackColor: colors.controlSurface,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

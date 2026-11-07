import 'package:flutter/material.dart';

import 'studio_badge.dart';

class StudioStateBadge extends StatelessWidget {
  const StudioStateBadge.inherited(String source, {super.key})
    : label = 'Hérité $source',
      icon = Icons.south_east,
      tone = StudioTone.neutral;

  const StudioStateBadge.local({super.key})
    : label = 'Valeur locale',
      icon = Icons.edit_location_alt_outlined,
      tone = StudioTone.feature;

  const StudioStateBadge.draft({super.key})
    : label = 'Non enregistré',
      icon = Icons.edit_note,
      tone = StudioTone.warning;

  const StudioStateBadge.mixed({super.key})
    : label = 'Valeurs différentes',
      icon = Icons.call_split,
      tone = StudioTone.info;

  final String label;
  final IconData icon;
  final StudioTone tone;

  @override
  Widget build(BuildContext context) =>
      StudioBadge(label, tone: tone, icon: icon);
}

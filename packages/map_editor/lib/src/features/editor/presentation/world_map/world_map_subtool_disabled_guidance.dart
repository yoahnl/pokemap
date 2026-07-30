import 'package:flutter/material.dart';

import '../../../../ui/design_system/design_system.dart';

class WorldMapSubtoolDisabledGuidance extends StatelessWidget {
  const WorldMapSubtoolDisabledGuidance({
    super.key,
    required this.title,
    required this.reason,
    this.icon = const Icon(Icons.info_outline_rounded),
  });

  final String title;
  final String reason;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: const ValueKey<String>(
        'world-map-inspector-disabled-guidance',
      ),
      canRequestFocus: true,
      child: Semantics(
        container: true,
        focusable: true,
        label: '$title. $reason',
        child: PokeMapEmptyState(
          icon: icon,
          title: title,
          description: reason,
        ),
      ),
    );
  }
}

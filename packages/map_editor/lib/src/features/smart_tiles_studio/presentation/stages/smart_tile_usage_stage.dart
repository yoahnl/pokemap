import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';

class SmartTileUsageStage extends StatelessWidget {
  const SmartTileUsageStage({
    super.key,
    required this.selectedUsage,
    required this.onSelected,
    required this.onContinue,
  });

  final SmartTileUsage? selectedUsage;
  final ValueChanged<SmartTileUsage> onSelected;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Que voulez-vous peindre ?',
          description:
              'Choisissez une intention. Les raccords restent modifiables plus tard.',
        ),
        const SizedBox(height: 12),
        for (final usage in SmartTileUsage.values) ...[
          PokeMapAssetCard(
            key: Key('smart-tiles-usage-${usage.name}'),
            thumbnail: Icon(_icon(usage), size: 22),
            label: _label(usage),
            description: '${_description(usage)} ${_recommendation(usage)}',
            selected: selectedUsage == usage,
            onPressed: () => onSelected(usage),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-usage-next-step'),
            onPressed: onContinue,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Choisir une image'),
          ),
        ),
      ],
    );
  }
}

String _label(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => 'Terrain',
      SmartTileUsage.path => 'Chemin',
      SmartTileUsage.forestSurface => 'Surface organique',
    };

String _description(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain =>
        'Une matière de fond qui peut couvrir toute la carte.',
      SmartTileUsage.path =>
        'Un réseau peint au-dessus du terrain avec raccords automatiques.',
      SmartTileUsage.forestSurface =>
        'Une surface riche, éventuellement composée de plusieurs couches.',
    };

String _recommendation(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => 'Recommandé : Bordures.',
      SmartTileUsage.path => 'Recommandé : Formes organiques.',
      SmartTileUsage.forestSurface =>
        'Recommandé : Formes organiques et visuels multicouches.',
    };

IconData _icon(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => CupertinoIcons.map,
      SmartTileUsage.path => CupertinoIcons.arrow_branch,
      SmartTileUsage.forestSurface => CupertinoIcons.tree,
    };

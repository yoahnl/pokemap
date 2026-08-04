import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_connection_profile.dart';

class SmartTileConnectionsStage extends StatelessWidget {
  const SmartTileConnectionsStage({
    super.key,
    required this.usage,
    required this.coveragePolicy,
    required this.selectedProfileId,
    required this.customTopology,
    required this.onProfileSelected,
    required this.onCustomTopologySelected,
    required this.onCoveragePolicySelected,
    required this.onContinue,
    this.guidePicker,
  });

  final SmartTileUsage usage;
  final SmartTileCoveragePolicy coveragePolicy;
  final SmartTileConnectionProfileId? selectedProfileId;
  final SmartTileTopology? customTopology;
  final ValueChanged<SmartTileConnectionProfile> onProfileSelected;
  final ValueChanged<SmartTileTopology> onCustomTopologySelected;
  final ValueChanged<SmartTileCoveragePolicy> onCoveragePolicySelected;
  final VoidCallback? onContinue;
  final Widget? guidePicker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Comment le calque démarre-t-il ?',
          description:
              'Le raccord visuel et le remplissage sont deux choix indépendants.',
        ),
        const SizedBox(height: 12),
        PokeMapAssetCard(
          key: const Key('smart-tiles-coverage-complete'),
          thumbnail: const Icon(CupertinoIcons.square_fill, size: 21),
          label: 'Fond de carte rempli',
          description:
              'La matière par défaut couvre toute la carte dès la création.',
          selected: coveragePolicy == SmartTileCoveragePolicy.complete,
          onPressed: () => onCoveragePolicySelected(
            SmartTileCoveragePolicy.complete,
          ),
        ),
        const SizedBox(height: 8),
        PokeMapAssetCard(
          key: const Key('smart-tiles-coverage-sparse'),
          thumbnail: const Icon(CupertinoIcons.paintbrush, size: 21),
          label: 'Calque vide à peindre',
          description:
              'La matière apparaît uniquement aux endroits peints sur la carte.',
          selected: coveragePolicy == SmartTileCoveragePolicy.sparse,
          onPressed: () => onCoveragePolicySelected(
            SmartTileCoveragePolicy.sparse,
          ),
        ),
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Comment les cellules se raccordent-elles ?',
          description:
              'Choisissez une famille visuelle. Vous pourrez revenir sur ce choix avant publication.',
        ),
        const SizedBox(height: 12),
        for (final profile in smartTileConnectionProfiles) ...[
          PokeMapAssetCard(
            key: Key('smart-tiles-connection-${profile.id.name}'),
            thumbnail: Icon(_profileIcon(profile.id), size: 21),
            label: profile.label,
            description: '${profile.description} ${profile.latticeLabel}.',
            selected: selectedProfileId == profile.id,
            onPressed: () => onProfileSelected(profile),
            trailing: profile.isRecommendedFor(usage)
                ? const PokeMapBadge(
                    label: 'Recommandé',
                    variant: PokeMapBadgeVariant.info,
                  )
                : null,
          ),
          const SizedBox(height: 8),
        ],
        if (selectedProfileId == SmartTileConnectionProfileId.custom) ...[
          const SizedBox(height: 6),
          const PokeMapSectionHeader(
            title: 'Structure sur mesure',
            description: 'Choisissez explicitement ce que décrit l’atlas.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final topology in SmartTileTopology.values)
                PokeMapButton(
                  key: Key('smart-tiles-custom-topology-${topology.name}'),
                  onPressed: () => onCustomTopologySelected(topology),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.ghost,
                  isSelected: customTopology == topology,
                  child: Text(_topologyLabel(topology)),
                ),
            ],
          ),
        ],
        if (guidePicker != null) ...[
          const SizedBox(height: 18),
          guidePicker!,
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-connections-next-step'),
            onPressed: onContinue,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Préparer les variantes'),
          ),
        ),
      ],
    );
  }
}

IconData _profileIcon(SmartTileConnectionProfileId id) => switch (id) {
      SmartTileConnectionProfileId.none => CupertinoIcons.square,
      SmartTileConnectionProfileId.borders => CupertinoIcons.rectangle,
      SmartTileConnectionProfileId.corners => CupertinoIcons.crop,
      SmartTileConnectionProfileId.organic => CupertinoIcons.circle_grid_3x3,
      SmartTileConnectionProfileId.bordersAndCorners =>
        CupertinoIcons.square_grid_3x2,
      SmartTileConnectionProfileId.custom => CupertinoIcons.slider_horizontal_3,
    };

String _topologyLabel(SmartTileTopology topology) => switch (topology) {
      SmartTileTopology.uniform => 'Cellule simple',
      SmartTileTopology.cardinal4 => 'Voisinage cardinal',
      SmartTileTopology.blob8 => 'Contour organique',
      SmartTileTopology.wangEdge4 => 'Arêtes indépendantes',
      SmartTileTopology.wangCorner4 => 'Coins indépendants',
      SmartTileTopology.wang8 => 'Arêtes et coins',
    };

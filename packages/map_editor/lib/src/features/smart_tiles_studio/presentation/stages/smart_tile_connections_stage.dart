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
    required this.showAdvancedSettings,
    required this.onToggleAdvancedSettings,
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
  final bool showAdvancedSettings;
  final VoidCallback onToggleAdvancedSettings;
  final Widget? guidePicker;

  @override
  Widget build(BuildContext context) {
    final recommended = recommendedSmartTileConnectionProfile(usage);
    final visibleProfiles =
        usage == SmartTileUsage.path && !showAdvancedSettings
        ? <SmartTileConnectionProfile>[
            smartTileConnectionProfiles.firstWhere(
              (profile) => profile.id == (selectedProfileId ?? recommended.id),
              orElse: () => recommended,
            ),
          ]
        : smartTileConnectionProfiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[ PokeMapSectionHeader(
          title: usage == SmartTileUsage.path
              ? 'Où le chemin doit-il apparaître ?'
              : 'Comment la peinture apparaît-elle sur la carte ?',
          description: usage == SmartTileUsage.path
              ? 'Le choix conseillé laisse la carte vide : le chemin apparaît uniquement sous votre pinceau.'
              : 'Choisissez entre une carte déjà remplie et une surface à peindre.',
        ),
        const SizedBox(height: 12),
        PokeMapAssetCard(
          key: const Key('smart-tiles-coverage-complete'),
          thumbnail: const Icon(CupertinoIcons.square_fill, size: 21),
          label: usage == SmartTileUsage.path
              ? 'Remplir toute la carte avec le chemin'
              : 'Fond de carte rempli',
          description: usage == SmartTileUsage.path
              ? 'Rarement utile : chaque case commence comme une partie du chemin.'
              : 'La peinture par défaut couvre toute la carte dès la création.',
          selected: coveragePolicy == SmartTileCoveragePolicy.complete,
          onPressed: () => onCoveragePolicySelected(
            SmartTileCoveragePolicy.complete
          ),
        ),
        const SizedBox(height: 8),
        PokeMapAssetCard(
          key: const Key('smart-tiles-coverage-sparse'),
          thumbnail: const Icon(CupertinoIcons.paintbrush, size: 21),
          label: usage == SmartTileUsage.path
              ? 'Dessiner seulement là où je peins'
              : 'Calque vide à peindre',
          description: usage == SmartTileUsage.path
              ? 'Conseillé : le chemin suit exactement votre coup de pinceau.'
              : 'La peinture apparaît uniquement aux endroits peints sur la carte.',
          selected: coveragePolicy == SmartTileCoveragePolicy.sparse,
          onPressed: () => onCoveragePolicySelected(
            SmartTileCoveragePolicy.sparse
          ),
        ),
        const SizedBox(height: 18), PokeMapSectionHeader(
          title: usage == SmartTileUsage.path
              ? 'Comment le chemin prend-il les virages ?'
              : 'Comment les tuiles se rejoignent-elles ?',
          description: usage == SmartTileUsage.path
              ? 'Gardez le choix marqué « Recommandé » pour un chemin naturel. Changez-le seulement si votre atlas suit une autre organisation.'
              : 'Le choix recommandé convient à la plupart des images. Vous pourrez encore le modifier avant l’enregistrement.',
        ),
        const SizedBox(height: 12),
        for (final profile in visibleProfiles) ...[
          PokeMapAssetCard(
            key: Key('smart-tiles-connection-${profile.id.name}'),
            thumbnail: Icon(_profileIcon(profile.id), size: 21),
            label: _profileLabel( profile, usage),
            description: _profileDescription(profile, usage),
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
        if (usage == SmartTileUsage.path) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const Key('smart-tiles-toggle-connections-advanced'),
              onPressed: onToggleAdvancedSettings,
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: Icon(
                showAdvancedSettings
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.slider_horizontal_3,
                size: 14,
              ),
              child: Text(
                showAdvancedSettings
                    ? 'Masquer les autres organisations'
                    : 'Mon image suit une autre organisation',
              ),
            ),
          ),
        ],
        if (guidePicker != null) ...[
          const SizedBox(height: 18),
          guidePicker!
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-connections-next-step'),
            onPressed: onContinue,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: Text(
              usage == SmartTileUsage.path
                  ? 'Continuer avec ce tracé'
                  : 'Continuer vers les options',),
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

String _profileLabel(SmartTileConnectionProfile profile, SmartTileUsage usage) {
  if (usage != SmartTileUsage.path) return profile.label;
  return switch (profile.id) {
    SmartTileConnectionProfileId.none => 'Même image partout',
    SmartTileConnectionProfileId.borders => 'Chemin rectiligne par les bords',
    SmartTileConnectionProfileId.corners =>
      'Transitions dessinées par les coins',
    SmartTileConnectionProfileId.organic => 'Chemin naturel avec virages',
    SmartTileConnectionProfileId.bordersAndCorners =>
      'Atlas complet avec bords et coins',
    SmartTileConnectionProfileId.custom => 'Organisation particulière',
  };
}

String _profileDescription(
  SmartTileConnectionProfile profile,
  SmartTileUsage usage,
) {
  if (usage != SmartTileUsage.path) {
    return '${profile.description} ${profile.latticeLabel}.';
  }
  return switch (profile.id) {
    SmartTileConnectionProfileId.none =>
      'Aucun virage automatique : la même tuile est répétée.',
    SmartTileConnectionProfileId.borders =>
      'Chaque côté se raccorde séparément pour des routes très régulières.',
    SmartTileConnectionProfileId.corners =>
      'Les quatre coins de chaque tuile déterminent la transition.',
    SmartTileConnectionProfileId.organic =>
      'Les tuiles droites, les virages et les intersections suivent naturellement le pinceau.',
    SmartTileConnectionProfileId.bordersAndCorners =>
      'Utilisez ce choix uniquement si votre atlas fournit séparément tous les bords et tous les coins.',
    SmartTileConnectionProfileId.custom =>
      'Choisissez vous-même la structure technique de l’atlas.',
  };
}

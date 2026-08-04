import 'package:map_core/map_core.dart';

enum SmartTileConnectionProfileId {
  none,
  borders,
  corners,
  organic,
  bordersAndCorners,
  custom,
}

final class SmartTileConnectionConfiguration {
  const SmartTileConnectionConfiguration({
    required this.topology,
    required this.templateHint,
    this.boundaryPolicy = SmartTileBoundaryPolicy.empty,
    this.coveragePolicy,
  });

  final SmartTileTopology topology;
  final SmartTileTemplateHint templateHint;
  final SmartTileBoundaryPolicy boundaryPolicy;

  /// Optional author override. Connection geometry does not normally decide
  /// whether a layer is a filled base or an empty overlay.
  final SmartTileCoveragePolicy? coveragePolicy;
}

/// Human-facing projection of the canonical Smart Tile topology contracts.
///
/// Profiles contain no persistence model of their own. Selecting one only
/// chooses values already owned by map_core.
final class SmartTileConnectionProfile {
  const SmartTileConnectionProfile({
    required this.id,
    required this.label,
    required this.description,
    required this.latticeLabel,
    required this.configuration,
    this.recommendedUsages = const <SmartTileUsage>{},
  });

  final SmartTileConnectionProfileId id;
  final String label;
  final String description;
  final String latticeLabel;
  final SmartTileConnectionConfiguration? configuration;
  final Set<SmartTileUsage> recommendedUsages;

  bool isRecommendedFor(SmartTileUsage usage) =>
      recommendedUsages.contains(usage);

  SmartTileConnectionConfiguration resolve({
    SmartTileTopology? customTopology,
  }) {
    final fixed = configuration;
    if (fixed != null) return fixed;
    if (customTopology == null) {
      throw ArgumentError(
        'A custom Smart Tile connection profile requires a topology.',
      );
    }
    return SmartTileConnectionConfiguration(
      topology: customTopology,
      templateHint: SmartTileTemplateHint.free,
    );
  }
}

const List<SmartTileConnectionProfile> smartTileConnectionProfiles =
    <SmartTileConnectionProfile>[
  SmartTileConnectionProfile(
    id: SmartTileConnectionProfileId.none,
    label: 'Sans raccords',
    description: 'Une image répétée telle quelle, sans voisinage à résoudre.',
    latticeLabel: 'Cellules',
    configuration: SmartTileConnectionConfiguration(
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
    ),
  ),
  SmartTileConnectionProfile(
    id: SmartTileConnectionProfileId.borders,
    label: 'Bordures',
    description: 'Les quatre bords se raccordent indépendamment.',
    latticeLabel: 'Arêtes',
    configuration: SmartTileConnectionConfiguration(
      topology: SmartTileTopology.wangEdge4,
      templateHint: SmartTileTemplateHint.edge16,
    ),
    recommendedUsages: <SmartTileUsage>{SmartTileUsage.terrain},
  ),
  SmartTileConnectionProfile(
    id: SmartTileConnectionProfileId.corners,
    label: 'Coins',
    description: 'Les quatre coins décrivent les transitions de la matière.',
    latticeLabel: 'Coins',
    configuration: SmartTileConnectionConfiguration(
      topology: SmartTileTopology.wangCorner4,
      templateHint: SmartTileTemplateHint.corner16,
    ),
  ),
  SmartTileConnectionProfile(
    id: SmartTileConnectionProfileId.organic,
    label: 'Formes organiques',
    description: 'Huit voisins produisent des contours naturels et souples.',
    latticeLabel: 'Cellules à 8 voisins',
    configuration: SmartTileConnectionConfiguration(
      topology: SmartTileTopology.blob8,
      templateHint: SmartTileTemplateHint.blob47,
    ),
    recommendedUsages: <SmartTileUsage>{
      SmartTileUsage.path,
      SmartTileUsage.forestSurface,
    },
  ),
  SmartTileConnectionProfile(
    id: SmartTileConnectionProfileId.bordersAndCorners,
    label: 'Bordures + coins',
    description: 'Bords et coins sont résolus ensemble pour un atlas riche.',
    latticeLabel: 'Arêtes et coins',
    configuration: SmartTileConnectionConfiguration(
      topology: SmartTileTopology.wang8,
      templateHint: SmartTileTemplateHint.mixed256,
    ),
  ),
  SmartTileConnectionProfile(
    id: SmartTileConnectionProfileId.custom,
    label: 'Sur mesure',
    description: 'Choisissez explicitement la structure à résoudre.',
    latticeLabel: 'Structure choisie',
    configuration: null,
  ),
];

SmartTileConnectionProfile smartTileConnectionProfileById(
  SmartTileConnectionProfileId id,
) =>
    smartTileConnectionProfiles.singleWhere((profile) => profile.id == id);

SmartTileConnectionProfile recommendedSmartTileConnectionProfile(
  SmartTileUsage usage,
) =>
    smartTileConnectionProfiles.singleWhere(
      (profile) => profile.isRecommendedFor(usage),
    );

SmartTileConnectionProfile? smartTileConnectionProfileForConfiguration({
  required SmartTileTopology topology,
  required SmartTileTemplateHint templateHint,
}) {
  for (final profile in smartTileConnectionProfiles) {
    final configuration = profile.configuration;
    if (configuration?.topology == topology &&
        configuration?.templateHint == templateHint) {
      return profile;
    }
  }
  return null;
}

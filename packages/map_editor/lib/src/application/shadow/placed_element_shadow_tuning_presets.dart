import 'package:map_core/map_core.dart';

final class PlacedElementShadowTuningPreset {
  const PlacedElementShadowTuningPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.offsetX,
    required this.offsetY,
    required this.scaleX,
    required this.scaleY,
    required this.opacity,
  });

  final String id;
  final String label;
  final String description;
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double opacity;
}

List<PlacedElementShadowTuningPreset> createPlacedElementShadowTuningPresets() {
  return const [
    PlacedElementShadowTuningPreset(
      id: 'compact-footprint',
      label: 'Petite ombre',
      description: 'Réduit fortement l’emprise au sol.',
      offsetX: 0,
      offsetY: 2,
      scaleX: 0.65,
      scaleY: 0.45,
      opacity: 0.24,
    ),
    PlacedElementShadowTuningPreset(
      id: 'soft-wide-footprint',
      label: 'Ombre large douce',
      description: 'Plus large, plus discrète, utile pour les objets bas.',
      offsetX: 0,
      offsetY: 3,
      scaleX: 1.15,
      scaleY: 0.60,
      opacity: 0.22,
    ),
    PlacedElementShadowTuningPreset(
      id: 'subtle-footprint',
      label: 'Ombre discrète',
      description: 'Ombre légère pour les petits props.',
      offsetX: 0,
      offsetY: 2,
      scaleX: 0.75,
      scaleY: 0.35,
      opacity: 0.14,
    ),
    PlacedElementShadowTuningPreset(
      id: 'cast-bottom-right',
      label: 'Portée bas-droite',
      description: 'Simule une lumière venant du haut-gauche.',
      offsetX: 6,
      offsetY: 5,
      scaleX: 0.85,
      scaleY: 0.45,
      opacity: 0.26,
    ),
    PlacedElementShadowTuningPreset(
      id: 'cast-bottom-left',
      label: 'Portée bas-gauche',
      description: 'Simule une lumière venant du haut-droite.',
      offsetX: -6,
      offsetY: 5,
      scaleX: 0.85,
      scaleY: 0.45,
      opacity: 0.26,
    ),
  ];
}

MapPlacedElementShadowOverride applyPlacedElementShadowTuningPreset({
  required PlacedElementShadowTuningPreset preset,
  MapPlacedElementShadowOverride? currentOverride,
}) {
  final shadowProfileId = currentOverride?.mode == ShadowOverrideMode.custom
      ? currentOverride?.shadowProfileId
      : null;
  return MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    shadowProfileId: shadowProfileId,
    offsetX: preset.offsetX,
    offsetY: preset.offsetY,
    scaleX: preset.scaleX,
    scaleY: preset.scaleY,
    opacity: preset.opacity,
  );
}

import 'package:map_core/map_core_domain.dart';

String? mapAtmosphereOverrides(
  SpatialVisualPatch? effective,
  SpatialVisualPatch? local,
) {
  if (effective == null) return null;
  const groups = <(String, List<SpatialVisualParameter>)>[
    (
      'profondeur de champ',
      [
        SpatialVisualParameter.depthOfFieldEnabled,
        SpatialVisualParameter.depthOfFieldStrength,
        SpatialVisualParameter.depthOfFieldFocusRange,
      ],
    ),
    (
      'halos',
      [
        SpatialVisualParameter.halosEnabled,
        SpatialVisualParameter.haloStrength,
        SpatialVisualParameter.haloSpread,
      ],
    ),
    (
      'brume',
      [
        SpatialVisualParameter.depthFogEnabled,
        SpatialVisualParameter.fogOpacity,
        SpatialVisualParameter.fogStart,
        SpatialVisualParameter.fogEnd,
      ],
    ),
    (
      'eau animée',
      [
        SpatialVisualParameter.waterAnimated,
        SpatialVisualParameter.waterStrength,
        SpatialVisualParameter.waterSpeed,
      ],
    ),
    (
      'fenêtres',
      [
        SpatialVisualParameter.windowsLit,
        SpatialVisualParameter.windowStrength,
      ],
    ),
    (
      'lucioles',
      [SpatialVisualParameter.fireflies, SpatialVisualParameter.fireflyDensity],
    ),
  ];
  final fromProject = <String>[], fromMap = <String>[];
  for (final (label, parameters) in groups) {
    final set = parameters.where((p) => effective.value(p) != null);
    if (set.isEmpty) continue;
    if (set.any((p) => local?.value(p) != null)) {
      fromMap.add(label);
    } else {
      fromProject.add(label);
    }
  }
  if (fromProject.isEmpty && fromMap.isEmpty) return null;
  return [
    'En jeu, des réglages d’image remplacent une partie de ces effets :',
    if (fromProject.isNotEmpty)
      '${fromProject.join(', ')} (réglages du projet › Image et caméra)',
    if (fromMap.isNotEmpty)
      '${fromMap.join(', ')} (dérogation propre à cette carte)',
    'Les sources placées ici (lumières, vitrages, lucioles, eau) restent '
        'celles de cette carte.',
  ].join('\n');
}

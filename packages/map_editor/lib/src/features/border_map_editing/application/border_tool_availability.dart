import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

const String borderVisualOnlySafetyMessage =
    'Visuel uniquement — aucune collision';

@immutable
final class BorderToolAvailability {
  const BorderToolAvailability._({
    required this.isEnabled,
    required this.disabledReason,
    required this.blueprintRevision,
  });

  const BorderToolAvailability.enabled({required int blueprintRevision})
      : this._(
          isEnabled: true,
          disabledReason: null,
          blueprintRevision: blueprintRevision,
        );

  const BorderToolAvailability.disabled(String reason)
      : this._(
          isEnabled: false,
          disabledReason: reason,
          blueprintRevision: null,
        );

  final bool isEnabled;
  final String? disabledReason;
  final int? blueprintRevision;

  String get permanentSafetyMessage => borderVisualOnlySafetyMessage;
}

BorderToolAvailability assessBorderToolAvailability({
  required ProjectManifest? manifest,
  required MapData? map,
  required String? activeLayerId,
  required String? activeFeatureId,
  Set<BorderBlueprintTemplate> enabledTemplates =
      const <BorderBlueprintTemplate>{
    BorderBlueprintTemplate.organicEdge,
    BorderBlueprintTemplate.masonryLine,
    BorderBlueprintTemplate.postAndRailLine,
  },
}) {
  if (map == null || activeLayerId == null) {
    return const BorderToolAvailability.disabled(
      'Sélectionnez un calque Bordures.',
    );
  }
  BorderLayer? layer;
  for (final candidate in map.layers) {
    if (candidate.id == activeLayerId) {
      if (candidate is BorderLayer) layer = candidate;
      break;
    }
  }
  if (layer == null) {
    return const BorderToolAvailability.disabled(
      'Le calque actif doit être un calque Bordures.',
    );
  }
  if (activeFeatureId == null) {
    return const BorderToolAvailability.disabled(
      'Sélectionnez ou créez une bordure dans ce calque.',
    );
  }
  final feature = layer.content.featureById(activeFeatureId);
  if (feature == null) {
    return const BorderToolAvailability.disabled(
      'La bordure sélectionnée n’existe plus.',
    );
  }
  final record = manifest?.borderCatalog.recordById(feature.blueprintId);
  if (record?.isDeprecated ?? false) {
    return const BorderToolAvailability.disabled(
      'Le blueprint utilisé par cette bordure est obsolète.',
    );
  }
  final revision = record?.latestPublished;
  if (revision == null) {
    return const BorderToolAvailability.disabled(
      'Publiez le blueprint utilisé par cette bordure.',
    );
  }
  final template = revision.definition.template;
  if (!_geometryMatchesTemplate(feature.geometry, template)) {
    return const BorderToolAvailability.disabled(
      'La géométrie de la bordure ne correspond pas à son blueprint.',
    );
  }
  if (!enabledTemplates.contains(template)) {
    return const BorderToolAvailability.disabled(
      'Ce type de bordure ne peut pas encore être dessiné.',
    );
  }
  return BorderToolAvailability.enabled(
    blueprintRevision: revision.revision,
  );
}

bool _geometryMatchesTemplate(
  BorderFeatureGeometry geometry,
  BorderBlueprintTemplate template,
) {
  return switch (template) {
    BorderBlueprintTemplate.organicEdge => geometry is BorderRegionGeometry,
    BorderBlueprintTemplate.masonryLine ||
    BorderBlueprintTemplate.postAndRailLine =>
      geometry is BorderStrokeGeometry,
  };
}

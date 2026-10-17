import 'package:map_core/map_core.dart';

import 'editable_map_document.dart';

final class SpatialRampEditingPreview {
  const SpatialRampEditingPreview._({
    required this.source,
    required this.result,
    required this.updatedRamp,
  });

  final MapData source;
  final MapData result;
  final SpatialRamp updatedRamp;
  String get rampId => updatedRamp.id;
  bool get hasChanges => result != source;
  bool validFor(MapData map) => identical(source, map);
}

final class SpatialRampEditingCommands {
  SpatialRampEditingCommands(this.document);

  final EditableMapDocument document;

  SpatialRampEditingPreview preview(SpatialRamp ramp) {
    _requireEditable();
    final source = document.current;
    final scene = source.spatialScene;
    if (scene == null) {
      throw StateError('L’édition des pentes nécessite une carte 3D.');
    }
    if (!scene.navigation.ramps.any((existing) => existing.id == ramp.id)) {
      throw StateError(
        'Cette pente n’existe plus. Choisissez une autre pente.',
      );
    }
    final result = const SpatialMapOperations().configureNavigation(
      source,
      scene.navigation.copyWith(
        ramps: [
          for (final existing in scene.navigation.ramps)
            if (existing.id == ramp.id) ramp else existing,
        ],
      ),
    );
    return SpatialRampEditingPreview._(
      source: source,
      result: result,
      updatedRamp: ramp,
    );
  }

  void apply(SpatialRampEditingPreview preview) {
    _requireEditable();
    if (!preview.validFor(document.current)) {
      throw StateError(
        'La carte a changé. Préparez un nouvel aperçu avant d’appliquer la pente.',
      );
    }
    document.commit(preview.result);
  }

  void _requireEditable() {
    if (document.saving) {
      throw StateError('Attendez la fin de l’enregistrement de la carte.');
    }
  }
}

String spatialRampEditingFailureMessage(Object failure) {
  if (failure is StateError) return failure.message.toString();
  if (failure is FormatException) {
    return switch (failure.message) {
      'A ramp surface must reference an existing model instance.' => 'Le décor associé à la pente n’existe plus. Choisissez un autre décor ou le terrain peint.',
      'A ramp surface must allow movement.' => 'Le décor associé bloque le passage. Désactivez sa collision avant de l’utiliser comme escalier.',
      'A ramp must contact its low and high terrain levels.' => 'Les deux extrémités de la pente doivent toucher les sols aux niveaux bas et haut choisis.',
      'Navigation rectangles must not overlap.' =>
        'La pente ne peut pas chevaucher une autre pente ou une zone bloquée.',
      'Navigation must be inside the spatial map.' =>
        'La pente doit rester entièrement à l’intérieur de la carte.',
      'Invalid spatial ramp levels or identity.' =>
        'Le niveau haut doit dépasser le niveau bas, entre 0 et 64.',
      'Invalid spatial navigation rectangle.' => 'Les coordonnées doivent être positives ou nulles et les dimensions strictement positives, dans les limites de la carte.',
      _ => 'Vérifiez la position, les dimensions et les niveaux de la pente.',
    };
  }
  return 'Impossible de préparer cette pente. Rechargez la carte et réessayez.';
}

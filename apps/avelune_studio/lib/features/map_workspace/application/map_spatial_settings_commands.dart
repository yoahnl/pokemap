import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core_domain.dart' hide SpatialMapOperations;

import 'editable_map_document.dart';

String _frenchNumber(double value, int digits) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

String? mapCameraOverrides(EditableMapDocument document) {
  final effective = document.visualProfile;
  final local = document.weatherVisuals?.preview.value;
  final entries = <(SpatialVisualParameter, String)>[
    for (final (parameter, label, digits, unit) in const [
      (SpatialVisualParameter.pitchDegrees, 'Inclinaison', 1, '°'),
      (SpatialVisualParameter.yawDegrees, 'Orientation', 0, '°'),
      (SpatialVisualParameter.fieldOfViewDegrees, 'Champ de vision', 1, '°'),
      (SpatialVisualParameter.cameraDistance, 'Distance', 2, ' cases'),
    ])
      if (effective.number(parameter) case final value?)
        (parameter, '$label ${_frenchNumber(value, digits)}$unit'),
  ];
  if (entries.isEmpty) return null;
  final fromMap = entries
      .where((entry) => local?.value(entry.$1) != null)
      .map((entry) => entry.$2);
  final fromProject = entries
      .where((entry) => local?.value(entry.$1) == null)
      .map((entry) => entry.$2);
  return [
    'En jeu, ces valeurs remplacent celles de cette caméra :',
    if (fromProject.isNotEmpty)
      '${fromProject.join(', ')} (réglages du projet › Image et caméra)',
    if (fromMap.isNotEmpty)
      '${fromMap.join(', ')} (dérogation propre à cette carte)',
    'Les autres champs de cette caméra s’appliquent tels quels.',
  ].join('\n');
}

class MapSpatialSettingsCommands {
  MapSpatialSettingsCommands(this.document);
  final EditableMapDocument document;

  bool fishingDrop(String text, ProjectManifest project) {
    if (document.saving) return false;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || !value.isFinite || value < 0 || value > 4) {
      document.error =
          'Choisissez une hauteur de lancer comprise entre 0 et 4 cases.';
      return false;
    }
    final map = document.current;
    document.commit(
      const SpatialMapOperations().configureNavigation(
        map,
        map.spatialScene!.navigation.copyWith(maximumFishingDropWorld: value),
        models: project.models3d,
      ),
    );
    document.error = null;
    return true;
  }

  bool terrainAppearance({
    SmartTileFrameRef? cliffFrame,
    bool? generateCliffs,
  }) {
    if (document.saving) return false;
    try {
      document.commit(
        const SpatialMapOperations().configureTerrainAppearance(
          document.current,
          cliffFrame: cliffFrame,
          generateCliffs: generateCliffs,
        ),
      );
      return true;
    } on Object catch (failure) {
      document.error = failure.toString();
      return false;
    }
  }

  bool camera(SpatialCameraProfile Function() update) {
    try {
      document.commit(
        const SpatialMapOperations().configureCamera(
          document.current,
          update(),
        ),
      );
      return true;
    } on FormatException {
      document.error = 'La caméra exige une inclinaison entre 0 et 90°, une taille et une distance positives.';
      return false;
    }
  }

  bool cameraNumber(String text, SpatialCameraProfile Function(double) update) {
    final number = double.tryParse(text.trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite) {
      document.error = 'Saisissez un nombre valide.';
      return false;
    }
    return camera(() => update(number));
  }

  bool dayNight(SpatialDayNightCycle? next) {
    try {
      document.commit(
        const SpatialMapOperations().configureDayNightCycle(
          document.current,
          next,
        ),
      );
      document.error = null;
      return true;
    } on FormatException catch (failure) {
      document.error = '$failure';
      return false;
    }
  }

  bool dayDuration(String text, SpatialDayNightCycle cycle) {
    final minutes = double.tryParse(text.trim().replaceAll(',', '.'));
    if (minutes == null ||
        !minutes.isFinite ||
        minutes * 60 < 10 ||
        minutes * 60 > 86400) {
      document.error = 'Choisissez une durée entre 10 secondes et 24 heures.';
      return false;
    }
    return dayNight(
      SpatialDayNightCycle(
        durationSeconds: minutes * 60,
        startMinuteOfDay: cycle.startMinuteOfDay,
      ),
    );
  }

  bool dayStart(String text, SpatialDayNightCycle cycle) {
    final parts = text.trim().split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      document.error = 'Saisissez une heure entre 00:00 et 23:59.';
      return false;
    }
    return dayNight(
      SpatialDayNightCycle(
        durationSeconds: cycle.durationSeconds,
        startMinuteOfDay: hour * 60 + minute,
      ),
    );
  }
}

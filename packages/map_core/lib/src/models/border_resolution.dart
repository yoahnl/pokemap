import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'border_blueprint.dart';
import 'border_diagnostics.dart';
import 'border_feature.dart';
import 'border_materialization.dart';
import 'border_visual_snapshot.dart';
import 'geometry.dart';

/// Complete pure input to one deterministic Border resolution attempt.
@immutable
final class BorderResolutionRequest {
  factory BorderResolutionRequest({
    required GridSize mapSize,
    required GridSize tileSizePx,
    required String blueprintId,
    required BorderBlueprintRevision? blueprintRevision,
    required BorderFeature feature,
    required Iterable<BorderVisualSnapshot> visualSnapshots,
    required int resolverVersion,
  }) {
    _requirePositiveSize(mapSize, 'BorderResolutionRequest.mapSize');
    _requirePositiveSize(tileSizePx, 'BorderResolutionRequest.tileSizePx');
    _requireStableText(blueprintId, 'BorderResolutionRequest.blueprintId');
    if (feature.blueprintId != blueprintId) {
      throw const ValidationException(
        'BorderResolutionRequest.blueprintId must match feature.blueprintId',
      );
    }
    if (resolverVersion < 1) {
      throw const ValidationException(
        'BorderResolutionRequest.resolverVersion must be >= 1',
      );
    }

    final sortedSnapshots = List<BorderVisualSnapshot>.of(visualSnapshots)
      ..sort((first, second) => first.id.compareTo(second.id));
    for (var index = 1; index < sortedSnapshots.length; index += 1) {
      if (sortedSnapshots[index - 1].id == sortedSnapshots[index].id) {
        throw ValidationException(
          'BorderResolutionRequest.visualSnapshots must not contain '
          'duplicate ids: ${sortedSnapshots[index].id}',
        );
      }
    }

    return BorderResolutionRequest._(
      mapSize: GridSize(width: mapSize.width, height: mapSize.height),
      tileSizePx: GridSize(
        width: tileSizePx.width,
        height: tileSizePx.height,
      ),
      blueprintId: blueprintId,
      blueprintRevision: blueprintRevision,
      feature: _withoutMaterialization(feature),
      visualSnapshots: List<BorderVisualSnapshot>.unmodifiable(sortedSnapshots),
      resolverVersion: resolverVersion,
    );
  }

  const BorderResolutionRequest._({
    required this.mapSize,
    required this.tileSizePx,
    required this.blueprintId,
    required this.blueprintRevision,
    required this.feature,
    required List<BorderVisualSnapshot> visualSnapshots,
    required this.resolverVersion,
  }) : _visualSnapshots = visualSnapshots;

  final GridSize mapSize;
  final GridSize tileSizePx;
  final String blueprintId;
  final BorderBlueprintRevision? blueprintRevision;
  final BorderFeature feature;
  final List<BorderVisualSnapshot> _visualSnapshots;
  final int resolverVersion;

  List<BorderVisualSnapshot> get visualSnapshots => _visualSnapshots;

  BorderVisualSnapshot? visualSnapshotById(String id) {
    var lower = 0;
    var upper = _visualSnapshots.length - 1;
    while (lower <= upper) {
      final middle = lower + ((upper - lower) ~/ 2);
      final candidate = _visualSnapshots[middle];
      final comparison = candidate.id.compareTo(id);
      if (comparison == 0) {
        return candidate;
      }
      if (comparison < 0) {
        lower = middle + 1;
      } else {
        upper = middle - 1;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderResolutionRequest &&
          mapSize == other.mapSize &&
          tileSizePx == other.tileSizePx &&
          blueprintId == other.blueprintId &&
          blueprintRevision == other.blueprintRevision &&
          feature == other.feature &&
          _listsEqual(_visualSnapshots, other._visualSnapshots) &&
          resolverVersion == other.resolverVersion;

  @override
  int get hashCode => Object.hash(
        mapSize,
        tileSizePx,
        blueprintId,
        blueprintRevision,
        feature,
        Object.hashAll(_visualSnapshots),
        resolverVersion,
      );
}

enum BorderResolutionStatus {
  success,
  warning,
  error,
}

/// Output and canonical diagnostics produced by one resolution attempt.
@immutable
final class BorderResolutionResult {
  BorderResolutionResult({
    required this.materialization,
    required this.diagnosticReport,
  }) {
    if ((materialization == null) != diagnosticReport.hasErrors) {
      throw const ValidationException(
        'BorderResolutionResult.materialization must be null exactly when '
        'diagnostics contain errors',
      );
    }
  }

  final BorderMaterialization? materialization;
  final BorderDiagnosticsReport diagnosticReport;

  BorderResolutionStatus get status {
    if (diagnosticReport.hasErrors) {
      return BorderResolutionStatus.error;
    }
    if (diagnosticReport.hasWarnings) {
      return BorderResolutionStatus.warning;
    }
    return BorderResolutionStatus.success;
  }

  List<BorderDiagnostic> get diagnostics => diagnosticReport.diagnostics;

  bool get canApply => !diagnosticReport.hasErrors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderResolutionResult &&
          materialization == other.materialization &&
          diagnosticReport == other.diagnosticReport;

  @override
  int get hashCode => Object.hash(materialization, diagnosticReport);
}

BorderFeature _withoutMaterialization(BorderFeature feature) => BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: null,
    );

void _requirePositiveSize(GridSize size, String field) {
  if (size.width <= 0 || size.height <= 0) {
    throw ValidationException('$field dimensions must be > 0');
  }
}

void _requireStableText(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
}

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

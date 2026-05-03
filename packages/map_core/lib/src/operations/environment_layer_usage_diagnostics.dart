import '../models/environment.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';

/// Gravité d’un diagnostic d’usage Environment sur carte (Lot Environment-7).
enum EnvironmentLayerUsageDiagnosticSeverity {
  error,
  warning,
}

/// Catégorie de diagnostic d’usage (Lot Environment-7).
enum EnvironmentLayerUsageDiagnosticKind {
  missingAreaPreset,
  missingTargetTileLayerId,
  unknownTargetTileLayer,
  targetLayerIsNotTileLayer,
  areaMaskSizeMismatch,
  emptyAreaMask,
  missingGeneratedPlacement,
}

/// Un problème d’usage Environment sur une [MapData].
final class EnvironmentLayerUsageDiagnostic {
  const EnvironmentLayerUsageDiagnostic({
    required this.severity,
    required this.kind,
    required this.mapId,
    required this.layerId,
    this.areaId,
    this.presetId,
    this.targetTileLayerId,
    this.generatedPlacementId,
    required this.message,
  });

  final EnvironmentLayerUsageDiagnosticSeverity severity;
  final EnvironmentLayerUsageDiagnosticKind kind;
  final String mapId;
  final String layerId;
  final String? areaId;
  final String? presetId;
  final String? targetTileLayerId;
  final String? generatedPlacementId;
  final String message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentLayerUsageDiagnostic &&
            severity == other.severity &&
            kind == other.kind &&
            mapId == other.mapId &&
            layerId == other.layerId &&
            areaId == other.areaId &&
            presetId == other.presetId &&
            targetTileLayerId == other.targetTileLayerId &&
            generatedPlacementId == other.generatedPlacementId &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        mapId,
        layerId,
        areaId,
        presetId,
        targetTileLayerId,
        generatedPlacementId,
        message,
      );
}

/// Rapport agrégé pour une carte.
final class EnvironmentLayerUsageDiagnosticsReport {
  factory EnvironmentLayerUsageDiagnosticsReport({
    required List<EnvironmentLayerUsageDiagnostic> diagnostics,
  }) {
    return EnvironmentLayerUsageDiagnosticsReport._(
      diagnostics: List<EnvironmentLayerUsageDiagnostic>.unmodifiable(
        List<EnvironmentLayerUsageDiagnostic>.from(diagnostics),
      ),
    );
  }

  const EnvironmentLayerUsageDiagnosticsReport._({
    required this.diagnostics,
  });

  final List<EnvironmentLayerUsageDiagnostic> diagnostics;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  bool get hasErrors => diagnostics.any(
        (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.error,
      );

  bool get hasWarnings => diagnostics.any(
        (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.warning,
      );

  int get diagnosticCount => diagnostics.length;

  int get errorCount => diagnostics
      .where((d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.error)
      .length;

  int get warningCount => diagnostics
      .where(
          (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.warning)
      .length;

  List<EnvironmentLayerUsageDiagnostic> diagnosticsForLayer(String layerId) {
    final key = layerId.trim();
    if (key.isEmpty) {
      return const [];
    }
    final out = <EnvironmentLayerUsageDiagnostic>[];
    for (final d in diagnostics) {
      if (d.layerId == key) {
        out.add(d);
      }
    }
    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(out);
  }

  List<EnvironmentLayerUsageDiagnostic> diagnosticsForArea(String areaId) {
    final key = areaId.trim();
    if (key.isEmpty) {
      return const [];
    }
    final out = <EnvironmentLayerUsageDiagnostic>[];
    for (final d in diagnostics) {
      if (d.areaId == key) {
        out.add(d);
      }
    }
    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(out);
  }

  List<EnvironmentLayerUsageDiagnostic> diagnosticsForKind(
    EnvironmentLayerUsageDiagnosticKind kind,
  ) {
    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.kind == kind).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentLayerUsageDiagnosticsReport &&
            _listEqualsUsage(other.diagnostics, diagnostics);
  }

  @override
  int get hashCode => Object.hashAll(diagnostics);
}

bool _listEqualsUsage(
  List<EnvironmentLayerUsageDiagnostic> a,
  List<EnvironmentLayerUsageDiagnostic> b,
) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

String _mapLayerId(MapLayer layer) {
  return switch (layer) {
    TileLayer(:final id) => id,
    CollisionLayer(:final id) => id,
    TerrainLayer(:final id) => id,
    PathLayer(:final id) => id,
    SurfaceLayer(:final id) => id,
    ObjectLayer(:final id) => id,
    EnvironmentLayer(:final id) => id,
  };
}

/// Diagnostique les layers Environment d’une [MapData] (lecture seule, pas d’exception).
///
/// Ordre : pour chaque [EnvironmentLayer] dans [MapData.layers], d’abord les
/// diagnostics sur `targetTileLayerId` ([missingTargetTileLayerId],
/// [unknownTargetTileLayer], [targetLayerIsNotTileLayer]), puis pour chaque
/// [EnvironmentArea] dans l’ordre : [areaMaskSizeMismatch], [emptyAreaMask],
/// [missingAreaPreset], puis [missingGeneratedPlacement] dans l’ordre des ids.
EnvironmentLayerUsageDiagnosticsReport diagnoseMapEnvironmentLayerUsage(
  ProjectManifest manifest,
  MapData map,
) {
  final diagnostics = <EnvironmentLayerUsageDiagnostic>[];
  final presetIds = <String>{
    for (final p in manifest.environmentPresets) p.id,
  };
  final placedIds = <String>{
    for (final pe in map.placedElements) pe.id,
  };

  MapLayer? targetForId(String? targetId) {
    if (targetId == null) {
      return null;
    }
    for (final l in map.layers) {
      if (_mapLayerId(l) == targetId) {
        return l;
      }
    }
    return null;
  }

  for (final layer in map.layers) {
    if (layer is! EnvironmentLayer) {
      continue;
    }
    final layerId = layer.id;
    final content = layer.content;
    final areas = content.areas;

    if (areas.isNotEmpty && content.targetTileLayerId == null) {
      diagnostics.add(
        EnvironmentLayerUsageDiagnostic(
          severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
          kind: EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
          mapId: map.id,
          layerId: layerId,
          message:
              'Environment layer "$layerId" has areas but no target tile layer.',
        ),
      );
    }

    final targetId = content.targetTileLayerId;
    if (targetId != null) {
      final targetLayer = targetForId(targetId);
      if (targetLayer == null) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
            kind: EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
            mapId: map.id,
            layerId: layerId,
            targetTileLayerId: targetId,
            message:
                'Environment layer "$layerId" targets missing tile layer "$targetId".',
          ),
        );
      } else if (targetLayer is! TileLayer) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
            kind: EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
            mapId: map.id,
            layerId: layerId,
            targetTileLayerId: targetId,
            message:
                'Environment layer "$layerId" targets layer "$targetId", but it is not a TileLayer.',
          ),
        );
      }
    }

    for (final area in areas) {
      final aid = area.id;
      if (area.mask.width != map.size.width ||
          area.mask.height != map.size.height) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
            kind: EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
            mapId: map.id,
            layerId: layerId,
            areaId: aid,
            message:
                'Environment area "$aid" mask size ${area.mask.width}x${area.mask.height} does not match map size ${map.size.width}x${map.size.height}.',
          ),
        );
      }
      if (!area.mask.hasAnyActiveCell) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
            kind: EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
            mapId: map.id,
            layerId: layerId,
            areaId: aid,
            message: 'Environment area "$aid" has an empty mask.',
          ),
        );
      }
      if (!presetIds.contains(area.presetId)) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
            kind: EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
            mapId: map.id,
            layerId: layerId,
            areaId: aid,
            presetId: area.presetId,
            message:
                'Environment area "$aid" on layer "$layerId" references missing preset "${area.presetId}".',
          ),
        );
      }
      for (final pid in area.generatedPlacementIds) {
        if (!placedIds.contains(pid)) {
          diagnostics.add(
            EnvironmentLayerUsageDiagnostic(
              severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
              kind:
                  EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
              mapId: map.id,
              layerId: layerId,
              areaId: aid,
              generatedPlacementId: pid,
              message:
                  'Environment area "$aid" references generated placement "$pid", but it is not present in map.placedElements.',
            ),
          );
        }
      }
    }
  }

  return EnvironmentLayerUsageDiagnosticsReport(diagnostics: diagnostics);
}

import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'environment_layer_usage_diagnostics.dart';
import 'environment_preset_diagnostics.dart';

/// Gravité unifiée pour l’UI auteur Environment (Lot Environment-8).
enum EnvironmentAuthoringDiagnosticSeverity {
  error,
  warning,
}

/// Origine du diagnostic dans la pile Environment.
enum EnvironmentAuthoringDiagnosticSource {
  /// Issu de [diagnoseProjectEnvironmentPresets].
  presetManifest,

  /// Issu de [diagnoseMapEnvironmentLayerUsage].
  layerUsage,
}

/// Union des kinds des lots Environment-6 et Environment-7.
enum EnvironmentAuthoringDiagnosticKind {
  duplicatePresetId,
  missingPaletteElement,
  unknownTemplateId,
  forcedCollisionWithoutProfile,
  missingAreaPreset,
  missingTargetTileLayerId,
  unknownTargetTileLayer,
  targetLayerIsNotTileLayer,
  areaMaskSizeMismatch,
  emptyAreaMask,
  missingGeneratedPlacement,
}

/// Ligne de diagnostic prête pour agrégation / UI.
final class EnvironmentAuthoringDiagnostic {
  const EnvironmentAuthoringDiagnostic({
    required this.source,
    required this.severity,
    required this.kind,
    required this.message,
    this.mapId,
    this.layerId,
    this.areaId,
    this.presetId,
    this.elementId,
    this.templateId,
    this.targetTileLayerId,
    this.generatedPlacementId,
  });

  final EnvironmentAuthoringDiagnosticSource source;
  final EnvironmentAuthoringDiagnosticSeverity severity;
  final EnvironmentAuthoringDiagnosticKind kind;
  final String message;

  final String? mapId;
  final String? layerId;
  final String? areaId;
  final String? presetId;
  final String? elementId;
  final String? templateId;
  final String? targetTileLayerId;
  final String? generatedPlacementId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAuthoringDiagnostic &&
            source == other.source &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            mapId == other.mapId &&
            layerId == other.layerId &&
            areaId == other.areaId &&
            presetId == other.presetId &&
            elementId == other.elementId &&
            templateId == other.templateId &&
            targetTileLayerId == other.targetTileLayerId &&
            generatedPlacementId == other.generatedPlacementId;
  }

  @override
  int get hashCode => Object.hash(
        source,
        severity,
        kind,
        message,
        mapId,
        layerId,
        areaId,
        presetId,
        elementId,
        templateId,
        targetTileLayerId,
        generatedPlacementId,
      );
}

/// Compteurs globaux pour un tableau de bord auteur.
final class EnvironmentAuthoringDiagnosticsSummary {
  const EnvironmentAuthoringDiagnosticsSummary({
    required this.totalCount,
    required this.errorCount,
    required this.warningCount,
    required this.presetManifestCount,
    required this.layerUsageCount,
    required this.mapsWithDiagnosticsCount,
    required this.presetsWithDiagnosticsCount,
  });

  final int totalCount;
  final int errorCount;
  final int warningCount;
  final int presetManifestCount;
  final int layerUsageCount;
  final int mapsWithDiagnosticsCount;
  final int presetsWithDiagnosticsCount;

  bool get hasDiagnostics => totalCount > 0;

  bool get hasErrors => errorCount > 0;

  bool get hasWarnings => warningCount > 0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAuthoringDiagnosticsSummary &&
            totalCount == other.totalCount &&
            errorCount == other.errorCount &&
            warningCount == other.warningCount &&
            presetManifestCount == other.presetManifestCount &&
            layerUsageCount == other.layerUsageCount &&
            mapsWithDiagnosticsCount == other.mapsWithDiagnosticsCount &&
            presetsWithDiagnosticsCount == other.presetsWithDiagnosticsCount;
  }

  @override
  int get hashCode => Object.hash(
        totalCount,
        errorCount,
        warningCount,
        presetManifestCount,
        layerUsageCount,
        mapsWithDiagnosticsCount,
        presetsWithDiagnosticsCount,
      );
}

/// Rapport unifié presets + usages cartes (lecture seule côté entrées).
final class EnvironmentAuthoringDiagnosticsReport {
  factory EnvironmentAuthoringDiagnosticsReport({
    required List<EnvironmentAuthoringDiagnostic> diagnostics,
  }) {
    final copy = List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      List<EnvironmentAuthoringDiagnostic>.from(diagnostics),
    );
    return EnvironmentAuthoringDiagnosticsReport._(
      diagnostics: copy,
      summary: _computeSummary(copy),
    );
  }

  const EnvironmentAuthoringDiagnosticsReport._({
    required this.diagnostics,
    required this.summary,
  });

  final List<EnvironmentAuthoringDiagnostic> diagnostics;

  final EnvironmentAuthoringDiagnosticsSummary summary;

  bool get hasDiagnostics => summary.hasDiagnostics;

  bool get hasErrors => summary.hasErrors;

  bool get hasWarnings => summary.hasWarnings;

  int get diagnosticCount => diagnostics.length;

  int get errorCount => summary.errorCount;

  int get warningCount => summary.warningCount;

  List<EnvironmentAuthoringDiagnostic> diagnosticsForSource(
    EnvironmentAuthoringDiagnosticSource source,
  ) {
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.source == source).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForKind(
    EnvironmentAuthoringDiagnosticKind kind,
  ) {
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.kind == kind).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForMap(String mapId) {
    final key = mapId.trim();
    if (key.isEmpty) {
      return const [];
    }
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.mapId == key).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForLayer(String layerId) {
    final key = layerId.trim();
    if (key.isEmpty) {
      return const [];
    }
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.layerId == key).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForArea(String areaId) {
    final key = areaId.trim();
    if (key.isEmpty) {
      return const [];
    }
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.areaId == key).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForPreset(String presetId) {
    final key = presetId.trim();
    if (key.isEmpty) {
      return const [];
    }
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.presetId == key).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAuthoringDiagnosticsReport &&
            _listEqualsAuthoring(other.diagnostics, diagnostics);
  }

  @override
  int get hashCode => Object.hashAll(diagnostics);
}

EnvironmentAuthoringDiagnosticsSummary _computeSummary(
  List<EnvironmentAuthoringDiagnostic> diagnostics,
) {
  var errors = 0;
  var warnings = 0;
  var presetSrc = 0;
  var layerSrc = 0;
  final mapIds = <String>{};
  final presetIds = <String>{};

  for (final d in diagnostics) {
    switch (d.severity) {
      case EnvironmentAuthoringDiagnosticSeverity.error:
        errors++;
      case EnvironmentAuthoringDiagnosticSeverity.warning:
        warnings++;
    }
    switch (d.source) {
      case EnvironmentAuthoringDiagnosticSource.presetManifest:
        presetSrc++;
      case EnvironmentAuthoringDiagnosticSource.layerUsage:
        layerSrc++;
    }
    final mid = d.mapId;
    if (mid != null) {
      mapIds.add(mid);
    }
    final pid = d.presetId;
    if (pid != null) {
      presetIds.add(pid);
    }
  }

  final n = diagnostics.length;

  return EnvironmentAuthoringDiagnosticsSummary(
    totalCount: n,
    errorCount: errors,
    warningCount: warnings,
    presetManifestCount: presetSrc,
    layerUsageCount: layerSrc,
    mapsWithDiagnosticsCount: mapIds.length,
    presetsWithDiagnosticsCount: presetIds.length,
  );
}

bool _listEqualsAuthoring(
  List<EnvironmentAuthoringDiagnostic> a,
  List<EnvironmentAuthoringDiagnostic> b,
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

EnvironmentAuthoringDiagnosticSeverity _mapPresetSeverity(
  EnvironmentPresetDiagnosticSeverity s,
) {
  return switch (s) {
    EnvironmentPresetDiagnosticSeverity.error =>
      EnvironmentAuthoringDiagnosticSeverity.error,
    EnvironmentPresetDiagnosticSeverity.warning =>
      EnvironmentAuthoringDiagnosticSeverity.warning,
  };
}

EnvironmentAuthoringDiagnosticKind _mapPresetKind(
  EnvironmentPresetDiagnosticKind k,
) {
  return switch (k) {
    EnvironmentPresetDiagnosticKind.duplicatePresetId =>
      EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
    EnvironmentPresetDiagnosticKind.missingPaletteElement =>
      EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
    EnvironmentPresetDiagnosticKind.unknownTemplateId =>
      EnvironmentAuthoringDiagnosticKind.unknownTemplateId,
    EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile =>
      EnvironmentAuthoringDiagnosticKind.forcedCollisionWithoutProfile,
  };
}

EnvironmentAuthoringDiagnostic _fromPreset(EnvironmentPresetDiagnostic d) {
  return EnvironmentAuthoringDiagnostic(
    source: EnvironmentAuthoringDiagnosticSource.presetManifest,
    severity: _mapPresetSeverity(d.severity),
    kind: _mapPresetKind(d.kind),
    message: d.message,
    presetId: d.presetId,
    elementId: d.elementId,
    templateId: d.templateId,
  );
}

EnvironmentAuthoringDiagnosticSeverity _mapUsageSeverity(
  EnvironmentLayerUsageDiagnosticSeverity s,
) {
  return switch (s) {
    EnvironmentLayerUsageDiagnosticSeverity.error =>
      EnvironmentAuthoringDiagnosticSeverity.error,
    EnvironmentLayerUsageDiagnosticSeverity.warning =>
      EnvironmentAuthoringDiagnosticSeverity.warning,
  };
}

EnvironmentAuthoringDiagnosticKind _mapUsageKind(
  EnvironmentLayerUsageDiagnosticKind k,
) {
  return switch (k) {
    EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
      EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
    EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
      EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
    EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
      EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
    EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
      EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
    EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
      EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
    EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
      EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
    EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
      EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
  };
}

EnvironmentAuthoringDiagnostic _fromUsage(EnvironmentLayerUsageDiagnostic d) {
  return EnvironmentAuthoringDiagnostic(
    source: EnvironmentAuthoringDiagnosticSource.layerUsage,
    severity: _mapUsageSeverity(d.severity),
    kind: _mapUsageKind(d.kind),
    message: d.message,
    mapId: d.mapId,
    layerId: d.layerId,
    areaId: d.areaId,
    presetId: d.presetId,
    targetTileLayerId: d.targetTileLayerId,
    generatedPlacementId: d.generatedPlacementId,
  );
}

/// Agrège les diagnostics Environment presets (Lot 6) et usages cartes (Lot 7).
///
/// [maps] : uniquement les cartes déjà chargées ; aucune lecture disque ni
/// chargement depuis [ProjectManifest.maps].
///
/// Ordre : diagnostics presets dans l’ordre de [diagnoseProjectEnvironmentPresets],
/// puis pour chaque entrée de [maps] dans l’ordre, les diagnostics de
/// [diagnoseMapEnvironmentLayerUsage] pour cette carte.
EnvironmentAuthoringDiagnosticsReport diagnoseProjectEnvironmentAuthoring(
  ProjectManifest manifest, {
  required List<MapData> maps,
  Set<String> knownTemplateIds = const <String>{},
}) {
  final out = <EnvironmentAuthoringDiagnostic>[];

  final presetReport = diagnoseProjectEnvironmentPresets(
    manifest,
    knownTemplateIds: knownTemplateIds,
  );
  for (final d in presetReport.diagnostics) {
    out.add(_fromPreset(d));
  }

  for (final map in maps) {
    final usageReport = diagnoseMapEnvironmentLayerUsage(manifest, map);
    for (final d in usageReport.diagnostics) {
      out.add(_fromUsage(d));
    }
  }

  return EnvironmentAuthoringDiagnosticsReport(diagnostics: out);
}

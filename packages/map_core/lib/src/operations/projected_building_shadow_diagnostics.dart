import '../models/project_manifest.dart';
import '../models/projected_building_shadow.dart';

enum ProjectedBuildingShadowDiagnosticSeverity {
  info,
  warning,
  error,
}

enum ProjectedBuildingShadowDiagnosticKind {
  missingPreset,
  missingPresetForDisabledConfig,
  unusedPreset,
  v1AndV2Coexistence,
  followsSunWithoutTimeOfDay,
}

final class ProjectedBuildingShadowDiagnostic {
  const ProjectedBuildingShadowDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    this.elementId,
    this.elementName,
    this.presetId,
    this.presetName,
  });

  final ProjectedBuildingShadowDiagnosticSeverity severity;
  final ProjectedBuildingShadowDiagnosticKind kind;
  final String message;
  final String? elementId;
  final String? elementName;
  final String? presetId;
  final String? presetName;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProjectedBuildingShadowDiagnostic &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            elementId == other.elementId &&
            elementName == other.elementName &&
            presetId == other.presetId &&
            presetName == other.presetName;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        elementId,
        elementName,
        presetId,
        presetName,
      );
}

/// Diagnoses authored projected building shadow V2 data in memory.
///
/// This is intentionally not a resolver, renderer, validator, migration, or
/// autofix: it reports semantic authoring issues without mutating [manifest].
List<ProjectedBuildingShadowDiagnostic> diagnoseProjectedBuildingShadows(
  ProjectManifest manifest,
) {
  final diagnostics = <ProjectedBuildingShadowDiagnostic>[];
  final catalog = manifest.projectedBuildingShadowCatalog;
  final referencedPresetIds = <String>{};
  final activelyReferencedPresetIds = <String>{};

  for (final element in manifest.elements) {
    final config = element.projectedBuildingShadow;
    if (config == null) {
      continue;
    }

    referencedPresetIds.add(config.presetId);
    if (config.enabled) {
      activelyReferencedPresetIds.add(config.presetId);
    }

    final preset = catalog.presetById(config.presetId);
    if (preset == null) {
      diagnostics.add(
        config.enabled
            ? _missingPresetDiagnostic(element, config)
            : _missingPresetForDisabledConfigDiagnostic(element, config),
      );
    }

    if (config.enabled && element.shadow != null) {
      diagnostics.add(
        _v1AndV2CoexistenceDiagnostic(element, config, preset),
      );
    }
  }

  for (final preset in catalog.presets) {
    if (!referencedPresetIds.contains(preset.id)) {
      diagnostics.add(_unusedPresetDiagnostic(preset));
      continue;
    }

    if (activelyReferencedPresetIds.contains(preset.id) &&
        preset.timeOfDayMode == ProjectedShadowTimeOfDayMode.followsSun) {
      diagnostics.add(_followsSunWithoutTimeOfDayDiagnostic(preset));
    }
  }

  return List<ProjectedBuildingShadowDiagnostic>.unmodifiable(diagnostics);
}

ProjectedBuildingShadowDiagnostic _missingPresetDiagnostic(
  ProjectElementEntry element,
  ProjectElementProjectedBuildingShadowConfig config,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.error,
    kind: ProjectedBuildingShadowDiagnosticKind.missingPreset,
    message:
        'Element "${element.id}" references missing projected building shadow preset "${config.presetId}".',
    elementId: element.id,
    elementName: element.name,
    presetId: config.presetId,
  );
}

ProjectedBuildingShadowDiagnostic _missingPresetForDisabledConfigDiagnostic(
  ProjectElementEntry element,
  ProjectElementProjectedBuildingShadowConfig config,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
    kind: ProjectedBuildingShadowDiagnosticKind.missingPresetForDisabledConfig,
    message:
        'Element "${element.id}" has disabled projected building shadow config referencing missing preset "${config.presetId}".',
    elementId: element.id,
    elementName: element.name,
    presetId: config.presetId,
  );
}

ProjectedBuildingShadowDiagnostic _unusedPresetDiagnostic(
  ProjectBuildingShadowPreset preset,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
    kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
    message:
        'Projected building shadow preset "${preset.id}" is not referenced by any element.',
    presetId: preset.id,
    presetName: preset.name,
  );
}

ProjectedBuildingShadowDiagnostic _v1AndV2CoexistenceDiagnostic(
  ProjectElementEntry element,
  ProjectElementProjectedBuildingShadowConfig config,
  ProjectBuildingShadowPreset? preset,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
    kind: ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence,
    message:
        'Element "${element.id}" has both Shadow V1 and enabled projected building shadow V2.',
    elementId: element.id,
    elementName: element.name,
    presetId: config.presetId,
    presetName: preset?.name,
  );
}

ProjectedBuildingShadowDiagnostic _followsSunWithoutTimeOfDayDiagnostic(
  ProjectBuildingShadowPreset preset,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.info,
    kind: ProjectedBuildingShadowDiagnosticKind.followsSunWithoutTimeOfDay,
    message:
        'Projected building shadow preset "${preset.id}" follows the sun, but no time-of-day system is active yet.',
    presetId: preset.id,
    presetName: preset.name,
  );
}

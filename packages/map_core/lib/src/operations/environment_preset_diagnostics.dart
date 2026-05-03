import '../models/environment.dart';
import '../models/project_manifest.dart';

/// Gravité d’un diagnostic preset environnement (Lot Environment-6).
enum EnvironmentPresetDiagnosticSeverity {
  error,
  warning,
}

/// Catégorie de diagnostic (Lot Environment-6).
enum EnvironmentPresetDiagnosticKind {
  duplicatePresetId,
  missingPaletteElement,
  unknownTemplateId,
  forcedCollisionWithoutProfile,
}

/// Un problème détecté sur les presets Environment du manifest.
final class EnvironmentPresetDiagnostic {
  const EnvironmentPresetDiagnostic({
    required this.severity,
    required this.kind,
    required this.presetId,
    this.elementId,
    this.templateId,
    required this.message,
  });

  final EnvironmentPresetDiagnosticSeverity severity;
  final EnvironmentPresetDiagnosticKind kind;
  final String presetId;
  final String? elementId;
  final String? templateId;
  final String message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDiagnostic &&
            severity == other.severity &&
            kind == other.kind &&
            presetId == other.presetId &&
            elementId == other.elementId &&
            templateId == other.templateId &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        presetId,
        elementId,
        templateId,
        message,
      );
}

/// Rapport agrégé des diagnostics [`EnvironmentPreset`] pour un [`ProjectManifest`].
final class EnvironmentPresetDiagnosticsReport {
  factory EnvironmentPresetDiagnosticsReport({
    required List<EnvironmentPresetDiagnostic> diagnostics,
  }) {
    return EnvironmentPresetDiagnosticsReport._(
      diagnostics: List<EnvironmentPresetDiagnostic>.unmodifiable(
        List<EnvironmentPresetDiagnostic>.from(diagnostics),
      ),
    );
  }

  const EnvironmentPresetDiagnosticsReport._({
    required this.diagnostics,
  });

  final List<EnvironmentPresetDiagnostic> diagnostics;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  bool get hasErrors => diagnostics.any(
        (d) => d.severity == EnvironmentPresetDiagnosticSeverity.error,
      );

  bool get hasWarnings => diagnostics.any(
        (d) => d.severity == EnvironmentPresetDiagnosticSeverity.warning,
      );

  int get diagnosticCount => diagnostics.length;

  int get errorCount => diagnostics
      .where((d) => d.severity == EnvironmentPresetDiagnosticSeverity.error)
      .length;

  int get warningCount => diagnostics
      .where((d) => d.severity == EnvironmentPresetDiagnosticSeverity.warning)
      .length;

  List<EnvironmentPresetDiagnostic> diagnosticsForPreset(String presetId) {
    final key = presetId.trim();
    if (key.isEmpty) {
      return const [];
    }
    final out = <EnvironmentPresetDiagnostic>[];
    for (final d in diagnostics) {
      if (d.presetId == key) {
        out.add(d);
      }
    }
    return List<EnvironmentPresetDiagnostic>.unmodifiable(out);
  }

  List<EnvironmentPresetDiagnostic> diagnosticsForKind(
    EnvironmentPresetDiagnosticKind kind,
  ) {
    return List<EnvironmentPresetDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.kind == kind).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDiagnosticsReport &&
            _listEqualsDiagnostics(other.diagnostics, diagnostics);
  }

  @override
  int get hashCode => Object.hashAll(diagnostics);
}

bool _listEqualsDiagnostics(
  List<EnvironmentPresetDiagnostic> a,
  List<EnvironmentPresetDiagnostic> b,
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

/// Diagnostique les [`EnvironmentPreset`] du manifest (aucune mutation, jamais d’exception).
///
/// [knownTemplateIds] vide : aucun diagnostic [unknownTemplateId]. Sinon, tout
/// [EnvironmentPreset.templateId] absent du set génère un avertissement.
EnvironmentPresetDiagnosticsReport diagnoseProjectEnvironmentPresets(
  ProjectManifest manifest, {
  Set<String> knownTemplateIds = const <String>{},
}) {
  final diagnostics = <EnvironmentPresetDiagnostic>[];
  final presets = manifest.environmentPresets;

  final firstIndex = <String, int>{};
  final duplicateIds = <String>{};
  for (var i = 0; i < presets.length; i++) {
    final id = presets[i].id;
    if (firstIndex.containsKey(id)) {
      duplicateIds.add(id);
    } else {
      firstIndex[id] = i;
    }
  }
  final orderedDuplicateIds = duplicateIds.toList(growable: false)
    ..sort((a, b) => firstIndex[a]!.compareTo(firstIndex[b]!));

  for (final dupId in orderedDuplicateIds) {
    diagnostics.add(
      EnvironmentPresetDiagnostic(
        severity: EnvironmentPresetDiagnosticSeverity.error,
        kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
        presetId: dupId,
        message: 'Environment preset "$dupId" is declared more than once.',
      ),
    );
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final e in manifest.elements) e.id: e,
  };

  for (final preset in presets) {
    for (final item in preset.palette) {
      if (!elementsById.containsKey(item.elementId)) {
        diagnostics.add(
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.error,
            kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
            presetId: preset.id,
            elementId: item.elementId,
            message:
                'Environment preset "${preset.id}" references missing element "${item.elementId}".',
          ),
        );
      }
    }

    for (final item in preset.palette) {
      if (item.collisionMode != EnvironmentCollisionMode.forceEnabled) {
        continue;
      }
      final entry = elementsById[item.elementId];
      if (entry == null) {
        continue;
      }
      if (entry.collisionProfile == null) {
        diagnostics.add(
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.warning,
            kind: EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
            presetId: preset.id,
            elementId: item.elementId,
            message:
                'Environment preset "${preset.id}" forces collision for element "${item.elementId}", but this element has no collision profile.',
          ),
        );
      }
    }

    if (knownTemplateIds.isNotEmpty &&
        !knownTemplateIds.contains(preset.templateId)) {
      diagnostics.add(
        EnvironmentPresetDiagnostic(
          severity: EnvironmentPresetDiagnosticSeverity.warning,
          kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
          presetId: preset.id,
          templateId: preset.templateId,
          message:
              'Environment preset "${preset.id}" uses unknown template "${preset.templateId}".',
        ),
      );
    }
  }

  return EnvironmentPresetDiagnosticsReport(diagnostics: diagnostics);
}

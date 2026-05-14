import '../models/project_manifest.dart';

enum ShadowAuthoringDiagnosticKind {
  missingShadowProfile,
}

final class ShadowAuthoringDiagnostic {
  const ShadowAuthoringDiagnostic({
    required this.kind,
    required this.elementId,
    required this.shadowProfileId,
    required this.message,
  });

  final ShadowAuthoringDiagnosticKind kind;
  final String elementId;
  final String shadowProfileId;
  final String message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ShadowAuthoringDiagnostic &&
            kind == other.kind &&
            elementId == other.elementId &&
            shadowProfileId == other.shadowProfileId &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        elementId,
        shadowProfileId,
        message,
      );
}

/// Diagnoses element shadow profile references for authoring tools.
///
/// This is intentionally not a shadow resolver: it does not merge profile
/// fields, inspect map instances, or produce runtime render instructions.
List<ShadowAuthoringDiagnostic> diagnoseProjectShadowAuthoring(
  ProjectManifest manifest,
) {
  final diagnostics = <ShadowAuthoringDiagnostic>[];
  final catalog = manifest.shadowCatalog;

  for (final element in manifest.elements) {
    final shadow = element.shadow;
    if (shadow == null || !shadow.castsShadow) {
      continue;
    }

    final shadowProfileId = shadow.shadowProfileId;
    if (shadowProfileId == null) {
      continue;
    }

    if (catalog.profileById(shadowProfileId) != null) {
      continue;
    }

    diagnostics.add(
      ShadowAuthoringDiagnostic(
        kind: ShadowAuthoringDiagnosticKind.missingShadowProfile,
        elementId: element.id,
        shadowProfileId: shadowProfileId,
        message:
            'Element "${element.id}" references missing shadow profile "$shadowProfileId".',
      ),
    );
  }

  return List<ShadowAuthoringDiagnostic>.unmodifiable(diagnostics);
}

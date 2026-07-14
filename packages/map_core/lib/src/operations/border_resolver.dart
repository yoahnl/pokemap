import '../models/border_diagnostics.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import 'organic_edge_border_resolver.dart';

/// Current deterministic Border resolver contract used by editor/runtime
/// freshness checks.
const int borderResolverVersion = 1;

/// Dispatches a Border request to the closed V1 template solver set.
///
/// The two line templates remain deliberately unavailable until their
/// specialized canonical stroke solvers are installed. No fallback silently
/// treats a line as an organic region.
BorderResolutionResult resolveBorderFeature(BorderResolutionRequest request) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    return _unsupported(
      request,
      code: 'border.resolution.blueprint_unavailable',
      action: 'border.action.publish_blueprint',
    );
  }
  return switch (revision.definition.template) {
    BorderBlueprintTemplate.organicEdge => resolveOrganicEdgeBorder(request),
    BorderBlueprintTemplate.masonryLine ||
    BorderBlueprintTemplate.postAndRailLine =>
      _unsupported(
        request,
        code: 'border.resolution.template_solver_unavailable',
        action: 'border.action.wait_for_line_solver',
      ),
  };
}

/// Validates an editor proposal against a fresh canonical re-resolution.
///
/// Fingerprints alone cannot prove the provenance of hashed slot keys or
/// native sprite geometry. Apply therefore uses exact result equality in V1.
BorderDiagnosticsReport validateBorderResolutionResultForRequest({
  required BorderResolutionRequest request,
  required BorderResolutionResult proposedResult,
}) {
  final canonical = resolveBorderFeature(request);
  if (canonical == proposedResult) {
    return const BorderDiagnosticsReport.empty();
  }
  return BorderDiagnosticsReport(
    diagnostics: <BorderDiagnostic>[
      BorderDiagnostic(
        code: 'border.resolution.proposal_not_canonical',
        severity: BorderDiagnosticSeverity.error,
        phase: BorderDiagnosticPhase.materialization,
        scope: BorderDiagnosticScope.materialization,
        blueprintId: request.blueprintId,
        featureId: request.feature.id,
        suggestedAction: 'border.action.resolve_preview_again',
      ),
    ],
  );
}

BorderResolutionResult _unsupported(
  BorderResolutionRequest request, {
  required String code,
  required String action,
}) =>
    BorderResolutionResult(
      materialization: null,
      diagnosticReport: BorderDiagnosticsReport(
        diagnostics: <BorderDiagnostic>[
          BorderDiagnostic(
            code: code,
            severity: BorderDiagnosticSeverity.error,
            phase: BorderDiagnosticPhase.resolution,
            scope: BorderDiagnosticScope.blueprint,
            blueprintId: request.blueprintId,
            featureId: request.feature.id,
            parameters: <String, Object?>{
              if (request.blueprintRevision != null)
                'template': request.blueprintRevision!.definition.template.name,
            },
            suggestedAction: action,
          ),
        ],
      ),
    );

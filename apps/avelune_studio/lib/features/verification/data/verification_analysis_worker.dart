import 'dart:isolate';

import 'package:map_core/map_core_domain.dart';
import 'package:map_gameplay/map_gameplay.dart'
    show
        NarrativePhysicalIssueCode,
        NarrativePhysicalReachabilityReport,
        NarrativePhysicalReachabilityVerdict,
        validateNarrativePhysicalReachability;

import '../domain/verification_port.dart';

const verificationWorkerName = 'avelune-verification';

class VerificationAnalysisRequest {
  const VerificationAnalysisRequest(this.reply, this.project, this.maps);
  final SendPort reply;
  final ProjectManifest project;
  final List<MapData> maps;
}

/// Runs the canonical validators in the spawned isolate. The interface isolate
/// only receives the finished result.
void verificationAnalysisWorker(VerificationAnalysisRequest request) {
  try {
    final validation = validateNarrativeProject(
      request.project,
      maps: request.maps,
    );
    final symbolic = validation.symbolicReachability;
    final physical = symbolic == null
        ? NarrativeValidationDimensionResult(
            status: NarrativeValidationStatus.notRun,
            limitations: const [
              'La preuve symbolique manque : aucune exploration physique n’a '
                  'été tentée.',
            ],
          )
        : _physical(
            validateNarrativePhysicalReachability(
              project: request.project,
              maps: request.maps,
              narrativeReport: symbolic,
            ),
          );
    request.reply.send(
      VerificationAnalysis(
        validation: validation,
        dependencies: buildNarrativeDependencyIndex(
          project: request.project,
          maps: request.maps,
        ),
        physical: physical,
        isolateName: Isolate.current.debugName ?? verificationWorkerName,
      ),
    );
  } on Object catch (failure) {
    request.reply.send(failure.toString());
  }
}

NarrativeValidationDimensionResult _physical(
  NarrativePhysicalReachabilityReport report,
) => NarrativeValidationDimensionResult(
  status: switch (report.verdict) {
    NarrativePhysicalReachabilityVerdict.pass => NarrativeValidationStatus.pass,
    NarrativePhysicalReachabilityVerdict.fail => NarrativeValidationStatus.fail,
    NarrativePhysicalReachabilityVerdict.indeterminate =>
      NarrativeValidationStatus.indeterminate,
  },
  diagnostics: [
    for (final issue in report.issues)
      NarrativeMultidimensionalDiagnostic(
        id:
            'physical:${issue.code.name}:${issue.eventId ?? ''}'
            ':${issue.mapId ?? ''}',
        code: issue.code.name,
        severity: issue.code == NarrativePhysicalIssueCode.permanentlyBlocked
            ? 'error'
            : 'warning',
        message: issue.message,
        path: issue.mapId == null ? 'maps' : 'maps.${issue.mapId}',
      ),
  ],
);

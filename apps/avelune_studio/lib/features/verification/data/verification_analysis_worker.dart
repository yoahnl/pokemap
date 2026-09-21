import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart'
    show DialogueAuthoringCompiler, NarrativeAuthoringDiagnosticSeverity;
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
  const VerificationAnalysisRequest(
    this.reply,
    this.project,
    this.maps,
    this.sources,
  );
  final SendPort reply;
  final ProjectManifest project;
  final List<MapData> maps;
  final List<VerificationDialogueSource> sources;
}

/// Runs the canonical validators in the spawned isolate. The interface isolate
/// only receives the finished result.
void verificationAnalysisWorker(VerificationAnalysisRequest request) {
  try {
    final canonical = validateNarrativeProject(
      request.project,
      maps: request.maps,
    );
    final validation = _withDialogueSources(canonical, request.sources);
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

/// Compiles the captured Yarn sources with the authoring compiler the dialogue
/// editor already uses, and folds its verdicts into the canonical report. No
/// second set of rules, and a diagnostic the validator already produced is
/// never shown twice.
NarrativeProjectValidationReport _withDialogueSources(
  NarrativeProjectValidationReport canonical,
  List<VerificationDialogueSource> sources,
) {
  const compiler = DialogueAuthoringCompiler();
  final known = {for (final item in canonical.diagnostics) item.stableKey};
  final added = <NarrativeProjectDiagnostic>[];
  for (final source in sources) {
    if (!source.readable) continue;
    final result = compiler.compile(entry: source.entry, source: source.text);
    for (final diagnostic in result.diagnostics) {
      final item = NarrativeProjectDiagnostic(
        code: diagnostic.code,
        severity:
            diagnostic.severity == NarrativeAuthoringDiagnosticSeverity.error
            ? NarrativeProjectDiagnosticSeverity.error
            : NarrativeProjectDiagnosticSeverity.warning,
        domain: NarrativeProjectDiagnosticDomain.dialogue,
        message: diagnostic.line == null
            ? diagnostic.message
            : '${diagnostic.message} (ligne ${diagnostic.line})',
        path: diagnostic.path ?? 'dialogues.${source.entry.id}',
        destination: NarrativeProjectDiagnosticDestination.dialogue,
        dialogueId: source.entry.id,
      );
      if (known.add(item.stableKey)) added.add(item);
    }
  }
  if (added.isEmpty) return canonical;
  return NarrativeProjectValidationReport(
    diagnostics: [...canonical.diagnostics, ...added],
    mapEventViews: canonical.mapEventViews,
    symbolicReachability: canonical.symbolicReachability,
  );
}

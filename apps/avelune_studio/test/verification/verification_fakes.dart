import 'dart:async';

import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:map_core/map_core_domain.dart';

NarrativeProjectDiagnostic verificationDiagnostic(
  String code,
  NarrativeProjectDiagnosticDestination destination, {
  NarrativeProjectDiagnosticSeverity severity =
      NarrativeProjectDiagnosticSeverity.error,
  String? eventId,
  String? stepId,
  String? factId,
  String? worldRuleId,
  String? mapId,
}) => NarrativeProjectDiagnostic(
  code: code,
  severity: severity,
  domain: NarrativeProjectDiagnosticDomain.storyline,
  message: 'Problème $code',
  path: code,
  destination: destination,
  eventId: eventId,
  stepId: stepId,
  factId: factId,
  worldRuleId: worldRuleId,
  mapId: mapId,
);

final class FakeVerificationPort implements VerificationPort {
  FakeVerificationPort({this.diagnostics = const [], this.maps = const []});

  List<NarrativeProjectDiagnostic> diagnostics;
  List<MapData> maps;
  Completer<VerificationAnalysis>? gate;
  var analyses = 0;
  var cancels = 0;
  final dialogueReads = <List<String>>[];

  @override
  Future<List<VerificationMapSource>> readMaps({
    void Function(int loaded, int total)? progress,
  }) async {
    for (var index = 0; index < maps.length; index++) {
      progress?.call(index + 1, maps.length);
    }
    return [
      for (final map in maps)
        VerificationMapSource(
          entry: ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
          bytes: const [],
        ),
    ];
  }

  @override
  Future<String> projectRevision() async => 'r1';

  @override
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile? profile,
  ) async => const VerificationRuntimeEvidence(
    state: VerificationRuntimeState.unconfigured,
    reason: 'none',
  );

  @override
  Future<List<VerificationDialogueSource>> readDialogueSources(
    List<ProjectDialogueEntry> entries,
  ) async {
    dialogueReads.add([for (final entry in entries) entry.id]);
    return const [];
  }

  @override
  VerificationJob analyse({
    required ProjectManifest project,
    required List<VerificationMapSource> maps,
    required List<VerificationDialogueSource> sources,
  }) {
    analyses++;
    final completer = gate ?? Completer<VerificationAnalysis>();
    if (gate == null) {
      completer.complete(
        VerificationAnalysis(
          validation: NarrativeProjectValidationReport(
            diagnostics: diagnostics,
            mapEventViews: const [],
          ),
          dependencies: buildNarrativeDependencyIndex(
            project: project,
            maps: this.maps,
          ),
          physical: NarrativeValidationDimensionResult(
            status: NarrativeValidationStatus.pass,
          ),
          isolateName: 'fake',
        ),
      );
    }
    return VerificationJob(result: completer.future, cancel: () => cancels++);
  }
}

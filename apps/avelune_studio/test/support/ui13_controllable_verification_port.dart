import 'dart:async';

import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:map_core/map_core_domain.dart';

/// An executor a test drives by hand: it never computes, it answers when the
/// test says so, and it records what was cancelled.
class Ui13ControllableVerificationPort implements VerificationPort {
  Ui13ControllableVerificationPort({
    required this.revision,
    required this.maps,
    required this.evidence,
    this.sources = const [],
  });

  String revision;
  List<MapData> maps;
  VerificationRuntimeEvidence evidence;
  List<VerificationDialogueSource> sources;

  /// Runs once before the maps are answered, so a test can publish while the
  /// preparation is in flight.
  Future<void> Function()? beforeMaps;

  /// When true, each runtime proof read waits for its own release, so a test
  /// can hold one request's last read open while another one finishes.
  bool holdEvidence = false;
  final evidenceCalls = <Completer<VerificationRuntimeEvidence>>[];
  final started = <Completer<VerificationAnalysis>>[];
  final cancelled = <int>[];
  Object? readFailure;

  int get analyses => started.length;

  @override
  Future<String> projectRevision() async {
    if (readFailure case final failure?) throw failure;
    return revision;
  }

  @override
  Future<List<MapData>> loadMaps() async {
    await beforeMaps?.call();
    return maps;
  }

  @override
  Future<List<VerificationDialogueSource>> readDialogueSources(
    List<ProjectDialogueEntry> entries,
  ) async => [
    for (final entry in entries)
      sources.firstWhere(
        (item) => item.entry.id == entry.id,
        orElse: () => VerificationDialogueSource(
          entry: entry,
          text: '',
          origin: 'version enregistrée',
        ),
      ),
  ];

  @override
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile profile,
  ) {
    if (!holdEvidence) return Future.value(evidence);
    final gate = Completer<VerificationRuntimeEvidence>();
    evidenceCalls.add(gate);
    return gate.future;
  }

  /// Answers the runtime proof read at [index], or makes it fail.
  void releaseEvidence(
    int index, {
    VerificationRuntimeEvidence? value,
    Object? failure,
  }) {
    final gate = evidenceCalls[index];
    if (gate.isCompleted) return;
    if (failure != null) {
      gate.completeError(failure);
      return;
    }
    gate.complete(value ?? evidence);
  }

  @override
  VerificationJob analyse({
    required ProjectManifest project,
    required List<MapData> maps,
    required List<VerificationDialogueSource> sources,
  }) {
    final completer = Completer<VerificationAnalysis>();
    final index = started.length;
    started.add(completer);
    return VerificationJob(
      result: completer.future,
      cancel: () {
        cancelled.add(index);
        if (!completer.isCompleted) {
          completer.completeError(
            const VerificationFailure('Contrôle abandonné.'),
          );
        }
      },
    );
  }

  /// Answers the job at [index] as a finished analysis would.
  void complete(
    int index, {
    required ProjectManifest project,
    required List<MapData> maps,
    String isolateName = 'faux-executeur',
  }) {
    final completer = started[index];
    if (completer.isCompleted) return;
    completer.complete(
      VerificationAnalysis(
        validation: validateNarrativeProject(project, maps: maps),
        dependencies: buildNarrativeDependencyIndex(
          project: project,
          maps: maps,
        ),
        physical: NarrativeValidationDimensionResult(
          status: NarrativeValidationStatus.notRun,
          limitations: const ['Exécuteur de test.'],
        ),
        isolateName: isolateName,
      ),
    );
  }
}

import 'package:map_core/map_core_domain.dart';

import '../domain/verification_port.dart';
import 'verification_problems.dart';

enum VerificationFreshness { current, stale, unconfirmed }

final class VerificationSnapshot {
  VerificationSnapshot({
    required this.revision,
    required this.revisionAfterAnalysis,
    required this.elapsed,
    required ProjectManifest project,
    required VerificationAnalysis analysis,
    required List<VerificationDialogueSource> sources,
    this.inputRevisions = const [],
    this.inputsMatchedAfterAnalysis = true,
  }) : symbolic = analysis.validation.symbolicReachability?.verdict,
       physical = analysis.physical.status,
       physicalLimitations = analysis.physical.limitations,
       unreadableDialogues = List.unmodifiable(
         _missingDialogues(project.dialogues, sources),
       ),
       problems = List.unmodifiable(
         verificationProblems(analysis.validation, analysis.physical, project),
       );

  final String revision;
  final String? revisionAfterAnalysis;
  final List<VerificationInputRevision> inputRevisions;
  final bool? inputsMatchedAfterAnalysis;
  final Duration elapsed;
  final NarrativeSymbolicVerdict? symbolic;
  final NarrativeValidationStatus physical;
  final List<String> physicalLimitations;
  final List<ProjectDialogueEntry> unreadableDialogues;
  final List<VerificationProblem> problems;

  late final errors = problems
      .where((problem) => problem.severity == VerificationProblemSeverity.error)
      .length;
  late final warnings = problems
      .where(
        (problem) => problem.severity == VerificationProblemSeverity.warning,
      )
      .length;
  late final unreadableMapCount = problems
      .where((problem) => problem.code == verificationUnreadableMap)
      .length;

  bool get complete =>
      symbolic != null &&
      symbolic != NarrativeSymbolicVerdict.indeterminate &&
      (physical == NarrativeValidationStatus.pass ||
          physical == NarrativeValidationStatus.fail) &&
      unreadableDialogues.isEmpty &&
      unreadableMapCount == 0;

  bool get clean =>
      complete &&
      problems.isEmpty &&
      symbolic == NarrativeSymbolicVerdict.pass &&
      physical == NarrativeValidationStatus.pass;

  VerificationFreshness freshness(
    String? latestRevision, {
    bool? inputsMatch = true,
  }) {
    if ((revisionAfterAnalysis != null && revision != revisionAfterAnalysis) ||
        (latestRevision != null && revision != latestRevision) ||
        inputsMatchedAfterAnalysis == false ||
        inputsMatch == false) {
      return VerificationFreshness.stale;
    }
    if (revisionAfterAnalysis == null ||
        latestRevision == null ||
        inputsMatchedAfterAnalysis == null ||
        inputsMatch == null) {
      return VerificationFreshness.unconfirmed;
    }
    return VerificationFreshness.current;
  }
}

Iterable<ProjectDialogueEntry> _missingDialogues(
  List<ProjectDialogueEntry> entries,
  List<VerificationDialogueSource> sources,
) {
  final read = {
    for (final source in sources)
      if (source.readable) source.entry.id,
  };
  return entries.where((entry) => !read.contains(entry.id));
}

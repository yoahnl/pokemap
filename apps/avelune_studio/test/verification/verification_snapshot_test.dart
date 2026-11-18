import 'package:avelune_studio/features/verification/application/verification_snapshot.dart';
import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'verification_fakes.dart';

const _project = ProjectManifest(name: 'Vérification', maps: [], tilesets: []);
const _dialogue = ProjectDialogueEntry(
  id: 'letter',
  name: 'Lettre',
  relativePath: 'dialogues/letter.yarn',
);

VerificationSnapshot _snapshot({
  String? after = 'r1',
  NarrativeSymbolicVerdict? symbolic = NarrativeSymbolicVerdict.pass,
  NarrativeValidationStatus physical = NarrativeValidationStatus.pass,
  List<NarrativeProjectDiagnostic> diagnostics = const [],
  List<ProjectDialogueEntry> entries = const [],
  List<VerificationDialogueSource> sources = const [],
}) {
  final project = _project.copyWith(dialogues: entries);
  return VerificationSnapshot(
    revision: 'r1',
    revisionAfterAnalysis: after,
    elapsed: const Duration(milliseconds: 15),
    project: project,
    sources: sources,
    analysis: VerificationAnalysis(
      validation: NarrativeProjectValidationReport(
        diagnostics: diagnostics,
        mapEventViews: const [],
        symbolicReachability: symbolic == null
            ? null
            : NarrativeSymbolicReachabilityReport(
                verdict: symbolic,
                terminalStates: const [],
                exploredStates: const [],
                issues: const [],
                reachableSceneIds: const {},
                exploredStateCount: 0,
              ),
      ),
      dependencies: buildNarrativeDependencyIndex(project: project, maps: []),
      physical: NarrativeValidationDimensionResult(status: physical),
      isolateName: 'test',
    ),
  );
}

void main() {
  test('freshness requires the saved revision before and after the run', () {
    final result = _snapshot();

    expect(result.freshness('r1'), VerificationFreshness.current);
    expect(result.freshness('r2'), VerificationFreshness.stale);
    expect(result.freshness(null), VerificationFreshness.unconfirmed);
    expect(
      _snapshot(after: null).freshness('r1'),
      VerificationFreshness.unconfirmed,
    );
    expect(_snapshot(after: 'r2').freshness('r1'), VerificationFreshness.stale);
  });

  test('empty diagnostics are clean only with verified passing dimensions', () {
    expect(_snapshot().clean, isTrue);
    expect(_snapshot(symbolic: null).complete, isFalse);
    expect(
      _snapshot(symbolic: NarrativeSymbolicVerdict.indeterminate).clean,
      isFalse,
    );
    expect(
      _snapshot(physical: NarrativeValidationStatus.notRun).clean,
      isFalse,
    );
    final failed = _snapshot(physical: NarrativeValidationStatus.fail);
    expect(failed.complete, isTrue);
    expect(failed.clean, isFalse);
  });

  test('an omitted or unreadable source leaves the report partial', () {
    const source = VerificationDialogueSource(
      entry: _dialogue,
      text: '',
      origin: 'saved',
    );
    const unreadable = VerificationDialogueSource(
      entry: _dialogue,
      text: '',
      origin: 'saved',
      problem: 'absent',
    );
    final omitted = _snapshot(entries: [_dialogue]);
    final failed = _snapshot(entries: [_dialogue], sources: [unreadable]);
    final read = _snapshot(entries: [_dialogue], sources: [source]);

    expect(omitted.unreadableDialogues, [_dialogue]);
    expect(failed.unreadableDialogues, [_dialogue]);
    expect(omitted.clean, isFalse);
    expect(failed.complete, isFalse);
    expect(read.complete, isTrue);
  });

  test('an unreadable map stays an error and makes the result partial', () {
    final result = _snapshot(
      diagnostics: [
        verificationDiagnostic(
          verificationUnreadableMap,
          NarrativeProjectDiagnosticDestination.map,
          mapId: 'annexe',
        ),
      ],
    );
    expect(result.errors, 1);
    expect(result.complete, isFalse);
    expect(result.problems.single.mapId, 'annexe');
  });
}

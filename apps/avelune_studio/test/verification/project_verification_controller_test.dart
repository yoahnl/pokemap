import 'dart:async';

import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/verification/application/verification_problems.dart';
import 'package:avelune_studio/features/verification/application/verification_snapshot.dart';
import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'verification_fakes.dart';

const _project = ProjectManifest(
  name: 'Vérif',
  maps: [],
  tilesets: [],
  dialogues: [
    ProjectDialogueEntry(
      id: 'hello',
      name: 'Bonjour',
      relativePath: 'dialogues/hello.yarn',
    ),
  ],
);

MapData _map(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 2, height: 2),
  layers: const [],
);

void main() {
  late FakeVerificationPort port;
  late ProjectVerificationController verification;
  late List<ProjectVerificationPhase> phases;

  setUp(() {
    port = FakeVerificationPort(
      maps: [_map('a'), _map('b')],
      diagnostics: [
        verificationDiagnostic(
          'warn',
          NarrativeProjectDiagnosticDestination.fact,
          severity: NarrativeProjectDiagnosticSeverity.warning,
          factId: 'met',
        ),
        verificationDiagnostic(
          'blocker',
          NarrativeProjectDiagnosticDestination.storyline,
          stepId: 'meet',
        ),
      ],
    )..savedProject = _project;
    phases = [];
    verification = ProjectVerificationController(
      port: port,
      changed: () => phases.add(verification.phase),
    );
  });

  test('nothing runs until asked, then every phase reports progress', () async {
    expect(verification.phase, ProjectVerificationPhase.idle);
    expect(port.analyses, 0);

    await verification.start();

    expect(phases.toSet(), {
      ProjectVerificationPhase.project,
      ProjectVerificationPhase.maps,
      ProjectVerificationPhase.dialogues,
      ProjectVerificationPhase.analysis,
      ProjectVerificationPhase.done,
    });
    expect((verification.mapsLoaded, verification.mapsTotal), (2, 2));
    expect(port.dialogueReads, [
      ['hello'],
    ]);
    expect(verification.problems.map((problem) => problem.code), [
      'blocker',
      'warn',
    ]);
    expect(
      verification.problems.first.severity,
      VerificationProblemSeverity.error,
    );
    expect(verification.problems.first.stepId, 'meet');
    expect(verification.elapsed, isNotNull);
    expect(port.revisionReads, 2);
  });

  test('cancelling stops the job and ignores its late result', () async {
    port.gate = Completer<VerificationAnalysis>();
    final running = verification.start();
    await Future<void>.delayed(Duration.zero);
    expect(verification.phase, ProjectVerificationPhase.analysis);

    verification.cancel();
    expect(port.cancels, 1);
    expect(verification.phase, ProjectVerificationPhase.cancelled);
    port.gate!.completeError(const VerificationFailure('Contrôle abandonné.'));
    await running;

    expect(verification.phase, ProjectVerificationPhase.cancelled);
    expect(verification.problems, isEmpty);
    expect(verification.snapshot, isNull);
  });

  test(
    'a saved change after analysis stales the report without rerunning',
    () async {
      await verification.start();
      expect(verification.freshness, VerificationFreshness.current);
      port.revision = 'r2';

      await verification.refreshRevision();

      expect(verification.snapshot!.revision, 'r1');
      expect(verification.freshness, VerificationFreshness.stale);
      expect(port.analyses, 1);
      await verification.start();
      expect(verification.snapshot!.revision, 'r2');
      expect(verification.freshness, VerificationFreshness.current);
      expect(port.analyses, 2);
    },
  );

  test('a saved change during analysis never certifies that run', () async {
    port.gate = Completer<VerificationAnalysis>();
    final running = verification.start();
    await Future<void>.delayed(Duration.zero);
    expect(verification.phase, ProjectVerificationPhase.analysis);
    port.revision = 'r2';
    port.gate!.complete(
      VerificationAnalysis(
        validation: NarrativeProjectValidationReport(
          diagnostics: const [],
          mapEventViews: const [],
        ),
        dependencies: buildNarrativeDependencyIndex(
          project: _project,
          maps: [],
        ),
        physical: NarrativeValidationDimensionResult(
          status: NarrativeValidationStatus.pass,
        ),
        isolateName: 'test',
      ),
    );
    await running;

    expect(verification.snapshot!.revision, 'r1');
    expect(verification.freshness, VerificationFreshness.stale);
    port.revision = 'r1';
    await verification.refreshRevision();
    expect(verification.freshness, VerificationFreshness.stale);
  });

  test('an unreadable revision removes any claim of freshness', () async {
    await verification.start();
    port.revisionFailure = StateError('révision illisible');
    await verification.refreshRevision();

    expect(verification.freshness, VerificationFreshness.unconfirmed);
    expect(port.analyses, 1);
  });

  test(
    'an uncertain input observed during analysis cannot certify it later',
    () async {
      port.inputMatch = null;
      await verification.start();
      expect(verification.freshness, VerificationFreshness.unconfirmed);
      port.inputMatch = true;
      await verification.refreshRevision();
      expect(verification.freshness, VerificationFreshness.unconfirmed);
      expect(port.analyses, 1);
    },
  );

  test('a save notification checks only the project revision', () async {
    await verification.start();
    final checks = port.inputChecks;
    port.revision = 'r2';

    await verification.refreshRevision(checkInputs: false);

    expect(verification.freshness, VerificationFreshness.stale);
    expect(port.inputChecks, checks);
    expect(port.analyses, 1);
  });

  test('a failure is stated with its cause', () async {
    port.projectFailure = StateError('catalogue illisible');

    await verification.start();

    expect(verification.phase, ProjectVerificationPhase.failed);
    expect('${verification.failure}', contains('catalogue illisible'));
    expect(port.analyses, 0);
  });
}

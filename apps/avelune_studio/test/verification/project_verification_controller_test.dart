import 'dart:async';

import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/verification/application/verification_problems.dart';
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
    );
    phases = [];
    verification = ProjectVerificationController(
      port: port,
      loadProject: () async => _project,
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
  });

  test('a failure is stated with its cause', () async {
    verification = ProjectVerificationController(
      port: port,
      loadProject: () async => throw StateError('catalogue illisible'),
      changed: () {},
    );

    await verification.start();

    expect(verification.phase, ProjectVerificationPhase.failed);
    expect('${verification.failure}', contains('catalogue illisible'));
    expect(port.analyses, 0);
  });
}

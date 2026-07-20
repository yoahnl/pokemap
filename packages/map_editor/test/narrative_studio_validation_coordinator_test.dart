import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_studio_validation_coordinator.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';

void main() {
  test('keeps four dimensions independent and refuses absent smoke', () {
    final symbolic = NarrativeSymbolicReachabilityReport(
      verdict: NarrativeSymbolicVerdict.pass,
      terminalStates: [NarrativeSymbolicState()],
      exploredStates: [NarrativeSymbolicState()],
      issues: const [],
      reachableSceneIds: const {},
      exploredStateCount: 1,
    );
    const project = ProjectManifest(
      name: 'Coordinator',
      maps: [],
      tilesets: [],
      newGame: ProjectNewGameConfig(
          enabled: true, startMapId: 'start', startSpawnId: 'spawn'),
    );
    final report = const NarrativeStudioValidationCoordinator().coordinate(
      project: project,
      maps: const [],
      projectReport: NarrativeProjectValidationReport(
        diagnostics: const [],
        mapEventViews: const [],
        symbolicReachability: symbolic,
      ),
      projectFingerprint: 'sha256:${'e' * 64}',
      profile: selbrumeReleaseV1Profile,
      runtimeReceipt: const NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.absent,
        reason: 'absent',
      ),
      generatedAt: DateTime.utc(2026),
    );

    expect(report.structurallyValid.status, NarrativeValidationStatus.pass);
    expect(report.narrativelySolvable.status, NarrativeValidationStatus.pass);
    expect(report.physicallyReachable.status, NarrativeValidationStatus.pass);
    expect(
        report.runtimeSmokeVerified.status, NarrativeValidationStatus.notRun);
    expect(report.isPlayable, isFalse);
  });
}

import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart';

/// Runs the real reads of [VerificationPort] where a widget test can await
/// them, and counts them so a test can prove that nothing runs on its own.
class Ui13WidgetVerificationPort implements VerificationPort {
  Ui13WidgetVerificationPort(this.delegate, this.tester);
  final VerificationPort delegate;
  final WidgetTester tester;
  int runs = 0;

  Future<T> _run<T>(Future<T> Function() action) async =>
      (await WidgetResourcePort.serial(tester, action)) as T;

  @override
  Future<String> projectRevision() {
    runs++;
    return _run(delegate.projectRevision);
  }

  @override
  Future<List<MapData>> loadMaps() => _run(delegate.loadMaps);

  @override
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile profile,
  ) => _run(() => delegate.readRuntimeEvidence(profile));

  @override
  Future<NarrativeValidationDimensionResult> physicalReachability({
    required ProjectManifest project,
    required List<MapData> maps,
    required NarrativeSymbolicReachabilityReport? symbolic,
  }) => _run(
    () => delegate.physicalReachability(
      project: project,
      maps: maps,
      symbolic: symbolic,
    ),
  );
}

import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart';

/// Runs the real reads and the real analysis of [VerificationPort] where a
/// widget test can await them, and counts them so a test can prove that
/// nothing runs on its own.
class Ui13WidgetVerificationPort implements VerificationPort {
  Ui13WidgetVerificationPort(this.delegate, this.tester);
  final VerificationPort delegate;
  final WidgetTester tester;
  int runs = 0;
  int analyses = 0;
  int sourceReads = 0;

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
  Future<List<VerificationDialogueSource>> readDialogueSources(
    List<ProjectDialogueEntry> entries,
  ) {
    sourceReads++;
    return _run(() => delegate.readDialogueSources(entries));
  }

  @override
  VerificationJob analyse({
    required ProjectManifest project,
    required List<MapData> maps,
    required List<VerificationDialogueSource> sources,
  }) {
    analyses++;
    VerificationJob? inner;
    var cancelled = false;
    final result = _run(() async {
      inner = delegate.analyse(project: project, maps: maps, sources: sources);
      if (cancelled) {
        inner!.cancel();
        throw const VerificationFailure('Contrôle abandonné.');
      }
      return inner!.result;
    });
    return VerificationJob(
      result: result,
      cancel: () {
        cancelled = true;
        inner?.cancel();
      },
    );
  }
}

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/features/narrative/state/narrative_validator_providers.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  test('canonical Selbrume separates structural pass from bounded solvability',
      () async {
    final projectRoot = p.normalize(
      p.join(Directory.current.path, '..', '..', 'selbrume'),
    );
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(projectRoot, 'project.json'),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot,
      project: session.manifest,
    );
    final report = await container.read(
      narrativeValidatorReportProvider(request).future,
    );
    final structuralCriticalDiagnostics = report.diagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity == NarrativeProjectDiagnosticSeverity.error &&
              !diagnostic.code.startsWith('narrative'),
        )
        .toList(growable: false);

    final canonicalEventCount = session.manifest.eventRegistry?.records.length;
    expect(canonicalEventCount, greaterThanOrEqualTo(27));
    expect(report.totalEventCount, canonicalEventCount);
    expect(
      report.mapEventViews
          .where((view) => view.groupKind == NarrativeMapEventsGroupKind.map),
      hasLength(session.manifest.maps.length),
    );
    expect(
      structuralCriticalDiagnostics,
      isEmpty,
      reason: structuralCriticalDiagnostics
          .map(
            (diagnostic) =>
                '${diagnostic.code} · ${diagnostic.path} · ${diagnostic.message}',
          )
          .join('\n'),
    );
    expect(
      report.narrativelySolvable,
      NarrativeSymbolicVerdict.indeterminate,
      reason:
          'Le budget borné doit rester visible, jamais devenir un faux pass.',
    );

    const receipts = NarrativeRuntimeSmokeReceiptRepository();
    final fingerprint = await receipts.computeProjectFingerprint(projectRoot);
    final runtimeReceipt = await receipts.read(
      projectRoot: projectRoot,
      expectedFingerprint: fingerprint,
      profile: selbrumeReleaseV1Profile,
    );
    expect(runtimeReceipt.state, NarrativeRuntimeReceiptState.freshPass);
    expect(runtimeReceipt.receipt?.projectFingerprint, fingerprint);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

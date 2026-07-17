import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

const _validId = 'evt_019abcde-0000-7000-8000-000000000005';

void main() {
  group('I1 Event V2 integrity validation', () {
    test('is deterministic and exposes typed repair destinations', () {
      final records = <NarrativeEventRecord>[
        draftRecord(id: eventIdA),
        configuredRecord(
          id: eventIdB,
          source: NarrativeEventSourceRef.triggerEnter('map_a', 'zone_bad'),
        ),
        configuredRecord(id: eventIdC, sceneId: 'scene_missing'),
        configuredRecord(id: _validId),
      ];
      final registry = registryWithRecords(
        records,
        claims: [
          authoringClaim(targetEventIds: [eventIdD])
        ],
      );
      final catalogDiagnostics = <NarrativeEventProjectDiagnostic>[
        NarrativeEventProjectDiagnostic(
          code: 'narrativeEventSourceUnavailable',
          severity: NarrativeEventProjectDiagnosticSeverity.error,
          message: 'La source ne correspond plus à un déclencheur utilisable.',
          path: 'eventRegistry.records.$eventIdB.source',
        ),
        NarrativeEventProjectDiagnostic(
          code: 'narrativeEventSceneMissing',
          severity: NarrativeEventProjectDiagnosticSeverity.error,
          message: 'La Scene sélectionnée est absente.',
          path: 'eventRegistry.records.$eventIdC.sceneId',
        ),
      ];

      NarrativeEventValidationReport build({required bool reversed}) {
        final orderedRecords = reversed ? records.reversed.toList() : records;
        final orderedDiagnostics = reversed
            ? catalogDiagnostics.reversed.toList()
            : catalogDiagnostics;
        final orderedRegistry = registryWithRecords(
          orderedRecords,
          claims: registry.legacyClaims,
        );
        return buildNarrativeEventValidationReport(
          registry: orderedRegistry,
          catalog: authoringCatalogForRegistry(
            orderedRegistry,
            diagnostics: orderedDiagnostics,
            invalidEventIds: {eventIdB, eventIdC},
          ),
        );
      }

      final report = build(reversed: false);
      expect(build(reversed: true).toDebugJson(), report.toDebugJson());
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'narrativeEventSourceMissing',
          'narrativeEventSourceUnavailable',
          'narrativeEventSceneMissing',
          'legacyClaimTargetEventAbsent',
        ]),
      );

      final sourceMissing = report.diagnostics.singleWhere(
        (diagnostic) =>
            diagnostic.code == 'narrativeEventSourceMissing' &&
            diagnostic.eventId == eventIdA,
      );
      expect(sourceMissing.severity, NarrativeEventValidationSeverity.error);
      expect(sourceMissing.action, NarrativeEventValidationAction.chooseSource);
      expect(
        sourceMissing.destination.kind,
        NarrativeEventValidationDestinationKind.eventSource,
      );
      expect(sourceMissing.destination.eventId, eventIdA);

      final sceneMissing = report.diagnostics.singleWhere(
        (diagnostic) => diagnostic.code == 'narrativeEventSceneMissing',
      );
      expect(sceneMissing.action, NarrativeEventValidationAction.chooseScene);
      expect(
        sceneMissing.destination.kind,
        NarrativeEventValidationDestinationKind.eventScene,
      );
      expect(sceneMissing.destination.eventId, eventIdC);

      final invalidClaim = report.diagnostics.singleWhere(
        (diagnostic) => diagnostic.code == 'legacyClaimTargetEventAbsent',
      );
      expect(invalidClaim.eventId, eventIdD);
      expect(invalidClaim.action, NarrativeEventValidationAction.reviewClaim);
      expect(
        invalidClaim.destination.kind,
        NarrativeEventValidationDestinationKind.claim,
      );
      expect(invalidClaim.destination.claimId,
          registry.legacyClaims.single.cohortId);

      expect(
        report.diagnostics.where(
          (diagnostic) => diagnostic.eventId == _validId,
        ),
        isEmpty,
      );
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.stableKey).toSet(),
        hasLength(report.diagnostics.length),
      );
    });

    test('keeps project diagnostics without an Event as registry destinations',
        () {
      final registry = registryWithRecords(const []);
      final report = buildNarrativeEventValidationReport(
        registry: registry,
        catalog: authoringCatalog(
          diagnostics: [
            NarrativeEventProjectDiagnostic(
              code: 'duplicateManifestMapId',
              severity: NarrativeEventProjectDiagnosticSeverity.warning,
              message: 'Deux maps partagent le même identifiant.',
              path: 'maps.map_a',
            ),
          ],
        ),
      );

      expect(report.errorCount, 0);
      expect(report.warningCount, 1);
      expect(
        report.diagnostics.single.destination.kind,
        NarrativeEventValidationDestinationKind.registry,
      );
      expect(report.diagnostics.single.eventId, isNull);
    });

    test('normalization keeps distinct conflict messages', () {
      NarrativeEventValidationDiagnostic conflict(String message) {
        return NarrativeEventValidationDiagnostic(
          code: 'legacyClaimGlobalConflict',
          severity: NarrativeEventValidationSeverity.error,
          path: 'eventRegistry.legacyClaims',
          message: message,
          action: NarrativeEventValidationAction.reviewRegistry,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.registry,
          ),
        );
      }

      final report = normalizeNarrativeEventValidationReport([
        conflict('Conflit A.'),
        conflict('Conflit B.'),
      ]);

      expect(report.diagnostics, hasLength(2));
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.message),
        ['Conflit A.', 'Conflit B.'],
      );
    });
  });
}

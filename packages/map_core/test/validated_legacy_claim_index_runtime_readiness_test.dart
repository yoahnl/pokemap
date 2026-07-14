import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _fingerprintA =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _fingerprintB =
    'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('ValidatedLegacyClaimIndex runtime readiness', () {
    test('empty registry is ready and resolves absent without null', () {
      final index = buildValidatedLegacyClaimIndex(_registry());
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');

      expect(index.canStartDualRead, isTrue);
      expect(index.canEnterDualRead, isTrue);
      expect(index.canRunDualRead, isTrue);
      expect(index.resolveSource(source), isA<LegacyClaimSourceAbsent>());
      expect(
        index.resolveProvenance(provenance),
        isA<LegacyClaimProvenanceAbsent>(),
      );
    });

    test('valid source and provenance resolve to the same cohort', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        _registry(
          records: [_configured(_eventA, source: source)],
          claims: [claim],
        ),
        runtimeEvidence: _evidence([
          _evidenceEntry(source: source, provenance: provenance),
        ]),
      );

      final sourceResolution = index.resolveSource(source);
      final provenanceResolution = index.resolveProvenance(provenance);

      expect(index.canStartDualRead, isTrue);
      expect(index.canEnterDualRead, isTrue);
      expect(index.canRunDualRead, isTrue);
      expect(sourceResolution, isA<LegacyClaimSourceValid>());
      expect(provenanceResolution, isA<LegacyClaimProvenanceValid>());
      expect(sourceResolution.claim, same(claim));
      expect(provenanceResolution.claim, same(claim));
      expect(sourceResolution.cohortId, claim.cohortId);
      expect(provenanceResolution.cohortId, claim.cohortId);
      expect(
        index.requireMatchingValidCohort(
          source: source,
          provenance: provenance,
        ),
        same(claim),
      );
    });

    test('local target failures become typed source and provenance tombstones',
        () {
      final cases = <({
        NarrativeEventRecord? record,
        LegacyClaimTombstoneDiagnosticCode code,
      })>[
        (
          record: null,
          code: LegacyClaimTombstoneDiagnosticCode.targetEventAbsent,
        ),
        (
          record: NarrativeEventRecord.draft(_draft(_eventA)),
          code: LegacyClaimTombstoneDiagnosticCode.targetEventDraft,
        ),
        (
          record: _configured(
            _eventA,
            source: NarrativeEventSourceRef.mapEnter('map_elsewhere'),
          ),
          code: LegacyClaimTombstoneDiagnosticCode.targetEventSourceMismatch,
        ),
      ];

      for (final testCase in cases) {
        final source = NarrativeEventSourceRef.mapEnter('map_port');
        final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
        final claim = _claim(
          source: source,
          provenance: provenance,
          targetIds: const [_eventA],
        );
        final index = buildRuntimeValidatedLegacyClaimIndex(
          _registry(
            records: [if (testCase.record != null) testCase.record!],
            claims: [claim],
          ),
          runtimeEvidence: _evidence([
            _evidenceEntry(source: source, provenance: provenance),
          ]),
        );

        final sourceResolution = index.resolveSource(source);
        final provenanceResolution = index.resolveProvenance(provenance);

        expect(index.canStartDualRead, isFalse);
        expect(index.canEnterDualRead, isFalse);
        expect(index.canRunDualRead, isTrue);
        expect(sourceResolution, isA<LegacyClaimSourceTombstone>());
        expect(provenanceResolution, isA<LegacyClaimProvenanceTombstone>());
        expect(sourceResolution.claim, same(claim));
        expect(provenanceResolution.claim, same(claim));
        expect(sourceResolution.cohortId, claim.cohortId);
        expect(provenanceResolution.cohortId, claim.cohortId);
        expect(sourceResolution.diagnostics.single.code, testCase.code);
        expect(provenanceResolution.diagnostics.single.code, testCase.code);
        expect(
          sourceResolution.diagnostics.single.targetEventId,
          _eventA,
        );
        expect(
          () => sourceResolution.diagnostics.add(
            sourceResolution.diagnostics.single,
          ),
          throwsUnsupportedError,
        );
      }
    });

    test('a local tombstone does not block another valid source', () {
      final tombstoneSource = NarrativeEventSourceRef.mapEnter('map_port');
      final validSource = NarrativeEventSourceRef.mapEnter('map_forest');
      final tombstoneClaim = _claim(
        source: tombstoneSource,
        provenance: LegacySourceRef.mapEvent('map_port', 'legacy'),
        targetIds: const [_eventA],
      );
      final validClaim = _claim(
        source: validSource,
        provenance: LegacySourceRef.mapEvent('map_forest', 'legacy'),
        targetIds: const [_eventB],
        sourceFingerprint: _fingerprintB,
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        _registry(
          records: [_configured(_eventB, source: validSource)],
          claims: [tombstoneClaim, validClaim],
        ),
        runtimeEvidence: _evidence([
          _evidenceEntry(
            source: tombstoneSource,
            provenance: tombstoneClaim.members.single.provenance,
          ),
          _evidenceEntry(
            source: validSource,
            provenance: validClaim.members.single.provenance,
            sourceFingerprint: _fingerprintB,
          ),
        ]),
      );

      expect(index.canEnterDualRead, isFalse);
      expect(index.canRunDualRead, isTrue);
      expect(
        index.resolveSource(tombstoneSource),
        isA<LegacyClaimSourceTombstone>(),
      );
      expect(index.resolveSource(validSource), isA<LegacyClaimSourceValid>());
    });

    test('global cohort source and provenance collisions block runtime', () {
      final sourceA = NarrativeEventSourceRef.mapEnter('map_a');
      final sourceB = NarrativeEventSourceRef.mapEnter('map_b');
      final provenanceA = LegacySourceRef.mapEvent('map_a', 'legacy_a');
      final provenanceB = LegacySourceRef.mapEvent('map_b', 'legacy_b');
      final claimA = _claim(
        source: sourceA,
        provenance: provenanceA,
        targetIds: const [_eventA],
      );
      final records = [
        _configured(_eventA, source: sourceA),
        _configured(_eventB, source: sourceB),
      ];
      final cases = [
        [claimA, claimA],
        [
          claimA,
          _claim(
            source: sourceA,
            provenance: provenanceB,
            targetIds: const [_eventB],
            sourceFingerprint: _fingerprintB,
          ),
        ],
        [
          claimA,
          _claim(
            source: sourceB,
            provenance: provenanceA,
            targetIds: const [_eventB],
            sourceFingerprint: _fingerprintB,
          ),
        ],
      ];

      for (final claims in cases) {
        final index = buildRuntimeValidatedLegacyClaimIndex(
          _registry(records: records, claims: claims),
          runtimeEvidence: _evidence([
            _evidenceEntry(source: sourceA, provenance: provenanceA),
            _evidenceEntry(
              source: sourceB,
              provenance: provenanceB,
              sourceFingerprint: _fingerprintB,
            ),
          ]),
        );

        expect(index.canStartDualRead, isFalse);
        expect(index.canEnterDualRead, isFalse);
        expect(index.canRunDualRead, isFalse);
        expect(index.globalConflicts, isNotEmpty);
        expect(() => index.resolveSource(sourceA), throwsStateError);
        expect(() => index.resolveProvenance(provenanceA), throwsStateError);
      }
    });

    test('mismatched valid source and provenance cohorts fail preparation', () {
      final sourceA = NarrativeEventSourceRef.mapEnter('map_a');
      final sourceB = NarrativeEventSourceRef.mapEnter('map_b');
      final provenanceA = LegacySourceRef.mapEvent('map_a', 'legacy_a');
      final provenanceB = LegacySourceRef.mapEvent('map_b', 'legacy_b');
      final claimA = _claim(
        source: sourceA,
        provenance: provenanceA,
        targetIds: const [_eventA],
      );
      final claimB = _claim(
        source: sourceB,
        provenance: provenanceB,
        targetIds: const [_eventB],
        sourceFingerprint: _fingerprintB,
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        _registry(
          records: [
            _configured(_eventA, source: sourceA),
            _configured(_eventB, source: sourceB),
          ],
          claims: [claimA, claimB],
        ),
        runtimeEvidence: _evidence([
          _evidenceEntry(source: sourceA, provenance: provenanceA),
          _evidenceEntry(
            source: sourceB,
            provenance: provenanceB,
            sourceFingerprint: _fingerprintB,
          ),
        ]),
      );

      expect(
        () => index.requireMatchingValidCohort(
          source: sourceA,
          provenance: provenanceB,
        ),
        throwsStateError,
      );
    });

    test('typed diagnostics are immutable and stable across builds', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA, _eventB],
      );
      final registry = _registry(claims: [claim]);

      final evidence = _evidence([
        _evidenceEntry(source: source, provenance: provenance),
      ]);
      final first = buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: evidence,
      );
      final second = buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: evidence,
      );
      final firstDiagnostics = first.resolveSource(source).diagnostics;
      final secondDiagnostics = second.resolveSource(source).diagnostics;

      expect(firstDiagnostics, secondDiagnostics);
      expect(
        firstDiagnostics.map((diagnostic) => diagnostic.code.code),
        ['targetEventAbsent', 'targetEventAbsent'],
      );
      expect(
        firstDiagnostics.map((diagnostic) => diagnostic.targetEventId),
        [_eventA, _eventB],
      );
      expect(() => firstDiagnostics.clear(), throwsUnsupportedError);
    });

    test('registry-only claims cannot announce runtime readiness', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final index = buildValidatedLegacyClaimIndex(
        _registry(
          records: [_configured(_eventA, source: source)],
          claims: [claim],
        ),
      );

      expect(index.runtimeEvidenceValidated, isFalse);
      expect(index.canStartDualRead, isFalse);
      expect(index.canEnterDualRead, isFalse);
      expect(index.canRunDualRead, isFalse);
      expect(() => index.resolveSource(source), throwsStateError);
      expect(() => index.resolveProvenance(provenance), throwsStateError);
    });

    test('missing stale and source-mismatched evidence become tombstones', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'legacy');
      final claim = _claim(
        source: source,
        provenance: provenance,
        targetIds: const [_eventA],
      );
      final registry = _registry(
        records: [_configured(_eventA, source: source)],
        claims: [claim],
      );
      final cases = <({
        LegacyClaimRuntimeEvidence evidence,
        LegacyClaimTombstoneDiagnosticCode code,
      })>[
        (
          evidence: _evidence(const []),
          code: LegacyClaimTombstoneDiagnosticCode.provenanceMissing,
        ),
        (
          evidence: _evidence([
            _evidenceEntry(
              source: source,
              provenance: provenance,
              sourceFingerprint: _fingerprintB,
            ),
          ]),
          code: LegacyClaimTombstoneDiagnosticCode.sourceFingerprintMismatch,
        ),
        (
          evidence: _evidence([
            _evidenceEntry(
              source: NarrativeEventSourceRef.mapEnter('map_elsewhere'),
              provenance: provenance,
            ),
          ]),
          code: LegacyClaimTombstoneDiagnosticCode.provenanceSourceMismatch,
        ),
      ];

      for (final testCase in cases) {
        final index = buildRuntimeValidatedLegacyClaimIndex(
          registry,
          runtimeEvidence: testCase.evidence,
        );
        final sourceResolution = index.resolveSource(source);
        final provenanceResolution = index.resolveProvenance(provenance);

        expect(index.runtimeEvidenceValidated, isTrue);
        expect(index.canEnterDualRead, isFalse);
        expect(index.canRunDualRead, isTrue);
        expect(sourceResolution, isA<LegacyClaimSourceTombstone>());
        expect(provenanceResolution, isA<LegacyClaimProvenanceTombstone>());
        expect(
          sourceResolution.diagnostics.map((entry) => entry.code),
          contains(testCase.code),
        );
        expect(
          provenanceResolution.diagnostics.map((entry) => entry.code),
          contains(testCase.code),
        );
      }
    });

    test('an unexpected cohort member tombstones source and provenance', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final claimed = LegacySourceRef.mapEvent('map_port', 'legacy_a');
      final unexpected = LegacySourceRef.mapEvent('map_port', 'legacy_b');
      final claim = _claim(
        source: source,
        provenance: claimed,
        targetIds: const [_eventA],
      );
      final index = buildRuntimeValidatedLegacyClaimIndex(
        _registry(
          records: [_configured(_eventA, source: source)],
          claims: [claim],
        ),
        runtimeEvidence: _evidence([
          _evidenceEntry(source: source, provenance: claimed),
          _evidenceEntry(
            source: source,
            provenance: unexpected,
            sourceFingerprint: _fingerprintB,
          ),
        ]),
      );

      final sourceResolution = index.resolveSource(source);
      final unexpectedResolution = index.resolveProvenance(unexpected);

      expect(index.canRunDualRead, isTrue);
      expect(index.canEnterDualRead, isFalse);
      expect(sourceResolution, isA<LegacyClaimSourceTombstone>());
      expect(unexpectedResolution, isA<LegacyClaimProvenanceTombstone>());
      expect(
        sourceResolution.diagnostics.map((entry) => entry.code),
        contains(LegacyClaimTombstoneDiagnosticCode.cohortMemberUnexpected),
      );
      expect(unexpectedResolution.claim, same(claim));
      expect(unexpectedResolution.cohortId, claim.cohortId);
    });
  });
}

NarrativeEventRegistry _registry({
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _configured(
  String id, {
  required NarrativeEventSourceRef source,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: const [],
      sceneId: 'scene',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
}

NarrativeEventDraft _draft(String id) {
  return NarrativeEventDraft(
    id: id,
    name: id,
    conditions: const [],
    priority: 0,
    order: 0,
  );
}

LegacySourceClaim _claim({
  required NarrativeEventSourceRef source,
  required LegacySourceRef provenance,
  required List<String> targetIds,
  String sourceFingerprint = _fingerprintA,
}) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: sourceFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: targetIds,
    migrationReceiptId: 'receipt_1',
  );
}

LegacyClaimRuntimeEvidence _evidence(
  List<LegacyClaimRuntimeEvidenceEntry> entries,
) {
  return LegacyClaimRuntimeEvidence(entries: entries);
}

LegacyClaimRuntimeEvidenceEntry _evidenceEntry({
  required NarrativeEventSourceRef source,
  required LegacySourceRef provenance,
  String sourceFingerprint = _fingerprintA,
}) {
  return LegacyClaimRuntimeEvidenceEntry(
    source: source,
    provenance: provenance,
    sourceFingerprint: sourceFingerprint,
  );
}

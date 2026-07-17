import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/narrative_event_wire.dart';
import '../models/project_manifest.dart';
import 'narrative_event_canonical_json.dart';

@immutable
sealed class EventRegistryDecodeResult {
  const EventRegistryDecodeResult._();

  factory EventRegistryDecodeResult.absent() = _AbsentEventRegistryDecodeResult;

  factory EventRegistryDecodeResult.decoded(NarrativeEventRegistry registry) =
      _DecodedEventRegistryDecodeResult;

  factory EventRegistryDecodeResult.unsupported(
    Object? rawEventRegistryJson,
    List<String> diagnostics,
  ) = _UnsupportedEventRegistryDecodeResult;

  factory EventRegistryDecodeResult.invalid(
    Object? rawEventRegistryJson,
    List<String> diagnostics,
  ) = _InvalidEventRegistryDecodeResult;

  NarrativeEventRegistry? get registryOrNull;
  Object? get rawEventRegistryJson;
  List<String> get diagnostics;
  bool get writable;
  bool get runtimeAllowed;
  bool get migrationAllowed;
  bool get playtestAllowed;

  T when<T>({
    required T Function() absent,
    required T Function(NarrativeEventRegistry registry) decoded,
    required T Function(Object? raw, List<String> diagnostics) unsupported,
    required T Function(Object? raw, List<String> diagnostics) invalid,
  });

  Map<String, Object?> toJson() {
    final registry = registryOrNull;
    if (registry == null) {
      throw StateError('Only a decoded Event registry can be encoded.');
    }
    return registry.toJson();
  }
}

final class _AbsentEventRegistryDecodeResult extends EventRegistryDecodeResult {
  const _AbsentEventRegistryDecodeResult() : super._();

  @override
  NarrativeEventRegistry? get registryOrNull => null;
  @override
  Object? get rawEventRegistryJson => null;
  @override
  List<String> get diagnostics => const [];
  @override
  bool get writable => true;
  @override
  bool get runtimeAllowed => true;
  @override
  bool get migrationAllowed => true;
  @override
  bool get playtestAllowed => true;

  @override
  T when<T>({
    required T Function() absent,
    required T Function(NarrativeEventRegistry registry) decoded,
    required T Function(Object? raw, List<String> diagnostics) unsupported,
    required T Function(Object? raw, List<String> diagnostics) invalid,
  }) =>
      absent();
}

final class _DecodedEventRegistryDecodeResult
    extends EventRegistryDecodeResult {
  const _DecodedEventRegistryDecodeResult(this.registry) : super._();

  final NarrativeEventRegistry registry;

  @override
  NarrativeEventRegistry get registryOrNull => registry;
  @override
  Object? get rawEventRegistryJson => null;
  @override
  List<String> get diagnostics => const [];
  @override
  bool get writable => true;
  @override
  bool get runtimeAllowed => true;
  @override
  bool get migrationAllowed => true;
  @override
  bool get playtestAllowed => true;

  @override
  T when<T>({
    required T Function() absent,
    required T Function(NarrativeEventRegistry registry) decoded,
    required T Function(Object? raw, List<String> diagnostics) unsupported,
    required T Function(Object? raw, List<String> diagnostics) invalid,
  }) =>
      decoded(registry);
}

abstract base class _FailedEventRegistryDecodeResult
    extends EventRegistryDecodeResult {
  _FailedEventRegistryDecodeResult(
    Object? rawEventRegistryJson,
    List<String> diagnostics,
  )   : rawEventRegistryJson = _freezeJson(rawEventRegistryJson),
        diagnostics = List.unmodifiable(diagnostics),
        super._();

  @override
  final Object? rawEventRegistryJson;
  @override
  final List<String> diagnostics;
  @override
  NarrativeEventRegistry? get registryOrNull => null;
  @override
  bool get writable => false;
  @override
  bool get runtimeAllowed => false;
  @override
  bool get migrationAllowed => false;
  @override
  bool get playtestAllowed => false;
}

final class _UnsupportedEventRegistryDecodeResult
    extends _FailedEventRegistryDecodeResult {
  _UnsupportedEventRegistryDecodeResult(super.raw, super.diagnostics);

  @override
  T when<T>({
    required T Function() absent,
    required T Function(NarrativeEventRegistry registry) decoded,
    required T Function(Object? raw, List<String> diagnostics) unsupported,
    required T Function(Object? raw, List<String> diagnostics) invalid,
  }) =>
      unsupported(rawEventRegistryJson, diagnostics);
}

final class _InvalidEventRegistryDecodeResult
    extends _FailedEventRegistryDecodeResult {
  _InvalidEventRegistryDecodeResult(super.raw, super.diagnostics);

  @override
  T when<T>({
    required T Function() absent,
    required T Function(NarrativeEventRegistry registry) decoded,
    required T Function(Object? raw, List<String> diagnostics) unsupported,
    required T Function(Object? raw, List<String> diagnostics) invalid,
  }) =>
      invalid(rawEventRegistryJson, diagnostics);
}

EventRegistryDecodeResult decodeNarrativeEventRegistry(Object? raw) {
  if (raw == null) return EventRegistryDecodeResult.absent();
  try {
    return EventRegistryDecodeResult.decoded(
      NarrativeEventRegistry.fromJson(raw),
    );
  } on NarrativeEventUnsupportedWireException catch (error) {
    return EventRegistryDecodeResult.unsupported(
      raw,
      [_wireDiagnostic(error)],
    );
  } on NarrativeEventInvalidWireException catch (error) {
    return EventRegistryDecodeResult.invalid(raw, [_wireDiagnostic(error)]);
  } on FormatException catch (error) {
    return EventRegistryDecodeResult.invalid(
      raw,
      [error.message.toString()],
    );
  } on ArgumentError catch (error) {
    return EventRegistryDecodeResult.invalid(
      raw,
      [error.message?.toString() ?? 'Invalid Event registry invariant.'],
    );
  }
}

@immutable
final class LegacyClaimRuntimeEvidenceEntry {
  LegacyClaimRuntimeEvidenceEntry({
    required this.provenance,
    required this.source,
    required String sourceFingerprint,
  }) : sourceFingerprint = _validateRuntimeEvidenceFingerprint(
          sourceFingerprint,
        );

  final LegacySourceRef provenance;
  final NarrativeEventSourceRef source;
  final String sourceFingerprint;
}

@immutable
final class LegacyClaimRuntimeEvidence {
  LegacyClaimRuntimeEvidence({
    required List<LegacyClaimRuntimeEvidenceEntry> entries,
  }) : entries = List.unmodifiable(entries);

  final List<LegacyClaimRuntimeEvidenceEntry> entries;
}

enum LegacyClaimTombstoneDiagnosticCode {
  targetEventAbsent('targetEventAbsent'),
  targetEventDraft('targetEventDraft'),
  targetEventSourceMismatch('targetEventSourceMismatch'),
  provenanceMissing('provenanceMissing'),
  provenanceAmbiguous('provenanceAmbiguous'),
  provenanceSourceMismatch('provenanceSourceMismatch'),
  sourceFingerprintMismatch('sourceFingerprintMismatch'),
  cohortMemberUnexpected('cohortMemberUnexpected');

  const LegacyClaimTombstoneDiagnosticCode(this.code);

  final String code;
}

@immutable
final class LegacyClaimTombstoneDiagnostic {
  const LegacyClaimTombstoneDiagnostic._({
    required this.code,
    required this.message,
    this.targetEventId,
    this.provenance,
  });

  final LegacyClaimTombstoneDiagnosticCode code;
  final String? targetEventId;
  final LegacySourceRef? provenance;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyClaimTombstoneDiagnostic &&
          other.code == code &&
          other.targetEventId == targetEventId &&
          other.provenance == provenance &&
          other.message == message;

  @override
  int get hashCode => Object.hash(code, targetEventId, provenance, message);
}

@immutable
sealed class LegacyClaimSourceResolution {
  const LegacyClaimSourceResolution();

  NarrativeEventSourceRef get source;
  LegacySourceClaim? get claim;
  List<LegacyClaimTombstoneDiagnostic> get diagnostics;
  String? get cohortId => claim?.cohortId;
}

final class LegacyClaimSourceAbsent extends LegacyClaimSourceResolution {
  const LegacyClaimSourceAbsent._(this.source);

  @override
  final NarrativeEventSourceRef source;
  @override
  LegacySourceClaim? get claim => null;
  @override
  List<LegacyClaimTombstoneDiagnostic> get diagnostics => const [];
}

final class LegacyClaimSourceValid extends LegacyClaimSourceResolution {
  const LegacyClaimSourceValid._({
    required this.source,
    required this.claim,
  });

  @override
  final NarrativeEventSourceRef source;
  @override
  final LegacySourceClaim claim;
  @override
  List<LegacyClaimTombstoneDiagnostic> get diagnostics => const [];
}

final class LegacyClaimSourceTombstone extends LegacyClaimSourceResolution {
  LegacyClaimSourceTombstone._({
    required this.source,
    required this.claim,
    required List<LegacyClaimTombstoneDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  @override
  final NarrativeEventSourceRef source;
  @override
  final LegacySourceClaim? claim;
  @override
  final List<LegacyClaimTombstoneDiagnostic> diagnostics;
}

@immutable
sealed class LegacyClaimProvenanceResolution {
  const LegacyClaimProvenanceResolution();

  LegacySourceRef get provenance;
  LegacySourceClaim? get claim;
  List<LegacyClaimTombstoneDiagnostic> get diagnostics;
  String? get cohortId => claim?.cohortId;
}

final class LegacyClaimProvenanceAbsent
    extends LegacyClaimProvenanceResolution {
  const LegacyClaimProvenanceAbsent._(this.provenance);

  @override
  final LegacySourceRef provenance;
  @override
  LegacySourceClaim? get claim => null;
  @override
  List<LegacyClaimTombstoneDiagnostic> get diagnostics => const [];
}

final class LegacyClaimProvenanceValid extends LegacyClaimProvenanceResolution {
  const LegacyClaimProvenanceValid._({
    required this.provenance,
    required this.claim,
  });

  @override
  final LegacySourceRef provenance;
  @override
  final LegacySourceClaim claim;
  @override
  List<LegacyClaimTombstoneDiagnostic> get diagnostics => const [];
}

final class LegacyClaimProvenanceTombstone
    extends LegacyClaimProvenanceResolution {
  LegacyClaimProvenanceTombstone._({
    required this.provenance,
    required this.claim,
    required List<LegacyClaimTombstoneDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  @override
  final LegacySourceRef provenance;
  @override
  final LegacySourceClaim? claim;
  @override
  final List<LegacyClaimTombstoneDiagnostic> diagnostics;
}

@immutable
final class ValidatedLegacyClaimIndex {
  ValidatedLegacyClaimIndex._({
    required this.runtimeEvidenceValidated,
    required this.canEnterDualRead,
    required this.canRunDualRead,
    required Map<NarrativeEventSourceRef, LegacySourceClaim> validBySource,
    required Map<LegacySourceRef, LegacySourceClaim> validByProvenance,
    required Map<NarrativeEventSourceRef, List<String>> invalidBySource,
    required Map<LegacySourceRef, List<String>> invalidByProvenance,
    required Map<NarrativeEventSourceRef, LegacyClaimSourceTombstone>
        sourceTombstones,
    required Map<LegacySourceRef, LegacyClaimProvenanceTombstone>
        provenanceTombstones,
    required List<String> globalConflicts,
  })  : validBySource = Map.unmodifiable(validBySource),
        validByProvenance = Map.unmodifiable(validByProvenance),
        invalidBySource =
            Map<NarrativeEventSourceRef, List<String>>.unmodifiable({
          for (final entry in invalidBySource.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        }),
        invalidByProvenance = Map<LegacySourceRef, List<String>>.unmodifiable({
          for (final entry in invalidByProvenance.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        }),
        _sourceTombstones = Map.unmodifiable(sourceTombstones),
        _provenanceTombstones = Map.unmodifiable(provenanceTombstones),
        globalConflicts = List<String>.unmodifiable(globalConflicts);

  final bool runtimeEvidenceValidated;
  bool get canStartDualRead => canEnterDualRead;
  final bool canEnterDualRead;
  final bool canRunDualRead;
  final Map<NarrativeEventSourceRef, LegacySourceClaim> validBySource;
  final Map<LegacySourceRef, LegacySourceClaim> validByProvenance;
  final Map<NarrativeEventSourceRef, List<String>> invalidBySource;
  final Map<LegacySourceRef, List<String>> invalidByProvenance;
  final Map<NarrativeEventSourceRef, LegacyClaimSourceTombstone>
      _sourceTombstones;
  final Map<LegacySourceRef, LegacyClaimProvenanceTombstone>
      _provenanceTombstones;
  final List<String> globalConflicts;

  LegacyClaimSourceResolution resolveSource(
    NarrativeEventSourceRef source,
  ) {
    _requireRuntimeReady();
    return inspectSourceStructure(source);
  }

  /// Resolves structural claim validity for authoring and diagnostics without
  /// asserting that a runtime legacy corpus has been supplied.
  LegacyClaimSourceResolution inspectSourceStructure(
    NarrativeEventSourceRef source,
  ) {
    final valid = validBySource[source];
    if (valid != null) {
      return LegacyClaimSourceValid._(source: source, claim: valid);
    }
    return _sourceTombstones[source] ?? LegacyClaimSourceAbsent._(source);
  }

  LegacyClaimProvenanceResolution resolveProvenance(
    LegacySourceRef provenance,
  ) {
    _requireRuntimeReady();
    final valid = validByProvenance[provenance];
    if (valid != null) {
      return LegacyClaimProvenanceValid._(
        provenance: provenance,
        claim: valid,
      );
    }
    return _provenanceTombstones[provenance] ??
        LegacyClaimProvenanceAbsent._(provenance);
  }

  LegacySourceClaim requireMatchingValidCohort({
    required NarrativeEventSourceRef source,
    required LegacySourceRef provenance,
  }) {
    final sourceResolution = resolveSource(source);
    final provenanceResolution = resolveProvenance(provenance);
    if (sourceResolution is! LegacyClaimSourceValid ||
        provenanceResolution is! LegacyClaimProvenanceValid) {
      throw StateError(
        'Source and provenance must both resolve to valid claims.',
      );
    }
    if (sourceResolution.cohortId != provenanceResolution.cohortId) {
      throw StateError(
        'Source and provenance resolve to different legacy claim cohorts.',
      );
    }
    return sourceResolution.claim;
  }

  void _requireRuntimeReady() {
    if (!canRunDualRead) {
      throw StateError(
        'Dual-read runtime preparation is blocked by global claim conflicts.',
      );
    }
  }
}

ValidatedLegacyClaimIndex buildValidatedLegacyClaimIndex(
  NarrativeEventRegistry registry,
) {
  return _buildValidatedLegacyClaimIndex(registry, runtimeEvidence: null);
}

ValidatedLegacyClaimIndex buildRuntimeValidatedLegacyClaimIndex(
  NarrativeEventRegistry registry, {
  required LegacyClaimRuntimeEvidence runtimeEvidence,
}) {
  return _buildValidatedLegacyClaimIndex(
    registry,
    runtimeEvidence: runtimeEvidence,
  );
}

ValidatedLegacyClaimIndex _buildValidatedLegacyClaimIndex(
  NarrativeEventRegistry registry, {
  required LegacyClaimRuntimeEvidence? runtimeEvidence,
}) {
  final recordsById = {
    for (final record in registry.records) record.id: record
  };
  final claims = registry.legacyClaims;
  final runtimeEvidenceValidated = claims.isEmpty || runtimeEvidence != null;
  final evidenceByProvenance =
      <LegacySourceRef, List<LegacyClaimRuntimeEvidenceEntry>>{};
  final evidenceBySource =
      <NarrativeEventSourceRef, List<LegacyClaimRuntimeEvidenceEntry>>{};
  for (final entry in runtimeEvidence?.entries ?? const []) {
    evidenceByProvenance.putIfAbsent(entry.provenance, () => []).add(entry);
    evidenceBySource.putIfAbsent(entry.source, () => []).add(entry);
  }
  for (final entries in evidenceByProvenance.values) {
    entries.sort(_compareLegacyClaimRuntimeEvidenceEntries);
  }
  for (final entries in evidenceBySource.values) {
    entries.sort(_compareLegacyClaimRuntimeEvidenceEntries);
  }
  final cohortOwners = <String, List<int>>{};
  final sourceOwners = <NarrativeEventSourceRef, List<int>>{};
  final provenanceOwners = <LegacySourceRef, List<int>>{};

  for (var index = 0; index < claims.length; index++) {
    final claim = claims[index];
    cohortOwners.putIfAbsent(claim.cohortId, () => []).add(index);
    sourceOwners.putIfAbsent(claim.source, () => []).add(index);
    for (final member in claim.members) {
      provenanceOwners.putIfAbsent(member.provenance, () => []).add(index);
    }
  }

  final conflictedClaims = <int>{};
  final globalConflicts = <String>[];
  void recordConflicts<K>(
    String label,
    Map<K, List<int>> owners,
    String Function(K key) stableKey,
  ) {
    final entries = owners.entries
        .where((entry) => entry.value.length > 1)
        .toList()
      ..sort(
          (left, right) => stableKey(left.key).compareTo(stableKey(right.key)));
    for (final entry in entries) {
      conflictedClaims.addAll(entry.value);
      final cohorts = [for (final index in entry.value) claims[index].cohortId]
        ..sort();
      globalConflicts.add(
        '$label ${stableKey(entry.key)} is shared by cohorts ${cohorts.join(', ')}.',
      );
    }
  }

  recordConflicts('cohortId', cohortOwners, (key) => key);
  recordConflicts(
    'source',
    sourceOwners,
    (key) => canonicalizeNarrativeEventJson(key.toJson()),
  );
  recordConflicts(
    'provenance',
    provenanceOwners,
    (key) => canonicalizeNarrativeEventJson(key.toJson()),
  );

  final validBySource = <NarrativeEventSourceRef, LegacySourceClaim>{};
  final validByProvenance = <LegacySourceRef, LegacySourceClaim>{};
  final invalidBySource = <NarrativeEventSourceRef, List<String>>{};
  final invalidByProvenance = <LegacySourceRef, List<String>>{};
  final sourceTombstones =
      <NarrativeEventSourceRef, LegacyClaimSourceTombstone>{};
  final provenanceTombstones =
      <LegacySourceRef, LegacyClaimProvenanceTombstone>{};
  for (var index = 0; index < claims.length; index++) {
    final claim = claims[index];
    final localDiagnostics = <LegacyClaimTombstoneDiagnostic>[];
    final tombstoneProvenances = <LegacySourceRef>{
      for (final member in claim.members) member.provenance,
    };
    for (final targetId in claim.targetEventIds) {
      final target = recordsById[targetId];
      if (target == null) {
        localDiagnostics.add(
          LegacyClaimTombstoneDiagnostic._(
            code: LegacyClaimTombstoneDiagnosticCode.targetEventAbsent,
            targetEventId: targetId,
            message: 'Target Event $targetId is absent.',
          ),
        );
        continue;
      }
      final definition = target.definitionOrNull;
      if (definition == null) {
        localDiagnostics.add(
          LegacyClaimTombstoneDiagnostic._(
            code: LegacyClaimTombstoneDiagnosticCode.targetEventDraft,
            targetEventId: targetId,
            message: 'Target Event $targetId is still a draft.',
          ),
        );
      } else if (definition.source != claim.source) {
        localDiagnostics.add(
          LegacyClaimTombstoneDiagnostic._(
            code: LegacyClaimTombstoneDiagnosticCode.targetEventSourceMismatch,
            targetEventId: targetId,
            message: 'Target Event $targetId uses a different source.',
          ),
        );
      }
    }
    if (runtimeEvidence != null) {
      final claimedProvenances = <LegacySourceRef>{
        for (final member in claim.members) member.provenance,
      };
      for (final member in claim.members) {
        final currentEntries = evidenceByProvenance[member.provenance] ??
            const <LegacyClaimRuntimeEvidenceEntry>[];
        if (currentEntries.isEmpty) {
          localDiagnostics.add(
            LegacyClaimTombstoneDiagnostic._(
              code: LegacyClaimTombstoneDiagnosticCode.provenanceMissing,
              provenance: member.provenance,
              message: 'Claim provenance is absent from the runtime corpus.',
            ),
          );
          continue;
        }
        if (currentEntries.length > 1) {
          localDiagnostics.add(
            LegacyClaimTombstoneDiagnostic._(
              code: LegacyClaimTombstoneDiagnosticCode.provenanceAmbiguous,
              provenance: member.provenance,
              message: 'Claim provenance has multiple runtime corpus entries.',
            ),
          );
          continue;
        }
        final current = currentEntries.single;
        if (current.source != claim.source) {
          localDiagnostics.add(
            LegacyClaimTombstoneDiagnostic._(
              code: LegacyClaimTombstoneDiagnosticCode.provenanceSourceMismatch,
              provenance: member.provenance,
              message:
                  'Claim provenance resolves to a different runtime source.',
            ),
          );
        }
        if (current.sourceFingerprint != member.sourceFingerprint) {
          localDiagnostics.add(
            LegacyClaimTombstoneDiagnostic._(
              code:
                  LegacyClaimTombstoneDiagnosticCode.sourceFingerprintMismatch,
              provenance: member.provenance,
              message:
                  'Claim provenance fingerprint differs from the runtime corpus.',
            ),
          );
        }
      }
      for (final current in evidenceBySource[claim.source] ??
          const <LegacyClaimRuntimeEvidenceEntry>[]) {
        if (claimedProvenances.contains(current.provenance)) continue;
        tombstoneProvenances.add(current.provenance);
        localDiagnostics.add(
          LegacyClaimTombstoneDiagnostic._(
            code: LegacyClaimTombstoneDiagnosticCode.cohortMemberUnexpected,
            provenance: current.provenance,
            message:
                'Runtime corpus provenance is missing from the claimed cohort.',
          ),
        );
      }
    }
    localDiagnostics.sort(_compareLegacyClaimTombstoneDiagnostics);
    final diagnostics = <String>[];
    if (globalConflicts.isNotEmpty) {
      diagnostics.add(
        conflictedClaims.contains(index)
            ? 'Claim participates in a global '
                'cohort/source/provenance conflict.'
            : 'Claim is unusable while the claim index contains a global '
                'cohort/source/provenance conflict.',
      );
    }
    diagnostics.addAll(
      localDiagnostics.map((diagnostic) => diagnostic.message),
    );
    if (localDiagnostics.isNotEmpty) {
      sourceTombstones[claim.source] = LegacyClaimSourceTombstone._(
        source: claim.source,
        claim: claim,
        diagnostics: localDiagnostics,
      );
      for (final provenance in tombstoneProvenances) {
        provenanceTombstones[provenance] = LegacyClaimProvenanceTombstone._(
          provenance: provenance,
          claim: claim,
          diagnostics: localDiagnostics,
        );
      }
    }
    if (diagnostics.isEmpty) {
      validBySource[claim.source] = claim;
      for (final member in claim.members) {
        validByProvenance[member.provenance] = claim;
      }
    } else {
      invalidBySource.putIfAbsent(claim.source, () => []).addAll(diagnostics);
      for (final provenance in tombstoneProvenances) {
        invalidByProvenance
            .putIfAbsent(provenance, () => [])
            .addAll(diagnostics);
      }
    }
  }

  globalConflicts.sort();
  final canEnterDualRead = globalConflicts.isEmpty &&
      invalidBySource.isEmpty &&
      invalidByProvenance.isEmpty &&
      runtimeEvidenceValidated;
  return ValidatedLegacyClaimIndex._(
    runtimeEvidenceValidated: runtimeEvidenceValidated,
    canEnterDualRead: canEnterDualRead,
    canRunDualRead: globalConflicts.isEmpty && runtimeEvidenceValidated,
    validBySource: validBySource,
    validByProvenance: validByProvenance,
    invalidBySource: invalidBySource,
    invalidByProvenance: invalidByProvenance,
    sourceTombstones: sourceTombstones,
    provenanceTombstones: provenanceTombstones,
    globalConflicts: globalConflicts,
  );
}

int _compareLegacyClaimTombstoneDiagnostics(
  LegacyClaimTombstoneDiagnostic left,
  LegacyClaimTombstoneDiagnostic right,
) {
  final codeComparison = left.code.code.compareTo(right.code.code);
  if (codeComparison != 0) return codeComparison;
  final provenanceComparison = canonicalizeNarrativeEventJson(
    left.provenance?.toJson(),
  ).compareTo(
    canonicalizeNarrativeEventJson(right.provenance?.toJson()),
  );
  if (provenanceComparison != 0) return provenanceComparison;
  final targetComparison =
      (left.targetEventId ?? '').compareTo(right.targetEventId ?? '');
  if (targetComparison != 0) return targetComparison;
  return left.message.compareTo(right.message);
}

int _compareLegacyClaimRuntimeEvidenceEntries(
  LegacyClaimRuntimeEvidenceEntry left,
  LegacyClaimRuntimeEvidenceEntry right,
) {
  final provenanceComparison = canonicalizeNarrativeEventJson(
    left.provenance.toJson(),
  ).compareTo(canonicalizeNarrativeEventJson(right.provenance.toJson()));
  if (provenanceComparison != 0) return provenanceComparison;
  final sourceComparison = canonicalizeNarrativeEventJson(
    left.source.toJson(),
  ).compareTo(canonicalizeNarrativeEventJson(right.source.toJson()));
  if (sourceComparison != 0) return sourceComparison;
  return left.sourceFingerprint.compareTo(right.sourceFingerprint);
}

String _validateRuntimeEvidenceFingerprint(String value) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'sourceFingerprint',
      'must match sha256:<64 lowercase hex characters>',
    );
  }
  return value;
}

@immutable
final class ProjectManifestEventRegistryPreflightResult {
  ProjectManifestEventRegistryPreflightResult._({
    required List<int> originalJsonBytes,
    required this.eventRegistry,
    required this.manifest,
    required List<String> diagnostics,
  })  : originalJsonBytes = List.unmodifiable(originalJsonBytes),
        diagnostics = List.unmodifiable(diagnostics);

  final List<int> originalJsonBytes;
  final EventRegistryDecodeResult eventRegistry;
  final ProjectManifest? manifest;
  final List<String> diagnostics;

  bool get writable => manifest != null && eventRegistry.writable;
  bool get runtimeAllowed => manifest != null && eventRegistry.runtimeAllowed;
  bool get migrationAllowed =>
      manifest != null && eventRegistry.migrationAllowed;
  bool get playtestAllowed => manifest != null && eventRegistry.playtestAllowed;

  EventSystemMode? get effectiveMode => eventRegistry.when(
        absent: () => EventSystemMode.legacyOnly,
        decoded: (registry) => registry.mode,
        unsupported: (_, __) => null,
        invalid: (_, __) => null,
      );
}

ProjectManifestEventRegistryPreflightResult preflightProjectManifestJson(
  List<int> jsonBytes,
) {
  final diagnostics = <String>[];
  Object? decoded;
  late List<String> duplicateJsonKeys;
  try {
    final jsonSource = utf8.decode(jsonBytes);
    duplicateJsonKeys = findDuplicateNarrativeEventJsonKeys(jsonSource);
    decoded = jsonDecode(jsonSource);
  } on Object catch (error) {
    diagnostics.add('Project JSON decode failed: $error');
    return ProjectManifestEventRegistryPreflightResult._(
      originalJsonBytes: jsonBytes,
      eventRegistry: EventRegistryDecodeResult.invalid(null, diagnostics),
      manifest: null,
      diagnostics: diagnostics,
    );
  }
  if (decoded is! Map) {
    diagnostics.add('Project JSON root must be an object.');
    return ProjectManifestEventRegistryPreflightResult._(
      originalJsonBytes: jsonBytes,
      eventRegistry: EventRegistryDecodeResult.invalid(null, diagnostics),
      manifest: null,
      diagnostics: diagnostics,
    );
  }
  final root = <String, dynamic>{};
  for (final entry in decoded.entries) {
    if (entry.key is! String) {
      diagnostics.add('Project JSON root keys must be strings.');
      return ProjectManifestEventRegistryPreflightResult._(
        originalJsonBytes: jsonBytes,
        eventRegistry: EventRegistryDecodeResult.invalid(null, diagnostics),
        manifest: null,
        diagnostics: diagnostics,
      );
    }
    root[entry.key as String] = entry.value;
  }

  if (duplicateJsonKeys.isNotEmpty) {
    diagnostics.addAll([
      for (final path in duplicateJsonKeys)
        'Duplicate JSON key at $path is not valid I-JSON.',
    ]);
    return ProjectManifestEventRegistryPreflightResult._(
      originalJsonBytes: jsonBytes,
      eventRegistry: EventRegistryDecodeResult.invalid(
        root['eventRegistry'],
        diagnostics,
      ),
      manifest: null,
      diagnostics: diagnostics,
    );
  }

  final registryResult = decodeNarrativeEventRegistry(root['eventRegistry']);
  final manifestJson = Map<String, dynamic>.from(root);
  if (!registryResult.writable) {
    manifestJson.remove('eventRegistry');
  }

  ProjectManifest? manifest;
  try {
    manifest = ProjectManifest.fromJson(manifestJson);
  } on Object catch (error) {
    diagnostics.add('Project manifest decode failed: $error');
  }
  diagnostics.addAll(registryResult.diagnostics);

  return ProjectManifestEventRegistryPreflightResult._(
    originalJsonBytes: jsonBytes,
    eventRegistry: registryResult,
    manifest: manifest,
    diagnostics: diagnostics,
  );
}

String _wireDiagnostic(NarrativeEventWireException error) {
  return error.message.toString();
}

Object? _freezeJson(Object? value) {
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJson));
  }
  if (value is Map) {
    return Map<Object?, Object?>.unmodifiable({
      for (final entry in value.entries)
        _freezeJson(entry.key): _freezeJson(entry.value),
    });
  }
  return value;
}

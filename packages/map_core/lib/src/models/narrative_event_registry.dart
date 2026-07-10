import 'package:meta/meta.dart' show immutable;

import '../operations/narrative_event_canonical_json.dart';
import 'narrative_event_definition.dart';
import 'narrative_event_source_ref.dart';
import 'narrative_event_wire.dart';

const Set<String> _legacySourceFields = {
  'kind',
  'mapId',
  'eventId',
  'scenarioId',
  'nodeId',
};

final RegExp _sha256FingerprintPattern = RegExp(r'^sha256:[0-9a-f]{64}$');
final RegExp _cohortIdPattern = RegExp(r'^lsc_[0-9a-f]{64}$');

enum EventSystemMode { legacyOnly, dualRead, v2Only }

@immutable
sealed class LegacySourceRef {
  const LegacySourceRef._();

  factory LegacySourceRef.mapEvent(String mapId, String eventId) =
      _LegacyMapEventSourceRef;

  factory LegacySourceRef.scenarioSourceNode(
    String scenarioId,
    String nodeId,
  ) = _LegacyScenarioSourceNodeRef;

  factory LegacySourceRef.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'provenance');
    final kind = NarrativeEventWire.requiredString(
      object,
      'kind',
      path: 'provenance',
    );
    switch (kind) {
      case 'mapEvent':
        NarrativeEventWire.expectExactFields(
          object,
          const {'kind', 'mapId', 'eventId'},
          path: 'provenance',
          knownFields: _legacySourceFields,
        );
        return LegacySourceRef.mapEvent(
          NarrativeEventWire.requiredIdentity(
            object,
            'mapId',
            path: 'provenance',
          ),
          NarrativeEventWire.requiredIdentity(
            object,
            'eventId',
            path: 'provenance',
          ),
        );
      case 'scenarioSourceNode':
        NarrativeEventWire.expectExactFields(
          object,
          const {'kind', 'scenarioId', 'nodeId'},
          path: 'provenance',
          knownFields: _legacySourceFields,
        );
        return LegacySourceRef.scenarioSourceNode(
          NarrativeEventWire.requiredIdentity(
            object,
            'scenarioId',
            path: 'provenance',
          ),
          NarrativeEventWire.requiredIdentity(
            object,
            'nodeId',
            path: 'provenance',
          ),
        );
      default:
        return NarrativeEventWire.unsupported(
          'Unknown legacy source kind "$kind".',
          path: 'provenance.kind',
          source: kind,
        );
    }
  }

  T when<T>({
    required T Function(String mapId, String eventId) mapEvent,
    required T Function(String scenarioId, String nodeId) scenarioSourceNode,
  });

  Map<String, Object?> toJson();
}

final class _LegacyMapEventSourceRef extends LegacySourceRef {
  _LegacyMapEventSourceRef(String mapId, String eventId)
      : mapId = _validateIdentity(mapId, 'mapId'),
        eventId = _validateIdentity(eventId, 'eventId'),
        super._();

  final String mapId;
  final String eventId;

  @override
  T when<T>({
    required T Function(String mapId, String eventId) mapEvent,
    required T Function(String scenarioId, String nodeId) scenarioSourceNode,
  }) =>
      mapEvent(mapId, eventId);

  @override
  Map<String, Object?> toJson() => {
        'kind': 'mapEvent',
        'mapId': mapId,
        'eventId': eventId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LegacyMapEventSourceRef &&
          other.mapId == mapId &&
          other.eventId == eventId;

  @override
  int get hashCode => Object.hash('mapEvent', mapId, eventId);
}

final class _LegacyScenarioSourceNodeRef extends LegacySourceRef {
  _LegacyScenarioSourceNodeRef(String scenarioId, String nodeId)
      : scenarioId = _validateIdentity(scenarioId, 'scenarioId'),
        nodeId = _validateIdentity(nodeId, 'nodeId'),
        super._();

  final String scenarioId;
  final String nodeId;

  @override
  T when<T>({
    required T Function(String mapId, String eventId) mapEvent,
    required T Function(String scenarioId, String nodeId) scenarioSourceNode,
  }) =>
      scenarioSourceNode(scenarioId, nodeId);

  @override
  Map<String, Object?> toJson() => {
        'kind': 'scenarioSourceNode',
        'scenarioId': scenarioId,
        'nodeId': nodeId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LegacyScenarioSourceNodeRef &&
          other.scenarioId == scenarioId &&
          other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash('scenarioSourceNode', scenarioId, nodeId);
}

int compareLegacySourceRefs(LegacySourceRef left, LegacySourceRef right) {
  final leftParts = _legacySourceSortParts(left);
  final rightParts = _legacySourceSortParts(right);
  for (var index = 0; index < leftParts.length; index++) {
    final comparison = compareNarrativeEventUtf16(
      leftParts[index],
      rightParts[index],
    );
    if (comparison != 0) return comparison;
  }
  return 0;
}

@immutable
final class LegacySourceClaimMember {
  LegacySourceClaimMember({
    required this.provenance,
    required String sourceFingerprint,
  }) : sourceFingerprint = _validateFingerprint(
          sourceFingerprint,
          'sourceFingerprint',
        );

  factory LegacySourceClaimMember.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'claimMember');
    NarrativeEventWire.expectExactFields(
      object,
      const {'provenance', 'sourceFingerprint'},
      path: 'claimMember',
    );
    return _decodeConstruct(
      () => LegacySourceClaimMember(
        provenance: LegacySourceRef.fromJson(
          NarrativeEventWire.requiredObject(
            object,
            'provenance',
            path: 'claimMember',
          ),
        ),
        sourceFingerprint: NarrativeEventWire.requiredIdentity(
          object,
          'sourceFingerprint',
          path: 'claimMember',
        ),
      ),
      path: 'claimMember',
      source: object,
    );
  }

  final LegacySourceRef provenance;
  final String sourceFingerprint;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'sourceFingerprint': sourceFingerprint,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacySourceClaimMember &&
          other.provenance == provenance &&
          other.sourceFingerprint == sourceFingerprint;

  @override
  int get hashCode => Object.hash(provenance, sourceFingerprint);
}

@immutable
final class LegacySourceClaim {
  LegacySourceClaim({
    required String cohortId,
    required this.source,
    required List<LegacySourceClaimMember> members,
    required String cohortFingerprint,
    required List<String> targetEventIds,
    required String migrationReceiptId,
  })  : cohortId = _validateCohortId(cohortId),
        members = _validateMembers(members),
        cohortFingerprint = _validateFingerprint(
          cohortFingerprint,
          'cohortFingerprint',
        ),
        targetEventIds = _validateTargets(targetEventIds),
        migrationReceiptId = _validateIdentity(
          migrationReceiptId,
          'migrationReceiptId',
        ) {
    final expectedCohortId = _computeCohortId(source, this.members);
    if (this.cohortId != expectedCohortId) {
      throw ArgumentError.value(
        this.cohortId,
        'cohortId',
        'does not match the canonical source/provenance preimage',
      );
    }
    final expectedFingerprint = _computeCohortFingerprint(
      this.cohortId,
      this.members,
    );
    if (this.cohortFingerprint != expectedFingerprint) {
      throw ArgumentError.value(
        this.cohortFingerprint,
        'cohortFingerprint',
        'does not match the canonical cohort/member preimage',
      );
    }
  }

  factory LegacySourceClaim.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'legacyClaim');
    NarrativeEventWire.expectExactFields(
      object,
      const {
        'cohortId',
        'source',
        'members',
        'cohortFingerprint',
        'targetEventIds',
        'migrationReceiptId',
      },
      path: 'legacyClaim',
    );
    final memberValues = NarrativeEventWire.requiredList(
      object,
      'members',
      path: 'legacyClaim',
    );
    final targetValues = NarrativeEventWire.requiredList(
      object,
      'targetEventIds',
      path: 'legacyClaim',
    );
    return _decodeConstruct(
      () => LegacySourceClaim(
        cohortId: NarrativeEventWire.requiredIdentity(
          object,
          'cohortId',
          path: 'legacyClaim',
        ),
        source: NarrativeEventSourceRef.fromJson(
          NarrativeEventWire.requiredObject(
            object,
            'source',
            path: 'legacyClaim',
          ),
        ),
        members: [
          for (final value in memberValues)
            LegacySourceClaimMember.fromJson(value),
        ],
        cohortFingerprint: NarrativeEventWire.requiredIdentity(
          object,
          'cohortFingerprint',
          path: 'legacyClaim',
        ),
        targetEventIds: [
          for (final value in targetValues) _decodeTargetEventId(value),
        ],
        migrationReceiptId: NarrativeEventWire.requiredIdentity(
          object,
          'migrationReceiptId',
          path: 'legacyClaim',
        ),
      ),
      path: 'legacyClaim',
      source: object,
    );
  }

  final String cohortId;
  final NarrativeEventSourceRef source;
  final List<LegacySourceClaimMember> members;
  final String cohortFingerprint;
  final List<String> targetEventIds;
  final String migrationReceiptId;

  Map<String, Object?> toJson() => {
        'cohortId': cohortId,
        'source': source.toJson(),
        'members': [for (final member in members) member.toJson()],
        'cohortFingerprint': cohortFingerprint,
        'targetEventIds': targetEventIds,
        'migrationReceiptId': migrationReceiptId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacySourceClaim &&
          other.cohortId == cohortId &&
          other.source == source &&
          _listEquals(other.members, members) &&
          other.cohortFingerprint == cohortFingerprint &&
          _listEquals(other.targetEventIds, targetEventIds) &&
          other.migrationReceiptId == migrationReceiptId;

  @override
  int get hashCode => Object.hash(
        cohortId,
        source,
        Object.hashAll(members),
        cohortFingerprint,
        Object.hashAll(targetEventIds),
        migrationReceiptId,
      );
}

@immutable
final class NarrativeEventRegistry {
  NarrativeEventRegistry({
    required int schemaVersion,
    required this.mode,
    required List<NarrativeEventRecord> records,
    required List<LegacySourceClaim> legacyClaims,
  })  : schemaVersion = _validateSchemaVersion(schemaVersion),
        records = _validateUniqueRecords(records),
        legacyClaims = List.unmodifiable(legacyClaims);

  factory NarrativeEventRegistry.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'eventRegistry');
    NarrativeEventWire.expectExactFields(
      object,
      const {'schemaVersion', 'mode', 'records', 'legacyClaims'},
      path: 'eventRegistry',
    );
    final schemaVersion = NarrativeEventWire.requiredInt(
      object,
      'schemaVersion',
      path: 'eventRegistry',
    );
    if (schemaVersion != 1) {
      return NarrativeEventWire.unsupported(
        'Unsupported Event registry schema version $schemaVersion.',
        path: 'eventRegistry.schemaVersion',
        source: schemaVersion,
      );
    }
    final modeName = NarrativeEventWire.requiredString(
      object,
      'mode',
      path: 'eventRegistry',
    );
    final mode = switch (modeName) {
      'legacyOnly' => EventSystemMode.legacyOnly,
      'dualRead' => EventSystemMode.dualRead,
      'v2Only' => EventSystemMode.v2Only,
      _ => NarrativeEventWire.unsupported(
          'Unknown Event system mode "$modeName".',
          path: 'eventRegistry.mode',
          source: modeName,
        ),
    };
    final recordValues = NarrativeEventWire.requiredList(
      object,
      'records',
      path: 'eventRegistry',
    );
    final claimValues = NarrativeEventWire.requiredList(
      object,
      'legacyClaims',
      path: 'eventRegistry',
    );
    return _decodeConstruct(
      () => NarrativeEventRegistry(
        schemaVersion: schemaVersion,
        mode: mode,
        records: [
          for (final value in recordValues)
            NarrativeEventRecord.fromJson(value),
        ],
        legacyClaims: [
          for (final value in claimValues) LegacySourceClaim.fromJson(value),
        ],
      ),
      path: 'eventRegistry',
      source: object,
    );
  }

  final int schemaVersion;
  final EventSystemMode mode;
  final List<NarrativeEventRecord> records;
  final List<LegacySourceClaim> legacyClaims;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'mode': mode.name,
        'records': [for (final record in records) record.toJson()],
        'legacyClaims': [for (final claim in legacyClaims) claim.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeEventRegistry &&
          other.schemaVersion == schemaVersion &&
          other.mode == mode &&
          _listEquals(other.records, records) &&
          _listEquals(other.legacyClaims, legacyClaims);

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        mode,
        Object.hashAll(records),
        Object.hashAll(legacyClaims),
      );
}

List<String> _legacySourceSortParts(LegacySourceRef source) {
  return source.when(
    mapEvent: (mapId, eventId) => ['mapEvent', mapId, eventId],
    scenarioSourceNode: (scenarioId, nodeId) => [
      'scenarioSourceNode',
      scenarioId,
      nodeId,
    ],
  );
}

int _compareMembers(
  LegacySourceClaimMember left,
  LegacySourceClaimMember right,
) {
  final provenanceComparison = compareLegacySourceRefs(
    left.provenance,
    right.provenance,
  );
  if (provenanceComparison != 0) return provenanceComparison;
  return compareNarrativeEventUtf16(
    left.sourceFingerprint,
    right.sourceFingerprint,
  );
}

List<LegacySourceClaimMember> _validateMembers(
  List<LegacySourceClaimMember> values,
) {
  if (values.isEmpty) {
    throw ArgumentError.value(
        values, 'members', 'must contain at least one member');
  }
  final provenances = <LegacySourceRef>{};
  for (var index = 0; index < values.length; index++) {
    final member = values[index];
    if (!provenances.add(member.provenance)) {
      throw ArgumentError.value(
        values,
        'members',
        'must not contain duplicate provenances',
      );
    }
    if (index > 0 && _compareMembers(values[index - 1], member) >= 0) {
      throw ArgumentError.value(
        values,
        'members',
        'must use canonical provenance order',
      );
    }
  }
  return List.unmodifiable(values);
}

List<String> _validateTargets(List<String> values) {
  if (values.isEmpty) {
    throw ArgumentError.value(
      values,
      'targetEventIds',
      'must contain at least one Event ID',
    );
  }
  final seen = <String>{};
  for (var index = 0; index < values.length; index++) {
    final value = _validateEventId(values[index], 'targetEventIds[$index]');
    if (!seen.add(value)) {
      throw ArgumentError.value(
        values,
        'targetEventIds',
        'must not contain duplicates',
      );
    }
    if (index > 0 &&
        compareNarrativeEventUtf16(values[index - 1], value) >= 0) {
      throw ArgumentError.value(
        values,
        'targetEventIds',
        'must be sorted lexically',
      );
    }
  }
  return List.unmodifiable(values);
}

List<NarrativeEventRecord> _validateUniqueRecords(
  List<NarrativeEventRecord> values,
) {
  final ids = <String>{};
  for (final record in values) {
    if (!ids.add(record.id)) {
      throw ArgumentError.value(
        values,
        'records',
        'must not contain duplicate Event IDs',
      );
    }
  }
  return List.unmodifiable(values);
}

String _computeCohortId(
  NarrativeEventSourceRef source,
  List<LegacySourceClaimMember> members,
) {
  return 'lsc_${narrativeEventCanonicalSha256({
        'source': source.toJson(),
        'provenances': [
          for (final member in members) member.provenance.toJson(),
        ],
      })}';
}

String _computeCohortFingerprint(
  String cohortId,
  List<LegacySourceClaimMember> members,
) {
  return 'sha256:${narrativeEventCanonicalSha256({
        'cohortId': cohortId,
        'members': [for (final member in members) member.toJson()],
      })}';
}

String _validateIdentity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(
        value, name, 'must be non-empty and already trimmed');
  }
  return value;
}

String _validateEventId(String value, String name) {
  _validateIdentity(value, name);
  if (!narrativeEventIdPattern.hasMatch(value)) {
    throw ArgumentError.value(value, name, 'must match the Event V2 ID format');
  }
  return value;
}

String _validateFingerprint(String value, String name) {
  _validateIdentity(value, name);
  if (!_sha256FingerprintPattern.hasMatch(value)) {
    throw ArgumentError.value(
        value, name, 'must use sha256:<64 lowercase hex>');
  }
  return value;
}

String _validateCohortId(String value) {
  _validateIdentity(value, 'cohortId');
  if (!_cohortIdPattern.hasMatch(value)) {
    throw ArgumentError.value(
        value, 'cohortId', 'must use lsc_<64 lowercase hex>');
  }
  return value;
}

int _validateSchemaVersion(int value) {
  if (value != 1) {
    throw ArgumentError.value(
        value, 'schemaVersion', 'only version 1 is supported');
  }
  return value;
}

String _decodeTargetEventId(Object? value) {
  if (value is! String || value.isEmpty || value.trim() != value) {
    return NarrativeEventWire.invalid(
      'Target Event ID must be a non-empty, already-trimmed string.',
      path: 'legacyClaim.targetEventIds',
      source: value,
    );
  }
  if (!narrativeEventIdPattern.hasMatch(value)) {
    return NarrativeEventWire.invalid(
      'Target Event ID has an invalid V2 format.',
      path: 'legacyClaim.targetEventIds',
      source: value,
    );
  }
  return value;
}

T _decodeConstruct<T>(
  T Function() construct, {
  required String path,
  required Object? source,
}) {
  try {
    return construct();
  } on ArgumentError catch (error) {
    return NarrativeEventWire.invalid(
      error.message?.toString() ?? 'Invalid structural invariant.',
      path: path,
      source: source,
    );
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

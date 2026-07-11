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
final class ValidatedLegacyClaimIndex {
  ValidatedLegacyClaimIndex._({
    required this.canStartDualRead,
    required Map<NarrativeEventSourceRef, LegacySourceClaim> validBySource,
    required Map<LegacySourceRef, LegacySourceClaim> validByProvenance,
    required Map<NarrativeEventSourceRef, List<String>> invalidBySource,
    required Map<LegacySourceRef, List<String>> invalidByProvenance,
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
        globalConflicts = List<String>.unmodifiable(globalConflicts);

  final bool canStartDualRead;
  final Map<NarrativeEventSourceRef, LegacySourceClaim> validBySource;
  final Map<LegacySourceRef, LegacySourceClaim> validByProvenance;
  final Map<NarrativeEventSourceRef, List<String>> invalidBySource;
  final Map<LegacySourceRef, List<String>> invalidByProvenance;
  final List<String> globalConflicts;
}

ValidatedLegacyClaimIndex buildValidatedLegacyClaimIndex(
  NarrativeEventRegistry registry,
) {
  final recordsById = {
    for (final record in registry.records) record.id: record
  };
  final claims = registry.legacyClaims;
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
  for (var index = 0; index < claims.length; index++) {
    final claim = claims[index];
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
    for (final targetId in claim.targetEventIds) {
      final target = recordsById[targetId];
      if (target == null) {
        diagnostics.add('Target Event $targetId is absent.');
        continue;
      }
      final definition = target.definitionOrNull;
      if (definition == null) {
        diagnostics.add('Target Event $targetId is still a draft.');
      } else if (definition.source != claim.source) {
        diagnostics.add('Target Event $targetId uses a different source.');
      }
    }
    if (diagnostics.isEmpty) {
      validBySource[claim.source] = claim;
      for (final member in claim.members) {
        validByProvenance[member.provenance] = claim;
      }
    } else {
      invalidBySource.putIfAbsent(claim.source, () => []).addAll(diagnostics);
      for (final member in claim.members) {
        invalidByProvenance
            .putIfAbsent(member.provenance, () => [])
            .addAll(diagnostics);
      }
    }
  }

  globalConflicts.sort();
  return ValidatedLegacyClaimIndex._(
    canStartDualRead: globalConflicts.isEmpty && invalidBySource.isEmpty,
    validBySource: validBySource,
    validByProvenance: validByProvenance,
    invalidBySource: invalidBySource,
    invalidByProvenance: invalidByProvenance,
    globalConflicts: globalConflicts,
  );
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

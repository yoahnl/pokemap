import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/narrative_fact.dart';
import '../models/scene_asset.dart';
import 'narrative_outcome_event_source_catalog.dart';
import 'narrative_spatial_event_source_catalog.dart';

enum NarrativeEventProjectResolutionStatus {
  found,
  unavailable,
  missing,
  ambiguous,
}

enum NarrativeEventProjectDiagnosticSeverity { info, warning, error }

@immutable
final class NarrativeEventProjectDiagnostic {
  NarrativeEventProjectDiagnostic({
    required String code,
    required this.severity,
    required String message,
    required String path,
  })  : code = _identity(code, 'code'),
        message = _identity(message, 'message'),
        path = _identity(path, 'path');

  final String code;
  final NarrativeEventProjectDiagnosticSeverity severity;
  final String message;
  final String path;

  Map<String, Object?> toDebugJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'path': path,
      };
}

@immutable
final class NarrativeEventProjectSceneEntry {
  const NarrativeEventProjectSceneEntry({
    required this.scene,
    required this.buildable,
  });

  final SceneAsset scene;
  final bool buildable;

  Map<String, Object?> toDebugJson() => {
        'sceneId': scene.id,
        'label': scene.name,
        'buildable': buildable,
      };
}

@immutable
final class NarrativeEventProjectFactEntry {
  const NarrativeEventProjectFactEntry(this.fact);

  final NarrativeFactDefinition fact;

  Map<String, Object?> toDebugJson() => {
        'factId': fact.id,
        'label': fact.label,
      };
}

@immutable
final class NarrativeEventProjectEventEntry {
  const NarrativeEventProjectEventEntry({
    required this.record,
    required this.proposed,
    required this.inDependencyCycle,
    required this.contextuallyValid,
  });

  final NarrativeEventRecord record;
  final bool proposed;
  final bool inDependencyCycle;
  final bool contextuallyValid;

  bool get configured => record.definitionOrNull != null;
  bool get draft => record.draftOrNull != null;
  bool get applicableReferenceTarget =>
      configured && !inDependencyCycle && contextuallyValid;

  Map<String, Object?> toDebugJson() => {
        'eventId': record.id,
        'state': configured ? 'configured' : 'draft',
        'proposed': proposed,
        'inDependencyCycle': inDependencyCycle,
        'contextuallyValid': contextuallyValid,
      };
}

@immutable
final class NarrativeEventProjectResolution<T> {
  NarrativeEventProjectResolution({
    required this.status,
    List<T> matches = const [],
  }) : matches = List.unmodifiable(matches) {
    if ((status == NarrativeEventProjectResolutionStatus.found ||
            status == NarrativeEventProjectResolutionStatus.unavailable) &&
        this.matches.length != 1) {
      throw ArgumentError('A resolved project reference requires one match.');
    }
    if (status == NarrativeEventProjectResolutionStatus.missing &&
        this.matches.isNotEmpty) {
      throw ArgumentError('A missing project reference cannot have matches.');
    }
    if (status == NarrativeEventProjectResolutionStatus.ambiguous &&
        this.matches.length < 2) {
      throw ArgumentError('An ambiguous project reference needs two matches.');
    }
  }

  final NarrativeEventProjectResolutionStatus status;
  final List<T> matches;

  T? get valueOrNull => matches.length == 1 ? matches.single : null;
}

@immutable
final class NarrativeEventProjectCatalog {
  NarrativeEventProjectCatalog({
    required String manifestHash,
    required Map<String, String> mapHashes,
    required this.spatialSources,
    required this.outcomeSources,
    required List<NarrativeEventProjectSceneEntry> scenes,
    required List<NarrativeEventProjectFactEntry> facts,
    required List<NarrativeEventProjectEventEntry> events,
    required List<NarrativeEventProjectDiagnostic> diagnostics,
  })  : manifestHash = _identity(manifestHash, 'manifestHash'),
        mapHashes = Map.unmodifiable(mapHashes),
        scenes = List.unmodifiable(scenes),
        facts = List.unmodifiable(facts),
        events = List.unmodifiable(events),
        diagnostics = List.unmodifiable(diagnostics),
        _scenesById = _index(scenes, (entry) => entry.scene.id),
        _factsById = _index(facts, (entry) => entry.fact.id),
        _eventsById = _index(events, (entry) => entry.record.id) {
    if (this.mapHashes.entries.any(
          (entry) =>
              entry.key.isEmpty ||
              entry.key.trim() != entry.key ||
              entry.value.isEmpty ||
              entry.value.trim() != entry.value,
        )) {
      throw ArgumentError.value(
        mapHashes,
        'mapHashes',
        'keys and values must be non-empty and trimmed',
      );
    }
  }

  final String manifestHash;
  final Map<String, String> mapHashes;
  final NarrativeSpatialEventSourceCatalog spatialSources;
  final NarrativeOutcomeEventSourceCatalog outcomeSources;
  final List<NarrativeEventProjectSceneEntry> scenes;
  final List<NarrativeEventProjectFactEntry> facts;
  final List<NarrativeEventProjectEventEntry> events;
  final List<NarrativeEventProjectDiagnostic> diagnostics;
  final Map<String, List<NarrativeEventProjectSceneEntry>> _scenesById;
  final Map<String, List<NarrativeEventProjectFactEntry>> _factsById;
  final Map<String, List<NarrativeEventProjectEventEntry>> _eventsById;

  List<NarrativeEventRecord> get proposedRecords => List.unmodifiable([
        for (final entry in events)
          if (entry.proposed) entry.record,
      ]);

  bool get hasBlockingDiagnostics => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity ==
            NarrativeEventProjectDiagnosticSeverity.error,
      );

  NarrativeEventProjectResolution<Object> resolveSource(
    NarrativeEventSourceRef source,
  ) {
    return source.when(
      entityInteract: (_, __) => _spatialResolution(source),
      triggerEnter: (_, __) => _spatialResolution(source),
      mapEnter: (_) => _spatialResolution(source),
      outcomeReceived: _outcomeResolution,
    );
  }

  NarrativeEventProjectResolution<NarrativeEventProjectSceneEntry> resolveScene(
    String sceneId,
  ) {
    return _resolveIndexed(
      _scenesById[sceneId] ?? const [],
      available: (entry) => entry.buildable,
    );
  }

  NarrativeEventProjectResolution<NarrativeEventProjectFactEntry> resolveFact(
    String factId,
  ) {
    return _resolveIndexed(
      _factsById[factId] ?? const [],
      available: (_) => true,
    );
  }

  NarrativeEventProjectResolution<NarrativeEventProjectEventEntry> resolveEvent(
    String eventId,
  ) {
    return _resolveIndexed(
      _eventsById[eventId] ?? const [],
      available: (entry) => entry.applicableReferenceTarget,
    );
  }

  Map<String, Object?> toDebugJson() => {
        'manifestHash': manifestHash,
        'mapHashes': mapHashes,
        'spatialSources': spatialSources.toDebugJson(),
        'outcomeSources': outcomeSources.toDebugJson(),
        'scenes': [for (final entry in scenes) entry.toDebugJson()],
        'facts': [for (final entry in facts) entry.toDebugJson()],
        'events': [for (final entry in events) entry.toDebugJson()],
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };

  NarrativeEventProjectResolution<Object> _spatialResolution(
    NarrativeEventSourceRef source,
  ) {
    final resolution = spatialSources.resolve(source);
    final matches = spatialSources.optionsForSource(source);
    return NarrativeEventProjectResolution<Object>(
      status: switch (resolution.status) {
        NarrativeSpatialEventSourceResolutionStatus.found =>
          NarrativeEventProjectResolutionStatus.found,
        NarrativeSpatialEventSourceResolutionStatus.unavailable =>
          NarrativeEventProjectResolutionStatus.unavailable,
        NarrativeSpatialEventSourceResolutionStatus.missing =>
          NarrativeEventProjectResolutionStatus.missing,
        NarrativeSpatialEventSourceResolutionStatus.ambiguous =>
          NarrativeEventProjectResolutionStatus.ambiguous,
      },
      matches: matches,
    );
  }

  NarrativeEventProjectResolution<Object> _outcomeResolution(
    NarrativeOutcomeRef outcome,
  ) {
    final resolution = outcomeSources.resolve(outcome);
    final matches = outcomeSources.optionsForOutcome(outcome);
    return NarrativeEventProjectResolution<Object>(
      status: switch (resolution.status) {
        NarrativeOutcomeEventSourceResolutionStatus.found =>
          NarrativeEventProjectResolutionStatus.found,
        NarrativeOutcomeEventSourceResolutionStatus.unavailable =>
          NarrativeEventProjectResolutionStatus.unavailable,
        NarrativeOutcomeEventSourceResolutionStatus.missing =>
          NarrativeEventProjectResolutionStatus.missing,
        NarrativeOutcomeEventSourceResolutionStatus.ambiguous =>
          NarrativeEventProjectResolutionStatus.ambiguous,
      },
      matches: matches,
    );
  }
}

NarrativeEventProjectResolution<T> _resolveIndexed<T>(
  List<T> matches, {
  required bool Function(T entry) available,
}) {
  if (matches.isEmpty) {
    return NarrativeEventProjectResolution(
      status: NarrativeEventProjectResolutionStatus.missing,
    );
  }
  if (matches.length > 1) {
    return NarrativeEventProjectResolution(
      status: NarrativeEventProjectResolutionStatus.ambiguous,
      matches: matches,
    );
  }
  return NarrativeEventProjectResolution(
    status: available(matches.single)
        ? NarrativeEventProjectResolutionStatus.found
        : NarrativeEventProjectResolutionStatus.unavailable,
    matches: matches,
  );
}

Map<String, List<T>> _index<T>(
  List<T> values,
  String Function(T value) idOf,
) {
  final result = <String, List<T>>{};
  for (final value in values) {
    result.putIfAbsent(idOf(value), () => []).add(value);
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<T>.unmodifiable(entry.value),
  });
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

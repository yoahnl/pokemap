import 'dart:convert';

import '../catalogs/narrative_event_project_catalog.dart';
import '../catalogs/narrative_outcome_event_source_catalog.dart';
import '../catalogs/narrative_spatial_event_source_catalog.dart';
import '../compatibility/legacy_map_event_projection.dart';
import '../diagnostics/scene_diagnostics.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'build_narrative_outcome_event_source_catalog.dart';
import 'build_narrative_spatial_event_source_catalog.dart';
import 'narrative_event_canonical_json.dart';

NarrativeEventProjectCatalog buildNarrativeEventProjectCatalog({
  required ProjectManifest project,
  required List<MapData> maps,
  List<LegacyMapEventProjection> legacyProjections = const [],
  List<NarrativeOutcomeRef> referencedOutcomes = const [],
  List<NarrativeEventRecord> proposedRecords = const [],
}) {
  final spatialSources = buildNarrativeSpatialEventSourceCatalog(
    project: project,
    maps: maps,
    legacyProjections: legacyProjections,
  );
  final outcomeSources = buildNarrativeOutcomeEventSourceCatalog(
    project: project,
    maps: maps,
    referencedOutcomes: referencedOutcomes,
  );
  final diagnostics = <NarrativeEventProjectDiagnostic>[];
  _appendSourceCatalogDiagnostics(
    spatialSources: spatialSources,
    outcomeSources: outcomeSources,
    diagnostics: diagnostics,
  );
  final mapsById = {for (final map in maps) map.id: map};
  final scenes = [
    for (final scene in project.scenes)
      NarrativeEventProjectSceneEntry(
        scene: scene,
        buildable: buildSceneRuntimePlan(scene).canBuild &&
            diagnoseSceneAgainstProject(
                  scene,
                  project,
                  mapsById: mapsById,
                ).errorCount ==
                0,
      ),
  ]..sort(_compareScenes);
  final facts = [
    for (final fact in project.facts) NarrativeEventProjectFactEntry(fact),
  ]..sort(_compareFacts);

  _recordDuplicates(
    values: scenes,
    idOf: (entry) => entry.scene.id,
    code: 'duplicateSceneId',
    label: 'Scene',
    path: 'scenes',
    diagnostics: diagnostics,
  );
  for (final entry in scenes) {
    if (!entry.buildable) {
      diagnostics.add(
        NarrativeEventProjectDiagnostic(
          code: 'sceneNotBuildable',
          severity: NarrativeEventProjectDiagnosticSeverity.error,
          message: 'Cette Scene n’est pas exécutable dans le projet actuel.',
          path: 'scenes.${entry.scene.id}',
        ),
      );
    }
  }
  _recordDuplicates(
    values: facts,
    idOf: (entry) => entry.fact.id,
    code: 'duplicateFactId',
    label: 'Fact',
    path: 'facts',
    diagnostics: diagnostics,
  );

  final existingRecords = project.eventRegistry?.records ?? const [];
  final allRecords = <_ProjectRecordInput>[
    for (final record in existingRecords)
      _ProjectRecordInput(record: record, proposed: false),
    for (final record in proposedRecords)
      _ProjectRecordInput(record: record, proposed: true),
  ];
  final recordsById = <String, List<_ProjectRecordInput>>{};
  for (final input in allRecords) {
    recordsById.putIfAbsent(input.record.id, () => []).add(input);
  }
  final cycleIds = _dependencyCycleIds(
    allRecords.map((entry) => entry.record),
  );
  final scenesById = _groupBy(scenes, (entry) => entry.scene.id);
  final factsById = _groupBy(facts, (entry) => entry.fact.id);
  final dependencies = <_ProjectRecordInput, List<_EventDependency>>{};
  final validity = <_ProjectRecordInput, bool>{};
  for (final input in allRecords) {
    final record = input.record;
    var valid =
        recordsById[record.id]!.length == 1 && !cycleIds.contains(record.id);
    final definition = record.definitionOrNull;
    if (definition == null) {
      valid = false;
      if (input.proposed) {
        _recordEventIssue(
          diagnostics: diagnostics,
          code: 'proposedNarrativeEventDraft',
          message: 'Un Event proposé doit être entièrement configuré.',
          eventId: record.id,
        );
      }
      validity[input] = valid;
      dependencies[input] = const [];
      continue;
    }
    if (input.proposed && record.enabledOrNull == true) {
      valid = false;
      _recordEventIssue(
        diagnostics: diagnostics,
        code: 'proposedNarrativeEventEnabled',
        message: 'Un Event proposé par la migration doit rester désactivé.',
        eventId: record.id,
      );
    }
    final sourceStatus = _resolveSource(
      definition.source,
      spatialSources: spatialSources,
      outcomeSources: outcomeSources,
    );
    if (sourceStatus != NarrativeEventProjectResolutionStatus.found) {
      valid = false;
      _recordEventIssue(
        diagnostics: diagnostics,
        code: switch (sourceStatus) {
          NarrativeEventProjectResolutionStatus.missing =>
            'narrativeEventSourceMissing',
          NarrativeEventProjectResolutionStatus.unavailable =>
            'narrativeEventSourceUnavailable',
          NarrativeEventProjectResolutionStatus.ambiguous =>
            'narrativeEventSourceAmbiguous',
          NarrativeEventProjectResolutionStatus.found =>
            throw StateError('A found source cannot be invalid.'),
        },
        message: 'La source de cet Event ne résout pas une option utilisable.',
        eventId: record.id,
        suffix: 'source',
      );
    }
    final sceneMatches = scenesById[definition.sceneId] ?? const [];
    if (sceneMatches.length != 1 || !sceneMatches.single.buildable) {
      valid = false;
      _recordEventIssue(
        diagnostics: diagnostics,
        code: sceneMatches.isEmpty
            ? 'narrativeEventSceneMissing'
            : sceneMatches.length > 1
                ? 'narrativeEventSceneAmbiguous'
                : 'narrativeEventSceneUnavailable',
        message: 'La Scene de cet Event doit être unique et exécutable.',
        eventId: record.id,
        suffix: 'sceneId',
      );
    }
    final eventDependencies = <_EventDependency>[];
    for (var index = 0; index < definition.conditions.length; index++) {
      definition.conditions[index].when<void>(
        fact: (factId, _) {
          final matches = factsById[factId] ?? const [];
          if (matches.length == 1) return;
          valid = false;
          _recordEventIssue(
            diagnostics: diagnostics,
            code: matches.isEmpty
                ? 'narrativeEventFactMissing'
                : 'narrativeEventFactAmbiguous',
            message: 'Le Fact référencé doit exister exactement une fois.',
            eventId: record.id,
            suffix: 'conditions.$index.factId',
          );
        },
        narrativeEventConsumed: (eventId, _) {
          eventDependencies.add(
            _EventDependency(eventId: eventId, conditionIndex: index),
          );
        },
      );
    }
    validity[input] = valid;
    dependencies[input] = List.unmodifiable(eventDependencies);
  }

  var changed = true;
  while (changed) {
    changed = false;
    for (final input in allRecords) {
      if (validity[input] != true) continue;
      for (final dependency in dependencies[input]!) {
        final matches = recordsById[dependency.eventId] ?? const [];
        if (matches.length != 1 || validity[matches.single] != true) {
          validity[input] = false;
          changed = true;
          break;
        }
      }
    }
  }

  for (final input in allRecords) {
    final record = input.record;
    for (var index = 0; index < (dependencies[input]?.length ?? 0); index++) {
      final dependency = dependencies[input]![index];
      final matches = recordsById[dependency.eventId] ?? const [];
      if (matches.length == 1 && validity[matches.single] == true) continue;
      _recordEventIssue(
        diagnostics: diagnostics,
        code: matches.isEmpty
            ? 'narrativeEventReferenceMissing'
            : matches.length > 1
                ? 'narrativeEventReferenceAmbiguous'
                : 'narrativeEventReferenceUnavailable',
        message:
            'L’Event référencé doit être unique, configuré et contextuellement valide.',
        eventId: record.id,
        suffix: 'conditions.${dependency.conditionIndex}.eventId',
      );
    }
  }

  final events = [
    for (final value in allRecords)
      NarrativeEventProjectEventEntry(
        record: value.record,
        proposed: value.proposed,
        inDependencyCycle: cycleIds.contains(value.record.id),
        contextuallyValid: validity[value] == true,
      ),
  ]..sort(_compareEvents);
  _recordDuplicates(
    values: events,
    idOf: (entry) => entry.record.id,
    code: 'duplicateNarrativeEventId',
    label: 'Event',
    path: 'eventRegistry.records',
    diagnostics: diagnostics,
  );
  for (final eventId in cycleIds.toList()..sort(compareNarrativeEventUtf16)) {
    diagnostics.add(
      NarrativeEventProjectDiagnostic(
        code: 'narrativeEventDependencyCycle',
        severity: NarrativeEventProjectDiagnosticSeverity.error,
        message: 'Cet Event participe à un cycle de conditions Event.',
        path: 'eventRegistry.records.$eventId.conditions',
      ),
    );
  }

  diagnostics.sort(_compareDiagnostics);
  return NarrativeEventProjectCatalog(
    manifestHash: _jsonFingerprint(project.toJson()),
    mapHashes: {
      for (final map in maps) map.id: _jsonFingerprint(map.toJson()),
    },
    spatialSources: spatialSources,
    outcomeSources: outcomeSources,
    scenes: scenes,
    facts: facts,
    events: events,
    diagnostics: diagnostics,
  );
}

void _appendSourceCatalogDiagnostics({
  required NarrativeSpatialEventSourceCatalog spatialSources,
  required NarrativeOutcomeEventSourceCatalog outcomeSources,
  required List<NarrativeEventProjectDiagnostic> diagnostics,
}) {
  const blockingSpatialCodes = {
    'duplicateEntityId',
    'duplicateManifestMapId',
    'duplicateMapData',
    'duplicateTriggerId',
    'invalidMapIdentityOrSize',
    'missingMapData',
    'orphanMapData',
  };
  for (final diagnostic in spatialSources.diagnostics) {
    diagnostics.add(
      NarrativeEventProjectDiagnostic(
        code: 'spatial.${diagnostic.code}',
        severity: blockingSpatialCodes.contains(diagnostic.code)
            ? NarrativeEventProjectDiagnosticSeverity.error
            : NarrativeEventProjectDiagnosticSeverity.warning,
        message: diagnostic.message,
        path: diagnostic.ownerId == null
            ? 'maps.${diagnostic.mapId}'
            : 'maps.${diagnostic.mapId}.${diagnostic.ownerId}',
      ),
    );
  }

  const blockingOutcomeCodes = {
    'duplicateProducerId',
    'invalidOutcomeIdentity',
    'sceneMapDataUnavailable',
    'sceneNotBuildable',
    'sceneProjectReferencesInvalid',
  };
  for (var index = 0; index < outcomeSources.diagnostics.length; index++) {
    final diagnostic = outcomeSources.diagnostics[index];
    diagnostics.add(
      NarrativeEventProjectDiagnostic(
        code: 'outcome.${diagnostic.code}',
        severity: blockingOutcomeCodes.contains(diagnostic.code)
            ? NarrativeEventProjectDiagnosticSeverity.error
            : NarrativeEventProjectDiagnosticSeverity.warning,
        message: diagnostic.message,
        path: diagnostic.outcome == null
            ? 'outcomes.$index'
            : 'outcomes.${_outcomePath(diagnostic.outcome!)}',
      ),
    );
  }
}

NarrativeEventProjectResolutionStatus _resolveSource(
  NarrativeEventSourceRef source, {
  required NarrativeSpatialEventSourceCatalog spatialSources,
  required NarrativeOutcomeEventSourceCatalog outcomeSources,
}) {
  return source.when(
    entityInteract: (_, __) =>
        _spatialStatus(spatialSources.resolve(source).status),
    triggerEnter: (_, __) =>
        _spatialStatus(spatialSources.resolve(source).status),
    mapEnter: (_) => _spatialStatus(spatialSources.resolve(source).status),
    outcomeReceived: (outcome) =>
        _outcomeStatus(outcomeSources.resolve(outcome).status),
  );
}

NarrativeEventProjectResolutionStatus _spatialStatus(
  NarrativeSpatialEventSourceResolutionStatus status,
) {
  return switch (status) {
    NarrativeSpatialEventSourceResolutionStatus.found =>
      NarrativeEventProjectResolutionStatus.found,
    NarrativeSpatialEventSourceResolutionStatus.unavailable =>
      NarrativeEventProjectResolutionStatus.unavailable,
    NarrativeSpatialEventSourceResolutionStatus.missing =>
      NarrativeEventProjectResolutionStatus.missing,
    NarrativeSpatialEventSourceResolutionStatus.ambiguous =>
      NarrativeEventProjectResolutionStatus.ambiguous,
  };
}

NarrativeEventProjectResolutionStatus _outcomeStatus(
  NarrativeOutcomeEventSourceResolutionStatus status,
) {
  return switch (status) {
    NarrativeOutcomeEventSourceResolutionStatus.found =>
      NarrativeEventProjectResolutionStatus.found,
    NarrativeOutcomeEventSourceResolutionStatus.unavailable =>
      NarrativeEventProjectResolutionStatus.unavailable,
    NarrativeOutcomeEventSourceResolutionStatus.missing =>
      NarrativeEventProjectResolutionStatus.missing,
    NarrativeOutcomeEventSourceResolutionStatus.ambiguous =>
      NarrativeEventProjectResolutionStatus.ambiguous,
  };
}

void _recordEventIssue({
  required List<NarrativeEventProjectDiagnostic> diagnostics,
  required String code,
  required String message,
  required String eventId,
  String? suffix,
}) {
  diagnostics.add(
    NarrativeEventProjectDiagnostic(
      code: code,
      severity: NarrativeEventProjectDiagnosticSeverity.error,
      message: message,
      path: suffix == null
          ? 'eventRegistry.records.$eventId'
          : 'eventRegistry.records.$eventId.$suffix',
    ),
  );
}

Map<String, List<T>> _groupBy<T>(
  Iterable<T> values,
  String Function(T value) idOf,
) {
  final result = <String, List<T>>{};
  for (final value in values) {
    result.putIfAbsent(idOf(value), () => []).add(value);
  }
  return result;
}

String _outcomePath(NarrativeOutcomeRef outcome) =>
    '${outcome.producerKind.name}.${outcome.producerId}.${outcome.outcomeId}';

String _jsonFingerprint(Object? value) =>
    'sha256:${narrativeEventCanonicalSha256(jsonDecode(jsonEncode(value)))}';

final class _ProjectRecordInput {
  const _ProjectRecordInput({
    required this.record,
    required this.proposed,
  });

  final NarrativeEventRecord record;
  final bool proposed;
}

final class _EventDependency {
  const _EventDependency({
    required this.eventId,
    required this.conditionIndex,
  });

  final String eventId;
  final int conditionIndex;
}

void _recordDuplicates<T>({
  required List<T> values,
  required String Function(T value) idOf,
  required String code,
  required String label,
  required String path,
  required List<NarrativeEventProjectDiagnostic> diagnostics,
}) {
  final counts = <String, int>{};
  for (final value in values) {
    counts.update(idOf(value), (count) => count + 1, ifAbsent: () => 1);
  }
  final duplicateIds = [
    for (final entry in counts.entries)
      if (entry.value > 1) entry.key,
  ]..sort(compareNarrativeEventUtf16);
  for (final id in duplicateIds) {
    diagnostics.add(
      NarrativeEventProjectDiagnostic(
        code: code,
        severity: NarrativeEventProjectDiagnosticSeverity.error,
        message: 'Plusieurs $label utilisent le même identifiant.',
        path: '$path.$id',
      ),
    );
  }
}

Set<String> _dependencyCycleIds(Iterable<NarrativeEventRecord> records) {
  final byId = <String, List<NarrativeEventRecord>>{};
  for (final record in records) {
    byId.putIfAbsent(record.id, () => []).add(record);
  }
  final graph = <String, Set<String>>{};
  for (final entry in byId.entries) {
    if (entry.value.length != 1) continue;
    final definition = entry.value.single.definitionOrNull;
    if (definition == null) continue;
    graph[entry.key] = {
      for (final condition in definition.conditions)
        ...condition.whenTyped(
          fact: (_, __, ___) => const <String>[],
          narrativeEventConsumed: (eventId, _) => [eventId],
        ),
    };
  }

  final state = <String, int>{};
  final stack = <String>[];
  final cycles = <String>{};

  void visit(String eventId) {
    final current = state[eventId] ?? 0;
    if (current == 2) return;
    if (current == 1) {
      final start = stack.lastIndexOf(eventId);
      if (start >= 0) cycles.addAll(stack.sublist(start));
      return;
    }
    state[eventId] = 1;
    stack.add(eventId);
    final targets = graph[eventId]?.toList() ?? const <String>[];
    targets.sort(compareNarrativeEventUtf16);
    for (final target in targets) {
      if (graph.containsKey(target)) visit(target);
    }
    stack.removeLast();
    state[eventId] = 2;
  }

  final ids = graph.keys.toList()..sort(compareNarrativeEventUtf16);
  for (final id in ids) {
    visit(id);
  }
  return cycles;
}

int _compareScenes(
  NarrativeEventProjectSceneEntry left,
  NarrativeEventProjectSceneEntry right,
) {
  return _compareWithFallback(
    [
      compareNarrativeEventUtf16(left.scene.id, right.scene.id),
      compareNarrativeEventUtf16(left.scene.name, right.scene.name),
    ],
    left.scene.toJson(),
    right.scene.toJson(),
  );
}

int _compareFacts(
  NarrativeEventProjectFactEntry left,
  NarrativeEventProjectFactEntry right,
) {
  return _compareWithFallback(
    [
      compareNarrativeEventUtf16(left.fact.id, right.fact.id),
      compareNarrativeEventUtf16(left.fact.label, right.fact.label),
    ],
    left.fact.toJson(),
    right.fact.toJson(),
  );
}

int _compareEvents(
  NarrativeEventProjectEventEntry left,
  NarrativeEventProjectEventEntry right,
) {
  return _compareWithFallback(
    [
      compareNarrativeEventUtf16(left.record.id, right.record.id),
      left.proposed == right.proposed ? 0 : (left.proposed ? 1 : -1),
    ],
    left.record.toJson(),
    right.record.toJson(),
  );
}

int _compareWithFallback(
  List<int> comparisons,
  Object? left,
  Object? right,
) {
  for (final comparison in comparisons) {
    if (comparison != 0) return comparison;
  }
  return _safeSortKey(left).compareTo(_safeSortKey(right));
}

String _safeSortKey(Object? value) {
  try {
    return canonicalizeNarrativeEventJson(value);
  } on FormatException {
    return value.toString();
  }
}

int _compareDiagnostics(
  NarrativeEventProjectDiagnostic left,
  NarrativeEventProjectDiagnostic right,
) {
  for (final comparison in [
    compareNarrativeEventUtf16(left.path, right.path),
    compareNarrativeEventUtf16(left.code, right.code),
    left.severity.index.compareTo(right.severity.index),
    compareNarrativeEventUtf16(left.message, right.message),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

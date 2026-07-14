import '../catalogs/narrative_event_project_catalog.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'narrative_event_authoring_contract.dart';

NarrativeEventAuthoringDiagnostic? validateNarrativeEventAuthoringName(
  String name,
) {
  final normalized = name.trim();
  if (normalized.isEmpty) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'emptyName',
      message: 'Le nom de l’Event doit être renseigné.',
      path: 'name',
    );
  }
  try {
    canonicalizeNarrativeEventJson({'name': normalized});
  } on FormatException {
    return NarrativeEventAuthoringDiagnostic(
      code: 'invalidNameEncoding',
      message:
          'Le nom contient des caractères qui ne peuvent pas être enregistrés.',
      path: 'name',
    );
  }
  return null;
}

NarrativeEventAuthoringDiagnostic? validateNarrativeEventAuthoringInteger({
  required int value,
  required bool nonNegative,
  required String path,
}) {
  if (nonNegative && value < 0) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'invalidOrder',
      message: 'L’ordre doit être supérieur ou égal à zéro.',
      path: path,
    );
  }
  try {
    canonicalizeNarrativeEventJson({path: value});
  } on FormatException {
    return NarrativeEventAuthoringDiagnostic(
      code: 'numericOverflow',
      message: 'Cette valeur entière ne peut pas être enregistrée exactement.',
      path: path,
    );
  }
  return null;
}

NarrativeEventAuthoringDiagnostic? validateNarrativeEventAuthoringSource({
  required NarrativeEventAuthoringContext context,
  required NarrativeEventSourceRef source,
}) {
  final resolution = context.catalog.resolveSource(source);
  return switch (resolution.status) {
    NarrativeEventProjectResolutionStatus.found => null,
    NarrativeEventProjectResolutionStatus.missing =>
      NarrativeEventAuthoringDiagnostic(
        code: 'sourceMissing',
        message: 'La source de cet événement n’existe plus.',
        path: 'source',
      ),
    NarrativeEventProjectResolutionStatus.unavailable =>
      NarrativeEventAuthoringDiagnostic(
        code: 'sourceUnavailable',
        message: 'La source de cet événement n’est pas disponible.',
        path: 'source',
      ),
    NarrativeEventProjectResolutionStatus.ambiguous =>
      NarrativeEventAuthoringDiagnostic(
        code: 'sourceAmbiguous',
        message: 'La source de cet événement n’est pas unique.',
        path: 'source',
      ),
  };
}

NarrativeEventAuthoringDiagnostic? validateNarrativeEventAuthoringScene({
  required NarrativeEventAuthoringContext context,
  required String sceneId,
}) {
  if (sceneId.isEmpty || sceneId.trim() != sceneId) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'invalidSceneId',
      message: 'La Scene choisie possède un identifiant invalide.',
      path: 'sceneId',
    );
  }
  try {
    canonicalizeNarrativeEventJson({'sceneId': sceneId});
  } on FormatException {
    return NarrativeEventAuthoringDiagnostic(
      code: 'invalidSceneId',
      message: 'La Scene choisie possède un identifiant invalide.',
      path: 'sceneId',
    );
  }
  final resolution = context.catalog.resolveScene(sceneId);
  return switch (resolution.status) {
    NarrativeEventProjectResolutionStatus.found => null,
    NarrativeEventProjectResolutionStatus.missing =>
      NarrativeEventAuthoringDiagnostic(
        code: 'sceneMissing',
        message: 'La Scene choisie n’existe plus.',
        path: 'sceneId',
      ),
    NarrativeEventProjectResolutionStatus.unavailable =>
      NarrativeEventAuthoringDiagnostic(
        code: 'sceneUnavailable',
        message: 'La Scene choisie ne peut pas être exécutée.',
        path: 'sceneId',
      ),
    NarrativeEventProjectResolutionStatus.ambiguous =>
      NarrativeEventAuthoringDiagnostic(
        code: 'sceneAmbiguous',
        message: 'La Scene choisie n’est pas unique.',
        path: 'sceneId',
      ),
  };
}

NarrativeEventAuthoringDiagnostic? validateNarrativeEventAuthoringConditions({
  required NarrativeEventAuthoringContext context,
  required String eventId,
  required List<NarrativeEventCondition> conditions,
}) {
  for (var index = 0; index < conditions.length; index++) {
    final issue = conditions[index].when<NarrativeEventAuthoringDiagnostic?>(
      fact: (factId, _) {
        final resolution = context.catalog.resolveFact(factId);
        return switch (resolution.status) {
          NarrativeEventProjectResolutionStatus.found => null,
          NarrativeEventProjectResolutionStatus.missing =>
            NarrativeEventAuthoringDiagnostic(
              code: 'factMissing',
              message: 'Le Fact référencé n’existe plus.',
              path: 'conditions.$index.factId',
            ),
          NarrativeEventProjectResolutionStatus.unavailable =>
            NarrativeEventAuthoringDiagnostic(
              code: 'factUnavailable',
              message: 'Le Fact référencé n’est pas disponible.',
              path: 'conditions.$index.factId',
            ),
          NarrativeEventProjectResolutionStatus.ambiguous =>
            NarrativeEventAuthoringDiagnostic(
              code: 'factAmbiguous',
              message: 'Le Fact référencé n’est pas unique.',
              path: 'conditions.$index.factId',
            ),
        };
      },
      narrativeEventConsumed: (targetEventId, _) {
        if (targetEventId == eventId) {
          return NarrativeEventAuthoringDiagnostic(
            code: 'selfReference',
            message: 'Un événement ne peut pas dépendre de lui-même.',
            path: 'conditions.$index.eventId',
          );
        }
        final resolution = context.catalog.resolveEvent(targetEventId);
        return switch (resolution.status) {
          NarrativeEventProjectResolutionStatus.found => null,
          NarrativeEventProjectResolutionStatus.missing =>
            NarrativeEventAuthoringDiagnostic(
              code: 'eventReferenceMissing',
              message: 'L’événement référencé n’existe plus.',
              path: 'conditions.$index.eventId',
            ),
          NarrativeEventProjectResolutionStatus.unavailable =>
            NarrativeEventAuthoringDiagnostic(
              code: 'eventReferenceUnavailable',
              message: 'L’événement référencé doit être configuré et valide.',
              path: 'conditions.$index.eventId',
            ),
          NarrativeEventProjectResolutionStatus.ambiguous =>
            NarrativeEventAuthoringDiagnostic(
              code: 'eventReferenceAmbiguous',
              message: 'L’événement référencé n’est pas unique.',
              path: 'conditions.$index.eventId',
            ),
        };
      },
    );
    if (issue != null) return issue;
  }
  if (_projectedDependencyCycleIds(
    context: context,
    eventId: eventId,
    conditions: conditions,
  ).contains(eventId)) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'eventDependencyCycle',
      message: 'Ces conditions créeraient un cycle entre événements.',
      path: 'conditions',
    );
  }
  return null;
}

bool narrativeEventRepairStrictlyReducesCatalogErrors({
  required NarrativeEventAuthoringContext context,
  required NarrativeEventRecord nextRecord,
}) {
  final blockingDiagnostics = [
    for (final diagnostic in context.catalog.diagnostics)
      if (diagnostic.severity == NarrativeEventProjectDiagnosticSeverity.error)
        diagnostic,
  ];
  if (blockingDiagnostics.isEmpty ||
      blockingDiagnostics.any(
        (diagnostic) => !_repairableEventDiagnosticCodes.contains(
          diagnostic.code,
        ),
      )) {
    return false;
  }
  final registry = context.registryOrNull;
  if (registry == null) return false;
  final nextRecords = [
    for (final record in registry.records)
      if (record.id == nextRecord.id) nextRecord else record,
  ];
  final before = _projectEventIssueCounts(
    catalog: context.catalog,
    records: registry.records,
  );
  final after = _projectEventIssueCounts(
    catalog: context.catalog,
    records: nextRecords,
  );
  if (after.length > before.length) return false;
  var beforeTotal = 0;
  var afterTotal = 0;
  for (final count in before.values) {
    beforeTotal += count;
  }
  for (final entry in after.entries) {
    afterTotal += entry.value;
    if (entry.value > (before[entry.key] ?? 0)) return false;
  }
  return afterTotal < beforeTotal;
}

Map<String, int> _projectEventIssueCounts({
  required NarrativeEventProjectCatalog catalog,
  required List<NarrativeEventRecord> records,
}) {
  final configuredById = <String, NarrativeEventRecord>{};
  for (final record in records) {
    if (record.definitionOrNull != null) configuredById[record.id] = record;
  }
  final issues = <String, int>{};
  final dependencies = <String, List<String>>{};
  final directlyValid = <String, bool>{};
  void recordIssue(String key) {
    issues.update(key, (count) => count + 1, ifAbsent: () => 1);
  }

  for (final entry in configuredById.entries) {
    final eventId = entry.key;
    final definition = entry.value.definitionOrNull!;
    var valid = true;
    final sourceStatus = catalog.resolveSource(definition.source).status;
    if (sourceStatus != NarrativeEventProjectResolutionStatus.found) {
      valid = false;
      recordIssue('$eventId|source|${sourceStatus.name}');
    }
    final sceneStatus = catalog.resolveScene(definition.sceneId).status;
    if (sceneStatus != NarrativeEventProjectResolutionStatus.found) {
      valid = false;
      recordIssue('$eventId|scene|${sceneStatus.name}');
    }
    final eventDependencies = <String>[];
    for (final condition in definition.conditions) {
      condition.when<void>(
        fact: (factId, _) {
          final factStatus = catalog.resolveFact(factId).status;
          if (factStatus != NarrativeEventProjectResolutionStatus.found) {
            valid = false;
            recordIssue('$eventId|fact|$factId|${factStatus.name}');
          }
        },
        narrativeEventConsumed: (targetId, _) {
          eventDependencies.add(targetId);
          if (!configuredById.containsKey(targetId)) {
            valid = false;
            recordIssue('$eventId|event|$targetId|unavailable');
          }
        },
      );
    }
    dependencies[eventId] = eventDependencies;
    directlyValid[eventId] = valid;
  }

  final cycleIds = _cycleIds(dependencies);
  for (final eventId in cycleIds) {
    directlyValid[eventId] = false;
    recordIssue('$eventId|cycle');
  }
  final valid = Map<String, bool>.from(directlyValid);
  var changed = true;
  while (changed) {
    changed = false;
    for (final eventId in configuredById.keys) {
      if (valid[eventId] != true) continue;
      if (dependencies[eventId]!.any((targetId) => valid[targetId] != true)) {
        valid[eventId] = false;
        changed = true;
      }
    }
  }
  for (final entry in dependencies.entries) {
    for (final targetId in entry.value) {
      if (configuredById.containsKey(targetId) && valid[targetId] != true) {
        recordIssue('${entry.key}|event|$targetId|invalid');
      }
    }
  }
  return issues;
}

Set<String> _cycleIds(Map<String, List<String>> dependencies) {
  final graph = <String, List<String>>{
    for (final entry in dependencies.entries)
      entry.key: [
        for (final target in entry.value)
          if (dependencies.containsKey(target)) target,
      ]..sort(compareNarrativeEventUtf16),
  };
  final orderedNodes = graph.keys.toList()..sort(compareNarrativeEventUtf16);
  final visited = <String>{};
  final finishOrder = <String>[];
  for (final start in orderedNodes) {
    if (!visited.add(start)) continue;
    final stack = <_DepthFrame>[_DepthFrame(start, graph[start]!)];
    while (stack.isNotEmpty) {
      final frame = stack.last;
      if (frame.nextIndex < frame.targets.length) {
        final target = frame.targets[frame.nextIndex++];
        if (visited.add(target)) {
          stack.add(_DepthFrame(target, graph[target]!));
        }
      } else {
        finishOrder.add(frame.eventId);
        stack.removeLast();
      }
    }
  }
  final reverse = {for (final node in orderedNodes) node: <String>[]};
  for (final entry in graph.entries) {
    for (final target in entry.value) {
      reverse[target]!.add(entry.key);
    }
  }
  final assigned = <String>{};
  final cycles = <String>{};
  for (final start in finishOrder.reversed) {
    if (!assigned.add(start)) continue;
    final component = <String>[];
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      component.add(current);
      for (final target in reverse[current]!) {
        if (assigned.add(target)) stack.add(target);
      }
    }
    if (component.length > 1 || graph[start]!.contains(start)) {
      cycles.addAll(component);
    }
  }
  return cycles;
}

const _repairableEventDiagnosticCodes = {
  'narrativeEventSourceMissing',
  'narrativeEventSourceUnavailable',
  'narrativeEventSourceAmbiguous',
  'narrativeEventSceneMissing',
  'narrativeEventSceneUnavailable',
  'narrativeEventSceneAmbiguous',
  'narrativeEventFactMissing',
  'narrativeEventFactAmbiguous',
  'narrativeEventReferenceMissing',
  'narrativeEventReferenceUnavailable',
  'narrativeEventReferenceAmbiguous',
  'narrativeEventDependencyCycle',
};

NarrativeEventAuthoringDiagnostic? firstBlockingNarrativeEventCatalogIssue(
  NarrativeEventAuthoringContext context, {
  bool Function(NarrativeEventProjectDiagnostic diagnostic)? repairable,
}) {
  for (final diagnostic in context.catalog.diagnostics) {
    if (diagnostic.severity == NarrativeEventProjectDiagnosticSeverity.error &&
        !(repairable?.call(diagnostic) ?? false)) {
      return NarrativeEventAuthoringDiagnostic(
        code: 'catalogBlocked',
        message:
            'Le projet contient des références à corriger avant cette action.',
        path: diagnostic.path,
      );
    }
  }
  return null;
}

Set<String> _projectedDependencyCycleIds({
  required NarrativeEventAuthoringContext context,
  required String eventId,
  required List<NarrativeEventCondition> conditions,
}) {
  final graph = <String, List<String>>{};
  for (final record
      in context.registryOrNull?.records ?? const <NarrativeEventRecord>[]) {
    final definition = record.definitionOrNull;
    if (definition == null && record.id != eventId) continue;
    final effectiveConditions =
        record.id == eventId ? conditions : definition!.conditions;
    graph[record.id] = _eventDependencies(effectiveConditions);
  }
  graph.putIfAbsent(eventId, () => _eventDependencies(conditions));
  final nodes = graph.keys.toSet();
  for (final entry in graph.entries) {
    entry.value.removeWhere((target) => !nodes.contains(target));
    entry.value.sort(compareNarrativeEventUtf16);
  }
  final orderedNodes = graph.keys.toList()..sort(compareNarrativeEventUtf16);
  final visited = <String>{};
  final finishOrder = <String>[];
  for (final start in orderedNodes) {
    if (!visited.add(start)) continue;
    final stack = <_DepthFrame>[_DepthFrame(start, graph[start]!)];
    while (stack.isNotEmpty) {
      final frame = stack.last;
      if (frame.nextIndex < frame.targets.length) {
        final target = frame.targets[frame.nextIndex++];
        if (visited.add(target)) {
          stack.add(_DepthFrame(target, graph[target]!));
        }
      } else {
        finishOrder.add(frame.eventId);
        stack.removeLast();
      }
    }
  }
  final reverse = {for (final node in orderedNodes) node: <String>[]};
  for (final entry in graph.entries) {
    for (final target in entry.value) {
      reverse[target]!.add(entry.key);
    }
  }
  for (final targets in reverse.values) {
    targets.sort(compareNarrativeEventUtf16);
  }
  final assigned = <String>{};
  final cycles = <String>{};
  for (final start in finishOrder.reversed) {
    if (!assigned.add(start)) continue;
    final component = <String>[];
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      component.add(current);
      for (final target in reverse[current]!.reversed) {
        if (assigned.add(target)) stack.add(target);
      }
    }
    if (component.length > 1 || graph[start]!.contains(start)) {
      cycles.addAll(component);
    }
  }
  return cycles;
}

List<String> _eventDependencies(List<NarrativeEventCondition> conditions) {
  return [
    for (final condition in conditions)
      ...condition.when(
        fact: (_, __) => const <String>[],
        narrativeEventConsumed: (eventId, _) => [eventId],
      ),
  ];
}

final class _DepthFrame {
  _DepthFrame(this.eventId, this.targets);

  final String eventId;
  final List<String> targets;
  int nextIndex = 0;
}

import 'package:meta/meta.dart' show immutable;

import '../catalogs/narrative_spatial_event_source_catalog.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';
import '../operations/build_narrative_spatial_event_source_catalog.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'narrative_event_builder_project_read_model.dart';

enum NarrativeMapSourceLinkState { none, one, multiple, unavailable }

enum NarrativeMapEventLinkState {
  linked,
  sourceMissing,
  noSpatialSource,
  crossMap,
  priorityConflict,
}

enum NarrativeMapEventsDiagnosticSeverity { info, warning, error }

/// One actionable issue local to the Map Events projection.
@immutable
final class NarrativeMapEventsDiagnostic {
  const NarrativeMapEventsDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
    this.sourceStableKey,
    this.eventId,
  });

  final String code;
  final String message;
  final NarrativeMapEventsDiagnosticSeverity severity;
  final String? sourceStableKey;
  final String? eventId;
}

/// A physical owner from the Map Editor and its exact Event V2 consumers.
@immutable
final class NarrativeMapEventSourceRow {
  NarrativeMapEventSourceRow({
    required this.stableKey,
    required this.option,
    required List<String> eventIds,
    required this.linkState,
    required this.hasPriorityConflict,
  }) : eventIds = List.unmodifiable(eventIds);

  final String stableKey;
  final NarrativeSpatialEventSourceOption option;
  final List<String> eventIds;
  final NarrativeMapSourceLinkState linkState;
  final bool hasPriorityConflict;
}

/// Event-facing row used by the list and the synchronized inspector.
@immutable
final class NarrativeMapEventRow {
  NarrativeMapEventRow({
    required this.stableKey,
    required this.summary,
    required this.state,
    required this.sourceStableKey,
    required this.hasPriorityConflict,
    required List<String> factIds,
  }) : factIds = List.unmodifiable(factIds);

  final String stableKey;
  final NarrativeEventProjectSummary summary;
  final NarrativeMapEventLinkState state;
  final String? sourceStableKey;
  final bool hasPriorityConflict;
  final List<String> factIds;

  String? get eventId => summary.eventId;
}

/// Canonical World Rule whose target belongs to one map.
@immutable
final class NarrativeMapWorldRuleRow {
  const NarrativeMapWorldRuleRow({
    required this.stableKey,
    required this.rule,
    required this.targetAvailable,
    required this.sourceStableKey,
  });

  final String stableKey;
  final WorldRuleDefinition rule;
  final bool targetAvailable;
  final String? sourceStableKey;

  String get ruleId => rule.id;
  String? get sourceFactId => rule.source.kind == WorldRuleSourceKind.fact
      ? rule.source.sourceId
      : null;
}

@immutable
final class NarrativeMapEventsMapSummary {
  NarrativeMapEventsMapSummary({
    required this.mapId,
    required this.mapLabel,
    required List<NarrativeMapEventSourceRow> sources,
    required List<NarrativeMapEventRow> events,
    required List<NarrativeMapWorldRuleRow> worldRules,
    required List<NarrativeMapEventsDiagnostic> diagnostics,
  })  : sources = List.unmodifiable(sources),
        events = List.unmodifiable(events),
        worldRules = List.unmodifiable(worldRules),
        diagnostics = List.unmodifiable(diagnostics);

  final String mapId;
  final String mapLabel;
  final List<NarrativeMapEventSourceRow> sources;
  final List<NarrativeMapEventRow> events;
  final List<NarrativeMapWorldRuleRow> worldRules;
  final List<NarrativeMapEventsDiagnostic> diagnostics;

  NarrativeMapEventSourceRow? sourceByStableKey(String stableKey) {
    for (final source in sources) {
      if (source.stableKey == stableKey) return source;
    }
    return null;
  }
}

/// Exhaustive project-level projection for the Events > Map Events route.
///
/// It composes the canonical spatial catalog and Event Builder read model. It
/// never reconstructs map identities from coordinates or mutates geometry.
@immutable
final class NarrativeMapEventsReadModel {
  NarrativeMapEventsReadModel({
    required List<NarrativeMapEventsMapSummary> maps,
    required List<NarrativeMapEventRow> unassignedEvents,
    required List<NarrativeMapEventRow> orphanEvents,
  })  : maps = List.unmodifiable(maps),
        unassignedEvents = List.unmodifiable(unassignedEvents),
        orphanEvents = List.unmodifiable(orphanEvents);

  final List<NarrativeMapEventsMapSummary> maps;
  final List<NarrativeMapEventRow> unassignedEvents;
  final List<NarrativeMapEventRow> orphanEvents;

  NarrativeMapEventsMapSummary? mapById(String mapId) {
    for (final map in maps) {
      if (map.mapId == mapId) return map;
    }
    return null;
  }
}

NarrativeMapEventsReadModel buildNarrativeMapEventsReadModel({
  required ProjectManifest project,
  required List<MapData> maps,
}) {
  final eventModel = buildNarrativeEventBuilderProjectReadModel(
    project: project,
    maps: maps,
  );
  final spatialCatalog = buildNarrativeSpatialEventSourceCatalog(
    project: project,
    maps: maps,
  );
  final projectMapIds = {for (final entry in project.maps) entry.id};
  final recordsById = <String, NarrativeEventRecord>{};
  for (final record in project.eventRegistry?.records ?? const []) {
    if (!recordsById.containsKey(record.id)) recordsById[record.id] = record;
  }

  final sourceRowsByMap = <String, List<_MutableSourceRow>>{};
  final sourceRowsByRef = <NarrativeEventSourceRef, List<_MutableSourceRow>>{};
  final stableKeyCounts = <String, int>{};
  for (final option in spatialCatalog.options) {
    final baseKey = 'source:${option.mapId}:${option.debugTechnicalLabel}';
    final occurrence = stableKeyCounts.update(
      baseKey,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    final row = _MutableSourceRow(
      stableKey: occurrence == 1 ? baseKey : '$baseKey#$occurrence',
      option: option,
    );
    sourceRowsByMap.putIfAbsent(option.mapId, () => []).add(row);
    final source = option.source;
    if (source != null) {
      sourceRowsByRef.putIfAbsent(source, () => []).add(row);
    }
  }

  final eventRowsByMap = <String, List<_MutableEventRow>>{};
  final unassigned = <NarrativeMapEventRow>[];
  final orphaned = <NarrativeMapEventRow>[];
  for (final summary in eventModel.events) {
    final source = summary.source.source;
    final record =
        summary.eventId == null ? null : recordsById[summary.eventId];
    final factIds = _factIds(record);
    if (source == null ||
        source.kind == NarrativeEventSourceKind.outcomeReceived) {
      unassigned.add(
        _eventRow(
          summary,
          state: NarrativeMapEventLinkState.noSpatialSource,
          factIds: factIds,
        ),
      );
      continue;
    }
    final mapId = _sourceMapId(source)!;
    if (!projectMapIds.contains(mapId)) {
      orphaned.add(
        _eventRow(
          summary,
          state: NarrativeMapEventLinkState.crossMap,
          factIds: factIds,
        ),
      );
      continue;
    }
    final sourceMatches = sourceRowsByRef[source] ?? const [];
    final exactSource = sourceMatches.length == 1 ? sourceMatches.single : null;
    final state = exactSource == null || !summary.source.available
        ? NarrativeMapEventLinkState.sourceMissing
        : NarrativeMapEventLinkState.linked;
    final row = _MutableEventRow(
      summary: summary,
      state: state,
      source: exactSource,
      factIds: factIds,
    );
    eventRowsByMap.putIfAbsent(mapId, () => []).add(row);
    if (exactSource != null && summary.eventId != null) {
      exactSource.events.add(row);
    }
  }

  final mapDataById = <String, List<MapData>>{};
  for (final map in maps) {
    mapDataById.putIfAbsent(map.id, () => []).add(map);
  }
  final results = <NarrativeMapEventsMapSummary>[];
  for (final entry in project.maps) {
    final mutableSources = <_MutableSourceRow>[
      ...?sourceRowsByMap[entry.id],
    ];
    final mutableEvents = <_MutableEventRow>[
      ...?eventRowsByMap[entry.id],
    ];
    final diagnostics = <NarrativeMapEventsDiagnostic>[];
    for (final source in mutableSources) {
      source.events.sort(_compareMutableEvents);
      final conflicts = _priorityConflicts(source.events);
      source.conflictingEventIds.addAll(conflicts);
      if (conflicts.isNotEmpty) {
        diagnostics.add(
          NarrativeMapEventsDiagnostic(
            code: 'priorityConflict',
            message: 'Plusieurs Events actifs partagent cette source avec la '
                'même priorité et le même ordre.',
            severity: NarrativeMapEventsDiagnosticSeverity.warning,
            sourceStableKey: source.stableKey,
          ),
        );
      }
    }
    mutableEvents.sort(_compareMutableEvents);
    final sourceRows = [for (final source in mutableSources) source.freeze()];
    final eventRows = [for (final event in mutableEvents) event.freeze()];
    final rules = <NarrativeMapWorldRuleRow>[
      for (final rule in project.worldRules)
        if (rule.target.mapId == entry.id)
          _worldRuleRow(
            rule,
            sources: sourceRows,
            events: eventRows,
            maps: mapDataById[entry.id] ?? const [],
          ),
    ]..sort((left, right) => compareNarrativeEventUtf16(
          left.rule.label,
          right.rule.label,
        ));
    for (final event in eventRows) {
      if (event.state == NarrativeMapEventLinkState.sourceMissing) {
        diagnostics.add(
          NarrativeMapEventsDiagnostic(
            code: 'eventSourceMissing',
            message: 'La source physique de ${event.summary.title} est '
                'absente ou ambiguë.',
            severity: NarrativeMapEventsDiagnosticSeverity.error,
            eventId: event.eventId,
          ),
        );
      }
    }
    results.add(
      NarrativeMapEventsMapSummary(
        mapId: entry.id,
        mapLabel: entry.name.trim().isEmpty ? entry.id : entry.name.trim(),
        sources: sourceRows,
        events: eventRows,
        worldRules: rules,
        diagnostics: diagnostics,
      ),
    );
  }
  results.sort((left, right) => compareNarrativeEventUtf16(
        left.mapLabel,
        right.mapLabel,
      ));
  unassigned.sort(_compareFrozenEvents);
  orphaned.sort(_compareFrozenEvents);
  return NarrativeMapEventsReadModel(
    maps: results,
    unassignedEvents: unassigned,
    orphanEvents: orphaned,
  );
}

final class _MutableSourceRow {
  _MutableSourceRow({required this.stableKey, required this.option});

  final String stableKey;
  final NarrativeSpatialEventSourceOption option;
  final List<_MutableEventRow> events = [];
  final Set<String> conflictingEventIds = {};

  NarrativeMapEventSourceRow freeze() => NarrativeMapEventSourceRow(
        stableKey: stableKey,
        option: option,
        eventIds: [
          for (final event in events)
            if (event.summary.eventId != null) event.summary.eventId!,
        ],
        linkState: !option.selectable
            ? NarrativeMapSourceLinkState.unavailable
            : events.isEmpty
                ? NarrativeMapSourceLinkState.none
                : events.length == 1
                    ? NarrativeMapSourceLinkState.one
                    : NarrativeMapSourceLinkState.multiple,
        hasPriorityConflict: conflictingEventIds.isNotEmpty,
      );
}

final class _MutableEventRow {
  _MutableEventRow({
    required this.summary,
    required this.state,
    required this.source,
    required this.factIds,
  });

  final NarrativeEventProjectSummary summary;
  final NarrativeMapEventLinkState state;
  final _MutableSourceRow? source;
  final List<String> factIds;

  NarrativeMapEventRow freeze() {
    final eventId = summary.eventId;
    final conflict = eventId != null &&
        source?.conflictingEventIds.contains(eventId) == true;
    return NarrativeMapEventRow(
      stableKey: 'event:${summary.stableKey}',
      summary: summary,
      state: conflict ? NarrativeMapEventLinkState.priorityConflict : state,
      sourceStableKey: source?.stableKey,
      hasPriorityConflict: conflict,
      factIds: factIds,
    );
  }
}

NarrativeMapEventRow _eventRow(
  NarrativeEventProjectSummary summary, {
  required NarrativeMapEventLinkState state,
  required List<String> factIds,
}) =>
    NarrativeMapEventRow(
      stableKey: 'event:${summary.stableKey}',
      summary: summary,
      state: state,
      sourceStableKey: null,
      hasPriorityConflict: false,
      factIds: factIds,
    );

Set<String> _priorityConflicts(List<_MutableEventRow> events) {
  final active = events.where((event) => event.summary.enabled == true);
  final groups = <(int?, int?), List<_MutableEventRow>>{};
  for (final event in active) {
    final key =
        (event.summary.lifecycle.priority, event.summary.lifecycle.order);
    groups.putIfAbsent(key, () => []).add(event);
  }
  return {
    for (final group in groups.values)
      if (group.length > 1)
        for (final event in group)
          if (event.summary.eventId != null) event.summary.eventId!,
  };
}

NarrativeMapWorldRuleRow _worldRuleRow(
  WorldRuleDefinition rule, {
  required List<NarrativeMapEventSourceRow> sources,
  required List<NarrativeMapEventRow> events,
  required List<MapData> maps,
}) {
  NarrativeMapEventSourceRow? source;
  if (rule.target.entityId != null) {
    for (final candidate in sources) {
      if (candidate.option.ownerId == rule.target.entityId) {
        source = candidate;
        break;
      }
    }
  }
  final targetAvailable = switch (rule.target.kind) {
    WorldRuleTargetKind.mapEntity ||
    WorldRuleTargetKind.npcDialogue =>
      source != null && source.option.selectable,
    WorldRuleTargetKind.mapEvent =>
      events.any((event) => event.eventId == rule.target.eventId) ||
          maps.any(
            (map) => map.events.any((event) => event.id == rule.target.eventId),
          ),
  };
  return NarrativeMapWorldRuleRow(
    stableKey: 'rule:${rule.id}',
    rule: rule,
    targetAvailable: targetAvailable,
    sourceStableKey: source?.stableKey,
  );
}

List<String> _factIds(NarrativeEventRecord? record) {
  final expression = record?.draftOrNull?.conditionExpression ??
      record?.definitionOrNull?.conditionExpression;
  if (expression == null) return const [];
  final ids = <String>{};
  for (final condition in expression.leaves) {
    condition.when(
      fact: (factId, _) => ids.add(factId),
      narrativeEventConsumed: (_, __) {},
    );
  }
  final result = ids.toList()..sort(compareNarrativeEventUtf16);
  return result;
}

String? _sourceMapId(NarrativeEventSourceRef source) => source.when(
      entityInteract: (mapId, _) => mapId,
      triggerEnter: (mapId, _) => mapId,
      mapEnter: (mapId) => mapId,
      outcomeReceived: (_) => null,
    );

int _compareMutableEvents(_MutableEventRow left, _MutableEventRow right) =>
    _compareSummaries(left.summary, right.summary);

int _compareFrozenEvents(
        NarrativeMapEventRow left, NarrativeMapEventRow right) =>
    _compareSummaries(left.summary, right.summary);

int _compareSummaries(
  NarrativeEventProjectSummary left,
  NarrativeEventProjectSummary right,
) {
  final priority =
      (right.lifecycle.priority ?? 0).compareTo(left.lifecycle.priority ?? 0);
  if (priority != 0) return priority;
  final order =
      (left.lifecycle.order ?? 0).compareTo(right.lifecycle.order ?? 0);
  if (order != 0) return order;
  return compareNarrativeEventUtf16(left.stableKey, right.stableKey);
}

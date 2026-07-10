import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../operations/narrative_event_canonical_json.dart';

@immutable
final class NarrativeEventSourceIndex {
  NarrativeEventSourceIndex._(
    Map<NarrativeEventSourceRef, List<NarrativeEventRecord>> recordsBySource,
  ) : _recordsBySource = Map.unmodifiable({
          for (final entry in recordsBySource.entries)
            entry.key: List<NarrativeEventRecord>.unmodifiable(entry.value),
        });

  final Map<NarrativeEventSourceRef, List<NarrativeEventRecord>>
      _recordsBySource;

  Iterable<NarrativeEventSourceRef> get sources => _recordsBySource.keys;

  List<NarrativeEventRecord> recordsFor(NarrativeEventSourceRef source) {
    return _recordsBySource[source] ?? const <NarrativeEventRecord>[];
  }

  bool containsSource(NarrativeEventSourceRef source) {
    return _recordsBySource.containsKey(source);
  }
}

@immutable
final class NarrativeEventSourceConflict {
  NarrativeEventSourceConflict({
    required this.source,
    required this.priority,
    required this.order,
    required List<NarrativeEventRecord> records,
  }) : records = List.unmodifiable(records);

  final NarrativeEventSourceRef source;
  final int priority;
  final int order;
  final List<NarrativeEventRecord> records;

  String get diagnostic =>
      'Multiple enabled Narrative Events share source, priority $priority, and order $order: '
      '${records.map((record) => record.id).join(', ')}.';
}

@immutable
final class NarrativeEventSourceIndexBuildResult {
  NarrativeEventSourceIndexBuildResult._({
    required this.index,
    required List<NarrativeEventSourceConflict> conflicts,
  }) : conflicts = List.unmodifiable(conflicts);

  final NarrativeEventSourceIndex index;
  final List<NarrativeEventSourceConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
}

/// Builds the structural source index in O(R + sum(k log k)).
///
/// This operation deliberately does not evaluate conditions, lifecycle state,
/// catalog existence, or runtime eligibility. It keeps every tied candidate.
NarrativeEventSourceIndexBuildResult buildNarrativeEventSourceIndex(
  Iterable<NarrativeEventRecord> records,
) {
  final recordsBySource =
      <NarrativeEventSourceRef, List<NarrativeEventRecord>>{};
  for (final record in records) {
    final definition = record.definitionOrNull;
    if (definition == null || record.enabledOrNull != true) continue;
    recordsBySource.putIfAbsent(definition.source, () => []).add(record);
  }

  final conflicts = <NarrativeEventSourceConflict>[];
  for (final entry in recordsBySource.entries) {
    final sourceRecords = entry.value..sort(_compareIndexedRecords);
    var start = 0;
    while (start < sourceRecords.length) {
      final firstDefinition = sourceRecords[start].definitionOrNull!;
      var end = start + 1;
      while (end < sourceRecords.length) {
        final nextDefinition = sourceRecords[end].definitionOrNull!;
        if (nextDefinition.priority != firstDefinition.priority ||
            nextDefinition.order != firstDefinition.order) {
          break;
        }
        end++;
      }
      if (end - start > 1) {
        conflicts.add(
          NarrativeEventSourceConflict(
            source: entry.key,
            priority: firstDefinition.priority,
            order: firstDefinition.order,
            records: sourceRecords.sublist(start, end),
          ),
        );
      }
      start = end;
    }
  }

  conflicts.sort((left, right) {
    final source = canonicalizeNarrativeEventJson(left.source.toJson())
        .compareTo(canonicalizeNarrativeEventJson(right.source.toJson()));
    if (source != 0) return source;
    final priority = right.priority.compareTo(left.priority);
    if (priority != 0) return priority;
    return left.order.compareTo(right.order);
  });

  return NarrativeEventSourceIndexBuildResult._(
    index: NarrativeEventSourceIndex._(recordsBySource),
    conflicts: conflicts,
  );
}

int _compareIndexedRecords(
  NarrativeEventRecord left,
  NarrativeEventRecord right,
) {
  final leftDefinition = left.definitionOrNull!;
  final rightDefinition = right.definitionOrNull!;
  final priority = rightDefinition.priority.compareTo(leftDefinition.priority);
  if (priority != 0) return priority;
  final order = leftDefinition.order.compareTo(rightDefinition.order);
  if (order != 0) return order;
  return compareNarrativeEventUtf16(left.id, right.id);
}

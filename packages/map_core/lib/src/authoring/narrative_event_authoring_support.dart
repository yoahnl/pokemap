import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';

NarrativeEventRecord? findNarrativeEventRecord(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  if (registry == null) return null;
  for (final record in registry.records) {
    if (record.id == eventId) return record;
  }
  return null;
}

NarrativeEventRegistry replaceNarrativeEventRecord(
  NarrativeEventRegistry registry,
  NarrativeEventRecord nextRecord,
) {
  final index = registry.records.indexWhere(
    (record) => record.id == nextRecord.id,
  );
  if (index < 0) {
    throw ArgumentError.value(nextRecord.id, 'nextRecord', 'must exist');
  }
  final records = [...registry.records]..[index] = nextRecord;
  return NarrativeEventRegistry(
    schemaVersion: registry.schemaVersion,
    mode: registry.mode,
    records: records,
    legacyClaims: registry.legacyClaims,
  );
}

import 'package:map_core/map_core_domain.dart';

import 'event_labels.dart';
import 'event_legacy_catalog.dart';

bool _onMap(String? mapId, {required bool onMapOnly, String? filterMapId}) =>
    !onMapOnly || mapId != null && mapId == filterMapId;

List<NarrativeEventRecord> filterEventRecords(
  ProjectManifest project,
  Iterable<NarrativeEventRecord> records, {
  required String search,
  required bool onMapOnly,
  String? filterMapId,
}) {
  final query = search.toLowerCase().trim();
  return records.where((record) {
    final source = eventSource(record);
    final mapId = eventMapId(source);
    return _onMap(mapId, onMapOnly: onMapOnly, filterMapId: filterMapId) &&
        '${eventName(record)} ${record.id} ${eventKindLabel(source?.kind)} ${eventTargetId(source)} ${eventMapLabel(project, mapId)}'
            .toLowerCase()
            .contains(query);
  }).toList();
}

List<EventLegacyEntry> filterEventLegacyEntries(
  ProjectManifest project,
  Iterable<EventLegacyEntry> entries, {
  required String search,
  required bool onMapOnly,
  String? filterMapId,
}) {
  final query = search.toLowerCase().trim();
  return entries
      .where(
        (entry) =>
            _onMap(
              entry.mapId,
              onMapOnly: onMapOnly,
              filterMapId: filterMapId,
            ) &&
            '${entry.name} ${entry.key} ${eventMapLabel(project, entry.mapId)}'
                .toLowerCase()
                .contains(query),
      )
      .toList();
}

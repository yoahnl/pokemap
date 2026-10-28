import 'package:map_core/map_core.dart';

ProjectManifest projectRuntimeBorderRecords({
  required ProjectManifest project,
  required Iterable<Object?> documents,
}) {
  final catalog = project.borderCatalog;
  if (catalog.records.isEmpty) return project;
  final borderIds = {for (final record in catalog.records) record.id};
  final externalProject = project.toJson();
  final recordDocuments = {
    for (final record
        in (externalProject.remove('borderCatalog') as Map)['records'] as List)
      (record as Map)['id'] as String: record,
  };
  externalProject.remove('resourceLibraryCatalog');
  final retained =
      _referencedStrings([externalProject, ...documents], borderIds);
  final pending = retained.toList();
  for (var index = 0; index < pending.length; index++) {
    for (final reference
        in _referencedStrings(recordDocuments[pending[index]], borderIds)) {
      if (retained.add(reference)) pending.add(reference);
    }
  }
  if (retained.length == borderIds.length) return project;
  return project.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: catalog.formatVersion,
      records: catalog.records
          .where((record) => retained.contains(record.id))
          .toList(),
      visualSnapshots: catalog.visualSnapshots,
    ),
    resourceLibraryCatalog: ResourceLibraryCatalog(
      families: project.resourceLibraryCatalog.families,
      entries: project.resourceLibraryCatalog.entries
          .where((entry) =>
              entry.resourceKind != 'borderBlueprint' ||
              retained.contains(entry.resourceId))
          .toList(),
    ),
  );
}

Set<String> _referencedStrings(Object? value, Set<String> candidates) {
  final references = <String>{};
  final pending = <Object?>[value];
  while (pending.isNotEmpty) {
    final item = pending.removeLast();
    if (item is String && candidates.contains(item)) {
      references.add(item);
    } else if (item is Map) {
      pending.addAll(item.values);
    } else if (item is List) {
      pending.addAll(item);
    }
  }
  return references;
}

enum ResourceUsageRelation { direct, indirect, technical, ambiguous }

final class ResourceUsageTarget {
  const ResourceUsageTarget({required this.family, required this.id});

  final String family;
  final String id;
  String get identity => '$family:$id';

  Map<String, Object?> toJson() => {'family': family, 'id': id};
}

final class ResourceUsageEntry {
  const ResourceUsageEntry({
    required this.ownerKind,
    required this.ownerId,
    required this.ownerLabel,
    required this.location,
    required this.relation,
    this.mapId,
    this.entityId,
    this.resourceFamily,
    this.resourceId,
  });

  final String ownerKind;
  final String ownerId;
  final String ownerLabel;
  final String location;
  final ResourceUsageRelation relation;
  final String? mapId;
  final String? entityId;
  final String? resourceFamily;
  final String? resourceId;

  Map<String, Object?> toJson() => {
        'ownerKind': ownerKind,
        'ownerId': ownerId,
        'ownerLabel': ownerLabel,
        'location': location,
        'relation': relation.name,
        if (mapId != null) 'mapId': mapId,
        if (entityId != null) 'entityId': entityId,
        if (resourceFamily != null) 'resourceFamily': resourceFamily,
        if (resourceId != null) 'resourceId': resourceId,
      };
}

final class ResourceUsageReport {
  ResourceUsageReport({
    required this.target,
    required this.revision,
    required Map<String, String> fingerprints,
    required Iterable<ResourceUsageEntry> entries,
    required Iterable<String> coverageIssues,
  })  : fingerprints = Map.unmodifiable(fingerprints),
        entries = List.unmodifiable(entries),
        coverageIssues = List.unmodifiable(coverageIssues);

  final ResourceUsageTarget target;
  final String revision;
  final Map<String, String> fingerprints;
  final List<ResourceUsageEntry> entries;
  final List<String> coverageIssues;
  bool get complete => coverageIssues.isEmpty;

  Map<String, Object?> toJson() => {
        'id': target.identity,
        'name': target.identity,
        'target': target.toJson(),
        'revision': revision,
        'fingerprints': fingerprints,
        'complete': complete,
        'coverageIssues': coverageIssues,
        'entries': [for (final entry in entries) entry.toJson()],
      };
}

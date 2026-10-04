import 'dart:convert';

import '../domains/assets/asset_store.dart';
import '../workspace/project_snapshot.dart';
import 'project_reference_index.dart';
import 'resource_usage_documents.dart';
import 'resource_usage_report.dart';
import 'resource_usage_walk.dart';

final class ResourceUsageProjection {
  const ResourceUsageProjection();

  ResourceUsageReport analyze(
    ProjectSnapshot snapshot,
    ResourceUsageTarget target,
  ) {
    final issues = <String>[];
    final documents = resourceUsageDocuments(snapshot, issues);
    final targetKind = switch (target.family) {
      'images' => 'tileset',
      'decors' => 'element',
      'terrains' => 'preset',
      'borders' => 'border',
      _ => throw ArgumentError.value(target.family, 'family'),
    };
    final definition = documents
        .where((doc) => doc.kind == targetKind && doc.id == target.id)
        .firstOrNull;
    if (definition == null) {
      issues.add('resource.usages.target_missing:${target.identity}');
    }
    final records = <AssetRecord>[];
    final catalogBytes =
        snapshot.findResourceBytes(assetCatalogResourceIdentity);
    if (catalogBytes != null) {
      try {
        final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(catalogBytes)) as Map));
        if (target.family == 'images' && definition != null) {
          records.addAll(catalog.records.where((record) =>
              record.logicalPath == definition.value['relativePath']));
        }
      } on Object {
        issues.add('resource.usages.asset_catalog_invalid');
      }
    } else if (documents.any(
        (doc) => resourceReferencePaths(doc.value, 'asset', null).isNotEmpty)) {
      issues.add('resource.usages.asset_catalog_unavailable');
    }
    final entries = <ResourceUsageEntry>[];
    final added = <String>{};
    final related = <String>{};
    final pending = <String>[];
    void add(ResourceUsageDocument doc, String path,
        ResourceUsageRelation relation) {
      final key = '${doc.identity}:$path';
      if (!added.add(key)) return;
      final family = switch (doc.kind) {
        'tileset' => 'images',
        'element' => 'decors',
        'preset' => 'terrains',
        'border' => 'borders',
        _ => null,
      };
      entries.add(ResourceUsageEntry(
        ownerKind: doc.kind,
        ownerId: doc.id,
        ownerLabel: doc.label,
        location: '${doc.origin}:$path',
        relation: relation,
        mapId: doc.kind == 'map' ? doc.id : null,
        entityId: doc.kind == 'map' ? usageEntityId(doc.value, path) : null,
        resourceFamily: family,
        resourceId: family == null ? null : doc.id,
      ));
      if (relation != ResourceUsageRelation.ambiguous &&
          related.add(doc.identity)) {
        pending.add(doc.identity);
      }
    }

    for (final doc in documents) {
      for (final path
          in resourceReferencePaths(doc.value, targetKind, target.id)) {
        if (doc.kind == targetKind && doc.id == target.id) continue;
        add(doc, path, resourceUsageRelationFor(doc.kind));
      }
      if (target.family == 'images' && definition != null) {
        for (final path in resourceReferencePaths(
            doc.value, 'imagePath', '${definition.value['relativePath']}')) {
          add(
              doc,
              path,
              doc.identity == definition.identity
                  ? ResourceUsageRelation.technical
                  : resourceUsageRelationFor(doc.kind));
        }
      }
      for (final record in records) {
        final logicalPaths = {
          ...resourceReferencePaths(doc.value, 'asset', record.id),
          ...resourceReferencePaths(doc.value, 'imagePath', record.logicalPath),
        };
        final paths = deriveAssetDocumentUsages(
            asset: record, documents: {'document': doc.value});
        for (final match in paths) {
          final path = match.substring('document:'.length);
          final isLogical = logicalPaths.contains(path);
          add(
              doc,
              path,
              isLogical
                  ? doc.identity == definition?.identity
                      ? ResourceUsageRelation.technical
                      : resourceUsageRelationFor(doc.kind)
                  : ResourceUsageRelation.ambiguous);
        }
      }
    }
    final byIdentity = {for (final doc in documents) doc.identity: doc};
    final consumers = <String,
        List<({ResourceUsageDocument owner, String path, bool edge})>>{};
    for (final doc in documents) {
      for (final reference in resourceReferences(doc.value)) {
        consumers
            .putIfAbsent('${reference.kind}:${reference.id}', () => [])
            .add((owner: doc, path: reference.path, edge: false));
      }
    }
    try {
      final index = ProjectReferenceIndex.fromSnapshot(snapshot);
      for (final edge in index.edges.where((edge) =>
          edge.target.kind == 'media' ||
          edge.target.kind == 'presentationCinematic')) {
        final owner = byIdentity['${edge.owner.kind}:${edge.owner.id}'];
        if (owner != null) {
          consumers
              .putIfAbsent('${edge.target.kind}:${edge.target.id}', () => [])
              .add((owner: owner, path: edge.path, edge: true));
        }
      }
      issues.addAll(index.diagnostics
          .where((diagnostic) =>
              diagnostic.target.kind == 'media' ||
              diagnostic.target.kind == 'asset')
          .map((diagnostic) =>
              '${diagnostic.code}:${diagnostic.target.kind}:${diagnostic.target.id}'));
    } on Object {
      issues.add('resource.usages.reference_index_incomplete');
    }
    for (var cursor = 0; cursor < pending.length; cursor++) {
      final identity = pending[cursor];
      for (final reference in consumers[identity] ?? const []) {
        final doc = reference.owner;
        if (doc.identity == identity ||
            doc.kind == targetKind && doc.id == target.id) {
          continue;
        }
        add(
            doc,
            reference.path,
            !reference.edge &&
                    (doc.kind == 'borderSnapshot' ||
                        doc.kind == 'smartTileDraft' ||
                        doc.kind == 'border' &&
                            reference.path.startsWith(r'$.draft.'))
                ? ResourceUsageRelation.technical
                : ResourceUsageRelation.indirect);
      }
    }
    entries.sort((a, b) {
      final owners = '${a.ownerKind}:${a.ownerId}'
          .compareTo('${b.ownerKind}:${b.ownerId}');
      return owners != 0 ? owners : a.location.compareTo(b.location);
    });
    return ResourceUsageReport(
      target: target,
      revision: snapshot.revision,
      fingerprints: snapshot.resourceFingerprints,
      entries: entries,
      coverageIssues: issues.toSet().toList()..sort(),
    );
  }
}

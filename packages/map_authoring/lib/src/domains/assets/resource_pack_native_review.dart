part of 'resource_pack_projection.dart';

final class ResourcePackNativeReview {
  ResourcePackNativeReview._(
      Iterable<Map<String, Object?>> rows,
      Map<String, List<String>> nativeIds,
      this.requiresOrganizationAcknowledgement,
      Map<String, int> summary)
      : rows = List.unmodifiable(
            rows.map((row) => Map<String, Object?>.unmodifiable(row))),
        reachedNativeIds = Map.unmodifiable({
          for (final entry in nativeIds.entries)
            entry.key: List<String>.unmodifiable(entry.value)
        }),
        summary = Map.unmodifiable(summary);
  final List<Map<String, Object?>> rows;
  final Map<String, List<String>> reachedNativeIds;
  final bool requiresOrganizationAcknowledgement;
  final Map<String, int> summary;
}

final class ResourcePackNativeInventory {
  ResourcePackNativeInventory(ProjectManifest manifest)
      : sections = _nativeInventory(manifest);
  final Map<String, List<Map<String, Object?>>> sections;
}

Map<String, Object?> _nativeReviewLabel(String name) => {
      'label': String.fromCharCodes(name.runes.take(160)),
      'labelComplete': name.runes.length <= 160,
      'labelLength': name.runes.length,
    };

Map<String, List<Map<String, Object?>>> _nativeInventory(
    ProjectManifest manifest) {
  final authors = <String>{};
  final sources = <Map<String, Object?>>[];
  for (final installation in manifest.resourcePackInstallations.entries) {
    for (final origin in installation.origins) {
      authors.add(origin.author);
      sources.add({
        'kind': 'source',
        'id': jsonEncode([installation.installationId, origin.id]),
        ..._nativeReviewLabel(origin.author),
        if (origin.sourceUrl != null) 'sourceUrl': origin.sourceUrl,
        'licenseCount': origin.licenseIds.length
      });
    }
  }
  final sortedAuthors = authors.toList()..sort();
  final result = <String, List<Map<String, Object?>>>{
    'families': [
      for (final family in manifest.resourceLibraryCatalog.effectiveFamilies)
        {
          'kind': 'resourceFamily',
          'id': family.id,
          ..._nativeReviewLabel(family.name)
        }
    ],
    'authors': [
      for (final author in sortedAuthors)
        {'kind': 'author', ..._nativeReviewLabel(author)}
    ],
    'sources': sources,
  };
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<Map<String, Object?>>.unmodifiable(
          entry.value.map((row) => Map<String, Object?>.unmodifiable(row)))
  });
}

String _nativeNodeName(_NativeNode node) {
  final published = node.value['latestPublished'];
  final name = node.value['name'] ??
      (published is Map ? (published['definition'] as Map)['name'] : null) ??
      node.value['displayName'];
  return name is String
      ? name
      : switch (node.kind) {
          'file' => 'Fichier associé',
          'smartTilePattern' => 'Motif de terrain',
          'smartTileAtlas' => 'Atlas de terrain',
          'smartTileMaterial' => 'Matériau de terrain',
          'borderSnapshot' => 'Instantané publié de bordure',
          _ => 'Support associé',
        };
}

ResourcePackNativeReview _nativeReview(
    _Projection projection,
    ResourcePackCatalog catalog,
    List<NativeResourcePackRef> roots,
    List<String> patterns,
    List<ResourcePackBuildSource> sources,
    Set<String> documentNativeIds) {
  final selected = {
    for (final root in roots) _key(root.kind.name, root.id),
    for (final id in patterns) _key('smartTilePattern', id)
  };
  final keys = projection.completed.keys.toList()..sort();
  final rows = <Map<String, Object?>>[];
  final ids = <String, List<String>>{};
  final labelsByPortable = <String, String>{};
  final portableKinds =
      ResourcePackKind.values.map((kind) => kind.name).toSet();
  var resources = 0;
  var supports = 0;
  var files = 0;
  for (final key in keys) {
    final node = projection.nodes[key]!;
    ids.putIfAbsent(node.kind, () => []).add(node.id);
    final resource = portableKinds.contains(node.kind);
    labelsByPortable['${node.kind}:${projection.mapping[key] ?? node.id}'] =
        _nativeNodeName(node);
    if (resource) {
      resources++;
    } else if (node.kind == 'file') {
      files++;
    } else {
      supports++;
    }
    rows.add({
      'kind': resource
          ? 'resource'
          : node.kind == 'file'
              ? 'file'
              : 'support',
      'resourceKind': node.kind,
      'nativeId': node.id,
      'id': projection.mapping[key] ?? node.id,
      if (node.owner != null) 'ownerId': node.owner,
      'selected': selected.contains(key),
      ..._nativeReviewLabel(_nativeNodeName(node))
    });
  }
  ids['file'] = {...?ids['file'], ...documentNativeIds}.toList();
  for (final entry in ids.values) {
    entry.sort();
  }
  for (final promoted in projection.promoted) {
    rows.add({
      'kind': 'promotion',
      'resourceKind': promoted.kind.name,
      'nativeId': promoted.id,
      ..._nativeReviewLabel(_nativeNodeName(
          projection.nodes[_key(promoted.kind.name, promoted.id)]!)),
      'effect': 'privateToCommon'
    });
  }
  for (final effect in projection.removed.toList()..sort()) {
    final separator = effect.lastIndexOf('.');
    final nativeKey = effect.substring(0, separator);
    final field = effect.substring(separator + 1);
    final node = projection.nodes[nativeKey];
    final effectLabel = switch (field) {
      'mapId' => 'Ressource privée rendue commune',
      'groupId' => 'Groupe local retiré',
      'recommendedLayerId' => 'Calque recommandé retiré',
      'scope' => 'Portée rendue globale',
      'isWorldTileset' => 'Organisation de carte retirée',
      _ => 'Organisation locale retirée'
    };
    rows.add({
      'kind': 'organization',
      'effect': effect,
      'field': field,
      if (node != null) ...{'resourceKind': node.kind, 'nativeId': node.id},
      ..._nativeReviewLabel(
          node == null ? 'Ressource associée' : _nativeNodeName(node)),
      'effectLabel': effectLabel,
      'notice':
          'Les liens propres à une carte ou à son organisation ne seront pas distribués.'
    });
  }
  final reachedBorders = (ids['borderBlueprint'] ?? []).toSet();
  for (final record in projection.manifest.borderCatalog.records
      .where((record) => reachedBorders.contains(record.id))) {
    final published = record.latestPublished!;
    final comparison = record.draft.definition ==
            reconstructResourcePackBorderDraft(published).definition
        ? 'equivalent'
        : 'divergent';
    rows.add({
      'kind': 'publication',
      'resourceKind': 'borderBlueprint',
      'nativeId': record.id,
      ..._nativeReviewLabel(published.definition.name),
      'publishedRevision': published.revision,
      'draftComparison': comparison,
      'notice':
          'La version publiée sera exportée ; le brouillon enregistré reste inchangé.'
    });
  }
  final reachedPresets = (ids['smartTilePreset'] ?? []).toSet();
  final draftsByPreset = <String, List<ProjectSmartTileAuthoringDraft>>{};
  for (final draft in projection.manifest.smartTileCatalog.drafts) {
    if (reachedPresets.contains(draft.targetPresetId)) {
      draftsByPreset.putIfAbsent(draft.targetPresetId, () => []).add(draft);
    }
  }
  for (final preset in projection.manifest.smartTileCatalog.presets
      .where((preset) => reachedPresets.contains(preset.id))) {
    final drafts = draftsByPreset[preset.id] ?? [];
    if (drafts.isEmpty) {
      rows.add({
        'kind': 'publication',
        'resourceKind': 'smartTilePreset',
        'nativeId': preset.id,
        ..._nativeReviewLabel(preset.name),
        'draftComparison': 'absent',
        'notice': 'La publication actuelle sera exportée.'
      });
    }
    for (final draft in drafts) {
      final compiled = compileSmartTileAuthoringDraft(
          draft: draft,
          catalog: projection.manifest.smartTileCatalog,
          manifest: projection.manifest);
      var comparison = 'notComparable';
      if (compiled is SmartTileDraftCompilationSuccess) {
        final after = ProjectSmartTileCatalog(
            atlases: compiled.atlases,
            materials: compiled.materials,
            animations: compiled.animations,
            presets: [compiled.preset]);
        comparison = CanonicalJson.encode(_terrainPublication(
                    preset, projection.manifest.smartTileCatalog)) ==
                CanonicalJson.encode(
                    _terrainPublication(compiled.preset, after))
            ? 'equivalent'
            : 'divergent';
      }
      rows.add({
        'kind': 'publication',
        'resourceKind': 'smartTilePreset',
        'nativeId': preset.id,
        'draftId': draft.id,
        ..._nativeReviewLabel(preset.name),
        'draftComparison': comparison,
        'notice': comparison == 'notComparable'
            ? 'Le brouillon enregistré ne peut pas être comparé ; la publication valide sera exportée.'
            : 'La publication actuelle sera exportée ; le brouillon enregistré reste inchangé.'
      });
    }
  }
  final fileOrigins = catalog.files.map((file) => file.provenanceId).toSet();
  var globalCredits = 0;
  for (final origin in catalog.provenance) {
    final global = origin.resources.isEmpty && !fileOrigins.contains(origin.id);
    if (global) {
      globalCredits++;
    }
    rows.add({
      'kind': 'source',
      'id': origin.id,
      'attributionScope':
          global ? 'globalCredits' : 'resourceOrFileAttribution',
      ..._nativeReviewLabel(origin.author),
      if (origin.sourceUrl != null) 'sourceUrl': origin.sourceUrl,
      'licenseCount': origin.licenseIds.length
    });
    for (final ref in origin.resources) {
      rows.add({
        'kind': 'sourceResource',
        'sourceId': origin.id,
        'resourceKind': ref.kind.name,
        'id': ref.id,
        ..._nativeReviewLabel(
            labelsByPortable[ref.identity] ?? 'Ressource associée')
      });
    }
    for (final license in origin.licenseIds) {
      rows.add({
        'kind': 'sourceLicense',
        'sourceId': origin.id,
        'documentPath': license,
        'label': 'Licence de cette origine'
      });
    }
  }
  for (final file in catalog.files) {
    rows.add({
      'kind': 'sourceFile',
      'sourceId': file.provenanceId,
      'fileId': file.id,
      'logicalPath': file.logicalPath,
      'archivePath': file.archivePath,
      'label': 'Fichier associé à cette origine',
      'licenseCount': file.licenseIds.length
    });
    for (final license in file.licenseIds) {
      rows.add({
        'kind': 'fileLicense',
        'fileId': file.id,
        'documentPath': license,
        'label': 'Licence de ce fichier'
      });
    }
  }
  final documents =
      sources.where((source) => source.mediaType == 'text/plain').toList();
  for (final document in documents) {
    rows.add({
      'kind': 'license',
      'path': document.path,
      'rawSha256': document.rawSha256,
      'byteLength': document.byteLength,
      'label': 'Document de licence UTF-8'
    });
  }
  return ResourcePackNativeReview._(rows, ids, projection.removed.isNotEmpty, {
    'selectedRootCount': selected.length,
    'resourceCount': resources,
    'supportCount': supports,
    'fileCount': files,
    'promotionCount': projection.promoted.length,
    'neutralizationCount': projection.removed.length,
    'sourceCount': catalog.provenance.length,
    'globalCreditCount': globalCredits,
    'licenseCount': documents.length,
    'publicationNoticeCount':
        rows.where((row) => row['kind'] == 'publication').length
  });
}

Map<String, Object?> _terrainPublication(
    ProjectSmartTilePreset preset, ProjectSmartTileCatalog catalog) {
  final source =
      reconstructResourcePackSmartTileDraft(preset: preset, catalog: catalog);
  return {
    'preset': preset.toJson(),
    'atlases': {for (final atlas in source.atlases) atlas.id: atlas.toJson()},
    'materials': {
      for (final material in source.materials) material.id: material.toJson()
    },
    'animations': {
      for (final animation in source.animations)
        animation.id: animation.toJson()
    }
  };
}

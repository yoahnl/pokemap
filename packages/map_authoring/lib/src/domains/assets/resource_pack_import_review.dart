part of 'resource_pack_import_preparer.dart';

final class ResourcePackImportReview {
  ResourcePackImportReview(this.summary, this.rows);
  final Map<String, Object?> summary;
  final List<Map<String, Object?>> rows;
}

Set<String> _reachedImportOrigins(
    ResourcePackCatalog catalog, ResourcePackClosure closure) {
  final resources = closure.resources.toSet();
  final files = closure.files.toSet();
  final mediaOrigins = catalog.files.map((file) => file.provenanceId).toSet();
  final selectedOrigins = {
    for (final file in catalog.files)
      if (files.contains(file.id)) file.provenanceId
  };
  return {
    for (final origin in catalog.provenance)
      if (selectedOrigins.contains(origin.id) ||
          origin.resources.any(resources.contains) ||
          closure.nodes.isNotEmpty &&
              origin.resources.isEmpty &&
              !mediaOrigins.contains(origin.id))
        origin.id
  };
}

Set<String> _requiredImportLicenses(
    ResourcePackCatalog catalog, ResourcePackClosure closure) {
  final files = closure.files.toSet();
  final origins = _reachedImportOrigins(catalog, closure);
  return {
    for (final file in catalog.files)
      if (files.contains(file.id)) ...file.licenseIds,
    for (final origin in catalog.provenance)
      if (origins.contains(origin.id)) ...origin.licenseIds
  };
}

ResourcePackImportReview _buildImportReview({
  required ResourcePackImportSelection selection,
  required ProjectSnapshot snapshot,
  required ResourcePackClosure closure,
  required ResourcePackConflictPolicy policy,
  required ResourcePackPreparedImportStatus status,
  ResourcePackInstallation? previous,
  ResourcePackInstallation? installation,
  ResourcePackImportProjection? projection,
  Iterable<String> conflicts = const [],
  List<_Output> outputs = const [],
  int metadataBytes = 0,
}) {
  final catalog = selection.inspection.catalog;
  final sources = indexResourcePackDefinitions(catalog.toJson());
  final current = _nativeDefinitions(snapshot.manifest);
  final resources = closure.resources;
  final supports = closure.supports;
  final files = closure.files.toSet();
  final roots = {
    for (final root in selection.roots) ResourcePackNodeRef.resource(root),
    for (final id in selection.smartTilePatternIds)
      ResourcePackNodeRef.support(ResourcePackSupportRef(
          kind: ResourcePackSupportKind.smartTilePattern, id: id)),
  };
  final historical = _historicalKeys(previous);
  final mappedResources = {
    for (final mapping
        in installation?.resources ?? const <ResourcePackResourceMapping>[])
      mapping.source.identity: mapping
  };
  final mappedSupports = {
    for (final mapping
        in installation?.supports ?? const <ResourcePackSupportMapping>[])
      mapping.sourceIdentity: mapping
  };
  final oldResources = {
    for (final mapping
        in previous?.resources ?? const <ResourcePackResourceMapping>[])
      mapping.source.identity: mapping
  };
  final fileBindings = {for (final file in catalog.files) file.id: file};
  String kind(ResourcePackNodeRef node) =>
      node.resource?.kind.name ?? node.support?.kind.name ?? 'file';
  String id(ResourcePackNodeRef node) =>
      node.resource?.id ?? node.support?.id ?? node.fileId!;
  String key(ResourcePackNodeRef node) =>
      resourcePackNativeKey(kind(node), id(node), node.support?.owner?.id);
  String label(ResourcePackNodeRef node) {
    final definition = sources[key(node)];
    final name = definition?['name'] ??
        definition?['title'] ??
        definition?['displayName'];
    if (name is String && name.isNotEmpty) return name;
    if (node.resource?.kind == ResourcePackKind.borderBlueprint) {
      final publication =
          definition?['latestPublished'] ?? definition?['draft'];
      if (publication is Map &&
          publication['definition'] is Map &&
          (publication['definition'] as Map)['name'] is String) {
        return (publication['definition'] as Map)['name'] as String;
      }
    }
    if (node.fileId != null) {
      return fileBindings[node.fileId]?.logicalPath.split('/').last ??
          'Source du pack';
    }
    return switch (node.support?.kind) {
      ResourcePackSupportKind.smartTileConnectionGroup =>
        'Groupe de raccordement',
      ResourcePackSupportKind.borderSnapshot => 'Publication de bordure',
      ResourcePackSupportKind.characterPortraitState => 'État de portrait',
      ResourcePackSupportKind.characterAnimationDefinition =>
        'Animation de personnage',
      _ => 'Support d’édition',
    };
  }

  final rows = <Map<String, Object?>>[];
  final subjects = <String, String>{};
  var created = 0,
      copied = 0,
      reused = 0,
      present = 0,
      modified = 0,
      deleted = 0;
  Map<String, Object?>? firstAdded;
  for (final node in closure.nodes) {
    final nodeKind = kind(node), nodeId = id(node), sourceKey = key(node);
    final resourceMapping =
        node.resource == null ? null : mappedResources[node.resource!.identity];
    final supportMapping =
        node.support == null ? null : mappedSupports[node.support!.identity];
    final targetId = resourceMapping?.targetId ??
        supportMapping?.targetId ??
        projection?.mapping[sourceKey];
    final owner = supportMapping?.targetOwnerId ??
        (node.support?.owner == null
            ? null
            : projection?.mapping[
                resourcePackNativeKey('tileset', node.support!.owner!.id)]);
    final targetKey = targetId == null
        ? null
        : resourcePackNativeKey(nodeKind, targetId, owner);
    final stored = targetKey == null ? null : current[targetKey];
    var disposition = 'source';
    var localState = 'unchecked';
    if (node.fileId == null) {
      if (stored != null) present++;
      if (historical.contains(sourceKey) || stored != null) {
        reused++;
        disposition = 'historical';
      } else if (policy == ResourcePackConflictPolicy.importCopy) {
        copied++;
        disposition = 'copy';
      } else {
        created++;
        disposition = 'create';
      }
      final original =
          node.resource == null ? null : oldResources[node.resource!.identity];
      if (original != null) {
        if (stored == null) {
          deleted++;
          localState = 'deleted';
        } else if (CanonicalJson.sha256Hex(stored) !=
            original.definitionRawSha256) {
          modified++;
          localState = 'modified';
        } else {
          localState = 'unchanged';
        }
      }
      if (firstAdded == null &&
          (disposition == 'create' || disposition == 'copy') &&
          (node.resource != null ||
              node.support?.kind == ResourcePackSupportKind.smartTilePattern)) {
        firstAdded = {'kind': nodeKind, 'id': targetId};
      }
    }
    final requiredBy =
        roots.contains(node) ? node : closure.representativeRoots[node]!;
    final fullLabel = label(node);
    final characters = fullLabel.runes;
    final length = characters.length;
    final display = String.fromCharCodes(characters.take(160));
    subjects[sourceKey] = display;
    if (targetKey != null) subjects[targetKey] = display;
    if (targetId != null) subjects[targetId] = display;
    if (node.fileId case final String fileId) {
      final file = fileBindings[fileId]!;
      subjects[projection?.filePaths[fileId] ?? file.logicalPath] = display;
      subjects[file.rawSha256] = display;
      subjects['sha256:${file.rawSha256}'] = display;
    }
    rows.add({
      'kind': nodeKind,
      'id': nodeId,
      if (targetId != null) 'targetId': targetId,
      'label': display,
      'labelComplete': length <= 160,
      'labelLength': length,
      'selected': roots.contains(node),
      'disposition': disposition,
      'localState': localState,
      'requiredByKind': kind(requiredBy),
      'requiredById': id(requiredBy),
      'requiredByLabel':
          String.fromCharCodes(label(requiredBy).runes.take(160)),
      'requiredByRepresentative': !roots.contains(node)
    });
  }
  final licenses = _requiredImportLicenses(catalog, closure);
  final sourceBytes = catalog.files
      .where((file) => files.contains(file.id))
      .fold<int>(0, (total, file) => total + file.byteLength);
  final licenseBytes = selection.inspection.manifest.content.files
      .where((file) => licenses.contains(file.path))
      .fold<int>(0, (total, file) => total + file.byteLength);
  final conflictRows = <Map<String, Object?>>[];
  for (final conflict in conflicts.toList()..sort()) {
    final separator = conflict.indexOf(':');
    final code = separator < 0 ? conflict : conflict.substring(0, separator);
    final subject = separator < 0 ? '' : conflict.substring(separator + 1);
    final message = switch (code) {
      'dependency_modified_or_missing' =>
        'La définition locale a été modifiée ou retirée.',
      'classification_modified_or_missing' =>
        'Le classement local a été modifié.',
      'dependency_draft_modified_or_missing' =>
        'Un brouillon local a été modifié ou retiré.',
      'id_occupied' => 'Une ressource locale occupe déjà cette identité.',
      'asset_dependency_conflict' ||
      'asset_dependency_missing' =>
        'Une source locale a été modifiée ou retirée.',
      _ => 'Un fichier local empêche cette installation.',
    };
    conflictRows.add({
      'conflict': conflict,
      'conflictCode': code,
      'label': subjects[subject] ?? 'Ressources de cette sélection',
      'message': message
    });
  }
  final applicable = status == ResourcePackPreparedImportStatus.ready;
  final outputBytes = applicable
      ? outputs.fold<int>(
          0, (total, output) => total + output.payload.byteLength)
      : 0;
  final definitionCount = resources.length + supports.length;
  return ResourcePackImportReview(
      Map.unmodifiable({
        'selectedResourceCount': selection.roots.length,
        'selectedPatternCount': selection.smartTilePatternIds.length,
        'resourceCount': resources.length,
        'supportCount': supports.length,
        'definitionCount': definitionCount,
        'dependencyCount': closure.nodes.length - roots.length,
        'fileCount': files.length,
        'createdDefinitionCount': created,
        'copiedDefinitionCount': copied,
        'reusedDefinitionCount': reused,
        'presentDefinitionCount': present,
        'blockedDefinitionCount':
            status == ResourcePackPreparedImportStatus.conflict
                ? definitionCount
                : 0,
        'localModifiedResourceCount': modified,
        'localDeletedResourceCount': deleted,
        'localVerificationScope': 'resourceDefinitionsOnly',
        'sourceBytes': sourceBytes,
        'licenseBytes': licenseBytes,
        'outputBytes': outputBytes,
        'newBlobBytes': applicable
            ? outputs.where((output) => output.role == 'blob').fold<int>(
                0, (total, output) => total + output.payload.byteLength)
            : 0,
        'metadataBytes': applicable ? metadataBytes : 0,
        'writeBytes': outputBytes + (applicable ? metadataBytes : 0),
        'status': status.name,
        if (firstAdded != null) 'firstAdded': firstAdded,
      }),
      List.unmodifiable([...conflictRows, ...rows]));
}

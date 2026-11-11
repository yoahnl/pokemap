part of 'model3d_actions.dart';

const _modelPruneInputSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['modelIds'],
  'properties': {
    'modelIds': {
      'type': 'array',
      'minItems': 1,
      'maxItems': Model3dActions.maximumPruneModelCount,
      'uniqueItems': true,
      'items': {'type': 'string', 'pattern': r'^[a-zA-Z0-9_-]{1,128}$'}
    }
  }
};

final class ModelPruneInspection {
  const ModelPruneInspection._(
      this.project, this.sourceIds, this.retainedSources);

  final ProjectManifest project;
  final List<String> sourceIds;
  final Map<String, List<String>> retainedSources;
}

Set<String> _pruneModelIds(Map<String, Object?> parameters) {
  final raw = parameters['modelIds'];
  if (parameters.length != 1 ||
      raw is! List ||
      raw.isEmpty ||
      raw.length > Model3dActions.maximumPruneModelCount ||
      raw.any((id) =>
          id is! String || !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id))) {
    throw const FormatException(
        'model3d.prune_unused: expected 1 to 500 model identities');
  }
  final ids = raw.cast<String>().toSet();
  if (ids.length != raw.length) {
    throw const FormatException(
        'model3d.prune_unused: duplicate model identity');
  }
  return ids;
}

ModelPruneInspection _inspectModelPrune(
    ProjectSnapshot snapshot, Set<String> ids) {
  if (snapshot.availableProjectSections != null ||
      snapshot.maps.length != snapshot.manifest.maps.length ||
      snapshot.manifest.pokemon.enabled && !snapshot.pokemonInventoryComplete) {
    throw AuthoringPlanException(
        code: 'model3d.prune_audit_required',
        message:
            'Library pruning requires an explicit complete reference audit.');
  }
  final models = snapshot.manifest.models3d
      .where((model) => ids.contains(model.id))
      .toList();
  if (models.length != ids.length) {
    throw const FormatException('model3d.prune_unused: unknown model identity');
  }
  final library = snapshot.manifest.resourceLibraryCatalog;
  final allModels = snapshot.manifest.models3d;
  final remaining = allModels.length - ids.length;
  final tail = allModels
      .skip(remaining)
      .where((model) => !ids.contains(model.id))
      .iterator;
  final keptModels = <ProjectModel3dEntry>[];
  for (final model in allModels.take(remaining)) {
    if (ids.contains(model.id)) {
      if (!tail.moveNext()) {
        throw const FormatException(
            'model3d.prune_unused: missing position replacement');
      }
      keptModels.add(tail.current);
    } else {
      keptModels.add(model);
    }
  }
  final project = snapshot.manifest.copyWith(
      models3d: keptModels,
      resourceLibraryCatalog: ResourceLibraryCatalog(
          families: library.families,
          entries: library.entries.where((entry) =>
              entry.resourceKind != 'model3d' ||
              !ids.contains(entry.resourceId))));
  final projected = _modelPruneProjection(snapshot, project);
  final issues = <String>[];
  final documents = resourceUsageDocuments(projected, issues);
  if (issues.isNotEmpty) {
    throw AuthoringPlanException(
        code: 'model3d.prune_audit_incomplete',
        message:
            'The library reference audit is incomplete: ${issues.join(', ')}.');
  }
  final external = <String, Object?>{
    for (final document in documents)
      if (const {'media', 'pokemonMedia', 'dialogueSource'}
          .contains(document.kind))
        document.identity: document.value,
    for (final identity in snapshot.resourceFingerprints.keys)
      if (identity.startsWith('exteriorReference:'))
        identity: jsonDecode(utf8.decode(snapshot.resourceBytes(identity))),
  };
  for (final document in [
    for (final document in documents) (document.identity, document.value),
    for (final entry in external.entries) (entry.key, entry.value),
  ]) {
    for (final reference in resourceReferences(document.$2)) {
      if (reference.kind == 'model3d' && ids.contains(reference.id)) {
        throw AuthoringPlanException(
            code: 'model3d.prune_model_in_use',
            message:
                'Model ${reference.id} is still referenced by ${document.$1} at ${reference.path}.');
      }
    }
  }
  final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(jsonDecode(
          utf8.decode(snapshot.resourceBytes(assetCatalogResourceIdentity)))
      as Map));
  final deleted = <String>[];
  final retained = <String, List<String>>{};
  final sources = {
    for (final id in models.map((model) => model.sourceAssetId).toSet())
      id: catalog.require(id)
  };
  final sourceUsages =
      deriveAssetBatchDocumentUsages(assets: sources.values, documents: {
    'project': project.toJson()..remove('resourcePackInstallations'),
    for (final map in snapshot.maps) 'map:${map.id}': map.toJson(),
    ...external,
  });
  for (final source in sources.values) {
    final id = source.id;
    final usages = [
      ...sourceUsages[id]!,
      ...source.usages,
    ];
    if (usages.isEmpty) {
      deleted.add(id);
    } else {
      retained[id] = usages;
    }
  }
  return ModelPruneInspection._(project, deleted, retained);
}

ProjectSnapshot _modelPruneProjection(
        ProjectSnapshot snapshot, ProjectManifest project) =>
    ProjectSnapshot(
        projectHandle: snapshot.projectHandle,
        revision: snapshot.revision,
        manifest: project,
        maps: snapshot.maps,
        pokemonInventoryComplete: snapshot.pokemonInventoryComplete,
        materializedCatalogProject: snapshot.materializedCatalogProject,
        resourceFingerprints: snapshot.resourceFingerprints,
        resourceBytes: snapshot.inlineResourceBytes,
        storedResources: snapshot.storedResources,
        payloadResources: snapshot.payloadResources,
        resourcePayloadReader: snapshot.resourcePayloadReader,
        payloadOwner: snapshot.payloadOwner,
        loadDiagnostics: snapshot.loadDiagnostics,
        resourceStorageKeys: snapshot.resourceStorageKeys);

extension _ModelPrune on Model3dActions {
  Future<AuthoringMutationDraft> _pruneUnused(
      AuthoringPlanningContext context) async {
    final ids = _pruneModelIds(context.request.parameters);
    final inspected = _inspectModelPrune(context.snapshot, ids);
    final projected =
        _modelPruneProjection(context.snapshot, inspected.project);
    final manifestDraft = buildVisualManifestDraft(
        context.snapshot, inspected.project,
        operation: context.request.actionId,
        path: '/models3d',
        before: {'modelIds': ids.toList()},
        after: {'modelIds': const []});
    final draft = await AssetActions(
            artifactStore: artifactStore,
            retainedBlobReader: retainedBlobReader)
        .composeDeletionBatch(projected, inspected.sourceIds);
    return AuthoringMutationDraft(
        changeSet: AuthoringChangeSet(
            changes: [
              ...manifestDraft.changeSet.changes,
              ...draft.changeSet.changes,
            ],
            diff: AuthoringDiff([
              ...manifestDraft.changeSet.diff.entries,
              ...draft.changeSet.diff.entries,
            ])),
        projectedProject: inspected.project,
        preview: {
          'operation': context.request.actionId,
          'executionScope': 'explicit_library_maintenance',
          'deletedModelIds': ids.toList(),
          'deletedSourceIds': inspected.sourceIds,
          'retainedSources': {
            for (final entry in inspected.retainedSources.entries)
              entry.key: {
                'usageCount': entry.value.length,
                'examples': entry.value.take(8).toList(),
              }
          },
          'auditedMaps': context.snapshot.maps.length,
          'auditedPokemonMedia': context.snapshot.resourceFingerprints.keys
              .where((identity) => identity.startsWith('pokemonMedia:'))
              .length,
          'pokemonMediaCoverage': context.snapshot.manifest.pokemon.enabled
              ? 'enumerated'
              : 'disabled',
          'auditedExteriorDocuments': context.snapshot.resourceFingerprints.keys
              .where((identity) => identity.startsWith('exteriorReference:'))
              .length,
        });
  }
}

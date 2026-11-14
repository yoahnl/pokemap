part of 'local_resource_adapter.dart';

ProjectManifest _classifiedManifest(
  ({ProjectManifest manifest, String revision}) before,
  AuthoringMutationPlanResult planned,
  ResourceMutationPreparation preparation,
  Map<String, Object?> parameters,
) {
  final selected =
      planned.projectedProject ??
      (throw const ResourceFailure(
        'Le rangement n’a pas pu être préparé. Rien n’a été écrit.',
      ));
  final merged = mergeResourceLibraryCatalogs(
    before.manifest.resourceLibraryCatalog,
    selected.resourceLibraryCatalog,
  );
  final cleared = _clearedClassifications(
    preparation.actionId,
    parameters,
    selected.resourceLibraryCatalog,
  );
  final manifest = before.manifest.copyWith(
    resourceLibraryCatalog: cleared.isEmpty
        ? merged
        : ResourceLibraryCatalog(
            families: merged.families,
            entries: merged.entries.where(
              (entry) => !cleared.contains(entry.identity),
            ),
          ),
  );
  final publishedManifest = preparation.actionId == 'resource.family.delete'
      ? manifest.copyWith(
          resourceLibraryCatalog: ResourceLibraryCatalog(
            families: manifest.resourceLibraryCatalog.families.where(
              (family) => family.id != parameters['familyId'],
            ),
            entries: manifest.resourceLibraryCatalog.entries,
          ),
        )
      : manifest;
  return publishedManifest;
}

Set<String> _clearedClassifications(
  String actionId,
  Map<String, Object?> parameters,
  ResourceLibraryCatalog selected,
) {
  final targets = switch (actionId) {
    'resource.classify' => [parameters],
    'resource.classify_batch' => [
      for (final entry in parameters['entries'] as List) entry as Map,
    ],
    _ => const <Map>[],
  };
  return {
    for (final target in targets)
      if (selected.entryFor(
            target['resourceKind'] as String,
            target['resourceId'] as String,
          ) ==
          null)
        '${target['resourceKind']}:${target['resourceId']}',
  };
}

part of 'catalog_workshop_selection.dart';

Future<void> _requireContextualSceneScopes({
  required CatalogProjectReader reader,
  required ProjectManifest project,
  required String mapId,
  required Set<String> sceneIds,
  required Map<String, String?> revisions,
}) =>
    reader.read((catalog) async {
      final pending = <(String, int)>[
        for (final id in sceneIds) ('scene:$id', 0)
      ];
      final visited = <String>{};
      final roots = <CatalogDefinitionKey>{};
      for (var cursor = 0; cursor < pending.length; cursor++) {
        final (identity, depth) = pending[cursor];
        if (!visited.add(identity)) continue;
        if (visited.length > catalog.snapshot.limits.maxClosureNodes ||
            depth > catalog.snapshot.limits.maxClosureDepth) {
          throw const FormatException(
              'The contextual Scene resource closure exceeds its limits.');
        }
        final split = identity.indexOf(':');
        if (split <= 0)
          throw const FormatException(
              'Invalid contextual Scene resource identity.');
        final kind = identity.substring(0, split),
            id = identity.substring(split + 1);
        final nativeKind = switch (kind) {
          'preset' => 'smartTilePreset',
          'border' => 'borderBlueprint',
          _ => kind
        };
        if (catalogResourceKinds[nativeKind] case final definitionKind?) {
          roots.add(CatalogDefinitionKey(definitionKind, id));
          continue;
        }
        final field = switch (kind) {
          'scene' => 'scenes',
          'cinematic' => 'cinematics',
          'dialogue' => 'dialogues',
          'script' => 'scripts',
          'presentationCinematic' => 'presentationCinematics',
          'cinematicMedia' => 'cinematicMediaAssets',
          'presentationPreset' => 'presentationPresets',
          _ => null,
        };
        if (field == null) continue;
        final selected = await CatalogMetadataDocuments.readDocuments(
            snapshot: catalog.snapshot,
            project: project,
            ids: {
              field: {id}
            });
        final unit = selected.documents[field]?[id];
        if (unit == null)
          throw FormatException(
              'A contextual Scene dependency is missing: $identity.');
        final targets = {
          ...await CatalogResourceUsageIndex.directDependencies(
              catalog.snapshot, unit)
        };
        if (kind == 'dialogue') {
          final entry =
              selected.project.dialogues.singleWhere((entry) => entry.id == id);
          final source =
              await CatalogResourceUsageIndex.dialogueSourceDependencies(
                  catalog.snapshot, id);
          final current = await reader.store.gateway
              .readResourceRevision(entry.relativePath);
          if (current != source.revision)
            throw const FormatException(
                'The dialogue resource usage index is stale.');
          revisions[entry.relativePath] = current;
          targets.addAll(source.targets);
        }
        pending.addAll(targets.map((target) => (target, depth + 1)));
      }
      if (roots.isEmpty) return;
      final selected = await ProjectCatalogSelection(catalog).resolve(roots);
      for (final entry in selected.resourceLibraryCatalog.entries) {
        if (entry.mapId != null && entry.mapId != mapId) {
          throw VisualLibraryException('resource_library.scope_conflict',
              'A contextual Scene uses a resource reserved for another map.',
              details: {
                'resource': entry.identity,
                'mapId': mapId,
                'ownerMapId': entry.mapId
              });
        }
      }
    });

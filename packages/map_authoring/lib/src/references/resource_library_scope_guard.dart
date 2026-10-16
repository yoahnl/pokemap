import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/authoring_diff.dart';
import '../transactions/action_planner.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/change_set.dart';
import '../transactions/authoring_payload.dart';
import '../workspace/project_snapshot.dart';
import '../support/authoring_fingerprint.dart';
import '../domains/assets/tileset_actions.dart';
import 'resource_usage_documents.dart';
import 'resource_usage_walk.dart';

final class ResourceLibraryUsageIndex {
  ResourceLibraryUsageIndex(ProjectSnapshot snapshot)
      : this.fromDocuments(
            maps: snapshot.maps, documents: _snapshotUsageDocuments(snapshot));

  ResourceLibraryUsageIndex.fromDocuments({
    required Iterable<MapData> maps,
    required Iterable<ResourceUsageDocument> documents,
  }) : _mapIds = maps.map((map) => map.id).toSet() {
    for (final document in documents) {
      final owner = document.kind == 'dialogueSource'
          ? 'dialogue:${document.id}'
          : document.identity;
      if (document.kind == 'scene') {
        final scene = SceneAsset.fromJson(document.value);
        for (final node in scene.graph.nodes) {
          if (node.payload case final SceneCinematicPayload payload) {
            _consumers
                .putIfAbsent('cinematic:${payload.cinematicId}', () => {})
                .add(owner);
          }
        }
      }
      if ((document.kind, document.value['mapId'])
          case ('cinematic', final String mapId)) {
        if (!_mapIds.contains(mapId)) {
          throw VisualLibraryException('resource_library.usage_incomplete',
              'Resource scope needs cinematics bound to known maps.',
              details: {'cinematicId': document.id, 'mapId': mapId});
        }
        _consumers.putIfAbsent(owner, () => {}).add('map:$mapId');
      }
      for (final reference in resourceReferences(document.value)) {
        var kind = reference.kind;
        if (kind == 'preset' &&
            RegExp(r'\.areas\[\d+\]\.presetId$').hasMatch(reference.path)) {
          kind = 'environmentPreset';
        }
        _consumers.putIfAbsent('$kind:${reference.id}', () => {}).add(owner);
      }
    }
  }

  static List<ResourceUsageDocument> _snapshotUsageDocuments(
      ProjectSnapshot snapshot) {
    final issues = <String>[];
    final documents = resourceUsageDocuments(snapshot, issues);
    if (issues.isNotEmpty) {
      throw VisualLibraryException('resource_library.usage_incomplete',
          'Resource scope needs a complete saved project usage inventory.',
          details: {'issues': issues});
    }
    return documents;
  }

  final Set<String> _mapIds;
  final Map<String, Set<String>> _consumers = {};
  final Map<String, Set<String>> _cachedMapUsages = {};

  Set<String> mapUsages(String resourceKind, String resourceId) {
    final identity = '$resourceKind:$resourceId';
    final cached = _cachedMapUsages[identity];
    if (cached != null) return cached;
    final kind = switch (resourceKind) {
      'smartTilePreset' => 'preset',
      'borderBlueprint' => 'border',
      _ => resourceKind,
    };
    final visited = <String>{'$kind:$resourceId'};
    final pending = visited.toList();
    final maps = <String>{};
    for (var index = 0; index < pending.length; index++) {
      for (final owner in _consumers[pending[index]] ?? const <String>{}) {
        if (owner.startsWith('map:')) maps.add(owner.substring(4));
        if (owner == 'project:project') {
          maps.addAll(_mapIds);
        }
        if (visited.add(owner)) pending.add(owner);
      }
    }
    return _cachedMapUsages[identity] = Set.unmodifiable(maps);
  }
}

Set<String> resourceLibraryMapUsages(
        ProjectSnapshot snapshot, String resourceKind, String resourceId) =>
    ResourceLibraryUsageIndex(snapshot).mapUsages(resourceKind, resourceId);

void validateResourceLibraryMapScopes(ProjectSnapshot snapshot) {
  validateResourceLibraryTargets(snapshot.manifest);
  if (snapshot.manifest.resourceLibraryCatalog.entries
      .every((entry) => entry.mapId == null)) {
    return;
  }
  validateResourceLibraryScopeIndex(
      snapshot.manifest, ResourceLibraryUsageIndex(snapshot));
}

void validateResourceLibraryScopeIndex(
    ProjectManifest project, ResourceLibraryUsageIndex index) {
  validateResourceLibraryTargets(project);
  final scoped = project.resourceLibraryCatalog.entries
      .where((entry) => entry.mapId != null)
      .toList();
  if (scoped.isEmpty) return;
  for (final entry in scoped) {
    final otherMaps = index
        .mapUsages(entry.resourceKind, entry.resourceId)
        .where((id) => id != entry.mapId)
        .toList()
      ..sort();
    if (otherMaps.isNotEmpty) {
      throw VisualLibraryException('resource_library.scope_conflict',
          'This resource is reserved for another map.',
          details: {
            'resourceKind': entry.resourceKind,
            'resourceId': entry.resourceId,
            'mapId': entry.mapId,
            'referencingMapIds': otherMaps
          });
    }
  }
}

AuthoringMutationDraft guardResourceLibraryMutation(
    AuthoringPlanningContext context, AuthoringMutationDraft draft) {
  final original = context.snapshot;
  if (original.manifest.resourceLibraryCatalog.isEmpty &&
      context.request.actionId != 'resource.classify' &&
      context.request.actionId != 'resource.classify_batch' &&
      draft.projectedProject?.resourceLibraryCatalog.isEmpty != false &&
      !draft.changeSet.changes
          .any((change) => change.resource.kind == 'project')) {
    return draft;
  }
  var project = draft.projectedProject ?? original.manifest;
  final maps = {for (final map in original.maps) map.id: map};
  final replacements = <String, List<int>>{};
  final storedReplacements = <String, AuthoringPayload>{};
  final deletedReferenceDocuments = <String>{};
  final referenceStorageKeys = <String, String>{};
  for (final change in draft.changeSet.changes) {
    if (change.resource.kind == 'project' && change.afterPayload != null) {
      project = draft.projectedProject ??
          ProjectManifest.fromJson(Map<String, dynamic>.from(
              jsonDecode(utf8.decode(change.afterBytes!)) as Map));
    } else if (change.resource.kind == 'map') {
      if (change.afterPayload == null) {
        if (original.manifest.resourceLibraryCatalog.entries
            .any((entry) => entry.mapId == change.resource.id)) {
          throw VisualLibraryException(
              'resource_library.map_has_local_resources',
              'Promote or delete the resources reserved for this map before deleting it.',
              details: {'mapId': change.resource.id});
        }
        maps.remove(change.resource.id);
      } else {
        maps[change.resource.id] = MapData.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(change.afterBytes!)) as Map));
      }
    }
    final identity = original.resourceStorageKeys.entries
            .where((entry) => entry.value == change.storageKey)
            .firstOrNull
            ?.key ??
        switch (change.resource.kind) {
          'project' => 'project',
          'dialogue' => 'dialogueSource:${change.resource.id}',
          _ => '${change.resource.kind}:${change.resource.id}',
        };
    if (change.afterPayload == null) {
      deletedReferenceDocuments.add(identity);
    } else if (change.afterPayload!.isInline) {
      replacements[identity] = change.afterBytes!;
      referenceStorageKeys[identity] = change.storageKey;
    } else {
      storedReplacements[identity] = change.afterPayload!;
      referenceStorageKeys[identity] = change.storageKey;
    }
  }
  final staleEntries = project.resourceLibraryCatalog.entries
      .where((entry) =>
          !resourceLibraryResourceExists(
              project, entry.resourceKind, entry.resourceId) &&
          resourceLibraryResourceExists(
              original.manifest, entry.resourceKind, entry.resourceId))
      .toList();
  final inheritedEntries = <ResourceLibraryEntry>[];
  if (context.request.actionId == 'element.duplicate') {
    final sourceId = context.request.parameters['sourceElementId'];
    final newId = context.request.parameters['newElementId'];
    final source = sourceId is String
        ? original.manifest.resourceLibraryCatalog.entryFor('element', sourceId)
        : null;
    if (source != null &&
        newId is String &&
        resourceLibraryResourceExists(project, 'element', newId)) {
      inheritedEntries.add(ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: newId,
          familyId: source.familyId,
          mapId: source.mapId,
          role: source.role,
          placementContext: source.placementContext));
    }
  }
  if (staleEntries.isNotEmpty || inheritedEntries.isNotEmpty) {
    final catalog = ResourceLibraryCatalog(
        families: project.resourceLibraryCatalog.families,
        entries: [
          ...project.resourceLibraryCatalog.entries
              .where((entry) => !staleEntries.contains(entry)),
          ...inheritedEntries
        ]);
    project = project.copyWith(resourceLibraryCatalog: catalog);
    final changes = <AuthoringResourceChange>[];
    for (final change in draft.changeSet.changes) {
      if (change.resource.kind == 'project') {
        final raw = Map<String, Object?>.from(
            jsonDecode(utf8.decode(change.afterBytes!)) as Map);
        if (catalog.isEmpty) {
          raw.remove('resourceLibraryCatalog');
        } else {
          raw['resourceLibraryCatalog'] = catalog.toJson();
        }
        changes.add(AuthoringResourceChange(
            resource: change.resource,
            storageKey: change.storageKey,
            beforeBytes: change.beforeBytes,
            afterBytes: utf8.encode(jsonEncode(raw))));
      } else {
        changes.add(change);
      }
    }
    draft = AuthoringMutationDraft(
        projectedProject: project,
        changeSet: AuthoringChangeSet(
            changes: changes,
            diff: AuthoringDiff([
              ...draft.changeSet.diff.entries,
              AuthoringDiffEntry(
                  operation: AuthoringDiffOperation.replace,
                  resource: changes
                      .firstWhere((change) => change.resource.kind == 'project')
                      .resource,
                  path: '/resourceLibraryCatalog',
                  before: original.manifest.resourceLibraryCatalog.toJson(),
                  after: catalog.toJson()),
            ])),
        preview: draft.preview,
        referenceImpact: draft.referenceImpact,
        artifacts: draft.artifacts);
  }
  final projected = ProjectSnapshot(
    projectHandle: original.projectHandle,
    revision: original.revision,
    manifest: project,
    maps: maps.values,
    pokemonInventoryComplete: original.pokemonInventoryComplete,
    resourceFingerprints: {
      for (final entry in original.resourceFingerprints.entries)
        if (!deletedReferenceDocuments.contains(entry.key))
          entry.key: entry.value,
      for (final entry in replacements.entries)
        entry.key: computeAuthoringBytesFingerprint(entry.value,
            logicalName: referenceStorageKeys[entry.key]!),
      for (final entry in storedReplacements.entries)
        entry.key: entry.value.resourceRevision,
    },
    itemCatalog: original.itemCatalog,
    additionalItemReferences: original.additionalItemReferences,
    resourceStorageKeys: {
      for (final entry in original.resourceStorageKeys.entries)
        if (!deletedReferenceDocuments.contains(entry.key))
          entry.key: entry.value,
      ...referenceStorageKeys,
    },
    loadDiagnostics: original.loadDiagnostics,
    storedResources: {
      for (final entry in original.storedResources.entries)
        if (!deletedReferenceDocuments.contains(entry.key) &&
            !referenceStorageKeys.containsKey(entry.key))
          entry.key: entry.value
    },
    payloadResources: {
      for (final entry in original.payloadResources.entries)
        if (!deletedReferenceDocuments.contains(entry.key) &&
            !referenceStorageKeys.containsKey(entry.key))
          entry.key: entry.value,
      ...storedReplacements
    },
    resourcePayloadReader: original.resourcePayloadReader,
    payloadOwner: original.payloadOwner,
    resourceBytes: {
      for (final id in {
        ...original.resourceFingerprints.keys,
        ...replacements.keys
      })
        if (!deletedReferenceDocuments.contains(id))
          if (id.startsWith('pokemonMedia:') ||
              id.startsWith('dialogueSource:') ||
              id == 'projectMediaCatalog')
            if (replacements[id] ?? original.findResourceBytes(id)
                case final bytes?)
              id: bytes
    },
  );
  validateResourceLibraryMapScopes(projected);
  return draft;
}

import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../references/resource_usage_documents.dart';
import '../../references/resource_usage_walk.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'asset_store.dart';
import 'resource_information_document.dart';
import 'tileset_actions.dart';

List<int> encodeSourceManifest(
        ProjectSnapshot snapshot, ProjectManifest next) =>
    encodeResourceInformationDocument(snapshot, next);

AuthoringMutationDraft replaceResourceSourceReferences(
    ProjectSnapshot snapshot, AssetRecord before, AssetRecord after) {
  final issues = <String>[];
  final documents = resourceUsageDocuments(snapshot, issues);
  final manifestJson = Map<String, dynamic>.from(snapshot.manifest.toJson());
  final changedOwners = <String>[];
  for (final doc in documents) {
    final matches = deriveAssetDocumentUsages(
        asset: before, documents: {doc.identity: doc.value});
    if (matches.isEmpty) continue;
    final logical = {
      ...resourceReferencePaths(doc.value, 'asset', before.id),
      ...resourceReferencePaths(doc.value, 'imagePath', before.logicalPath)
    };
    final immutable = doc.kind == 'borderSnapshot' ||
        doc.kind == 'border' ||
        doc.kind == 'smartTileDraft' ||
        doc.kind == 'preset';
    if (immutable) {
      if (before.logicalPath == after.logicalPath &&
          resourceReferencePaths(doc.value, 'imagePath', before.logicalPath)
              .isNotEmpty) {
        throw VisualLibraryException('tileset.immutable_path_blocking',
            'A published snapshot reads this stable path. Preserve its version through its owner before replacing pixels.');
      }
      continue;
    }
    final matchesLogicalIdentity = logical.isNotEmpty;
    if (!matchesLogicalIdentity) continue;
    if (doc.kind == 'character' ||
        doc.kind == 'cinematicMedia' ||
        doc.kind == 'media') {
      throw VisualLibraryException('tileset.specialized_owner_required',
          'A specialized portrait, clip or media owner references this logical source. Use that owner to replace it.',
          details: {'ownerKind': doc.kind, 'ownerId': doc.id});
    }
    if (doc.kind == 'map' ||
        doc.kind == 'pokemonMedia' ||
        doc.kind == 'dialogueSource') {
      if (before.logicalPath != after.logicalPath) {
        throw VisualLibraryException('tileset.external_document_owner_required',
            'This path change requires its map, Pokemon or dialogue owner guard.',
            details: {'ownerKind': doc.kind, 'ownerId': doc.id});
      }
      continue;
    }
    final updated = _replaceReferences(doc.value, before, after);
    if (jsonEncode(updated) == jsonEncode(doc.value)) continue;
    changedOwners.add(doc.identity);
    _replaceDocument(manifestJson, doc, updated);
  }
  final next = ProjectManifest.fromJson(manifestJson);
  ProjectValidator.validate(next);
  final changes = <AuthoringResourceChange>[];
  final entries = <AuthoringDiffEntry>[];
  if (next != snapshot.manifest) {
    final resource = AuthoringResourceRef(
        kind: 'project',
        id: 'project',
        revision: snapshot.resourceFingerprints['project']);
    changes.add(AuthoringResourceChange(
        resource: resource,
        storageKey: 'project.json',
        beforeBytes: snapshot.resourceBytes('project'),
        afterBytes: encodeSourceManifest(snapshot, next)));
    entries.add(AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: '/resourceSourceReferences',
        before: before.logicalPath,
        after: after.logicalPath));
  }
  return AuthoringMutationDraft(
      changeSet: changes.isEmpty
          ? AuthoringChangeSet.noChanges()
          : AuthoringChangeSet(changes: changes, diff: AuthoringDiff(entries)),
      projectedProject: next,
      preview: {
        'mutableOwners': changedOwners
      },
      referenceImpact: {
        'mutableOwners': changedOwners,
        'immutableVersionsPreserved': true
      });
}

Map<String, dynamic> _replaceReferences(
    Map<String, dynamic> value, AssetRecord before, AssetRecord after) {
  final paths =
      resourceReferencePaths(value, 'imagePath', before.logicalPath).toSet();
  Object? walk(Object? current, String path) {
    if (current is Map) {
      final map = Map<String, dynamic>.from(current);
      if (map['assetId'] == before.id || map['sourceAssetId'] == before.id) {
        for (final key in ['artifact', 'sourceArtifact']) {
          final reference = map[key];
          if (reference is Map &&
              reference['digest'] == before.artifact.digest) {
            map[key] = after.artifact.toJson();
          }
        }
        if (map['artifactHandle'] == before.artifact.handle) {
          map['artifactHandle'] = after.artifact.handle;
        }
        if (map['sha256'] == before.artifact.digest) {
          map['sha256'] = after.artifact.digest;
        }
      }
      return {
        for (final entry in map.entries)
          entry.key: walk(entry.value, '$path.${entry.key}')
      };
    }
    if (current is List) {
      return [
        for (var i = 0; i < current.length; i++) walk(current[i], '$path[$i]')
      ];
    }
    return paths.contains(path) ? after.logicalPath : current;
  }

  return Map<String, dynamic>.from(walk(value, r'$') as Map);
}

void _replaceDocument(Map<String, dynamic> manifest, ResourceUsageDocument doc,
    Map<String, dynamic> next) {
  final match = RegExp(r'^([A-Za-z]+)(?:\.([A-Za-z]+))?\[(\d+)\]$')
      .firstMatch(doc.origin);
  if (doc.kind == 'project') {
    manifest.addAll(next);
  } else if (match != null) {
    final root = manifest[match.group(1)];
    final entries =
        match.group(2) == null ? root : (root as Map)[match.group(2)];
    (entries as List)[int.parse(match.group(3)!)] = next;
  } else {
    throw VisualLibraryException('tileset.mutable_owner_unsupported',
        'The source owner cannot be updated by this composed operation.',
        details: {'ownerKind': doc.kind, 'ownerId': doc.id});
  }
}

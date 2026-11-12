import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../references/resource_usage_projection.dart';
import '../../references/resource_usage_report.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'tileset_actions.dart';

final class ResourceUsageReplacementActions {
  const ResourceUsageReplacementActions();

  static const actionId = 'resource.usages.replace';

  static final List<AuthoringActionDescriptor> descriptors = [
    visualLibraryDescriptor(
      actionId,
      'Repoint every map occurrence of one décor or 3D model to a compatible replacement',
      risk: AuthoringRiskLevel.high,
      resourceKinds: const ['project', 'map'],
      inputSchema: {
        'type': 'object',
        'additionalProperties': false,
        'required': ['family', 'resourceId', 'replacementId'],
        'properties': {
          'family': {
            'type': 'string',
            'enum': ['decors', 'models3d']
          },
          'resourceId': {'type': 'string', 'minLength': 1},
          'replacementId': {'type': 'string', 'minLength': 1}
        }
      },
    ),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters)
      ..allow(const {'family', 'resourceId', 'replacementId'});
    final family = parameters.string('family');
    if (family != 'decors' && family != 'models3d') {
      throw VisualLibraryException('resource.usages.family_unsupported',
          'Only décor and 3D model usages can be replaced.',
          details: {'family': family});
    }
    final spatial = family == 'models3d';
    final resourceId = parameters.string('resourceId');
    final replacementId = parameters.string('replacementId');
    final snapshot = context.snapshot;
    final manifest = snapshot.manifest;
    final elements = {for (final entry in manifest.elements) entry.id: entry};
    final models = {for (final entry in manifest.models3d) entry.id: entry};
    final sources = spatial ? models : elements;
    final others = spatial ? elements : models;
    if (!sources.containsKey(resourceId)) {
      throw VisualLibraryException(
          'resource.usages.source_unknown', 'The replaced resource no longer exists.',
          details: {'family': family, 'resourceId': resourceId});
    }
    if (replacementId == resourceId) {
      throw VisualLibraryException('resource.usages.replacement_same',
          'Choose a different resource as the replacement.',
          details: {'resourceId': resourceId});
    }
    if (!sources.containsKey(replacementId)) {
      throw others.containsKey(replacementId)
          ? VisualLibraryException('resource.usages.replacement_incompatible',
              'A décor and a 3D model cannot replace each other.',
              details: {'family': family, 'replacementId': replacementId})
          : VisualLibraryException('resource.usages.replacement_unknown',
              'The replacement resource no longer exists.',
              details: {'family': family, 'replacementId': replacementId});
    }
    final report = const ResourceUsageProjection()
        .analyze(snapshot, ResourceUsageTarget(family: family, id: resourceId));
    final loadedMaps = snapshot.maps.map((map) => map.id).toSet();
    final declaredMaps = manifest.maps.map((map) => map.id).toSet();
    final scoped = snapshot.materializedCatalogProject &&
        snapshot.scopedStorageRevisions != null;
    if (!scoped && !report.complete ||
        !loadedMaps.containsAll(declaredMaps) ||
        !declaredMaps.containsAll(loadedMaps)) {
      throw VisualLibraryException('resource.usages.inventory_incomplete',
          'The project usage inventory is incomplete. Nothing was replaced.',
          details: {'coverageIssues': report.coverageIssues});
    }
    final pattern = spatial
        ? RegExp(r'^\$\.spatialScene\.instances\[(\d+)\]\.modelId$')
        : RegExp(r'^\$\.placedElements\[(\d+)\]\.elementId$');
    final occurrences = <String, List<int>>{};
    final borderIds = <String>{};
    final borderMaps = <String>{};
    final unsupported = <ResourceUsageEntry>[];
    for (final entry in report.entries) {
      if (spatial && entry.ownerKind == 'border') {
        borderIds.add(entry.ownerId);
        continue;
      }
      final mapId = entry.mapId;
      final prefix = 'map:$mapId:';
      final local = mapId != null &&
              entry.ownerKind == 'map' &&
              entry.location.startsWith(prefix)
          ? entry.location.substring(prefix.length)
          : null;
      if (spatial &&
          local != null &&
          entry.relation != ResourceUsageRelation.direct &&
          local.endsWith('.blueprintId')) {
        borderMaps.add(mapId!);
        continue;
      }
      final match =
          local != null && entry.relation == ResourceUsageRelation.direct
              ? pattern.firstMatch(local)
              : null;
      if (match == null) {
        unsupported.add(entry);
      } else {
        occurrences.putIfAbsent(mapId!, () => []).add(int.parse(match[1]!));
      }
    }
    if (unsupported.isNotEmpty) {
      throw VisualLibraryException('resource.usages.unsupported_usages',
          'Some usages are not map placements or Border pieces and cannot be replaced here. Nothing was replaced.',
          details: {
            'usages': [for (final entry in unsupported) entry.toJson()]
          });
    }
    if (occurrences.isEmpty && borderIds.isEmpty) {
      return AuthoringMutationDraft(
          changeSet: AuthoringChangeSet.noChanges(),
          preview: _preview(family, resourceId, replacementId, const []));
    }
    final interchangeable = spatial && _interchangeable(models[resourceId]!, models[replacementId]!);
    final borderCatalog = manifest.borderCatalog;
    final project = borderIds.isEmpty
        ? manifest
        : manifest.copyWith(
            borderCatalog: ProjectBorderCatalog(
                formatVersion: borderCatalog.formatVersion,
                records: [
                  for (final record in borderCatalog.records)
                    borderIds.contains(record.id)
                        ? repointModelInBorderRecord(record,
                            modelId: resourceId,
                            replacementId: replacementId,
                            formatVersion: borderCatalog.formatVersion)
                        : record
                ],
                visualSnapshots: borderCatalog.visualSnapshots));
    final tileSize = PixelSize(
        width: manifest.settings.tileWidth,
        height: manifest.settings.tileHeight);
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    final scope = <Map<String, Object?>>[];
    for (final map in snapshot.maps) {
      if (!occurrences.containsKey(map.id) && !borderMaps.contains(map.id)) {
        continue;
      }
      final owned = {
        for (final layer in map.layers.whereType<BorderLayer>())
          for (final feature in layer.content.features)
            if (borderIds.contains(feature.blueprintId))
              ...feature.generatedPlacementIds
      };
      final regenerates = map.layers.whereType<BorderLayer>().any((layer) =>
          layer.content.features
              .any((feature) => borderIds.contains(feature.blueprintId)));
      final instanceIds = [
        for (final index in occurrences[map.id] ?? const <int>[])
          spatial
              ? map.spatialScene!.instances[index].id
              : map.placedElements[index].id
      ];
      final direct = [
        for (final id in instanceIds)
          if (!owned.contains(id)) id
      ];
      var next = map;
      for (final instanceId in direct) {
        try {
          next = spatial
              ? replaceSpatialInstanceModel(next,
                  instanceId: instanceId, model: models[replacementId]!)
              : replaceMapPlacedElementResource(next,
                  instanceId: instanceId,
                  element: elements[replacementId]!,
                  tileSize: tileSize);
        } on MapResourceReplacementException catch (refusal) {
          if (interchangeable &&
              refusal.reason == MapResourceReplacementRefusal.borderOwned) {
            final scene = next.spatialScene!;
            next = next.copyWith(
                spatialScene: scene.copyWith(instances: [
              for (final instance in scene.instances)
                instance.id == instanceId
                    ? instance.copyWith(modelId: replacementId)
                    : instance
            ]));
            continue;
          }
          throw VisualLibraryException(
              'resource.usages.replacement_incompatible',
              'An occurrence cannot use the replacement. Nothing was replaced.',
              details: {
                'mapId': map.id,
                'instanceId': instanceId,
                'reason': refusal.reason.name
              });
        }
      }
      if (regenerates) {
        try {
          next = repointModelInMap(next,
              before: manifest,
              after: project,
              modelId: resourceId,
              replacementId: replacementId,
              blueprintIds: borderIds,
              keepStaleBorders: interchangeable);
        } on Model3dMergeException catch (refusal) {
          throw VisualLibraryException(
              'resource.usages.border_regeneration_refused',
              'A Border using this model cannot be regenerated identically. Nothing was replaced.',
              details: {
                'mapId': refusal.mapId,
                'featureId': refusal.featureId,
                'reason': refusal.reason.name
              });
        }
      }
      if (next == map) continue;
      MapValidator.validate(next,
          projectDialogueContext: scoped ? null : project);
      final repointed = [
        ...direct,
        for (final id in owned)
          if (next.spatialScene?.instances
                  .any((instance) => instance.id == id) ==
              true)
            id
      ];
      final resource = AuthoringResourceRef(
          kind: 'map',
          id: map.id,
          revision: snapshot.resourceFingerprints['map:${map.id}']);
      changes.add(AuthoringResourceChange(
          resource: resource,
          storageKey: manifest.maps
              .singleWhere((entry) => entry.id == map.id)
              .relativePath,
          beforeBytes: snapshot.resourceBytes('map:${map.id}'),
          afterBytes: encodeMapAuthoringDocument(next)));
      diffs.add(AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: spatial ? '/spatialScene/instances' : '/placedElements',
          before: {for (final id in repointed) id: resourceId},
          after: {for (final id in repointed) id: replacementId}));
      scope.add({
        'mapId': map.id,
        'mapName': map.name,
        'instanceIds': repointed,
      });
    }
    final sortedBorders = borderIds.toList()..sort();
    if (borderIds.isNotEmpty) {
      final manifestDraft = buildVisualManifestDraft(snapshot, project,
          operation: actionId,
          path: '/borderCatalog/records',
          validateProject: !scoped,
          before: {for (final id in sortedBorders) id: resourceId},
          after: {for (final id in sortedBorders) id: replacementId});
      changes.addAll(manifestDraft.changeSet.changes);
      diffs.addAll(manifestDraft.changeSet.diff.entries);
    }
    return AuthoringMutationDraft(
      changeSet:
          AuthoringChangeSet(changes: changes, diff: AuthoringDiff(diffs)),
      projectedProject: borderIds.isEmpty ? null : project,
      preview: {
        ..._preview(family, resourceId, replacementId, scope),
        if (borderIds.isNotEmpty) 'definitionsUnchanged': false,
        if (borderIds.isNotEmpty) 'repointedBorderIds': sortedBorders,
      },
      referenceImpact: {
        'replacedMapIds': [for (final entry in scope) entry['mapId']],
        'occurrenceCount': _occurrenceCount(scope),
        'definitionsUnchanged': borderIds.isEmpty,
        if (borderIds.isNotEmpty) 'repointedBorderIds': sortedBorders,
      },
    );
  }

  bool _interchangeable(ProjectModel3dEntry model, ProjectModel3dEntry other) {
    Map<String, Object?> settings(ProjectModel3dEntry value) => value.toJson()
      ..remove('id')
      ..remove('name')
      ..remove('sourceAssetId')
      ..remove('relativePath');
    return jsonEncode(settings(model)) == jsonEncode(settings(other));
  }

  Map<String, Object?> _preview(String family, String resourceId,
          String replacementId, List<Map<String, Object?>> scope) =>
      {
        'operation': actionId,
        'family': family,
        'resourceId': resourceId,
        'replacementId': replacementId,
        'noOp': scope.isEmpty,
        'mapCount': scope.length,
        'occurrenceCount': _occurrenceCount(scope),
        'maps': scope,
        'definitionsUnchanged': true,
      };

  int _occurrenceCount(List<Map<String, Object?>> scope) => scope.fold(
      0, (total, entry) => total + (entry['instanceIds'] as List).length);
}

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
    if (!report.complete ||
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
    final unsupported = <ResourceUsageEntry>[];
    for (final entry in report.entries) {
      final mapId = entry.mapId;
      final prefix = 'map:$mapId:';
      final match = mapId != null &&
              entry.ownerKind == 'map' &&
              entry.relation == ResourceUsageRelation.direct &&
              entry.location.startsWith(prefix)
          ? pattern.firstMatch(entry.location.substring(prefix.length))
          : null;
      if (match == null) {
        unsupported.add(entry);
      } else {
        occurrences.putIfAbsent(mapId!, () => []).add(int.parse(match[1]!));
      }
    }
    if (unsupported.isNotEmpty) {
      throw VisualLibraryException('resource.usages.unsupported_usages',
          'Some usages are not map placements and cannot be replaced here. Nothing was replaced.',
          details: {
            'usages': [for (final entry in unsupported) entry.toJson()]
          });
    }
    if (occurrences.isEmpty) {
      return AuthoringMutationDraft(
          changeSet: AuthoringChangeSet.noChanges(),
          preview: _preview(family, resourceId, replacementId, const []));
    }
    final tileSize = PixelSize(
        width: manifest.settings.tileWidth,
        height: manifest.settings.tileHeight);
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    final scope = <Map<String, Object?>>[];
    for (final map in snapshot.maps) {
      final indexes = occurrences[map.id];
      if (indexes == null) continue;
      final instanceIds = [
        for (final index in indexes)
          spatial
              ? map.spatialScene!.instances[index].id
              : map.placedElements[index].id
      ];
      var next = map;
      for (final instanceId in instanceIds) {
        try {
          next = spatial
              ? replaceSpatialInstanceModel(next,
                  instanceId: instanceId, model: models[replacementId]!)
              : replaceMapPlacedElementResource(next,
                  instanceId: instanceId,
                  element: elements[replacementId]!,
                  tileSize: tileSize);
        } on MapResourceReplacementException catch (refusal) {
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
      MapValidator.validate(next, projectDialogueContext: manifest);
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
          before: {for (final id in instanceIds) id: resourceId},
          after: {for (final id in instanceIds) id: replacementId}));
      scope.add({
        'mapId': map.id,
        'mapName': map.name,
        'instanceIds': instanceIds,
      });
    }
    return AuthoringMutationDraft(
      changeSet:
          AuthoringChangeSet(changes: changes, diff: AuthoringDiff(diffs)),
      preview: _preview(family, resourceId, replacementId, scope),
      referenceImpact: {
        'replacedMapIds': [for (final entry in scope) entry['mapId']],
        'occurrenceCount': _occurrenceCount(scope),
        'definitionsUnchanged': true,
      },
    );
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

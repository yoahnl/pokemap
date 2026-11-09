import 'package:map_core/map_core.dart';

import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/change_set.dart';
import '../assets/tileset_actions.dart';
import 'map_lifecycle_adapter.dart';

final class MapLibraryActions {
  const MapLibraryActions();

  static final descriptors = [
    visualLibraryDescriptor(
      'map.library.reorganize',
      'Organize map folders and map placements without changing map content',
      resourceKinds: const ['project', 'map'],
    ),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final groupAdditions = context.snapshot.materializedCatalogProject &&
      context.snapshot.availableProjectSections?.length == 1 && context.snapshot.availableProjectSections!.contains('groups');
    final fields = VisualLibraryParameters(context.request.parameters);
    fields.allow(const {'groups', 'assignments'});
    final next = reorganize(
      context.snapshot.manifest,
      groups: context.request.parameters.containsKey('groups')
          ? fields.objects('groups').map((group) {
              VisualLibraryParameters(group).allow(const {
                'id',
                'name',
                'type',
                'parentGroupId',
                'sortOrder',
                'tags',
                'properties',
              });
              return ProjectMapGroup.fromJson(Map<String, dynamic>.from(group));
            }).toList()
          : null,
      assignments: fields.objects('assignments'),
      groupAdditionsOnly: groupAdditions,
    );
    final groupIds = next.groups.map((group) => group.id).toSet();
    final removedGroupIds = context.snapshot.manifest.groups.map((group) => group.id).where((id) => !groupIds.contains(id)).toSet();
    if (groupAdditions) {
      if (context.snapshot.manifest.groups.any((group) => !next.groups.contains(group)) || fields.objects('assignments').isNotEmpty) _reject('group_addition_scope_invalid');
      final resource = AuthoringResourceRef(kind: 'project', id: 'project', revision: context.snapshot.resourceFingerprints['project']);
      return AuthoringMutationDraft(changeSet: AuthoringChangeSet(changes: [AuthoringResourceChange(resource: resource,
        storageKey: 'project.json', beforeBytes: context.snapshot.resourceBytes('project'), afterBytes: encodeProjectAuthoringDocument(context.snapshot, next))],
        diff: AuthoringDiff([AuthoringDiffEntry(operation: AuthoringDiffOperation.replace, resource: resource, path: '/groups',
          before: context.snapshot.manifest.groups.map((group) => group.toJson()).toList(), after: next.groups.map((group) => group.toJson()).toList())])),
        preview: {'operation': 'map.library.reorganize', 'groupAdditionsOnly': true}, referenceImpact: const {'mapContentUnchanged': true});
    }
    if (removedGroupIds.isNotEmpty) {
      for (final entry in context.snapshot.manifest.maps) {
        final map = context.snapshot.mapById(entry.id);
        if (map == null) {
          _reject('map_document_missing_for_group_removal');
        }
        if (removedGroupIds.contains(map.mapMetadata.escapeRopeDungeonId)) {
          _reject('group_in_use_by_escape_rope');
        }
      }
    }
    return buildVisualManifestDraft(
      context.snapshot,
      next,
      operation: 'map.library.reorganize',
      path: '/',
      before: {
        'groups':
            context.snapshot.manifest.groups.map((g) => g.toJson()).toList(),
        'maps': context.snapshot.manifest.maps.map((m) => m.toJson()).toList(),
      },
      after: {
        'groups': next.groups.map((g) => g.toJson()).toList(),
        'maps': next.maps.map((m) => m.toJson()).toList(),
      },
      referenceImpact: const {'mapContentUnchanged': true},
    );
  }

  ProjectManifest reorganize(
    ProjectManifest manifest, {
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
    bool groupAdditionsOnly = false,
  }) {
    final folders = groups ?? manifest.groups;
    final folderIds = folders.map((g) => g.id).toSet();
    if (folderIds.length != folders.length ||
        folders.any((g) =>
            g.id.trim().isEmpty || g.name.trim().isEmpty || g.sortOrder < 0)) {
      _reject('groups_invalid');
    }
    final siblingNames = <String, Set<String>>{};
    for (final folder in folders) {
      final names =
          siblingNames.putIfAbsent(folder.parentGroupId ?? '', () => {});
      if (!names.add(folder.name.trim().toLowerCase())) {
        _reject('sibling_name_conflict');
      }
    }
    for (final removed
        in manifest.groups.where((g) => !folderIds.contains(g.id))) {
      if (manifest.maps.any((m) => m.groupId == removed.id) ||
          manifest.groups.any((g) => g.parentGroupId == removed.id)) {
        _reject('group_not_empty');
      }
    }
    final entries = {for (final map in manifest.maps) map.id: map};
    final moved = <String>{};
    for (final assignment in assignments) {
      final fields = VisualLibraryParameters(assignment);
      fields.allow(const {'mapId', 'groupId', 'sortOrder'});
      final id = fields.string('mapId');
      final original = entries[id];
      final group = assignment['groupId'];
      final order = assignment['sortOrder'];
      if (original == null ||
          !moved.add(id) ||
          !assignment.containsKey('groupId') ||
          (group != null && (group is! String || !folderIds.contains(group))) ||
          (assignment.containsKey('sortOrder') &&
              (order is! int || order < 0))) {
        _reject('assignment_invalid');
      }
      entries[id] = original.copyWith(
        groupId: group as String?,
        sortOrder: order as int? ?? original.sortOrder,
      );
    }
    final next = manifest.copyWith(
      groups: folders,
      maps: [for (final map in manifest.maps) entries[map.id]!],
    );
    if (groupAdditionsOnly) {
      ProjectValidator.validateMapGroupHierarchy(next.groups);
    } else {
      ProjectValidator.validate(next);
    }
    return next;
  }
}

Never _reject(String code) => throw VisualLibraryException(
      'map.library.$code',
      'The map folder organization is invalid.',
    );

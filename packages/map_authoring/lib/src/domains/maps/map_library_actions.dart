import 'package:map_core/map_core.dart';

import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

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
    );
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
  }) {
    final folders = groups ?? manifest.groups;
    final folderIds = folders.map((g) => g.id).toSet();
    if (folderIds.length != folders.length ||
        folders.any((g) =>
            g.id.trim().isEmpty || g.name.trim().isEmpty || g.sortOrder < 0)) {
      _reject('groups_invalid');
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
    ProjectValidator.validate(next);
    return next;
  }
}

Never _reject(String code) => throw VisualLibraryException(
      'map.library.$code',
      'The map folder organization is invalid.',
    );

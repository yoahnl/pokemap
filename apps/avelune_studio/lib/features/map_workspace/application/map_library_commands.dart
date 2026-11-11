import 'package:map_core/map_core_domain.dart';

import 'map_workspace_controller.dart';

typedef OrganizeMapLibrary = Future<String?> Function({
  List<ProjectMapGroup>? groups,
  required List<Map<String, Object?>> assignments,
});

void Function(String) mapLibraryOpenAction(
  ProjectManifest project,
  void Function(ProjectMapEntry) activate,
  void Function()? close,
) => (id) {
  final entry = project.maps.where((entry) => entry.id == id).firstOrNull;
  if (entry == null) return;
  close?.call();
  activate(entry);
};

Future<String?> organizeWorkspaceMaps(
  MapWorkspaceController controller, {
  List<ProjectMapGroup>? groups,
  required List<Map<String, Object?>> assignments,
}) async {
  final result = await controller.mutateCatalog('map.library.reorganize', {
    if (groups != null)
      'groups': groups.map((group) => group.toJson()).toList(),
    'assignments': assignments,
  });
  return result.integrated
      ? null
      : result.published
      ? 'L’organisation est enregistrée sur disque. ${result.error ?? ''} Relisez le catalogue avant une autre opération.'
      : result.error ?? 'Organisation impossible.';
}

class WorkspaceMapLibraryCommands {
  WorkspaceMapLibraryCommands({required this.project, required this.submit});
  final ProjectManifest Function() project;
  final OrganizeMapLibrary submit;
  String? lastCreatedGroupId;

  List<ProjectMapGroup> siblings(ProjectMapGroup group) =>
      project().groups
          .where((item) => item.parentGroupId == group.parentGroupId)
          .toList()
        ..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          return order == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : order;
        });

  List<ProjectMapGroup> parentCandidates(String groupId) {
    final excluded = <String>{groupId};
    bool changed;
    do {
      changed = false;
      for (final item in project().groups) {
        if (excluded.contains(item.parentGroupId) && excluded.add(item.id)) {
          changed = true;
        }
      }
    } while (changed);
    return project().groups
        .where((item) => !excluded.contains(item.id))
        .toList();
  }

  Future<String?> createFolder(String name, {String? parentId}) async {
    final groups = project().groups;
    if (groups.any(
      (group) =>
          group.parentGroupId == parentId &&
          group.name.trim().toLowerCase() == name.trim().toLowerCase(),
    )) {
      return 'Un dossier du même nom existe déjà ici.';
    }
    final id = 'studio_folder_${DateTime.now().microsecondsSinceEpoch}';
    final error = await submit(
      groups: [
        ...groups,
        ProjectMapGroup(
          id: id,
          name: name.trim(),
          type: MapGroupType.special,
          parentGroupId: parentId,
          sortOrder: groups.length,
        ),
      ],
      assignments: const [],
    );
    if (error == null) lastCreatedGroupId = id;
    return error;
  }

  Future<String?> updateFolder(ProjectMapGroup replacement) {
    final groups = project().groups;
    if (groups.any(
      (item) =>
          item.id != replacement.id &&
          item.parentGroupId == replacement.parentGroupId &&
          item.name.trim().toLowerCase() ==
              replacement.name.trim().toLowerCase(),
    )) {
      return Future.value('Un dossier du même nom existe déjà ici.');
    }
    return submit(
      groups: [
        for (final item in groups)
          item.id == replacement.id ? replacement : item,
      ],
      assignments: const [],
    );
  }

  bool canDeleteFolder(String id) =>
      !project().maps.any((map) => map.groupId == id) &&
      !project().groups.any((group) => group.parentGroupId == id);

  Future<String?> deleteFolder(String id) {
    if (!canDeleteFolder(id)) {
      return Future.value(
        'Déplacez les cartes et les sous-dossiers avant de supprimer ce dossier.',
      );
    }
    return submit(
      groups: project().groups.where((group) => group.id != id).toList(),
      assignments: const [],
    );
  }

  Future<String?> reorderFolder(
    ProjectMapGroup group, {
    required bool forward,
  }) {
    final ordered = siblings(group);
    final index = ordered.indexWhere((item) => item.id == group.id);
    final target = index + (forward ? 1 : -1);
    if (index < 0 || target < 0 || target >= ordered.length) {
      return Future.value();
    }
    ordered.insert(target, ordered.removeAt(index));
    final orders = {for (var i = 0; i < ordered.length; i++) ordered[i].id: i};
    return submit(
      groups: [
        for (final item in project().groups)
          orders.containsKey(item.id)
              ? item.copyWith(sortOrder: orders[item.id]!)
              : item,
      ],
      assignments: const [],
    );
  }
}

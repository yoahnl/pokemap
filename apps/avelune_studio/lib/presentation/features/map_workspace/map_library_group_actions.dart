part of 'map_library_navigator.dart';

extension _MapLibraryGroupActions on _MapLibraryNavigatorState {
  List<ProjectMapGroup> _siblings(ProjectMapGroup group) =>
      (widget.project.groups
          .where((value) => value.parentGroupId == group.parentGroupId)
          .toList()
        ..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          return order == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : order;
        }));

  Map<MapLibraryAction, String> _groupDisabled(ProjectMapGroup group) {
    final siblings = _siblings(group),
        index = siblings.indexWhere((item) => item.id == group.id);
    return {
      if (index <= 0) MapLibraryAction.up: 'premier dossier',
      if (index >= siblings.length - 1)
        MapLibraryAction.down: 'dernier dossier',
      if (widget.onCreateMap == null)
        MapLibraryAction.createMap: 'création indisponible',
      if (widget.onOrganize == null)
        for (final action in MapLibraryAction.values.where(
          (value) => value != MapLibraryAction.createMap,
        ))
          action: 'organisation indisponible',
    };
  }

  Future<void> _groupAction(
    ProjectMapGroup group,
    MapLibraryAction action,
  ) async {
    if (_busy || widget.onOrganize == null) return;
    if (action == MapLibraryAction.up || action == MapLibraryAction.down) {
      final siblings = _siblings(group),
          index = siblings.indexWhere((item) => item.id == group.id);
      final target = index + (action == MapLibraryAction.up ? -1 : 1);
      if (index < 0 || target < 0 || target >= siblings.length) return;
      final moved = siblings.removeAt(index);
      siblings.insert(target, moved);
      final orders = {
        for (var i = 0; i < siblings.length; i++) siblings[i].id: i,
      };
      await _submitOrganization(
        groups: [
          for (final item in widget.project.groups)
            orders.containsKey(item.id)
                ? item.copyWith(sortOrder: orders[item.id]!)
                : item,
        ],
        assignments: const [],
      );
      return;
    }
    if (action == MapLibraryAction.deleteFolder) {
      final maps = widget.project.maps
          .where((map) => map.groupId == group.id)
          .length;
      final children = widget.project.groups
          .where((item) => item.parentGroupId == group.id)
          .length;
      await showMapCatalogueForm(
        context,
        title: 'Supprimer le dossier',
        submitLabel: 'Supprimer',
        valid: () => maps == 0 && children == 0,
        fields: (_, _) => Text(
          maps > 0 || children > 0
              ? 'Ce dossier contient $maps carte(s) et $children sous-dossier(s). Déplacez-les d’abord. Aucune carte ne sera supprimée.'
              : 'Supprimer « ${group.name} » ? Ce dossier est vide. Aucune carte ne sera supprimée.',
        ),
        submit: () => _submitOrganization(
          groups: widget.project.groups
              .where((item) => item.id != group.id)
              .toList(),
          assignments: const [],
        ),
      );
      return;
    }
    var name = group.name, parent = group.parentGroupId ?? '';
    final excluded = <String>{group.id};
    bool changed;
    do {
      changed = false;
      for (final item in widget.project.groups) {
        if (excluded.contains(item.parentGroupId) && excluded.add(item.id)) {
          changed = true;
        }
      }
    } while (changed);
    final rename = action == MapLibraryAction.rename;
    await showMapCatalogueForm(
      context,
      title: rename ? 'Renommer le dossier' : 'Déplacer le dossier',
      submitLabel: 'Enregistrer',
      valid: () => name.trim().isNotEmpty,
      fields: (refresh, busy) => rename
          ? StudioDraftField(
              value: name,
              label: 'Nom du dossier',
              enabled: !busy,
              onChanged: (value) {
                name = value;
                refresh();
              },
            )
          : StudioSelect(
              label: 'Dossier parent',
              value: parent,
              options: mapLibraryFolderLabels(
                widget.project.groups
                    .where((item) => !excluded.contains(item.id))
                    .toList(),
              ),
              onChanged: busy
                  ? null
                  : (value) {
                      parent = value;
                      refresh();
                    },
            ),
      submit: () {
        final replacement = group.copyWith(
          name: name.trim(),
          parentGroupId: parent.isEmpty ? null : parent,
        );
        if (widget.project.groups.any(
          (item) =>
              item.id != group.id &&
              item.parentGroupId == replacement.parentGroupId &&
              item.name.trim().toLowerCase() == replacement.name.toLowerCase(),
        )) {
          return Future.value('Un dossier du même nom existe déjà ici.');
        }
        return _submitOrganization(
          groups: [
            for (final item in widget.project.groups)
              item.id == group.id ? replacement : item,
          ],
          assignments: const [],
          onSuccess: () => _revealFolder(parent),
        );
      },
    );
  }
}

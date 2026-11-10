part of 'map_library_navigator.dart';

extension _MapLibraryGroupActions on _MapLibraryNavigatorState {
  List<ProjectMapGroup> _siblings(ProjectMapGroup group) =>
      _libraryCommands.siblings(group);

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
      await _libraryCommands.reorderFolder(
        group,
        forward: action == MapLibraryAction.down,
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
        submit: () => _libraryCommands.deleteFolder(group.id),
      );
      return;
    }
    var name = group.name, parent = group.parentGroupId ?? '';
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
                _libraryCommands.parentCandidates(group.id),
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
        return _libraryCommands.updateFolder(replacement).then((error) {
          if (mounted && error == null) _update(() => _revealFolder(parent));
          return error;
        });
      },
    );
  }
}

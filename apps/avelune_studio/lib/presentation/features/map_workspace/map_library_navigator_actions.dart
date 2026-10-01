part of 'map_library_navigator.dart';

extension _MapLibraryActions on _MapLibraryNavigatorState {
  Future<void> _createFolderDialog() async {
    if (_creating || _busy) return;
    _creating = true;
    _name = '';
    _parent = _folderSelection ?? '';
    await showMapCatalogueForm(
      context,
      title: 'Nouveau dossier',
      submitLabel: 'Créer',
      valid: () => _name.trim().isNotEmpty,
      fields: (refresh, busy) => Column(
        children: [
          StudioDraftField(
            value: _name,
            label: 'Nom du dossier',
            enabled: !busy,
            onChanged: (value) {
              _name = value;
              refresh();
            },
          ),
          const SizedBox(height: 12),
          StudioSelect(
            label: 'Dossier parent',
            value: _parent,
            options: mapLibraryFolderLabels(widget.project.groups),
            onChanged: busy
                ? null
                : (value) {
                    _parent = value;
                    refresh();
                  },
          ),
        ],
      ),
      submit: () async {
        final name = _name.trim(), parentId = _parent.isEmpty ? null : _parent;
        final groups = widget.project.groups;
        if (groups.any(
          (group) =>
              group.parentGroupId == parentId &&
              group.name.trim().toLowerCase() == name.toLowerCase(),
        )) {
          return 'Un dossier du même nom existe déjà ici.';
        }
        final id = 'studio_folder_${DateTime.now().microsecondsSinceEpoch}';
        return _submitOrganization(
          groups: [
            ...groups,
            ProjectMapGroup(
              id: id,
              name: name,
              type: MapGroupType.special,
              parentGroupId: parentId,
              sortOrder: groups.length,
            ),
          ],
          assignments: const [],
          onSuccess: () {
            _collapsed.remove(parentId);
            _folderSelection = id;
          },
        );
      },
    );
    _creating = false;
  }

  Future<String?> _submitOrganization({
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
    VoidCallback? onSuccess,
  }) async {
    final action = widget.onOrganize;
    if (_busy || action == null) return 'L’organisation est indisponible.';
    _update(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      error = await action(groups: groups, assignments: assignments);
    } on Object catch (failure) {
      error = 'Organisation impossible : $failure';
    }
    if (!mounted) return error ?? 'Le navigateur a été fermé.';
    _update(() {
      _busy = false;
      _error = error;
      if (error == null) onSuccess?.call();
    });
    return error;
  }

  Future<void> _moveSelected() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    await _submitOrganization(
      assignments: [
        for (final id in ids)
          {'mapId': id, 'groupId': _destination.isEmpty ? null : _destination},
      ],
      onSuccess: () {
        _selected.clear();
        _selecting = false;
        _revealFolder(_destination);
      },
    );
  }

  void _revealFolder(String id) {
    String? current = id.isEmpty ? '__root__' : id;
    final visited = <String>{};
    while (current != null && visited.add(current)) {
      _collapsed.remove(current);
      current = widget.project.groups
          .where((group) => group.id == current)
          .firstOrNull
          ?.parentGroupId;
    }
  }

  Future<void> _rowAction(MapLibraryRow row, MapLibraryAction action) async {
    final map = row.map;
    if (map != null) {
      if (action == MapLibraryAction.rename) {
        widget.onRenameMap?.call(map);
        return;
      }
      var destination = map.groupId ?? '';
      await showMapCatalogueForm(
        context,
        title: 'Déplacer ${map.name}',
        submitLabel: 'Déplacer',
        fields: (refresh, busy) => StudioSelect(
          label: 'Dossier de destination',
          value: destination,
          options: mapLibraryFolderLabels(widget.project.groups),
          onChanged: busy
              ? null
              : (value) {
                  destination = value;
                  refresh();
                },
        ),
        submit: () => _submitOrganization(
          assignments: [
            {
              'mapId': map.id,
              'groupId': destination.isEmpty ? null : destination,
            },
          ],
          onSuccess: () => _revealFolder(destination),
        ),
      );
      return;
    }
    final group = row.group;
    if (group == null) return;
    if (action == MapLibraryAction.createMap) {
      widget.onCreateMap?.call(group.id);
      return;
    }
    await _groupAction(group, action);
  }
}

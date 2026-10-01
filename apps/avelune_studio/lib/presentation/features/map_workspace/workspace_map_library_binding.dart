part of 'map_workspace_screen.dart';

extension _WorkspaceMapLibrary on _MapWorkspaceScreenState {
  Future<String?> _organizeMaps({
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
  }) async {
    final result = await _controller.mutateCatalog('map.library.reorganize', {
      if (groups != null)
        'groups': groups.map((group) => group.toJson()).toList(),
      'assignments': assignments,
    });
    if (mounted) _changed();
    return result.integrated
        ? null
        : result.published
        ? 'L’organisation est enregistrée sur disque. ${result.error ?? ''} Relisez le catalogue avant une autre opération.'
        : result.error ?? 'Organisation impossible.';
  }

  Future<void> _createMap([String? groupId]) =>
      createWorkspaceMap(context, _controller, groupId: groupId);
}

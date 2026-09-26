part of 'map_workspace_screen.dart';

extension _WorkspaceMapLibrary on _MapWorkspaceScreenState {
  Future<String?> _organizeMaps({
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
  }) async {
    final resources = _resources;
    if (resources == null || resources.busy) {
      return 'Les ressources du projet ne sont pas encore disponibles.';
    }
    try {
      await resources.mutate('map.library.reorganize', {
        if (groups != null)
          'groups': groups.map((group) => group.toJson()).toList(),
        'assignments': assignments,
      });
      if (mounted) _changed();
      return null;
    } on Object catch (failure) {
      return 'Organisation impossible : $failure';
    }
  }
}

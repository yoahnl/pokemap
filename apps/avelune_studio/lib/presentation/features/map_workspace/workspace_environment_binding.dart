part of 'map_workspace_screen.dart';

extension _WorkspaceEnvironments on _MapWorkspaceScreenState {
  void _openEnvironments() {
    final resources = _resources;
    if (resources == null) return;
    resources.library.selectFamily(ResourceLibraryFamily.environments);
    resources.showLibrary();
    _show(WorkspaceSpace.resources);
  }

  Future<void> _drawEnvironment(EnvironmentPreset preset) async {
    final resources = _resources;
    final project = _controller.project;
    if (resources == null || resources.busy || project == null) return;
    if (resources.environments[preset.id]?.dirty == true) {
      resources.error =
          'Enregistrez ou annulez la préparation de cet environnement avant de dessiner sa zone.';
      resources.changed();
      return;
    }
    if (_controller.active == null) {
      final entry = await showDialog<ProjectMapEntry>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une carte'),
          content: SizedBox(
            width: 420,
            height: 280,
            child: ListView(
              children: [
                for (final entry in project.maps)
                  StudioButton(
                    label: entry.name,
                    secondary: true,
                    onPressed: () => Navigator.pop(context, entry),
                  ),
              ],
            ),
          ),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      if (entry == null || !mounted || !identical(resources, _resources)) {
        return;
      }
      await _controller.activate(
        entry,
        isCurrent: () => mounted && identical(resources, _resources),
      );
    }
    final document = _controller.active;
    final current = _controller.project;
    final view = _view;
    if (!mounted ||
        document == null ||
        current == null ||
        view == null ||
        !identical(resources, _resources)) {
      return;
    }
    final selected = current.environmentPresets
        .where((entry) => entry.id == preset.id)
        .firstOrNull;
    if (selected == null) return;
    try {
      view.environment = EnvironmentEditingCommands(
        document,
        current,
      ).create(selected);
      view.tool = StudioMapTool.environment;
      _openMap();
      _toolChanged();
    } on Object catch (failure) {
      resources.error = environmentEditingMessage(failure);
      resources.changed();
    }
  }
}

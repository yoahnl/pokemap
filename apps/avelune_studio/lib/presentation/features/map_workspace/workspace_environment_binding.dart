part of 'map_workspace_screen.dart';

extension _WorkspaceEnvironments on _MapWorkspaceScreenState {
  void _openEnvironments() {
    if (!_controller.hasWorkshop(MapWorkspaceWorkshop.resources) ||
        !_controller.hasResourceKind('environmentPreset')) {
      unawaited(
        _openResourceWorkshop(() {
          _resources?.library.selectFamily(ResourceLibraryFamily.environments);
          _resources?.showLibrary();
        }, family: ResourceLibraryFamily.environments),
      );
      return;
    }
    final resources = _resources;
    if (resources == null) return;
    resources.library.selectFamily(ResourceLibraryFamily.environments);
    resources.showLibrary();
    _show(WorkspaceSpace.resources);
  }

  Future<void> _drawEnvironment(EnvironmentPreset preset) async {
    final resources = _resources;
    if (resources == null) return;
    final used = await useMapEnvironment(
      workspace: _controller,
      resources: resources,
      preset: preset,
      view: () => _view,
      isActive: () => mounted && identical(resources, _resources),
      chooseMap: (entries) => showDialog<ProjectMapEntry>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une carte'),
          content: SizedBox(
            width: 420,
            height: 280,
            child: ListView(
              children: [
                for (final entry in entries)
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
      ),
    );
    if (used) {
      _openMap();
      _toolChanged();
    }
  }
}

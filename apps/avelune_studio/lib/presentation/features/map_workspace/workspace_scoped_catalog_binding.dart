part of 'map_workspace_screen.dart';

extension _WorkspaceScopedCatalog on _MapWorkspaceScreenState {
  Future<void> _refreshScopedVisuals(ProjectManifest definitions) async {
    final visuals = _visuals;
    if (visuals == null || visuals is! ResourceWorkspaceVisuals) return;
    final generation = ++_projectionVisualGeneration;
    _projectionVisualsLoading = true;
    try {
      final queued = _projectionVisualQueue.then((_) async {
        if (!mounted ||
            generation != _projectionVisualGeneration ||
            !identical(visuals, _visuals)) {
          return;
        }
        await (visuals as ResourceWorkspaceVisuals).updateCatalog(definitions);
      });
      _projectionVisualQueue = queued.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      );
      await queued;
      if (!mounted ||
          generation != _projectionVisualGeneration ||
          !identical(visuals, _visuals)) {
        return;
      }
      _preparedMap = _controller.active?.current;
      if (_preparedMap != null) visuals.setActiveMap(_preparedMap!);
    } catch (failure) {
      if (mounted && generation == _projectionVisualGeneration) {
        _resourceError =
            'Les ressources de cette carte ne peuvent pas être chargées : $failure';
      }
    } finally {
      if (mounted && generation == _projectionVisualGeneration) {
        _projectionVisualsLoading = false;
        _changed();
      }
    }
  }

  Future<void> _materializeWorkshops({WorkspaceSpace? destination}) async {
    if (_materializingWorkshops || _controller.hasCompleteProject) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StudioReviewDialog(
        title: 'Charger tous les ateliers du projet ?',
        content: const Text(
          'Les imports, l’histoire et les autres ateliers nécessitent toutes les définitions du projet. La carte ouverte et ses brouillons seront conservés.',
        ),
        confirmLabel: 'Charger les ateliers',
        onConfirmed: () => Navigator.pop(context, true),
        onCancelled: () => Navigator.pop(context, false),
      ),
    );
    if (confirmed != true || !mounted) return;
    _materializingWorkshops = true;
    _changed();
    try {
      await _controller.materializeProject();
      if (!mounted) return;
      _projectionVisualGeneration++;
      final previous = _visuals;
      _visuals = null;
      previous?.removeListener(_changed);
      await previous?.dispose();
      _projectionVisualsLoading = false;
      _initializePokemon();
      await _initialize();
      if (mounted && destination != null) _show(destination);
    } catch (failure) {
      if (mounted) {
        _resourceError = 'Les ateliers ne peuvent pas être chargés : $failure';
      }
    } finally {
      if (mounted) {
        _materializingWorkshops = false;
        _changed();
      }
    }
  }
}

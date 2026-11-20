part of 'map_builder_page.dart';

extension _MapBuilderProjectSections on _MapBuilderPageState {
  Widget _projectHome() {
    if (_section != StudioRailSection.home || _sceneShown) {
      return const SizedBox.shrink();
    }
    final project = _maps.project;
    return ProjectHomePage(
      projectName: project?.name ?? widget.session.name,
      maps: project?.maps ?? const [],
      activeMap: _activeEntry,
      onOpenMap: _editable
          ? (entry) =>
                unawaited(_openMapFromSection(entry.id, StudioRailSection.home))
          : null,
      onSection: _setSection,
      onClose: () => unawaited(widget.onHome()),
    );
  }

  Widget _projectPokemon() => _retainedSurface(
    visible: _section == StudioRailSection.pokemon && !_sceneShown,
    child: _pokemonShown
        ? ProjectPokemonPage(
            session: widget.session,
            onImporting: _setPokemonImporting,
          )
        : const SizedBox.shrink(),
  );
}

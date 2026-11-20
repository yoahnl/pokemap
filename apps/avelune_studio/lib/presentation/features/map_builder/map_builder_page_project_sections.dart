part of 'map_builder_page.dart';

extension _MapBuilderProjectSections on _MapBuilderPageState {
  Widget _withProjectHome(Widget editor) {
    final home = _section == StudioRailSection.home && !_sceneShown;
    return IndexedStack(
      index: home ? 1 : 0,
      sizing: StackFit.expand,
      children: [
        _retainedSurface(visible: !home, child: editor),
        home ? _projectHome() : const SizedBox.shrink(),
      ],
    );
  }

  Widget _projectHome() {
    final project = _maps.project;
    final access = widget.homeProjects;
    final busy =
        widget.homeBusy ||
        _exporting ||
        _openingExport ||
        _packDialogOpen ||
        _testing;
    final canTest = _editable && _maps.active != null && _activeEntry != null;
    final canCreateMap =
        _editable &&
        project != null &&
        widget.session.storage != ProjectSessionStorage.portableCatalog;
    void resume() => _setSection(StudioRailSection.map);
    void createMap() => unawaited(
      showMapBuilderNewMapDialog(context, MapLibraryCommands(_maps)),
    );
    return StudioHomeScreen(
      key: const ValueKey('studio-project-home'),
      projectName: project?.name ?? widget.session.name,
      projectPath: widget.session.directoryPath,
      busy: busy,
      canTest: canTest,
      onOpen: access.open,
      onResume: resume,
      onExport: _editable && project != null
          ? () => unawaited(_exportGame())
          : null,
      onClose: () => unawaited(widget.onHome()),
      onCreateMap: canCreateMap ? createMap : null,
      destinations: {
        'map': resume,
        'resources': () => _setSection(StudioRailSection.resources),
        'terrains': () {
          resume();
          _setSpace(MapBuilderSpace.construction);
        },
        'story': () => _setSection(StudioRailSection.story),
        'pokemon': () => _setSection(StudioRailSection.pokemon),
        if (canTest) 'test': () => unawaited(_testMap()),
        if (canCreateMap) 'createMap': createMap,
      },
      recentProjects: access.recent,
      onRecent: (entry) {
        if (entry.directoryPath == widget.session.directoryPath) {
          resume();
        } else {
          access.openRecent(entry);
        }
      },
      onRemoveRecent: access.removeRecent,
      maps: [
        for (final map in project?.maps ?? const <ProjectMapEntry>[])
          (id: map.id, name: map.name),
      ],
      mapLibrary: project,
      mapPreviewBuilder: switch (_visuals) {
        final MapWorkspacePreviewVisuals visuals =>
          (id) => StudioHomeMapPreview(
            key: ValueKey(id),
            controller: _maps,
            visuals: visuals,
            mapId: id,
          ),
        _ => null,
      },
      onMap: (id) {
        if (_editable) {
          unawaited(_openMapFromSection(id, StudioRailSection.home));
        }
      },
      status: widget.homeStatus,
      statusAtTop: widget.homeStatus != null,
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

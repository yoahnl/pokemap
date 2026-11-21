part of 'map_builder_page.dart';

extension _MapBuilderPageResources on _MapBuilderPageState {
  Widget _resourceLibrary(ProjectLibraryManagement? management) {
    final packPort =
        widget.session.storage == ProjectSessionStorage.workingCatalog
        ? ref.watch(resourcePackPortProvider(widget.session))
        : null;
    return ProjectLibraryPage(
      active: _section == StudioRailSection.resources && !_sceneShown,
      maps: _maps,
      visuals: _visuals,
      management: _editable ? management : null,
      onModelWorkshopPublished: (receipt) =>
          _projection.acceptModelWorkshopReceipt(_maps, receipt),
      onOpenMap: _openMapFromResources,
      onUseEnvironment: _editable ? _useEnvironmentFromResources : null,
      packPort: packPort,
      pickPack: packPort == null ? null : ref.watch(resourcePackPickerProvider),
      onPackDialogChanged: _setPackDialogOpen,
    );
  }

  void _setPackDialogOpen(bool value) {
    _packDialogOpen = value;
    if (value) _protect();
  }

  Future<bool> _openMapFromResources(String mapId) =>
      _openMapFromSection(mapId, StudioRailSection.resources);

  Future<bool> _useEnvironmentFromResources(
    String mapId,
    String presetId,
  ) async {
    if (!await _openMapFromResources(mapId)) return false;
    return _resources.useEnvironment(
      presetId,
      isCurrent: () =>
          mounted && _section == StudioRailSection.map && !_sceneShown,
    );
  }

  Widget? _environmentInspector(MapEditingViewportSession view) {
    final document = _maps.active;
    final project = _maps.project;
    final session = view.environment;
    if (document == null || project == null || session == null) return null;
    final commands = EnvironmentEditingCommands(document, project);
    final area = commands.area(session);
    if (area == null) return null;
    final preview =
        identical(session.previewSource, document.current) &&
            identical(session.previewProject, project)
        ? session.generation
        : null;
    final canPreview =
        area.generatedPlacementIds.isNotEmpty || area.mask.cells.contains(true);

    void edit(VoidCallback action) {
      if (!_editable) return;
      try {
        action();
        document.error = null;
      } on Object catch (failure) {
        document.error = environmentEditingMessage(failure);
      }
      _changed();
    }

    return StudioPanel(
      title: area.name,
      icon: Icons.forest_outlined,
      children: [
        StudioSelect(
          label: 'Tracer la zone',
          value: session.tool.name,
          options: const {
            'brush': 'Pinceau',
            'rectangle': 'Rectangle',
            'erase': 'Gomme',
          },
          onChanged: !_editable
              ? null
              : (value) => edit(() {
                  session.tool = EnvironmentPaintTool.values.byName(value);
                  session.clearPreview();
                }),
        ),
        if (preview == null) ...[
          if (!canPreview) const Text('Dessinez une zone sur la carte.'),
          StudioButton(
            key: const ValueKey('map-environment-preview'),
            label: 'Prévisualiser la répartition',
            onPressed: _editable && canPreview
                ? () => edit(() => commands.preview(session))
                : null,
          ),
        ] else ...[
          Text(switch (preview.placements.length) {
            1 => '1 décor dans l’aperçu',
            final count => '$count décors dans l’aperçu',
          }),
          StudioButton(
            key: const ValueKey('map-environment-apply'),
            label: 'Appliquer la répartition',
            onPressed: _editable
                ? () => edit(() => commands.apply(session))
                : null,
          ),
          StudioButton(
            label: 'Fermer l’aperçu',
            variant: StudioButtonVariant.quiet,
            onPressed: () => edit(session.clearPreview),
          ),
        ],
        StudioButton(
          label: context.l10n.backToSelection,
          variant: StudioButtonVariant.quiet,
          onPressed: _resources.release,
        ),
      ],
    );
  }

  Future<bool> _openMapFromSection(
    String mapId,
    StudioRailSection source,
  ) async {
    final sectionGeneration = _storyNavigation;
    bool current() =>
        mounted &&
        !_disposed &&
        _section == source &&
        sectionGeneration == _storyNavigation &&
        !_sceneShown;

    if (!current() || _maps.loading) return false;
    final entry = _maps.project?.maps
        .where((entry) => entry.id == mapId)
        .firstOrNull;
    if (entry == null) return false;
    await _commitTyping();
    if (!current() || _maps.loading) return false;
    if (_maps.active?.base.mapId != mapId) {
      await _maps.activate(entry, isCurrent: current);
    }
    if (!current() || _maps.active?.base.mapId != mapId) return false;
    _setSection(StudioRailSection.map);
    _setSpace(MapBuilderSpace.construction);
    return true;
  }
}

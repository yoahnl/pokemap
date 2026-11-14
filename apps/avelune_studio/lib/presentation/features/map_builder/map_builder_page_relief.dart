part of 'map_builder_page.dart';

extension _MapBuilderPageRelief on _MapBuilderPageState {
  bool get _reliefAvailable =>
      _space == MapBuilderSpace.construction &&
      _maps.active?.current.spatialScene != null;

  List<MapReliefProfile> _reliefProfiles(MapEditingViewportSession view) {
    final project = _maps.project, map = _maps.active?.current;
    return project == null || map == null
        ? const []
        : view.relief.profiles(project, map);
  }

  Future<void> _prepareRelief(MapEditingViewportSession view) async {
    final relief = view.relief;
    relief
      ..loading = true
      ..loadFailure = null;
    _changed();
    try {
      await _maps.ensureResourceKind('borderBlueprint', placeableOnly: true);
    } on Object catch (failure) {
      relief.loadFailure = failure;
    } finally {
      relief.loading = false;
    }
    if (_disposed) return;
    final profiles = _reliefProfiles(view);
    final chosen = profiles
        .where((profile) => profile.id == relief.profileId)
        .firstOrNull;
    if (chosen == null && profiles.isNotEmpty) {
      await _chooseRelief(view, profiles.first);
    }
    _changed();
  }

  Future<void> _chooseRelief(
    MapEditingViewportSession view,
    MapReliefProfile profile,
  ) async {
    view.relief
      ..profileId = profile.id
      ..outcome = null;
    _changed();
    try {
      for (final id in [profile.id, ?profile.twoLevelId]) {
        await _maps.ensureBorderBlueprint(id);
      }
    } on Object catch (failure) {
      view.relief.loadFailure = failure;
    }
    if (!_disposed) _changed();
  }

  Widget? _reliefPalette(MapEditingViewportSession? view) {
    final map = _maps.active?.current;
    if (view?.tool != StudioMapTool.relief || map?.spatialScene == null) {
      return null;
    }
    final relief = view!.relief;
    return MapBuilderReliefPalette(
      palette: relief.palette(map!),
      level: relief.level,
      onLevel: (level) {
        relief
          ..level = level.clamp(0, relief.maximumLevel(map))
          ..outcome = null;
        _changed();
      },
    );
  }

  Widget _reliefInspector(MapEditingViewportSession view) =>
      MapBuilderReliefInspector(
        state: view.relief,
        profiles: _reliefProfiles(view),
        onProfile: (profile) => unawaited(_chooseRelief(view, profile)),
      );

  Future<void> _prepareStair(MapEditingViewportSession view) async {
    final slope = view.slope
      ..loading = true
      ..loadFailure = null;
    _changed();
    try {
      await _maps.ensureResourceKind('model3d', placeableOnly: true);
    } on Object catch (failure) {
      slope.loadFailure = failure;
    } finally {
      slope.loading = false;
    }
    if (_disposed) return;
    final models = _stairModels(view);
    if (models.length == 1) slope.stairModelId = models.single.model.id;
    _changed();
  }

  List<TerrainStairModel> _stairModels(MapEditingViewportSession view) {
    final project = _maps.project, map = _maps.active?.current;
    return project == null || map == null
        ? const []
        : view.slope.stairModels(project, map);
  }

  ({String message, bool isError})? _constructionNotice(
    MapEditingViewportSession? view,
  ) => switch (view?.tool) {
    StudioMapTool.relief => mapBuilderReliefNotice(
      context.l10n,
      view!.relief.outcome,
    ),
    StudioMapTool.slope || StudioMapTool.stair => mapBuilderSlopeNotice(
      context.l10n,
      view!.slope.outcome,
    ),
    _ => null,
  };

  Widget? _constructionInspector(MapEditingViewportSession? view) =>
      switch (view?.tool) {
        StudioMapTool.relief => _reliefInspector(view!),
        StudioMapTool.slope || StudioMapTool.stair => MapBuilderSlopeInspector(
          stair: view!.tool == StudioMapTool.stair,
          state: view.slope,
          models: view.tool == StudioMapTool.stair
              ? _stairModels(view)
              : const [],
          onModel: (model) {
            view.slope
              ..stairModelId = model.model.id
              ..outcome = null;
            _changed();
          },
        ),
        _ => null,
      };
}

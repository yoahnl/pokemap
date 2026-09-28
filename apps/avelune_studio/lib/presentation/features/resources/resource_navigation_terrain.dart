part of 'resource_navigation.dart';

mixin ResourceNavigationTerrain on ChangeNotifier {
  MapWorkspaceController get workspace;
  Map<String, TerrainDraftController> get terrains;
  TerrainDraftController? get terrain;
  set terrain(TerrainDraftController? value);
  String? get error;
  set error(String? value);
  ResourcePage get page;
  set page(ResourcePage value);
  int get _terrainSequence;
  set _terrainSequence(int value);
  void showLibrary([ResourceItem? item]);

  void prepareTerrain(ResourceItem item) {
    if (item.terrain != null) {
      final draft = editableTerrainDraft(
        workspace.project!,
        item.terrain!,
        localDrafts: terrains.values.map((model) => model.draft),
      );
      if (draft != null) {
        resumeTerrain(draft);
      } else {
        error = advancedTerrainPreparationMessage;
        showLibrary(item);
      }
      return;
    }
    final tileset = item.tileset;
    if (tileset == null) return;
    final problem = terrainSourceCompatibilityProblem(tileset);
    if (problem != null) {
      error = problem;
      showLibrary(item);
      return;
    }
    final id =
        'terrain-${DateTime.now().microsecondsSinceEpoch}-${++_terrainSequence}';
    terrain = TerrainDraftController(
      manifest: workspace.project!,
      atlas: terrainAtlas(tileset, 'atlas-$id'),
      id: id,
      name: tileset.name,
    );
    terrains[terrain!.draft.id] = terrain!;
    error = null;
    page = ResourcePage.terrain;
    notifyListeners();
  }

  void resumeTerrain(ProjectSmartTileAuthoringDraft draft) {
    final problem = terrainDraftCompatibilityProblem(
      workspace.project!,
      terrains[draft.id]?.draft ?? draft,
    );
    if (problem != null) {
      error = problem;
      showLibrary();
      return;
    }
    terrain = terrains.putIfAbsent(
      draft.id,
      () => TerrainDraftController.resume(
        manifest: workspace.project!,
        draft: draft,
      ),
    );
    error = null;
    page = ResourcePage.terrain;
    notifyListeners();
  }
}

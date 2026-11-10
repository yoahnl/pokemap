import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_layout_preferences.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';

export 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';

class MapWorkspaceViewState extends MapEditingViewportSession {
  MapWorkspaceViewState({MapLayoutPreferences? layout})
    : layout = layout ?? MapLayoutPreferences();

  final MapLayoutPreferences layout;
  @override
  set tool(StudioMapTool value) {
    if (value != tool) paletteRevealedFor = null;
    super.tool = value;
  }

  @override
  void prepareFieldObstaclePlacement(FieldObstacleKind kind) {
    paletteTab = 'Décors';
    super.prepareFieldObstaclePlacement(kind);
  }

  String characterQuery = '';
  double characterScrollOffset = 0;
  bool elementsVisible = false;
  bool contentInLeftColumn = false;
  bool get navigatorCollapsed => layout.navigatorCollapsed;
  set navigatorCollapsed(bool value) =>
      layout.update(navigatorCollapsed: value);
  bool get mapOnly => layout.mapOnly;
  set mapOnly(bool value) => layout.update(mapOnly: value);
  bool paletteTiles = false;
  bool revealPalette = false;
  bool revealInspector = false;
  String _paletteTab = 'Décors';
  String get paletteTab => _paletteTab;
  set paletteTab(String value) {
    if (value == _paletteTab) return;
    final search = paletteSearch;
    paletteQueries[_paletteTab] = search?.text ?? resourceFilters.query;
    paletteFamilies[_paletteTab] = resourceFilters.familyId;
    _paletteTab = value;
    final query = paletteQueries[value] ?? '';
    if (search != null && search.text != query) search.text = query;
    resourceFilters
      ..query = query
      ..familyId = paletteFamilies[value] ?? '';
  }

  StudioMapTool? paletteRevealedFor;
  final paletteQueries = <String, String>{};
  final paletteFamilies = <String, String>{};
  TextEditingController? paletteSearch;
  final paletteScrollOffsets = <String, double>{};
  final paletteAtlasTransforms = <String, TransformationController>{};
  final fittedPaletteAtlases = <String>{};
  @override
  void prepareCharacterPlacement() {
    paletteTab = 'Personnages';
    super.prepareCharacterPlacement();
  }

  @override
  void prepareTerrainPainting(ProjectSmartTilePreset preset) {
    paletteTab = 'Terrains';
    super.prepareTerrainPainting(preset);
  }

  List<ResourceItem> paletteResources(
    ProjectManifest project,
    String mapId, {
    bool applyFilters = true,
  }) => paletteResourcesFor(
    project,
    mapId,
    paletteTab,
    applyFilters: applyFilters,
  );

  @override
  void prepareWarpPlacement() {
    paletteTab = 'Passages';
    super.prepareWarpPlacement();
  }

  @override
  void prepareConnections() {
    paletteTab = 'Passages';
    revealInspector = true;
    super.prepareConnections();
  }

  @override
  void dispose() {
    super.dispose();
    for (final controller in paletteAtlasTransforms.values) {
      controller.dispose();
    }
  }
}

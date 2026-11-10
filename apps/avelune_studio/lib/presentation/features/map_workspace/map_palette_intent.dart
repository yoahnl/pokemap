import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_palette_intent.dart'
    as intents;
import 'map_workspace_view_state.dart';

export '../../../features/map_workspace/application/map_palette_intent.dart'
    show
        MapIntentGroup,
        MapPaletteIntent,
        mapTerrainGestureLabel,
        mapConnectionsUnavailable;

intents.MapPaletteIntent mapPaletteIntent(
  MapWorkspaceViewState view, {
  bool spatial = false,
  bool connectionsAvailable = true,
  bool? editingExterior,
  ProjectManifest? project,
}) => intents.mapPaletteIntent(
  view,
  spatial: spatial,
  paletteTab: view.paletteTab,
  connectionsAvailable: connectionsAvailable,
  editingExterior: editingExterior,
  project: project,
);

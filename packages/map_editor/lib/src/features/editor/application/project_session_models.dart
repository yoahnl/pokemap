import 'package:map_core/map_core.dart';

import '../../../application/services/terrain_preset_selection_coordinator.dart';

/// Données minimales nécessaires pour ouvrir/initialiser une session projet
/// dans l'éditeur.
class ProjectSessionLoadResult {
  const ProjectSessionLoadResult({
    required this.projectRootPath,
    required this.project,
    required this.presetSelection,
  });

  final String projectRootPath;
  final ProjectManifest project;
  final TerrainPresetSelection presetSelection;
}

/// Données minimales nécessaires pour ouvrir un document map dans la session.
class MapDocumentLoadResult {
  const MapDocumentLoadResult({
    required this.map,
    required this.activeMapPath,
    required this.presetSelection,
    required this.selectedTilesetEditorId,
  });

  final MapData map;
  final String activeMapPath;
  final TerrainPresetSelection presetSelection;
  final String? selectedTilesetEditorId;
}

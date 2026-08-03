import 'package:map_core/map_core.dart';

/// Données minimales nécessaires pour ouvrir/initialiser une session projet
/// dans l'éditeur.
class ProjectSessionLoadResult {
  const ProjectSessionLoadResult({
    required this.projectRootPath,
    required this.project,
  });

  final String projectRootPath;
  final ProjectManifest project;
}

/// Données minimales nécessaires pour ouvrir un document map dans la session.
class MapDocumentLoadResult {
  const MapDocumentLoadResult({
    required this.map,
    required this.activeMapPath,
    required this.selectedTilesetEditorId,
  });

  final MapData map;
  final String activeMapPath;
  final String? selectedTilesetEditorId;
}

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'workspace_resource_diagnostic.dart';

abstract interface class MapWorkspaceVisuals implements Listenable {
  Widget canvas(MapData map);
  Widget thumbnail(ProjectElementEntry element, {double size = 48});
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48});
  List<WorkspaceResourceDiagnostic> get diagnostics;
  Set<String> get activeResourceIds;
  void setActiveMap(MapData map);
  void setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile);
  Future<void> retryResources(Iterable<String> resourceIds);
  List<String> get warnings;
  Future<void> dispose();
}

typedef LoadWorkspaceVisuals =
    Future<MapWorkspaceVisuals> Function(
      ProjectSession session,
      ProjectManifest manifest,
    );

abstract interface class ResourceWorkspaceVisuals {
  void setTerrainBrush(ProjectSmartTilePreset? preset);
  Widget atlasPreview(String tilesetId);
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  });
}

abstract interface class MapBorderPreviewVisuals {
  bool get borderPreviewLoading;
  bool get borderPreviewReady;
  String? get borderPreviewIssue;
}

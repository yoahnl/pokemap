import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import '../../features/rendering/contracts/workspace_resource_diagnostic.dart';

abstract interface class StudioThumbnailResources implements Listenable {
  ProjectManifest get manifest;
  Map<String, ProjectTilesetEntry> get tilesets;
  Map<String, RuntimeTilesetImage> get images;
  List<WorkspaceResourceDiagnostic> get diagnostics;
  int get catalogVersion;
  void retain(Object owner, Set<String> ids);
  void release(Object owner);
  bool hasFailure(Iterable<String> ids);
  Set<String> elementResourceIds(ProjectElementEntry element);
  Set<String> tileResourceIds(TileLayerPaletteEntry tile);
  Set<String> characterResourceIds(ProjectCharacterEntry character);
}

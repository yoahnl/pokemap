import 'package:map_core/map_core_domain.dart';

import 'project_library_editor.dart';
import 'resource_port.dart';

typedef ProjectTerrainWorkshopEditor = ({
  String revision,
  ResourceMutationReceipt? pendingReceipt,
  void Function(ResourceMutationReceipt?) onPendingReceiptChanged,
  Future<ResourceMutationReceipt> Function(ProjectSmartTilePreset, String)
  publish,
  Future<void> Function(ResourceMutationReceipt) reconcile,
});

abstract interface class ProjectTerrainWorkshopPort {
  bool get terrainConnectionEditingAvailable;

  Future<ProjectLibraryEdit> createTerrain(
    ProjectSmartTilePreset draft, {
    required String expectedRevision,
  });

  Future<ProjectLibraryEdit> reconcileTerrainCreation(
    ResourceMutationReceipt receipt,
  );

  Future<ResourceMutationReceipt> publishTerrainConnections(
    ProjectSmartTilePreset preset, {
    required String expectedRevision,
  });

  Future<void> reconcileTerrainConnections(ResourceMutationReceipt receipt);
}

abstract interface class ProjectTerrainImageWorkshopPort {
  Future<ProjectLibraryEdit> createTerrainFromImage(
    PickedProjectLibraryFile file, {
    required String name,
    required LibraryImageSize tileSize,
    required GridPos cell,
    required String expectedRevision,
  });
}

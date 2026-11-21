import 'package:map_core/map_core_domain.dart';

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

  Future<ResourceMutationReceipt> publishTerrainConnections(
    ProjectSmartTilePreset preset, {
    required String expectedRevision,
  });

  Future<void> reconcileTerrainConnections(ResourceMutationReceipt receipt);
}

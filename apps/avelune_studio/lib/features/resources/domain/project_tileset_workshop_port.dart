import '../application/project_resource_library.dart';
import 'project_library_editor.dart';
import 'resource_port.dart';

typedef ProjectTilesetGridEditor = ({
  String revision,
  Future<String> Function() prepareCatalog,
  Future<ResourceMutationReceipt> Function(LibraryImageSize, String) save,
  Future<ResourceMutationReceipt> Function(ResourceMutationReceipt) reconcile,
  ResourceMutationReceipt? pendingReceipt,
  void Function(ResourceMutationReceipt?) onPendingReceiptChanged,
});

abstract interface class ProjectTilesetWorkshopPort {
  bool get tilesetGridEditingAvailable;

  Future<ResourceMutationReceipt> saveTilesetGrid(
    ProjectLibraryItem item, {
    required LibraryImageSize tileSize,
    required String expectedRevision,
    String? Function()? validateBeforeApply,
  });

  Future<void> reconcileTilesetGrid(ResourceMutationReceipt receipt);
}

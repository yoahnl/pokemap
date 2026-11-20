import 'package:map_core/map_core_domain.dart';

import '../application/project_resource_library.dart';
import 'resource_port.dart';

typedef ProjectLibraryBatchEdit = ({
  List<ProjectLibraryItem> items,
  ResourceMutationReceipt receipt,
});

typedef ProjectLibraryFamilyEdit = ({
  String id,
  ResourceFamily? family,
  ResourceMutationReceipt receipt,
});

abstract interface class ProjectLibraryOrganization {
  Future<ProjectLibraryBatchEdit> classifyLibraryResources(
    Iterable<ProjectLibraryItem> items, {
    required ({String? id})? family,
    required ResourceLibraryRole? role,
    required String expectedRevision,
  });

  Future<ProjectLibraryFamilyEdit> saveLibraryFamily({
    required ResourceFamily? existing,
    required String name,
    required String? parentId,
    required String expectedRevision,
  });

  Future<ProjectLibraryFamilyEdit> deleteLibraryFamily(
    ResourceFamily family, {
    required String expectedRevision,
  });
}

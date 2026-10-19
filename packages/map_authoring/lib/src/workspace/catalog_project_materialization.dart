import 'package:map_core/map_core.dart';

typedef ProjectCatalogMaterializer = Future<ProjectCatalogMaterialization>
    Function(List<int> expectedDescriptorBytes);

final class ProjectCatalogMaterialization {
  ProjectCatalogMaterialization({
    required this.manifest,
    required this.descriptorRevision,
    List<int>? headBytes,
  }) : headBytes = headBytes == null ? null : List.unmodifiable(headBytes);

  final ProjectManifest manifest;
  final String descriptorRevision;
  final List<int>? headBytes;
}

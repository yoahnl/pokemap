import 'package:map_core/map_core_domain.dart';

final class ResourceImageImport {
  const ResourceImageImport({
    required this.sourcePath,
    required this.name,
    required this.tileWidth,
    required this.tileHeight,
  });

  final String sourcePath;
  final String name;
  final int tileWidth;
  final int tileHeight;
}

final class ResourceMutationReceipt {
  const ResourceMutationReceipt({
    required this.before,
    required this.manifest,
    required this.beforeRevision,
    required this.revision,
    required this.changedPaths,
    this.createdTilesetId,
  });

  final ProjectManifest before;
  final ProjectManifest manifest;
  final String beforeRevision;
  final String revision;
  final List<String> changedPaths;
  final String? createdTilesetId;
}

abstract interface class ResourcePort {
  Future<ResourceMutationReceipt> importImage(ResourceImageImport request);

  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  );

  Future<ResourceMutationReceipt> saveElement(ProjectElementEntry element);

  Future<void> dispose();
}

final class ResourceFailure implements Exception {
  const ResourceFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

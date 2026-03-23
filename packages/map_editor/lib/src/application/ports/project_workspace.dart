abstract class ProjectWorkspace {
  String get projectRoot;
  String get projectManifestPath;

  String resolveMapPath(String relativePath);
  String getMapPath(String mapId);
  String getMapRelativePath(String mapId);
  String resolveTilesetPath(String relativePath);
  String resolveProjectRelativePath(String relativePath);

  Future<void> ensureDirectoryExists(String path);
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  });
  Future<void> deleteRelativeFile(String relativePath);
}

abstract class ProjectWorkspaceFactory {
  ProjectWorkspace create(String projectRoot);
}

abstract class ProjectWorkspace {
  String get projectRoot;
  String get projectManifestPath;

  String resolveMapPath(String relativePath);
  String getMapPath(String mapId);
  String getMapRelativePath(String mapId);
  String resolveTilesetPath(String relativePath);
  String resolveProjectRelativePath(String relativePath);

  Future<void> ensureDirectoryExists(String path);
  Future<bool> fileExists(String path);
  Future<bool> directoryExists(String path);
  Future<String> readTextFile(String path);
  Future<void> writeTextFile(String path, String contents);
  Future<void> copyFile(String sourcePath, String destinationPath);
  Future<void> moveFile(String sourcePath, String destinationPath);
  Future<void> moveDirectory(String sourcePath, String destinationPath);
  Future<void> deleteDirectoryIfEmpty(String path);
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  });
  Future<void> deleteRelativeFile(String relativePath);
}

abstract class ProjectWorkspaceFactory {
  ProjectWorkspace create(String projectRoot);
}

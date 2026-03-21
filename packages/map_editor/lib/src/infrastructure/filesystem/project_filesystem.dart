import 'dart:io';
import 'package:path/path.dart' as p;

class ProjectFileSystem {
  final String _projectRoot;

  ProjectFileSystem(this._projectRoot);

  String get projectRoot => _projectRoot;
  
  String get projectManifestPath => p.join(_projectRoot, 'project.json');

  String resolveMapPath(String relativePath) {
    return p.normalize(p.join(_projectRoot, relativePath));
  }

  String resolveTilesetPath(String relativePath) {
    return p.normalize(p.join(_projectRoot, relativePath));
  }

  String relativePath(String absolutePath) {
    return p.relative(absolutePath, from: _projectRoot);
  }

  Future<void> ensureDirectoryExists(String path) async {
    final dir = Directory(p.dirname(path));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}

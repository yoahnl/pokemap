import 'package:map_authoring/map_authoring.dart';

/// Editor-owned adapter for the read-only filesystem capability expected by
/// `map_authoring`.
///
/// Keeping this class in infrastructure makes the ownership boundary visible:
/// application/UI code receives snapshots and query projections, never raw
/// filesystem paths or JSON bytes. Path canonicalization and symlink checks
/// remain delegated to the canonical Authoring implementation.
final class EditorProjectFileReader implements ProjectFileReader {
  const EditorProjectFileReader({
    ProjectFileReader delegate = const LocalProjectFileReader(),
  }) : _delegate = delegate;

  final ProjectFileReader _delegate;

  @override
  Future<String> canonicalizeDirectory(String path) {
    return _delegate.canonicalizeDirectory(path);
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

import '../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../application/services/editor_performance_telemetry.dart';

/// Editor-owned adapter for the read-only filesystem capability expected by
/// `map_authoring`.
///
/// Keeping this class in infrastructure makes the ownership boundary visible:
/// application/UI code receives snapshots and query projections, never raw
/// filesystem paths or JSON bytes. Path canonicalization and symlink checks
/// remain delegated to the canonical Authoring implementation.
final class EditorProjectFileReader
    implements
        ProjectFileReader,
        ProjectResourceIdentityReader,
        ProjectSnapshotCacheIdentityReader,
        EditorProjectRootLocator {
  const EditorProjectFileReader({
    ProjectFileReader delegate = const LocalProjectFileReader(),
  }) : _delegate = delegate;

  final ProjectFileReader _delegate;

  @override
  Future<String> canonicalizeDirectory(String path) {
    EditorPerformanceTelemetry.incrementCounter(
      EditorPerformanceCounterName.filesystemMetadata,
    );
    return _delegate.canonicalizeDirectory(path);
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    EditorPerformanceTelemetry.incrementCounter(
      EditorPerformanceCounterName.filesystemRead,
    );
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) {
    EditorPerformanceTelemetry.incrementCounter(
      EditorPerformanceCounterName.filesystemMetadata,
    );
    final delegate = _delegate;
    if (delegate is! ProjectSnapshotCacheIdentityReader) {
      return Future.value();
    }
    return (delegate as ProjectSnapshotCacheIdentityReader).readIdentity(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<String> locateForResource(String resourcePath) async {
    var directory = File(p.normalize(p.absolute(resourcePath))).parent;
    while (true) {
      final manifest = File(p.join(directory.path, 'project.json'));
      EditorPerformanceTelemetry.incrementCounter(
        EditorPerformanceCounterName.filesystemMetadata,
      );
      if (await manifest.exists()) {
        return canonicalizeDirectory(directory.path);
      }
      final parent = directory.parent;
      if (parent.path == directory.path) {
        throw const FileSystemException(
          'Resource is not inside a PokeMap project.',
        );
      }
      directory = parent;
    }
  }
}

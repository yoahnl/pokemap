import 'dart:convert';

import '../../contracts/artifact_ref.dart';
import '../../ports/project_file_reader.dart';
import '../assets/asset_store.dart';
import 'runtime_project_projection_builder.dart';

final class RuntimeProjectProjectionFileReader
    implements
        ProjectFileReader,
        ProjectDirectoryReader,
        ProjectResourceProbeReader {
  RuntimeProjectProjectionFileReader(RuntimeProjectProjection projection)
    : _payloadFiles = projection.payloadFiles,
      _payloadDirectories = projection.payloadDirectories,
      _assetCatalog = _decodeAssetCatalog(projection.payloadFiles);

  static const projectRoot = 'runtime-project-projection';

  final Map<String, List<int>> _payloadFiles;
  final Set<String> _payloadDirectories;
  final AssetCatalog? _assetCatalog;

  @override
  Future<String> canonicalizeDirectory(String path) async => projectRoot;

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    final canonical = _canonicalRelativePath(relativePath);
    final bytes = _payloadFiles['project/$canonical'];
    if (bytes == null) {
      throw const WorkspaceAccessException(
        'workspace.file_unavailable',
        'The requested projected resource is unavailable.',
      );
    }
    return bytes;
  }

  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) async {
    final directory = _canonicalRelativePath(relativeDirectory);
    final prefix = 'project/$directory/';
    if (!_payloadDirectories.contains('project/$directory') &&
        !_payloadFiles.keys.any((path) => path.startsWith(prefix))) {
      throw const WorkspaceAccessException(
        'workspace.directory_unavailable',
        'The requested projected directory is unavailable.',
      );
    }
    final files = <String>[
      for (final path in _payloadFiles.keys)
        if (path.startsWith(prefix) &&
            !path.substring(prefix.length).contains('/'))
          path.substring('project/'.length),
    ]..sort();
    return List<String>.unmodifiable(files);
  }

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) async {
    final canonical = _canonicalRelativePath(relativePath);
    final direct = _payloadFiles['project/$canonical'];
    if (direct != null) return _exists(canonical, direct);
    final artifact = _assetCatalog?.findByLogicalPath(canonical)?.artifact;
    if (artifact == null) return const ProjectResourceProbe.missing();
    final storagePath = assetBlobStorageKey(artifact);
    final bytes = _payloadFiles['project/$storagePath'];
    if (bytes == null) return const ProjectResourceProbe.missing();
    final actual = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: artifact.mediaType,
    );
    if (actual.digest != artifact.digest ||
        actual.byteLength != artifact.byteLength) {
      return const ProjectResourceProbe.inventoryUnavailable();
    }
    return _exists(canonical, bytes);
  }

  ProjectResourceProbe _exists(String relativePath, List<int> bytes) {
    return ProjectResourceProbe.exists(
      ProjectResourceIdentity(
        scope: projectRoot,
        relativePath: relativePath,
        byteLength: bytes.length,
        modifiedAtMicros: 0,
        changedAtMicros: 0,
      ),
    );
  }
}

AssetCatalog? _decodeAssetCatalog(Map<String, List<int>> payloadFiles) {
  final bytes = payloadFiles['project/$assetCatalogStorageKey'];
  if (bytes == null) return null;
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map) return null;
  return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
}

String _canonicalRelativePath(String value) {
  return validateProjectRelativePath(value).join('/');
}

import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../ports/project_file_reader.dart';
import 'workspace_handle_store.dart';
import 'workspace_policy.dart';

final class ProjectOpenException implements Exception {
  const ProjectOpenException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ProjectOpenException($code): $message';
}

final class OpenedProject {
  const OpenedProject({
    required this.workspaceHandle,
    required this.projectHandle,
    required this.projectName,
    required this.fingerprint,
    required this.expiresAt,
  });

  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final String projectName;
  final String fingerprint;
  final DateTime expiresAt;

  bool get readOnly => true;

  Map<String, Object?> toJson() => {
        'workspaceHandle': workspaceHandle.value,
        'projectHandle': projectHandle.value,
        'projectName': projectName,
        'fingerprint': fingerprint,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'readOnly': true,
      };
}

final class ProjectOpenService {
  const ProjectOpenService({
    required WorkspacePolicy policy,
    required ProjectFileReader fileReader,
    required WorkspaceHandleStore handles,
  })  : _policy = policy,
        _fileReader = fileReader,
        _handles = handles;

  final WorkspacePolicy _policy;
  final ProjectFileReader _fileReader;
  final WorkspaceHandleStore _handles;

  Future<OpenedProject> openProject(String projectRootPath) async {
    final canonicalRoot = await _policy.authorizeProjectRoot(projectRootPath);
    final manifestBytes = await _fileReader.readBytes(
      projectRoot: canonicalRoot,
      relativePath: 'project.json',
    );
    final manifest = _decodeManifest(manifestBytes);
    final fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
    ]);
    final reader = _fileReader;
    final registered = _handles.registerProject(
      projectName: manifest.name,
      initialFingerprint: fingerprint,
      readBytes: (relativePath) => reader.readBytes(
        projectRoot: canonicalRoot,
        relativePath: relativePath,
      ),
      // Only readers that can report identity cheaply enable snapshot reuse.
      readIdentity: reader is ProjectResourceIdentityReader
          ? (relativePath) =>
              (reader as ProjectResourceIdentityReader).readIdentity(
                projectRoot: canonicalRoot,
                relativePath: relativePath,
              )
          : null,
      listFiles: reader is ProjectDirectoryReader
          ? (relativeDirectory) => (reader as ProjectDirectoryReader).listFiles(
                projectRoot: canonicalRoot,
                relativeDirectory: relativeDirectory,
              )
          : null,
      probeResource: reader is ProjectResourceProbeReader
          ? (relativePath) =>
              (reader as ProjectResourceProbeReader).probeResource(
                projectRoot: canonicalRoot,
                relativePath: relativePath,
              )
          : null,
      canReuseSnapshots: reader is ProjectSnapshotCacheIdentityReader,
    );
    return OpenedProject(
      workspaceHandle: registered.workspaceHandle,
      projectHandle: registered.projectHandle,
      projectName: manifest.name,
      fingerprint: fingerprint,
      expiresAt: registered.expiresAt,
    );
  }

  bool closeWorkspace(WorkspaceHandle handle) =>
      _handles.closeWorkspace(handle);
}

ProjectManifest _decodeManifest(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object.');
    }
    return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw const ProjectOpenException(
      'project.manifest_invalid',
      'The project manifest is not valid PokeMap JSON.',
    );
  }
}

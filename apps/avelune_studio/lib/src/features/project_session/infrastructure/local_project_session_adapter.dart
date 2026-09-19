import 'dart:io';

import 'package:map_authoring/map_authoring.dart' show WorkspaceAccessException;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

import '../application/project_session.dart';

final class LocalProjectSessionAdapter implements ProjectSessionPort {
  LocalProjectSessionAdapter({
    ProjectFileReader? fileReader,
    WorkspaceHandleStore? handles,
  }) : _reader = fileReader ?? const LocalProjectFileReader(),
       _handles = handles ?? WorkspaceHandleStore();

  final ProjectFileReader _reader;
  final WorkspaceHandleStore _handles;

  @override
  Future<ProjectSession> open(String directoryPath) async {
    final selectedPath = directoryPath.trim();
    if (!p.isAbsolute(selectedPath) ||
        selectedPath.contains('\u0000') ||
        selectedPath.split(RegExp(r'[\\/]')).contains('..')) {
      throw const ProjectOpenFailure(ProjectOpenProblem.invalidPath);
    }
    try {
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [selectedPath],
        fileReader: _reader,
      );
      final canonicalPath = await policy.authorizeProjectRoot(selectedPath);
      final reader = _reader;
      if (reader is ProjectResourceProbeReader) {
        final probe = await (reader as ProjectResourceProbeReader)
            .probeResource(
              projectRoot: canonicalPath,
              relativePath: 'project.json',
            );
        switch (probe.status) {
          case ProjectResourceProbeStatus.missing:
            throw const ProjectOpenFailure(ProjectOpenProblem.manifestMissing);
          case ProjectResourceProbeStatus.unsafePath:
          case ProjectResourceProbeStatus.accessDenied:
            throw const ProjectOpenFailure(ProjectOpenProblem.accessDenied);
          case ProjectResourceProbeStatus.exists:
          case ProjectResourceProbeStatus.inventoryUnavailable:
            break;
        }
      }
      final service = ProjectOpenService(
        policy: policy,
        fileReader: _reader,
        handles: _handles,
      );
      final opened = await service.openProject(canonicalPath);
      return ProjectSession(
        sessionId: opened.workspaceHandle.value,
        name: opened.projectName,
        directoryPath: canonicalPath,
      );
    } on ProjectOpenFailure {
      rethrow;
    } on ProjectOpenException {
      throw const ProjectOpenFailure(ProjectOpenProblem.manifestInvalid);
    } on WorkspaceAccessException catch (error) {
      throw ProjectOpenFailure(_workspaceProblem(error.code));
    } on FileSystemException catch (error) {
      throw ProjectOpenFailure(
        const {1, 5, 13}.contains(error.osError?.errorCode)
            ? ProjectOpenProblem.accessDenied
            : ProjectOpenProblem.readFailed,
      );
    }
  }

  @override
  Future<void> close(ProjectSession session) async {
    _handles.closeWorkspace(WorkspaceHandle(session.sessionId));
  }

  ProjectOpenProblem _workspaceProblem(String code) => switch (code) {
    'workspace.path_invalid' ||
    'workspace.path_traversal' ||
    'workspace.path_absolute' => ProjectOpenProblem.invalidPath,
    'workspace.directory_required' ||
    'workspace.directory_missing' ||
    'workspace.directory_unavailable' =>
      ProjectOpenProblem.directoryUnavailable,
    'workspace.path_outside_allowed_roots' ||
    'workspace.path_outside_project' => ProjectOpenProblem.accessDenied,
    'workspace.file_required' => ProjectOpenProblem.manifestInvalid,
    _ => ProjectOpenProblem.readFailed,
  };
}

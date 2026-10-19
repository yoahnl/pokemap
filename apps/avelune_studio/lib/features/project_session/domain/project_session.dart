enum ProjectSessionStorage { manifest, workingCatalog, portableCatalog }

class ProjectSession {
  const ProjectSession({
    required this.sessionId,
    required this.name,
    required this.directoryPath,
    this.storage = ProjectSessionStorage.manifest,
    this.recoveryOperationIds = const [],
  });

  final String sessionId;
  final String name;
  final String directoryPath;
  final ProjectSessionStorage storage;
  final List<String> recoveryOperationIds;
}

abstract interface class ProjectSessionPort {
  Future<ProjectSession> open(String directoryPath);
  Future<void> close(ProjectSession session);
}

enum ProjectOpenProblem {
  invalidPath,
  pathNotPreserved,
  directoryUnavailable,
  manifestMissing,
  manifestInvalid,
  accessDenied,
  readFailed,
}

class ProjectOpenFailure implements Exception {
  const ProjectOpenFailure(this.problem);

  final ProjectOpenProblem problem;
}

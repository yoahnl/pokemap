class ProjectSession {
  const ProjectSession({
    required this.sessionId,
    required this.name,
    required this.directoryPath,
  });

  final String sessionId;
  final String name;
  final String directoryPath;
}

abstract interface class ProjectSessionPort {
  Future<ProjectSession> open(String directoryPath);
  Future<void> close(ProjectSession session);
}

enum ProjectOpenProblem {
  invalidPath,
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

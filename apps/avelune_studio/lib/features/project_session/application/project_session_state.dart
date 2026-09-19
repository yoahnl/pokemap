import 'package:avelune_studio/features/project_session/domain/project_session.dart';

enum ProjectSessionStatus { idle, opening, ready, failed }

class ProjectSessionState {
  const ProjectSessionState({
    this.status = ProjectSessionStatus.idle,
    this.project,
    this.requestedPath,
    this.problem,
  });

  final ProjectSessionStatus status;
  final ProjectSession? project;
  final String? requestedPath;
  final ProjectOpenProblem? problem;
}

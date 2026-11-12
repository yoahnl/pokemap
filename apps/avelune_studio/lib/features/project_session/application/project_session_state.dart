import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

enum ProjectSessionStatus { idle, opening, ready, failed }

class ProjectSessionState {
  const ProjectSessionState({
    this.status = ProjectSessionStatus.idle,
    this.project,
    this.requestedPath,
    this.problem,
    this.progress,
  });

  final ProjectSessionStatus status;
  final ProjectSession? project;
  final String? requestedPath;
  final ProjectOpenProblem? problem;
  final ProjectOpeningProgress? progress;
}

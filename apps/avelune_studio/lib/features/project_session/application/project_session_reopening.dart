import '../domain/project_session.dart';
import 'project_session_controller.dart';

Future<void> reopenRecoveredProject(
  ProjectSessionController controller,
  ProjectSession previous,
) async {
  await controller.open(previous.directoryPath);
  if (controller.state.project?.sessionId == previous.sessionId) {
    throw StateError('La nouvelle session ne peut pas être ouverte.');
  }
}

Future<void> reopenPartitionedProject(
  ProjectSessionController controller,
  ProjectSession previous,
) async {
  await controller.open(previous.directoryPath);
  if (controller.state.project?.storage != ProjectSessionStorage.workingCatalog) {
    throw StateError('Rouvrez le projet pour terminer la conversion.');
  }
}

import 'project_session.dart';

final class ProjectHistoryMaintenancePreview {
  const ProjectHistoryMaintenancePreview({
    required this.revision,
    required this.fingerprint,
    required this.retainedOperations,
    required this.expiredOperations,
    required this.retainedBytes,
    this.hasLegacyBarrier = false,
    this.blocked = false,
  });

  final String revision;
  final String fingerprint;
  final int retainedOperations;
  final int expiredOperations;
  final int retainedBytes;
  final bool hasLegacyBarrier;
  final bool blocked;
}

final class ProjectHistoryMaintenanceResult {
  const ProjectHistoryMaintenanceResult({
    required this.deletedObjects,
    required this.deletedBytes,
  });

  final int deletedObjects;
  final int deletedBytes;
}

abstract interface class ProjectHistoryMaintenancePort {
  Future<ProjectHistoryMaintenancePreview> preview(ProjectSession session);
  Future<ProjectHistoryMaintenanceResult> apply(
    ProjectSession session,
    ProjectHistoryMaintenancePreview preview,
  );
}

final class ProjectHistoryMaintenanceFailure implements Exception {
  const ProjectHistoryMaintenanceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

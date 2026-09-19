enum WorkspaceResourceCause {
  missing,
  accessDenied,
  unsupported,
  decodeFailure,
  memoryPressure,
  readFailure,
}

enum WorkspaceResourceStatus { failed, retrying }

final class WorkspaceResourceDiagnostic {
  const WorkspaceResourceDiagnostic({
    required this.resourceId,
    required this.name,
    required this.cause,
    this.detail,
    this.status = WorkspaceResourceStatus.failed,
  });

  final String resourceId;
  final String name;
  final WorkspaceResourceCause cause;
  final String? detail;
  final WorkspaceResourceStatus status;
  bool get canRetry => status == WorkspaceResourceStatus.failed;
  String get message => switch (cause) {
    WorkspaceResourceCause.missing => 'Fichier absent',
    WorkspaceResourceCause.accessDenied => 'Accès refusé',
    WorkspaceResourceCause.unsupported =>
      'Référence ou chemin non pris en charge',
    WorkspaceResourceCause.decodeFailure => 'Échec du décodage',
    WorkspaceResourceCause.memoryPressure =>
      'Budget mémoire des images atteint',
    WorkspaceResourceCause.readFailure =>
      'Lecture impossible, cause non précisée',
  };
}

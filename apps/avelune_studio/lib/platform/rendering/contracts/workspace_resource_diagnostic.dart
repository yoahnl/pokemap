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
    this.retryable = true,
    this.ownerKind,
    this.ownerId,
    this.ownerName,
    this.role,
  });

  final String resourceId;
  final String name;
  final WorkspaceResourceCause cause;
  final String? detail;
  final WorkspaceResourceStatus status;
  final bool retryable;
  final String? ownerKind, ownerId, ownerName, role;
  String get ownerKey =>
      ownerKind == null || ownerId == null ? resourceId : '$ownerKind:$ownerId';
  bool get verified => cause != WorkspaceResourceCause.readFailure;
  String get explanation => switch (cause) {
    WorkspaceResourceCause.missing => 'Le fichier référencé est introuvable dans le projet. La référence est conservée.',
    WorkspaceResourceCause.accessDenied =>
      'Le système refuse la lecture de ce fichier. Vérifiez ses autorisations.',
    WorkspaceResourceCause.unsupported => 'L’aperçu de Studio ne lit pas ce type de référence. La donnée est conservée telle quelle.',
    WorkspaceResourceCause.decodeFailure =>
      'Le fichier existe mais son image ne peut pas être décodée.',
    WorkspaceResourceCause.memoryPressure =>
      'L’aperçu a atteint son budget d’images ; la ressource est intacte.',
    WorkspaceResourceCause.readFailure => 'La lecture a échoué sans cause identifiée. Réessayez ou consultez le détail technique.',
  };
  bool get canRetry => retryable && status == WorkspaceResourceStatus.failed;
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

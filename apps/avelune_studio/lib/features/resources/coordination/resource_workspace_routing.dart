import 'package:map_core/map_core_domain.dart';

import '../../terrains/domain/terrain_draft_compatibility.dart';
import '../application/resource_pack_transfer_controller.dart';
import 'resource_navigation.dart' show ResourcePage;

enum ResourceWorkspaceView {
  decorUnavailable,
  environmentUnavailable,
  characters,
  terrainEditor,
  library,
}

ResourceWorkspaceView resourceWorkspaceView(
  ResourcePage page, {
  required bool hasDecor,
  required bool hasEnvironment,
  required bool hasTerrain,
  required bool terrainSpatial,
  required bool hasResourceVisuals,
}) {
  if (page == ResourcePage.decor && hasDecor) {
    return ResourceWorkspaceView.decorUnavailable;
  }
  if (page == ResourcePage.environment && hasEnvironment) {
    return ResourceWorkspaceView.environmentUnavailable;
  }
  if (page == ResourcePage.characters) return ResourceWorkspaceView.characters;
  if (page == ResourcePage.terrain &&
      hasTerrain &&
      (terrainSpatial || hasResourceVisuals)) {
    return ResourceWorkspaceView.terrainEditor;
  }
  return ResourceWorkspaceView.library;
}

bool resourceImportCanCreateDecor(ProjectDimension dimension) =>
    dimension == ProjectDimension.twoD;

bool terrainDraftResumable(
  ProjectManifest project,
  ProjectSmartTileAuthoringDraft draft,
) => terrainDraftCompatibilityProblem(project, draft) == null;

enum ResourcePackResolutionKind { publication, reconciliation, recovery }

typedef ResourcePackResolution = ({
  ResourcePackResolutionKind kind,
  String noticeKey,
  String actionKey,
  String message,
  String label,
  Future<void> Function() resolve,
});

ResourcePackResolution? resourcePackResolution(
  ResourcePackTransferController? transfer,
) => switch (transfer) {
  final owner? when owner.requiresPublicationReconciliation => (
    kind: ResourcePackResolutionKind.publication,
    noticeKey: 'resource-pack-publication-pending',
    actionKey: 'resource-pack-reconcile-publication',
    message:
        'Le résultat de la publication du pack reste à vérifier. Relisez son statut avant de fermer le projet. Aucun nouvel export ne sera lancé.',
    label: 'Relire le statut de publication',
    resolve: owner.retryPublication,
  ),
  final owner? when owner.requiresReconciliation => (
    kind: ResourcePackResolutionKind.reconciliation,
    noticeKey: 'resource-pack-reconciliation-pending',
    actionKey: 'resource-pack-reconcile-library',
    message:
        'Le pack a été importé. La bibliothèque doit être relue avant de fermer le projet. L’import ne sera pas relancé.',
    label: 'Relire la bibliothèque',
    resolve: () async {
      await owner.retryReconciliation();
    },
  ),
  final owner? when owner.requiresRecovery => (
    kind: ResourcePackResolutionKind.recovery,
    noticeKey: 'resource-pack-recovery-pending',
    actionKey: 'resource-pack-recover-finalization',
    message:
        'La finalisation de l’import du pack doit être reprise avant de fermer le projet. La sélection ne sera pas importée à nouveau.',
    label: 'Reprendre la finalisation',
    resolve: owner.recover,
  ),
  _ => null,
};

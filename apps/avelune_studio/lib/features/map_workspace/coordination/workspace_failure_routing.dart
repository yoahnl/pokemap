import '../../verification/application/studio_failure_diagnosis.dart';
import '../domain/workspace_navigation.dart';

WorkspaceSpace? workspaceSpaceForFailure(
  StudioFailureOwner owner, {
  required bool presentationsAvailable,
}) => switch (owner) {
  StudioFailureOwner.general ||
  StudioFailureOwner.image ||
  StudioFailureOwner.timeWeather => WorkspaceSpace.projectSettings,
  StudioFailureOwner.resources => WorkspaceSpace.resources,
  StudioFailureOwner.pokemon => WorkspaceSpace.pokemon,
  StudioFailureOwner.regionalMap => WorkspaceSpace.regionalMap,
  StudioFailureOwner.story => WorkspaceSpace.story,
  StudioFailureOwner.presentations =>
    presentationsAvailable ? WorkspaceSpace.presentation : WorkspaceSpace.story,
  StudioFailureOwner.map => WorkspaceSpace.map,
  StudioFailureOwner.verification => WorkspaceSpace.verification,
  StudioFailureOwner.exportDestination || StudioFailureOwner.exportMode => null,
};

WorkspaceSpace workspaceSettingsOrigin(
  WorkspaceSpace current,
  WorkspaceSpace origin,
) => current == WorkspaceSpace.projectSettings ? origin : current;

String workspaceSettingsReturnLabel(WorkspaceSpace origin) => switch (origin) {
  WorkspaceSpace.gameExport => 'Retour à l’export',
  WorkspaceSpace.verification => 'Retour aux vérifications',
  WorkspaceSpace.map => 'Retour à la carte',
  _ => 'Retour à l’espace précédent',
};

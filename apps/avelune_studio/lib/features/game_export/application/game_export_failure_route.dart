import '../../verification/application/studio_failure_diagnosis.dart';

enum GameExportFailureRoute { chooseDestination, localTestMode, ownerWorkspace }

GameExportFailureRoute? gameExportFailureRoute(
  StudioFailureOwner? owner, {
  required bool workspaceAvailable,
}) => switch (owner) {
  null => null,
  StudioFailureOwner.exportDestination =>
    GameExportFailureRoute.chooseDestination,
  StudioFailureOwner.exportMode => GameExportFailureRoute.localTestMode,
  _ => workspaceAvailable ? GameExportFailureRoute.ownerWorkspace : null,
};

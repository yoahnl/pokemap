part of 'map_workspace_screen.dart';

extension _WorkspaceVerificationBinding on _MapWorkspaceScreenState {
  void _openVerification() {
    _verificationOrigin = WorkspaceReturn.story;
    _show(WorkspaceSpace.verification);
  }

  Widget _verificationPage() {
    return const Center(
      child: Text('Interface Vérification retirée — reconstruction en attente.'),
    );
  }
}

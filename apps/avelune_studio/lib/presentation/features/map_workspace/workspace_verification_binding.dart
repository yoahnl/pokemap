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

  /// Names the editor a diagnostic can reach, or null when the report only
  /// carries a family this host cannot open precisely.
  String? _destinationLabel(NarrativeProjectDiagnostic item) =>
      switch (item.destination) {
        NarrativeProjectDiagnosticDestination.scene =>
          _empty(item.sceneId) || _scenes == null ? null : 'Éditeur de scène',
        NarrativeProjectDiagnosticDestination.dialogue =>
          _empty(item.dialogueId) || _dialogues == null
              ? null
              : 'Éditeur de dialogue',
        NarrativeProjectDiagnosticDestination.cinematic =>
          _empty(item.cinematicId) || _cinematics == null
              ? null
              : 'Cinématique sur carte',
        NarrativeProjectDiagnosticDestination.event =>
          _empty(item.eventId) || _events == null
              ? null
              : 'Événements et déclencheurs',
        NarrativeProjectDiagnosticDestination.storyline =>
          _empty(item.storylineId) || _stories == null
              ? null
              : _progressionLabel(item),
        NarrativeProjectDiagnosticDestination.fact =>
          _empty(item.factId) || _world == null ? null : 'États du monde',
        NarrativeProjectDiagnosticDestination.worldRule =>
          _empty(item.worldRuleId) || _world == null ? null : 'Règles du monde',
        NarrativeProjectDiagnosticDestination.map =>
          _empty(item.mapId) ? null : 'Carte',
        NarrativeProjectDiagnosticDestination.overview => null,
      };

  bool _empty(String? value) => value == null || value.isEmpty;

  /// The page only promises the precision the diagnostic actually carries.
  String _progressionLabel(NarrativeProjectDiagnostic item) =>
      _empty(item.stepId) && _empty(item.chapterId)
      ? 'Histoires et progression (l’histoire, sans étape précise)'
      : 'Histoires et progression (étape ciblée)';

  Future<void> _openDiagnostic(NarrativeProjectDiagnostic item) =>
      _navigation.openDiagnostic(item);
}

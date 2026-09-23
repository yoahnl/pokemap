part of 'map_workspace_screen.dart';

extension _WorkspaceExportBinding on _MapWorkspaceScreenState {
  Future<bool> _allowCloseWithExport() async {
    if (_gameExport?.operationActive == true) return false;
    return _actions.allowClose();
  }

  Future<bool> _prepareGameExport() async {
    if (!await _actions.flushEditors()) return false;
    if (!mounted) return false;
    if (!_actions.hasPendingChanges) return true;
    final choice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enregistrer avant l’export ?'),
        content: const Text(
          'Le paquet utilise uniquement la version enregistrée. '
          'Les documents en cours seront enregistrés par leurs éditeurs ; '
          'si l’un échoue, l’export sera arrêté et les brouillons conservés.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          StudioButton(
            label: 'Enregistrer puis exporter',
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (choice != true || !mounted) return false;
    return _actions.saveForExport();
  }
}

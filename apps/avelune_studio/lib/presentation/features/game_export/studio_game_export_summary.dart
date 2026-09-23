part of 'studio_game_export_page.dart';

extension _StudioGameExportSummary on _StudioGameExportPageState {
  Widget _summaryRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Text(value.isEmpty ? 'À renseigner' : value)),
      ],
    ),
  );

  Widget _summary() {
    final output = widget.controller.outputPath;
    final destinationName = _destination?.split(RegExp(r'[/\\]')).last;
    return StudioPanel(
      title: 'Résumé',
      children: [
        Text(
          'Vérifiez les informations avant de lancer l’export.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _summaryRow(Icons.title_outlined, 'Titre', _title),
        _summaryRow(Icons.update_outlined, 'Version', _version),
        _summaryRow(Icons.person_outline, 'Auteur', _author),
        _summaryRow(Icons.language_outlined, 'Langue principale', _locale),
        _summaryRow(Icons.translate_outlined, 'Langues disponibles', _locales),
        _summaryRow(
          Icons.rocket_launch_outlined,
          'Mode',
          _publication ? 'Publication' : 'Test local',
        ),
        _summaryRow(
          Icons.folder_outlined,
          'Destination',
          destinationName == null ? 'À choisir' : '…/$destinationName',
        ),
        const Divider(height: 30),
        StudioBadge(
          output == null ? 'Contrôles à lancer' : 'Paquet produit',
          tone: output == null ? StudioTone.neutral : StudioTone.success,
          icon: output == null
              ? Icons.info_outline
              : Icons.check_circle_outline,
        ),
        const SizedBox(height: 10),
        Text(
          output == null
              ? 'Les ressources et la compatibilité seront contrôlées pendant la construction du paquet.'
              : 'Le dernier paquet a été écrit. Les changements du formulaire nécessitent un nouvel export.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Divider(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _edit(() => _advanced = !_advanced),
            icon: Icon(_advanced ? Icons.expand_less : Icons.expand_more),
            label: const Text('Options avancées'),
          ),
        ),
        if (_advanced) ...[
          const SizedBox(height: 8),
          StudioDraftField(
            key: const ValueKey('export-game-id'),
            value: _gameId,
            label: 'Identifiant stable du jeu',
            onChanged: (value) => _edit(() => _gameId = value),
          ),
        ],
      ],
    );
  }
}

part of 'studio_game_export_page.dart';

extension _StudioGameExportContent on _StudioGameExportPageState {
  Widget _identityFields(double width) {
    final twoColumns =
        width >= 650 && MediaQuery.textScalerOf(context).scale(1) <= 1.25;
    Widget pair(Widget first, Widget second) => twoColumns
        ? Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          )
        : Column(children: [first, const SizedBox(height: 12), second]);
    return StudioPanel(
      title: 'Informations du jeu',
      children: [
        Text(
          'Ces informations décrivent le paquet distribué. Elles ne renomment pas le projet auteur.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        StudioDraftField(
          value: _title,
          label: 'Titre du jeu',
          onChanged: (value) => _edit(() => _title = value),
        ),
        const SizedBox(height: 12),
        pair(
          StudioDraftField(
            value: _version,
            label: 'Version du jeu',
            onChanged: (value) => _edit(() => _version = value),
          ),
          StudioDraftField(
            value: _author,
            label: 'Auteur',
            onChanged: (value) => _edit(() => _author = value),
          ),
        ),
        const SizedBox(height: 12),
        pair(
          StudioDraftField(
            value: _locale,
            label: 'Langue principale',
            onChanged: (value) => _edit(() => _locale = value),
          ),
          StudioDraftField(
            value: _locales,
            label: 'Langues disponibles',
            onChanged: (value) => _edit(() => _locales = value),
          ),
        ),
      ],
    );
  }

  Widget _modeOptions() {
    final active = widget.controller.operationActive;
    return StudioPanel(
      title: 'Options d’export',
      children: [
        Text(
          'Choisissez les validations prévues par le format du paquet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, bounds) {
            final cards = [
              StudioActionCard(
                title: 'Publication',
                subtitle: 'Paquet distribué dans Avelune Player',
                icon: Icons.rocket_launch_outlined,
                tone: StudioTone.info,
                selected: _publication,
                compact: true,
                onPressed: active
                    ? null
                    : () => _edit(() => _publication = true),
              ),
              StudioActionCard(
                title: 'Test local',
                subtitle: 'Paquet d’essai avec les validations de test',
                icon: Icons.science_outlined,
                tone: StudioTone.feature,
                selected: !_publication,
                compact: true,
                onPressed: active
                    ? null
                    : () => _edit(() => _publication = false),
              ),
            ];
            final narrow =
                bounds.maxWidth < 650 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.25;
            final modeCards = bounds.maxWidth < 510 || !narrow
                ? Row(
                    children: [
                      Expanded(child: cards.first),
                      const SizedBox(width: 10),
                      Expanded(child: cards.last),
                    ],
                  )
                : Column(
                    children: [
                      cards.first,
                      const SizedBox(height: 8),
                      cards.last,
                    ],
                  );
            final destination = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fichier de destination',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                _destinationFields(),
              ],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  modeCards,
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  destination,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: modeCards),
                const SizedBox(width: 14),
                Expanded(child: destination),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _destinationFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Tooltip(
              message: _destination ?? 'Aucun fichier choisi',
              child: Text(
                _destination ?? 'Aucun fichier choisi',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          StudioButton(
            label: 'Choisir…',
            secondary: true,
            icon: Icons.folder_open_outlined,
            onPressed:
                _selectingDestination || widget.controller.operationActive
                ? null
                : () => unawaited(_chooseDestination()),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Un remplacement demandera confirmation.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _statusPanel() {
    final controller = widget.controller;
    return StudioPanel(
      title: controller.outputPath == null
          ? 'Vérifications et export'
          : 'Dernier paquet produit',
      compact: true,
      children: [
        if (controller.outputPath case final path?) ...[
          const Text('Ce fichier peut être installé dans Avelune Player.'),
          const SizedBox(height: 8),
          SelectableText(path),
          ExpansionTile(
            title: const Text('Détails techniques'),
            children: [
              SelectableText('SHA-256 : ${controller.packageSha256}'),
              SelectableText('Révision source : ${controller.sourceRevision}'),
            ],
          ),
        ] else
          Text(
            widget.hasPendingChanges()
                ? 'Des brouillons existent. Leur enregistrement vous sera proposé avant l’export.'
                : 'Le paquet utilisera la version enregistrée du projet.',
          ),
        if (controller.busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(switch (controller.stage) {
            StudioExportStage.preparing =>
              'Préparation et contrôle des documents enregistrés…',
            StudioExportStage.building =>
              'Construction et validation du paquet…',
            _ => 'Écriture et vérification du fichier…',
          }),
        ],
        if (_inputError != null) ...[
          const SizedBox(height: 8),
          StudioNotice(_inputError!, isError: true),
        ],
        if (controller.error != null) ...[
          const SizedBox(height: 8),
          StudioNotice(controller.error!, isError: true),
        ],
        if (controller.warning != null) ...[
          const SizedBox(height: 8),
          StudioNotice(controller.warning!),
        ],
      ],
    );
  }

  Widget _form(double width) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!_loaded) const LinearProgressIndicator(),
      if (_loaded) _identityFields(width),
      const SizedBox(height: 12),
      _modeOptions(),
      const SizedBox(height: 12),
      _statusPanel(),
    ],
  );
}

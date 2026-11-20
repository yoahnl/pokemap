part of 'project_library_pack_dialog.dart';

extension _ProjectLibraryPackReview on _ProjectLibraryPackDialogState {
  Widget _review(BuildContext context, {required bool ready}) {
    final phase = transfer.phase;
    final pack = transfer.inspection['pack'];
    final name = pack is Map ? pack['name'] as String? : null;
    final version = pack is Map ? pack['version'] as String? : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (name != null) ...[
          Text(name, style: Theme.of(context).textTheme.titleLarge),
          if (version != null) Text('Version $version'),
          const SizedBox(height: StudioSpacing.l),
        ],
        if (_closing || transfer.operationActive) _progress(),
        if (transfer.error case final error?) ...[
          Text(
            _errorLabel(error),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: StudioSpacing.m),
        ],
        if (transfer.notice case final notice?) Text(notice),
        if (phase == ResourcePackTransferPhase.selecting) _selection(ready),
        if (phase == ResourcePackTransferPhase.preview) _preview(ready),
        if (phase == ResourcePackTransferPhase.idle && transfer.error == null)
          const Text(
            'Choisissez un fichier .aveluneassets sur cet ordinateur.',
          ),
      ],
    );
  }

  Widget _progress() => Padding(
    padding: const EdgeInsets.only(bottom: StudioSpacing.l),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: StudioSpacing.m),
        Expanded(
          child: Text(switch (transfer.phase) {
            _ when _closing => 'Fermeture de l’aperçu…',
            ResourcePackTransferPhase.picking => 'Sélection du fichier…',
            ResourcePackTransferPhase.inspecting => 'Vérification du pack…',
            ResourcePackTransferPhase.preparing =>
              'Calcul des dépendances et des conflits…',
            ResourcePackTransferPhase.applying => 'Installation du pack…',
            _ => 'Lecture du pack…',
          }),
        ),
      ],
    ),
  );

  Widget _selection(bool ready) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSearchField(
        controller: _search,
        label: 'Rechercher dans le pack',
        onChanged: (value) => unawaited(transfer.setFilter(search: value)),
      ),
      const SizedBox(height: StudioSpacing.m),
      Wrap(
        spacing: StudioSpacing.m,
        runSpacing: StudioSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StudioBadge(
            '${transfer.selectedCount} sur ${transfer.totalCount} sélectionnées',
          ),
          StudioButton(
            label: transfer.search.isEmpty
                ? 'Tout sélectionner'
                : 'Sélectionner les résultats',
            variant: StudioButtonVariant.secondary,
            onPressed: ready && transfer.visibleCount > 0
                ? () => unawaited(transfer.selectFiltered())
                : null,
          ),
        ],
      ),
      const SizedBox(height: StudioSpacing.m),
      if (transfer.entries.isEmpty)
        const Text('Aucune ressource ne correspond à la recherche.'),
      _packRows(
        transfer.entries,
        (row) => CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: row['selected'] == true,
          onChanged: ready ? (_) => unawaited(transfer.toggle(row)) : null,
          title: Text(_label(row)),
        ),
      ),
      if (transfer.nextCursor != null ||
          transfer.entries.length < transfer.visibleCount)
        Wrap(
          spacing: StudioSpacing.m,
          children: [
            StudioButton(
              label: 'Première page',
              variant: StudioButtonVariant.quiet,
              onPressed: ready ? () => unawaited(transfer.firstPage()) : null,
            ),
            StudioButton(
              label: 'Page suivante',
              variant: StudioButtonVariant.quiet,
              onPressed: ready && transfer.nextCursor != null
                  ? () => unawaited(transfer.nextPage())
                  : null,
            ),
          ],
        ),
      _credits(ready),
    ],
  );

  Widget _credits(bool ready) => Padding(
    padding: const EdgeInsets.only(top: StudioSpacing.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: 'Crédits et licences',
          value: transfer.attributionSection,
          options: const {
            'authors': 'Auteurs',
            'sources': 'Origines et licences',
          },
          onChanged: ready
              ? (value) => unawaited(transfer.showAttributions(value))
              : null,
        ),
        if (transfer.attributions.isEmpty)
          const Text('Aucune attribution déclarée.'),
        _packRows(
          transfer.attributions,
          (row) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(_label(row)),
            subtitle: switch (row['licenseCount']) {
              final int count => Text(
                count == 1
                    ? '1 document de licence'
                    : '$count documents de licence',
              ),
              _ => null,
            },
          ),
          maxHeight: 112,
        ),
        if (transfer.attributionCursor != null)
          StudioButton(
            label: 'Autres crédits',
            variant: StudioButtonVariant.quiet,
            onPressed: ready
                ? () => unawaited(transfer.nextAttributionPage())
                : null,
          ),
      ],
    ),
  );

  Widget _preview(bool ready) {
    final summary = transfer.preparedSummary;
    final dependencies = summary['dependencyCount'] as int? ?? 0;
    final resources = transfer.resourceCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: StudioSpacing.m,
          runSpacing: StudioSpacing.s,
          children: [
            StudioBadge(
              resources == 1 ? '1 ressource' : '$resources ressources',
            ),
            StudioBadge(
              dependencies == 1 ? '1 dépendance' : '$dependencies dépendances',
            ),
            if (transfer.conflictCount > 0)
              StudioBadge(
                '${transfer.conflictCount} conflit${transfer.conflictCount == 1 ? '' : 's'}',
              ),
          ],
        ),
        const SizedBox(height: StudioSpacing.m),
        _packRows(
          transfer.preview,
          (row) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(_previewLabel(row)),
            subtitle: switch (row['message'] ?? _disposition(row)) {
              final String detail => Text(detail),
              _ => null,
            },
          ),
        ),
        if (transfer.previewCursor != null)
          StudioButton(
            label: 'Voir la page suivante',
            variant: StudioButtonVariant.quiet,
            onPressed: ready
                ? () => unawaited(transfer.nextPreviewPage())
                : null,
          ),
        if (transfer.conflictCount > 0)
          StudioButton(
            label: 'Préparer une copie séparée',
            variant: StudioButtonVariant.secondary,
            onPressed: ready
                ? () => unawaited(transfer.prepare(importCopy: true))
                : null,
          ),
        _credits(ready),
      ],
    );
  }

  Widget _packRows(
    List<Map<String, Object?>> rows,
    Widget Function(Map<String, Object?>) tile, {
    double maxHeight = 208,
  }) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: maxHeight),
    child: ListView.builder(
      primary: false,
      shrinkWrap: true,
      itemCount: rows.length,
      itemBuilder: (_, index) => tile(rows[index]),
    ),
  );

  String _label(Map<String, Object?> row) =>
      row['label'] as String? ?? 'Ressource du pack';

  String _previewLabel(Map<String, Object?> row) {
    final label = _label(row);
    if (row['disposition'] != 'source') return label;
    return switch (label.split('.').last.toLowerCase()) {
      'glb' => 'Fichier GLB',
      'png' => 'Image PNG',
      _ => 'Fichier associé',
    };
  }

  String? _disposition(Map<String, Object?> row) =>
      switch (row['disposition']) {
        'create' => 'À ajouter',
        'copy' => 'À installer en copie',
        'historical' => 'Déjà présent dans le projet',
        'source' => switch (row['requiredByLabel']) {
          final String owner when owner.isNotEmpty => 'Associé à $owner',
          _ => null,
        },
        _ => null,
      };

  String _errorLabel(String error) {
    if (error.contains('project_stale') || error.contains('projet a changé')) {
      return 'Le projet a changé. Préparez de nouveau l’installation avant de confirmer.';
    }
    if (error.contains('dimensions_incompatible')) {
      return 'La taille des tuiles du pack diffère de celle du projet.';
    }
    return switch (transfer.phase) {
      ResourcePackTransferPhase.reconciliationRequired ||
      ResourcePackTransferPhase.recoveryRequired =>
        'La relecture a échoué. Réessayez de reprendre l’installation.',
      ResourcePackTransferPhase.idle => 'Le pack n’a pas pu être vérifié. Choisissez un fichier .aveluneassets valide.',
      _ =>
        'Le pack n’a pas pu être préparé. Vérifiez la sélection et réessayez.',
    };
  }
}

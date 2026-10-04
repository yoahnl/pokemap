part of 'character_removal_dialog.dart';

extension _CharacterRemovalFields on _CharacterRemovalDialogState {
  Widget _fields(bool busy) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(widget.name, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
        'Seule cette identité sera retirée. Les PNG, portraits, images et animations partagées restent conservés.',
      ),
      if (_working) const LinearProgressIndicator(),
      if (_error != null)
        Text(
          'Analyse ou résolution refusée : $_error',
          key: const ValueKey('character-removal-refusal'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (_inspection != null) ...[
        const SizedBox(height: 12),
        Text(
          _requiresResolution
              ? 'Références à résoudre dans tout le projet'
              : 'Aucune référence dans le périmètre complet analysé.',
        ),
        for (final dependency
            in (_impact['dependencies'] as List? ?? const []).whereType<Map>())
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${widget.ownerLabel(dependency)}${_resolution == 'replace'
                  ? ' → remplacement global par le personnage choisi'
                  : _resolution == 'clear'
                  ? ' → référence retirée ou vidée, propriétaire conservé'
                  : ''}',
            ),
          ),
        if (_requiresResolution) ...[
          const SizedBox(height: 14),
          StudioSelect(
            key: const ValueKey('character-removal-resolution'),
            value: _resolution,
            label: 'Résolution pour toutes les références',
            options: {
              'replace': 'Remplacer par un autre personnage',
              if (_impact['clearAllowed'] != false)
                'clear': 'Retirer les références autorisées',
            },
            onChanged: busy || _working
                ? null
                : (value) {
                    _change(() => _resolution = value);
                    _prepare();
                  },
          ),
          if (_impact['clearAllowed'] == false)
            for (final problem
                in (_impact['clearProblems'] as List? ?? const [])
                    .whereType<Map>())
              Text(
                'Retrait des références indisponible : ${problem['message'] ?? problem['code']}',
              ),
          if (_resolution == 'replace') ...[
            const SizedBox(height: 12),
            StudioSelect(
              key: const ValueKey('character-removal-replacement'),
              value: _replacementId,
              label: 'Personnage remplaçant',
              options: {
                for (final candidate in _candidates.where(
                  (candidate) => candidate['compatible'] != false,
                ))
                  candidate['id'] as String: candidate['name'] as String,
              },
              onChanged: busy || _working
                  ? null
                  : (value) {
                      _change(() => _replacementId = value);
                      _prepare();
                    },
            ),
            for (final candidate in _candidates.where(
              (candidate) => candidate['compatible'] == false,
            ))
              for (final problem
                  in (candidate['incompatibilities'] as List? ?? const [])
                      .whereType<Map>())
                Text(
                  '${candidate['name']} : ${problem['message'] ?? problem['code']}',
                ),
          ],
        ],
      ],
      if (_plan != null) ...[
        const SizedBox(height: 12),
        Text(
          'Plan validé : ${_plan!.changedPaths.length} document(s) concernés. Aucune écriture avant confirmation.',
        ),
      ],
      const SizedBox(height: 12),
      StudioButton(
        label: 'Réanalyser',
        secondary: true,
        onPressed: busy || _working ? null : _inspect,
      ),
      CheckboxListTile(
        key: const ValueKey('character-removal-confirm'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Je confirme ce retrait et la résolution affichée.'),
        value: _confirmed,
        onChanged: busy || _working || _plan == null
            ? null
            : (value) => _change(() => _confirmed = value == true),
      ),
    ],
  );
}

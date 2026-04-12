part of 'pokedex_workspace_page.dart';

// Colonne droite du workspace Pokédex.
//
// Cette zone reste en lecture ou édition locale selon l'onglet actif. Elle ne
// décide jamais du contenu métier ; elle reflète uniquement la sélection et les
// loaders déjà résolus par le workspace principal.

class PokedexWorkspaceDetailPane extends StatelessWidget {
  const PokedexWorkspaceDetailPane({
    super.key,
    required this.selectedEntry,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.detailFuture,
    required this.onDeleteSpecies,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
    required this.onLoadMovesCatalog,
    required this.onPreviewMovesCatalogSync,
    required this.onSyncMovesCatalog,
  });

  final PokemonDatabaseIndexEntry? selectedEntry;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<PokedexSpeciesDetail>? detailFuture;
  final Future<void> Function(PokemonDatabaseIndexEntry entry) onDeleteSpecies;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;
  final Future<PokemonMovesCatalogView> Function() onLoadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      onPreviewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() onSyncMovesCatalog;

  @override
  Widget build(BuildContext context) {
    final entry = selectedEntry;
    if (entry == null || detailFuture == null) {
      return const PokedexWorkspaceStateCard(
        key: Key('pokedex-detail-empty-state'),
        title: 'Fiche espèce',
        message:
            'Sélectionnez une espèce dans la liste pour voir sa fiche, ses formes, son learnset, ses évolutions et ses médias.',
      );
    }

    return FutureBuilder<PokedexSpeciesDetail>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-detail-loading-state'),
            title: 'Fiche espèce',
            message: 'Chargement de la fiche Pokédex…',
          );
        }

        if (snapshot.hasError) {
          final message = switch (snapshot.error) {
            final EditorApplicationException applicationError =>
              applicationError.message,
            _ => snapshot.error?.toString() ?? 'Erreur inconnue',
          };
          return PokedexWorkspaceStateCard(
            key: const Key('pokedex-detail-error-state'),
            title: 'Fiche espèce',
            accent: EditorChrome.inspectorJoyCoral,
            message: 'Impossible de charger la fiche de ${entry.id}.\n$message',
          );
        }

        final detail = snapshot.data;
        if (detail == null) {
          return const PokedexWorkspaceStateCard(
            title: 'Fiche espèce',
            message: 'Aucune donnée Pokédex détaillée disponible.',
          );
        }

        return _PokedexSpeciesDetailView(
          entry: entry,
          detail: detail,
          selectedTabId: selectedTabId,
          onTabChanged: onTabChanged,
          onDeleteSpecies: onDeleteSpecies,
          onSaveMetadata: onSaveMetadata,
          onSaveFormsClassification: onSaveFormsClassification,
          onSaveLearnset: onSaveLearnset,
          onSaveEvolution: onSaveEvolution,
          onSaveMedia: onSaveMedia,
          onLoadMovesCatalog: onLoadMovesCatalog,
          onPreviewMovesCatalogSync: onPreviewMovesCatalogSync,
          onSyncMovesCatalog: onSyncMovesCatalog,
        );
      },
    );
  }
}

class _PokedexSpeciesDetailView extends StatelessWidget {
  const _PokedexSpeciesDetailView({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.onDeleteSpecies,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
    required this.onLoadMovesCatalog,
    required this.onPreviewMovesCatalogSync,
    required this.onSyncMovesCatalog,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<void> Function(PokemonDatabaseIndexEntry entry) onDeleteSpecies;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;
  final Future<PokemonMovesCatalogView> Function() onLoadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      onPreviewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() onSyncMovesCatalog;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: const Key('pokedex-detail-pane'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.primaryName,
                        style: TextStyle(
                          color: label,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.id}',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Le bouton de suppression vit dans l'en-tête de la fiche
                // parce que l'action s'applique à l'espèce sélectionnée entière,
                // pas seulement à un onglet particulier.
                //
                // On le garde volontairement simple :
                // - pas de menu contextuel ;
                // - pas de second flux de suppression dans la liste ;
                // - confirmation obligatoire gérée au niveau du workspace.
                PushButton(
                  key: const Key('pokedex-delete-species-button'),
                  controlSize: ControlSize.large,
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  onPressed: () => onDeleteSpecies(entry),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PokedexStatusChip(
                  label: entry.isEnabledInProject ? 'Activée' : 'Désactivée',
                  isEnabled: entry.isEnabledInProject,
                ),
                ...entry.types.map((type) => _PokedexTypeChip(label: type)),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoSlidingSegmentedControl<String>(
              key: const Key('pokedex-detail-tabs'),
              groupValue: selectedTabId,
              onValueChanged: (value) {
                if (value != null) {
                  onTabChanged(value);
                }
              },
              children: const <String, Widget>{
                'overview': Padding(
                  key: Key('pokedex-tab-overview'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Fiche'),
                ),
                'forms': Padding(
                  key: Key('pokedex-tab-forms'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Formes'),
                ),
                'learnset': Padding(
                  key: Key('pokedex-tab-learnset'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Learnset'),
                ),
                'evolutions': Padding(
                  key: Key('pokedex-tab-evolutions'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Évolutions'),
                ),
                'media': Padding(
                  key: Key('pokedex-tab-media'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Médias'),
                ),
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _PokedexDetailTabBody(
                entry: entry,
                detail: detail,
                selectedTabId: selectedTabId,
                onSaveMetadata: onSaveMetadata,
                onSaveFormsClassification: onSaveFormsClassification,
                onSaveLearnset: onSaveLearnset,
                onSaveEvolution: onSaveEvolution,
                onSaveMedia: onSaveMedia,
                onLoadMovesCatalog: onLoadMovesCatalog,
                onPreviewMovesCatalogSync: onPreviewMovesCatalogSync,
                onSyncMovesCatalog: onSyncMovesCatalog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexDetailTabBody extends StatelessWidget {
  const _PokedexDetailTabBody({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
    required this.onLoadMovesCatalog,
    required this.onPreviewMovesCatalogSync,
    required this.onSyncMovesCatalog,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;
  final Future<PokemonMovesCatalogView> Function() onLoadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      onPreviewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() onSyncMovesCatalog;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTabId) {
      'forms' => _PokedexFormsTab(
          detail: detail,
          onSave: onSaveFormsClassification,
        ),
      'learnset' => _PokedexLearnsetTab(
          detail: detail,
          onSave: onSaveLearnset,
          loadMovesCatalog: onLoadMovesCatalog,
          previewMovesCatalogSync: onPreviewMovesCatalogSync,
          syncMovesCatalog: onSyncMovesCatalog,
        ),
      'evolutions' => _PokedexEvolutionTab(
          detail: detail,
          onSave: onSaveEvolution,
        ),
      'media' => _PokedexMediaTab(
          detail: detail,
          onSave: onSaveMedia,
        ),
      _ => _PokedexOverviewTab(
          entry: entry,
          detail: detail,
          onSaveMetadata: onSaveMetadata,
        ),
    };
  }
}

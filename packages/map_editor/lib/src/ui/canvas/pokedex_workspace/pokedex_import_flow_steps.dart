part of 'pokedex_workspace_page.dart';

// Étapes visuelles du wizard d'import.
//
// Chaque widget ici reste strictement présentation :
// - aucun accès disque ;
// - aucun accès HTTP ;
// - aucune validation métier ;
// - seulement du wording, de la hiérarchie visuelle et des callbacks.

class _PokedexImportSourceStep extends StatelessWidget {
  const _PokedexImportSourceStep({
    required this.selectedSource,
    required this.onSourceSelected,
    required this.onContinue,
    required this.onCancel,
  });

  final _PokedexImportSourceKind selectedSource;
  final ValueChanged<_PokedexImportSourceKind> onSourceSelected;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-source-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Importer des Pokémon',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez la source qui vous convient. Le parcours reste volontairement simple : une source, un aperçu honnête, puis un import dans le projet local.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir une source',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        _PokedexImportSourceCard(
          cardKey: const Key('pokedex-import-json-source-card'),
          title: 'Fichier JSON',
          icon: CupertinoIcons.doc_text_fill,
          isSelected: selectedSource == _PokedexImportSourceKind.jsonLocal,
          onPressed: () => onSourceSelected(_PokedexImportSourceKind.jsonLocal),
        ),
        const SizedBox(height: 10),
        _PokedexImportSourceCard(
          cardKey: const Key('pokedex-import-external-api-source-card'),
          title: 'API externe',
          icon: CupertinoIcons.cloud_fill,
          isSelected: selectedSource == _PokedexImportSourceKind.externalApi,
          trailingLabel: 'Live',
          onPressed: () =>
              onSourceSelected(_PokedexImportSourceKind.externalApi),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-source-continue-button'),
              controlSize: ControlSize.large,
              onPressed: onContinue,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportJsonFileStep extends StatelessWidget {
  const _PokedexImportJsonFileStep({
    required this.selectedJsonSourcePath,
    required this.isBusy,
    required this.errorMessage,
    required this.onPickJsonSource,
    required this.onContinue,
    required this.onCancel,
  });

  final String? selectedJsonSourcePath;
  final bool isBusy;
  final String? errorMessage;
  final Future<void> Function() onPickJsonSource;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final hasFile = selectedJsonSourcePath?.trim().isNotEmpty == true;
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: subtle,
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-json-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis fichier JSON',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez le fichier espèce à importer. L’aperçu vous montrera ensuite ce qui sera ajouté au projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir un fichier',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          key: const Key('pokedex-import-pick-json-file-button'),
          color: EditorChrome.accentJade.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          onPressed: isBusy ? null : onPickJsonSource,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Choisir un fichier'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('pokedex-import-selected-file'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            hasFile
                ? p.basename(selectedJsonSourcePath!)
                : 'Aucun fichier sélectionné',
            style: TextStyle(
              color: hasFile ? CupertinoColors.white : subtle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-json-continue-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onContinue,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportExternalQueryStep extends StatelessWidget {
  const _PokedexImportExternalQueryStep({
    required this.externalImportMode,
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.isSearching,
    required this.isResolvingBatch,
    required this.errorMessage,
    required this.searchResult,
    required this.batchSelectionResult,
    required this.selectedSuggestion,
    required this.onModeChanged,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    required this.onContinue,
    required this.onCancel,
  });

  final _PokedexExternalImportMode externalImportMode;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isSearching;
  final bool isResolvingBatch;
  final String? errorMessage;
  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalBatchSelectionResult batchSelectionResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;
  final ValueChanged<_PokedexExternalImportMode> onModeChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PokemonExternalSpeciesSuggestion> onSuggestionSelected;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-external-query-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis API externe',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'La source produit reste “API externe”. Choisissez ensuite explicitement un mode mono-espèce ou batch dry-run selon le besoin.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Mode de requête',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        _PokedexExternalImportModeSegmentedControl(
          selectedMode: externalImportMode,
          onModeChanged: isBusy ? null : onModeChanged,
        ),
        const SizedBox(height: 20),
        Text(
          externalImportMode == _PokedexExternalImportMode.singleSpecies
              ? 'Pokémon à importer'
              : 'Sélection batch à prévisualiser',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        if (externalImportMode == _PokedexExternalImportMode.singleSpecies)
          _PokedexExternalSpeciesAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            isBusy: isBusy,
            isSearching: isSearching,
            searchResult: searchResult,
            selectedSuggestion: selectedSuggestion,
            onQueryChanged: onQueryChanged,
            onSuggestionSelected: onSuggestionSelected,
          )
        else
          _PokedexExternalBatchSelectionField(
            controller: controller,
            focusNode: focusNode,
            isBusy: isBusy,
            isResolving: isResolvingBatch,
            selectionResult: batchSelectionResult,
            onQueryChanged: onQueryChanged,
          ),
        const SizedBox(height: 10),
        Text(
          externalImportMode == _PokedexExternalImportMode.singleSpecies
              ? 'Les détails techniques PokeAPI / Showdown restent internes au pipeline. La prévisualisation reste bloquée tant qu’une suggestion n’a pas été sélectionnée explicitement.'
              : 'Le dry-run batch reste strictement non destructif dans ce lot. La liste finale résolue doit être lisible avant toute prévisualisation, et aucun import batch réel n’est encore proposé.',
          style: helperStyle,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: Key(
                externalImportMode == _PokedexExternalImportMode.singleSpecies
                    ? 'pokedex-import-external-preview-button'
                    : 'pokedex-import-external-batch-preview-button',
              ),
              controlSize: ControlSize.large,
              onPressed: _resolveContinueState(),
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : Text(
                      externalImportMode ==
                              _PokedexExternalImportMode.singleSpecies
                          ? 'Prévisualiser'
                          : 'Dry-run batch',
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> Function()? _resolveContinueState() {
    if (isBusy) {
      return null;
    }

    return switch (externalImportMode) {
      _PokedexExternalImportMode.singleSpecies =>
        isSearching || selectedSuggestion == null ? null : onContinue,
      _PokedexExternalImportMode.batchDryRun =>
        isResolvingBatch || !batchSelectionResult.canDryRun ? null : onContinue,
    };
  }
}

class _PokedexExternalImportModeSegmentedControl extends StatelessWidget {
  const _PokedexExternalImportModeSegmentedControl({
    required this.selectedMode,
    required this.onModeChanged,
  });

  final _PokedexExternalImportMode selectedMode;
  final ValueChanged<_PokedexExternalImportMode>? onModeChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<_PokedexExternalImportMode>(
      key: const Key('pokedex-import-external-mode-segmented-control'),
      groupValue: selectedMode,
      onValueChanged: (value) {
        if (value != null && onModeChanged != null) {
          onModeChanged!(value);
        }
      },
      thumbColor: EditorChrome.accentJade.withValues(alpha: 0.28),
      backgroundColor: EditorChrome.islandFillElevated(context),
      children: const <_PokedexExternalImportMode, Widget>{
        _PokedexExternalImportMode.singleSpecies: Padding(
          key: Key('pokedex-import-external-mode-mono-option'),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'Mono-espèce',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        _PokedexExternalImportMode.batchDryRun: Padding(
          key: Key('pokedex-import-external-mode-batch-option'),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'Batch dry-run',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      },
    );
  }
}

class _PokedexImportPreviewStep extends StatelessWidget {
  const _PokedexImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonJsonImportPreview preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez rapidement l’espèce et les fichiers trouvés avant de lancer l’import.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${preview.nationalDex.toString().padLeft(3, '0')} ${preview.primaryName}',
                  key: const Key('pokedex-import-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${preview.types.join(' / ')}',
                  key: const Key('pokedex-import-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-learnset-status'),
                  label: preview.learnset.label,
                  isFound: preview.learnset.isFound,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-evolution-status'),
                  label: preview.evolution.label,
                  isFound: preview.evolution.isFound,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-media-status'),
                  label: preview.media.label,
                  isFound: preview.media.isFound,
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalImportPreviewStep extends StatelessWidget {
  const _PokedexExternalImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonExternalImportResult preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final previewData = preview.preview;

    return Column(
      key: const Key('pokedex-import-external-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez l’espèce, les données trouvées et les warnings avant d’ajouter ce Pokémon au projet local.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: preview.hasConflicts
                  ? EditorChrome.inspectorJoyCoral
                  : EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${previewData.nationalDex.toString().padLeft(3, '0')} ${previewData.primaryName}',
                  key: const Key('pokedex-import-external-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${previewData.types.join(' / ')}',
                  key: const Key('pokedex-import-external-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key(
                      'pokedex-import-external-preview-learnset-status'),
                  label: previewData.learnset.label,
                  isFound: previewData.learnset.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key(
                      'pokedex-import-external-preview-evolution-status'),
                  label: previewData.evolution.label,
                  isFound: previewData.evolution.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key:
                      const Key('pokedex-import-external-preview-media-status'),
                  label: previewData.media.label,
                  isFound: previewData.media.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key:
                      const Key('pokedex-import-external-preview-cries-status'),
                  label: previewData.cries.label,
                  isFound: previewData.cries.isAvailable,
                ),
                const SizedBox(height: 16),
                Text(
                  preview.hasConflicts
                      ? 'Politique actuelle : bloquer en cas de conflit'
                      : 'Politique actuelle : import local prudent',
                  style: helperStyle,
                ),
                if (preview.warnings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (final warning in preview.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $warning',
                        key: Key(
                          'pokedex-import-external-warning-${warning.hashCode}',
                        ),
                        style: const TextStyle(
                          color: EditorChrome.inspectorJoyCoral,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-external-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy || preview.hasConflicts ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalBatchPreviewStep extends StatelessWidget {
  const _PokedexExternalBatchPreviewStep({
    required this.selection,
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
    required this.onClose,
  });

  final PokemonExternalBatchSelectionResult selection;
  final PokemonExternalBatchImportResult preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onImport;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final entriesBySpeciesId = <String, PokemonExternalBatchImportEntryResult>{
      for (final entry in preview.entries) entry.speciesId: entry,
    };

    return Column(
      key: const Key('pokedex-import-external-batch-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dry-run batch API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Ce lot reste volontairement non destructif : ce dry-run montre uniquement ce qui serait ciblé et les conflits éventuels, sans rien écrire dans le projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _PokedexBatchSummaryMetric(
                  key: const Key(
                      'pokedex-import-external-batch-summary-targets'),
                  label: 'Cibles',
                  value: selection.targets.length.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key: const Key('pokedex-import-external-batch-summary-ready'),
                  label: 'Prêtes',
                  value: preview.successfulCount.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key: const Key(
                      'pokedex-import-external-batch-summary-conflicts'),
                  label: 'Conflits',
                  value: preview.conflictCount.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key:
                      const Key('pokedex-import-external-batch-summary-failed'),
                  label: 'Erreurs',
                  value: preview.failedCount.toString(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Résultat détaillé du dry-run',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            key: const Key('pokedex-import-external-batch-preview-list'),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EditorChrome.accentJade.withValues(alpha: 0.25),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: selection.targets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final target = selection.targets[index];
                final entry = entriesBySpeciesId[target.speciesId];
                return _PokedexExternalBatchPreviewEntryCard(
                  target: target,
                  entry: entry,
                );
              },
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key(
                  'pokedex-import-external-batch-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key(
                'pokedex-import-external-batch-execute-button',
              ),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onImport,
              child: const Text('Exécuter le batch'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key(
                'pokedex-import-external-batch-preview-close-button',
              ),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onClose,
              child: const Text('Fermer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalBatchExecutionResultStep extends StatelessWidget {
  const _PokedexExternalBatchExecutionResultStep({
    required this.selection,
    required this.progress,
    required this.result,
    required this.isBusy,
    required this.errorMessage,
    required this.onClose,
  });

  final PokemonExternalBatchSelectionResult selection;
  final PokemonExternalBatchImportProgress? progress;
  final PokemonExternalBatchImportResult? result;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final currentProgress = progress;
    final totalCount = selection.targets.length;
    final completedCount = currentProgress?.completedCount ?? 0;
    final successfulCount =
        result?.successfulCount ?? currentProgress?.successfulCount ?? 0;
    final skippedCount =
        result?.skippedCount ?? currentProgress?.skippedCount ?? 0;
    final conflictCount =
        result?.conflictCount ?? currentProgress?.conflictCount ?? 0;
    final failedCount =
        result?.failedCount ?? currentProgress?.failedCount ?? 0;
    final completionRatio = totalCount <= 0 ? 0.0 : completedCount / totalCount;
    final entriesBySpeciesId = <String, PokemonExternalBatchImportEntryResult>{
      for (final entry
          in result?.entries ?? const <PokemonExternalBatchImportEntryResult>[])
        entry.speciesId: entry,
    };
    // Le lot 4 n'affiche volontairement aucune "fausse" progression :
    // l'état visible dépend uniquement des callbacks réellement remontés par le
    // batch applicatif existant après chaque espèce terminée.

    return Column(
      key: const Key('pokedex-import-external-batch-result-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import batch API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          isBusy
              ? 'Le batch réel est en cours. La progression ci-dessous reflète uniquement les espèces effectivement terminées par le pipeline existant.'
              : 'Le batch réel est terminé. Ce rapport reprend le résultat détaillé renvoyé par le pipeline existant, espèce par espèce.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentJade.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 10,
                  children: [
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-total',
                      ),
                      label: 'Cibles',
                      value: totalCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-completed',
                      ),
                      label: 'Terminées',
                      value: completedCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-success',
                      ),
                      label: 'Succès',
                      value: successfulCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-skips',
                      ),
                      label: 'Skips',
                      value: skippedCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-conflicts',
                      ),
                      label: 'Conflits',
                      value: conflictCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-failed',
                      ),
                      label: 'Erreurs',
                      value: failedCount.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    key: const Key(
                      'pokedex-import-external-batch-result-progress-track',
                    ),
                    height: 8,
                    color: EditorChrome.subtleSeparator(context),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: completionRatio.clamp(0.0, 1.0),
                        child: Container(
                          color: EditorChrome.accentJade,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Progression observée : $completedCount / $totalCount espèces terminées.',
                  key: const Key(
                    'pokedex-import-external-batch-result-progress-label',
                  ),
                  style: helperStyle,
                ),
                if ((currentProgress?.lastCompletedSpeciesId ?? '')
                    .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dernière espèce terminée : ${currentProgress!.lastCompletedSpeciesId}',
                    key: const Key(
                      'pokedex-import-external-batch-result-last-completed',
                    ),
                    style: helperStyle.copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isBusy ? 'Résultat en construction' : 'Rapport final',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            key: const Key('pokedex-import-external-batch-result-list'),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EditorChrome.accentJade.withValues(alpha: 0.25),
              ),
            ),
            child: result == null
                ? Center(
                    child: Text(
                      isBusy
                          ? 'L’exécution batch est en cours. Le rapport final apparaîtra ici au fil des espèces terminées.'
                          : 'Aucun rapport final disponible.',
                      style: helperStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: selection.targets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final target = selection.targets[index];
                      final entry = entriesBySpeciesId[target.speciesId];
                      return _PokedexExternalBatchExecutionEntryCard(
                        target: target,
                        entry: entry,
                      );
                    },
                  ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key:
                const Key('pokedex-import-external-batch-result-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key(
                  'pokedex-import-external-batch-result-close-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onClose,
              child: const Text('Fermer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexBatchSummaryMetric extends StatelessWidget {
  const _PokedexBatchSummaryMetric({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PokedexExternalBatchPreviewEntryCard extends StatelessWidget {
  const _PokedexExternalBatchPreviewEntryCard({
    required this.target,
    required this.entry,
  });

  final PokemonExternalBatchSelectionTarget target;
  final PokemonExternalBatchImportEntryResult? entry;

  @override
  Widget build(BuildContext context) {
    final batchEntry = entry;
    final isFailed = batchEntry?.isFailed ?? true;
    final isConflict = batchEntry?.isConflict ?? false;
    final isSkipped = batchEntry?.isSkipped ?? false;
    final hasPreview = batchEntry?.result != null;
    final statusLabel = switch ((isFailed, isConflict, isSkipped)) {
      (true, _, _) => 'Erreur dry-run',
      (_, true, _) => 'Conflit détecté',
      (_, _, true) => 'Espèce skippée',
      _ => hasPreview ? 'Aperçu disponible' : 'Aucun aperçu',
    };
    final accent = switch ((isFailed, isConflict, isSkipped)) {
      (true, _, _) => EditorChrome.inspectorJoyCoral,
      (_, true, _) => EditorChrome.accentWarm,
      (_, _, true) => EditorChrome.accentWarm,
      _ => EditorChrome.accentJade,
    };
    final warnings = batchEntry?.result?.warnings ?? const <String>[];

    return Container(
      key: Key(
          'pokedex-import-external-batch-preview-entry-${target.speciesId}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${target.nationalDex.toString().padLeft(4, '0')} ${target.primaryName} · ${target.speciesId}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Demandé par : ${target.requestedInputs.join(', ')}',
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (batchEntry?.result != null) ...[
            const SizedBox(height: 10),
            Text(
              'Prévisualisation disponible : ${batchEntry!.result!.preview.primaryName} · ${batchEntry.result!.preview.speciesId}',
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (batchEntry?.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              batchEntry!.errorMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $warning',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PokedexExternalBatchExecutionEntryCard extends StatelessWidget {
  const _PokedexExternalBatchExecutionEntryCard({
    required this.target,
    required this.entry,
  });

  final PokemonExternalBatchSelectionTarget target;
  final PokemonExternalBatchImportEntryResult? entry;

  @override
  Widget build(BuildContext context) {
    final batchEntry = entry;
    final isFailed = batchEntry?.isFailed ?? true;
    final isConflict = batchEntry?.isConflict ?? false;
    final isSkipped = batchEntry?.isSkipped ?? false;
    final hasWritesApplied = batchEntry?.result?.hasWritesApplied ?? false;
    final statusLabel =
        switch ((isFailed, isConflict, isSkipped, hasWritesApplied)) {
      (true, _, _, _) => 'Erreur',
      (_, true, _, _) => 'Conflit',
      (_, _, true, _) => 'Skippée',
      (_, _, _, true) => 'Import réussi',
      _ => 'Sans écriture',
    };
    final accent =
        switch ((isFailed, isConflict, isSkipped, hasWritesApplied)) {
      (true, _, _, _) => EditorChrome.inspectorJoyCoral,
      (_, true, _, _) => EditorChrome.accentWarm,
      (_, _, true, _) => EditorChrome.accentWarm,
      (_, _, _, true) => EditorChrome.accentJade,
      _ => EditorChrome.subtleLabel(context),
    };
    final warnings = batchEntry?.result?.warnings ?? const <String>[];
    final result = batchEntry?.result;

    return Container(
      key: Key(
        'pokedex-import-external-batch-result-entry-${target.speciesId}',
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${target.nationalDex.toString().padLeft(4, '0')} ${target.primaryName} · ${target.speciesId}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Demandé par : ${target.requestedInputs.join(', ')}',
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 10),
            Text(
              'Résolu en : ${result.preview.primaryName} · ${result.preview.speciesId}',
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Artifacts écrits : ${result.artifacts.where((artifact) => artifact.action == PokemonExternalImportArtifactAction.create || artifact.action == PokemonExternalImportArtifactAction.overwrite).length} · Assets téléchargés : ${result.downloadedAssetCount}',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (batchEntry?.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              batchEntry!.errorMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $warning',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

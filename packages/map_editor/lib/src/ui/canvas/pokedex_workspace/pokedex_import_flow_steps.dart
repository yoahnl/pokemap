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
    required this.controller,
    required this.isBusy,
    required this.errorMessage,
    required this.onContinue,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool isBusy;
  final String? errorMessage;
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
          'Saisissez un nom, un slug ou un numéro Pokédex. L’éditeur préparera un aperçu avant toute écriture dans le projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Pokémon à importer',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        CupertinoTextField(
          key: const Key('pokedex-import-external-query-field'),
          controller: controller,
          placeholder: 'Ex. pikachu, bulbasaur ou 25',
          enabled: !isBusy,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        const SizedBox(height: 10),
        Text(
          'La source visible reste “API externe”. Les détails techniques PokeAPI / Showdown restent internes au pipeline.',
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
              key: const Key('pokedex-import-external-preview-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onContinue,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Prévisualiser'),
            ),
          ],
        ),
      ],
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

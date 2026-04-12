part of 'pokedex_workspace_page.dart';

/// Champ batch du wizard externe.
///
/// Contrairement au mono-espèce :
/// - il ne propose pas d'auto-complétion par suggestion ;
/// - il n'accepte que trois formes batch explicites : liste, plage, génération ;
/// - il montre la liste finale résolue avant tout dry-run.
///
/// Toute la compréhension métier reste hors de ce widget :
/// - le résolveur lot 1 comprend la requête ;
/// - le use case batch la transforme en cibles réelles ;
/// - ce widget se contente d'afficher l'état courant.
class _PokedexExternalBatchSelectionField extends StatelessWidget {
  const _PokedexExternalBatchSelectionField({
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.isResolving,
    required this.selectionResult,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isResolving;
  final PokemonExternalBatchSelectionResult selectionResult;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTextField(
          key: const Key('pokedex-import-external-batch-query-field'),
          controller: controller,
          focusNode: focusNode,
          enabled: !isBusy,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          placeholder: 'Ex. pikachu, eevee, abra · 1-151 · gen 1',
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 10),
        if (isResolving)
          const Row(
            key: Key('pokedex-import-external-batch-selection-loading'),
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: ProgressCircle(),
              ),
              SizedBox(width: 10),
              Text(
                'Résolution de la sélection batch…',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          _PokedexExternalBatchSelectionMessage(
            selectionResult: selectionResult,
          ),
        if (selectionResult.hasTargets) ...[
          const SizedBox(height: 12),
          _PokedexExternalBatchResolvedTargetsList(
            selectionResult: selectionResult,
          ),
        ],
      ],
    );
  }
}

class _PokedexExternalBatchSelectionMessage extends StatelessWidget {
  const _PokedexExternalBatchSelectionMessage({
    required this.selectionResult,
  });

  final PokemonExternalBatchSelectionResult selectionResult;

  @override
  Widget build(BuildContext context) {
    if (selectionResult.kind == PokemonExternalBatchSelectionResultKind.empty) {
      return Text(
        'Saisissez une liste explicite, une plage dex ou une génération. Exemples : `pikachu, eevee, abra`, `1-151`, `gen 1`.',
        key: const Key('pokedex-import-external-batch-idle-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    if (selectionResult.kind ==
        PokemonExternalBatchSelectionResultKind.resolved) {
      final deduplicatedCount =
          selectionResult.requestedInputCount - selectionResult.targets.length;
      final summary = deduplicatedCount > 0
          ? '${selectionResult.targets.length} cibles résolues · $deduplicatedCount doublon(s) éliminé(s).'
          : '${selectionResult.targets.length} cibles résolues et prêtes pour le dry-run.';
      return Text(
        summary,
        key: const Key('pokedex-import-external-batch-resolved-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      );
    }

    final isError = selectionResult.kind ==
            PokemonExternalBatchSelectionResultKind.invalidQuery ||
        selectionResult.kind == PokemonExternalBatchSelectionResultKind.error;
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentWarm;

    return Container(
      key: const Key('pokedex-import-external-batch-selection-message'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        selectionResult.message ?? 'Aucune cible batch exploitable.',
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PokedexExternalBatchResolvedTargetsList extends StatelessWidget {
  const _PokedexExternalBatchResolvedTargetsList({
    required this.selectionResult,
  });

  final PokemonExternalBatchSelectionResult selectionResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pokedex-import-external-batch-resolved-list'),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.35),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: selectionResult.targets.length,
        separatorBuilder: (_, __) => Container(
          height: 1,
          color: EditorChrome.subtleSeparator(context),
        ),
        itemBuilder: (context, index) {
          final target = selectionResult.targets[index];
          final requestedInputs = target.requestedInputs.join(', ');
          return Container(
            key: Key(
              'pokedex-import-external-batch-target-${target.speciesId}',
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${target.nationalDex.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${target.primaryName} · ${target.speciesId}',
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Demandé par : $requestedInputs',
                        style: TextStyle(
                          color: EditorChrome.subtleLabel(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (target.generation != null)
                  Text(
                    'Gen ${target.generation}',
                    style: TextStyle(
                      color: EditorChrome.subtleLabel(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

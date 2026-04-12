part of 'pokedex_workspace_page.dart';

// Sous-sections de l'onglet Learnset.
//
// On extrait le rendu lecture/édition pour garder l'onglet principal léger.
// Cela permet de conserver le même comportement applicatif tout en rendant le
// code UI plus facile à relire, à tester et à faire évoluer.

class _PokedexLearnsetEditSection extends StatelessWidget {
  const _PokedexLearnsetEditSection({
    required this.learnsetRef,
    required this.isSaving,
    required this.saveErrorMessage,
    required this.startingMovesController,
    required this.relearnMovesController,
    required this.levelUpController,
    required this.tmController,
    required this.tutorController,
    required this.eggController,
    required this.eventController,
    required this.transferController,
    required this.onSave,
    required this.onCancel,
  });

  final String learnsetRef;
  final bool isSaving;
  final String? saveErrorMessage;
  final TextEditingController startingMovesController;
  final TextEditingController relearnMovesController;
  final TextEditingController levelUpController;
  final TextEditingController tmController;
  final TextEditingController tutorController;
  final TextEditingController eggController;
  final TextEditingController eventController;
  final TextEditingController transferController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: 'Édition learnset locale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PokedexPropertyLine(
            label: 'Ref learnset',
            value: learnsetRef.isEmpty ? 'Ref absente' : learnsetRef,
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Moves de départ',
            description:
                'Un move id par ligne. Les doublons exacts sont ignorés.',
            fieldKey: const Key('pokedex-learnset-starting-field'),
            controller: startingMovesController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 5,
            placeholder: 'tackle\ngrowl',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Moves à réapprendre',
            description: 'Un move id par ligne.',
            fieldKey: const Key('pokedex-learnset-relearn-field'),
            controller: relearnMovesController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 5,
            placeholder: 'vine_whip',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Level-up',
            description:
                'Une entrée par ligne au format moveId|level|source|versionGroup.',
            fieldKey: const Key('pokedex-learnset-level-up-field'),
            controller: levelUpController,
            enabled: !isSaving,
            minLines: 3,
            maxLines: 8,
            placeholder: 'vine_whip|7|level_up|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'TM',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-tm-field'),
            controller: tmController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'protect|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Tutor',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-tutor-field'),
            controller: tutorController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'seed_bomb|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Egg',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-egg-field'),
            controller: eggController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'petal_dance|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Event',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-event-field'),
            controller: eventController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'celebrate|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Transfer',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-transfer-field'),
            controller: transferController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'toxic|scarlet-violet',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CupertinoButton.filled(
                key: const Key('pokedex-save-learnset-button'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                onPressed: isSaving ? null : onSave,
                child: Text(isSaving ? 'Enregistrement…' : 'Enregistrer'),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                key: const Key('pokedex-cancel-learnset-button'),
                onPressed: isSaving ? null : onCancel,
                child: const Text('Annuler'),
              ),
            ],
          ),
          if (saveErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              saveErrorMessage!,
              key: const Key('pokedex-learnset-save-error'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PokedexLearnsetReadOnlySection extends StatelessWidget {
  const _PokedexLearnsetReadOnlySection({
    required this.learnset,
    required this.learnsetRef,
    required this.onEditRequested,
  });

  final PokemonLearnsetFile? learnset;
  final String learnsetRef;
  final VoidCallback? onEditRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (learnset == null)
          _PokedexMissingSection(
            key: const Key('pokedex-learnset-missing'),
            title: 'Learnset',
            message: learnsetRef.isEmpty
                ? 'La ref learnset est vide dans l’espèce locale ; aucun learnset ne peut être édité depuis cette fiche.'
                : 'Aucun learnset local trouvé pour cette espèce. Vous pouvez en créer un depuis cet onglet.',
          )
        else ...[
          _PokedexDetailSectionCard(
            title: 'Moves de départ',
            child: Text(
              learnset!.startingMoves.isEmpty
                  ? 'Aucun move de départ déclaré.'
                  : learnset!.startingMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Moves à réapprendre',
            child: Text(
              learnset!.relearnMoves.isEmpty
                  ? 'Aucun move à réapprendre déclaré.'
                  : learnset!.relearnMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Level-up',
            child: learnset!.levelUp.isEmpty
                ? const Text('Aucune entrée level-up.')
                : Column(
                    children: learnset!.levelUp
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: '${entry.moveId} • niveau ${entry.level}',
                            value:
                                '${entry.versionGroup} • source ${entry.source}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'TM', entries: learnset!.tm),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Tutor', entries: learnset!.tutor),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Egg', entries: learnset!.egg),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Event', entries: learnset!.event),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Transfer', entries: learnset!.transfer),
        ],
        const SizedBox(height: 12),
        _PokedexDetailSectionCard(
          title: 'Édition locale',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                learnsetRef.isEmpty
                    ? 'Impossible d’éditer ce learnset tant que la ref locale est vide.'
                    : 'Le learnset édité réécrit uniquement le JSON local déjà relié par les refs de l’espèce.',
              ),
              if (onEditRequested != null) ...[
                const SizedBox(height: 14),
                CupertinoButton(
                  key: const Key('pokedex-edit-learnset-button'),
                  padding: EdgeInsets.zero,
                  onPressed: onEditRequested,
                  child:
                      Text(learnset == null ? 'Créer localement' : 'Modifier'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

part of 'trainer_library_panel.dart';

class _TrainerLifecycleEditor extends StatelessWidget {
  const _TrainerLifecycleEditor({
    required this.createMode,
    required this.dialogues,
    required this.templateKind,
    required this.rematchPolicy,
    required this.preBattleDialogueId,
    required this.victoryDialogueId,
    required this.defeatDialogueId,
    required this.onSelectTemplate,
    required this.onSelectRematchPolicy,
    required this.onSelectPreBattleDialogue,
    required this.onSelectVictoryDialogue,
    required this.onSelectDefeatDialogue,
  });

  final bool createMode;
  final List<ProjectDialogueEntry> dialogues;
  final ProjectTrainerTemplateKind? templateKind;
  final ProjectTrainerRematchPolicy? rematchPolicy;
  final String? preBattleDialogueId;
  final String? victoryDialogueId;
  final String? defeatDialogueId;
  final ValueChanged<ProjectTrainerTemplateKind?> onSelectTemplate;
  final ValueChanged<ProjectTrainerRematchPolicy?> onSelectRematchPolicy;
  final ValueChanged<String?> onSelectPreBattleDialogue;
  final ValueChanged<String?> onSelectVictoryDialogue;
  final ValueChanged<String?> onSelectDefeatDialogue;

  String get _keyPrefix => createMode
      ? 'trainer-library-create-lifecycle'
      : 'trainer-library-edit-lifecycle';

  @override
  Widget build(BuildContext context) {
    final sortedDialogues = dialogues.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    final dialogueItems = <PokeMapDropdownItem<String>>[
      const PokeMapDropdownItem<String>(
        value: '',
        label: 'Aucun dialogue',
      ),
      for (final dialogue in sortedDialogues)
        PokeMapDropdownItem<String>(
          value: dialogue.id,
          label: '${dialogue.name} · ${dialogue.id}',
        ),
    ];

    return PokeMapCard(
      key: Key('$_keyPrefix-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Cycle de vie du dresseur',
            description:
                'Choisissez un preset, les dialogues guidés et la politique de réaffrontement.',
          ),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-template-dropdown'),
            label: 'Template auteur',
            value: switch (templateKind) {
              ProjectTrainerTemplateKind.gymLeader => 'gym_leader',
              ProjectTrainerTemplateKind.rival => 'rival',
              null => '',
            },
            items: const <PokeMapDropdownItem<String>>[
              PokeMapDropdownItem<String>(
                value: '',
                label: 'Dresseur générique',
              ),
              PokeMapDropdownItem<String>(
                value: 'gym_leader',
                label: 'Champion d’Arène',
              ),
              PokeMapDropdownItem<String>(
                value: 'rival',
                label: 'Rival / suivi narratif',
              ),
            ],
            onChanged: (value) => onSelectTemplate(
              switch (value) {
                'gym_leader' => ProjectTrainerTemplateKind.gymLeader,
                'rival' => ProjectTrainerTemplateKind.rival,
                _ => null,
              },
            ),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-rematch-dropdown'),
            label: 'Réaffrontement',
            value: rematchPolicy == ProjectTrainerRematchPolicy.allowed
                ? 'allowed'
                : '',
            items: const <PokeMapDropdownItem<String>>[
              PokeMapDropdownItem<String>(
                value: '',
                label: 'Combat unique (par défaut)',
              ),
              PokeMapDropdownItem<String>(
                value: 'allowed',
                label: 'Réaffrontement autorisé',
              ),
            ],
            onChanged: (value) => onSelectRematchPolicy(
              value == 'allowed' ? ProjectTrainerRematchPolicy.allowed : null,
            ),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-pre-battle-dropdown'),
            label: 'Dialogue avant combat',
            value: preBattleDialogueId ?? '',
            items: dialogueItems,
            onChanged: (value) =>
                onSelectPreBattleDialogue(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-victory-dropdown'),
            label: 'Dialogue après victoire du joueur',
            value: victoryDialogueId ?? '',
            items: dialogueItems,
            onChanged: (value) =>
                onSelectVictoryDialogue(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-defeat-dropdown'),
            label: 'Dialogue après défaite du joueur (optionnel)',
            value: defeatDialogueId ?? '',
            items: dialogueItems,
            onChanged: (value) =>
                onSelectDefeatDialogue(value.isEmpty ? null : value),
          ),
          if (dialogues.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Créez d’abord un dialogue dans la bibliothèque pour relier ce cycle de vie.',
            ),
          ],
        ],
      ),
    );
  }
}

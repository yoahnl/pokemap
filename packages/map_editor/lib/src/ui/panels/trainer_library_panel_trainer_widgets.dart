part of 'trainer_library_panel.dart';

// ---------------------------------------------------------------------------
// Widgets trainer
// ---------------------------------------------------------------------------

class _TrainerReferencesBanner extends StatelessWidget {
  const _TrainerReferencesBanner({
    required this.references,
    required this.onRefresh,
  });

  final _TrainerReferenceData references;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final itemState = references.itemsCatalogView.isAvailable
        ? '${references.itemsCatalogView.entries.length} items'
        : 'items indisponibles';
    final moveState = references.movesCatalogView.isAvailable
        ? '${references.movesCatalogView.entries.length} moves'
        : 'moves indisponibles';
    final speciesState = references.isSpeciesAvailable
        ? '${references.speciesEntries.length} espèces'
        : 'espèces indisponibles';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Références Dresseurs · $speciesState · $moveState · $itemState',
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  key: const Key('trainer-library-refresh-references-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(1, 28),
                  onPressed: onRefresh,
                  child: const Text(
                    'Actualiser',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              references.speciesMessage,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.movesCatalogView.isAvailable
                  ? references.movesCatalogView.description
                  : _buildAuthorFacingCatalogUnavailableMessage(
                      subjectLabel: 'des capacités',
                      fallbackMessage:
                          'Les suggestions guidées de capacités restent indisponibles tant que le catalogue local ne peut pas être lu.',
                      technicalMessage: references.movesCatalogView.message,
                    ),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.itemsCatalogView.isAvailable
                  ? references.itemsCatalogView.description
                  : _buildAuthorFacingCatalogUnavailableMessage(
                      subjectLabel: 'des objets',
                      fallbackMessage:
                          'Les ID bruts d’objets restent possibles alors que le catalogue local est indisponible.',
                      technicalMessage: references.itemsCatalogView.message,
                    ),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerOperationBanner extends StatelessWidget {
  const _TrainerOperationBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentJade;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TrainerEditorCard extends StatelessWidget {
  const _TrainerEditorCard({
    super.key,
    required this.title,
    required this.accent,
    required this.nameController,
    required this.classController,
    required this.portraitController,
    required this.battleThemeController,
    required this.victoryThemeController,
    required this.tagsController,
    required this.rewardMoneyController,
    required this.rewardFlagsController,
    required this.rewardItemQuantityController,
    required this.references,
    required this.badges,
    required this.dialogues,
    required this.selectedRewardItemId,
    required this.rewardItemGrants,
    required this.rewardBadgeId,
    required this.rewardFieldAbilityUnlock,
    required this.templateKind,
    required this.rematchPolicy,
    required this.preBattleDialogueId,
    required this.victoryDialogueId,
    required this.defeatDialogueId,
    required this.battleDifficulty,
    required this.battleBackgroundRelativePath,
    required this.projectRootPath,
    required this.characters,
    required this.elements,
    required this.selectedCharacterId,
    required this.validationMessage,
    required this.showAdvanced,
    required this.createMode,
    required this.onToggleAdvanced,
    required this.onBattleDifficultyChanged,
    required this.onClearBattleDifficulty,
    required this.onPickBattleBackground,
    required this.onClearBattleBackground,
    required this.onSelectCharacter,
    required this.onSelectRewardItem,
    required this.onAddRewardItem,
    required this.onRemoveRewardItem,
    required this.onSelectRewardBadge,
    required this.onSelectRewardFieldAbility,
    required this.onSelectTemplate,
    required this.onSelectRematchPolicy,
    required this.onSelectPreBattleDialogue,
    required this.onSelectVictoryDialogue,
    required this.onSelectDefeatDialogue,
    required this.onCancel,
    required this.onSubmit,
  });

  final String title;
  final Color accent;
  final TextEditingController nameController;
  final TextEditingController classController;
  final TextEditingController portraitController;
  final TextEditingController battleThemeController;
  final TextEditingController victoryThemeController;
  final TextEditingController tagsController;
  final TextEditingController rewardMoneyController;
  final TextEditingController rewardFlagsController;
  final TextEditingController rewardItemQuantityController;
  final _TrainerReferenceData references;
  final List<BadgeDefinition> badges;
  final List<ProjectDialogueEntry> dialogues;
  final String? selectedRewardItemId;
  final List<ProjectTrainerItemGrant> rewardItemGrants;
  final String? rewardBadgeId;
  final FieldAbility? rewardFieldAbilityUnlock;
  final ProjectTrainerTemplateKind? templateKind;
  final ProjectTrainerRematchPolicy? rematchPolicy;
  final String? preBattleDialogueId;
  final String? victoryDialogueId;
  final String? defeatDialogueId;
  final int? battleDifficulty;
  final String? battleBackgroundRelativePath;
  final String? projectRootPath;
  final List<ProjectCharacterEntry> characters;
  final List<ProjectElementEntry> elements;
  final String? selectedCharacterId;
  final String? validationMessage;
  final bool showAdvanced;
  final bool createMode;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<double> onBattleDifficultyChanged;
  final VoidCallback onClearBattleDifficulty;
  final VoidCallback onPickBattleBackground;
  final VoidCallback onClearBattleBackground;
  final ValueChanged<String?> onSelectCharacter;
  final ValueChanged<String?> onSelectRewardItem;
  final VoidCallback onAddRewardItem;
  final ValueChanged<String> onRemoveRewardItem;
  final ValueChanged<String?> onSelectRewardBadge;
  final ValueChanged<FieldAbility?> onSelectRewardFieldAbility;
  final ValueChanged<ProjectTrainerTemplateKind?> onSelectTemplate;
  final ValueChanged<ProjectTrainerRematchPolicy?> onSelectRematchPolicy;
  final ValueChanged<String?> onSelectPreBattleDialogue;
  final ValueChanged<String?> onSelectVictoryDialogue;
  final ValueChanged<String?> onSelectDefeatDialogue;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final knownPortraitIds = elements.map((element) => element.id).toSet();
    final portraitId = portraitController.text.trim();
    final portraitIsKnown =
        portraitId.isEmpty || knownPortraitIds.contains(portraitId);
    final displayedBattleDifficulty = (battleDifficulty ?? 4).toDouble();
    final hasExplicitBattleBackground =
        (battleBackgroundRelativePath?.trim().isNotEmpty ?? false);
    final absoluteBattleBackgroundPath =
        !hasExplicitBattleBackground || projectRootPath == null
            ? null
            : p.join(projectRootPath!, battleBackgroundRelativePath!.trim());
    final battleBackgroundFile = absoluteBattleBackgroundPath == null
        ? null
        : File(absoluteBattleBackgroundPath);
    final battleBackgroundExists =
        battleBackgroundFile != null && battleBackgroundFile.existsSync();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InspectorEmbeddedSectionLabel(title),
            const SizedBox(height: 10),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-name-field'
                    : 'trainer-library-edit-name-field',
              ),
              controller: nameController,
              placeholder: 'Nom (ex : Sacha)',
              decoration: BoxDecoration(
                color: EditorChrome.islandFill(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-class-field'
                    : 'trainer-library-edit-class-field',
              ),
              controller: classController,
              placeholder: 'Classe (ex : Dresseur Pokémon)',
              decoration: BoxDecoration(
                color: EditorChrome.islandFill(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 8),
            _TrainerCharacterPicker(
              characters: characters,
              selectedCharacterId: selectedCharacterId,
              onSelected: onSelectCharacter,
            ),
            const SizedBox(height: 12),
            _TrainerLifecycleEditor(
              createMode: createMode,
              dialogues: dialogues,
              templateKind: templateKind,
              rematchPolicy: rematchPolicy,
              preBattleDialogueId: preBattleDialogueId,
              victoryDialogueId: victoryDialogueId,
              defeatDialogueId: defeatDialogueId,
              onSelectTemplate: onSelectTemplate,
              onSelectRematchPolicy: onSelectRematchPolicy,
              onSelectPreBattleDialogue: onSelectPreBattleDialogue,
              onSelectVictoryDialogue: onSelectVictoryDialogue,
              onSelectDefeatDialogue: onSelectDefeatDialogue,
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: EditorChrome.islandFillElevated(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            battleDifficulty == null
                                ? 'Difficulté de combat · valeur par défaut'
                                : 'Difficulté de combat · ${battleDifficulty!}/10',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          key: Key(
                            createMode
                                ? 'trainer-library-create-difficulty-clear-button'
                                : 'trainer-library-edit-difficulty-clear-button',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: const Size(1, 24),
                          onPressed: battleDifficulty == null
                              ? null
                              : onClearBattleDifficulty,
                          child: Text(
                            battleDifficulty == null
                                ? 'Défaut actif'
                                : 'Utiliser le défaut',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    CupertinoSlider(
                      key: Key(
                        createMode
                            ? 'trainer-library-create-difficulty-slider'
                            : 'trainer-library-edit-difficulty-slider',
                      ),
                      value: displayedBattleDifficulty,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: onBattleDifficultyChanged,
                    ),
                    Text(
                      _trainerBattleDifficultyPolicySummary(
                        battleDifficulty,
                      ),
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      battleDifficulty == null
                          ? 'Aucune difficulté explicite n’est enregistrée. Déplacez le curseur pour définir une valeur de 1 à 10.'
                          : 'La difficulté du dresseur est enregistrée dans les données du projet pour le combat.',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _TrainerRewardEditor(
              createMode: createMode,
              moneyController: rewardMoneyController,
              flagsController: rewardFlagsController,
              itemQuantityController: rewardItemQuantityController,
              references: references,
              badges: badges,
              selectedItemId: selectedRewardItemId,
              itemGrants: rewardItemGrants,
              badgeId: rewardBadgeId,
              fieldAbilityUnlock: rewardFieldAbilityUnlock,
              onSelectItem: onSelectRewardItem,
              onAddItem: onAddRewardItem,
              onRemoveItem: onRemoveRewardItem,
              onSelectBadge: onSelectRewardBadge,
              onSelectFieldAbility: onSelectRewardFieldAbility,
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(1, 24),
              alignment: Alignment.centerLeft,
              onPressed: onToggleAdvanced,
              child: Text(
                showAdvanced
                    ? 'Masquer les références optionnelles'
                    : 'Afficher les références optionnelles',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (showAdvanced) ...[
              const SizedBox(height: 8),
              CupertinoTextField(
                key: Key(
                  createMode
                      ? 'trainer-library-create-portrait-field'
                      : 'trainer-library-edit-portrait-field',
                ),
                controller: portraitController,
                placeholder: 'ID d’élément de portrait brut (optionnel)',
                decoration: BoxDecoration(
                  color: EditorChrome.islandFill(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              if (!portraitIsKnown)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'L’ID de l’élément de portrait n’est pas présent dans les éléments du projet.',
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              CupertinoTextField(
                key: Key(
                  createMode
                      ? 'trainer-library-create-battle-theme-field'
                      : 'trainer-library-edit-battle-theme-field',
                ),
                controller: battleThemeController,
                placeholder: 'ID de thème de combat brut (optionnel)',
                decoration: BoxDecoration(
                  color: EditorChrome.islandFill(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 6),
              CupertinoTextField(
                key: Key(
                  createMode
                      ? 'trainer-library-create-victory-theme-field'
                      : 'trainer-library-edit-victory-theme-field',
                ),
                controller: victoryThemeController,
                placeholder: 'ID de thème de victoire brut (optionnel)',
                decoration: BoxDecoration(
                  color: EditorChrome.islandFill(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 6),
              CupertinoTextField(
                key: Key(
                  createMode
                      ? 'trainer-library-create-tags-field'
                      : 'trainer-library-edit-tags-field',
                ),
                controller: tagsController,
                placeholder: 'Tags (séparés par des virgules, optionnel)',
                decoration: BoxDecoration(
                  color: EditorChrome.islandFill(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: EditorChrome.islandFillElevated(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Image de fond de combat (optionnelle)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasExplicitBattleBackground
                            ? battleBackgroundRelativePath!.trim()
                            : 'Aucun fond spécifique sélectionné.',
                        style: TextStyle(
                          color: hasExplicitBattleBackground
                              ? EditorChrome.primaryLabel(context)
                              : subtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          key: Key(
                            createMode
                                ? 'trainer-library-create-background-preview'
                                : 'trainer-library-edit-background-preview',
                          ),
                          height: 88,
                          child: ColoredBox(
                            color: EditorChrome.islandFillElevated(context),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: battleBackgroundExists
                                            ? <Color>[
                                                accent.withValues(alpha: 0.85),
                                                EditorChrome.accentJade
                                                    .withValues(alpha: 0.72),
                                              ]
                                            : <Color>[
                                                EditorChrome.accentCoral
                                                    .withValues(alpha: 0.65),
                                                EditorChrome.accentWarm
                                                    .withValues(alpha: 0.38),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Icon(
                                      battleBackgroundExists
                                          ? CupertinoIcons
                                              .photo_fill_on_rectangle_fill
                                          : CupertinoIcons
                                              .exclamationmark_triangle_fill,
                                      color: CupertinoColors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hasExplicitBattleBackground
                                              ? (battleBackgroundExists
                                                  ? 'Image projet liée'
                                                  : 'Fichier lié manquant')
                                              : 'Aucune image liée',
                                          style: TextStyle(
                                            color: EditorChrome.primaryLabel(
                                              context,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          hasExplicitBattleBackground
                                              ? (battleBackgroundExists
                                                  ? 'Le runtime tentera d’utiliser cette image spécifique avant le fond contextuel.'
                                                  : 'Le runtime ignorera ce fichier manquant et se rabattra sur le fond contextuel.')
                                              : 'Choisissez une image locale du projet pour remplacer le fond de combat contextuel.',
                                          style: TextStyle(
                                            color: subtle,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CupertinoButton(
                            key: Key(
                              createMode
                                  ? 'trainer-library-create-background-pick-button'
                                  : 'trainer-library-edit-background-pick-button',
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(1, 28),
                            onPressed: onPickBattleBackground,
                            child: const Text(
                              'Choisir une image',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 6),
                          CupertinoButton(
                            key: Key(
                              createMode
                                  ? 'trainer-library-create-background-clear-button'
                                  : 'trainer-library-edit-background-clear-button',
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(1, 28),
                            onPressed: onClearBattleBackground,
                            child: const Text(
                              'Effacer',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cette option lie une image locale du projet par chemin relatif. Si le fichier disparaît, le runtime se rabattra sur le fond par défaut.',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ces refs optionnelles restent brutes pour le moment. Le fond de combat trainer reste un simple chemin relatif projet qui override le fond contextuel côté runtime ; battle theme, victory theme et tags restent conservés tels quels.',
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
            if (validationMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                validationMessage!,
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: onCancel,
                  child: const Text('Annuler', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                CupertinoButton.filled(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: onSubmit,
                  child: Text(
                    createMode ? 'Créer' : 'Enregistrer',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Player-facing truth for the three runtime PSDK AI profiles.
///
/// Items are announced as unavailable because RM-021 does not invent a hidden
/// trainer inventory. The battle policy can consume authored options later,
/// but the current Editor intentionally exposes no such control.
String _trainerBattleDifficultyPolicySummary(int? difficulty) {
  if (difficulty == null || difficulty <= 3) {
    return 'Profil basique · choix simples · aucun switch tactique · aucun objet';
  }
  if (difficulty <= 7) {
    return 'Profil tactique · analyse dégâts/types · switch tactique · objets indisponibles';
  }
  return 'Profil avancé · analyse statuts/utilité · switch tactique · objets indisponibles';
}

class _TrainerCharacterPicker extends StatelessWidget {
  const _TrainerCharacterPicker({
    required this.characters,
    required this.selectedCharacterId,
    required this.onSelected,
  });

  final List<ProjectCharacterEntry> characters;
  final String? selectedCharacterId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    ProjectCharacterEntry? selected;
    for (final character in characters) {
      if (character.id == selectedCharacterId) {
        selected = character;
        break;
      }
    }
    final label = selected?.name ?? 'Aucun';

    return Align(
      alignment: Alignment.centerLeft,
      child: PushButton(
        controlSize: ControlSize.regular,
        secondary: true,
        onPressed: () async {
          final picked = await showCupertinoListPicker<ProjectCharacterEntry?>(
            context: context,
            title: 'Personnage du dresseur',
            items: [null, ...characters],
            labelOf: (value) => value?.name ?? 'Aucun',
          );
          onSelected(picked?.id);
        },
        child: Text('Personnage : $label'),
      ),
    );
  }
}

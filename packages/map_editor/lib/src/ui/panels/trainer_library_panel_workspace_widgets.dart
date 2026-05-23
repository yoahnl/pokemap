part of 'trainer_library_panel.dart';

// Trainer Studio lot 8-2 keeps a single source of truth:
// - the sidebar (`embedded: true`) is now only a launcher / summary surface;
// - the central workspace (`embedded: false`) owns the real authoring UI;
// - both views still reuse the same local state, notifier calls and lookup
//   services from `TrainerLibraryPanel`.
extension _TrainerLibraryWorkspaceRendering on _TrainerLibraryPanelState {
  Widget _buildEmbeddedTrainerLibrary({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
  }) {
    final selectedTrainer = _selectedTrainerForWorkspace(project, state);
    final totalTeamPokemon = project.trainers.fold<int>(
      0,
      (sum, trainer) => sum + trainer.team.length,
    );
    final subtle = EditorChrome.subtleLabel(context);

    void openStudio() {
      if (selectedTrainer != null) {
        notifier.selectTrainer(selectedTrainer.id);
      }
      notifier.selectTrainerWorkspace();
    }

    return ListView(
      padding: kInspectorTileBodyPadding,
      children: [
        EditorSidebarListRow(
          key: const Key('trainer-library-studio-entry'),
          selected: state.workspaceMode == EditorWorkspaceMode.trainer,
          onTap: openStudio,
          leading: const MacosIcon(CupertinoIcons.person_3_fill),
          title: const Text('Trainer Studio'),
          subtitle: const Text(
            'Ouvrez le workspace central pour créer des dresseurs et des équipes de combat.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: EditorChrome.accentCoral.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${project.trainers.length} dresseurs • $totalTeamPokemon Pokémon d’équipe',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedTrainer == null
                      ? 'Aucun dresseur sélectionné pour le moment. Ouvrez le Trainer Studio pour créer votre premier dresseur.'
                      : 'Sélection actuelle : ${selectedTrainer.name} • ${selectedTrainer.trainerClass}\n'
                          '${_buildRosterPreview(selectedTrainer, references)}',
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
        const SizedBox(height: 10),
        CupertinoButton.filled(
          key: const Key('trainer-library-open-studio-button'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: openStudio,
          child: const Text('Ouvrir le Trainer Studio'),
        ),
        const SizedBox(height: 8),
        Text(
          'L’édition détaillée se fait désormais dans l’espace central afin que les dresseurs, les fiches d’équipe et les sélecteurs guidés restent visibles ensemble.',
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerStudioWorkspace({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
  }) {
    final visibleTrainer = _selectedTrainerForWorkspace(project, state);
    final workspace = _workspaceForState(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rosterWidth = constraints.maxWidth >= 1440 ? 320.0 : 280.0;
        final editorWidth = constraints.maxWidth >= 1440 ? 430.0 : 390.0;
        // The main shell can shrink the center stage a lot once both side
        // panels are visible. When that happens, keeping the original
        // three-column layout would crush the detail pane down to unusable
        // widths. We keep the same authoring surface, but fold it into a
        // stacked layout so the central workspace stays readable instead of
        // silently overflowing.
        final useCompactLayout =
            constraints.maxWidth < rosterWidth + editorWidth + 360;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TrainerStudioHeaderCard(
                referencesBanner: _TrainerReferencesBanner(
                  references: references,
                  onRefresh: () => _refreshReferenceData(state),
                ),
                operationBanner: (state.errorMessage ?? '').trim().isEmpty &&
                        (state.statusMessage ?? '').trim().isEmpty
                    ? null
                    : _TrainerOperationBanner(
                        message:
                            (state.errorMessage?.trim().isNotEmpty ?? false)
                                ? state.errorMessage!.trim()
                                : state.statusMessage!.trim(),
                        isError:
                            (state.errorMessage?.trim().isNotEmpty ?? false),
                      ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: useCompactLayout
                    ? _buildCompactTrainerStudioBody(
                        context: context,
                        state: state,
                        project: project,
                        notifier: notifier,
                        references: references,
                        visibleTrainer: visibleTrainer,
                        workspace: workspace,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: rosterWidth,
                            child: _buildTrainerRosterPane(
                              context: context,
                              state: state,
                              project: project,
                              references: references,
                              visibleTrainer: visibleTrainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTrainerDetailWorkspacePane(
                              context: context,
                              project: project,
                              notifier: notifier,
                              references: references,
                              visibleTrainer: visibleTrainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: editorWidth,
                            child: _buildTrainerEditorWorkspacePane(
                              context: context,
                              workspace: workspace,
                              visibleTrainer: visibleTrainer,
                              references: references,
                              notifier: notifier,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactTrainerStudioBody({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
    required ProjectWorkspace? workspace,
  }) {
    // This is intentionally a stacked version of the same three surfaces.
    // We do not create a second trainer editor; we only reflow the existing
    // roster/detail/editor panes so the workspace remains usable inside the
    // narrower center shell.
    final detailHeight = _showCreateForm || _editingTrainerId != null
        ? 560.0
        : visibleTrainer == null
            ? 320.0
            : 500.0;
    final editorHeight = _activePokemonTrainerId == visibleTrainer?.id
        ? 760.0
        : visibleTrainer == null
            ? 260.0
            : 320.0;

    return ListView(
      children: [
        SizedBox(
          height: 300,
          child: _buildTrainerRosterPane(
            context: context,
            state: state,
            project: project,
            references: references,
            visibleTrainer: visibleTrainer,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: detailHeight,
          child: _buildTrainerDetailWorkspacePane(
            context: context,
            project: project,
            notifier: notifier,
            references: references,
            visibleTrainer: visibleTrainer,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: editorHeight,
          child: _buildTrainerEditorWorkspacePane(
            context: context,
            workspace: workspace,
            visibleTrainer: visibleTrainer,
            references: references,
            notifier: notifier,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerRosterPane({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    final subtle = EditorChrome.subtleLabel(context);
    return _TrainerStudioPane(
      key: const Key('trainer-library-roster-pane'),
      title: 'Roster de dresseurs',
      subtitle: 'Recherchez, parcourez et sélectionnez le dresseur à éditer.',
      headerAction: CupertinoButton(
        key: const Key('trainer-library-new-trainer-button'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(1, 28),
        onPressed: _openCreateTrainerForm,
        child: const Text('Nouveau dresseur', style: TextStyle(fontSize: 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: EditorChrome.islandFill(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: EditorChrome.accentCoral.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    color: subtle,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoTextField.borderless(
                      key: const Key(
                        'trainer-library-roster-search-field',
                      ),
                      controller: _trainerSearchController,
                      placeholder: 'Rechercher par nom, classe, ID ou tag',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildTrainerRosterList(
              context: context,
              state: state,
              project: project,
              references: references,
              visibleTrainer: visibleTrainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerDetailWorkspacePane({
    required BuildContext context,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    return _TrainerStudioPane(
      key: const Key('trainer-library-detail-pane'),
      title: 'Détail du dresseur',
      subtitle: 'Identité, références optionnelles et équipe de combat.',
      child: _buildTrainerDetailPane(
        context: context,
        project: project,
        notifier: notifier,
        references: references,
        visibleTrainer: visibleTrainer,
      ),
    );
  }

  Widget _buildTrainerEditorWorkspacePane({
    required BuildContext context,
    required ProjectWorkspace? workspace,
    required ProjectTrainerEntry? visibleTrainer,
    required _TrainerReferenceData references,
    required EditorNotifier notifier,
  }) {
    return _TrainerStudioPane(
      key: const Key('trainer-library-editor-pane'),
      title: 'Éditeur Pokémon guidé',
      subtitle:
          'Sélectionnez l’espèce, les capacités, les formes et les objets.',
      child: _buildPokemonEditorPane(
        context: context,
        workspace: workspace,
        visibleTrainer: visibleTrainer,
        references: references,
        notifier: notifier,
      ),
    );
  }

  Widget _buildTrainerRosterList({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    final filtered = project.trainers
        .where(
          (trainer) =>
              _trainerMatchesSearch(trainer, _trainerSearchController.text),
        )
        .toList(growable: false);
    final subtle = EditorChrome.subtleLabel(context);

    if (project.trainers.isEmpty) {
      return Center(
        child: Text(
          'Aucun dresseur pour le moment.\nUtilisez le bouton ci-dessus pour créer votre premier dresseur.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Aucun dresseur ne correspond à cette recherche.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('trainer-library-roster-scroll'),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trainer = filtered[index];
        return _TrainerStudioRosterCard(
          key: Key('trainer-library-roster-row-${trainer.id}'),
          trainer: trainer,
          selected: visibleTrainer?.id == trainer.id,
          preview: _buildRosterPreview(trainer, references),
          onTap: () => _selectTrainerForWorkspace(trainer.id),
        );
      },
    );
  }

  String _buildRosterPreview(
    ProjectTrainerEntry trainer,
    _TrainerReferenceData references,
  ) {
    if (trainer.team.isEmpty) {
      return 'Aucun Pokémon assigné pour le moment';
    }
    final preview = trainer.team.take(3).map((pokemon) {
      final species = _speciesLookupService.findById(
        references.speciesEntries,
        pokemon.speciesId,
      );
      return species?.primaryName ?? pokemon.speciesId;
    }).join(', ');
    final suffix = trainer.team.length > 3 ? '…' : '';
    return '$preview$suffix';
  }

  Widget _buildTrainerDetailPane({
    required BuildContext context,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    if (_showCreateForm) {
      return ListView(
        key: const Key('trainer-library-detail-scroll'),
        children: [
          _TrainerEditorCard(
            key: const Key('trainer-library-create-card'),
            title: 'NEW TRAINER',
            accent: EditorChrome.accentCoral,
            nameController: _newNameController,
            classController: _newClassController,
            portraitController: _newPortraitController,
            battleThemeController: _newBattleThemeController,
            victoryThemeController: _newVictoryThemeController,
            tagsController: _newTagsController,
            battleDifficulty: _newBattleDifficulty,
            battleBackgroundRelativePath: _newBattleBackgroundRelativePath,
            projectRootPath: ref.read(editorNotifierProvider).projectRootPath,
            characters: project.characters,
            elements: project.elements,
            selectedCharacterId: _newCharacterId,
            validationMessage: _createTrainerValidationMessage,
            showAdvanced: _showCreateAdvanced,
            createMode: true,
            onToggleAdvanced: _toggleCreateAdvanced,
            onBattleDifficultyChanged: _setNewBattleDifficulty,
            onClearBattleDifficulty: _clearNewBattleDifficulty,
            onPickBattleBackground: _pickCreateBattleBackground,
            onClearBattleBackground: _clearCreateBattleBackground,
            onSelectCharacter: _setNewCharacterId,
            onCancel: _cancelCreateTrainerDraft,
            onSubmit: () => _handleCreateTrainer(
              notifier: notifier,
              project: project,
            ),
          ),
        ],
      );
    }

    if (visibleTrainer == null) {
      return _TrainerStudioEmptyState(
        title: 'Aucun dresseur sélectionné',
        body:
            'Sélectionnez un dresseur dans le roster ou créez-en un nouveau pour commencer à composer une équipe de combat.',
        actionLabel: 'Créer un dresseur',
        onAction: _openCreateTrainerForm,
      );
    }

    final subtle = EditorChrome.subtleLabel(context);
    final isEditing = _editingTrainerId == visibleTrainer.id;
    final isAddingPokemon =
        _isAddingPokemon && _activePokemonTrainerId == visibleTrainer.id;

    return ListView(
      key: const Key('trainer-library-detail-scroll'),
      children: [
        if (isEditing)
          _TrainerEditorCard(
            key: Key('trainer-library-edit-card-${visibleTrainer.id}'),
            title: 'EDIT TRAINER',
            accent: EditorChrome.accentCoral,
            nameController: _editNameController,
            classController: _editClassController,
            portraitController: _editPortraitController,
            battleThemeController: _editBattleThemeController,
            victoryThemeController: _editVictoryThemeController,
            tagsController: _editTagsController,
            battleDifficulty: _editBattleDifficulty,
            battleBackgroundRelativePath: _editBattleBackgroundRelativePath,
            projectRootPath: ref.read(editorNotifierProvider).projectRootPath,
            characters: project.characters,
            elements: project.elements,
            selectedCharacterId: _editCharacterId,
            validationMessage: _editTrainerValidationMessage,
            showAdvanced: _showEditAdvanced,
            createMode: false,
            onToggleAdvanced: _toggleEditAdvanced,
            onBattleDifficultyChanged: _setEditBattleDifficulty,
            onClearBattleDifficulty: _clearEditBattleDifficulty,
            onPickBattleBackground: _pickEditBattleBackground,
            onClearBattleBackground: _clearEditBattleBackground,
            onSelectCharacter: _setEditCharacterId,
            onCancel: _cancelTrainerEditor,
            onSubmit: () => _handleUpdateTrainer(
              notifier: notifier,
              project: project,
              trainer: visibleTrainer,
            ),
          )
        else
          _TrainerStudioIdentityCard(
            trainer: visibleTrainer,
            onEdit: () => _startEditingTrainer(visibleTrainer),
            onDelete: () => _handleDeleteTrainer(
              notifier: notifier,
              trainer: visibleTrainer,
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'ÉQUIPE (${visibleTrainer.team.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            CupertinoButton(
              key: Key(
                  'trainer-library-add-pokemon-button-${visibleTrainer.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(1, 32),
              onPressed: () {
                if (isAddingPokemon) {
                  _cancelPokemonEditor();
                } else {
                  _startAddingPokemon(visibleTrainer.id);
                }
              },
              child: Text(
                isAddingPokemon ? 'Annuler' : 'Ajouter un Pokémon',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibleTrainer.team.isEmpty)
          Text(
            'Ce dresseur n\'a pas encore d\'équipe. Vous pouvez l\'enregistrer maintenant et ajouter des Pokémon de combat juste après.',
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        for (var i = 0; i < visibleTrainer.team.length; i++) ...[
          _TrainerPokemonSummaryRow(
            key: Key('trainer-library-pokemon-row-${visibleTrainer.id}-$i'),
            pokemon: visibleTrainer.team[i],
            speciesEntry: _speciesLookupService.findById(
              references.speciesEntries,
              visibleTrainer.team[i].speciesId,
            ),
            isSpeciesCatalogAvailable: references.isSpeciesAvailable,
            moveCatalogView: references.movesCatalogView,
            itemCatalogView: references.itemsCatalogView,
            onEdit: () => _startEditingPokemon(
                visibleTrainer.id, i, visibleTrainer.team[i]),
            onDelete: () => _handleDeletePokemon(
              notifier: notifier,
              trainerId: visibleTrainer.id,
              pokemonIndex: i,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildPokemonEditorPane({
    required BuildContext context,
    required ProjectWorkspace? workspace,
    required ProjectTrainerEntry? visibleTrainer,
    required _TrainerReferenceData references,
    required EditorNotifier notifier,
  }) {
    final subtle = EditorChrome.subtleLabel(context);

    if (workspace == null) {
      return Center(
        child: Text(
          'L’enregistrement des dresseurs nécessite un espace de travail projet valide.\nAucun espace n’est disponible actuellement.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (visibleTrainer == null) {
      return Center(
        child: Text(
          'Sélectionnez d’abord un dresseur.\nL’éditeur Pokémon guidé apparaîtra ici.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (_activePokemonTrainerId != visibleTrainer.id) {
      return const _TrainerStudioEmptyState(
        title: 'Aucun Pokémon sélectionné',
        body:
            'Choisissez « Ajouter un Pokémon » ou modifiez une fiche d’équipe pour ouvrir l’éditeur guidé ici.',
      );
    }

    final editorTitle =
        _editingPokemonIndex == null ? 'NOUVEAU POKÉMON D’ÉQUIPE' : 'MODIFIER LE POKÉMON D’ÉQUIPE';

    return ListView(
      key: const Key('trainer-library-editor-scroll'),
      children: [
        Text(
          '${visibleTrainer.name} • $editorTitle',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        _TrainerPokemonEditorCard(
          key: _editingPokemonIndex == null
              ? Key('trainer-library-add-pokemon-card-${visibleTrainer.id}')
              : Key(
                  'trainer-library-edit-pokemon-card-${visibleTrainer.id}-${_editingPokemonIndex!}',
                ),
          trainerId: visibleTrainer.id,
          references: references,
          speciesController: _pokemonSpeciesController,
          levelController: _pokemonLevelController,
          itemController: _pokemonItemController,
          formController: _pokemonFormController,
          genderController: _pokemonGenderController,
          moveControllers: _pokemonMoveControllers,
          shiny: _pokemonShiny,
          validationMessage: _pokemonValidationMessage,
          onToggleShiny: _setPokemonShiny,
          onCancel: _cancelPokemonEditor,
          onSave: () => _handleSavePokemonDraft(
            notifier: notifier,
            workspace: workspace,
            references: references,
          ),
          loadSpeciesDetail: (speciesId) =>
              _loadSpeciesDetailIfPossible(workspace, speciesId),
        ),
      ],
    );
  }
}

class _TrainerStudioHeaderCard extends StatelessWidget {
  const _TrainerStudioHeaderCard({
    required this.referencesBanner,
    required this.operationBanner,
  });

  final Widget referencesBanner;
  final Widget? operationBanner;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentCoral.withValues(alpha: 0.07),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Créez et modifiez les dresseurs du projet dans un espace de travail clair : le roster à gauche, le détail de l'équipe au milieu et l'éditeur Pokémon guidé à droite.",
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            referencesBanner,
            if (operationBanner != null) ...[
              const SizedBox(height: 10),
              operationBanner!,
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainerStudioPane extends StatelessWidget {
  const _TrainerStudioPane({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerAction,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _TrainerStudioRosterCard extends StatelessWidget {
  const _TrainerStudioRosterCard({
    super.key,
    required this.trainer,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final ProjectTrainerEntry trainer;
  final bool selected;
  final String preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.accentCoral.withValues(alpha: 0.1),
              )
            : EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? EditorChrome.accentCoral.withValues(alpha: 0.5)
              : CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        onPressed: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trainer.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _TrainerStudioMiniBadge(
                  label: '${trainer.team.length} mon',
                  selected: selected,
                ),
                if (trainer.battleDifficulty != null) ...[
                  const SizedBox(width: 6),
                  _TrainerStudioMiniBadge(
                    label: 'AI ${trainer.battleDifficulty}',
                    selected: selected,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${trainer.trainerClass} • ${trainer.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

class _TrainerStudioMiniBadge extends StatelessWidget {
  const _TrainerStudioMiniBadge({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? EditorChrome.accentCoral
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrainerStudioIdentityCard extends StatelessWidget {
  const _TrainerStudioIdentityCard({
    required this.trainer,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerEntry trainer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trainer.trainerClass} • ${trainer.id}',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(1, 32),
                  onPressed: onEdit,
                  child: const Text('Modifier'),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(1, 32),
                  onPressed: onDelete,
                  child: const Text(
                    'Supprimer',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                ),
              ],
            ),
            if (trainer.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in trainer.tags) _TrainerMetaChip(label: tag),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              [
                if ((trainer.characterId ?? '').trim().isNotEmpty)
                  'Character: ${trainer.characterId!.trim()}',
                if ((trainer.portraitElementId ?? '').trim().isNotEmpty)
                  'Portrait: ${trainer.portraitElementId!.trim()}',
                if ((trainer.battleThemeId ?? '').trim().isNotEmpty)
                  'Battle theme: ${trainer.battleThemeId!.trim()}',
                if ((trainer.victoryThemeId ?? '').trim().isNotEmpty)
                  'Victory theme: ${trainer.victoryThemeId!.trim()}',
                if (trainer.battleDifficulty != null)
                  'Difficulty: ${trainer.battleDifficulty}/10',
                if ((trainer.battleBackgroundRelativePath ?? '').trim().isNotEmpty)
                  'Background: ${trainer.battleBackgroundRelativePath!.trim()}',
              ].isEmpty
                  ? 'No optional refs configured yet. You can still author a complete battle team right away.'
                  : [
                      if ((trainer.characterId ?? '').trim().isNotEmpty)
                        'Character: ${trainer.characterId!.trim()}',
                      if ((trainer.portraitElementId ?? '').trim().isNotEmpty)
                        'Portrait: ${trainer.portraitElementId!.trim()}',
                      if ((trainer.battleThemeId ?? '').trim().isNotEmpty)
                        'Battle theme: ${trainer.battleThemeId!.trim()}',
                      if ((trainer.victoryThemeId ?? '').trim().isNotEmpty)
                        'Victory theme: ${trainer.victoryThemeId!.trim()}',
                      if (trainer.battleDifficulty != null)
                        'Difficulty: ${trainer.battleDifficulty}/10',
                      if ((trainer.battleBackgroundRelativePath ?? '')
                          .trim()
                          .isNotEmpty)
                        'Background: ${trainer.battleBackgroundRelativePath!.trim()}',
                    ].join('\n'),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerMetaChip extends StatelessWidget {
  const _TrainerMetaChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrainerStudioEmptyState extends StatelessWidget {
  const _TrainerStudioEmptyState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              CupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

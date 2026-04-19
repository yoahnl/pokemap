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
            'Open the main workspace to create trainers, teams and battle rosters.',
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
                  '${project.trainers.length} trainers • $totalTeamPokemon team Pokémon',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedTrainer == null
                      ? 'No trainer selected yet. Open Trainer Studio to create your first roster.'
                      : 'Current focus: ${selectedTrainer.name} • ${selectedTrainer.trainerClass}\n'
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
          child: const Text('Open Trainer Studio'),
        ),
        const SizedBox(height: 8),
        Text(
          'Detailed editing now lives in the center workspace so trainers, team cards and guided selectors all stay visible together.',
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
                onNewTrainer: _openCreateTrainerForm,
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
    return _TrainerStudioPane(
      key: const Key('trainer-library-roster-pane'),
      title: 'Trainer Roster',
      subtitle: 'Search, browse and pick the trainer you want to author.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            key: const Key(
              'trainer-library-roster-search-field',
            ),
            controller: _trainerSearchController,
            placeholder: 'Search by name, class, id or tag',
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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
      title: 'Trainer Detail',
      subtitle: 'Identity, optional refs and the current battle team.',
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
      title: 'Guided Pokémon Editor',
      subtitle:
          'Pick species, moves, forms and items with local search when available.',
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
          'No trainers yet.\nUse the button above to create your first roster.',
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
          'No trainer matches this search.',
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
      return 'No Pokémon assigned yet';
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
        title: 'No trainer selected',
        body:
            'Pick a trainer from the roster or create a new one to start authoring a full battle team.',
        actionLabel: 'Create Trainer',
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
                'TEAM (${visibleTrainer.team.length})',
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
                isAddingPokemon ? 'Cancel' : 'Add Pokémon',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibleTrainer.team.isEmpty)
          Text(
            'This trainer has no team yet. You can save the trainer now and add battle Pokémon right after.',
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
          'Trainer saves need a valid project workspace.\nNo workspace is currently available.',
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
          'Select a trainer first.\nThe guided Pokémon editor will appear here.',
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
        title: 'No Pokémon selected',
        body:
            'Choose “Add Pokémon” or edit one of the trainer team cards to open the guided editor here.',
      );
    }

    final editorTitle =
        _editingPokemonIndex == null ? 'NEW TEAM POKÉMON' : 'EDIT TEAM POKÉMON';

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
    required this.onNewTrainer,
    required this.referencesBanner,
    required this.operationBanner,
  });

  final VoidCallback onNewTrainer;
  final Widget referencesBanner;
  final Widget? operationBanner;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

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
        padding: const EdgeInsets.all(18),
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
                        'Trainer Studio',
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create and edit project trainers in one readable workspace: roster on the left, team detail in the middle, guided Pokémon editing on the right.',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton.filled(
                  key: const Key('trainer-library-new-trainer-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: const Size(1, 34),
                  onPressed: onNewTrainer,
                  child: const Text('New Trainer'),
                ),
              ],
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
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
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
                  child: const Text('Edit'),
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
                    'Delete',
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

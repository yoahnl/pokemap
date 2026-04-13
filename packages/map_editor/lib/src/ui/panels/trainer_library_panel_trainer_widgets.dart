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
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.18),
          width: 1,
        ),
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
                    'Trainer Studio references · $speciesState · $moveState · $itemState',
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
                    'Refresh',
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
                  : references.movesCatalogView.message ??
                      references.movesCatalogView.description,
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
                  : references.itemsCatalogView.message ??
                      references.itemsCatalogView.description,
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
    required this.characters,
    required this.elements,
    required this.selectedCharacterId,
    required this.validationMessage,
    required this.showAdvanced,
    required this.createMode,
    required this.onToggleAdvanced,
    required this.onSelectCharacter,
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
  final List<ProjectCharacterEntry> characters;
  final List<ProjectElementEntry> elements;
  final String? selectedCharacterId;
  final String? validationMessage;
  final bool showAdvanced;
  final bool createMode;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<String?> onSelectCharacter;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final knownPortraitIds = elements.map((element) => element.id).toSet();
    final portraitId = portraitController.text.trim();
    final portraitIsKnown =
        portraitId.isEmpty || knownPortraitIds.contains(portraitId);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorEmbeddedSectionLabel(title),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-name-field'
                  : 'trainer-library-edit-name-field',
            ),
            controller: nameController,
            placeholder: 'Name (e.g. Ash)',
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-class-field'
                  : 'trainer-library-edit-class-field',
            ),
            controller: classController,
            placeholder: 'Class (e.g. Pokémon Trainer)',
          ),
          const SizedBox(height: 6),
          _TrainerCharacterPicker(
            characters: characters,
            selectedCharacterId: selectedCharacterId,
            onSelected: onSelectCharacter,
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(1, 24),
            alignment: Alignment.centerLeft,
            onPressed: onToggleAdvanced,
            child: Text(
              showAdvanced
                  ? 'Hide optional references'
                  : 'Show optional references',
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
              placeholder: 'Raw portrait element ID (optional)',
            ),
            if (!portraitIsKnown)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Portrait element ID is not present in the project elements.',
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
              placeholder: 'Raw battle theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-victory-theme-field'
                    : 'trainer-library-edit-victory-theme-field',
              ),
              controller: victoryThemeController,
              placeholder: 'Raw victory theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-tags-field'
                    : 'trainer-library-edit-tags-field',
              ),
              controller: tagsController,
              placeholder: 'Tags (comma separated, optional)',
            ),
            const SizedBox(height: 6),
            Text(
              'Ces refs optionnelles restent brutes pour le moment. Seul le portrait est vérifié contre les éléments du projet ; battle theme, victory theme et tags sont conservés tels quels.',
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
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 6),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onSubmit,
                child: Text(
                  createMode ? 'Create' : 'Save',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
    final label = selected?.name ?? 'None';

    return Align(
      alignment: Alignment.centerLeft,
      child: PushButton(
        controlSize: ControlSize.regular,
        secondary: true,
        onPressed: () async {
          final picked = await showCupertinoListPicker<ProjectCharacterEntry?>(
            context: context,
            title: 'Trainer Character',
            items: [null, ...characters],
            labelOf: (value) => value?.name ?? 'None',
          );
          onSelected(picked?.id);
        },
        child: Text('Character: $label'),
      ),
    );
  }
}

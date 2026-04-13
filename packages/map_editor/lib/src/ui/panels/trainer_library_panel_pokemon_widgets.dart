part of 'trainer_library_panel.dart';

class _TrainerPokemonSummaryRow extends StatelessWidget {
  const _TrainerPokemonSummaryRow({
    super.key,
    required this.pokemon,
    required this.speciesEntry,
    required this.isSpeciesCatalogAvailable,
    required this.moveCatalogView,
    required this.itemCatalogView,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerPokemonEntry pokemon;
  final PokemonDatabaseIndexEntry? speciesEntry;
  final bool isSpeciesCatalogAvailable;
  final PokemonMovesCatalogView moveCatalogView;
  final PokemonItemsCatalogView itemCatalogView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedMoveLabels = pokemon.moves.map((moveId) {
      if (!moveCatalogView.isAvailable) {
        return moveId;
      }
      final match = _movesLookupService.findById(
        moveCatalogView.entries,
        moveId,
      );
      return match == null ? '$moveId (?)' : match.name;
    }).toList(growable: false);
    final resolvedItemLabel = pokemon.heldItemId == null ||
            pokemon.heldItemId!.trim().isEmpty ||
            !itemCatalogView.isAvailable
        ? pokemon.heldItemId?.trim()
        : _itemsLookupService
                .findById(itemCatalogView.entries, pokemon.heldItemId!.trim())
                ?.name ??
            '${pokemon.heldItemId!.trim()} (?)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
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
                          speciesEntry?.primaryName ?? pokemon.speciesId,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          speciesEntry == null
                              ? '${pokemon.speciesId} • Lv.${pokemon.level}'
                              : '#${speciesEntry!.nationalDex.toString().padLeft(4, '0')} • ${pokemon.speciesId} • ${speciesEntry!.types.join('/')} • Lv.${pokemon.level}',
                          style: TextStyle(
                            fontSize: 11,
                            color: subtle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onEdit,
                    child: const Icon(
                      CupertinoIcons.pencil,
                      size: 14,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onDelete,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 12,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
              ),
              if (speciesEntry == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isSpeciesCatalogAvailable
                        ? 'Species absent from the local Pokédex.'
                        : 'Local species index unavailable. The raw value is kept as-is.',
                    style: const TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (resolvedMoveLabels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final moveLabel in resolvedMoveLabels)
                      _TrainerSummaryChip(
                        label: moveLabel,
                        accent: EditorChrome.accentWarm,
                      ),
                  ],
                ),
              ],
              if (resolvedItemLabel != null &&
                  resolvedItemLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Item: $resolvedItemLabel',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.formId ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Form: ${pokemon.formId!.trim()}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.gender ?? '').trim().isNotEmpty ||
                  pokemon.shiny) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if ((pokemon.gender ?? '').trim().isNotEmpty)
                      'Gender: ${pokemon.gender!.trim()}',
                    if (pokemon.shiny) 'Shiny',
                  ].join(' • '),
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerPokemonEditorCard extends StatefulWidget {
  const _TrainerPokemonEditorCard({
    super.key,
    required this.trainerId,
    required this.references,
    required this.speciesController,
    required this.levelController,
    required this.itemController,
    required this.formController,
    required this.genderController,
    required this.moveControllers,
    required this.shiny,
    required this.validationMessage,
    required this.onToggleShiny,
    required this.onCancel,
    required this.onSave,
    required this.loadSpeciesDetail,
  });

  final String trainerId;
  final _TrainerReferenceData references;
  final TextEditingController speciesController;
  final TextEditingController levelController;
  final TextEditingController itemController;
  final TextEditingController formController;
  final TextEditingController genderController;
  final List<TextEditingController> moveControllers;
  final bool shiny;
  final String? validationMessage;
  final ValueChanged<bool> onToggleShiny;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Future<PokedexSpeciesDetail?> Function(String speciesId)
      loadSpeciesDetail;

  @override
  State<_TrainerPokemonEditorCard> createState() =>
      _TrainerPokemonEditorCardState();
}

class _TrainerPokemonEditorCardState extends State<_TrainerPokemonEditorCard> {
  Future<PokedexSpeciesDetail?>? _speciesDetailFuture;
  String _lastSpeciesId = '';
  bool _showRawFallbacks = false;

  @override
  void initState() {
    super.initState();
    _bindDraftControllers();
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void didUpdateWidget(covariant _TrainerPokemonEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speciesController != widget.speciesController) {
      oldWidget.speciesController.removeListener(_onDraftFieldChanged);
      widget.speciesController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.levelController != widget.levelController) {
      oldWidget.levelController.removeListener(_onDraftFieldChanged);
      widget.levelController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.itemController != widget.itemController) {
      oldWidget.itemController.removeListener(_onDraftFieldChanged);
      widget.itemController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.formController != widget.formController) {
      oldWidget.formController.removeListener(_onDraftFieldChanged);
      widget.formController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.genderController != widget.genderController) {
      oldWidget.genderController.removeListener(_onDraftFieldChanged);
      widget.genderController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.moveControllers != widget.moveControllers) {
      for (final controller in oldWidget.moveControllers) {
        controller.removeListener(_onDraftFieldChanged);
      }
      for (final controller in widget.moveControllers) {
        controller.addListener(_onDraftFieldChanged);
      }
    }
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void dispose() {
    _unbindDraftControllers();
    super.dispose();
  }

  void _bindDraftControllers() {
    widget.speciesController.addListener(_onDraftFieldChanged);
    widget.levelController.addListener(_onDraftFieldChanged);
    widget.itemController.addListener(_onDraftFieldChanged);
    widget.formController.addListener(_onDraftFieldChanged);
    widget.genderController.addListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.addListener(_onDraftFieldChanged);
    }
  }

  void _unbindDraftControllers() {
    widget.speciesController.removeListener(_onDraftFieldChanged);
    widget.levelController.removeListener(_onDraftFieldChanged);
    widget.itemController.removeListener(_onDraftFieldChanged);
    widget.formController.removeListener(_onDraftFieldChanged);
    widget.genderController.removeListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.removeListener(_onDraftFieldChanged);
    }
  }

  void _onDraftFieldChanged() {
    _refreshSpeciesDetailFuture();
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshSpeciesDetailFuture({bool force = false}) {
    final speciesId = widget.speciesController.text.trim();
    if (!force && speciesId == _lastSpeciesId) {
      return;
    }
    _lastSpeciesId = speciesId;
    _speciesDetailFuture = widget.loadSpeciesDetail(speciesId);
  }

  void _toggleRawFallbacks() {
    setState(() {
      _showRawFallbacks = !_showRawFallbacks;
    });
  }

  Widget _buildRawFallbackSection(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentWarm.withValues(alpha: 0.04),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Advanced raw IDs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PushButton(
                  key: const Key(
                    'trainer-library-pokemon-raw-fallback-toggle-button',
                  ),
                  controlSize: ControlSize.small,
                  secondary: _showRawFallbacks,
                  onPressed: _toggleRawFallbacks,
                  child: Text(
                    _showRawFallbacks ? 'Hide raw fields' : 'Show raw fields',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Use these manual IDs only when the guided dropdowns cannot express the exact value you need.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (_showRawFallbacks) ...[
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw species ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-species-field'),
                controller: widget.speciesController,
                placeholder: 'pikachu',
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < widget.moveControllers.length; i++) ...[
                _TrainerInlineField(
                  label: 'Raw move ID ${i + 1} (fallback)',
                  fieldKey: Key('trainer-library-pokemon-move-$i-field'),
                  controller: widget.moveControllers[i],
                  placeholder: 'move id',
                ),
                if (i != widget.moveControllers.length - 1)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw held item ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-item-field'),
                controller: widget.itemController,
                placeholder: 'oran_berry',
              ),
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw form ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-form-field'),
                controller: widget.formController,
                placeholder: 'base / alternate form id',
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final speciesId = widget.speciesController.text.trim();
    final level = int.tryParse(widget.levelController.text.trim());
    final heldItemId = widget.itemController.text.trim();
    final formId = widget.formController.text.trim();
    final resolvedSpecies = widget.references.isSpeciesAvailable
        ? _speciesLookupService.findById(
            widget.references.speciesEntries,
            speciesId,
          )
        : null;
    final speciesCatalogReady = widget.references.isSpeciesAvailable;
    final resolvedItem =
        widget.references.itemsCatalogView.isAvailable && heldItemId.isNotEmpty
            ? _itemsLookupService.findById(
                widget.references.itemsCatalogView.entries,
                heldItemId,
              )
            : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentWarm.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InspectorEmbeddedSectionLabel('TRAINER POKÉMON'),
            const SizedBox(height: 8),
            _TrainerSearchableDropdown<PokemonDatabaseIndexEntry>(
              keyPrefix: 'trainer-library-pokemon-species',
              label: 'Species',
              description: speciesCatalogReady
                  ? 'Search the local Pokédex to choose a Pokémon.'
                  : widget.references.speciesMessage,
              entries: widget.references.speciesEntries,
              lookupService: _speciesLookupService,
              enabled: speciesCatalogReady,
              disabledLabel: 'Local Pokédex unavailable',
              emptySelectionLabel: 'Select a Pokémon species',
              searchPlaceholder: 'Filter local species',
              selectedLabel: resolvedSpecies?.primaryName ?? speciesId,
              selectedSubtitle: resolvedSpecies == null
                  ? (speciesId.isEmpty
                      ? null
                      : speciesCatalogReady
                          ? 'Raw species ID not resolved locally'
                          : 'Raw species ID kept as-is')
                  : [
                      '#${resolvedSpecies.nationalDex.toString().padLeft(4, '0')}',
                      resolvedSpecies.types.join('/'),
                      resolvedSpecies.id,
                    ].join(' • '),
              emptyResultsLabel: 'No local species match this search.',
              subtitleBuilder: (entry) => [
                '#${entry.nationalDex.toString().padLeft(4, '0')}',
                entry.types.join('/'),
                entry.id,
              ].join(' • '),
              onSelected: (entry) {
                // Species selection stays explicit: the draft only changes when
                // the author chooses an item from the dropdown.
                widget.speciesController.text = entry.id;
              },
              onClear: speciesId.isEmpty
                  ? null
                  : () {
                      widget.speciesController.clear();
                    },
            ),
            const SizedBox(height: 6),
            Text(
              speciesId.isEmpty
                  ? 'No species selected yet.'
                  : resolvedSpecies == null
                      ? speciesCatalogReady
                          ? 'Selected species ID not present in the local Pokédex: $speciesId'
                          : 'Local species verification unavailable. Raw species ID is kept as-is: $speciesId'
                      : 'Selected species: ${resolvedSpecies.primaryName} • #${resolvedSpecies.nationalDex.toString().padLeft(4, '0')} • ${resolvedSpecies.id}',
              key: const Key(
                'trainer-library-pokemon-selected-species-status',
              ),
              style: TextStyle(
                color: speciesId.isNotEmpty && resolvedSpecies == null
                    ? EditorChrome.inspectorJoyCoral
                    : subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<PokedexSpeciesDetail?>(
              future: _speciesDetailFuture,
              builder: (context, snapshot) {
                final detail = snapshot.data;
                final guidedMoves = snapshot.connectionState ==
                            ConnectionState.waiting &&
                        speciesId.isNotEmpty
                    ? const _TrainerGuidedMoveSuggestions(
                        description:
                            'Loading the local learnset for this species… Guided move suggestions will appear when the data is ready.',
                        disabledPlaceholder: 'Loading local learnset…',
                      )
                    : _buildTrainerGuidedMoveSuggestions(
                        rawSpeciesId: speciesId,
                        level: level,
                        isSpeciesCatalogAvailable: speciesCatalogReady,
                        resolvedSpecies: resolvedSpecies,
                        speciesDetail: detail,
                        movesCatalogView: widget.references.movesCatalogView,
                      );
                final availableForms = detail == null
                    ? const <String>[]
                    : _buildSpeciesFormSuggestions(detail.species);
                final availableGenders =
                    snapshot.connectionState == ConnectionState.waiting
                        ? _trainerFallbackGenderValues
                        : detail == null
                            ? _trainerFallbackGenderValues
                            : _buildTrainerGenderSuggestions(detail.species);
                final itemStatus = heldItemId.isEmpty
                    ? 'No held item selected.'
                    : resolvedItem == null
                        ? widget.references.itemsCatalogView.isAvailable
                            ? 'The current held item value is not resolved in the local item catalog.'
                            : 'Local item catalog unavailable. The raw value is kept as-is.'
                        : 'Selected item: ${resolvedItem.name} • ${resolvedItem.id}';
                final formStatus = formId.isEmpty
                    ? 'No form override selected.'
                    : availableForms.contains(formId)
                        ? 'Selected form: $formId'
                        : 'Current raw form override: $formId';
                final currentGender = widget.genderController.text.trim();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TrainerLevelSelector(
                            controller: widget.levelController,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TrainerGenderSelector(
                            controller: widget.genderController,
                            speciesId: speciesId,
                            speciesDetail: detail,
                            connectionState: snapshot.connectionState,
                          ),
                        ),
                      ],
                    ),
                    if (currentGender.isNotEmpty &&
                        detail != null &&
                        availableGenders.isNotEmpty &&
                        !availableGenders.contains(currentGender)) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'The current gender override does not match the selected species.',
                        style: TextStyle(
                          color: EditorChrome.inspectorJoyCoral,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Shiny',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        MacosSwitch(
                          value: widget.shiny,
                          onChanged: widget.onToggleShiny,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const InspectorEmbeddedSectionLabel('MOVES'),
                    const SizedBox(height: 8),
                    // Guided move suggestions stay local to this species draft.
                    // We deliberately keep them in the widget layer because
                    // they are a presentational helper over already-loaded
                    // authoring data, not a second trainer domain service.
                    for (var i = 0; i < widget.moveControllers.length; i++) ...[
                      _TrainerMoveSlotEditor(
                        slotIndex: i,
                        controller: widget.moveControllers[i],
                        catalogView: widget.references.movesCatalogView,
                        guidedMoves: guidedMoves,
                        // Every slot should offer a unique move choice. The
                        // raw fallback can still type duplicates manually, but
                        // the guided dropdown keeps the primary path safe and
                        // uncluttered for authors.
                        blockedMoveIds: widget.moveControllers
                            .asMap()
                            .entries
                            .where((entry) => entry.key != i)
                            .map(
                              (entry) => entry.value.text.trim().toLowerCase(),
                            )
                            .where((value) => value.isNotEmpty)
                            .toSet(),
                      ),
                      if (i != widget.moveControllers.length - 1)
                        const SizedBox(height: 10),
                    ],
                    if (guidedMoves.missingCatalogMoveIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Some locally available learnset moves are missing from the local move catalog: ${guidedMoves.missingCatalogMoveIds.join(', ')}.',
                        style: const TextStyle(
                          color: EditorChrome.inspectorJoyCoral,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const InspectorEmbeddedSectionLabel('ITEM / FORM'),
                    const SizedBox(height: 8),
                    _TrainerSearchableDropdown<PokemonItemCatalogEntryView>(
                      keyPrefix: 'trainer-library-pokemon-item',
                      label: 'Held item',
                      description: widget
                              .references.itemsCatalogView.isAvailable
                          ? 'Search the local item catalog to choose a held item.'
                          : _buildAuthorFacingCatalogUnavailableMessage(
                              subjectLabel: 'item data',
                              fallbackMessage:
                                  'You can use the advanced raw item ID if needed.',
                              technicalMessage:
                                  widget.references.itemsCatalogView.message,
                            ),
                      entries: widget.references.itemsCatalogView.entries,
                      lookupService: _itemsLookupService,
                      enabled: widget.references.itemsCatalogView.isAvailable,
                      disabledLabel: 'Local item catalog unavailable',
                      emptySelectionLabel: 'Select a held item',
                      searchPlaceholder: 'Filter local items',
                      selectedLabel: resolvedItem?.name ?? heldItemId,
                      selectedSubtitle: resolvedItem == null
                          ? (heldItemId.isEmpty
                              ? null
                              : widget.references.itemsCatalogView.isAvailable
                                  ? 'Raw item ID not resolved locally'
                                  : 'Raw item ID kept as-is')
                          : resolvedItem.id,
                      emptyResultsLabel: 'No local item matches this search.',
                      subtitleBuilder: (entry) => entry.id,
                      onSelected: (entry) {
                        widget.itemController.text = entry.id;
                      },
                      onClear: heldItemId.isEmpty
                          ? null
                          : () {
                              widget.itemController.clear();
                            },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      itemStatus,
                      style: TextStyle(
                        color: heldItemId.isNotEmpty && resolvedItem == null
                            ? EditorChrome.inspectorJoyCoral
                            : subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting &&
                              speciesId.isNotEmpty
                          ? 'Loading local forms for this species…'
                          : speciesId.isEmpty
                              ? 'Choose a species to check local form suggestions.'
                              : detail == null
                                  ? 'Unable to verify local forms for this species right now. The raw fallback remains available.'
                                  : availableForms.isEmpty
                                      ? 'No local form suggestion is available for this species. The raw fallback remains available.'
                                      : 'Local form suggestions:',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formStatus,
                      style: TextStyle(
                        color: formId.isNotEmpty &&
                                availableForms.isNotEmpty &&
                                !availableForms.contains(formId)
                            ? EditorChrome.inspectorJoyCoral
                            : subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (availableForms.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final formId in availableForms)
                            PushButton(
                              key: Key(
                                'trainer-library-pokemon-form-suggestion-$formId',
                              ),
                              controlSize: ControlSize.small,
                              secondary:
                                  widget.formController.text.trim() != formId,
                              onPressed: () {
                                widget.formController.text = formId;
                              },
                              child: Text(formId),
                            ),
                          PushButton(
                            key: const Key(
                              'trainer-library-pokemon-form-clear-button',
                            ),
                            controlSize: ControlSize.small,
                            secondary:
                                widget.formController.text.trim().isNotEmpty,
                            onPressed: () {
                              widget.formController.clear();
                            },
                            child: const Text('Clear form'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildRawFallbackSection(context),
                  ],
                );
              },
            ),
            if (widget.validationMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.validationMessage!,
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                CupertinoButton.filled(
                  key: const Key('trainer-library-pokemon-save-button'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onSave,
                  child: const Text(
                    'Save Pokémon',
                    style: TextStyle(fontSize: 13),
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

class _TrainerLevelSelector extends StatelessWidget {
  const _TrainerLevelSelector({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final parsedLevel = int.tryParse(controller.text.trim());
    final popupLevels = <int>[
      if (parsedLevel != null && !_trainerLevelValues.contains(parsedLevel))
        parsedLevel,
      ..._trainerLevelValues,
    ];
    final selectedLevel = parsedLevel ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Level',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: SizedBox(
              width: double.infinity,
              child: MacosPopupButton<int>(
                key: const Key('trainer-library-pokemon-level-popup'),
                value: selectedLevel,
                onChanged: (nextLevel) {
                  if (nextLevel != null) {
                    controller.text = nextLevel.toString();
                  }
                },
                items: [
                  for (final level in popupLevels)
                    MacosPopupMenuItem<int>(
                      key: Key('trainer-library-pokemon-level-option-$level'),
                      value: level,
                      child: Text(
                        level >= 1 && level <= 100
                            ? 'Lv.$level'
                            : 'Lv.$level (current value)',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          parsedLevel == null
              ? 'Choose a level between Lv.1 and Lv.100.'
              : parsedLevel >= 1 && parsedLevel <= 100
                  ? 'Trainer Pokémon levels are selected from Lv.1 to Lv.100.'
                  : 'The current saved level is outside Lv.1 to Lv.100. Choose a valid level before saving.',
          style: TextStyle(
            color: parsedLevel != null && (parsedLevel < 1 || parsedLevel > 100)
                ? EditorChrome.inspectorJoyCoral
                : subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _TrainerGenderSelector extends StatelessWidget {
  const _TrainerGenderSelector({
    required this.controller,
    required this.speciesId,
    required this.speciesDetail,
    required this.connectionState,
  });

  final TextEditingController controller;
  final String speciesId;
  final PokedexSpeciesDetail? speciesDetail;
  final ConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final currentGender = controller.text.trim();
    final suggestions = speciesDetail == null
        ? _trainerFallbackGenderValues
        : _buildTrainerGenderSuggestions(speciesDetail!.species);
    final availableOptions =
        suggestions.isEmpty ? _trainerFallbackGenderValues : suggestions;

    final description = connectionState == ConnectionState.waiting &&
            speciesId.isNotEmpty
        ? 'Loading local gender data for this species… Generic options stay available for now.'
        : speciesId.isEmpty
            ? 'Choose a species to tailor the available gender options.'
            : speciesDetail == null
                ? 'Unable to verify local gender data for this species. Generic options stay available.'
                : availableOptions.length == 1 &&
                        availableOptions.single == 'genderless'
                    ? 'This species is genderless in the local Pokédex.'
                    : availableOptions.length == 1
                        ? 'This species only supports ${_trainerGenderLabel(availableOptions.single)}.'
                        : 'Choose one of the locally valid gender options for this species.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final gender in availableOptions)
              PushButton(
                key: Key('trainer-library-pokemon-gender-option-$gender'),
                controlSize: ControlSize.small,
                secondary: currentGender != gender,
                onPressed: () {
                  controller.text = gender;
                },
                child: Text(_trainerGenderLabel(gender)),
              ),
            PushButton(
              key: const Key('trainer-library-pokemon-gender-clear-button'),
              controlSize: ControlSize.small,
              secondary: currentGender.isNotEmpty,
              onPressed: () {
                controller.clear();
              },
              child: const Text('Clear gender'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          currentGender.isEmpty
              ? description
              : 'Selected gender: ${_trainerGenderLabel(currentGender)}',
          style: TextStyle(
            color: currentGender.isNotEmpty &&
                    speciesDetail != null &&
                    availableOptions.isNotEmpty &&
                    !availableOptions.contains(currentGender)
                ? EditorChrome.inspectorJoyCoral
                : subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _TrainerMoveSlotEditor extends StatelessWidget {
  const _TrainerMoveSlotEditor({
    required this.slotIndex,
    required this.controller,
    required this.catalogView,
    required this.guidedMoves,
    required this.blockedMoveIds,
  });

  final int slotIndex;
  final TextEditingController controller;
  final PokemonMovesCatalogView catalogView;
  final _TrainerGuidedMoveSuggestions guidedMoves;
  final Set<String> blockedMoveIds;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final moveId = controller.text.trim();
    final normalizedMoveId = moveId.toLowerCase();
    final resolvedMove = catalogView.isAvailable
        ? _movesLookupService.findById(catalogView.entries, moveId)
        : null;
    final sourceLabels = resolvedMove == null
        ? const <String>[]
        : guidedMoves.sourceLabelsByMoveId[resolvedMove.id] ?? const <String>[];
    final selectableEntries = guidedMoves.entries
        .where(
          (entry) =>
              entry.id.toLowerCase() == normalizedMoveId ||
              !blockedMoveIds.contains(entry.id.toLowerCase()),
        )
        .toList(growable: false);
    final description = guidedMoves.entries.isNotEmpty &&
            selectableEntries.isEmpty &&
            blockedMoveIds.isNotEmpty
        ? 'All guided moves already occupy another slot. Clear or change another move to free a unique choice here.'
        : guidedMoves.description;
    final disabledLabel = guidedMoves.entries.isNotEmpty &&
            selectableEntries.isEmpty &&
            blockedMoveIds.isNotEmpty
        ? 'No unique guided move left'
        : guidedMoves.disabledPlaceholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrainerSearchableDropdown<PokemonMoveCatalogEntryView>(
          keyPrefix: 'trainer-library-pokemon-move-$slotIndex',
          label: 'Move slot ${slotIndex + 1}',
          description: description,
          entries: selectableEntries,
          lookupService: _movesLookupService,
          enabled: selectableEntries.isNotEmpty,
          disabledLabel: disabledLabel,
          emptySelectionLabel: 'Select a move',
          searchPlaceholder: 'Filter available moves',
          selectedLabel: resolvedMove?.name ?? moveId,
          selectedSubtitle: resolvedMove == null
              ? (moveId.isEmpty
                  ? null
                  : catalogView.isAvailable
                      ? 'Raw move ID not resolved locally'
                      : 'Raw move ID kept as-is')
              : [
                  ...sourceLabels,
                  if (resolvedMove.type != null) resolvedMove.type!,
                  if (resolvedMove.category != null) resolvedMove.category!,
                  if (resolvedMove.power != null) 'Power ${resolvedMove.power}',
                  if (resolvedMove.pp != null) 'PP ${resolvedMove.pp}',
                ].join(' • '),
          emptyResultsLabel: 'No guided move matches this search.',
          subtitleBuilder: (entry) => [
            ...?guidedMoves.sourceLabelsByMoveId[entry.id],
            if (entry.type != null) entry.type!,
            if (entry.category != null) entry.category!,
            if (entry.power != null) 'Power ${entry.power}',
            if (entry.pp != null) 'PP ${entry.pp}',
          ].join(' • '),
          onSelected: (entry) {
            controller.text = entry.id;
          },
          onClear: moveId.isEmpty
              ? null
              : () {
                  controller.clear();
                },
        ),
        const SizedBox(height: 4),
        Text(
          moveId.isEmpty
              ? 'Slot empty.'
              : resolvedMove == null
                  ? catalogView.isAvailable
                      ? 'Raw move ID not resolved in the local move catalog.'
                      : 'Move catalog unavailable: the raw value is kept as-is.'
                  : 'Selected move: ${resolvedMove.name} • ${resolvedMove.id}',
          style: TextStyle(
            color: moveId.isNotEmpty && resolvedMove == null
                ? EditorChrome.inspectorJoyCoral
                : subtle,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// This stays strictly local to the trainer studio. It gives the author a real
// searchable selection workflow without introducing a global dropdown system or
// a second source of truth for trainer data elsewhere in the editor.
class _TrainerSearchableDropdown<T> extends StatefulWidget {
  const _TrainerSearchableDropdown({
    required this.keyPrefix,
    required this.label,
    required this.description,
    required this.entries,
    required this.lookupService,
    required this.enabled,
    required this.disabledLabel,
    required this.emptySelectionLabel,
    required this.searchPlaceholder,
    required this.selectedLabel,
    required this.onSelected,
    required this.emptyResultsLabel,
    this.subtitleBuilder,
    this.selectedSubtitle,
    this.onClear,
  });

  final String keyPrefix;
  final String label;
  final String description;
  final List<T> entries;
  final ProgressiveLocalCatalogLookupService<T> lookupService;
  final bool enabled;
  final String disabledLabel;
  final String emptySelectionLabel;
  final String searchPlaceholder;
  final String selectedLabel;
  final String? selectedSubtitle;
  final ValueChanged<T> onSelected;
  final String emptyResultsLabel;
  final String Function(T entry)? subtitleBuilder;
  final VoidCallback? onClear;

  @override
  State<_TrainerSearchableDropdown<T>> createState() =>
      _TrainerSearchableDropdownState<T>();
}

class _TrainerSearchableDropdownState<T>
    extends State<_TrainerSearchableDropdown<T>> {
  late final TextEditingController _searchController;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant _TrainerSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isMenuOpen) {
      // Disabled dropdowns should collapse immediately instead of leaving a
      // stale interactive search panel on screen when prerequisites disappear.
      _closeMenu(clearSearch: true);
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleMenu() {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (!_isMenuOpen) {
        _searchController.clear();
      }
    });
  }

  void _closeMenu({bool clearSearch = false}) {
    if (!_isMenuOpen && (!clearSearch || _searchController.text.isEmpty)) {
      return;
    }
    setState(() {
      _isMenuOpen = false;
      if (clearSearch) {
        _searchController.clear();
      }
    });
  }

  void _selectEntry(T entry) {
    widget.onSelected(entry);
    _closeMenu(clearSearch: true);
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canSearch = widget.enabled && widget.entries.isNotEmpty;
    final suggestions = canSearch
        ? widget.lookupService.search(
            widget.entries,
            _searchController.text,
            limit: 12,
          )
        : List<T>.empty(growable: false);
    final hasSelection = widget.selectedLabel.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: PushButton(
                key: Key('${widget.keyPrefix}-dropdown-button'),
                controlSize: ControlSize.large,
                secondary: !_isMenuOpen,
                onPressed: widget.enabled ? _toggleMenu : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSelection
                                ? widget.selectedLabel
                                : (widget.enabled
                                    ? widget.emptySelectionLabel
                                    : widget.disabledLabel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: widget.enabled
                                  ? null
                                  : CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                            ),
                          ),
                          if ((widget.selectedSubtitle ?? '').trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                widget.selectedSubtitle!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subtle,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isMenuOpen
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 14,
                      color: subtle,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onClear != null) ...[
              const SizedBox(width: 6),
              CupertinoButton(
                key: Key('${widget.keyPrefix}-clear-button'),
                padding: EdgeInsets.zero,
                minimumSize: const Size(1, 24),
                onPressed: widget.onClear,
                child: const Text(
                  'Clear',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        if (_isMenuOpen) ...[
          const SizedBox(height: 8),
          DecoratedBox(
            key: Key('${widget.keyPrefix}-dropdown-menu'),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: EditorChrome.accentWarm.withValues(alpha: 0.22),
                width: 1,
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
                        child: CupertinoTextField(
                          key: Key('${widget.keyPrefix}-search-field'),
                          controller: _searchController,
                          enabled: canSearch,
                          placeholder: widget.searchPlaceholder,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        key: Key('${widget.keyPrefix}-close-button'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(1, 24),
                        onPressed: () => _closeMenu(clearSearch: true),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!canSearch)
                    Text(
                      'No local choices are available right now.',
                      key: Key('${widget.keyPrefix}-search-unavailable'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (suggestions.isEmpty)
                    Text(
                      widget.emptyResultsLabel,
                      key: Key('${widget.keyPrefix}-search-empty'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final entry = suggestions[index];
                          final title = widget.lookupService.labelOf(entry);
                          final id = widget.lookupService.idOf(entry);
                          final subtitle = widget.subtitleBuilder?.call(entry);
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: EditorChrome.largeIslandSurfaceColor(
                                context,
                                tint: EditorChrome.accentWarm
                                    .withValues(alpha: 0.04),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: EditorChrome.accentWarm
                                    .withValues(alpha: 0.18),
                                width: 1,
                              ),
                            ),
                            child: CupertinoButton(
                              key: Key('${widget.keyPrefix}-suggestion-$id'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              onPressed: () => _selectEntry(entry),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle == null ||
                                                  subtitle.trim().isEmpty
                                              ? id
                                              : subtitle,
                                          style: TextStyle(
                                            color: subtle,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (subtitle != null &&
                                            subtitle.trim().isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            id,
                                            style: TextStyle(
                                              color: subtle,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Select',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrainerSummaryChip extends StatelessWidget {
  const _TrainerSummaryChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrainerInlineField extends StatelessWidget {
  const _TrainerInlineField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.placeholder,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: fieldKey,
          controller: controller,
          placeholder: placeholder,
        ),
      ],
    );
  }
}

part of 'encounter_tables_panel.dart';

extension _EncounterTablesPanelEntryWidgets on _EncounterTablesPanelState {
  Widget _buildEntryRow({
    required BuildContext context,
    required ProjectEncounterTable table,
    required ProjectEncounterEntry entry,
    required int entryIndex,
    required _EncounterReferenceData references,
    required bool isEditingThisEntry,
    required Color accent,
    required VoidCallback onToggleEdit,
    required VoidCallback onDelete,
  }) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedSpecies =
        _resolveEncounterSpecies(references, entry.speciesId);
    final chanceLabel = _formatEncounterShare(
      _entryChance(table: table, weight: entry.weight),
    );

    return DecoratedBox(
      key: Key('encounter-tables-entry-row-${table.id}-$entryIndex'),
      decoration: BoxDecoration(
        color: isEditingThisEntry
            ? Color.lerp(
                EditorChrome.islandFillElevated(context),
                accent,
                0.18,
              )!
            : EditorChrome.islandFill(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isEditingThisEntry
              ? accent.withValues(alpha: 0.6)
              : EditorChrome.editorIslandRim(context),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        alignment: Alignment.centerLeft,
        onPressed: onToggleEdit,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedSpecies == null
                        ? '${entry.speciesId} • Lv.${entry.minLevel}-${entry.maxLevel}'
                        : '${resolvedSpecies.primaryName} • ${entry.speciesId} • Lv.${entry.minLevel}-${entry.maxLevel}',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.label.resolveFrom(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Weight ${entry.weight}${chanceLabel == null ? '' : ' • $chanceLabel'}',
                    style: TextStyle(fontSize: 11, color: subtle),
                  ),
                  if (resolvedSpecies == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      references.isSpeciesAvailable
                          ? 'Species not present in the local Pokédex.'
                          : 'Local species verification unavailable. The raw species ID is preserved.',
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            EditorToolbarIconButton(
              onPressed: onDelete,
              icon: CupertinoIcons.trash,
              tooltip: 'Delete entry',
              iconSize: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm(
    BuildContext context,
    EditorNotifier notifier,
    ProjectEncounterTable table,
    _EncounterReferenceData references,
    Color accent,
  ) {
    final isNew = _editingEntryIndex == null;
    final validation = _validateEntryDraft(references: references);
    final speciesStatus = _resolveEncounterSpeciesStatus(
      references: references,
      rawSpeciesId: _entrySpeciesController.text,
    );
    final suggestions = _buildEncounterSpeciesSuggestions(
      references: references,
      rawQuery: _entrySpeciesController.text,
    );
    final previewShare = _draftEncounterChance(table: table);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? 'New Entry' : 'Edit Entry',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              fieldKey: const Key('encounter-tables-entry-species-field'),
              label: 'Species ID',
              placeholder: 'bulbasaur',
              controller: _entrySpeciesController,
              onChanged: (_) => _runLocalStateMutation(() {
                _entryValidationMessage = null;
              }),
              validationMessage: validation.speciesMessage,
            ),
            const SizedBox(height: 4),
            _buildInlineMessage(
              context,
              speciesStatus.message,
              isError: speciesStatus.isError,
            ),
            if (_entrySpeciesController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              if (!references.isSpeciesAvailable)
                _buildInlineMessage(
                  context,
                  'Local species suggestions are unavailable right now.',
                  isError: true,
                  key: const Key(
                    'encounter-tables-entry-species-search-unavailable',
                  ),
                )
              else if (suggestions.isEmpty)
                _buildInlineMessage(
                  context,
                  'No local species suggestion matches this query.',
                  isError: true,
                  key: const Key(
                    'encounter-tables-entry-species-search-empty',
                  ),
                )
              else
                Container(
                  key: const Key(
                    'encounter-tables-entry-species-suggestions',
                  ),
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final entry = suggestions[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: EditorChrome.islandFill(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                            width: 1,
                          ),
                        ),
                        child: CupertinoButton(
                          key: Key(
                            'encounter-tables-entry-species-suggestion-${entry.id}',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          onPressed: () => _selectSuggestedSpecies(entry.id),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.primaryName} • ${entry.id}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.types.join(' / ')}',
                                      style: TextStyle(
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Use',
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
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey:
                        const Key('encounter-tables-entry-min-level-field'),
                    label: 'Min Lv',
                    placeholder: '1',
                    controller: _entryMinLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _runLocalStateMutation(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.minLevelMessage,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey:
                        const Key('encounter-tables-entry-max-level-field'),
                    label: 'Max Lv',
                    placeholder: '5',
                    controller: _entryMaxLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _runLocalStateMutation(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.maxLevelMessage,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey: const Key('encounter-tables-entry-weight-field'),
                    label: 'Weight',
                    placeholder: '1',
                    controller: _entryWeightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _runLocalStateMutation(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.weightMessage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildInlineMessage(
              context,
              previewShare == null
                  ? 'Higher weight means the entry appears more often.'
                  : 'With the current draft, this entry would represent $previewShare of the table.',
              isError: false,
            ),
            if (_entryValidationMessage != null &&
                validation.firstMessage == null) ...[
              const SizedBox(height: 8),
              _buildInlineMessage(
                context,
                _entryValidationMessage!,
                isError: true,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    key: const Key('encounter-tables-entry-save-button'),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    onPressed: validation.firstMessage == null
                        ? () => _saveEntry(notifier, table.id, references)
                        : null,
                    child: Text(isNew ? 'Add' : 'Save'),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  onPressed: () => _runLocalStateMutation(_closeEntryEditor),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

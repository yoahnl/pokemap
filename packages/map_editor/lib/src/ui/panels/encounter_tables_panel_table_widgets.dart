part of 'encounter_tables_panel.dart';

// ---------------------------------------------------------------------------
// Shared panel widgets
// ---------------------------------------------------------------------------
//
// These stay local to the encounter library. The corrective pass intentionally
// stops at presentational extraction: no new public widgets, no new panel
// architecture, and no new encounter-specific controller layer.

Widget _buildReferencesBanner(
  BuildContext context,
  _EncounterReferenceData references, {
  required Color accent,
  required VoidCallback onRefresh,
}) {
  final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
  final isAvailable = references.isSpeciesAvailable;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable
              ? accent.withValues(alpha: 0.25)
              : CupertinoColors.systemYellow.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.search_circle,
              size: 16,
              color: isAvailable
                  ? accent
                  : CupertinoColors.systemYellow.resolveFrom(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assistant d\'espèces local',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    references.speciesMessage,
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
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(1, 22),
              onPressed: onRefresh,
              child: const Icon(
                CupertinoIcons.refresh,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildOperationBanner(
  BuildContext context, {
  required String message,
  required bool isError,
}) {
  final color =
      isError ? EditorChrome.inspectorJoyCoral : EditorChrome.inspectorJoyCyan;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.38)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    ),
  );
}

Widget _buildInlineMessage(
  BuildContext context,
  String message, {
  required bool isError,
  Key? key,
}) {
  final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
  return Text(
    message,
    key: key,
    style: TextStyle(
      color: isError ? EditorChrome.inspectorJoyCoral : subtle,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.35,
    ),
  );
}

Widget _labeledField(
  BuildContext context, {
  Key? fieldKey,
  required String label,
  required TextEditingController controller,
  required String placeholder,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  ValueChanged<String>? onChanged,
  String? validationMessage,
}) {
  final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
      ),
      const SizedBox(height: 4),
      CupertinoTextField(
        key: fieldKey,
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
      ),
      if (validationMessage != null) ...[
        const SizedBox(height: 4),
        _buildInlineMessage(
          context,
          validationMessage,
          isError: true,
        ),
      ],
    ],
  );
}

extension _EncounterTablesPanelTableWidgets on _EncounterTablesPanelState {
  Widget _buildCreateTableForm(
    BuildContext context,
    EditorNotifier notifier,
    Color accent,
  ) {
    final inlineValidation =
        _validateEncounterTableName(_newTableNameController.text);
    final message = _createTableValidationMessage ?? inlineValidation;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.embedded)
                const InspectorEmbeddedSectionLabel('Nouvelle table')
              else
                Text(
                  'Nouvelle table',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              _labeledField(
                context,
                fieldKey: const Key('encounter-tables-create-name-field'),
                label: 'Nom',
                placeholder: 'Grass Patch',
                controller: _newTableNameController,
                onChanged: (_) => _runLocalStateMutation(() {
                  _createTableValidationMessage = null;
                }),
                validationMessage: inlineValidation,
              ),
              const SizedBox(height: 8),
              if (widget.embedded)
                InspectorEmbeddedDropdown(
                  accent: accent,
                  fieldLabel: 'Type',
                  valueLabel: _kindLabel(_newTableKind),
                  orderedIds: EncounterKind.values.map((k) => k.name).toList(),
                  selectedMenuValue: _newTableKind.name,
                  selectedIdForCheck: _newTableKind.name,
                  idToLabel: (id) => _kindLabel(
                    EncounterKind.values.firstWhere((k) => k.name == id),
                  ),
                  onSelected: (id) => _runLocalStateMutation(() {
                    _newTableKind =
                        EncounterKind.values.firstWhere((k) => k.name == id);
                  }),
                  tooltip: 'Type de rencontre',
                )
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () async {
                    final picked = await showCupertinoListPicker<EncounterKind>(
                      context: context,
                      title: 'Type de rencontre',
                      items: EncounterKind.values,
                      labelOf: _kindLabel,
                    );
                    if (picked != null) {
                      _runLocalStateMutation(() => _newTableKind = picked);
                    }
                  },
                  child: Text('Type : ${_kindLabel(_newTableKind)}'),
                ),
              if (message != null && inlineValidation == null) ...[
                const SizedBox(height: 8),
                _buildInlineMessage(
                  context,
                  message,
                  isError: true,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      key: const Key(
                        'encounter-tables-create-submit-button',
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      onPressed: inlineValidation == null
                          ? () => _createTable(notifier)
                          : null,
                      child: const Text('Créer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => _runLocalStateMutation(
                      _resetCreateTableDraft,
                    ),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard({
    required BuildContext context,
    required EditorNotifier notifier,
    required ProjectEncounterTable table,
    required _EncounterReferenceData references,
    required Color accent,
    required Color subtle,
  }) {
    final isEditingThis = _editingTableId == table.id;
    final totalWeight = _tableTotalWeight(table);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEditingThis
                ? accent.withValues(alpha: 0.7)
                : EditorChrome.editorIslandRim(context),
            width: 1,
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoButton(
              key: Key('encounter-tables-table-toggle-${table.id}'),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              alignment: Alignment.centerLeft,
              onPressed: () {
                _runLocalStateMutation(() {
                  if (_editingTableId == table.id) {
                    _closeTableEditor();
                  } else {
                    _editingTableId = table.id;
                    _editTableNameController.text = table.name;
                    _editTableKind = table.encounterKind;
                    _editTableValidationMessage = null;
                    _showCreateForm = false;
                    _closeEntryEditor();
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.list_bullet,
                    size: 15,
                    color: isEditingThis ? accent : subtle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.label.resolveFrom(context),
                            fontWeight: isEditingThis
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_kindLabel(table.encounterKind)} · ${table.entries.length} entrée${table.entries.length == 1 ? '' : 's'} · poids total $totalWeight · ${table.id}',
                          style: TextStyle(fontSize: 11, color: subtle),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isEditingThis
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: subtle,
                  ),
                ],
              ),
            ),
            if (isEditingThis) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: EditorHorizontalDivider(),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: _buildTableEditor(
                  context,
                  notifier,
                  table,
                  references,
                  accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableEditor(
    BuildContext context,
    EditorNotifier notifier,
    ProjectEncounterTable table,
    _EncounterReferenceData references,
    Color accent,
  ) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isEditingEntry = _editingEntryTableId == table.id;
    final inlineValidation =
        _validateEncounterTableName(_editTableNameController.text);
    final totalWeight = _tableTotalWeight(table);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labeledField(
          context,
          fieldKey: Key('encounter-tables-edit-name-field-${table.id}'),
          label: 'Nom',
          placeholder: 'Grass Patch',
          controller: _editTableNameController,
          onChanged: (_) => _runLocalStateMutation(() {
            _editTableValidationMessage = null;
          }),
          validationMessage: inlineValidation,
        ),
        const SizedBox(height: 8),
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: accent,
            fieldLabel: 'Type',
            valueLabel: _kindLabel(_editTableKind),
            orderedIds: EncounterKind.values.map((k) => k.name).toList(),
            selectedMenuValue: _editTableKind.name,
            selectedIdForCheck: _editTableKind.name,
            idToLabel: (id) => _kindLabel(
              EncounterKind.values.firstWhere((k) => k.name == id),
            ),
            onSelected: (id) => _runLocalStateMutation(() {
              _editTableKind =
                  EncounterKind.values.firstWhere((k) => k.name == id);
            }),
            tooltip: 'Type de rencontre',
          )
        else
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<EncounterKind>(
                context: context,
                title: 'Type de rencontre',
                items: EncounterKind.values,
                labelOf: _kindLabel,
              );
              if (picked != null) {
                _runLocalStateMutation(() => _editTableKind = picked);
              }
            },
            child: Text('Type : ${_kindLabel(_editTableKind)}'),
          ),
        if (_editTableValidationMessage != null &&
            inlineValidation == null) ...[
          const SizedBox(height: 8),
          _buildInlineMessage(
            context,
            _editTableValidationMessage!,
            isError: true,
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                key: Key('encounter-tables-save-table-button-${table.id}'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                onPressed: inlineValidation == null
                    ? () => _updateTable(notifier, table.id)
                    : null,
                child: const Text('Enregistrer la table'),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              key: Key('encounter-tables-delete-table-button-${table.id}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: () => _deleteTable(notifier, table.id),
              child: const Text('Supprimer la table'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const EditorHorizontalDivider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Entrées (${table.entries.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subtle,
                ),
              ),
            ),
            Text(
              'Poids total : $totalWeight',
              style: TextStyle(fontSize: 11, color: subtle),
            ),
            const SizedBox(width: 8),
            EditorToolbarIconButton(
              key: Key('encounter-tables-add-entry-button-${table.id}'),
              onPressed: () {
                _runLocalStateMutation(() {
                  _editingEntryTableId = table.id;
                  _editingEntryIndex = null;
                  _entryValidationMessage = null;
                  _entrySpeciesController.clear();
                  _entryMinLevelController.text = '1';
                  _entryMaxLevelController.text = '5';
                  _entryWeightController.text = '1';
                });
              },
              icon: CupertinoIcons.add,
              tooltip: 'Add entry',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Un poids plus élevé augmente la fréquence d’apparition. Les pourcentages ci-dessous sont calculés à partir de la table actuelle.',
          style: TextStyle(fontSize: 11, color: subtle, height: 1.35),
        ),
        if (table.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Aucune entrée pour le moment.',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        else
          ...List.generate(table.entries.length, (index) {
            final entry = table.entries[index];
            final isEditingThisEntry =
                isEditingEntry && _editingEntryIndex == index;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildEntryRow(
                context: context,
                table: table,
                entry: entry,
                entryIndex: index,
                references: references,
                isEditingThisEntry: isEditingThisEntry,
                accent: accent,
                onToggleEdit: () {
                  _runLocalStateMutation(() {
                    if (isEditingThisEntry) {
                      _closeEntryEditor();
                    } else {
                      _editingEntryTableId = table.id;
                      _editingEntryIndex = index;
                      _entryValidationMessage = null;
                      _entrySpeciesController.text = entry.speciesId;
                      _entryMinLevelController.text = entry.minLevel.toString();
                      _entryMaxLevelController.text = entry.maxLevel.toString();
                      _entryWeightController.text = entry.weight.toString();
                    }
                  });
                },
                onDelete: () => _deleteEntry(notifier, table.id, index),
              ),
            );
          }),
        if (isEditingEntry) ...[
          const SizedBox(height: 8),
          _buildEntryForm(
            context,
            notifier,
            table,
            references,
            accent,
          ),
        ],
      ],
    );
  }
}

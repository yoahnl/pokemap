part of 'encounter_tables_panel.dart';

enum _EncounterWorkspacePane { library, table, inspector }

class _EncounterTableDiagnostic {
  const _EncounterTableDiagnostic({
    required this.severity,
    required this.message,
  });

  final PokeMapDiagnosticSeverity severity;
  final String message;
}

extension _EncounterTablesPanelWorkspace on _EncounterTablesPanelState {
  Widget _buildEncounterWorkspace({
    required BuildContext context,
    required EditorState state,
    required EditorNotifier notifier,
    required List<ProjectEncounterTable> tables,
    required _EncounterReferenceData references,
  }) {
    final selectedTable = _resolveSelectedTable(tables);

    return LayoutBuilder(
      builder: (context, constraints) {
        final library = KeyedSubtree(
          key: encounterWorkspaceLibraryKey,
          child: _buildEncounterLibrary(
            context: context,
            notifier: notifier,
            tables: tables,
          ),
        );
        final editor = KeyedSubtree(
          key: encounterWorkspaceTableKey,
          child: _buildEncounterTableConfiguration(
            context: context,
            state: state,
            notifier: notifier,
            table: selectedTable,
            references: references,
          ),
        );
        final inspector = KeyedSubtree(
          key: encounterWorkspaceInspectorKey,
          child: _buildEncounterInspector(
            context: context,
            state: state,
            notifier: notifier,
            table: selectedTable,
            references: references,
          ),
        );

        if (constraints.maxWidth < 1180) {
          final activePane = switch (_compactWorkspacePane) {
            _EncounterWorkspacePane.library => library,
            _EncounterWorkspacePane.table => editor,
            _EncounterWorkspacePane.inspector => inspector,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PokeMapSegmentedTabs(
                  tabs: [
                    PokeMapSegmentedTab(
                      label: 'Bibliothèque',
                      icon: Icons.list_alt_rounded,
                      selected:
                          _compactWorkspacePane ==
                          _EncounterWorkspacePane.library,
                      onTap: () => _selectCompactWorkspacePane(
                        _EncounterWorkspacePane.library,
                      ),
                    ),
                    PokeMapSegmentedTab(
                      label: 'Table',
                      icon: Icons.grass_rounded,
                      selected:
                          _compactWorkspacePane ==
                          _EncounterWorkspacePane.table,
                      onTap: () => _selectCompactWorkspacePane(
                        _EncounterWorkspacePane.table,
                      ),
                    ),
                    PokeMapSegmentedTab(
                      label: 'Inspecteur',
                      icon: Icons.tune_rounded,
                      selected:
                          _compactWorkspacePane ==
                          _EncounterWorkspacePane.inspector,
                      onTap: () => _selectCompactWorkspacePane(
                        _EncounterWorkspacePane.inspector,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: activePane),
            ],
          );
        }

        final libraryWidth = (constraints.maxWidth * 0.22)
            .clamp(260.0, 320.0)
            .toDouble();
        final inspectorWidth = (constraints.maxWidth * 0.238)
            .clamp(300.0, 345.0)
            .toDouble();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: libraryWidth, child: library),
            const SizedBox(width: 12),
            Expanded(child: editor),
            const SizedBox(width: 12),
            SizedBox(width: inspectorWidth, child: inspector),
          ],
        );
      },
    );
  }

  ProjectEncounterTable? _resolveSelectedTable(
    List<ProjectEncounterTable> tables,
  ) {
    if (tables.isEmpty) {
      _editingTableId = null;
      return null;
    }

    ProjectEncounterTable? selected;
    final requestedTableId = _pendingSelectedTableId;
    _pendingSelectedTableId = null;
    for (final table in tables) {
      if (table.id == (requestedTableId ?? _editingTableId)) {
        selected = table;
        break;
      }
    }
    selected ??= tables.first;
    if (_editingTableId != selected.id) {
      _prepareTableDraft(selected);
    }
    return selected;
  }

  void _prepareTableDraft(ProjectEncounterTable table) {
    _editingTableId = table.id;
    _editTableNameController.text = table.name;
    _editTableChancePercentController.text = _formatEncounterChancePercent(
      table.chancePerStep,
    );
    _editTableRequiredFlagsController.text = _requiredEncounterFlagsText(
      table.conditions,
    );
    _editTableTagsController.text = _encounterTagsText(table.tags);
    _editTableKind = table.encounterKind;
    _editTableValidationMessage = null;
  }

  void _selectTable(ProjectEncounterTable table) {
    _runLocalStateMutation(() {
      _prepareTableDraft(table);
      _showCreateForm = false;
      _closeEntryEditor();
      _compactWorkspacePane = _EncounterWorkspacePane.table;
    });
  }

  void _selectCompactWorkspacePane(_EncounterWorkspacePane pane) {
    _runLocalStateMutation(() {
      _compactWorkspacePane = pane;
    });
  }

  void _openCreateTableForm() {
    _runLocalStateMutation(() {
      _showCreateForm = true;
      _createTableValidationMessage = null;
      _closeEntryEditor();
    });
  }

  Widget _buildEncounterLibrary({
    required BuildContext context,
    required EditorNotifier notifier,
    required List<ProjectEncounterTable> tables,
  }) {
    final filteredTables = _filterEncounterTables(tables);
    final hasTables = tables.isNotEmpty;

    return PokeMapPanel(
      borderRadius: 10,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: PokeMapSectionHeader(
          title: 'Tables de rencontres',
          description: 'Regroupées par type de déclenchement',
          trailing: PokeMapBadge(
            label: '${tables.length}',
            variant: PokeMapBadgeVariant.info,
          ),
        ),
      ),
      footer: hasTables && !_showCreateForm
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: PokeMapButton(
                key: const Key('encounter-tables-new-table-button'),
                onPressed: _openCreateTableForm,
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.add_rounded, size: 17),
                child: const Text('Nouvelle table'),
              ),
            )
          : null,
      child: _showCreateForm
          ? _buildCreateTableWorkspaceForm(context, notifier)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProjectBattleTransitionDefaults(context, notifier),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: PokeMapSearchField(
                    key: const Key('encounter-library-search-field'),
                    controller: _tableSearchController,
                    hintText: 'Rechercher une table…',
                    semanticLabel: 'Rechercher une table de rencontres',
                    onChanged: (query) => _runLocalStateMutation(() {
                      _tableSearchQuery = query;
                    }),
                  ),
                ),
                Expanded(
                  child: tables.isEmpty
                      ? PokeMapEmptyState(
                          compact: true,
                          title: 'Aucune table sauvage',
                          description:
                              'Créez votre première table sans renseigner d’ID technique.',
                          icon: const Icon(Icons.grass_rounded),
                          action: PokeMapButton(
                            key: const Key('encounter-tables-new-table-button'),
                            onPressed: _openCreateTableForm,
                            size: PokeMapButtonSize.compact,
                            leading: const Icon(Icons.add_rounded, size: 17),
                            child: const Text('Créer une table'),
                          ),
                        )
                      : filteredTables.isEmpty
                      ? const PokeMapEmptyState(
                          compact: true,
                          title: 'Aucun résultat',
                          description:
                              'Essayez un nom, un identifiant ou un type différent.',
                          icon: Icon(Icons.search_off_rounded),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          children: _buildEncounterLibraryGroups(
                            context,
                            filteredTables,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  List<ProjectEncounterTable> _filterEncounterTables(
    List<ProjectEncounterTable> tables,
  ) {
    final query = _tableSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return tables;
    }
    return tables
        .where((table) {
          return table.name.toLowerCase().contains(query) ||
              table.id.toLowerCase().contains(query) ||
              _kindLabel(table.encounterKind).toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<Widget> _buildEncounterLibraryGroups(
    BuildContext context,
    List<ProjectEncounterTable> tables,
  ) {
    final widgets = <Widget>[];
    for (final kind in EncounterKind.values) {
      final kindTables = tables
          .where((table) => table.encounterKind == kind)
          .toList(growable: false);
      if (kindTables.isEmpty) {
        continue;
      }
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(
        PokeMapSectionHeader(
          title: _kindLabel(kind),
          trailing: PokeMapBadge(
            label: '${kindTables.length}',
            variant: _isRuntimeCertifiedEncounterKind(kind)
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
        ),
      );
      for (final table in kindTables) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _buildEncounterLibraryItem(context, table),
          ),
        );
      }
    }
    return widgets;
  }

  /// Les transitions de combat par défaut du projet — BETA-BAT-034, lot 2.
  ///
  /// `manifest.battleTransitions` existait depuis BETA-BAT-019 et n'avait
  /// aucun producteur : le runtime le lisait, personne ne l'écrivait. Sans
  /// ce réglage, changer la transition de tous les combats demandait de
  /// passer calque par calque et dresseur par dresseur.
  Widget _buildProjectBattleTransitionDefaults(
    BuildContext context,
    EditorNotifier notifier,
  ) {
    final config = ref.watch(editorNotifierProvider).project?.battleTransitions;
    const engineDefault = '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: PokeMapDisclosure(
        key: const Key('encounter-project-battle-transitions'),
        label: 'Transitions de combat par défaut',
        expanded: _showBattleTransitionDefaults,
        onExpandedChanged: (expanded) => _runLocalStateMutation(() {
          _showBattleTransitionDefaults = expanded;
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapDropdownField<String>(
              key: const Key('project-battle-transition-wild'),
              label: 'Rencontres sauvages',
              value: config?.wildTransitionId ?? engineDefault,
              items: [
                const PokeMapDropdownItem(
                  value: engineDefault,
                  label: 'Défaut du moteur (Rouge/Bleu/Jaune)',
                ),
                for (final id in battleWildTransitionIds)
                  PokeMapDropdownItem(
                    value: id,
                    label: battleTransitionDisplayLabels[id] ?? id,
                  ),
              ],
              onChanged: (value) =>
                  notifier.updateProjectBattleTransitionDefaults(
                    wildTransitionId: value,
                  ),
            ),
            const SizedBox(height: 8),
            PokeMapDropdownField<String>(
              key: const Key('project-battle-transition-trainer'),
              label: 'Combats de dresseurs',
              value: config?.trainerTransitionId ?? engineDefault,
              items: [
                const PokeMapDropdownItem(
                  value: engineDefault,
                  label: 'Défaut du moteur (Diamant/Perle/Platine)',
                ),
                for (final id in battleTrainerTransitionIds)
                  PokeMapDropdownItem(
                    value: id,
                    label: battleTransitionDisplayLabels[id] ?? id,
                  ),
              ],
              onChanged: (value) =>
                  notifier.updateProjectBattleTransitionDefaults(
                    trainerTransitionId: value,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncounterLibraryItem(
    BuildContext context,
    ProjectEncounterTable table,
  ) {
    final colors = context.pokeMapColors;
    final selected = _editingTableId == table.id;

    return PokeMapCard(
      key: Key('encounter-tables-table-toggle-${table.id}'),
      selected: selected,
      keyboardInteractive: true,
      semanticLabel: 'Table de rencontres ${table.name}',
      padding: const EdgeInsets.all(10),
      onTap: () => _selectTable(table),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  table.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.brandPrimary,
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${_formatEncounterChancePercent(table.chancePerStep)} % par pas · '
            '${table.entries.length} entrée${table.entries.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapBadge(
              label: _isRuntimeCertifiedEncounterKind(table.encounterKind)
                  ? 'Runtime certifié'
                  : 'Runtime non certifié',
              variant: _isRuntimeCertifiedEncounterKind(table.encounterKind)
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTableWorkspaceForm(
    BuildContext context,
    EditorNotifier notifier,
  ) {
    final nameError = _validateEncounterTableName(_newTableNameController.text);
    final rateError = _validateEncounterChancePercent(
      _newTableChancePercentController.text,
    );
    final canSubmit = nameError == null && rateError == null;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        const PokeMapSectionHeader(
          title: 'Nouvelle table',
          description: 'L’identifiant sera généré automatiquement.',
        ),
        const SizedBox(height: 8),
        PokeMapTextField(
          label: 'Nom de la table',
          fieldKey: const Key('encounter-tables-create-name-field'),
          controller: _newTableNameController,
          hintText: 'Route 1 — Hautes herbes',
          errorText: nameError,
          onChanged: (_) => _runLocalStateMutation(() {
            _createTableValidationMessage = null;
          }),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<EncounterKind>(
          label: 'Type de rencontre',
          value: _newTableKind,
          items: _encounterKindDropdownItems(),
          onChanged: (kind) => _runLocalStateMutation(() {
            _newTableKind = kind;
          }),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Taux par pas (%)',
          fieldKey: const Key('encounter-tables-create-rate-percent-field'),
          controller: _newTableChancePercentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          errorText: rateError,
          onChanged: (_) => _runLocalStateMutation(() {
            _createTableValidationMessage = null;
          }),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Conditions — flags requis',
          fieldKey: const Key('encounter-tables-create-required-flags-field'),
          controller: _newTableRequiredFlagsController,
          hintText: 'route_1_open, chapter_2',
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Tags',
          fieldKey: const Key('encounter-tables-create-tags-field'),
          controller: _newTableTagsController,
          hintText: 'extérieur, commun',
        ),
        if (_createTableValidationMessage != null && canSubmit) ...[
          const SizedBox(height: 10),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _createTableValidationMessage!,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PokeMapButton(
                key: const Key('encounter-tables-create-submit-button'),
                onPressed: canSubmit ? () => _createTable(notifier) : null,
                size: PokeMapButtonSize.compact,
                child: const Text('Créer'),
              ),
            ),
            const SizedBox(width: 8),
            PokeMapButton(
              onPressed: () => _runLocalStateMutation(_resetCreateTableDraft),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.compact,
              child: const Text('Annuler'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEncounterTableConfiguration({
    required BuildContext context,
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectEncounterTable? table,
    required _EncounterReferenceData references,
  }) {
    if (table == null) {
      return const PokeMapPanel(
        expandChild: true,
        child: PokeMapEmptyState(
          title: 'Aucune table sélectionnée',
          description: 'Créez une table dans la bibliothèque pour commencer.',
          icon: Icon(Icons.tune_rounded),
        ),
      );
    }

    final runtimeCertified = _isRuntimeCertifiedEncounterKind(
      table.encounterKind,
    );
    final canSave =
        _validateEncounterTableName(_editTableNameController.text) == null &&
        _validateEncounterChancePercent(
              _editTableChancePercentController.text,
            ) ==
            null;

    return PokeMapPanel(
      borderRadius: 10,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: PokeMapSectionHeader(
          title: table.name,
          description: 'Configuration de la table',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PokeMapBadge(
                label: runtimeCertified
                    ? 'Runtime certifié'
                    : 'Runtime non certifié',
                variant: runtimeCertified
                    ? PokeMapBadgeVariant.success
                    : PokeMapBadgeVariant.warning,
              ),
              const SizedBox(width: 8),
              PokeMapIconButton(
                key: Key('encounter-tables-delete-table-button-${table.id}'),
                onPressed: () => _confirmDeleteEncounterTable(
                  context: context,
                  notifier: notifier,
                  table: table,
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Supprimer la table',
                variant: PokeMapIconButtonVariant.danger,
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: Key('encounter-tables-save-table-button-${table.id}'),
                onPressed: canSave ? () => _updateTable(notifier, table) : null,
                size: PokeMapButtonSize.small,
                leading: const Icon(Icons.save_outlined, size: 16),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if ((state.errorMessage ?? '').trim().isNotEmpty ||
              (state.statusMessage ?? '').trim().isNotEmpty) ...[
            PokeMapDiagnosticCallout(
              severity: (state.errorMessage ?? '').trim().isNotEmpty
                  ? PokeMapDiagnosticSeverity.error
                  : PokeMapDiagnosticSeverity.info,
              message: (state.errorMessage ?? '').trim().isNotEmpty
                  ? state.errorMessage!.trim()
                  : state.statusMessage!.trim(),
            ),
            const SizedBox(height: 10),
          ],
          if (!references.isSpeciesAvailable) ...[
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              title: 'Pokédex local indisponible',
              message: references.speciesMessage,
              actionLabel: 'Réessayer',
              onAction: () => _refreshReferenceData(state),
            ),
            const SizedBox(height: 10),
          ],
          _buildTableConfigurationCard(context, notifier, table),
          const SizedBox(height: 12),
          _buildEncounterRoster(
            context: context,
            table: table,
            references: references,
          ),
        ],
      ),
    );
  }

  Widget _buildTableConfigurationCard(
    BuildContext context,
    EditorNotifier notifier,
    ProjectEncounterTable table,
  ) {
    final nameError = _validateEncounterTableName(
      _editTableNameController.text,
    );
    final rateError = _validateEncounterChancePercent(
      _editTableChancePercentController.text,
    );
    final canSave = nameError == null && rateError == null;

    return PokeMapCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: PokeMapTextField(
                  label: 'Nom',
                  fieldKey: Key('encounter-tables-edit-name-field-${table.id}'),
                  controller: _editTableNameController,
                  errorText: nameError,
                  onChanged: (_) => _runLocalStateMutation(() {
                    _editTableValidationMessage = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: PokeMapDropdownField<EncounterKind>(
                  label: 'Type de rencontre',
                  value: _editTableKind,
                  items: _encounterKindDropdownItems(),
                  onChanged: (kind) => _runLocalStateMutation(() {
                    _editTableKind = kind;
                    _editTableValidationMessage = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 130,
                child: PokeMapTextField(
                  label: 'Taux par pas (%)',
                  fieldKey: Key(
                    'encounter-tables-edit-rate-percent-field-${table.id}',
                  ),
                  controller: _editTableChancePercentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  errorText: rateError,
                  onChanged: (_) => _runLocalStateMutation(() {
                    _editTableValidationMessage = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PokeMapTextField(
                  label: 'Conditions — flags requis',
                  fieldKey: Key(
                    'encounter-tables-edit-required-flags-field-${table.id}',
                  ),
                  controller: _editTableRequiredFlagsController,
                  hintText: 'route_1_open, chapter_2',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PokeMapTextField(
                  label: 'Tags',
                  fieldKey: Key('encounter-tables-edit-tags-field-${table.id}'),
                  controller: _editTableTagsController,
                  hintText: 'extérieur, commun',
                ),
              ),
            ],
          ),
          if (_editTableValidationMessage != null && canSave) ...[
            const SizedBox(height: 10),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              message: _editTableValidationMessage!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEncounterInspector({
    required BuildContext context,
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectEncounterTable? table,
    required _EncounterReferenceData references,
  }) {
    final hasEntryDraft = table != null && _editingEntryTableId == table.id;
    final title = hasEntryDraft
        ? _editingEntryIndex == null
              ? 'Nouvelle entrée'
              : 'Inspecteur de l’entrée'
        : 'Validation globale';

    return PokeMapPanel(
      key: const Key('encounter-entry-inspector'),
      borderRadius: 10,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: PokeMapSectionHeader(
          title: title,
          description: table?.name ?? 'Aucune table sélectionnée',
          trailing: hasEntryDraft
              ? PokeMapIconButton(
                  onPressed: () => _runLocalStateMutation(_closeEntryEditor),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Fermer l’inspecteur',
                )
              : null,
        ),
      ),
      child: table == null
          ? const PokeMapEmptyState(
              compact: true,
              title: 'Aucune validation disponible',
              description: 'Sélectionnez ou créez une table.',
              icon: Icon(Icons.rule_rounded),
            )
          : hasEntryDraft
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildEncounterEntryInspectorForm(
                    context: context,
                    state: state,
                    notifier: notifier,
                    table: table,
                    references: references,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: PokeMapSectionHeader(title: 'Validation globale'),
                ),
                SizedBox(
                  height: 130,
                  child: _buildEncounterGlobalValidation(
                    context: context,
                    table: table,
                    references: references,
                  ),
                ),
              ],
            )
          : _buildEncounterGlobalValidation(
              context: context,
              table: table,
              references: references,
            ),
    );
  }

  Widget _buildEncounterGlobalValidation({
    required BuildContext context,
    required ProjectEncounterTable table,
    required _EncounterReferenceData references,
  }) {
    final colors = context.pokeMapColors;
    final diagnostics = _encounterTableDiagnostics(table, references);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (diagnostics.isEmpty)
          PokeMapCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PokeMapBadge(
                  label: 'Table valide',
                  variant: PokeMapBadgeVariant.success,
                  icon: Icon(Icons.check_rounded),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les espèces, niveaux, poids et probabilités sont cohérents.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else ...[
          PokeMapSectionHeader(
            title:
                '${diagnostics.length} point${diagnostics.length == 1 ? '' : 's'} à vérifier',
            description:
                'Ces contrôles portent sur la table actuellement sélectionnée.',
          ),
          const SizedBox(height: 4),
          for (final diagnostic in diagnostics)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PokeMapDiagnosticCallout(
                severity: diagnostic.severity,
                message: diagnostic.message,
              ),
            ),
        ],
      ],
    );
  }

  List<_EncounterTableDiagnostic> _encounterTableDiagnostics(
    ProjectEncounterTable table,
    _EncounterReferenceData references,
  ) {
    final diagnostics = <_EncounterTableDiagnostic>[];
    if (_validateEncounterTableName(table.name) != null) {
      diagnostics.add(
        const _EncounterTableDiagnostic(
          severity: PokeMapDiagnosticSeverity.error,
          message: 'Le nom de la table est invalide.',
        ),
      );
    }
    if (!table.chancePerStep.isFinite ||
        table.chancePerStep < 0 ||
        table.chancePerStep > 1) {
      diagnostics.add(
        const _EncounterTableDiagnostic(
          severity: PokeMapDiagnosticSeverity.error,
          message: 'Le taux par pas doit rester compris entre 0 % et 100 %.',
        ),
      );
    }
    if (table.entries.isEmpty) {
      diagnostics.add(
        const _EncounterTableDiagnostic(
          severity: PokeMapDiagnosticSeverity.warning,
          message: 'La table ne contient encore aucune espèce.',
        ),
      );
      return diagnostics;
    }
    if (!references.isSpeciesAvailable) {
      diagnostics.add(
        const _EncounterTableDiagnostic(
          severity: PokeMapDiagnosticSeverity.warning,
          message:
              'La validation des espèces est indisponible tant que le Pokédex local ne peut pas être chargé.',
        ),
      );
    }

    final speciesIndexes = <String, List<int>>{};
    var totalWeight = 0;
    for (var index = 0; index < table.entries.length; index++) {
      final entry = table.entries[index];
      final position = index + 1;
      final speciesId = entry.speciesId.trim();
      speciesIndexes
          .putIfAbsent(speciesId.toLowerCase(), () => <int>[])
          .add(position);
      totalWeight += entry.weight;

      if (speciesId.isEmpty ||
          references.isSpeciesAvailable &&
              _resolveEncounterSpecies(references, speciesId) == null) {
        diagnostics.add(
          _EncounterTableDiagnostic(
            severity: PokeMapDiagnosticSeverity.error,
            message:
                'Entrée $position : l’espèce "$speciesId" est absente du Pokédex local.',
          ),
        );
      }
      if (entry.minLevel <= 0 ||
          entry.maxLevel <= 0 ||
          entry.minLevel > entry.maxLevel) {
        diagnostics.add(
          _EncounterTableDiagnostic(
            severity: PokeMapDiagnosticSeverity.error,
            message: 'Entrée $position : la plage de niveaux est invalide.',
          ),
        );
      }
      if (entry.weight <= 0) {
        diagnostics.add(
          _EncounterTableDiagnostic(
            severity: PokeMapDiagnosticSeverity.error,
            message: 'Entrée $position : le poids doit être positif.',
          ),
        );
      }
    }

    for (final duplicate in speciesIndexes.entries) {
      if (duplicate.key.isEmpty || duplicate.value.length < 2) {
        continue;
      }
      diagnostics.add(
        _EncounterTableDiagnostic(
          severity: PokeMapDiagnosticSeverity.warning,
          message:
              'L’espèce "${duplicate.key}" apparaît aux entrées ${duplicate.value.join(', ')}.',
        ),
      );
    }
    if (totalWeight <= 0) {
      diagnostics.add(
        const _EncounterTableDiagnostic(
          severity: PokeMapDiagnosticSeverity.error,
          message:
              'La somme des poids doit être strictement supérieure à zéro.',
        ),
      );
    }
    return diagnostics;
  }

  Widget _buildEncounterEntryInspectorForm({
    required BuildContext context,
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectEncounterTable table,
    required _EncounterReferenceData references,
  }) {
    final colors = context.pokeMapColors;
    final isNew = _editingEntryIndex == null;
    final validation = _validateEntryDraft(references: references);
    final speciesStatus = _resolveEncounterSpeciesStatus(
      references: references,
      rawSpeciesId: _entrySpeciesController.text,
    );
    final species = _resolveEncounterSpecies(
      references,
      _entrySpeciesController.text.trim(),
    );
    final suggestions = _buildEncounterSpeciesSuggestions(
      references: references,
      rawQuery: _entrySpeciesController.text,
    );
    final draftProbability = _draftEntryProbability(table);
    final duplicateMessage = _duplicateDraftSpeciesMessage(table);
    final persistenceError = (state.errorMessage ?? '').trim();
    final thumbnailPath = _encounterSpeciesThumbnailPath(species);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            PokeMapAssetThumbnail(
              key: const Key('encounter-entry-species-thumbnail'),
              semanticLabel:
                  'Aperçu de ${species?.primaryName ?? 'l’espèce sélectionnée'}',
              imageFilePath: thumbnailPath,
              imageScale: _encounterSpeciesThumbnailScale(species),
              size: 54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species?.primaryName ??
                        (isNew ? 'Choisir une espèce' : 'Espèce inconnue'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (species != null) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final type in species.types.take(2))
                          PokeMapBadge(
                            label: _encounterTypeLabel(type),
                            variant: PokeMapBadgeVariant.neutral,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          key: const Key('encounter-entry-species-control'),
          label: 'Espèce du Pokédex',
          fieldKey: const Key('encounter-tables-entry-species-field'),
          controller: _entrySpeciesController,
          hintText: 'Rechercher par nom ou identifiant',
          errorText: validation.speciesMessage,
          onChanged: (_) => _runLocalStateMutation(() {
            _entryValidationMessage = null;
          }),
        ),
        const SizedBox(height: 6),
        PokeMapDiagnosticCallout(
          severity: speciesStatus.isError
              ? PokeMapDiagnosticSeverity.warning
              : PokeMapDiagnosticSeverity.info,
          message: speciesStatus.message,
        ),
        if (_entrySpeciesController.text.trim().isNotEmpty &&
            (species == null ||
                species.id.toLowerCase() !=
                    _entrySpeciesController.text.trim().toLowerCase())) ...[
          const SizedBox(height: 8),
          if (!references.isSpeciesAvailable)
            const PokeMapDiagnosticCallout(
              key: Key('encounter-tables-entry-species-search-unavailable'),
              severity: PokeMapDiagnosticSeverity.warning,
              message:
                  "Les suggestions locales d'espèces sont indisponibles pour le moment.",
            )
          else if (suggestions.isEmpty)
            const PokeMapDiagnosticCallout(
              key: Key('encounter-tables-entry-species-search-empty'),
              severity: PokeMapDiagnosticSeverity.warning,
              message: 'Aucune espèce locale ne correspond à cette recherche.',
            )
          else
            for (final suggestion in suggestions.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PokeMapCard(
                  key: Key(
                    'encounter-tables-entry-species-suggestion-${suggestion.id}',
                  ),
                  keyboardInteractive: true,
                  semanticLabel:
                      'Choisir ${suggestion.primaryName}, ${suggestion.id}',
                  padding: const EdgeInsets.all(9),
                  onTap: () => _selectSuggestedSpecies(suggestion.id),
                  child: Row(
                    children: [
                      PokeMapAssetThumbnail(
                        key: Key(
                          'encounter-species-suggestion-thumbnail-${suggestion.id}',
                        ),
                        semanticLabel: 'Aperçu de ${suggestion.primaryName}',
                        imageFilePath: _encounterSpeciesThumbnailPath(
                          suggestion,
                        ),
                        imageScale: _encounterSpeciesThumbnailScale(suggestion),
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.primaryName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        suggestion.id,
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
        ],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PokeMapTextField(
                key: const Key('encounter-entry-min-level-control'),
                label: 'Niveau min',
                fieldKey: const Key('encounter-tables-entry-min-level-field'),
                controller: _entryMinLevelController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                errorText: validation.minLevelMessage,
                onChanged: (_) => _runLocalStateMutation(() {
                  _entryValidationMessage = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PokeMapTextField(
                key: const Key('encounter-entry-max-level-control'),
                label: 'Niveau max',
                fieldKey: const Key('encounter-tables-entry-max-level-field'),
                controller: _entryMaxLevelController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                errorText: validation.maxLevelMessage,
                onChanged: (_) => _runLocalStateMutation(() {
                  _entryValidationMessage = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          key: const Key('encounter-entry-weight-control'),
          label: 'Poids relatif',
          fieldKey: const Key('encounter-tables-entry-weight-field'),
          controller: _entryWeightController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          errorText: validation.weightMessage,
          onChanged: (_) => _runLocalStateMutation(() {
            _entryValidationMessage = null;
          }),
        ),
        const SizedBox(height: 14),
        const PokeMapSectionHeader(
          title: 'Génération du Pokémon',
          description: 'Laissez Aléatoire pour suivre le profil du projet.',
        ),
        const SizedBox(height: 8),
        PokeMapDropdownField<String>(
          key: const Key('encounter-entry-nature-control'),
          label: 'Nature',
          value: _entryNatureId,
          items: <PokeMapDropdownItem<String>>[
            const PokeMapDropdownItem<String>(value: '', label: 'Aléatoire'),
            for (final natureId in canonicalPokemonNatureIds)
              PokeMapDropdownItem<String>(
                value: natureId,
                label: '${natureId[0].toUpperCase()}${natureId.substring(1)}',
              ),
          ],
          onChanged: (natureId) => _runLocalStateMutation(() {
            _entryNatureId = natureId;
            _entryValidationMessage = null;
          }),
        ),
        const SizedBox(height: 8),
        PokeMapDropdownField<ProjectEncounterShinyPolicy>(
          key: const Key('encounter-entry-shiny-policy-control'),
          label: 'Pokémon chromatique',
          value: _entryShinyPolicy,
          items: const <PokeMapDropdownItem<ProjectEncounterShinyPolicy>>[
            PokeMapDropdownItem<ProjectEncounterShinyPolicy>(
              value: ProjectEncounterShinyPolicy.random,
              label: 'Aléatoire',
            ),
            PokeMapDropdownItem<ProjectEncounterShinyPolicy>(
              value: ProjectEncounterShinyPolicy.never,
              label: 'Jamais',
            ),
            PokeMapDropdownItem<ProjectEncounterShinyPolicy>(
              value: ProjectEncounterShinyPolicy.always,
              label: 'Toujours',
            ),
          ],
          onChanged: (policy) => _runLocalStateMutation(() {
            _entryShinyPolicy = policy;
            _entryValidationMessage = null;
          }),
        ),
        if (draftProbability != null) ...[
          const SizedBox(height: 10),
          PokeMapCard(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PokeMapProgressBar(
                  value: draftProbability.relativeShare ?? 0,
                  semanticLabel: 'Part relative prévisionnelle',
                  tone: PokeMapTone.map,
                ),
                const SizedBox(height: 7),
                Text(
                  '${_formatEncounterProbability(draftProbability.relativeShare!)} du roster',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatEncounterProbability(draftProbability.resolvedChancePerStep!)} par pas',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (duplicateMessage != null) ...[
          const SizedBox(height: 10),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            message: duplicateMessage,
          ),
        ],
        if (_entryValidationMessage != null &&
            (validation.firstMessage == null || _entryDeleteFailed)) ...[
          const SizedBox(height: 10),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _entryValidationMessage!,
            actionLabel: persistenceError.isEmpty || _entryDeleteFailed
                ? null
                : 'Réessayer',
            onAction: persistenceError.isEmpty || _entryDeleteFailed
                ? null
                : () => _saveEntry(notifier, table.id, references),
          ),
        ],
        const SizedBox(height: 12),
        if (!isNew) ...[
          PokeMapButton(
            key: const Key('encounter-entry-delete-button'),
            onPressed: () => _confirmDeleteEncounterEntry(
              context: context,
              notifier: notifier,
              table: table,
              entryIndex: _editingEntryIndex!,
              speciesName:
                  species?.primaryName ?? _entrySpeciesController.text.trim(),
            ),
            variant: PokeMapButtonVariant.danger,
            size: PokeMapButtonSize.compact,
            leading: const Icon(Icons.delete_outline_rounded, size: 17),
            child: const Text('Supprimer l’entrée'),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: PokeMapButton(
                onPressed: () => _runLocalStateMutation(_closeEntryEditor),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.compact,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PokeMapButton(
                key: const Key('encounter-tables-entry-save-button'),
                onPressed: validation.firstMessage == null
                    ? () => _saveEntry(notifier, table.id, references)
                    : null,
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.save_outlined, size: 17),
                child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  EncounterEntryProbability? _draftEntryProbability(
    ProjectEncounterTable table,
  ) {
    final weight = int.tryParse(_entryWeightController.text.trim());
    if (weight == null || weight <= 0) {
      return null;
    }
    final weights = table.entries.map((entry) => entry.weight).toList();
    final index = _editingEntryIndex;
    if (index == null) {
      weights.add(weight);
    } else {
      weights[index] = weight;
    }
    final projection = projectEncounterProbabilities(
      chancePerStep: table.chancePerStep,
      weights: weights,
    );
    if (!projection.isValid) {
      return null;
    }
    return projection.entries[index ?? projection.entries.length - 1];
  }

  String? _duplicateDraftSpeciesMessage(ProjectEncounterTable table) {
    final speciesId = _entrySpeciesController.text.trim().toLowerCase();
    if (speciesId.isEmpty) {
      return null;
    }
    for (var index = 0; index < table.entries.length; index++) {
      if (index == _editingEntryIndex) {
        continue;
      }
      if (table.entries[index].speciesId.trim().toLowerCase() == speciesId) {
        return 'Cette espèce existe déjà dans la table à l’entrée ${index + 1}.';
      }
    }
    return null;
  }

  Future<void> _confirmDeleteEncounterEntry({
    required BuildContext context,
    required EditorNotifier notifier,
    required ProjectEncounterTable table,
    required int entryIndex,
    required String speciesName,
  }) async {
    final confirmed = await showPokeMapConfirmationDialog<bool>(
      context: context,
      title: 'Supprimer cette entrée ?',
      message:
          '$speciesName sera retiré de la table « ${table.name} ». Cette action sera persistée immédiatement.',
      actions: const [
        PokeMapDialogAction<bool>(label: 'Annuler', value: false),
        PokeMapDialogAction<bool>(
          label: 'Supprimer',
          value: true,
          variant: PokeMapButtonVariant.danger,
        ),
      ],
    );
    if (confirmed == true && mounted) {
      await _deleteEntry(notifier, table.id, entryIndex);
    }
  }

  Future<void> _confirmDeleteEncounterTable({
    required BuildContext context,
    required EditorNotifier notifier,
    required ProjectEncounterTable table,
  }) async {
    final confirmed = await showPokeMapConfirmationDialog<bool>(
      context: context,
      title: 'Supprimer cette table ?',
      message:
          'La table « ${table.name} » et ses ${table.entries.length} entrées seront supprimées du projet.',
      actions: const [
        PokeMapDialogAction<bool>(label: 'Annuler', value: false),
        PokeMapDialogAction<bool>(
          label: 'Supprimer la table',
          value: true,
          variant: PokeMapButtonVariant.danger,
        ),
      ],
    );
    if (confirmed == true && mounted) {
      await _deleteTable(notifier, table.id);
    }
  }

  Widget _buildEncounterRoster({
    required BuildContext context,
    required ProjectEncounterTable table,
    required _EncounterReferenceData references,
  }) {
    final isEditingEntry = _editingEntryTableId == table.id;
    final projection = projectEncounterProbabilities(
      chancePerStep: table.chancePerStep,
      weights: table.entries.map((entry) => entry.weight),
    );

    return PokeMapCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Roster sauvage',
            description:
                '${table.entries.length} entrée${table.entries.length == 1 ? '' : 's'} · poids total ${_tableTotalWeight(table)}',
            trailing: PokeMapIconButton(
              key: Key('encounter-tables-add-entry-button-${table.id}'),
              onPressed: () => _startNewEncounterEntry(table.id),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Ajouter une entrée',
              variant: PokeMapIconButtonVariant.soft,
            ),
          ),
          if (table.entries.isEmpty)
            const PokeMapEmptyState(
              compact: true,
              title: 'Aucune espèce dans cette table',
              description: 'Ajoutez une espèce pour composer le roster.',
              icon: Icon(Icons.catching_pokemon_rounded),
            )
          else ...[
            if (!projection.isValid) ...[
              const SizedBox(height: 8),
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.error,
                title: 'Projection de probabilité impossible',
                message:
                    'Chaque poids doit être strictement positif et leur somme doit être supérieure à zéro.',
              ),
            ],
            for (var index = 0; index < table.entries.length; index++)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: _buildEncounterRosterRow(
                  context: context,
                  table: table,
                  entry: table.entries[index],
                  entryIndex: index,
                  references: references,
                  probability: projection.entries[index],
                  selected: isEditingEntry && _editingEntryIndex == index,
                  onTap: () => _toggleEncounterEntryEditor(table, index),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEncounterRosterRow({
    required BuildContext context,
    required ProjectEncounterTable table,
    required ProjectEncounterEntry entry,
    required int entryIndex,
    required _EncounterReferenceData references,
    required EncounterEntryProbability probability,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.pokeMapColors;
    final species = _resolveEncounterSpecies(references, entry.speciesId);
    final speciesName = species?.primaryName ?? entry.speciesId;
    final thumbnailPath = _encounterSpeciesThumbnailPath(species);
    final relativeShare = probability.relativeShare;
    final resolvedChance = probability.resolvedChancePerStep;

    return PokeMapCard(
      key: Key('encounter-roster-entry-${table.id}-$entryIndex'),
      selected: selected,
      keyboardInteractive: true,
      semanticLabel:
          'Entrée $speciesName, niveaux ${entry.minLevel} à ${entry.maxLevel}',
      onTap: onTap,
      padding: const EdgeInsets.all(5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PokeMapAssetThumbnail(
            key: Key('encounter-roster-sprite-${table.id}-$entryIndex'),
            semanticLabel: 'Aperçu de $speciesName',
            imageFilePath: thumbnailPath,
            imageScale: _encounterSpeciesThumbnailScale(species),
            size: 36,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        speciesName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (species != null)
                      for (final type in species.types.take(2)) ...[
                        const SizedBox(width: 5),
                        PokeMapBadge(
                          label: _encounterTypeLabel(type),
                          variant: PokeMapBadgeVariant.neutral,
                        ),
                      ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.speciesId} · Lv. ${entry.minLevel}–${entry.maxLevel} · Poids ${entry.weight}',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (species == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    references.isSpeciesAvailable
                        ? 'Espèce non présente dans le Pokédex local.'
                        : 'Vérification d’espèce locale indisponible. L’ID brut d’espèce est conservé.',
                    style: TextStyle(
                      color: references.isSpeciesAvailable
                          ? colors.error
                          : colors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  relativeShare == null
                      ? 'Part indisponible'
                      : '${_formatEncounterProbability(relativeShare)} du roster',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: relativeShare == null
                        ? colors.error
                        : colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  resolvedChance == null
                      ? 'Chance par pas indisponible'
                      : '${_formatEncounterProbability(resolvedChance)} par pas',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: resolvedChance == null
                        ? colors.error
                        : colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (relativeShare != null) ...[
                  const SizedBox(height: 5),
                  PokeMapProgressBar(
                    value: relativeShare,
                    semanticLabel: 'Part relative de $speciesName',
                    height: 4,
                    tone: PokeMapTone.map,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEncounterProbability(double probability) {
    return '${(probability * 100).toStringAsFixed(1)}%';
  }

  String? _encounterSpeciesThumbnailPath(PokemonDatabaseIndexEntry? species) {
    final relativePath =
        species?.thumbnailRelativePath ?? species?.portraitRelativePath;
    final projectRootPath = _referenceProjectRootPath;
    if (relativePath == null || projectRootPath == null) {
      return null;
    }
    return p.join(projectRootPath, relativePath);
  }

  double _encounterSpeciesThumbnailScale(PokemonDatabaseIndexEntry? species) {
    return species?.thumbnailRelativePath == null ? 1 : 3;
  }

  String _encounterTypeLabel(String type) {
    final normalized = type.trim();
    if (normalized.isEmpty) {
      return 'Type inconnu';
    }
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  void _startNewEncounterEntry(String tableId) {
    _runLocalStateMutation(() {
      _editingEntryTableId = tableId;
      _editingEntryIndex = null;
      _entryValidationMessage = null;
      _entrySpeciesController.clear();
      _entryMinLevelController.text = '1';
      _entryMaxLevelController.text = '5';
      _entryWeightController.text = '1';
      _entryNatureId = '';
      _entryShinyPolicy = ProjectEncounterShinyPolicy.random;
      _entryPokemonOverridesDraft = null;
      _compactWorkspacePane = _EncounterWorkspacePane.inspector;
    });
  }

  void _toggleEncounterEntryEditor(ProjectEncounterTable table, int index) {
    final isEditing =
        _editingEntryTableId == table.id && _editingEntryIndex == index;
    _runLocalStateMutation(() {
      if (isEditing) {
        _closeEntryEditor();
        return;
      }
      final entry = table.entries[index];
      _editingEntryTableId = table.id;
      _editingEntryIndex = index;
      _entryValidationMessage = null;
      _entrySpeciesController.text = entry.speciesId;
      _entryMinLevelController.text = entry.minLevel.toString();
      _entryMaxLevelController.text = entry.maxLevel.toString();
      _entryWeightController.text = entry.weight.toString();
      _entryPokemonOverridesDraft = entry.pokemonOverrides;
      _entryNatureId = entry.pokemonOverrides?.natureId ?? '';
      _entryShinyPolicy =
          entry.pokemonOverrides?.shinyPolicy ??
          ProjectEncounterShinyPolicy.random;
      _compactWorkspacePane = _EncounterWorkspacePane.inspector;
    });
  }

  List<PokeMapDropdownItem<EncounterKind>> _encounterKindDropdownItems() {
    return EncounterKind.values
        .map(
          (kind) => PokeMapDropdownItem<EncounterKind>(
            value: kind,
            label: _isRuntimeCertifiedEncounterKind(kind)
                ? _kindLabel(kind)
                : '${_kindLabel(kind)} — runtime non certifié',
          ),
        )
        .toList(growable: false);
  }

  bool _isRuntimeCertifiedEncounterKind(EncounterKind kind) {
    return kind == EncounterKind.walk || kind == EncounterKind.surf;
  }
}

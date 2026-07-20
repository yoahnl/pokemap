import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/editor/state/models/editor_workspace_mode.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import '../narrative_studio/narrative_studio_route_presentation.dart';
import '../narrative_studio/narrative_studio_workspace_page.dart';
import 'world_state_simulator_panel.dart';

enum FactsWorldRulesWorkspaceMode {
  facts,
  worldRules,
}

class FactsWorldRulesWorkspace extends StatefulWidget {
  const FactsWorldRulesWorkspace({
    super.key,
    required this.project,
    required this.activeMap,
    this.maps = const <MapData>[],
    required this.initialMode,
    required this.onCreateFact,
    required this.onDuplicateFact,
    required this.onUpdateFact,
    required this.onRemoveFact,
    required this.onCreateWorldRule,
    required this.onUpdateWorldRule,
    required this.onRemoveWorldRule,
    this.requestedFactId,
    this.requestedWorldRuleId,
    this.requestedSelectionNonce,
    this.runtimeState,
  });

  final ProjectManifest project;
  final MapData? activeMap;
  final List<MapData> maps;
  final FactsWorldRulesWorkspaceMode initialMode;
  final String? requestedFactId;
  final String? requestedWorldRuleId;
  final int? requestedSelectionNonce;
  final NarrativeFactRuntimeState? runtimeState;
  final Future<String?> Function({
    required String label,
  }) onCreateFact;
  final Future<String?> Function({
    required String factId,
  }) onDuplicateFact;
  final Future<bool> Function({
    required String factId,
    required String label,
    required String description,
    required String category,
    required NarrativeValue initialValue,
  }) onUpdateFact;
  final Future<bool> Function({
    required String factId,
  }) onRemoveFact;
  final Future<String?> Function({
    required String label,
    required String description,
    required bool enabled,
    required WorldRuleSource source,
    required WorldRuleTarget target,
    required WorldRuleEffect effect,
    required int priority,
  }) onCreateWorldRule;
  final Future<bool> Function({
    required String ruleId,
    required String label,
    required String description,
    required bool enabled,
    required WorldRuleSource source,
    required WorldRuleTarget target,
    required WorldRuleEffect effect,
    required int priority,
  }) onUpdateWorldRule;
  final Future<bool> Function({
    required String ruleId,
  }) onRemoveWorldRule;

  @override
  State<FactsWorldRulesWorkspace> createState() =>
      _FactsWorldRulesWorkspaceState();
}

class _FactsWorldRulesWorkspaceState extends State<FactsWorldRulesWorkspace> {
  late FactsWorldRulesWorkspaceMode _mode = widget.initialMode;

  final _factSearchController = TextEditingController();
  final _factCreateNameController = TextEditingController();
  final _factLabelController = TextEditingController();
  final _factDescriptionController = TextEditingController();
  final _factCategoryController = TextEditingController();
  final _factValueController = TextEditingController();

  final _ruleSearchController = TextEditingController();
  final _ruleLabelController = TextEditingController();
  final _ruleDescriptionController = TextEditingController();
  final _rulePriorityController = TextEditingController();
  final _ruleFactValueController = TextEditingController();
  final _ruleEditFactValueController = TextEditingController();

  String? _selectedFactId;
  String? _loadedFactId;
  bool _factDefaultValue = false;
  NarrativeValueKind _factKind = NarrativeValueKind.boolean;
  String? _pendingFactDeleteId;
  String? _factFeedback;
  String _factCategoryFilter = '__all__';
  String _factRoleFilter = 'all';

  String? _selectedRuleId;
  String? _loadedRuleId;
  String? _pendingRuleDeleteId;
  String? _ruleFeedback;
  String? _sourceKey;
  String? _targetKey;
  String? _effectKey;
  String? _dialogueId;
  String? _ruleTypedSourceId;
  NarrativeFactOperator _ruleFactOperator = NarrativeFactOperator.equals;
  String? _editSourceKey;
  String? _editTargetKey;
  String? _editEffectKey;
  String? _editDialogueId;
  NarrativeFactOperator _editRuleFactOperator = NarrativeFactOperator.equals;
  Object? _lastAppliedSelectionRequest;
  bool _requestedFactUnavailable = false;
  bool _requestedWorldRuleUnavailable = false;

  @override
  void didUpdateWidget(covariant FactsWorldRulesWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
    }
  }

  @override
  void dispose() {
    _factSearchController.dispose();
    _factValueController.dispose();
    _ruleFactValueController.dispose();
    _factCreateNameController.dispose();
    _factLabelController.dispose();
    _factDescriptionController.dispose();
    _factCategoryController.dispose();
    _ruleSearchController.dispose();
    _ruleLabelController.dispose();
    _ruleDescriptionController.dispose();
    _rulePriorityController.dispose();
    _ruleEditFactValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maps = widget.maps.isNotEmpty
        ? widget.maps
        : widget.activeMap == null
            ? const <MapData>[]
            : <MapData>[widget.activeMap!];
    final readModel = buildFactsWorldRulesManagerReadModel(
      widget.project,
      maps: maps,
      dependencyIndex: buildNarrativeDependencyIndex(
        project: widget.project,
        maps: maps,
      ),
      runtimeState: widget.runtimeState,
    );
    _ensureValidSelections(readModel);
    final workspaceMode = switch (_mode) {
      FactsWorldRulesWorkspaceMode.facts => EditorWorkspaceMode.facts,
      FactsWorldRulesWorkspaceMode.worldRules => EditorWorkspaceMode.worldRules,
    };

    return Material(
      type: MaterialType.transparency,
      child: NarrativeStudioWorkspacePage(
        presentation: narrativeStudioRoutePresentationFor(workspaceMode)!,
        body: PokeMapPageSurface(
          key: const ValueKey('facts-world-rules-workspace'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetricsStrip(readModel: readModel),
              const SizedBox(height: 14),
              Expanded(
                child: _mode == FactsWorldRulesWorkspaceMode.facts
                    ? _buildFactsManager(context, readModel)
                    : _buildWorldRulesManager(context, readModel, maps),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactsManager(
    BuildContext context,
    FactsWorldRulesManagerReadModel readModel,
  ) {
    final selectedFact =
        _selectedFactId == null ? null : readModel.factById(_selectedFactId!);
    _syncFactEditor(selectedFact);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: PokeMapPanel(
            expandChild: true,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PanelTitle(
                  title: 'Facts',
                  subtitle: 'Faits persistants lisibles par les scènes.',
                ),
                const SizedBox(height: 10),
                _TokenTextField(
                  key: const ValueKey('facts-search-field'),
                  controller: _factSearchController,
                  label: 'Rechercher',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PokeMapDropdownField<String>(
                        key: const ValueKey('facts-category-filter'),
                        label: 'Catégorie',
                        value: _factCategoryFilter,
                        items: [
                          const PokeMapDropdownItem(
                            value: '__all__',
                            label: 'Toutes',
                          ),
                          for (final category in readModel.factCategories)
                            PokeMapDropdownItem(
                              value: category,
                              label: category.isEmpty
                                  ? 'Sans catégorie'
                                  : category,
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _factCategoryFilter = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapDropdownField<String>(
                        key: const ValueKey('facts-role-filter'),
                        label: 'Portée',
                        value: _factRoleFilter,
                        items: const [
                          PokeMapDropdownItem(value: 'all', label: 'Tous'),
                          PokeMapDropdownItem(
                            value: 'readers',
                            label: 'Lus',
                          ),
                          PokeMapDropdownItem(
                            value: 'writers',
                            label: 'Écrits',
                          ),
                          PokeMapDropdownItem(
                            value: 'unused',
                            label: 'Non utilisés',
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _factRoleFilter = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _CreateFactPanel(
                  controller: _factCreateNameController,
                  onCreate: _createFact,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _FactList(
                    facts: _filteredFacts(readModel),
                    selectedFactId: _selectedFactId,
                    onSelect: (factId) {
                      setState(() {
                        _selectedFactId = factId;
                        _requestedFactUnavailable = false;
                        _pendingFactDeleteId = null;
                        _factFeedback = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _requestedFactUnavailable
              ? PokeMapPanel(
                  key: const ValueKey(
                    'facts-manager-requested-unavailable',
                  ),
                  expandChild: true,
                  child: _CompactEmptyState(
                    title: 'Fact introuvable',
                    description:
                        'La cible ${widget.requestedFactId} n’existe plus dans le projet.',
                  ),
                )
              : selectedFact == null
                  ? const PokeMapPanel(
                      key: ValueKey('facts-manager-empty-state'),
                      expandChild: true,
                      child: _CompactEmptyState(
                        title: 'Aucun Fact sélectionné',
                        description:
                            'Créez un Fact booléen, puis configurez son libellé auteur.',
                      ),
                    )
                  : _buildFactEditor(context, selectedFact),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 280,
          child: _buildFactUsagePanel(selectedFact),
        ),
      ],
    );
  }

  Widget _buildFactEditor(BuildContext context, FactManagerEntry entry) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelTitle(
              title: entry.fact.label,
              subtitle: entry.fact.id,
              badge: PokeMapBadge(
                label: entry.isUsed
                    ? 'Utilisé par ${entry.usages.length} élément'
                    : 'Non utilisé',
                variant: entry.isUsed
                    ? PokeMapBadgeVariant.warning
                    : PokeMapBadgeVariant.neutral,
              ),
            ),
            const SizedBox(height: 12),
            PokeMapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StrongText(
                    'Valeur initiale : ${_narrativeValueLabel(entry.initialNarrativeValue)}',
                  ),
                  const SizedBox(height: 4),
                  _SmallText(
                    entry.hasRuntimeOverride
                        ? 'Valeur runtime : ${_narrativeValueLabel(entry.runtimeNarrativeValue!)}'
                        : 'Valeur runtime : absente',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PokeMapBadge(
                        label: '${entry.readerUsages.length} lecture(s)',
                        variant: PokeMapBadgeVariant.info,
                      ),
                      PokeMapBadge(
                        label: '${entry.writerUsages.length} écriture(s)',
                        variant: PokeMapBadgeVariant.narrative,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _TokenTextField(
              key: const ValueKey('fact-editor-label-field'),
              controller: _factLabelController,
              label: 'Libellé auteur',
            ),
            const SizedBox(height: 10),
            _TokenTextField(
              key: const ValueKey('fact-editor-description-field'),
              controller: _factDescriptionController,
              label: 'Description',
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            _TokenTextField(
              key: const ValueKey('fact-editor-category-field'),
              controller: _factCategoryController,
              label: 'Catégorie',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: PokeMapDropdownField<NarrativeValueKind>(
                    key: const ValueKey('fact-editor-type-picker'),
                    label: 'Type du Fact',
                    value: _factKind,
                    items: const [
                      PokeMapDropdownItem(
                        value: NarrativeValueKind.boolean,
                        label: 'Booléen',
                      ),
                      PokeMapDropdownItem(
                        value: NarrativeValueKind.integer,
                        label: 'Nombre entier',
                      ),
                      PokeMapDropdownItem(
                        value: NarrativeValueKind.string,
                        label: 'Texte',
                      ),
                    ],
                    onChanged: (kind) => setState(() {
                      _factKind = kind;
                      if (kind == NarrativeValueKind.integer &&
                          int.tryParse(_factValueController.text) == null) {
                        _factValueController.text = '0';
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _factKind == NarrativeValueKind.boolean
                      ? _ToggleRow(
                          key: const ValueKey('fact-editor-default-toggle'),
                          label: 'Valeur par défaut',
                          value: _factDefaultValue,
                          onChanged: (value) {
                            setState(() => _factDefaultValue = value);
                          },
                        )
                      : _TokenTextField(
                          key: const ValueKey('fact-editor-value-field'),
                          controller: _factValueController,
                          label: _factKind == NarrativeValueKind.integer
                              ? 'Valeur entière initiale'
                              : 'Texte initial',
                        ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FeedbackText(message: _factFeedback),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PokeMapButton(
                  key: const ValueKey('fact-editor-save'),
                  onPressed: () => _saveFact(entry.fact.id),
                  leading: const Icon(CupertinoIcons.check_mark),
                  child: const Text('Enregistrer le Fact'),
                ),
                PokeMapButton(
                  key: const ValueKey('fact-editor-duplicate'),
                  onPressed: () => _duplicateFact(entry.fact.id),
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(CupertinoIcons.doc_on_doc),
                  child: const Text('Dupliquer'),
                ),
                if (entry.isUsed)
                  PokeMapButton(
                    key: const ValueKey('fact-editor-delete-blocked'),
                    onPressed: () {
                      setState(() {
                        _factFeedback =
                            'Suppression bloquée : ce Fact est encore utilisé.';
                      });
                    },
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(CupertinoIcons.lock),
                    child: const Text('Suppression bloquée'),
                  )
                else
                  PokeMapButton(
                    key: const ValueKey('fact-editor-delete'),
                    onPressed: () {
                      setState(() {
                        _pendingFactDeleteId = entry.fact.id;
                        _factFeedback = null;
                      });
                    },
                    variant: PokeMapButtonVariant.danger,
                    leading: const Icon(CupertinoIcons.trash),
                    child: const Text('Supprimer le Fact'),
                  ),
              ],
            ),
            if (_pendingFactDeleteId == entry.fact.id) ...[
              const SizedBox(height: 12),
              PokeMapCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SmallText(
                      'Ce Fact n’est pas référencé. Confirmez la suppression.',
                    ),
                    const SizedBox(height: 8),
                    PokeMapButton(
                      key: const ValueKey('facts-confirm-delete'),
                      onPressed: () => _deleteFact(entry.fact.id),
                      variant: PokeMapButtonVariant.danger,
                      size: PokeMapButtonSize.small,
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFactUsagePanel(FactManagerEntry? entry) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
            title: 'Usages',
            subtitle: 'Lecteurs et producteurs du projet.',
          ),
          const SizedBox(height: 10),
          if (entry == null || entry.usages.isEmpty)
            const Expanded(
              child: _CompactEmptyState(
                title: 'Aucun usage',
                description:
                    'Un Fact non utilisé peut être supprimé sans effet de bord.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: entry.usages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final usage = entry.usages[index];
                  return PokeMapCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StrongText(usage.ownerLabel),
                        const SizedBox(height: 4),
                        PokeMapBadge(
                          label: entry.writerUsages.contains(usage)
                              ? 'Écriture'
                              : 'Lecture',
                          variant: entry.writerUsages.contains(usage)
                              ? PokeMapBadgeVariant.narrative
                              : PokeMapBadgeVariant.info,
                        ),
                        const SizedBox(height: 4),
                        _SmallText(usage.details),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorldRulesManager(
    BuildContext context,
    FactsWorldRulesManagerReadModel readModel,
    List<MapData> maps,
  ) {
    final selectedEntry = _selectedRuleId == null
        ? null
        : _worldRuleById(readModel, _selectedRuleId!);
    _syncWorldRuleEditor(selectedEntry);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 330,
          child: PokeMapPanel(
            expandChild: true,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PanelTitle(
                  title: 'Règles du monde',
                  subtitle: 'Sources authorées vers effets visibles.',
                ),
                const SizedBox(height: 10),
                _TokenTextField(
                  key: const ValueKey('world-rules-search-field'),
                  controller: _ruleSearchController,
                  label: 'Rechercher',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _WorldRuleList(
                    rules: _filteredWorldRules(readModel),
                    selectedRuleId: _selectedRuleId,
                    onSelect: (ruleId) {
                      setState(() {
                        _selectedRuleId = ruleId;
                        _requestedWorldRuleUnavailable = false;
                        _pendingRuleDeleteId = null;
                        _ruleFeedback = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWorldRuleCreatePanel(context, readModel),
              const SizedBox(height: 12),
              Expanded(
                child: _requestedWorldRuleUnavailable
                    ? PokeMapPanel(
                        key: const ValueKey(
                          'world-rules-manager-requested-unavailable',
                        ),
                        expandChild: true,
                        child: _CompactEmptyState(
                          title: 'Règle du monde introuvable',
                          description:
                              'La cible ${widget.requestedWorldRuleId} n’existe plus dans le projet.',
                        ),
                      )
                    : selectedEntry == null
                        ? const PokeMapPanel(
                            key: ValueKey('world-rules-manager-empty-state'),
                            expandChild: true,
                            child: _CompactEmptyState(
                              title: 'Aucune règle sélectionnée',
                              description:
                                  'Créez une règle depuis les pickers no-code.',
                            ),
                          )
                        : _buildWorldRuleEditor(
                            context,
                            readModel,
                            selectedEntry,
                          ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 360,
          child: WorldStateSimulatorPanel(
            project: widget.project,
            maps: maps,
          ),
        ),
      ],
    );
  }

  Widget _buildWorldRuleCreatePanel(
    BuildContext context,
    FactsWorldRulesManagerReadModel readModel,
  ) {
    final source = _selectedSource(readModel);
    final sourceFact = source?.kind == WorldRuleSourceKind.fact
        ? widget.project.facts
            .where((fact) => fact.id == source!.sourceId)
            .firstOrNull
        : null;
    _syncRuleFactInput(sourceFact);
    final typedFactValue =
        sourceFact == null ? null : _ruleFactInputValue(sourceFact.valueKind);
    final target = _selectedTarget(readModel);
    final effects = _compatibleEffects(readModel, target);
    final effect = _selectedEffect(effects);
    final hasDialogue = effect?.requiresDialogue == true;
    final canCreate = source != null &&
        target != null &&
        effect != null &&
        (sourceFact == null || typedFactValue != null) &&
        (!hasDialogue || readModel.dialogueOptions.isNotEmpty);

    return PokeMapPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
            title: 'Nouvelle règle',
            subtitle: 'Construire sans ID manuel.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 220,
                child: _SourceDropdown(
                  value: source == null ? null : _sourceOptionKey(source),
                  options: readModel.sourceOptions,
                  onChanged: (value) {
                    setState(() {
                      _sourceKey = value;
                      _ruleTypedSourceId = null;
                    });
                  },
                ),
              ),
              if (sourceFact != null) ...[
                SizedBox(
                  width: 220,
                  child: PokeMapDropdownField<NarrativeFactOperator>(
                    key: const ValueKey('world-rule-fact-operator-picker'),
                    label: 'Comparaison',
                    value: _ruleFactOperator,
                    items: [
                      for (final operator
                          in sourceFact.valueKind.compatibleOperators)
                        PokeMapDropdownItem(
                          value: operator,
                          label: _factOperatorLabel(operator),
                        ),
                    ],
                    onChanged: (operator) {
                      setState(() => _ruleFactOperator = operator);
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: sourceFact.valueKind == NarrativeValueKind.boolean
                      ? _ToggleRow(
                          key: const ValueKey('world-rule-fact-bool-value'),
                          label: 'Valeur comparée',
                          value: typedFactValue?.boolValue ?? false,
                          onChanged: (value) => setState(() {
                            _ruleFactValueController.text = '$value';
                          }),
                        )
                      : _TokenTextField(
                          key: const ValueKey('world-rule-fact-value-field'),
                          controller: _ruleFactValueController,
                          label:
                              sourceFact.valueKind == NarrativeValueKind.integer
                                  ? 'Valeur entière comparée'
                                  : 'Texte comparé',
                          onChanged: (_) => setState(() {}),
                        ),
                ),
              ],
              SizedBox(
                width: 220,
                child: _TargetDropdown(
                  value: target == null ? null : _targetOptionKey(target),
                  options: readModel.targetOptions,
                  onChanged: (value) {
                    setState(() {
                      _targetKey = value;
                      _effectKey = null;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: _EffectDropdown(
                  value: effect == null ? null : _effectOptionKey(effect),
                  options: effects,
                  onChanged: (value) {
                    setState(() => _effectKey = value);
                  },
                ),
              ),
              if (hasDialogue)
                SizedBox(
                  width: 220,
                  child: _DialogueDropdown(
                    value: _selectedDialogueId(readModel),
                    options: readModel.dialogueOptions,
                    onChanged: (value) {
                      setState(() => _dialogueId = value);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _FeedbackText(message: _ruleFeedback),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const ValueKey('world-rule-create-submit'),
              onPressed: canCreate
                  ? () => _createWorldRule(
                        source: source,
                        typedFactValue: typedFactValue,
                        target: target,
                        effect: effect,
                        dialogueId: _selectedDialogueId(readModel),
                      )
                  : null,
              leading: const Icon(CupertinoIcons.plus),
              child: const Text('Créer la règle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldRuleEditor(
    BuildContext context,
    FactsWorldRulesManagerReadModel readModel,
    WorldRuleManagerEntry entry,
  ) {
    final source = _selectedEditSource(readModel);
    final sourceFact = source?.kind == WorldRuleSourceKind.fact
        ? widget.project.facts
            .where((fact) => fact.id == source!.sourceId)
            .firstOrNull
        : null;
    final typedFactValue = sourceFact == null
        ? null
        : _ruleEditFactInputValue(sourceFact.valueKind);
    final target = _selectedEditTarget(readModel);
    final effects = _compatibleEffects(readModel, target);
    final effect = _selectedEditEffect(effects);
    final hasDialogue = effect?.requiresDialogue == true;
    final dialogueId = _selectedEditDialogueId(readModel);
    final canSave = source != null &&
        target != null &&
        effect != null &&
        (sourceFact == null || typedFactValue != null) &&
        (!hasDialogue || dialogueId != null);
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelTitle(
              title: entry.rule.label,
              subtitle: entry.humanSummary,
              badge: PokeMapBadge(
                label: entry.rule.enabled ? 'Active' : 'Désactivée',
                variant: entry.rule.enabled
                    ? PokeMapBadgeVariant.success
                    : PokeMapBadgeVariant.neutral,
              ),
            ),
            const SizedBox(height: 12),
            _TokenTextField(
              key: const ValueKey('world-rule-editor-label-field'),
              controller: _ruleLabelController,
              label: 'Libellé auteur',
            ),
            const SizedBox(height: 10),
            _TokenTextField(
              key: const ValueKey('world-rule-editor-priority-field'),
              controller: _rulePriorityController,
              label: 'Priorité',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _TokenTextField(
              key: const ValueKey('world-rule-editor-description-field'),
              controller: _ruleDescriptionController,
              label: 'Description',
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            PokeMapCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PanelTitle(
                    title: 'Configuration',
                    subtitle:
                        'Source, prédicat, cible et effet restent modifiables.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 240,
                        child: _SourceDropdown(
                          key: const ValueKey(
                            'world-rule-editor-source-picker',
                          ),
                          value:
                              source == null ? null : _sourceOptionKey(source),
                          options: readModel.sourceOptions,
                          onChanged: (value) {
                            setState(() {
                              _editSourceKey = value;
                              final selected = _optionByKey(
                                readModel.sourceOptions,
                                value,
                                _sourceOptionKey,
                              );
                              _syncEditRuleFactInput(selected);
                            });
                          },
                        ),
                      ),
                      if (sourceFact != null) ...[
                        SizedBox(
                          width: 240,
                          child: PokeMapDropdownField<NarrativeFactOperator>(
                            key: const ValueKey(
                              'world-rule-editor-fact-operator-picker',
                            ),
                            label: 'Comparaison',
                            value: _editRuleFactOperator,
                            items: [
                              for (final operator
                                  in sourceFact.valueKind.compatibleOperators)
                                PokeMapDropdownItem(
                                  value: operator,
                                  label: _factOperatorLabel(operator),
                                ),
                            ],
                            onChanged: (operator) {
                              setState(() => _editRuleFactOperator = operator);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child:
                              sourceFact.valueKind == NarrativeValueKind.boolean
                                  ? _ToggleRow(
                                      key: const ValueKey(
                                        'world-rule-editor-fact-bool-value',
                                      ),
                                      label: 'Valeur comparée',
                                      value: typedFactValue?.boolValue ?? false,
                                      onChanged: (value) => setState(() {
                                        _ruleEditFactValueController.text =
                                            '$value';
                                      }),
                                    )
                                  : _TokenTextField(
                                      key: const ValueKey(
                                        'world-rule-editor-fact-value-field',
                                      ),
                                      controller: _ruleEditFactValueController,
                                      label: sourceFact.valueKind ==
                                              NarrativeValueKind.integer
                                          ? 'Valeur entière comparée'
                                          : 'Texte comparé',
                                      onChanged: (_) => setState(() {}),
                                    ),
                        ),
                      ],
                      SizedBox(
                        width: 240,
                        child: _TargetDropdown(
                          key: const ValueKey(
                            'world-rule-editor-target-picker',
                          ),
                          value:
                              target == null ? null : _targetOptionKey(target),
                          options: readModel.targetOptions,
                          onChanged: (value) {
                            setState(() {
                              _editTargetKey = value;
                              _editEffectKey = null;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: _EffectDropdown(
                          key: const ValueKey(
                            'world-rule-editor-effect-picker',
                          ),
                          value:
                              effect == null ? null : _effectOptionKey(effect),
                          options: effects,
                          onChanged: (value) {
                            setState(() => _editEffectKey = value);
                          },
                        ),
                      ),
                      if (hasDialogue)
                        SizedBox(
                          width: 240,
                          child: _DialogueDropdown(
                            key: const ValueKey(
                              'world-rule-editor-dialogue-picker',
                            ),
                            value: dialogueId,
                            options: readModel.dialogueOptions,
                            onChanged: (value) {
                              setState(() => _editDialogueId = value);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PokeMapBadge(
                  label: entry.sourceLabel,
                  variant: PokeMapBadgeVariant.info,
                ),
                PokeMapBadge(
                  label: entry.effectLabel,
                  variant: PokeMapBadgeVariant.narrative,
                ),
                PokeMapBadge(
                  label: entry.targetLabel,
                  variant: PokeMapBadgeVariant.mapAccent,
                ),
              ],
            ),
            if (entry.hasDiagnostics) ...[
              const SizedBox(height: 12),
              for (final diagnostic in entry.diagnostics)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PokeMapBadge(
                    label: diagnostic.message,
                    variant: PokeMapBadgeVariant.warning,
                  ),
                ),
            ],
            const SizedBox(height: 12),
            _FeedbackText(message: _ruleFeedback),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PokeMapButton(
                  key: const ValueKey('world-rule-editor-save'),
                  onPressed: canSave
                      ? () => _saveWorldRule(
                            entry.rule,
                            source: source,
                            target: target,
                            effect: effect,
                            dialogueId: dialogueId,
                            typedFactValue: typedFactValue,
                          )
                      : null,
                  leading: const Icon(CupertinoIcons.check_mark),
                  child: const Text('Enregistrer'),
                ),
                PokeMapButton(
                  key: const ValueKey('world-rule-toggle-enabled'),
                  onPressed: () => _toggleWorldRule(entry.rule),
                  variant: PokeMapButtonVariant.secondary,
                  leading: Icon(
                    entry.rule.enabled
                        ? CupertinoIcons.pause
                        : CupertinoIcons.play,
                  ),
                  child: Text(entry.rule.enabled ? 'Désactiver' : 'Activer'),
                ),
                PokeMapButton(
                  key: const ValueKey('world-rule-editor-delete'),
                  onPressed: () {
                    setState(() {
                      _pendingRuleDeleteId = entry.rule.id;
                      _ruleFeedback = null;
                    });
                  },
                  variant: PokeMapButtonVariant.danger,
                  leading: const Icon(CupertinoIcons.trash),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
            if (_pendingRuleDeleteId == entry.rule.id) ...[
              const SizedBox(height: 12),
              PokeMapCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SmallText(
                        'Confirmez la suppression de cette règle.'),
                    const SizedBox(height: 8),
                    PokeMapButton(
                      key: const ValueKey('world-rules-confirm-delete'),
                      onPressed: () => _deleteWorldRule(entry.rule.id),
                      variant: PokeMapButtonVariant.danger,
                      size: PokeMapButtonSize.small,
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _ensureValidSelections(FactsWorldRulesManagerReadModel readModel) {
    final factIds = readModel.facts.map((entry) => entry.fact.id).toSet();
    final ruleIds = readModel.worldRules.map((entry) => entry.rule.id).toSet();
    final requestedFactId = widget.requestedFactId?.trim();
    final requestedRuleId = widget.requestedWorldRuleId?.trim();
    final request = (
      widget.initialMode,
      widget.requestedFactId,
      widget.requestedWorldRuleId,
      widget.requestedSelectionNonce,
    );
    if (_lastAppliedSelectionRequest != request) {
      _lastAppliedSelectionRequest = request;
      if (_mode == FactsWorldRulesWorkspaceMode.facts) {
        _requestedFactUnavailable = requestedFactId != null &&
            requestedFactId.isNotEmpty &&
            !factIds.contains(requestedFactId);
        if (!_requestedFactUnavailable &&
            requestedFactId != null &&
            requestedFactId.isNotEmpty) {
          _selectedFactId = requestedFactId;
          _loadedFactId = null;
          _pendingFactDeleteId = null;
        }
      }
      if (_mode == FactsWorldRulesWorkspaceMode.worldRules) {
        _requestedWorldRuleUnavailable = requestedRuleId != null &&
            requestedRuleId.isNotEmpty &&
            !ruleIds.contains(requestedRuleId);
        if (!_requestedWorldRuleUnavailable &&
            requestedRuleId != null &&
            requestedRuleId.isNotEmpty) {
          _selectedRuleId = requestedRuleId;
          _loadedRuleId = null;
          _pendingRuleDeleteId = null;
        }
      }
    }
    if (_mode == FactsWorldRulesWorkspaceMode.facts &&
        requestedFactId != null &&
        requestedFactId.isNotEmpty &&
        !factIds.contains(requestedFactId)) {
      _requestedFactUnavailable = true;
      _selectedFactId = null;
    }
    if (_mode == FactsWorldRulesWorkspaceMode.worldRules &&
        requestedRuleId != null &&
        requestedRuleId.isNotEmpty &&
        !ruleIds.contains(requestedRuleId)) {
      _requestedWorldRuleUnavailable = true;
      _selectedRuleId = null;
    }
    if (!_requestedFactUnavailable &&
        (_selectedFactId == null || !factIds.contains(_selectedFactId))) {
      _selectedFactId =
          readModel.facts.isEmpty ? null : readModel.facts.first.fact.id;
      _loadedFactId = null;
      _pendingFactDeleteId = null;
    }
    if (!_requestedWorldRuleUnavailable &&
        (_selectedRuleId == null || !ruleIds.contains(_selectedRuleId))) {
      _selectedRuleId = readModel.worldRules.isEmpty
          ? null
          : readModel.worldRules.first.rule.id;
      _loadedRuleId = null;
      _pendingRuleDeleteId = null;
    }
  }

  List<FactManagerEntry> _filteredFacts(
    FactsWorldRulesManagerReadModel readModel,
  ) {
    final query = _factSearchController.text.trim().toLowerCase();
    return [
      for (final entry in readModel.facts)
        if ((_factCategoryFilter == '__all__' ||
                entry.fact.category == _factCategoryFilter) &&
            switch (_factRoleFilter) {
              'readers' => entry.readerUsages.isNotEmpty,
              'writers' => entry.writerUsages.isNotEmpty,
              'unused' => !entry.isUsed,
              _ => true,
            } &&
            (query.isEmpty ||
                entry.fact.label.toLowerCase().contains(query) ||
                entry.fact.id.toLowerCase().contains(query) ||
                entry.fact.category.toLowerCase().contains(query)))
          entry,
    ];
  }

  List<WorldRuleManagerEntry> _filteredWorldRules(
    FactsWorldRulesManagerReadModel readModel,
  ) {
    final query = _ruleSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return readModel.worldRules;
    }
    return [
      for (final entry in readModel.worldRules)
        if (entry.rule.label.toLowerCase().contains(query) ||
            entry.humanSummary.toLowerCase().contains(query) ||
            entry.rule.id.toLowerCase().contains(query))
          entry,
    ];
  }

  void _syncFactEditor(FactManagerEntry? entry) {
    final fact = entry?.fact;
    if (_loadedFactId == fact?.id) {
      return;
    }
    _loadedFactId = fact?.id;
    _factLabelController.text = fact?.label ?? '';
    _factDescriptionController.text = fact?.description ?? '';
    _factCategoryController.text = fact?.category ?? '';
    _factKind = fact?.valueKind ?? NarrativeValueKind.boolean;
    _factDefaultValue = fact?.valueKind == NarrativeValueKind.boolean
        ? fact!.initialValue.boolValue
        : false;
    _factValueController.text = switch (fact?.initialValue) {
      NarrativeValue(kind: NarrativeValueKind.integer) =>
        '${fact!.initialValue.intValue}',
      NarrativeValue(kind: NarrativeValueKind.string) =>
        fact!.initialValue.stringValue,
      _ => '',
    };
  }

  void _syncWorldRuleEditor(WorldRuleManagerEntry? entry) {
    final rule = entry?.rule;
    if (_loadedRuleId == rule?.id) {
      return;
    }
    _loadedRuleId = rule?.id;
    _ruleLabelController.text = rule?.label ?? '';
    _ruleDescriptionController.text = rule?.description ?? '';
    _rulePriorityController.text = rule == null ? '0' : '${rule.priority}';
    final editablePredicate = rule?.source.kind == WorldRuleSourceKind.fact
        ? WorldRuleSourcePredicate.isTrue
        : rule?.source.predicate;
    _editSourceKey = rule == null
        ? null
        : '${rule.source.kind.name}:${editablePredicate!.name}:'
            '${rule.source.sourceId}';
    _editTargetKey = rule == null
        ? null
        : '${rule.target.kind.name}:${rule.target.mapId}:'
            '${rule.target.entityId ?? ''}:${rule.target.eventId ?? ''}';
    _editEffectKey = rule?.effect.kind.name;
    _editDialogueId = rule?.effect.dialogueId;
    _editRuleFactOperator =
        rule?.source.resolvedFactOperator ?? NarrativeFactOperator.equals;
    _ruleEditFactValueController.text =
        switch (rule?.source.expectedFactValue) {
      NarrativeValue(kind: NarrativeValueKind.boolean) =>
        '${rule!.source.expectedFactValue!.boolValue}',
      NarrativeValue(kind: NarrativeValueKind.integer) =>
        '${rule!.source.expectedFactValue!.intValue}',
      NarrativeValue(kind: NarrativeValueKind.string) =>
        rule!.source.expectedFactValue!.stringValue,
      _ when rule?.source.kind == WorldRuleSourceKind.fact =>
        '${rule!.source.predicate == WorldRuleSourcePredicate.isTrue}',
      _ => '',
    };
  }

  void _syncEditRuleFactInput(WorldRuleSourcePickerOption? source) {
    if (source?.kind != WorldRuleSourceKind.fact) {
      _ruleEditFactValueController.clear();
      _editRuleFactOperator = NarrativeFactOperator.equals;
      return;
    }
    final fact = widget.project.facts
        .where((candidate) => candidate.id == source!.sourceId)
        .firstOrNull;
    _editRuleFactOperator = NarrativeFactOperator.equals;
    _ruleEditFactValueController.text = switch (fact?.initialValue) {
      NarrativeValue(kind: NarrativeValueKind.boolean) =>
        '${fact!.initialValue.boolValue}',
      NarrativeValue(kind: NarrativeValueKind.integer) =>
        '${fact!.initialValue.intValue}',
      NarrativeValue(kind: NarrativeValueKind.string) =>
        fact!.initialValue.stringValue,
      _ => '',
    };
  }

  void _syncRuleFactInput(NarrativeFactDefinition? fact) {
    if (_ruleTypedSourceId == fact?.id) return;
    _ruleTypedSourceId = fact?.id;
    _ruleFactOperator = NarrativeFactOperator.equals;
    _ruleFactValueController.text = switch (fact?.initialValue) {
      NarrativeValue(kind: NarrativeValueKind.boolean) =>
        '${fact!.initialValue.boolValue}',
      NarrativeValue(kind: NarrativeValueKind.integer) =>
        '${fact!.initialValue.intValue}',
      NarrativeValue(kind: NarrativeValueKind.string) =>
        fact!.initialValue.stringValue,
      _ => '',
    };
  }

  NarrativeValue? _ruleFactInputValue(NarrativeValueKind kind) =>
      switch (kind) {
        NarrativeValueKind.boolean => NarrativeValue.boolean(
            _ruleFactValueController.text.trim().toLowerCase() == 'true',
          ),
        NarrativeValueKind.integer => switch (
              int.tryParse(_ruleFactValueController.text.trim())) {
            final value? => NarrativeValue.integer(value),
            null => null,
          },
        NarrativeValueKind.string =>
          NarrativeValue.string(_ruleFactValueController.text),
      };

  NarrativeValue? _ruleEditFactInputValue(NarrativeValueKind kind) =>
      switch (kind) {
        NarrativeValueKind.boolean => NarrativeValue.boolean(
            _ruleEditFactValueController.text.trim().toLowerCase() == 'true',
          ),
        NarrativeValueKind.integer => switch (
              int.tryParse(_ruleEditFactValueController.text.trim())) {
            final value? => NarrativeValue.integer(value),
            null => null,
          },
        NarrativeValueKind.string =>
          NarrativeValue.string(_ruleEditFactValueController.text),
      };

  Future<void> _createFact() async {
    final label = _factCreateNameController.text.trim();
    if (label.isEmpty) {
      setState(() => _factFeedback = 'Le libellé du Fact est requis.');
      return;
    }
    final factId = await widget.onCreateFact(label: label);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedFactId = factId ?? _selectedFactId;
      _loadedFactId = null;
      _factCreateNameController.clear();
      _factFeedback = factId == null ? 'Création impossible.' : null;
    });
  }

  Future<void> _saveFact(String factId) async {
    final initialValue = switch (_factKind) {
      NarrativeValueKind.boolean => NarrativeValue.boolean(_factDefaultValue),
      NarrativeValueKind.integer => switch (
            int.tryParse(_factValueController.text.trim())) {
          final value? => NarrativeValue.integer(value),
          null => null,
        },
      NarrativeValueKind.string =>
        NarrativeValue.string(_factValueController.text),
    };
    if (initialValue == null) {
      setState(() => _factFeedback = 'Saisissez un nombre entier valide.');
      return;
    }
    final ok = await widget.onUpdateFact(
      factId: factId,
      label: _factLabelController.text,
      description: _factDescriptionController.text,
      category: _factCategoryController.text,
      initialValue: initialValue,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loadedFactId = null;
      _factFeedback = ok ? 'Fact enregistré.' : 'Enregistrement impossible.';
    });
  }

  Future<void> _duplicateFact(String factId) async {
    final duplicatedId = await widget.onDuplicateFact(factId: factId);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedFactId = duplicatedId ?? factId;
      _loadedFactId = null;
      _factFeedback = duplicatedId == null ? 'Duplication impossible.' : null;
    });
  }

  Future<void> _deleteFact(String factId) async {
    final ok = await widget.onRemoveFact(factId: factId);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingFactDeleteId = null;
      _selectedFactId = ok ? null : factId;
      _loadedFactId = null;
      _factFeedback = ok ? null : 'Suppression impossible.';
    });
  }

  WorldRuleManagerEntry? _worldRuleById(
    FactsWorldRulesManagerReadModel readModel,
    String ruleId,
  ) {
    for (final entry in readModel.worldRules) {
      if (entry.rule.id == ruleId) {
        return entry;
      }
    }
    return null;
  }

  WorldRuleSourcePickerOption? _selectedSource(
    FactsWorldRulesManagerReadModel readModel,
  ) {
    final options = readModel.sourceOptions;
    if (options.isEmpty) {
      return null;
    }
    return _optionByKey(options, _sourceKey, _sourceOptionKey) ??
        _defaultSource(options);
  }

  WorldRuleSourcePickerOption? _selectedEditSource(
    FactsWorldRulesManagerReadModel readModel,
  ) =>
      _optionByKey(
        readModel.sourceOptions,
        _editSourceKey,
        _sourceOptionKey,
      );

  WorldRuleTargetPickerOption? _selectedTarget(
    FactsWorldRulesManagerReadModel readModel,
  ) {
    final options = readModel.targetOptions;
    if (options.isEmpty) {
      return null;
    }
    return _optionByKey(options, _targetKey, _targetOptionKey) ??
        _defaultTarget(options);
  }

  WorldRuleTargetPickerOption? _selectedEditTarget(
    FactsWorldRulesManagerReadModel readModel,
  ) =>
      _optionByKey(
        readModel.targetOptions,
        _editTargetKey,
        _targetOptionKey,
      );

  WorldRuleEffectPickerOption? _selectedEffect(
    List<WorldRuleEffectPickerOption> options,
  ) {
    if (options.isEmpty) {
      return null;
    }
    return _optionByKey(options, _effectKey, _effectOptionKey) ??
        _defaultEffect(options);
  }

  WorldRuleEffectPickerOption? _selectedEditEffect(
    List<WorldRuleEffectPickerOption> options,
  ) =>
      _optionByKey(options, _editEffectKey, _effectOptionKey);

  List<WorldRuleEffectPickerOption> _compatibleEffects(
    FactsWorldRulesManagerReadModel readModel,
    WorldRuleTargetPickerOption? target,
  ) {
    if (target == null) {
      return const <WorldRuleEffectPickerOption>[];
    }
    return [
      for (final effect in readModel.effectOptions)
        if (effect.compatibleTargetKind == target.kind) effect,
    ];
  }

  String? _selectedDialogueId(FactsWorldRulesManagerReadModel readModel) {
    if (readModel.dialogueOptions.isEmpty) {
      return null;
    }
    final ids =
        readModel.dialogueOptions.map((option) => option.dialogueId).toSet();
    if (_dialogueId != null && ids.contains(_dialogueId)) {
      return _dialogueId;
    }
    return readModel.dialogueOptions.first.dialogueId;
  }

  String? _selectedEditDialogueId(
    FactsWorldRulesManagerReadModel readModel,
  ) {
    final ids =
        readModel.dialogueOptions.map((option) => option.dialogueId).toSet();
    if (_editDialogueId != null && ids.contains(_editDialogueId)) {
      return _editDialogueId;
    }
    return readModel.dialogueOptions.firstOrNull?.dialogueId;
  }

  Future<void> _createWorldRule({
    required WorldRuleSourcePickerOption source,
    required WorldRuleTargetPickerOption target,
    required WorldRuleEffectPickerOption effect,
    required String? dialogueId,
    required NarrativeValue? typedFactValue,
  }) async {
    final sourceModel =
        source.kind == WorldRuleSourceKind.fact && typedFactValue != null
            ? WorldRuleSource.factValue(
                factId: source.sourceId,
                operator: _ruleFactOperator,
                expectedValue: typedFactValue,
                label: source.label,
                debugTechnicalLabel: source.debugTechnicalLabel,
              )
            : WorldRuleSource(
                kind: source.kind,
                sourceId: source.sourceId,
                predicate: source.predicate,
                label: source.label,
                debugTechnicalLabel: source.debugTechnicalLabel,
              );
    final targetModel = WorldRuleTarget(
      kind: target.kind,
      mapId: target.mapId,
      entityId: target.entityId,
      eventId: target.eventId,
      label: target.label,
    );
    final effectModel = WorldRuleEffect(
      kind: effect.effectKind,
      dialogueId: effect.requiresDialogue ? dialogueId : null,
      label: effect.label,
    );
    final label = 'Règle ${source.label} ${effect.label}';
    final ruleId = await widget.onCreateWorldRule(
      label: label,
      description: '',
      enabled: true,
      source: sourceModel,
      target: targetModel,
      effect: effectModel,
      priority: 0,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedRuleId = ruleId ?? _selectedRuleId;
      _loadedRuleId = null;
      _ruleFeedback = ruleId == null ? 'Création impossible.' : null;
    });
  }

  Future<void> _saveWorldRule(
    WorldRuleDefinition rule, {
    required WorldRuleSourcePickerOption source,
    required WorldRuleTargetPickerOption target,
    required WorldRuleEffectPickerOption effect,
    required String? dialogueId,
    required NarrativeValue? typedFactValue,
  }) async {
    final priority = int.tryParse(_rulePriorityController.text.trim()) ?? 0;
    final sourceModel =
        source.kind == WorldRuleSourceKind.fact && typedFactValue != null
            ? WorldRuleSource.factValue(
                factId: source.sourceId,
                operator: _editRuleFactOperator,
                expectedValue: typedFactValue,
                label: source.label,
                debugTechnicalLabel: source.debugTechnicalLabel,
              )
            : WorldRuleSource(
                kind: source.kind,
                sourceId: source.sourceId,
                predicate: source.predicate,
                label: source.label,
                debugTechnicalLabel: source.debugTechnicalLabel,
              );
    final targetModel = WorldRuleTarget(
      kind: target.kind,
      mapId: target.mapId,
      entityId: target.entityId,
      eventId: target.eventId,
      label: target.label,
    );
    final effectModel = WorldRuleEffect(
      kind: effect.effectKind,
      dialogueId: effect.requiresDialogue ? dialogueId : null,
      label: effect.label,
    );
    final ok = await widget.onUpdateWorldRule(
      ruleId: rule.id,
      label: _ruleLabelController.text,
      description: _ruleDescriptionController.text,
      enabled: rule.enabled,
      source: sourceModel,
      target: targetModel,
      effect: effectModel,
      priority: priority,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loadedRuleId = null;
      _ruleFeedback = ok ? 'Règle enregistrée.' : 'Enregistrement impossible.';
    });
  }

  Future<void> _toggleWorldRule(WorldRuleDefinition rule) async {
    final ok = await widget.onUpdateWorldRule(
      ruleId: rule.id,
      label: rule.label,
      description: rule.description,
      enabled: !rule.enabled,
      source: rule.source,
      target: rule.target,
      effect: rule.effect,
      priority: rule.priority,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loadedRuleId = null;
      _ruleFeedback = ok ? null : 'Mise à jour impossible.';
    });
  }

  Future<void> _deleteWorldRule(String ruleId) async {
    final ok = await widget.onRemoveWorldRule(ruleId: ruleId);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingRuleDeleteId = null;
      _selectedRuleId = ok ? null : ruleId;
      _loadedRuleId = null;
      _ruleFeedback = ok ? null : 'Suppression impossible.';
    });
  }
}

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({required this.readModel});

  final FactsWorldRulesManagerReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5).toDouble();
    return SizedBox(
      // Metric cards include a subtitle; reserve the extra line-height at
      // accessible text scales instead of clipping the shared DS primitive.
      height: 132 + ((textScale - 1) * 32),
      child: Row(
        children: [
          Expanded(
            child: PokeMapMetricCard(
              title: 'Facts',
              value: '${readModel.factCount}',
              icon: CupertinoIcons.doc_text,
              subtitle: '${readModel.usedFactCount} utilisé(s)',
              tone: PokeMapTone.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PokeMapMetricCard(
              title: 'Règles',
              value: '${readModel.worldRuleCount}',
              icon: CupertinoIcons.checkmark_seal,
              subtitle: '${readModel.enabledWorldRuleCount} active(s)',
              tone: PokeMapTone.narrative,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PokeMapMetricCard(
              title: 'Diagnostics',
              value: '${readModel.worldRuleDiagnosticCount}',
              icon: CupertinoIcons.exclamationmark_triangle,
              subtitle: 'World Rules',
              tone: readModel.worldRuleDiagnosticCount == 0
                  ? PokeMapTone.success
                  : PokeMapTone.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateFactPanel extends StatelessWidget {
  const _CreateFactPanel({
    required this.controller,
    required this.onCreate,
  });

  final TextEditingController controller;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StrongText('Nouveau Fact'),
          const SizedBox(height: 8),
          _TokenTextField(
            key: const ValueKey('facts-create-name-field'),
            controller: controller,
            label: 'Nom auteur',
          ),
          const SizedBox(height: 8),
          PokeMapButton(
            key: const ValueKey('facts-create-submit'),
            onPressed: onCreate,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.plus),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _FactList extends StatelessWidget {
  const _FactList({
    required this.facts,
    required this.selectedFactId,
    required this.onSelect,
  });

  final List<FactManagerEntry> facts;
  final String? selectedFactId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) {
      return const _CompactEmptyState(
        title: 'Aucun Fact',
        description: 'Les Facts créés apparaîtront ici.',
      );
    }
    return ListView.separated(
      itemCount: facts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = facts[index];
        return PokeMapCard(
          key: ValueKey('fact-list-${entry.fact.id}'),
          selected: entry.fact.id == selectedFactId,
          onTap: () => onSelect(entry.fact.id),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StrongText(entry.fact.label),
              const SizedBox(height: 4),
              _SmallText(entry.fact.id),
              const SizedBox(height: 6),
              PokeMapBadge(
                label: entry.isUsed ? 'Utilisé' : 'Non utilisé',
                variant: entry.isUsed
                    ? PokeMapBadgeVariant.warning
                    : PokeMapBadgeVariant.neutral,
              ),
            ],
          ),
        );
      },
    );
  }
}

String _boolLabel(bool value) => value ? 'Vrai' : 'Faux';

String _narrativeValueLabel(NarrativeValue value) => switch (value.kind) {
      NarrativeValueKind.boolean => _boolLabel(value.boolValue),
      NarrativeValueKind.integer => '${value.intValue}',
      NarrativeValueKind.string =>
        value.stringValue.isEmpty ? 'Texte vide' : '“${value.stringValue}”',
    };

String _factOperatorLabel(NarrativeFactOperator operator) => switch (operator) {
      NarrativeFactOperator.equals => 'Est égal à',
      NarrativeFactOperator.notEquals => 'Est différent de',
      NarrativeFactOperator.greaterThan => 'Est supérieur à',
      NarrativeFactOperator.greaterThanOrEqual => 'Est supérieur ou égal à',
      NarrativeFactOperator.lessThan => 'Est inférieur à',
      NarrativeFactOperator.lessThanOrEqual => 'Est inférieur ou égal à',
    };

class _WorldRuleList extends StatelessWidget {
  const _WorldRuleList({
    required this.rules,
    required this.selectedRuleId,
    required this.onSelect,
  });

  final List<WorldRuleManagerEntry> rules;
  final String? selectedRuleId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const _CompactEmptyState(
        title: 'Aucune règle',
        description: 'Les règles créées apparaîtront ici.',
      );
    }
    return ListView.separated(
      itemCount: rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = rules[index];
        return PokeMapCard(
          selected: entry.rule.id == selectedRuleId,
          onTap: () => onSelect(entry.rule.id),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StrongText(entry.rule.label),
              const SizedBox(height: 4),
              _SmallText(entry.humanSummary),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PokeMapBadge(
                    label: entry.rule.enabled ? 'Active' : 'Désactivée',
                    variant: entry.rule.enabled
                        ? PokeMapBadgeVariant.success
                        : PokeMapBadgeVariant.neutral,
                  ),
                  if (entry.hasDiagnostics)
                    const PokeMapBadge(
                      label: 'Diagnostics',
                      variant: PokeMapBadgeVariant.warning,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceDropdown extends StatelessWidget {
  const _SourceDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<WorldRuleSourcePickerOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TokenDropdown<String>(
      label: 'Source',
      value: value,
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: _sourceOptionKey(option),
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _TargetDropdown extends StatelessWidget {
  const _TargetDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<WorldRuleTargetPickerOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TokenDropdown<String>(
      label: 'Cible',
      value: value,
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: _targetOptionKey(option),
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _EffectDropdown extends StatelessWidget {
  const _EffectDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<WorldRuleEffectPickerOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TokenDropdown<String>(
      label: 'Effet',
      value: value,
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: _effectOptionKey(option),
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _DialogueDropdown extends StatelessWidget {
  const _DialogueDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<WorldRuleDialoguePickerOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TokenDropdown<String>(
      label: 'Dialogue',
      value: value,
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option.dialogueId,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _TokenDropdown<T> extends StatelessWidget {
  const _TokenDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final resolvedValue =
        items.any((item) => item.value == value) ? value : null;
    return DropdownButtonFormField<T>(
      initialValue: resolvedValue,
      isExpanded: true,
      items: items,
      onChanged: items.isEmpty ? null : onChanged,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
      decoration: _fieldDecoration(context, label),
      dropdownColor: colors.cardSurface,
    );
  }
}

class _TokenTextField extends StatelessWidget {
  const _TokenTextField({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final int? minLines;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
      decoration: _fieldDecoration(context, label),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(child: _StrongText(label)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.brandPrimary,
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final String title;
  final String subtitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StrongText(title),
              const SizedBox(height: 3),
              _SmallText(subtitle),
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          badge!,
        ],
      ],
    );
  }
}

class _StrongText extends StatelessWidget {
  const _StrongText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _SmallText extends StatelessWidget {
  const _SmallText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _FeedbackText extends StatelessWidget {
  const _FeedbackText({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return const SizedBox.shrink();
    }
    return PokeMapBadge(
      label: message!,
      variant: PokeMapBadgeVariant.warning,
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  const _CompactEmptyState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StrongText(title),
            const SizedBox(height: 4),
            _SmallText(description),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, String label) {
  final colors = context.pokeMapColors;
  final radius = BorderRadius.circular(8);
  return InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: colors.controlSurface,
    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.controlBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.brandPrimaryBorder, width: 1.4),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.borderSubtle),
    ),
  );
}

T? _optionByKey<T>(
  List<T> options,
  String? key,
  String Function(T option) keyOf,
) {
  if (key == null) {
    return null;
  }
  for (final option in options) {
    if (keyOf(option) == key) {
      return option;
    }
  }
  return null;
}

WorldRuleSourcePickerOption _defaultSource(
  List<WorldRuleSourcePickerOption> options,
) {
  for (final option in options) {
    if (option.kind == WorldRuleSourceKind.fact) {
      return option;
    }
  }
  return options.first;
}

WorldRuleTargetPickerOption _defaultTarget(
  List<WorldRuleTargetPickerOption> options,
) {
  for (final option in options) {
    if (option.kind == WorldRuleTargetKind.mapEvent) {
      return option;
    }
  }
  return options.first;
}

WorldRuleEffectPickerOption _defaultEffect(
  List<WorldRuleEffectPickerOption> options,
) {
  for (final option in options) {
    if (option.effectKind == WorldRuleEffectKind.eventDisabled ||
        option.effectKind == WorldRuleEffectKind.entityHidden) {
      return option;
    }
  }
  return options.first;
}

String _sourceOptionKey(WorldRuleSourcePickerOption option) {
  return '${option.kind.name}:${option.predicate.name}:${option.sourceId}';
}

String _targetOptionKey(WorldRuleTargetPickerOption option) {
  return '${option.kind.name}:${option.mapId}:'
      '${option.entityId ?? ''}:${option.eventId ?? ''}';
}

String _effectOptionKey(WorldRuleEffectPickerOption option) {
  return option.effectKind.name;
}

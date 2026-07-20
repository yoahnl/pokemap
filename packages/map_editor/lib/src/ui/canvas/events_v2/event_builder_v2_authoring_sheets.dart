import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../application/use_cases/narrative_event_builder_v2_use_case.dart';
import '../../design_system/design_system.dart';

typedef EventBuilderV2CreationSubmit = Future<String?> Function(
  NarrativeEventBuilderV2CreationRequest request,
);

final class EventBuilderV2SourceChoice {
  const EventBuilderV2SourceChoice({
    required this.id,
    required this.label,
    required this.description,
    required this.source,
    required this.selectable,
    required this.groupLabel,
    required this.typeLabel,
    this.presentationKind,
    this.referenceState,
    this.unavailableReason,
  });

  final String id;
  final String label;
  final String description;
  final NarrativeEventSourceRef? source;
  final bool selectable;
  final String groupLabel;
  final String typeLabel;
  final NarrativeSpatialEventSourcePresentationKind? presentationKind;
  final NarrativeSpatialEventSourceReferenceState? referenceState;
  final String? unavailableReason;
}

List<EventBuilderV2SourceChoice> eventBuilderV2SourceChoices(
  NarrativeEventBuilderV2EditorSnapshot snapshot, {
  bool includeDecideLater = true,
}) {
  var index = 0;
  return [
    if (includeDecideLater)
      const EventBuilderV2SourceChoice(
        id: 'later',
        label: 'Décider plus tard',
        description: 'Conserver un brouillon sans déclencheur.',
        source: null,
        selectable: true,
        groupLabel: 'Brouillon',
        typeLabel: 'À configurer',
      ),
    for (final option in snapshot.spatialSources)
      EventBuilderV2SourceChoice(
        id: 'spatial_${index++}',
        label: option.humanLabel,
        description: option.humanDescription,
        source: option.source,
        selectable: option.selectable,
        groupLabel: option.mapLabel,
        typeLabel: option.sourceTypeLabel,
        presentationKind: option.presentationKind,
        referenceState: option.referenceState,
        unavailableReason: option.unavailableReason,
      ),
    for (final option in snapshot.outcomeSources)
      EventBuilderV2SourceChoice(
        id: 'outcome_${index++}',
        label: 'Résultat · ${option.outcomeLabel}',
        description: option.humanSourceSentence,
        source: option.outcome == null
            ? null
            : NarrativeEventSourceRef.outcomeReceived(option.outcome!),
        selectable: option.selectable,
        groupLabel: 'Résultats globaux',
        typeLabel: 'Résultat de Scene',
        unavailableReason: option.unavailableReason,
      ),
  ];
}

class EventBuilderV2CreationSheet extends StatefulWidget {
  const EventBuilderV2CreationSheet({
    super.key,
    required this.snapshot,
    required this.onSubmit,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final EventBuilderV2CreationSubmit onSubmit;

  @override
  State<EventBuilderV2CreationSheet> createState() =>
      _EventBuilderV2CreationSheetState();
}

class _EventBuilderV2CreationSheetState
    extends State<EventBuilderV2CreationSheet> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode(debugLabel: 'new event name');
  late final List<EventBuilderV2SourceChoice> _sources;
  String _sourceId = 'later';
  String _sceneId = 'later';
  String _reusePolicy = 'later';
  bool _submitted = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sources = eventBuilderV2SourceChoices(widget.snapshot);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  EventBuilderV2SourceChoice get _selectedSource =>
      _sources.firstWhere((choice) => choice.id == _sourceId);

  bool get _hasName => _nameController.text.trim().isNotEmpty;
  bool get _canPublish =>
      _hasName &&
      _selectedSource.source != null &&
      _selectedSource.selectable &&
      _sceneId != 'later' &&
      _reusePolicy != 'later';

  Future<void> _submit(bool publish) async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_hasName || (publish && !_canPublish)) return;
    setState(() => _saving = true);
    final error = await widget.onSubmit(
      NarrativeEventBuilderV2CreationRequest(
        name: _nameController.text.trim(),
        source: _selectedSource.source,
        sceneId: _sceneId == 'later' ? null : _sceneId,
        reusePolicy: switch (_reusePolicy) {
          'oneShot' => NarrativeEventReusePolicy.oneShot,
          'reusable' => NarrativeEventReusePolicy.reusable,
          _ => null,
        },
        publish: publish,
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final source = _selectedSource;
    return ListView(
      key: const ValueKey('event-builder-v2-creation-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapTextField(
          key: const ValueKey('event-builder-v2-create-name'),
          label: 'Nom de l’événement',
          controller: _nameController,
          focusNode: _nameFocusNode,
          autofocus: true,
          enabled: !_saving,
          hintText: 'Ex. Rencontre rival au port',
          errorText: _submitted && !_hasName
              ? 'Le nom de l’événement est obligatoire.'
              : null,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(false),
        ),
        const SizedBox(height: 14),
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Les éléments physiques appartiennent aux maps',
          message: 'Choisissez ici un élément déjà placé. Pour créer ou '
              'modifier un PNJ, un objet ou une zone, utilisez le Map Editor.',
        ),
        const SizedBox(height: 8),
        _EventBuilderV2SourcePicker(
          choices: _sources,
          selectedId: _sourceId,
          enabled: !_saving,
          onSelected: (value) => setState(() => _sourceId = value),
        ),
        if (!source.selectable && source.unavailableReason != null) ...[
          const SizedBox(height: 8),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Référence à réparer dans le Map Editor',
            message: source.unavailableReason!,
          ),
        ],
        const SizedBox(height: 14),
        PokeMapDropdownField<String>(
          label: 'Scene à jouer',
          value: _sceneId,
          enabled: !_saving,
          items: [
            const PokeMapDropdownItem(
              value: 'later',
              label: 'Décider plus tard',
            ),
            for (final entry in widget.snapshot.scenes)
              PokeMapDropdownItem(
                value: entry.scene.id,
                label: entry.scene.name,
              ),
          ],
          onChanged: (value) => setState(() => _sceneId = value),
        ),
        const SizedBox(height: 14),
        PokeMapDropdownField<String>(
          label: 'Réutilisation',
          value: _reusePolicy,
          enabled: !_saving,
          items: const [
            PokeMapDropdownItem(
              value: 'later',
              label: 'Décider plus tard',
            ),
            PokeMapDropdownItem(
              value: 'oneShot',
              label: 'Une seule fois',
            ),
            PokeMapDropdownItem(
              value: 'reusable',
              label: 'Réutilisable',
            ),
          ],
          onChanged: (value) => setState(() => _reusePolicy = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Enregistrement interrompu',
            message: _error!,
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            PokeMapButton(
              key: const ValueKey('event-builder-v2-save-draft'),
              onPressed: _saving ? null : () => _submit(false),
              isLoading: _saving,
              variant: PokeMapButtonVariant.secondary,
              child: const Text('Enregistrer le brouillon'),
            ),
            PokeMapButton(
              key: const ValueKey('event-builder-v2-publish-create'),
              onPressed: !_saving && _canPublish ? () => _submit(true) : null,
              variant: PokeMapButtonVariant.success,
              child: const Text('Publier désactivé'),
            ),
          ],
        ),
      ],
    );
  }
}

class EventBuilderV2SourceSheet extends StatefulWidget {
  const EventBuilderV2SourceSheet({
    super.key,
    required this.snapshot,
    required this.currentSource,
    required this.onSubmit,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final NarrativeEventSourceRef? currentSource;
  final Future<String?> Function(NarrativeEventSourceRef source) onSubmit;

  @override
  State<EventBuilderV2SourceSheet> createState() =>
      _EventBuilderV2SourceSheetState();
}

class _EventBuilderV2SourceSheetState extends State<EventBuilderV2SourceSheet> {
  late final List<EventBuilderV2SourceChoice> _sources;
  late String _sourceId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sources = eventBuilderV2SourceChoices(
      widget.snapshot,
      includeDecideLater: false,
    );
    _sourceId = _sources
            .where((choice) => choice.source == widget.currentSource)
            .map((choice) => choice.id)
            .firstOrNull ??
        _sources
            .where((choice) => choice.selectable && choice.source != null)
            .map((choice) => choice.id)
            .firstOrNull ??
        (_sources.isEmpty ? '' : _sources.first.id);
  }

  Future<void> _save() async {
    final selected =
        _sources.where((choice) => choice.id == _sourceId).firstOrNull;
    final source = selected?.source;
    if (source == null || selected?.selectable != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(source);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_sources.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucun déclencheur disponible',
        description: 'Placez d’abord un PNJ, un objet ou une zone dans le '
            'Map Editor, ou créez un résultat de Scene.',
        icon: Icon(CupertinoIcons.bolt_slash),
      );
    }
    final selected = _sources.firstWhere((choice) => choice.id == _sourceId);
    return Column(
      key: const ValueKey('event-builder-v2-source-sheet'),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            title: 'Sélection uniquement',
            message: 'L’Event Builder référence les éléments existants. '
                'La création, la position et la géométrie restent dans le '
                'Map Editor.',
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _EventBuilderV2SourcePicker(
                choices: _sources,
                selectedId: _sourceId,
                enabled: !_saving,
                onSelected: (value) => setState(() => _sourceId = value),
              ),
            ],
          ),
        ),
        if (!selected.selectable && selected.unavailableReason != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              title: 'À réparer dans le Map Editor',
              message: selected.unavailableReason!,
            ),
          ),
        ],
        if (_error != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              message: _error!,
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: PokeMapButton(
              onPressed: _saving || !selected.selectable ? null : _save,
              isLoading: _saving,
              child: const Text('Enregistrer le déclencheur'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Grouped, read-only projection of the canonical source catalog.
///
/// Cards with a broken reference deliberately have no tap handler. They stay
/// visible to explain the project state, but cannot leak an incompatible
/// trigger/source pair into an authoring command.
class _EventBuilderV2SourcePicker extends StatelessWidget {
  const _EventBuilderV2SourcePicker({
    required this.choices,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });

  final List<EventBuilderV2SourceChoice> choices;
  final String selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PokeMapEventSourcePicker(
      options: [
        for (final choice in choices)
          PokeMapEventSourcePickerOption(
            id: choice.id,
            label: choice.label,
            description: choice.description,
            groupLabel: choice.groupLabel,
            groupDescription: _groupDescription(choice),
            typeLabel: choice.typeLabel,
            kind: _sourcePickerKind(choice),
            state: _sourcePickerState(choice),
          ),
      ],
      selectedId: selectedId,
      enabled: enabled,
      optionKeyPrefix: 'event-builder-v2-source-choice-',
      onSelected: onSelected,
    );
  }
}

String _groupDescription(EventBuilderV2SourceChoice choice) {
  if (choice.source?.kind == NarrativeEventSourceKind.outcomeReceived) {
    return 'Déclencheurs non spatiaux produits par les Scenes.';
  }
  if (choice.source == null && choice.presentationKind == null) {
    return 'Enregistrer maintenant, compléter plus tard.';
  }
  return 'Sources physiques existantes de cette map.';
}

PokeMapEventSourcePickerKind _sourcePickerKind(
  EventBuilderV2SourceChoice choice,
) =>
    switch (choice.presentationKind) {
      NarrativeSpatialEventSourcePresentationKind.mapEntry =>
        PokeMapEventSourcePickerKind.mapEntry,
      NarrativeSpatialEventSourcePresentationKind.zone =>
        PokeMapEventSourcePickerKind.zone,
      NarrativeSpatialEventSourcePresentationKind.npc =>
        PokeMapEventSourcePickerKind.npc,
      NarrativeSpatialEventSourcePresentationKind.object =>
        PokeMapEventSourcePickerKind.object,
      NarrativeSpatialEventSourcePresentationKind.placedElement =>
        PokeMapEventSourcePickerKind.placedElement,
      NarrativeSpatialEventSourcePresentationKind.legacy =>
        PokeMapEventSourcePickerKind.legacy,
      null => choice.source?.kind == NarrativeEventSourceKind.outcomeReceived
          ? PokeMapEventSourcePickerKind.outcome
          : PokeMapEventSourcePickerKind.draft,
    };

PokeMapEventSourcePickerState _sourcePickerState(
  EventBuilderV2SourceChoice choice,
) =>
    switch (choice.referenceState) {
      NarrativeSpatialEventSourceReferenceState.ready =>
        PokeMapEventSourcePickerState.ready,
      NarrativeSpatialEventSourceReferenceState.needsMapRepair =>
        PokeMapEventSourcePickerState.needsMapRepair,
      NarrativeSpatialEventSourceReferenceState.notAttachable =>
        PokeMapEventSourcePickerState.notAttachable,
      NarrativeSpatialEventSourceReferenceState.legacyCompatibility =>
        PokeMapEventSourcePickerState.legacyCompatibility,
      null => choice.source == null
          ? PokeMapEventSourcePickerState.draft
          : PokeMapEventSourcePickerState.ready,
    };

class EventBuilderV2SceneSheet extends StatefulWidget {
  const EventBuilderV2SceneSheet({
    super.key,
    required this.snapshot,
    required this.currentSceneId,
    required this.onSubmit,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final String? currentSceneId;
  final Future<String?> Function(String? sceneId) onSubmit;

  @override
  State<EventBuilderV2SceneSheet> createState() =>
      _EventBuilderV2SceneSheetState();
}

class _EventBuilderV2SceneSheetState extends State<EventBuilderV2SceneSheet> {
  late String _sceneId = widget.currentSceneId ?? 'none';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(_sceneId == 'none' ? null : _sceneId);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final validSceneIds = widget.snapshot.scenes.map((entry) => entry.scene.id);
    if (_sceneId != 'none' && !validSceneIds.contains(_sceneId)) {
      _sceneId = 'none';
    }
    return ListView(
      key: const ValueKey('event-builder-v2-scene-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapDropdownField<String>(
          label: 'Scene à jouer',
          value: _sceneId,
          enabled: !_saving,
          items: [
            const PokeMapDropdownItem(
              value: 'none',
              label: 'Aucune Scene',
            ),
            for (final entry in widget.snapshot.scenes)
              PokeMapDropdownItem(
                value: entry.scene.id,
                label: entry.scene.name,
              ),
          ],
          onChanged: (value) => setState(() => _sceneId = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            child: const Text('Enregistrer la Scene'),
          ),
        ),
      ],
    );
  }
}

class EventBuilderV2ConditionsSheet extends StatefulWidget {
  const EventBuilderV2ConditionsSheet({
    super.key,
    required this.snapshot,
    required this.onSubmit,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final Future<String?> Function(NarrativeEventConditionExpression expression)
      onSubmit;

  @override
  State<EventBuilderV2ConditionsSheet> createState() =>
      _EventBuilderV2ConditionsSheetState();
}

class _EventBuilderV2ConditionsSheetState
    extends State<EventBuilderV2ConditionsSheet> {
  late String _mode =
      widget.snapshot.conditionExpression is NarrativeEventConditionAny
          ? 'any'
          : 'all';
  late final List<NarrativeEventConditionExpression> _clauses =
      switch (widget.snapshot.conditionExpression) {
    NarrativeEventConditionAll(:final children) => [...children],
    NarrativeEventConditionAny(:final children) => [...children],
    final expression => [expression],
  };
  String _kind = 'fact';
  String? _targetId;
  bool _expected = true;
  final _factValueController = TextEditingController();
  String? _loadedFactId;
  NarrativeFactOperator _factOperator = NarrativeFactOperator.equals;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _factValueController.dispose();
    super.dispose();
  }

  List<PokeMapDropdownItem<String>> get _targets => _kind == 'fact'
      ? [
          for (final entry in widget.snapshot.facts)
            PokeMapDropdownItem(
              value: entry.fact.id,
              label: entry.fact.label,
            ),
        ]
      : [
          for (final entry in widget.snapshot.events)
            if (entry.record.id != widget.snapshot.record?.id)
              PokeMapDropdownItem(
                value: entry.record.id,
                label: _recordName(entry.record),
              ),
        ];

  void _add() {
    final target = _targetId ?? _targets.firstOrNull?.value;
    if (target == null) return;
    final selectedFact = _factById(target);
    final factValue =
        selectedFact == null ? null : _factInputValue(selectedFact.valueKind);
    if (_kind == 'fact' && factValue == null) {
      setState(() => _error = 'Saisissez une valeur compatible avec le Fact.');
      return;
    }
    setState(() {
      _clauses.add(
        NarrativeEventConditionExpression.leaf(
          _kind == 'fact'
              ? NarrativeEventCondition.factValue(
                  target,
                  operator: _factOperator,
                  expectedValue: factValue!,
                )
              : NarrativeEventCondition.narrativeEventConsumed(
                  target,
                  _expected,
                ),
        ),
      );
    });
  }

  void _toggleExpectedValue(int index) {
    final clause = _clauses[index];
    final condition = _editableCondition(clause);
    if (condition == null) return;
    final updated = condition.whenTyped(
      fact: (factId, operator, expected) => NarrativeEventCondition.factValue(
        factId,
        operator: _inverseFactOperator(operator),
        expectedValue: expected,
      ),
      narrativeEventConsumed: (eventId, expected) =>
          NarrativeEventCondition.narrativeEventConsumed(eventId, !expected),
    );
    setState(() {
      _clauses[index] = clause is NarrativeEventConditionNot
          ? NarrativeEventConditionExpression.not(
              NarrativeEventConditionExpression.leaf(updated),
            )
          : NarrativeEventConditionExpression.leaf(updated);
    });
  }

  NarrativeFactDefinition? _factById(String factId) => widget.snapshot.facts
      .where((entry) => entry.fact.id == factId)
      .map((entry) => entry.fact)
      .firstOrNull;

  void _syncFactInput(NarrativeFactDefinition? fact) {
    if (_loadedFactId == fact?.id) return;
    _loadedFactId = fact?.id;
    _factOperator = NarrativeFactOperator.equals;
    _expected = fact?.valueKind == NarrativeValueKind.boolean
        ? fact!.initialValue.boolValue
        : true;
    _factValueController.text = switch (fact?.initialValue) {
      NarrativeValue(kind: NarrativeValueKind.integer) =>
        '${fact!.initialValue.intValue}',
      NarrativeValue(kind: NarrativeValueKind.string) =>
        fact!.initialValue.stringValue,
      _ => '',
    };
  }

  NarrativeValue? _factInputValue(NarrativeValueKind kind) {
    switch (kind) {
      case NarrativeValueKind.boolean:
        return NarrativeValue.boolean(_expected);
      case NarrativeValueKind.integer:
        final value = int.tryParse(_factValueController.text.trim());
        return value == null ? null : NarrativeValue.integer(value);
      case NarrativeValueKind.string:
        return NarrativeValue.string(_factValueController.text);
    }
  }

  void _toggleNegation(int index) {
    setState(() {
      final clause = _clauses[index];
      _clauses[index] = clause is NarrativeEventConditionNot
          ? clause.child
          : NarrativeEventConditionExpression.not(clause);
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final expression = _mode == 'any'
        ? NarrativeEventConditionExpression.any(_clauses)
        : NarrativeEventConditionExpression.all(_clauses);
    final error = await widget.onSubmit(expression);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final targets = _targets;
    final targetValue = targets.any((item) => item.value == _targetId)
        ? _targetId!
        : (targets.firstOrNull?.value ?? 'none');
    final selectedFact = _kind == 'fact' ? _factById(targetValue) : null;
    _syncFactInput(selectedFact);
    return ListView(
      key: const ValueKey('event-builder-v2-conditions-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapDropdownField<String>(
          key: const ValueKey('event-builder-v2-condition-mode'),
          label: 'Mode d’évaluation',
          value: _mode,
          enabled: !_saving,
          items: const [
            PokeMapDropdownItem(
              value: 'all',
              label: 'Toutes doivent être remplies',
            ),
            PokeMapDropdownItem(
              value: 'any',
              label: 'Au moins une doit être remplie',
            ),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 8),
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Groupes logiques bornés',
          message: 'Chaque ligne est une clause. Inversez une clause avec NON; '
              'les groupes imbriqués existants sont conservés.',
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < _clauses.length; index++) ...[
          PokeMapCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _expressionClauseLabel(widget.snapshot, _clauses[index]),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 2,
                    children: [
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-move-condition-up-$index',
                        ),
                        onPressed: index == 0
                            ? null
                            : () => setState(() {
                                  final clause = _clauses.removeAt(index);
                                  _clauses.insert(index - 1, clause);
                                }),
                        icon: const Icon(CupertinoIcons.arrow_up),
                        tooltip: 'Monter la condition',
                        size: 28,
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-move-condition-down-$index',
                        ),
                        onPressed: index == _clauses.length - 1
                            ? null
                            : () => setState(() {
                                  final clause = _clauses.removeAt(index);
                                  _clauses.insert(index + 1, clause);
                                }),
                        icon: const Icon(CupertinoIcons.arrow_down),
                        tooltip: 'Descendre la condition',
                        size: 28,
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-toggle-condition-$index',
                        ),
                        onPressed: () => _toggleExpectedValue(index),
                        icon: const Icon(CupertinoIcons.arrow_2_circlepath),
                        tooltip: 'Inverser la valeur attendue',
                        size: 28,
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-negate-condition-$index',
                        ),
                        onPressed: () => _toggleNegation(index),
                        icon: const Icon(CupertinoIcons.exclamationmark),
                        tooltip: 'Ajouter ou retirer NON',
                        size: 28,
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-delete-condition-$index',
                        ),
                        onPressed: () =>
                            setState(() => _clauses.removeAt(index)),
                        icon: const Icon(CupertinoIcons.delete),
                        tooltip: 'Supprimer la condition',
                        variant: PokeMapIconButtonVariant.danger,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 8),
        PokeMapDropdownField<String>(
          label: 'Type de condition',
          value: _kind,
          enabled: !_saving,
          items: const [
            PokeMapDropdownItem(value: 'fact', label: 'Fact projet'),
            PokeMapDropdownItem(
              value: 'event',
              label: 'Événement déjà consommé',
            ),
          ],
          onChanged: (value) => setState(() {
            _kind = value;
            _targetId = null;
            _loadedFactId = null;
          }),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<String>(
          label: 'Élément à vérifier',
          value: targetValue,
          enabled: !_saving && targets.isNotEmpty,
          items: targets.isEmpty
              ? const [
                  PokeMapDropdownItem(
                    value: 'none',
                    label: 'Aucun élément disponible',
                  ),
                ]
              : targets,
          onChanged: (value) => setState(() {
            _targetId = value;
            _loadedFactId = null;
          }),
        ),
        const SizedBox(height: 10),
        if (selectedFact != null) ...[
          PokeMapDropdownField<NarrativeFactOperator>(
            key: const ValueKey('event-builder-v2-fact-operator'),
            label: 'Opérateur',
            value: _factOperator,
            enabled: !_saving,
            items: [
              for (final operator in selectedFact.valueKind.compatibleOperators)
                PokeMapDropdownItem(
                  value: operator,
                  label: _narrativeFactOperatorLabel(operator),
                ),
            ],
            onChanged: (value) => setState(() => _factOperator = value),
          ),
          const SizedBox(height: 10),
          if (selectedFact.valueKind == NarrativeValueKind.boolean)
            PokeMapDropdownField<bool>(
              key: const ValueKey('event-builder-v2-fact-bool-value'),
              label: 'Valeur attendue',
              value: _expected,
              enabled: !_saving,
              items: const [
                PokeMapDropdownItem(value: true, label: 'Vrai'),
                PokeMapDropdownItem(value: false, label: 'Faux'),
              ],
              onChanged: (value) => setState(() => _expected = value),
            )
          else
            PokeMapTextField(
              key: const ValueKey('event-builder-v2-fact-value'),
              label: selectedFact.valueKind == NarrativeValueKind.integer
                  ? 'Valeur entière attendue'
                  : 'Texte attendu',
              controller: _factValueController,
              enabled: !_saving,
              onChanged: (_) => setState(() {}),
            ),
        ] else
          PokeMapDropdownField<bool>(
            label: 'Valeur attendue',
            value: _expected,
            enabled: !_saving,
            items: const [
              PokeMapDropdownItem(value: true, label: 'Vrai'),
              PokeMapDropdownItem(value: false, label: 'Faux'),
            ],
            onChanged: (value) => setState(() => _expected = value),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: PokeMapButton(
            key: const ValueKey('event-builder-v2-add-condition'),
            onPressed: !_saving && targets.isNotEmpty ? _add : null,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.add),
            child: const Text('Ajouter à la liste'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const ValueKey('event-builder-v2-save-conditions'),
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            child: const Text('Enregistrer les conditions'),
          ),
        ),
      ],
    );
  }
}

final class EventBuilderV2BehaviorUpdate {
  const EventBuilderV2BehaviorUpdate({
    required this.name,
    required this.reusePolicy,
    required this.resetPolicy,
    required this.priority,
    required this.order,
  });

  final String name;
  final NarrativeEventReusePolicy? reusePolicy;
  final NarrativeEventResetPolicy resetPolicy;
  final int priority;
  final int order;
}

class EventBuilderV2BehaviorSheet extends StatefulWidget {
  const EventBuilderV2BehaviorSheet({
    super.key,
    required this.record,
    required this.onSave,
    required this.onPublish,
    required this.onSetEnabled,
    this.outcomeSources = const [],
  });

  final NarrativeEventRecord record;
  final Future<String?> Function(EventBuilderV2BehaviorUpdate update) onSave;
  final Future<String?> Function() onPublish;
  final Future<String?> Function(bool enabled) onSetEnabled;
  final List<NarrativeOutcomeEventSourceOption> outcomeSources;

  @override
  State<EventBuilderV2BehaviorSheet> createState() =>
      _EventBuilderV2BehaviorSheetState();
}

class _EventBuilderV2BehaviorSheetState
    extends State<EventBuilderV2BehaviorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: _recordName(widget.record),
  );
  late final TextEditingController _priorityController = TextEditingController(
    text: _recordPriority(widget.record).toString(),
  );
  late final TextEditingController _orderController = TextEditingController(
    text: _recordOrder(widget.record).toString(),
  );
  late String _reuse = switch (_recordReuse(widget.record)) {
    NarrativeEventReusePolicy.oneShot => 'oneShot',
    NarrativeEventReusePolicy.reusable => 'reusable',
    null => 'later',
  };
  late final List<({String id, String label, NarrativeOutcomeRef outcome})>
      _outcomes = [
    for (var index = 0; index < widget.outcomeSources.length; index++)
      if (widget.outcomeSources[index].outcome case final outcome?)
        (
          id: 'outcome_$index',
          label:
              '${widget.outcomeSources[index].producerLabel} · ${widget.outcomeSources[index].outcomeLabel}',
          outcome: outcome,
        ),
  ];
  late String _reset = switch (_recordReset(widget.record)) {
    NarrativeEventResetOnMapReentry() => 'mapReentry',
    NarrativeEventResetOnOutcomeReceived() => 'outcome',
    _ => 'never',
  };
  late String? _resetOutcomeId = switch (_recordReset(widget.record)) {
    NarrativeEventResetOnOutcomeReceived(:final outcome) => _outcomes
        .where((entry) => entry.outcome == outcome)
        .map((entry) => entry.id)
        .firstOrNull,
    _ => null,
  };

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _priorityController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _perform(Future<String?> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final priority = int.tryParse(_priorityController.text.trim());
    final order = int.tryParse(_orderController.text.trim());
    if (_nameController.text.trim().isEmpty ||
        priority == null ||
        order == null) {
      setState(() => _error = 'Vérifiez le nom, la priorité et l’ordre.');
      return;
    }
    final selectedOutcome =
        _outcomes.where((entry) => entry.id == _resetOutcomeId).firstOrNull;
    if (_reset == 'outcome' && selectedOutcome == null) {
      setState(() => _error = 'Choisissez un résultat qualifié à recevoir.');
      return;
    }
    await _perform(
      () => widget.onSave(
        EventBuilderV2BehaviorUpdate(
          name: _nameController.text.trim(),
          reusePolicy: switch (_reuse) {
            'oneShot' => NarrativeEventReusePolicy.oneShot,
            'reusable' => NarrativeEventReusePolicy.reusable,
            _ => null,
          },
          resetPolicy: switch (_reset) {
            'mapReentry' => const NarrativeEventResetPolicy.onMapReentry(),
            'outcome' => NarrativeEventResetPolicy.onOutcomeReceived(
                selectedOutcome!.outcome,
              ),
            _ => const NarrativeEventResetPolicy.never(),
          },
          priority: priority,
          order: order,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = widget.record.draftOrNull != null;
    final enabled = widget.record.enabledOrNull ?? false;
    return ListView(
      key: const ValueKey('event-builder-v2-behavior-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapTextField(
          label: 'Nom',
          controller: _nameController,
          enabled: !_saving,
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          label: 'Réutilisation',
          value: _reuse,
          enabled: !_saving,
          items: const [
            PokeMapDropdownItem(
              value: 'later',
              label: 'Décider plus tard',
            ),
            PokeMapDropdownItem(
              value: 'oneShot',
              label: 'Une seule fois',
            ),
            PokeMapDropdownItem(
              value: 'reusable',
              label: 'Réutilisable',
            ),
          ],
          onChanged: (value) => setState(() {
            _reuse = value;
            if (value != 'oneShot') _reset = 'never';
          }),
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          key: const ValueKey('event-builder-v2-reset-policy'),
          label: 'Réarmement',
          value: _reset,
          enabled: !_saving && _reuse == 'oneShot',
          items: [
            const PokeMapDropdownItem(
              value: 'never',
              label: 'Jamais',
            ),
            if (_recordSource(widget.record)?.kind !=
                NarrativeEventSourceKind.outcomeReceived)
              const PokeMapDropdownItem(
                value: 'mapReentry',
                label: 'À la vraie réentrée sur la map',
              ),
            if (_outcomes.isNotEmpty)
              const PokeMapDropdownItem(
                value: 'outcome',
                label: 'À la réception d’un résultat',
              ),
          ],
          onChanged: (value) => setState(() => _reset = value),
        ),
        if (_reset == 'outcome') ...[
          const SizedBox(height: 12),
          PokeMapDropdownField<String>(
            key: const ValueKey('event-builder-v2-reset-outcome'),
            label: 'Résultat qualifié',
            value: _resetOutcomeId ?? _outcomes.firstOrNull?.id ?? 'none',
            enabled: !_saving && _reuse == 'oneShot',
            items: _outcomes.isEmpty
                ? const [
                    PokeMapDropdownItem(
                      value: 'none',
                      label: 'Résultat référencé indisponible',
                    ),
                  ]
                : [
                    for (final entry in _outcomes)
                      PokeMapDropdownItem(value: entry.id, label: entry.label),
                  ],
            onChanged: (value) => setState(() => _resetOutcomeId = value),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PokeMapTextField(
                label: 'Priorité',
                controller: _priorityController,
                enabled: !_saving,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapTextField(
                label: 'Ordre d’évaluation',
                controller: _orderController,
                enabled: !_saving,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PokeMapButton(
              onPressed: _saving ? null : _save,
              isLoading: _saving,
              child: const Text('Enregistrer'),
            ),
            if (isDraft)
              PokeMapButton(
                onPressed: _saving ? null : () => _perform(widget.onPublish),
                variant: PokeMapButtonVariant.success,
                child: const Text('Publier désactivé'),
              )
            else
              PokeMapButton(
                onPressed: _saving
                    ? null
                    : () => _perform(() => widget.onSetEnabled(!enabled)),
                variant: enabled
                    ? PokeMapButtonVariant.danger
                    : PokeMapButtonVariant.success,
                child: Text(enabled ? 'Désactiver' : 'Activer'),
              ),
          ],
        ),
      ],
    );
  }
}

String _recordName(NarrativeEventRecord record) =>
    record.draftOrNull?.name ?? record.definitionOrNull!.name;

NarrativeFactOperator _inverseFactOperator(NarrativeFactOperator operator) =>
    switch (operator) {
      NarrativeFactOperator.equals => NarrativeFactOperator.notEquals,
      NarrativeFactOperator.notEquals => NarrativeFactOperator.equals,
      NarrativeFactOperator.greaterThan =>
        NarrativeFactOperator.lessThanOrEqual,
      NarrativeFactOperator.greaterThanOrEqual =>
        NarrativeFactOperator.lessThan,
      NarrativeFactOperator.lessThan =>
        NarrativeFactOperator.greaterThanOrEqual,
      NarrativeFactOperator.lessThanOrEqual =>
        NarrativeFactOperator.greaterThan,
    };

String _narrativeFactOperatorLabel(NarrativeFactOperator operator) =>
    switch (operator) {
      NarrativeFactOperator.equals => 'est égal à',
      NarrativeFactOperator.notEquals => 'est différent de',
      NarrativeFactOperator.greaterThan => 'est supérieur à',
      NarrativeFactOperator.greaterThanOrEqual => 'est supérieur ou égal à',
      NarrativeFactOperator.lessThan => 'est inférieur à',
      NarrativeFactOperator.lessThanOrEqual => 'est inférieur ou égal à',
    };

String _narrativeValueLabel(NarrativeValue value) => switch (value.kind) {
      NarrativeValueKind.boolean => value.boolValue ? 'Vrai' : 'Faux',
      NarrativeValueKind.integer => '${value.intValue}',
      NarrativeValueKind.string => '“${value.stringValue}”',
    };

int _recordPriority(NarrativeEventRecord record) =>
    record.draftOrNull?.priority ?? record.definitionOrNull!.priority;

int _recordOrder(NarrativeEventRecord record) =>
    record.draftOrNull?.order ?? record.definitionOrNull!.order;

NarrativeEventReusePolicy? _recordReuse(NarrativeEventRecord record) =>
    record.draftOrNull?.reusePolicy ?? record.definitionOrNull?.reusePolicy;

NarrativeEventResetPolicy _recordReset(NarrativeEventRecord record) =>
    record.draftOrNull?.resetPolicy ??
    record.definitionOrNull?.resetPolicy ??
    const NarrativeEventResetPolicy.never();

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) =>
    record.draftOrNull?.source ?? record.definitionOrNull?.source;

String _conditionLabel(
  NarrativeEventBuilderV2EditorSnapshot snapshot,
  NarrativeEventCondition condition,
) {
  return condition.whenTyped(
    fact: (factId, operator, expected) {
      final label = snapshot.facts
              .where((entry) => entry.fact.id == factId)
              .map((entry) => entry.fact.label)
              .firstOrNull ??
          'Fact indisponible';
      return '$label ${_narrativeFactOperatorLabel(operator)} '
          '${_narrativeValueLabel(expected)}';
    },
    narrativeEventConsumed: (eventId, expected) {
      final label = snapshot.events
              .where((entry) => entry.record.id == eventId)
              .map((entry) => _recordName(entry.record))
              .firstOrNull ??
          'Événement indisponible';
      return '$label déjà joué = ${expected ? 'Vrai' : 'Faux'}';
    },
  );
}

NarrativeEventCondition? _editableCondition(
  NarrativeEventConditionExpression expression,
) {
  return switch (expression) {
    NarrativeEventConditionLeaf(:final condition) => condition,
    NarrativeEventConditionNot(
      child: NarrativeEventConditionLeaf(:final condition),
    ) =>
      condition,
    _ => null,
  };
}

String _expressionClauseLabel(
  NarrativeEventBuilderV2EditorSnapshot snapshot,
  NarrativeEventConditionExpression expression,
) {
  return switch (expression) {
    NarrativeEventConditionLeaf(:final condition) =>
      _conditionLabel(snapshot, condition),
    NarrativeEventConditionNot(:final child) =>
      'NON (${_expressionClauseLabel(snapshot, child)})',
    NarrativeEventConditionAll(:final children) =>
      'Toutes (${children.length} clause${children.length == 1 ? '' : 's'})',
    NarrativeEventConditionAny(:final children) =>
      'Au moins une (${children.length} clause${children.length == 1 ? '' : 's'})',
  };
}

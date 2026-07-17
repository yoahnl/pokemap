import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  });

  final String id;
  final String label;
  final String description;
  final NarrativeEventSourceRef? source;
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
      ),
    for (final option in snapshot.spatialSources)
      EventBuilderV2SourceChoice(
        id: 'spatial_${index++}',
        label: '${option.sourceTypeLabel} · ${option.humanLabel}',
        description: '${option.humanDescription} · ${option.mapLabel}',
        source: option.source,
      ),
    for (final option in snapshot.outcomeSources)
      EventBuilderV2SourceChoice(
        id: 'outcome_${index++}',
        label: 'Résultat · ${option.outcomeLabel}',
        description: option.humanSourceSentence,
        source: option.outcome == null
            ? null
            : NarrativeEventSourceRef.outcomeReceived(option.outcome!),
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
        PokeMapDropdownField<String>(
          label: 'Déclencheur existant',
          value: _sourceId,
          enabled: !_saving,
          items: [
            for (final choice in _sources)
              PokeMapDropdownItem(value: choice.id, label: choice.label),
          ],
          onChanged: (value) => setState(() => _sourceId = value),
        ),
        const SizedBox(height: 6),
        PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: source.label,
          message: source.description,
        ),
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
        (_sources.isEmpty ? '' : _sources.first.id);
  }

  Future<void> _save() async {
    final selected =
        _sources.where((choice) => choice.id == _sourceId).firstOrNull;
    final source = selected?.source;
    if (source == null) return;
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
        description:
            'Placez d’abord un PNJ ou une zone sur une map, ou créez un outcome.',
        icon: Icon(CupertinoIcons.bolt_slash),
      );
    }
    final selected = _sources.firstWhere((choice) => choice.id == _sourceId);
    return ListView(
      key: const ValueKey('event-builder-v2-source-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapDropdownField<String>(
          label: 'Déclencheur existant',
          value: _sourceId,
          enabled: !_saving,
          items: [
            for (final choice in _sources)
              PokeMapDropdownItem(value: choice.id, label: choice.label),
          ],
          onChanged: (value) => setState(() => _sourceId = value),
        ),
        const SizedBox(height: 8),
        PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: selected.label,
          message: selected.description,
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
            child: const Text('Enregistrer le déclencheur'),
          ),
        ),
      ],
    );
  }
}

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
  final Future<String?> Function(List<NarrativeEventCondition> conditions)
      onSubmit;

  @override
  State<EventBuilderV2ConditionsSheet> createState() =>
      _EventBuilderV2ConditionsSheetState();
}

class _EventBuilderV2ConditionsSheetState
    extends State<EventBuilderV2ConditionsSheet> {
  late final List<NarrativeEventCondition> _conditions = [
    ...widget.snapshot.conditions,
  ];
  String _kind = 'fact';
  String? _targetId;
  bool _expected = true;
  bool _saving = false;
  String? _error;

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
    setState(() {
      _conditions.add(
        _kind == 'fact'
            ? NarrativeEventCondition.fact(target, _expected)
            : NarrativeEventCondition.narrativeEventConsumed(
                target,
                _expected,
              ),
      );
    });
  }

  void _toggleExpectedValue(int index) {
    final condition = _conditions[index];
    final updated = condition.when(
      fact: (factId, expected) =>
          NarrativeEventCondition.fact(factId, !expected),
      narrativeEventConsumed: (eventId, expected) =>
          NarrativeEventCondition.narrativeEventConsumed(eventId, !expected),
    );
    setState(() => _conditions[index] = updated);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(List.unmodifiable(_conditions));
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
    return ListView(
      key: const ValueKey('event-builder-v2-conditions-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Toutes les conditions doivent être remplies, dans l’ordre affiché.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < _conditions.length; index++) ...[
          PokeMapCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _conditionLabel(widget.snapshot, _conditions[index]),
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
                                  final condition = _conditions.removeAt(index);
                                  _conditions.insert(index - 1, condition);
                                }),
                        icon: const Icon(CupertinoIcons.arrow_up),
                        tooltip: 'Monter la condition',
                        size: 28,
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'event-builder-v2-move-condition-down-$index',
                        ),
                        onPressed: index == _conditions.length - 1
                            ? null
                            : () => setState(() {
                                  final condition = _conditions.removeAt(index);
                                  _conditions.insert(index + 1, condition);
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
                          'event-builder-v2-delete-condition-$index',
                        ),
                        onPressed: () =>
                            setState(() => _conditions.removeAt(index)),
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
          onChanged: (value) => setState(() => _targetId = value),
        ),
        const SizedBox(height: 10),
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
    required this.priority,
    required this.order,
  });

  final String name;
  final NarrativeEventReusePolicy? reusePolicy;
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
  });

  final NarrativeEventRecord record;
  final Future<String?> Function(EventBuilderV2BehaviorUpdate update) onSave;
  final Future<String?> Function() onPublish;
  final Future<String?> Function(bool enabled) onSetEnabled;

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
    await _perform(
      () => widget.onSave(
        EventBuilderV2BehaviorUpdate(
          name: _nameController.text.trim(),
          reusePolicy: switch (_reuse) {
            'oneShot' => NarrativeEventReusePolicy.oneShot,
            'reusable' => NarrativeEventReusePolicy.reusable,
            _ => null,
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
          onChanged: (value) => setState(() => _reuse = value),
        ),
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

int _recordPriority(NarrativeEventRecord record) =>
    record.draftOrNull?.priority ?? record.definitionOrNull!.priority;

int _recordOrder(NarrativeEventRecord record) =>
    record.draftOrNull?.order ?? record.definitionOrNull!.order;

NarrativeEventReusePolicy? _recordReuse(NarrativeEventRecord record) =>
    record.draftOrNull?.reusePolicy ?? record.definitionOrNull?.reusePolicy;

String _conditionLabel(
  NarrativeEventBuilderV2EditorSnapshot snapshot,
  NarrativeEventCondition condition,
) {
  return condition.when(
    fact: (factId, expected) {
      final label = snapshot.facts
              .where((entry) => entry.fact.id == factId)
              .map((entry) => entry.fact.label)
              .firstOrNull ??
          'Fact indisponible';
      return '$label = ${expected ? 'Vrai' : 'Faux'}';
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

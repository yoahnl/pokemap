import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

class SceneConditionForm extends StatefulWidget {
  const SceneConditionForm({
    super.key,
    required this.project,
    required this.current,
    required this.onApply,
  });
  final ProjectManifest project;
  final SceneConditionPayload current;
  final ValueChanged<SceneConditionSource> onApply;
  @override
  State<SceneConditionForm> createState() => _SceneConditionFormState();
}

class _SceneConditionFormState extends State<SceneConditionForm> {
  static const families = {
    'fact': 'État du monde',
    'storyStepCompletion': 'Étape d’histoire',
    'consumedEvent': 'Interaction déjà jouée',
  };
  static const operators = {
    'equals': 'Est égal à',
    'notEquals': 'Est différent de',
    'greaterThan': 'Est supérieur à',
    'greaterThanOrEqual': 'Est supérieur ou égal à',
    'lessThan': 'Est inférieur à',
    'lessThanOrEqual': 'Est inférieur ou égal à',
  };
  String _family = 'fact';
  String? _id;
  NarrativeFactOperator _operator = NarrativeFactOperator.equals;
  bool _boolean = true;
  String _text = '';
  bool _unsupported = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(SceneConditionForm old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _reset();
  }

  void _reset() {
    final source = widget.current.conditionSource;
    _family = source?.sourceKind.name ?? 'fact';
    _id = source?.sourceId;
    _operator = NarrativeFactOperator.equals;
    _boolean = true;
    _text = '';
    _unsupported = source != null && !families.containsKey(_family);
    if (_unsupported || source == null) return;
    if (_family == 'fact') {
      try {
        _operator = source.resolvedFactOperator;
        final expected = source.resolvedExpectedFactValue;
        _boolean = expected.kind == NarrativeValueKind.boolean
            ? expected.boolValue
            : true;
        _text = expected.kind == NarrativeValueKind.boolean
            ? ''
            : '${expected.toJson()}';
      } catch (_) {
        _unsupported = true;
      }
    } else {
      _boolean = _family == 'storyStepCompletion'
          ? source.value == SceneConditionValues.completed
          : source.operator != SceneConditionOperator.isFalse;
    }
  }

  Map<String, String> get _references => switch (_family) {
    'fact' => {for (final value in widget.project.facts) value.id: value.label},
    'storyStepCompletion' => {
      for (final story in widget.project.storylines)
        for (final chapter in story.chapters)
          for (final step in chapter.steps)
            step.id: '${story.title} · ${step.title}',
    },
    'consumedEvent' => {
      for (final record
          in widget.project.eventRegistry?.records ?? <NarrativeEventRecord>[])
        record.id:
            record.definitionOrNull?.name ??
            record.draftOrNull?.name ??
            record.id,
    },
    _ => {},
  };

  NarrativeFactDefinition? get _fact =>
      widget.project.facts.where((fact) => fact.id == _id).firstOrNull;

  SceneConditionSource? get _prepared {
    final id = _id;
    if (_unsupported || id == null || !_references.containsKey(id)) return null;
    final existing = widget.current.conditionSource;
    final debug =
        existing?.sourceId == id && existing?.sourceKind.name == _family
        ? existing?.debugTechnicalLabel
        : null;
    if (_family != 'fact') {
      return SceneConditionSource(
        sourceKind: SceneConditionSourceKind.values.byName(_family),
        sourceId: id,
        operator: _family == 'storyStepCompletion'
            ? SceneConditionOperator.equals
            : _boolean
            ? SceneConditionOperator.isTrue
            : SceneConditionOperator.isFalse,
        value: _family == 'storyStepCompletion'
            ? _boolean
                  ? SceneConditionValues.completed
                  : SceneConditionValues.notCompleted
            : null,
        label: _references[id],
        debugTechnicalLabel: debug,
      );
    }
    final fact = _fact;
    if (fact == null ||
        !fact.valueKind.compatibleOperators.contains(_operator)) {
      return null;
    }
    try {
      final value = switch (fact.valueKind) {
        NarrativeValueKind.boolean => NarrativeValue.boolean(_boolean),
        NarrativeValueKind.integer => NarrativeValue.integer(int.parse(_text)),
        NarrativeValueKind.string => NarrativeValue.string(_text),
      };
      return SceneConditionSource.factValue(
        factId: id,
        operator: _operator,
        expectedValue: value,
        label: fact.label,
        debugTechnicalLabel: debug,
      );
    } catch (_) {
      return null;
    }
  }

  void _selectReference(String id) {
    setState(() {
      _id = id;
      _unsupported = false;
      _operator = NarrativeFactOperator.equals;
      final value = _family == 'fact' ? _fact?.initialValue : null;
      _boolean = value?.kind == NarrativeValueKind.boolean
          ? value!.boolValue
          : true;
      _text = value == null || value.kind == NarrativeValueKind.boolean
          ? ''
          : '${value.toJson()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final fact = _family == 'fact' ? _fact : null;
    final references = _references;
    final source = _prepared;
    final current = widget.current.conditionSource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_unsupported) ...[
          StudioNotice(
            'Condition avancée conservée : ${current?.label ?? widget.current.conditionLabel ?? current?.sourceId ?? 'référence existante'}. Pour la remplacer, choisissez une source puis appliquez explicitement.',
          ),
          const SizedBox(height: 12),
        ],
        StudioSelect(
          label: 'Source de la condition',
          value: _family,
          options: families,
          onChanged: (value) => setState(() {
            _family = value;
            _id = null;
            _unsupported = false;
          }),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Référence',
          value: _id,
          options: references,
          onChanged: _selectReference,
        ),
        if (references.isEmpty) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'Aucune référence disponible dans ce projet. La condition actuelle reste conservée.',
          ),
        ],
        const SizedBox(height: 12),
        if (fact != null) ...[
          StudioSelect(
            label: 'Comparaison',
            value: _operator.name,
            options: {
              for (final value in fact.valueKind.compatibleOperators)
                value.name: operators[value.name]!,
            },
            onChanged: (value) => setState(
              () => _operator = NarrativeFactOperator.values.byName(value),
            ),
          ),
          const SizedBox(height: 12),
          if (fact.valueKind == NarrativeValueKind.boolean)
            StudioSelect(
              label: 'Valeur attendue',
              value: '$_boolean',
              options: const {'true': 'Oui', 'false': 'Non'},
              onChanged: (value) => setState(() => _boolean = value == 'true'),
            )
          else
            StudioDraftField(
              label: fact.valueKind == NarrativeValueKind.integer
                  ? 'Nombre entier attendu'
                  : 'Texte attendu',
              value: _text,
              onChanged: (value) => setState(() => _text = value),
            ),
          if (source == null && !_unsupported)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: StudioNotice(
                'Saisissez une valeur compatible avec cet état.',
                isError: true,
              ),
            ),
        ] else if (_id != null && references.containsKey(_id))
          StudioSelect(
            label: _family == 'storyStepCompletion'
                ? 'État de l’étape'
                : 'Déjà jouée',
            value: '$_boolean',
            options: _family == 'storyStepCompletion'
                ? const {'true': 'Terminée', 'false': 'Non terminée'}
                : const {'true': 'Oui', 'false': 'Non'},
            onChanged: (value) => setState(() => _boolean = value == 'true'),
          ),
        const SizedBox(height: 12),
        StudioButton(
          label: 'Appliquer la condition',
          onPressed: source == null
              ? null
              : () {
                  final latest = _prepared;
                  if (latest != null) widget.onApply(latest);
                },
        ),
        const SizedBox(height: 8),
        const Text('Oui : condition remplie\nNon : condition non remplie'),
      ],
    );
  }
}

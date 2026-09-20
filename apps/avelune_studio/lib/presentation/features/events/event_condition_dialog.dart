import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'event_condition_labels.dart';
import 'event_labels.dart';

Future<NarrativeEventCondition?> chooseEventCondition(
  BuildContext context, {
  required List<NarrativeFactDefinition> facts,
  required List<NarrativeEventRecord> records,
  NarrativeEventCondition? initial,
}) => showDialog<NarrativeEventCondition>(
  context: context,
  builder: (_) =>
      _ConditionDialog(facts: facts, records: records, initial: initial),
);

class _ConditionDialog extends StatefulWidget {
  const _ConditionDialog({
    required this.facts,
    required this.records,
    this.initial,
  });
  final List<NarrativeFactDefinition> facts;
  final List<NarrativeEventRecord> records;
  final NarrativeEventCondition? initial;
  @override
  State<_ConditionDialog> createState() => _ConditionDialogState();
}

class _ConditionDialogState extends State<_ConditionDialog> {
  String _kind = 'fact';
  String? _id;
  NarrativeFactOperator _operator = NarrativeFactOperator.equals;
  bool _boolean = true;
  final _text = TextEditingController();
  String? _error;
  NarrativeFactDefinition? get _fact =>
      widget.facts.where((f) => f.id == _id).firstOrNull;
  @override
  void initState() {
    super.initState();
    widget.initial?.whenTyped<void>(
      fact: (id, operator, value) {
        _id = id;
        _operator = operator;
        if (value.kind == NarrativeValueKind.boolean) {
          _boolean = value.boolValue;
        } else {
          _text.text = value.toJson().toString();
        }
      },
      narrativeEventConsumed: (id, expected) {
        _kind = 'event';
        _id = id;
        _boolean = expected;
      },
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _accept() {
    try {
      final id = _id;
      if (id == null) throw StateError('Choisissez une référence.');
      final fact = _fact;
      final value = switch (fact?.valueKind) {
        NarrativeValueKind.integer => NarrativeValue.integer(
          int.parse(_text.text),
        ),
        NarrativeValueKind.string => NarrativeValue.string(_text.text),
        _ => NarrativeValue.boolean(_boolean),
      };
      if (_kind == 'fact' && fact == null) {
        throw StateError('Cet état est introuvable.');
      }
      Navigator.pop(
        context,
        _kind == 'event'
            ? NarrativeEventCondition.narrativeEventConsumed(id, _boolean)
            : NarrativeEventCondition.factValue(
                id,
                operator: _operator,
                expectedValue: value,
              ),
      );
    } catch (_) {
      setState(
        () => _error =
            'Choisissez une référence et une valeur compatible (nombre entier attendu si numérique).',
      );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Condition de déclenchement'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioSelect(
              label: 'Condition sur',
              value: _kind,
              options: const {
                'fact': 'Un état du monde',
                'event': 'Un événement déjà joué',
              },
              onChanged: (value) => setState(() {
                _kind = value;
                _id = null;
                _operator = NarrativeFactOperator.equals;
              }),
            ),
            const SizedBox(height: 16),
            StudioSelect(
              label: _kind == 'fact' ? 'État' : 'Événement',
              value: _id,
              options: _kind == 'fact'
                  ? {for (final f in widget.facts) f.id: '${f.label} · ${f.id}'}
                  : {
                      for (final r in widget.records)
                        r.id: '${eventName(r)} · ${r.id}',
                    },
              onChanged: (value) => setState(() {
                _id = value;
                _operator = NarrativeFactOperator.equals;
              }),
            ),
            if (_kind == 'fact' && _fact == null)
              const Text(
                'Les états se créent dans Histoire. Aucun état n’est créé ici.',
              ),
            const SizedBox(height: 16),
            if (_kind == 'fact' && _fact != null) ...[
              StudioSelect(
                label: 'Comparaison',
                value: _operator.name,
                options: {
                  for (final op in _fact!.valueKind.compatibleOperators)
                    op.name: eventOperatorLabel(op),
                },
                onChanged: (value) => setState(
                  () => _operator = NarrativeFactOperator.values.byName(value),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_kind == 'event' ||
                _fact?.valueKind == NarrativeValueKind.boolean)
              StudioSelect(
                label: _kind == 'event' ? 'Déjà joué' : 'Valeur attendue',
                value: _boolean.toString(),
                options: const {'true': 'Oui', 'false': 'Non'},
                onChanged: (value) =>
                    setState(() => _boolean = value == 'true'),
              )
            else if (_fact != null)
              TextField(
                controller: _text,
                decoration: InputDecoration(
                  labelText: _fact!.valueKind == NarrativeValueKind.integer
                      ? 'Nombre entier attendu'
                      : 'Texte attendu',
                ),
              ),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
    ),
    actions: [
      StudioButton(
        label: 'Annuler',
        secondary: true,
        onPressed: () => Navigator.pop(context),
      ),
      StudioButton(
        label: 'Appliquer la condition',
        onPressed: _id == null ? null : _accept,
      ),
    ],
  );
}

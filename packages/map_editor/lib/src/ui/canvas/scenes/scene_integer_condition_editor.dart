import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

class SceneIntegerConditionEditor extends StatefulWidget {
  const SceneIntegerConditionEditor({
    super.key,
    this.current,
    required this.facts,
    required this.items,
    required this.onApply,
  });
  final SceneConditionSource? current;
  final Map<String, String> facts, items;
  final Future<bool> Function(SceneConditionSource) onApply;
  @override
  State<SceneIntegerConditionEditor> createState() =>
      _SceneIntegerConditionEditorState();
}

class _SceneIntegerConditionEditorState
    extends State<SceneIntegerConditionEditor> {
  SceneIntegerOperand? left, right;
  NarrativeFactOperator comparison = NarrativeFactOperator.equals;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void didUpdateWidget(SceneIntegerConditionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) reset();
  }

  void reset() {
    final source = widget.current;
    left = source?.integerLeft ?? SceneIntegerOperand.literal(0);
    right = source?.integerRight ?? SceneIntegerOperand.literal(0);
    comparison =
        source?.integerComparisonOperator ?? NarrativeFactOperator.equals;
  }

  bool validOperand(SceneIntegerOperand? value) => value != null &&
    (value.factId == null || widget.facts.containsKey(value.factId)) &&
    (value.itemId == null || widget.items.containsKey(value.itemId));
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _IntegerOperandEditor(
        key: ValueKey(('left', widget.current)),
        label: 'Valeur de gauche',
        value: left ?? SceneIntegerOperand.literal(0),
        facts: widget.facts,
        items: widget.items,
        onChanged: (value) => setState(() => left = value),
      ),
      const SizedBox(height: 8),
      PokeMapDropdownField<NarrativeFactOperator>(
        label: 'Comparaison',
        value: comparison,
        items: [
          for (final value in NarrativeFactOperator.values)
            PokeMapDropdownItem(
              value: value,
              label: switch (value) {
                NarrativeFactOperator.equals => 'Égal à',
                NarrativeFactOperator.notEquals => 'Différent de',
                NarrativeFactOperator.greaterThan => 'Supérieur à',
                NarrativeFactOperator.greaterThanOrEqual =>
                  'Supérieur ou égal à',
                NarrativeFactOperator.lessThan => 'Inférieur à',
                NarrativeFactOperator.lessThanOrEqual => 'Inférieur ou égal à',
              },
            ),
        ],
        onChanged: (value) {
          setState(() => comparison = value);
        },
      ),
      const SizedBox(height: 8),
      _IntegerOperandEditor(
        key: ValueKey(('right', widget.current)),
        label: 'Valeur de droite',
        value: right ?? SceneIntegerOperand.literal(0),
        facts: widget.facts,
        items: widget.items,
        onChanged: (value) => setState(() => right = value),
      ),
      const SizedBox(height: 8),
      PokeMapButton(
        key: const ValueKey('scene-integer-comparison-apply'),
        onPressed: saving || !validOperand(left) || !validOperand(right)
            ? null
            : () async {
                setState(() => saving = true);
                try {
                  await widget.onApply(
                    SceneConditionSource.integerComparison(
                      left: left!,
                      comparison: comparison,
                      right: right!,
                      label: widget.current?.label,
                      debugTechnicalLabel: widget.current?.debugTechnicalLabel,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: const Text('Appliquer la comparaison'),
      ),
    ],
  );
}

class _IntegerOperandEditor extends StatefulWidget {
  const _IntegerOperandEditor({
    super.key,
    required this.label,
    required this.value,
    required this.facts,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final SceneIntegerOperand value;
  final Map<String, String> facts, items;
  final ValueChanged<SceneIntegerOperand?> onChanged;
  @override
  State<_IntegerOperandEditor> createState() => _IntegerOperandEditorState();
}

class _IntegerOperandEditorState extends State<_IntegerOperandEditor> {
  late String source;
  String? factId, itemId;
  late final TextEditingController number;
  @override
  void initState() {
    super.initState();
    final operand = widget.value;
    source = operand.kind == SceneIntegerOperandKind.gameRead
        ? operand.read!.name
        : operand.kind.name;
    factId = operand.factId ?? widget.facts.keys.firstOrNull;
    itemId = operand.itemId ?? widget.items.keys.firstOrNull;
    number = TextEditingController(text: '${operand.value ?? 0}');
  }

  @override
  void dispose() {
    number.dispose();
    super.dispose();
  }

  SceneIntegerOperand? get prepared {
    try {
      return switch (source) {
        'literal' =>
          int.tryParse(number.text) == null
              ? null
              : SceneIntegerOperand.literal(int.parse(number.text)),
        'integerFact' =>
          widget.facts.containsKey(factId)
              ? SceneIntegerOperand.integerFact(factId!)
              : null,
        'money' => SceneIntegerOperand.gameRead(SceneIntegerGameRead.money),
        'partyCount' => SceneIntegerOperand.gameRead(
          SceneIntegerGameRead.partyCount,
        ),
        'itemCount' =>
          widget.items.containsKey(itemId)
              ? SceneIntegerOperand.gameRead(
                  SceneIntegerGameRead.itemCount,
                  itemId: itemId,
                )
              : null,
        _ => null,
      };
    } on ArgumentError {
      return null;
    }
  }

  void publish() => widget.onChanged(prepared);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PokeMapDropdownField<String>(
        label: widget.label,
        value: source,
        items: [
          const PokeMapDropdownItem(value: 'literal', label: 'Nombre fixe'),
          const PokeMapDropdownItem(value: 'integerFact', label: 'Compteur'),
          const PokeMapDropdownItem(value: 'money', label: 'Argent du joueur'),
          const PokeMapDropdownItem(
            value: 'partyCount',
            label: 'Taille de l’équipe',
          ),
          const PokeMapDropdownItem(
            value: 'itemCount',
            label: 'Quantité d’un objet',
          ),
        ],
        onChanged: (value) {
          setState(() => source = value);
          publish();
        },
      ),
      if (source == 'literal')
        PokeMapTextField(
          label: 'Nombre entier',
          controller: number,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          onChanged: (_) {
            setState(() {});
            publish();
          },
        ),
      if (source == 'integerFact')
        widget.facts.isEmpty
            ? const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.warning,
                title: 'Aucun compteur',
                message: 'Créez un Fact entier dans le projet.',
              )
            : PokeMapDropdownField<String>(
                label: 'Compteur',
                value: widget.facts.containsKey(factId) ? factId! : widget.facts.keys.first,
                items: [
                  for (final entry in widget.facts.entries)
                    PokeMapDropdownItem(value: entry.key, label: entry.value),
                ],
                onChanged: (value) {
                  setState(() => factId = value);
                  publish();
                },
              ),
      if (source == 'itemCount')
        widget.items.isEmpty
            ? const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.warning,
                title: 'Aucun objet',
                message: 'Chargez le catalogue des objets du projet.',
              )
            : PokeMapDropdownField<String>(
                label: 'Objet',
                value: widget.items.containsKey(itemId) ? itemId! : widget.items.keys.first,
                items: [
                  for (final entry in widget.items.entries)
                    PokeMapDropdownItem(value: entry.key, label: entry.value),
                ],
                onChanged: (value) {
                  setState(() => itemId = value);
                  publish();
                },
              ),
    ],
  );
}

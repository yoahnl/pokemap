import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'scene_integer_authoring_fields.dart';

class SceneIntegerConditionForm extends StatefulWidget {
  const SceneIntegerConditionForm({super.key, this.current, required this.project, required this.onApply, this.loadItems});
  final SceneConditionSource? current;
  final ProjectManifest project;
  final ValueChanged<SceneConditionSource> onApply;
  final Future<Map<String, String>> Function()? loadItems;
  @override
  State<SceneIntegerConditionForm> createState() => _SceneIntegerConditionFormState();
}
class _SceneIntegerConditionFormState extends State<SceneIntegerConditionForm> {
  SceneIntegerOperand? left, right;
  NarrativeFactOperator comparison = NarrativeFactOperator.equals;
  Map<String, String> items = const {};
  bool loading = false;
  int request = 0;
  Map<String, String> get facts => integerSceneOptions(NarrativeCommandParameterKind.integerFacts,
    project: widget.project, commandId: null)!;
  @override
  void initState() { super.initState(); reset(); }
  @override
  void didUpdateWidget(SceneIntegerConditionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.project != widget.project || oldWidget.loadItems != widget.loadItems) reset();
  }
  void reset() {
    left = widget.current?.integerLeft ?? SceneIntegerOperand.literal(0);
    right = widget.current?.integerRight ?? SceneIntegerOperand.literal(0);
    comparison = widget.current?.integerComparisonOperator ?? NarrativeFactOperator.equals;
    loadItems();
  }
  Future<void> loadItems() async {
    final token = ++request;
    items = const {};
    loading = widget.loadItems != null;
    try {
      final result = await widget.loadItems?.call() ?? const <String, String>{};
      if (mounted && token == request) setState(() => items = result);
    } on Object {
      if (mounted && token == request) setState(() => items = const {});
    } finally { if (mounted && token == request) setState(() => loading = false); }
  }
  bool valid(SceneIntegerOperand? operand) => operand != null &&
    (operand.factId == null || facts.containsKey(operand.factId)) &&
    (operand.itemId == null || !loading && items.containsKey(operand.itemId));
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _IntegerOperandField(key: ValueKey(('left', widget.current)), label: 'Valeur de gauche', value: left ?? SceneIntegerOperand.literal(0), facts: facts, items: items,
      onChanged: (value) => setState(() => left = value)),
    const SizedBox(height: 12),
    StudioSelect(label: 'Comparaison', value: comparison.name,
      options: const {'equals': 'Est égal à', 'notEquals': 'Est différent de', 'greaterThan': 'Est supérieur à',
        'greaterThanOrEqual': 'Est supérieur ou égal à', 'lessThan': 'Est inférieur à', 'lessThanOrEqual': 'Est inférieur ou égal à'},
      onChanged: (value) => setState(() => comparison = NarrativeFactOperator.values.byName(value))),
    const SizedBox(height: 12),
    _IntegerOperandField(key: ValueKey(('right', widget.current)), label: 'Valeur de droite', value: right ?? SceneIntegerOperand.literal(0), facts: facts, items: items,
      onChanged: (value) => setState(() => right = value)),
    const SizedBox(height: 12),
    StudioButton(label: 'Appliquer la condition', onPressed: !valid(left) || !valid(right) ? null : () => widget.onApply(
      SceneConditionSource.integerComparison(left: left!, comparison: comparison, right: right!,
        label: widget.current?.label, debugTechnicalLabel: widget.current?.debugTechnicalLabel))),
  ]);
}

class _IntegerOperandField extends StatefulWidget {
  const _IntegerOperandField({super.key, required this.label, required this.value, required this.facts, required this.items, required this.onChanged});
  final String label;
  final SceneIntegerOperand value;
  final Map<String, String> facts, items;
  final ValueChanged<SceneIntegerOperand?> onChanged;
  @override
  State<_IntegerOperandField> createState() => _IntegerOperandFieldState();
}
class _IntegerOperandFieldState extends State<_IntegerOperandField> {
  late String source, number;
  String? factId, itemId;
  @override
  void initState() {
    super.initState();
    source = widget.value.kind == SceneIntegerOperandKind.gameRead ? widget.value.read!.name : widget.value.kind.name;
    number = '${widget.value.value ?? 0}';
    factId = widget.value.factId ?? widget.facts.keys.firstOrNull;
    itemId = widget.value.itemId ?? widget.items.keys.firstOrNull;
  }
  SceneIntegerOperand? get prepared {
    try {
      return switch (source) {
        'literal' => int.tryParse(number) == null ? null : SceneIntegerOperand.literal(int.parse(number)),
        'integerFact' => widget.facts.containsKey(factId) ? SceneIntegerOperand.integerFact(factId!) : null,
        'money' => SceneIntegerOperand.gameRead(SceneIntegerGameRead.money),
        'partyCount' => SceneIntegerOperand.gameRead(SceneIntegerGameRead.partyCount),
        'itemCount' => widget.items.containsKey(itemId) ? SceneIntegerOperand.gameRead(SceneIntegerGameRead.itemCount, itemId: itemId) : null,
        _ => null,
      };
    } on ArgumentError { return null; }
  }
  void publish() => widget.onChanged(prepared);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    StudioSelect(label: widget.label, value: source,
      options: const {'literal': 'Nombre fixe', 'integerFact': 'Compteur', 'money': 'Argent du joueur', 'partyCount': 'Taille de l’équipe', 'itemCount': 'Quantité d’un objet'},
      onChanged: (value) { setState(() => source = value); publish(); }),
    if (source == 'literal') StudioDraftField(label: 'Nombre entier', value: number,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      onChanged: (value) { setState(() => number = value); publish(); }),
    if (source == 'integerFact') StudioSelect(label: 'Compteur', value: factId, options: widget.facts,
      onChanged: (value) { setState(() => factId = value); publish(); }),
    if (source == 'itemCount') ...[
      StudioSelect(label: 'Objet', value: itemId, options: widget.items,
        onChanged: (value) { setState(() => itemId = value); publish(); }),
      if (widget.items.isEmpty) const StudioNotice('Le catalogue des objets est indisponible. La condition actuelle reste conservée.'),
    ],
  ]);
}

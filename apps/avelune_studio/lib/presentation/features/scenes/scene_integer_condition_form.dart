import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

import '../../../features/scenes/application/scene_integer_condition_draft.dart';

class SceneIntegerConditionForm extends StatefulWidget {
  const SceneIntegerConditionForm({
    super.key,
    this.current,
    required this.project,
    required this.onApply,
    this.loadItems,
  });
  final SceneConditionSource? current;
  final ProjectManifest project;
  final ValueChanged<SceneConditionSource> onApply;
  final Future<Map<String, String>> Function()? loadItems;
  @override
  State<SceneIntegerConditionForm> createState() =>
      _SceneIntegerConditionFormState();
}

class _SceneIntegerConditionFormState extends State<SceneIntegerConditionForm> {
  late final SceneIntegerConditionDraft draft;
  @override
  void initState() {
    super.initState();
    draft = SceneIntegerConditionDraft(
      project: widget.project,
      current: widget.current,
      loadItems: widget.loadItems,
      changed: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(SceneIntegerConditionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      project: widget.project,
      current: widget.current,
      loadItems: widget.loadItems,
    );
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _IntegerOperandField(
        key: ValueKey(('left', widget.current)),
        label: 'Valeur de gauche',
        value: draft.left ?? SceneIntegerOperand.literal(0),
        facts: draft.facts,
        items: draft.items,
        onChanged: (value) => setState(() => draft.left = value),
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Comparaison',
        value: draft.comparison.name,
        options: const {
          'equals': 'Est égal à',
          'notEquals': 'Est différent de',
          'greaterThan': 'Est supérieur à',
          'greaterThanOrEqual': 'Est supérieur ou égal à',
          'lessThan': 'Est inférieur à',
          'lessThanOrEqual': 'Est inférieur ou égal à',
        },
        onChanged: (value) => setState(
          () => draft.comparison = NarrativeFactOperator.values.byName(value),
        ),
      ),
      const SizedBox(height: 12),
      _IntegerOperandField(
        key: ValueKey(('right', widget.current)),
        label: 'Valeur de droite',
        value: draft.right ?? SceneIntegerOperand.literal(0),
        facts: draft.facts,
        items: draft.items,
        onChanged: (value) => setState(() => draft.right = value),
      ),
      const SizedBox(height: 12),
      StudioButton(
        label: 'Appliquer la condition',
        onPressed: draft.prepared == null
            ? null
            : () => widget.onApply(draft.prepared!),
      ),
    ],
  );
}

class _IntegerOperandField extends StatefulWidget {
  const _IntegerOperandField({
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
  State<_IntegerOperandField> createState() => _IntegerOperandFieldState();
}

class _IntegerOperandFieldState extends State<_IntegerOperandField> {
  late final SceneIntegerOperandDraft draft;
  @override
  void initState() {
    super.initState();
    draft = SceneIntegerOperandDraft(
      value: widget.value,
      facts: widget.facts,
      items: widget.items,
    );
  }

  void publish() =>
      widget.onChanged(draft.prepare(facts: widget.facts, items: widget.items));
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSelect(
        label: widget.label,
        value: draft.source,
        options: const {
          'literal': 'Nombre fixe',
          'integerFact': 'Compteur',
          'money': 'Argent du joueur',
          'partyCount': 'Taille de l’équipe',
          'itemCount': 'Quantité d’un objet',
        },
        onChanged: (value) {
          setState(() => draft.source = value);
          publish();
        },
      ),
      if (draft.source == 'literal')
        StudioDraftField(
          label: 'Nombre entier',
          value: draft.number,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          onChanged: (value) {
            setState(() => draft.number = value);
            publish();
          },
        ),
      if (draft.source == 'integerFact')
        StudioSelect(
          label: 'Compteur',
          value: draft.factId,
          options: widget.facts,
          onChanged: (value) {
            setState(() => draft.factId = value);
            publish();
          },
        ),
      if (draft.source == 'itemCount') ...[
        StudioSelect(
          label: 'Objet',
          value: draft.itemId,
          options: widget.items,
          onChanged: (value) {
            setState(() => draft.itemId = value);
            publish();
          },
        ),
        if (widget.items.isEmpty)
          const StudioNotice(
            'Le catalogue des objets est indisponible. La condition actuelle reste conservée.',
          ),
      ],
    ],
  );
}

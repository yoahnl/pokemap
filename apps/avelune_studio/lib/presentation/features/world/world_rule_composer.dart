part of 'world_workspace_page.dart';

extension _WorldRuleComposer on _WorldWorkspacePageState {
  Widget _ruleComposer() {
    final draft = controller.activeRule;
    if (draft == null) {
      return StudioPanel(
        children: [
          Expanded(
            child: StudioEmptyState(
              title: 'Aucune règle sélectionnée',
              description:
                  'Une règle relie une condition, une cible et un effet.',
              action: StudioButton(
                label: 'Nouvelle règle',
                icon: Icons.add,
                onPressed: _create,
              ),
            ),
          ),
        ],
      );
    }
    return StudioPanel(
      title: draft.label,
      actions: [
        StudioTool(
          label: 'Annuler la dernière modification',
          icon: Icons.undo,
          onPressed: controller.canUndoRule(draft.id)
              ? () {
                  controller.undoRule(draft.id);
                  refresh();
                }
              : null,
        ),
        StudioTool(
          label: 'Supprimer la règle',
          icon: Icons.delete_outline,
          onPressed: () => unawaited(_deleteRule(draft)),
        ),
      ],
      children: [
        Expanded(
          child: ListView(
            children: [
              StudioCommitField(
                label: 'Nom de la règle',
                value: draft.label,
                tryCommit: (value) {
                  final key = '${draft.id}.label';
                  if (value.trim().isEmpty) {
                    view.invalidFields.add(key);
                    refresh();
                    return false;
                  }
                  view.invalidFields.remove(key);
                  controller.editRule(draft.id, (d) => d.label = value);
                  refresh();
                  return true;
                },
              ),
              StudioToggleRow(
                label: 'Règle active',
                description:
                    'Une règle désactivée ne s’applique pas, même si sa '
                    'condition est vraie.',
                value: draft.enabled,
                onChanged: (value) {
                  controller.editRule(draft.id, (d) => d.enabled = value);
                  refresh();
                },
              ),
              const SizedBox(height: 12),
              _block(
                'Condition',
                draft.source == null
                    ? 'Choisissez ce qui déclenche la règle'
                    : _sourceSummary(draft.source!),
                filled: draft.source != null,
                onTap: () => unawaited(_pickSource(draft)),
                child: draft.source?.kind == WorldRuleSourceKind.fact
                    ? _comparison(draft)
                    : null,
              ),
              _arrow(),
              _block(
                'Cible',
                draft.target == null
                    ? 'Choisissez ce que la règle modifie'
                    : _targetSummary(draft.target!),
                filled: draft.target != null,
                onTap: () => unawaited(_pickTarget(draft)),
              ),
              _arrow(),
              _block(
                'Effet',
                draft.effect == null
                    ? 'Choisissez ce qui change sur la cible'
                    : _effectLabel(draft.effect!.kind),
                filled: draft.effect != null,
                onTap: draft.target == null
                    ? null
                    : () => unawaited(_pickEffect(draft)),
                hint: draft.target == null
                    ? 'Les effets dépendent de la cible : choisissez-la '
                          'd’abord.'
                    : null,
              ),
              if (draft.missing.isNotEmpty) ...[
                const SizedBox(height: 10),
                StudioNotice(
                  'Il manque ${draft.missing.join(', ')} pour enregistrer '
                  'cette règle.',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _arrow() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 2),
    child: Center(child: Icon(Icons.south, size: 18)),
  );

  Widget _block(
    String title,
    String value, {
    required bool filled,
    VoidCallback? onTap,
    Widget? child,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: filled ? 1 : .4),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('rule-block-$title'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(value),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(hint, style: Theme.of(context).textTheme.bodySmall),
              ],
              ?child,
            ],
          ),
        ),
      ),
    ),
  );

  /// The operator list comes from the model, so a text or a boolean never
  /// offers an order comparison.
  Widget _comparison(WorldRuleDraft draft) {
    final source = draft.source!;
    final fact = controller.fact(source.sourceId);
    if (fact == null) {
      return const Text('État introuvable : la référence reste à corriger.');
    }
    final value = source.expectedFactValue ?? fact.initialValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        StudioSelect(
          label: 'Comparaison',
          value: (source.factOperator ?? NarrativeFactOperator.equals).name,
          options: {
            for (final operator in fact.valueKind.compatibleOperators)
              operator.name: _operatorLabel(operator),
          },
          onChanged: (next) => _setSource(
            draft,
            fact.id,
            NarrativeFactOperator.values.byName(next),
            value,
          ),
        ),
        _expectedField(draft, fact, value),
      ],
    );
  }

  Widget _expectedField(
    WorldRuleDraft draft,
    NarrativeFactDefinition fact,
    NarrativeValue value,
  ) {
    final operator = draft.source?.factOperator ?? NarrativeFactOperator.equals;
    final compatible = value.kind == fact.valueKind ? value : fact.initialValue;
    return switch (fact.valueKind) {
      NarrativeValueKind.boolean => StudioToggleRow(
        label: 'Valeur attendue',
        value: compatible.boolValue,
        onChanged: (next) =>
            _setSource(draft, fact.id, operator, NarrativeValue.boolean(next)),
      ),
      NarrativeValueKind.integer => StudioCommitField(
        label: 'Valeur attendue',
        value: '${compatible.intValue}',
        tryCommit: (raw) {
          final parsed = int.tryParse(raw.trim());
          final key = '${draft.id}.expected';
          if (parsed == null) {
            view.invalidFields.add(key);
            refresh();
            return false;
          }
          view.invalidFields.remove(key);
          _setSource(draft, fact.id, operator, NarrativeValue.integer(parsed));
          return true;
        },
      ),
      NarrativeValueKind.string => StudioCommitField(
        label: 'Valeur attendue',
        value: compatible.stringValue,
        alwaysCommit: true,
        onCommit: (raw) =>
            _setSource(draft, fact.id, operator, NarrativeValue.string(raw)),
      ),
    };
  }

  void _setSource(
    WorldRuleDraft draft,
    String factId,
    NarrativeFactOperator operator,
    NarrativeValue expected,
  ) {
    controller.editRule(
      draft.id,
      (d) => d.source = WorldRuleSource.factValue(
        factId: factId,
        operator: operator,
        expectedValue: expected,
      ),
    );
    refresh();
  }
}

String _operatorLabel(NarrativeFactOperator operator) => switch (operator) {
  NarrativeFactOperator.equals => 'est égal à',
  NarrativeFactOperator.notEquals => 'est différent de',
  NarrativeFactOperator.greaterThan => 'est supérieur à',
  NarrativeFactOperator.greaterThanOrEqual => 'est supérieur ou égal à',
  NarrativeFactOperator.lessThan => 'est inférieur à',
  NarrativeFactOperator.lessThanOrEqual => 'est inférieur ou égal à',
};

String _effectLabel(WorldRuleEffectKind kind) => switch (kind) {
  WorldRuleEffectKind.entityVisible => 'Afficher le personnage',
  WorldRuleEffectKind.entityHidden => 'Masquer le personnage',
  WorldRuleEffectKind.npcDialogueOverride => 'Remplacer le dialogue',
  WorldRuleEffectKind.eventEnabled => 'Activer l’événement',
  WorldRuleEffectKind.eventDisabled => 'Désactiver l’événement',
  WorldRuleEffectKind.eventHidden => 'Masquer l’événement',
};

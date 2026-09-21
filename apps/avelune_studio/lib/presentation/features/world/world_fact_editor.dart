part of 'world_workspace_page.dart';

extension _WorldFactEditor on _WorldWorkspacePageState {
  Widget _factEditor() {
    final fact = controller.activeFact;
    if (fact == null) {
      return StudioPanel(
        children: [
          Expanded(
            child: StudioEmptyState(
              title: 'Aucun état sélectionné',
              description:
                  'Choisissez un état dans la bibliothèque, ou créez-en un.',
              action: StudioButton(
                label: 'Nouvel état',
                icon: Icons.add,
                onPressed: _create,
              ),
            ),
          ),
        ],
      );
    }
    return StudioPanel(
      title: fact.label,
      actions: [
        StudioTool(
          label: 'Annuler la dernière modification',
          icon: Icons.undo,
          onPressed: controller.canUndoFact(fact.id)
              ? () {
                  controller.undoFact(fact.id);
                  refresh();
                }
              : null,
        ),
        StudioTool(
          label: 'Créer une règle avec cet état',
          icon: Icons.rule,
          onPressed: () {
            if (!flush()) return;
            controller.createRule(factId: fact.id);
            view.view = WorldView.rules;
            refresh();
          },
        ),
        StudioTool(
          label: 'Supprimer l’état',
          icon: Icons.delete_outline,
          onPressed: () => unawaited(_deleteFact(fact)),
        ),
      ],
      children: [
        Expanded(
          child: ListView(
            children: [
              StudioCommitField(
                label: 'Nom',
                value: fact.label,
                tryCommit: (value) => _commitFact(
                  fact.id,
                  'label',
                  value.trim().isEmpty
                      ? null
                      : (current) => _copyFact(current, label: value),
                ),
              ),
              StudioCommitField(
                label: 'Description',
                value: fact.description,
                maxLines: 3,
                onCommit: (value) => _commitFact(
                  fact.id,
                  'description',
                  (current) => _copyFact(current, description: value),
                ),
              ),
              StudioCommitField(
                label: 'Catégorie',
                value: fact.category,
                onCommit: (value) => _commitFact(
                  fact.id,
                  'category',
                  (current) => _copyFact(current, category: value),
                ),
              ),
              const SizedBox(height: 8),
              StudioSelect(
                label: 'Type',
                value: fact.valueKind.name,
                options: {
                  for (final kind in NarrativeValueKind.values)
                    kind.name: _kindLabel(kind),
                },
                onChanged: (value) =>
                    _changeKind(fact, NarrativeValueKind.values.byName(value)),
              ),
              const SizedBox(height: 4),
              _initialValueField(fact),
              if (fact.legacyFlagName case final flag?) ...[
                const SizedBox(height: 8),
                Text('Liaison historique conservée : $flag'),
              ],
              const SizedBox(height: 16),
              _usages(fact.id),
            ],
          ),
        ),
      ],
    );
  }

  /// Named "of the project" so it is never read as the test value shown on the
  /// right, nor as the value of a save.
  Widget _initialValueField(NarrativeFactDefinition fact) =>
      switch (fact.valueKind) {
        NarrativeValueKind.boolean => StudioToggleRow(
          label: 'Valeur initiale du projet',
          value: fact.initialValue.boolValue,
          onChanged: (value) => _commitFact(
            fact.id,
            'value',
            (current) =>
                _copyFact(current, initialValue: NarrativeValue.boolean(value)),
          ),
        ),
        NarrativeValueKind.integer => StudioCommitField(
          label: 'Valeur initiale du projet',
          value: '${fact.initialValue.intValue}',
          tryCommit: (raw) {
            final parsed = int.tryParse(raw.trim());
            return _commitFact(
              fact.id,
              'value',
              parsed == null
                  ? null
                  : (current) => _copyFact(
                      current,
                      initialValue: NarrativeValue.integer(parsed),
                    ),
            );
          },
        ),
        NarrativeValueKind.string => StudioCommitField(
          label: 'Valeur initiale du projet',
          value: fact.initialValue.stringValue,
          alwaysCommit: true,
          onCommit: (raw) => _commitFact(
            fact.id,
            'value',
            (current) =>
                _copyFact(current, initialValue: NarrativeValue.string(raw)),
          ),
        ),
      };

  /// Rebuilds the definition field by field so nothing unedited is dropped.
  NarrativeFactDefinition _copyFact(
    NarrativeFactDefinition current, {
    String? label,
    String? description,
    String? category,
    NarrativeValue? initialValue,
  }) => NarrativeFactDefinition(
    id: current.id,
    label: label ?? current.label,
    description: description ?? current.description,
    category: category ?? current.category,
    initialValue: initialValue ?? current.initialValue,
    tags: current.tags,
    legacyFlagName: current.legacyFlagName,
  );

  bool _commitFact(
    String id,
    String field,
    NarrativeFactDefinition Function(NarrativeFactDefinition)? change,
  ) {
    final key = '$id.$field';
    if (change == null) {
      view.invalidFields.add(key);
      refresh();
      return false;
    }
    view.invalidFields.remove(key);
    final current = controller.fact(id);
    if (current != null) controller.editFact(change(current));
    refresh();
    return true;
  }

  Future<void> _changeKind(
    NarrativeFactDefinition fact,
    NarrativeValueKind kind,
  ) async {
    if (!flush() || kind == fact.valueKind) return;
    final preview = controller.previewFactType(fact.id, kind);
    final impacted = preview?.usages ?? const [];
    if (impacted.isNotEmpty) {
      view.actionError =
          'Changement refusé : ${impacted.length} usage(s) incompatible(s).';
      refresh();
      return;
    }
    if (fact.legacyFlagName != null && kind != NarrativeValueKind.boolean) {
      view.actionError =
          'La liaison historique n’existe que pour un booléen. Retirez-la '
          'explicitement avant de changer de type.';
      refresh();
      return;
    }
    view.actionError = null;
    controller.editFact(
      NarrativeFactDefinition(
        id: fact.id,
        label: fact.label,
        description: fact.description,
        category: fact.category,
        initialValue: switch (kind) {
          NarrativeValueKind.boolean => const NarrativeValue.boolean(false),
          NarrativeValueKind.integer => NarrativeValue.integer(0),
          NarrativeValueKind.string => const NarrativeValue.string(''),
        },
        tags: fact.tags,
      ),
    );
    controller.reconcileSimulation();
    refresh();
  }

  Future<void> _deleteFact(NarrativeFactDefinition fact) async {
    if (!flush()) return;
    final blockers = controller.factBlockers(fact.id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${fact.label} » ?'),
        content: Text(
          blockers.isEmpty
              ? 'Aucun usage connu n’a été trouvé pour cet état.'
              : 'Cet état est utilisé par :\n${blockers.join('\n')}',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Supprimer',
            variant: StudioButtonVariant.destructive,
            onPressed: blockers.isEmpty
                ? () => Navigator.pop(context, true)
                : null,
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteFact(fact.id);
    refresh();
  }
}

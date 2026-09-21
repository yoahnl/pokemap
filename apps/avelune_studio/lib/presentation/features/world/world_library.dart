part of 'world_workspace_page.dart';

extension _WorldLibrary on _WorldWorkspacePageState {
  Widget _library() => StudioPanel(
    compact: true,
    children: [
      _tabs(),
      const SizedBox(height: 10),
      if (_rules) ..._ruleLibrary() else ..._factLibrary(),
    ],
  );

  List<Widget> _factLibrary() {
    final query = view.factSearch.text.toLowerCase().trim();
    final entries = controller.model.facts
        .where(
          (entry) =>
              (entry.fact.label.toLowerCase().contains(query) ||
                  entry.fact.id.toLowerCase().contains(query)) &&
              (view.factCategory.isEmpty ||
                  entry.fact.category == view.factCategory),
        )
        .toList();
    final selected = controller.selectedFactId;
    return [
      StudioSearchField(
        controller: view.factSearch,
        label: 'Rechercher un état',
        onChanged: (_) => refresh(),
      ),
      const SizedBox(height: 8),
      if (controller.model.factCategories.isNotEmpty)
        StudioSelect(
          label: 'Catégorie',
          value: view.factCategory,
          options: {
            '': 'Toutes les catégories',
            for (final category in controller.model.factCategories)
              category: category,
          },
          onChanged: (value) {
            view.factCategory = value;
            refresh();
          },
        ),
      if (selected != null && !entries.any((e) => e.fact.id == selected))
        StudioNotice(
          'Sélection hors filtre : ${controller.fact(selected)?.label ?? selected}',
        ),
      Expanded(
        child: entries.isEmpty
            ? const StudioEmptyState(
                title: 'Aucun état',
                description:
                    'Créez un premier état pour que le jeu mémorise '
                    'quelque chose.',
              )
            : ListView(
                children: [
                  for (final entry in entries)
                    _row(
                      id: entry.fact.id,
                      title: entry.fact.label,
                      subtitle:
                          '${_kindLabel(entry.fact.valueKind)} · '
                          '${_valueLabel(entry.fact.initialValue)}',
                      selected: entry.fact.id == selected,
                      dirty: controller.isFactDirty(entry.fact.id),
                      onTap: () {
                        if (!flush()) return;
                        controller.selectFact(entry.fact.id);
                        refresh();
                      },
                    ),
                ],
              ),
      ),
      const SizedBox(height: 8),
      StudioButton(
        label: 'Nouvel état',
        icon: Icons.add,
        secondary: true,
        onPressed: _create,
      ),
    ];
  }

  List<Widget> _ruleLibrary() {
    final query = view.ruleSearch.text.toLowerCase().trim();
    final drafts = controller.pendingRules.values
        .where((draft) => draft.complete == null)
        .where((draft) => draft.label.toLowerCase().contains(query));
    final entries = controller.model.worldRules.where(
      (entry) =>
          entry.rule.label.toLowerCase().contains(query) ||
          entry.humanSummary.toLowerCase().contains(query),
    );
    final selected = controller.selectedRuleId;
    return [
      StudioSearchField(
        controller: view.ruleSearch,
        label: 'Rechercher une règle',
        onChanged: (_) => refresh(),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: entries.isEmpty && drafts.isEmpty
            ? const StudioEmptyState(
                title: 'Aucune règle',
                description:
                    'Une règle relie un état à une cible du jeu et à '
                    'un effet.',
              )
            : ListView(
                children: [
                  for (final entry in entries)
                    _row(
                      id: entry.rule.id,
                      title: entry.rule.label,
                      subtitle: entry.humanSummary,
                      selected: entry.rule.id == selected,
                      dirty: controller.isRuleDirty(entry.rule.id),
                      disabled: !entry.rule.enabled,
                      onTap: () {
                        if (!flush()) return;
                        controller.selectRule(entry.rule.id);
                        refresh();
                      },
                    ),
                  for (final draft in drafts)
                    _row(
                      id: draft.id,
                      title: draft.label,
                      subtitle:
                          'Incomplète : il manque '
                          '${draft.missing.join(', ')}',
                      selected: draft.id == selected,
                      dirty: true,
                      onTap: () {
                        if (!flush()) return;
                        controller.selectRule(draft.id);
                        refresh();
                      },
                    ),
                ],
              ),
      ),
      const SizedBox(height: 8),
      StudioButton(
        label: 'Nouvelle règle',
        icon: Icons.add,
        secondary: true,
        onPressed: _create,
      ),
    ];
  }

  Widget _row({
    required String id,
    required String title,
    required String subtitle,
    required bool selected,
    required bool dirty,
    required VoidCallback onTap,
    bool disabled = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        key: ValueKey('world-row-$id'),
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (disabled) const Text('Désactivée · '),
                  if (dirty) const Text('Brouillon'),
                ],
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _kindLabel(NarrativeValueKind kind) => switch (kind) {
  NarrativeValueKind.boolean => 'Booléen',
  NarrativeValueKind.integer => 'Nombre entier',
  NarrativeValueKind.string => 'Texte',
};

String _valueLabel(NarrativeValue value) => switch (value.kind) {
  NarrativeValueKind.boolean => value.boolValue ? 'vrai' : 'faux',
  NarrativeValueKind.integer => '${value.intValue}',
  NarrativeValueKind.string =>
    value.stringValue.isEmpty ? '(vide)' : value.stringValue,
};

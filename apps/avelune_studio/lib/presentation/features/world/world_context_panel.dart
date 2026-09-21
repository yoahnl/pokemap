part of 'world_workspace_page.dart';

extension _WorldContextPanel on _WorldWorkspacePageState {
  Widget _contextPanel() => StudioPanel(
    compact: true,
    title: _rules ? 'Test de la règle' : 'Usages et test',
    children: [
      Expanded(
        child: ListView(
          children: [
            const StudioNotice(
              'Simulation locale — aucune modification du projet ni d’une '
              'partie.',
            ),
            const SizedBox(height: 8),
            ..._testValues(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StudioButton(
                    label: 'Tester la règle',
                    icon: Icons.play_arrow,
                    onPressed: () {
                      if (!flush()) return;
                      controller.simulate();
                      refresh();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                StudioTool(
                  label: 'Réinitialiser le test',
                  icon: Icons.restart_alt,
                  onPressed: () {
                    controller.resetSimulation();
                    refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_rules) ..._ruleOutcome() else ..._factOutcome(),
          ],
        ),
      ),
    ],
  );

  /// Hypotheses are limited to the states the open document actually reads.
  List<Widget> _testValues() {
    final ids = _rules
        ? [
            if (controller.activeRule?.source case final source?)
              if (source.kind == WorldRuleSourceKind.fact) source.sourceId,
          ]
        : [?controller.selectedFactId];
    if (ids.isEmpty) {
      return const [Text('Aucune valeur hypothétique pour ce document.')];
    }
    return [
      for (final id in ids)
        if (controller.fact(id) case final fact?) _testValue(fact),
    ];
  }

  Widget _testValue(NarrativeFactDefinition fact) {
    final value = controller.simulationValue(fact.id);
    final hypothetical = controller.isHypothetical(fact.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hypothetical
              ? 'Valeur de test · hypothèse'
              : 'Valeur de test · valeur initiale du projet',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        switch (fact.valueKind) {
          NarrativeValueKind.boolean => StudioToggleRow(
            label: fact.label,
            value: value.boolValue,
            onChanged: (next) {
              controller.setSimulationValue(
                fact.id,
                NarrativeValue.boolean(next),
              );
              controller.simulate();
              refresh();
            },
          ),
          NarrativeValueKind.integer => StudioCommitField(
            label: fact.label,
            value: '${value.intValue}',
            tryCommit: (raw) {
              final parsed = int.tryParse(raw.trim());
              if (parsed == null) {
                controller.report = null;
                refresh();
                return false;
              }
              controller.setSimulationValue(
                fact.id,
                NarrativeValue.integer(parsed),
              );
              controller.simulate();
              refresh();
              return true;
            },
          ),
          NarrativeValueKind.string => StudioCommitField(
            label: fact.label,
            value: value.stringValue,
            alwaysCommit: true,
            onCommit: (raw) {
              controller.setSimulationValue(
                fact.id,
                NarrativeValue.string(raw),
              );
              controller.simulate();
              refresh();
            },
          ),
        },
      ],
    );
  }

  /// Three separate facts: a rule can be on, its condition false, and another
  /// rule can still win the same target.
  List<Widget> _ruleOutcome() {
    final draft = controller.activeRule;
    if (draft == null) return const [];
    final trace = controller.traceFor(draft.id);
    if (controller.report == null) {
      return const [Text('Lancez le test pour voir le résultat.')];
    }
    if (trace == null) {
      return const [
        Text('Cette règle n’est pas encore enregistrée ou reste incomplète.'),
      ];
    }
    final competitors = controller.competitorsFor(draft.id);
    return [
      Text('Règle activée : ${draft.enabled ? 'oui' : 'non'}'),
      Text('Condition satisfaite : ${trace.applicable ? 'oui' : 'non'}'),
      Text('Effet retenu dans ce test : ${trace.winner ? 'oui' : 'non'}'),
      const SizedBox(height: 6),
      Text(trace.explanation),
      if (competitors.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('Autres règles sur la même cible', style: _label),
        for (final other in competitors)
          StudioButton(
            label:
                '${other.label} · priorité ${other.priority}'
                '${other.winner ? ' · retenue' : ''}',
            secondary: true,
            onPressed: () {
              controller.selectRule(other.ruleId);
              refresh();
            },
          ),
      ],
      const SizedBox(height: 12),
      _preview(draft),
      const SizedBox(height: 12),
      StudioCommitField(
        label: 'Priorité',
        value: '${draft.priority}',
        tryCommit: (raw) {
          final parsed = int.tryParse(raw.trim());
          if (parsed == null) return false;
          controller.editRule(draft.id, (d) => d.priority = parsed);
          refresh();
          return true;
        },
      ),
    ];
  }

  List<Widget> _factOutcome() {
    final id = controller.selectedFactId;
    if (id == null) return const [];
    return [_usages(id)];
  }

  /// Readers and writers stay apart: knowing who changes a state is not the
  /// same question as knowing who reads it.
  Widget _usages(String factId) {
    final entry = controller.model.facts
        .where((item) => item.fact.id == factId)
        .firstOrNull;
    if (entry == null) {
      return const Text('Aucun usage connu pour cet état.');
    }
    Widget section(String title, List<FactManagerUsage> usages) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text('$title (${usages.length})', style: _label),
        if (usages.isEmpty)
          const Text('Aucun')
        else
          for (final usage in usages)
            StudioButton(
              label: usage.ownerLabel,
              secondary: true,
              onPressed:
                  usage.kind == FactManagerUsageKind.sceneCondition ||
                      usage.kind == FactManagerUsageKind.sceneConsequence
                  ? () => unawaited(widget.onOpenScene?.call(usage.ownerId))
                  : null,
            ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section('Lu par', entry.readerUsages),
        section('Modifié par', entry.writerUsages),
      ],
    );
  }

  TextStyle? get _label => Theme.of(context).textTheme.labelLarge;
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

/// Read-only project preview driven by an isolated, reproducible game snapshot.
class WorldStateSimulatorPanel extends StatefulWidget {
  const WorldStateSimulatorPanel({
    super.key,
    required this.project,
    required this.maps,
  });

  final ProjectManifest project;
  final List<MapData> maps;

  @override
  State<WorldStateSimulatorPanel> createState() =>
      _WorldStateSimulatorPanelState();
}

class _WorldStateSimulatorPanelState extends State<WorldStateSimulatorPanel> {
  late NarrativeWorldStateSimulationInput _input = _initialInput();
  String? _selectedStepId;
  final Map<String, String> _factInputErrors = {};

  @override
  void initState() {
    super.initState();
    _selectedStepId = _steps.firstOrNull?.id;
  }

  @override
  void didUpdateWidget(covariant WorldStateSimulatorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project || oldWidget.maps != widget.maps) {
      _input = _initialInput();
      _selectedStepId = _steps.firstOrNull?.id;
      _factInputErrors.clear();
    }
  }

  NarrativeWorldStateSimulationInput _initialInput() =>
      NarrativeWorldStateSimulationInput(
        gameState: const GameState(saveId: 'narrative-world-simulator'),
      );

  List<StorylineStep> get _steps => [
        for (final storyline in widget.project.storylines)
          for (final chapter in storyline.chapters) ...chapter.steps,
      ];

  @override
  Widget build(BuildContext context) {
    final report = simulateNarrativeWorldState(
      project: widget.project,
      maps: widget.maps,
      input: _input,
    );
    final selectedStep =
        _steps.where((step) => step.id == _selectedStepId).firstOrNull;

    return PokeMapPanel(
      key: const ValueKey('world-state-simulator-panel'),
      expandChild: true,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapSectionHeader(
              title: 'Simulateur du monde',
              description:
                  'Prévisualisation locale : le projet n’est jamais modifié.',
              trailing: PokeMapBadge(
                label: '${report.winnerRules.length} effet(s)',
                variant: PokeMapBadgeVariant.info,
              ),
            ),
            const SizedBox(height: 8),
            _buildFacts(context),
            const SizedBox(height: 12),
            _buildPresets(context, selectedStep),
            const SizedBox(height: 12),
            _buildSummary(report),
            const SizedBox(height: 12),
            _buildEntities(report),
            const SizedBox(height: 12),
            _buildEvents(report),
            const SizedBox(height: 12),
            _buildRules(report),
            if (report.diagnostics.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDiagnostics(report),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFacts(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Facts hypothétiques',
            description: 'Remplacez une valeur uniquement dans ce snapshot.',
          ),
          if (widget.project.facts.isEmpty)
            const _SimulatorHint('Aucun Fact défini dans le projet.')
          else
            for (final fact in widget.project.facts) ...[
              _buildFactControl(fact),
              if (fact != widget.project.facts.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildFactControl(NarrativeFactDefinition fact) {
    final current =
        _input.gameState.narrativeFactRuntimeState.valueFor(fact.id) ??
            fact.initialValue;
    if (fact.valueKind == NarrativeValueKind.boolean) {
      return KeyedSubtree(
        key: ValueKey('world-state-fact-toggle-${fact.id}'),
        child: PokeMapToggleTile(
          label: fact.label,
          description: 'Bool · ${current.boolValue ? 'vrai' : 'faux'}',
          value: current.boolValue,
          onChanged: (value) {
            _setFactValue(fact.id, NarrativeValue.boolean(value));
          },
        ),
      );
    }

    return PokeMapTextField(
      label: '${fact.label} · ${fact.valueKind.wireName}',
      placeholder: _valueLabel(current),
      fieldKey: ValueKey('world-state-fact-value-${fact.id}'),
      keyboardType: fact.valueKind == NarrativeValueKind.integer
          ? TextInputType.number
          : TextInputType.text,
      errorText: _factInputErrors[fact.id],
      onSubmitted: (raw) => _submitFactValue(fact, raw),
    );
  }

  Widget _buildPresets(
    BuildContext context,
    StorylineStep? selectedStep,
  ) {
    final steps = _steps;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Presets narratifs',
            description: 'Comparez rapidement un avant et un après.',
          ),
          if (steps.isNotEmpty) ...[
            PokeMapDropdownField<String>(
              label: 'Étape',
              value: selectedStep?.id ?? steps.first.id,
              items: [
                for (final step in steps)
                  PokeMapDropdownItem(value: step.id, label: step.title),
              ],
              onChanged: (stepId) => setState(() {
                _selectedStepId = stepId;
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('world-state-before-step'),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    onPressed: selectedStep == null
                        ? null
                        : () => _setStep(selectedStep.id, completed: false),
                    child: const Text('Avant'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('world-state-after-step'),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    onPressed: selectedStep == null
                        ? null
                        : () => _setStep(selectedStep.id, completed: true),
                    child: const Text('Après'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey('world-state-victory-preset'),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.rosette),
                  onPressed: () => _setOutcome('victory'),
                  child: const Text('Victoire'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey('world-state-defeat-preset'),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.xmark_circle),
                  onPressed: () => _setOutcome('defeat'),
                  child: const Text('Défaite'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(NarrativeWorldStateSimulationReport report) {
    final outcome = _input.hypotheticalOutcomes.lastOrNull?.outcomeId;
    return PokeMapCard(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          PokeMapBadge(
            label: 'Règles applicables : ${report.applicableRules.length}',
            variant: PokeMapBadgeVariant.info,
          ),
          PokeMapBadge(
            label:
                'Étapes terminées : ${_input.gameState.progression.completedStepIds.length}',
            variant: PokeMapBadgeVariant.narrative,
          ),
          PokeMapBadge(
            label: 'Issue hypothétique : ${_outcomeLabel(outcome)}',
            variant: outcome == null
                ? PokeMapBadgeVariant.neutral
                : PokeMapBadgeVariant.success,
          ),
          PokeMapBadge(
            label: 'Diagnostics : ${report.diagnostics.length}',
            variant: report.diagnostics.isEmpty
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildEntities(NarrativeWorldStateSimulationReport report) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Entités et dialogues',
            description: 'État final et règles contributrices.',
          ),
          if (report.entityStates.isEmpty)
            const _SimulatorHint('Aucune entité dans le snapshot.')
          else
            for (final entity in report.entityStates)
              _SimulatorStateRow(
                title: entity.label,
                detail: entity.dialogueId == null
                    ? entity.mapId
                    : '${entity.mapId} · dialogue ${entity.dialogueId}',
                stateLabel: entity.visible ? 'Visible' : 'Cachée',
                variant: entity.visible
                    ? PokeMapBadgeVariant.success
                    : PokeMapBadgeVariant.warning,
                contributors: entity.contributorRuleIds,
              ),
        ],
      ),
    );
  }

  Widget _buildEvents(NarrativeWorldStateSimulationReport report) {
    final eventCount =
        report.mapEventStates.length + report.narrativeEventStates.length;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Events',
            description: '$eventCount Event(s) projetés, legacy et V2 séparés.',
          ),
          if (eventCount == 0)
            const _SimulatorHint('Aucun Event dans le snapshot.'),
          for (final event in report.mapEventStates)
            _SimulatorStateRow(
              title: event.label,
              detail: '${event.mapId} · Event legacy',
              stateLabel: _eventStateLabel(event.active, event.hidden),
              variant: _eventVariant(event.active, event.hidden),
              contributors: event.contributorRuleIds,
            ),
          for (final event in report.narrativeEventStates)
            _SimulatorStateRow(
              title: event.label,
              detail: '${event.mapId ?? 'global'} · Event V2',
              stateLabel: event.configured
                  ? _eventStateLabel(event.active, event.hidden)
                  : 'Brouillon',
              variant: event.configured
                  ? _eventVariant(event.active, event.hidden)
                  : PokeMapBadgeVariant.neutral,
              contributors: event.contributorRuleIds,
            ),
        ],
      ),
    );
  }

  Widget _buildRules(NarrativeWorldStateSimulationReport report) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Explication des règles',
            description: 'Ordre croissant de priorité, puis gagnante finale.',
          ),
          if (report.rules.isEmpty)
            const _SimulatorHint('Aucune règle du monde.')
          else
            for (final rule in report.rules)
              _SimulatorStateRow(
                title: rule.label,
                detail: 'Priorité ${rule.priority} · ${rule.explanation}',
                stateLabel: rule.winner
                    ? 'Gagnante'
                    : rule.applicable
                        ? 'Remplacée'
                        : 'Inactive',
                variant: rule.winner
                    ? PokeMapBadgeVariant.success
                    : rule.applicable
                        ? PokeMapBadgeVariant.warning
                        : PokeMapBadgeVariant.neutral,
              ),
        ],
      ),
    );
  }

  Widget _buildDiagnostics(NarrativeWorldStateSimulationReport report) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Diagnostics',
            description: 'Les erreurs restent visibles dans la simulation.',
          ),
          for (final diagnostic in report.diagnostics)
            _SimulatorStateRow(
              title: diagnostic.ruleId,
              detail: diagnostic.message,
              stateLabel: _diagnosticLabel(diagnostic.severity),
              variant: _diagnosticVariant(diagnostic.severity),
            ),
        ],
      ),
    );
  }

  void _setFactValue(String factId, NarrativeValue value) {
    final current = _input.gameState.narrativeFactRuntimeState.valuesByFactId;
    setState(() {
      _factInputErrors.remove(factId);
      _input = _input.copyWith(
        gameState: _input.gameState.copyWith(
          narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
            valuesByFactId: {...current, factId: value},
          ),
        ),
      );
    });
  }

  void _submitFactValue(NarrativeFactDefinition fact, String raw) {
    if (fact.valueKind == NarrativeValueKind.integer) {
      final parsed = int.tryParse(raw.trim());
      if (parsed == null) {
        setState(() => _factInputErrors[fact.id] = 'Entier attendu.');
        return;
      }
      _setFactValue(fact.id, NarrativeValue.integer(parsed));
      return;
    }
    _setFactValue(fact.id, NarrativeValue.string(raw));
  }

  void _setStep(String stepId, {required bool completed}) {
    setState(() {
      _input = _input.withStepCompletion(stepId, completed: completed);
    });
  }

  void _setOutcome(String outcomeId) {
    setState(() {
      _input = _input.copyWith(
        hypotheticalOutcomes: [
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.legacyScenario,
            producerId: 'world_state_simulator',
            outcomeId: outcomeId,
          ),
        ],
      );
    });
  }
}

class _SimulatorStateRow extends StatelessWidget {
  const _SimulatorStateRow({
    required this.title,
    required this.detail,
    required this.stateLabel,
    required this.variant,
    this.contributors = const <String>[],
  });

  final String title;
  final String detail;
  final String stateLabel;
  final PokeMapBadgeVariant variant;
  final List<String> contributors;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  contributors.isEmpty
                      ? detail
                      : '$detail · via ${contributors.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PokeMapBadge(label: stateLabel, variant: variant),
        ],
      ),
    );
  }
}

class _SimulatorHint extends StatelessWidget {
  const _SimulatorHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
          ),
    );
  }
}

String _valueLabel(NarrativeValue value) => switch (value.kind) {
      NarrativeValueKind.boolean => value.boolValue ? 'vrai' : 'faux',
      NarrativeValueKind.integer => '${value.intValue}',
      NarrativeValueKind.string => value.stringValue,
    };

String _outcomeLabel(String? outcome) => switch (outcome) {
      'victory' => 'victoire',
      'defeat' => 'défaite',
      _ => 'aucune',
    };

String _eventStateLabel(bool active, bool hidden) => hidden
    ? 'Caché'
    : active
        ? 'Actif'
        : 'Désactivé';

PokeMapBadgeVariant _eventVariant(bool active, bool hidden) => hidden
    ? PokeMapBadgeVariant.warning
    : active
        ? PokeMapBadgeVariant.success
        : PokeMapBadgeVariant.neutral;

String _diagnosticLabel(WorldRuleDiagnosticSeverity severity) =>
    switch (severity) {
      WorldRuleDiagnosticSeverity.error => 'Erreur',
      WorldRuleDiagnosticSeverity.warning => 'Attention',
      WorldRuleDiagnosticSeverity.info => 'Info',
    };

PokeMapBadgeVariant _diagnosticVariant(WorldRuleDiagnosticSeverity severity) =>
    switch (severity) {
      WorldRuleDiagnosticSeverity.error => PokeMapBadgeVariant.error,
      WorldRuleDiagnosticSeverity.warning => PokeMapBadgeVariant.warning,
      WorldRuleDiagnosticSeverity.info => PokeMapBadgeVariant.info,
    };
